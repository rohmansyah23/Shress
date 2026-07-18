-- ============================================================
-- Fix: Notifikasi owner - auth header ke edge function
-- Problem: trigger mengirim Bearer token yang bukan JWT valid
--          sehingga Supabase API gateway return 401
-- Solution: simpan anon key di _app_config, baca dari trigger
-- ============================================================

-- 1. Config table
CREATE TABLE IF NOT EXISTS public._app_config (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
REVOKE ALL ON public._app_config FROM anon, authenticated;
GRANT SELECT ON public._app_config TO postgres;

-- 2. Simpan anon key (supabase anon key, bukan service_role JWT)
INSERT INTO public._app_config (key, value)
VALUES ('supabase_anon_key', 'sb_publishable_Zmj8DPdYfu2lw0id2Ca39w_63wrHVOl')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 3. Update trigger function
CREATE OR REPLACE FUNCTION public.handle_cud_owner_notification()
RETURNS trigger AS $function$
DECLARE
  v_business_id int;
  v_actor_id uuid;
  v_actor_name text;
  v_business_name text;
  v_title text;
  v_body text;
  v_amount decimal(15,2);
  v_type text;
  v_target_name text;
  v_log_id uuid;
  v_anon_key text;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    v_business_id := OLD.business_id;
    v_actor_id := OLD.user_id;
    IF (TG_TABLE_NAME = 'transactions') THEN
      v_amount := OLD.amount;
      v_type := CASE WHEN OLD.type = 'income' THEN 'pemasukan' ELSE 'pengeluaran' END;
    ELSIF (TG_TABLE_NAME = 'debts') THEN
      v_amount := OLD.amount;
    ELSIF (TG_TABLE_NAME = 'consignments') THEN
      v_amount := OLD.total_amount;
    END IF;
  ELSE
    v_business_id := NEW.business_id;
    v_actor_id := NEW.user_id;
    IF (TG_TABLE_NAME = 'transactions') THEN
      v_amount := NEW.amount;
      v_type := CASE WHEN NEW.type = 'income' THEN 'pemasukan' ELSE 'pengeluaran' END;
    ELSIF (TG_TABLE_NAME = 'debts') THEN
      v_amount := NEW.amount;
      SELECT name INTO v_target_name FROM public.debtors WHERE id = NEW.debtor_id;
    ELSIF (TG_TABLE_NAME = 'consignments') THEN
      v_amount := NEW.total_amount;
      SELECT name INTO v_target_name FROM public.consignors WHERE id = NEW.consignor_id;
    END IF;
  END IF;

  SELECT name INTO v_business_name FROM public.businesses WHERE id = v_business_id;
  SELECT COALESCE(display_name, username, 'Staf') INTO v_actor_name FROM public.users WHERE id = v_actor_id;

  IF (TG_TABLE_NAME = 'transactions') THEN
    IF (TG_OP = 'INSERT') THEN
      v_title := 'Transaksi Baru - ' || v_business_name;
      v_body := v_actor_name || ' menambahkan ' || v_type || ' baru sebesar Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    ELSIF (TG_OP = 'UPDATE') THEN
      v_title := 'Pembaruan Transaksi - ' || v_business_name;
      v_body := v_actor_name || ' mengubah transaksi ' || v_type || ' menjadi Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    ELSIF (TG_OP = 'DELETE') THEN
      v_title := 'Penghapusan Transaksi - ' || v_business_name;
      v_body := v_actor_name || ' menghapus transaksi ' || v_type || ' sebesar Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    END IF;
  ELSIF (TG_TABLE_NAME = 'debts') THEN
    IF (TG_OP = 'INSERT') THEN
      v_title := 'Piutang Baru - ' || v_business_name;
      v_body := v_actor_name || ' mencatat piutang baru untuk ' || COALESCE(v_target_name, 'Pelanggan') || ' sebesar Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    ELSIF (TG_OP = 'UPDATE') THEN
      v_title := 'Pembaruan Piutang - ' || v_business_name;
      v_body := v_actor_name || ' mengubah catatan piutang untuk ' || COALESCE(v_target_name, 'Pelanggan') || ' menjadi Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    ELSIF (TG_OP = 'DELETE') THEN
      v_title := 'Penghapusan Piutang - ' || v_business_name;
      v_body := v_actor_name || ' menghapus piutang sebesar Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    END IF;
  ELSIF (TG_TABLE_NAME = 'consignments') THEN
    IF (TG_OP = 'INSERT') THEN
      v_title := 'Titipan Baru - ' || v_business_name;
      v_body := v_actor_name || ' mencatat titipan baru dari ' || COALESCE(v_target_name, 'Reseller') || ' sebesar Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    ELSIF (TG_OP = 'UPDATE') THEN
      v_title := 'Pembaruan Titipan - ' || v_business_name;
      v_body := v_actor_name || ' mengubah catatan titipan dari ' || COALESCE(v_target_name, 'Reseller') || ' menjadi Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    ELSIF (TG_OP = 'DELETE') THEN
      v_title := 'Penghapusan Titipan - ' || v_business_name;
      v_body := v_actor_name || ' menghapus catatan titipan sebesar Rp ' || to_char(v_amount, 'FM999,999,999') || '.';
    END IF;
  END IF;

  INSERT INTO public.owner_activity_logs (
    business_id, actor_id, action_type, table_name, title, body, details
  ) VALUES (
    v_business_id, v_actor_id, TG_OP, TG_TABLE_NAME, v_title, v_body,
    CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD)::jsonb ELSE row_to_json(NEW)::jsonb END
  ) RETURNING id INTO v_log_id;

  BEGIN
    SELECT value INTO v_anon_key FROM public._app_config WHERE key = 'supabase_anon_key';
  EXCEPTION WHEN OTHERS THEN
    v_anon_key := NULL;
  END;

  BEGIN
    PERFORM net.http_post(
      url := 'https://vebjqkmzxelvlgyheyix.supabase.co/functions/v1/notify-owner-cud',
      body := jsonb_build_object(
        'log_id', v_log_id, 'business_id', v_business_id,
        'actor_id', v_actor_id, 'title', v_title, 'body', v_body
      ),
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(v_anon_key, ''),
        'apikey', COALESCE(v_anon_key, ''),
        'X-Webhook-Signature', 'sheress_super_secret_jwt_key_2026'
      )
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  IF (TG_OP = 'DELETE') THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$function$ LANGUAGE plpgsql SECURITY DEFINER;
