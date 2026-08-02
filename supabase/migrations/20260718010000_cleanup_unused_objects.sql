-- ============================================================
-- Cleanup: DROP objects yang tidak digunakan oleh Flutter app
-- Generated: 2026-07-18
-- ============================================================

-- 1. DROP fungsi yang tidak dipanggil dari app
DROP FUNCTION IF EXISTS public.get_current_user_role();
DROP FUNCTION IF EXISTS public.user_has_business_access(integer);
DROP FUNCTION IF EXISTS public.get_webhook_queue();
DROP FUNCTION IF EXISTS public.hmac(text, text, text);
