-- =============================================================
-- 024: Grant table permissions for push_tokens & owner_notifications
-- The anon role needs explicit GRANT for INSERT, UPDATE, DELETE
-- in addition to RLS policies.
-- =============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.push_tokens TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.owner_notifications TO anon;
