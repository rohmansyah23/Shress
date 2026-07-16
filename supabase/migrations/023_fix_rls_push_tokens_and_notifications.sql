-- =============================================================
-- 023: Fix RLS for push_tokens & owner_notifications
-- Migration 022 was applied with old policies that used auth.uid(),
-- which doesn't work with this app's custom auth (no Supabase Auth).
-- =============================================================

-- push_tokens: drop old policy, apply anon_all
DROP POLICY IF EXISTS "Users can manage their own push tokens" ON push_tokens;
DROP POLICY IF EXISTS anon_all ON push_tokens;
CREATE POLICY anon_all ON push_tokens FOR ALL TO public USING (true) WITH CHECK (true);

-- owner_notifications: drop old policies, apply anon_all
DROP POLICY IF EXISTS "Owner can insert notifications" ON owner_notifications;
DROP POLICY IF EXISTS "Staff can read their notifications" ON owner_notifications;
DROP POLICY IF EXISTS anon_all ON owner_notifications;
CREATE POLICY anon_all ON owner_notifications FOR ALL TO public USING (true) WITH CHECK (true);
