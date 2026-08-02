-- ============================================================
-- Auto-reminder rekap harian via pg_cron
-- Jadwal: 17.00 / 18.00 / 19.00 WIB
-- (Supabase server berjalan di UTC: 17/18/19 WIB == 10/11/12 UTC)
-- ============================================================

-- 1. Pastikan pg_cron terpasang
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Edge function send-recap-reminder perlu membaca override test di _app_config
GRANT SELECT ON public._app_config TO service_role;

-- 3. SQL function pemanggil edge function (dipanggil cron / manual)
CREATE OR REPLACE FUNCTION public.send_recap_reminder(
  p_title text,
  p_body text,
  p_target_role text DEFAULT 'all',
  p_target_user_ids uuid[] DEFAULT NULL
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_anon_key text;
  v_body jsonb;
BEGIN
  BEGIN
    SELECT value INTO v_anon_key FROM public._app_config WHERE key = 'supabase_anon_key';
  EXCEPTION WHEN OTHERS THEN
    v_anon_key := NULL;
  END;

  v_body := jsonb_build_object(
    'title', p_title,
    'body', p_body,
    'target_role', p_target_role,
    'target_user_ids', CASE
      WHEN p_target_user_ids IS NULL THEN NULL
      ELSE to_jsonb(p_target_user_ids)
    END
  );

  RETURN net.http_post(
    url := 'https://vebjqkmzxelvlgyheyix.supabase.co/functions/v1/send-recap-reminder',
    body := v_body,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || COALESCE(v_anon_key, ''),
      'apikey', COALESCE(v_anon_key, ''),
      'X-Webhook-Signature', COALESCE(NULLIF(current_setting('app.settings.jwt_secret', true), ''), 'sheress_super_secret_jwt_key_2026')
    )
  );
END;
$function$;

-- 4. Hapus job lama dengan nama sama (idempotent) lalu buat ulang
DO $$
DECLARE v_jobid bigint;
BEGIN
  FOR v_jobid IN
    SELECT jobid FROM cron.job
    WHERE jobname IN ('recap-reminder-1700', 'recap-reminder-1800', 'recap-reminder-1900')
  LOOP
    PERFORM cron.unschedule(v_jobid);
  END LOOP;
END $$;

-- 17.00 WIB == 10.00 UTC
SELECT cron.schedule(
  'recap-reminder-1700',
  '0 10 * * *',
  $$SELECT public.send_recap_reminder(
      'Laporan Tutup Toko',
      'Jangan lupa lakukan rekonsiliasi kas dan upload laporan penjualan hari ini setelah toko tutup ya. Batas akhir jam 20.00 WIB.'
    );$$
);

-- 18.00 WIB == 11.00 UTC
SELECT cron.schedule(
  'recap-reminder-1800',
  '0 11 * * *',
  $$SELECT public.send_recap_reminder(
      'Laporan Tutup Toko',
      'Jangan lupa lakukan rekonsiliasi kas dan upload laporan penjualan hari ini setelah toko tutup ya. Batas akhir jam 20.00 WIB.'
    );$$
);

-- 19.00 WIB == 12.00 UTC
SELECT cron.schedule(
  'recap-reminder-1900',
  '0 12 * * *',
  $$SELECT public.send_recap_reminder(
      'Laporan Tutup Toko',
      'Jangan lupa lakukan rekonsiliasi kas dan upload laporan penjualan hari ini setelah toko tutup ya. Batas akhir jam 20.00 WIB.'
    );$$
);

-- ============================================================
-- MODE TEST — jalankan manual di SQL Editor saat test:
--
-- 1) Hanya kirim ke pasep (untuk test, agar user lain tidak kena spam):
--    INSERT INTO public._app_config (key, value)
--    VALUES ('recap_reminder_test_user_ids', '["129e4811-8202-44d0-b723-1c0d06501109"]')
--    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
--
-- 2) Kirim sekarang juga (tanpa menunggu jam):
--    SELECT public.send_recap_reminder('Test Rekap', 'Cek notifikasi 17/18/19 WIB.');
--
-- 3) Kirim ke role spesifik (misal hanya manager):
--    SELECT public.send_recap_reminder('Test Rekap', 'Cek notifikasi manager.', 'manager');
--
-- 4) Selesai test — kembalikan ke semua staff+manager:
--    DELETE FROM public._app_config WHERE key = 'recap_reminder_test_user_ids';
--
-- 5) Cek daftar job cron:
--    SELECT jobid, jobname, schedule, command, active FROM cron.job;
-- ============================================================
