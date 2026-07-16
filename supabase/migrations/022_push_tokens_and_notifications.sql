-- =============================================================
-- 022: Push Tokens & Owner Notifications
-- Tabel untuk menyimpan FCM token device staff/manager,
-- dan tabel untuk menyimpan pesan notifikasi dari owner.
-- =============================================================

-- Tabel push_tokens: menyimpan FCM token setiap device
CREATE TABLE push_tokens (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_info TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

-- Tabel owner_notifications: pesan notifikasi dari owner ke staff
CREATE TABLE owner_notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_role TEXT CHECK (target_role IN ('staff', 'manager', 'all')),
  target_user_ids UUID[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON push_tokens(is_active) WHERE is_active = true;
CREATE INDEX idx_push_tokens_fcm ON push_tokens(fcm_token);
CREATE INDEX idx_owner_notifications_sender ON owner_notifications(sender_id);
CREATE INDEX idx_owner_notifications_created ON owner_notifications(created_at DESC);

-- RLS: push_tokens
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON push_tokens;
CREATE POLICY anon_all ON push_tokens FOR ALL TO public USING (true) WITH CHECK (true);

-- RLS: owner_notifications
ALTER TABLE owner_notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON owner_notifications;
CREATE POLICY anon_all ON owner_notifications FOR ALL TO public USING (true) WITH CHECK (true);
