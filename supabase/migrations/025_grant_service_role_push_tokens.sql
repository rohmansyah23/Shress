-- =============================================================
-- 025: Grant service_role permissions for push_tokens & owner_notifications
-- Edge Functions use service_role client, which also needs GRANT.
-- =============================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.push_tokens TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.owner_notifications TO service_role;
