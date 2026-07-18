-- ============================================================
-- Sheress - Initial Schema (Clean Squash)
-- Generated: 2026-07-18
-- Original: 25 migrations squashed into 1
-- ============================================================

-- 0. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pgjwt";
CREATE EXTENSION IF NOT EXISTS pg_net CASCADE;

-- 1. TABLES

-- 1a. Users
CREATE TABLE IF NOT EXISTS public.users (
  id uuid PRIMARY KEY,
  email varchar(255),
  username varchar(255) NOT NULL,
  display_name varchar(255),
  avatar_url varchar(500),
  role varchar(20) NOT NULL CHECK (role IN ('owner', 'manager', 'staff')),
  is_active boolean NOT NULL DEFAULT true,
  password_hash varchar(200),
  session_version int DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 1b. Businesses
CREATE TABLE IF NOT EXISTS public.businesses (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name varchar(255) NOT NULL,
  description text,
  qris_image_url varchar(500),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 1c. User-Business Bridge
CREATE TABLE IF NOT EXISTS public.user_businesses (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, business_id)
);

-- 1d. Categories
CREATE TABLE IF NOT EXISTS public.categories (
  id int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name varchar(255) NOT NULL,
  type varchar(20) NOT NULL CHECK (type IN ('income', 'expense')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT categories_business_name_type_unique UNIQUE (business_id, name, type)
);

-- 1e. Transactions
CREATE TABLE IF NOT EXISTS public.transactions (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id int NOT NULL REFERENCES public.categories(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type varchar(20) NOT NULL CHECK (type IN ('income', 'expense')),
  amount decimal(15,2) NOT NULL CHECK (amount >= 0),
  cogs decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (cogs >= 0),
  payment_method varchar(50) NOT NULL DEFAULT 'cash'
    CHECK (payment_method IN ('cash', 'transfer', 'qris', 'other')),
  description text,
  transaction_date date NOT NULL DEFAULT CURRENT_DATE,
  status_sync boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cogs_only_for_income CHECK (
    (type = 'income' AND cogs >= 0) OR (type = 'expense' AND cogs = 0.00)
  )
);

-- 1f. Debtors
CREATE TABLE public.debtors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- 1g. Debts
CREATE TABLE public.debts (
  id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debtor_id               int NOT NULL REFERENCES public.debtors(id) ON DELETE CASCADE,
  business_id             int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id                 uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount                  decimal(15,2) NOT NULL CHECK (amount > 0),
  paid_amount             decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
  description             text,
  status                  varchar(20) NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partial', 'paid')),
  debt_date               date NOT NULL DEFAULT CURRENT_DATE,
  due_date                date,
  expense_transaction_id  bigint REFERENCES public.transactions(id) ON DELETE SET NULL,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now()
);

-- 1h. Debt Payments
CREATE TABLE public.debt_payments (
  id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debt_id               bigint NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
  amount                decimal(15,2) NOT NULL CHECK (amount > 0),
  payment_date          date NOT NULL DEFAULT CURRENT_DATE,
  user_id               uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes                 text,
  income_transaction_id bigint REFERENCES public.transactions(id) ON DELETE SET NULL,
  created_at            timestamptz NOT NULL DEFAULT now()
);

-- 1i. Consignors
CREATE TABLE public.consignors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- 1j. Consignments
CREATE TABLE public.consignments (
  id                      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignor_id            int NOT NULL REFERENCES public.consignors(id) ON DELETE CASCADE,
  business_id             int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id                 uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_amount            decimal(15,2) NOT NULL CHECK (total_amount > 0),
  settled_amount          decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (settled_amount >= 0),
  description             text,
  status                  varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'settled', 'cancelled')),
  consignment_date        date NOT NULL DEFAULT CURRENT_DATE,
  due_date                date,
  type                    varchar(10) DEFAULT 'reseller' CHECK (type IN ('reseller', 'daily')),
  report_status           varchar(20) DEFAULT 'pending' CHECK (report_status IN ('pending', 'reported', 'settled')),
  income_transaction_id   bigint REFERENCES public.transactions(id) ON DELETE SET NULL,
  expense_transaction_id  bigint REFERENCES public.transactions(id) ON DELETE SET NULL,
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now()
);

-- 1k. Consignment Items
CREATE TABLE public.consignment_items (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id    bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  product_name      varchar(255) NOT NULL,
  quantity          int NOT NULL CHECK (quantity > 0),
  quantity_sold     int DEFAULT 0 CHECK (quantity_sold >= 0),
  quantity_returned  int DEFAULT 0 CHECK (quantity_returned >= 0),
  agreed_price      decimal(15,2) NOT NULL CHECK (agreed_price > 0),
  selling_price     decimal(15,2),
  description       text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

-- 1l. Consignment Settlements
CREATE TABLE public.consignment_settlements (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id   bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  amount           decimal(15,2) NOT NULL CHECK (amount > 0),
  settlement_date  date NOT NULL DEFAULT CURRENT_DATE,
  user_id          uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now()
);

-- 1m. Push Tokens
CREATE TABLE push_tokens (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token   TEXT NOT NULL,
  platform    TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_info TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, fcm_token)
);

-- 1n. Owner Notifications
CREATE TABLE owner_notifications (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender_id       UUID NOT NULL REFERENCES users(id),
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  target_role     TEXT CHECK (target_role IN ('staff', 'manager', 'all')),
  target_user_ids UUID[],
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 1o. Owner Activity Logs
CREATE TABLE IF NOT EXISTS public.owner_activity_logs (
  id            UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id   INT NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  actor_id      UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action_type   TEXT NOT NULL CHECK (action_type IN ('INSERT', 'UPDATE', 'DELETE')),
  table_name    TEXT NOT NULL CHECK (table_name IN ('transactions', 'debts', 'consignments')),
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  details       JSONB,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- 2. INDEXES
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON public.users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_user_businesses_user_id ON public.user_businesses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_businesses_business_id ON public.user_businesses(business_id);
CREATE INDEX IF NOT EXISTS idx_categories_business_id ON public.categories(business_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON public.categories(type);
CREATE INDEX IF NOT EXISTS idx_transactions_business_id ON public.transactions(business_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_payment_method ON public.transactions(payment_method);
CREATE INDEX IF NOT EXISTS idx_transactions_sync ON public.transactions(status_sync) WHERE status_sync = false;
CREATE INDEX IF NOT EXISTS idx_transactions_business_date ON public.transactions(business_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_user_sync ON public.transactions(user_id, status_sync) WHERE status_sync = false;
CREATE INDEX idx_debtors_business ON public.debtors(business_id);
CREATE INDEX idx_debts_business ON public.debts(business_id);
CREATE INDEX idx_debts_debtor ON public.debts(debtor_id);
CREATE INDEX idx_debts_status ON public.debts(status);
CREATE INDEX idx_debt_payments_debt ON public.debt_payments(debt_id);
CREATE INDEX idx_consignors_business ON public.consignors(business_id);
CREATE INDEX idx_consignments_business ON public.consignments(business_id);
CREATE INDEX idx_consignments_consignor ON public.consignments(consignor_id);
CREATE INDEX idx_consignments_status ON public.consignments(status);
CREATE INDEX idx_consignment_items_consignment ON public.consignment_items(consignment_id);
CREATE INDEX idx_consignment_settlements_consignment ON public.consignment_settlements(consignment_id);
CREATE INDEX idx_push_tokens_user ON push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON push_tokens(is_active) WHERE is_active = true;
CREATE INDEX idx_push_tokens_fcm ON push_tokens(fcm_token);
CREATE INDEX idx_owner_notifications_sender ON owner_notifications(sender_id);
CREATE INDEX idx_owner_notifications_created ON owner_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_owner_activity_logs_business ON public.owner_activity_logs(business_id);
CREATE INDEX IF NOT EXISTS idx_owner_activity_logs_created ON public.owner_activity_logs(created_at DESC);
-- 3. TRIGGER FUNCTIONS

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.users (id, email, username, display_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data ->> 'role', 'staff')
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    display_name = EXCLUDED.display_name,
    role = EXCLUDED.role,
    updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_user_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  UPDATE public.users SET
    email = NEW.email,
    username = COALESCE(NEW.raw_user_meta_data ->> 'username', split_part(NEW.email, '@', 1))
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.base64_encode(p_input text)
RETURNS text AS $$
  SELECT translate(encode(p_input::bytea, 'base64'), E'\n ', '');
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.base64_decode(p_input text)
RETURNS text AS $$
  SELECT convert_from(decode(p_input, 'base64'), 'UTF8');
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.hmac(data text, key text, type text)
RETURNS bytea
LANGUAGE sql SECURITY DEFINER
AS $$
  SELECT extensions.hmac(data, key, type);
$$;

CREATE OR REPLACE FUNCTION public.check_qty_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.quantity_sold > 0 OR NEW.quantity_returned > 0 THEN
    IF NEW.quantity_sold + NEW.quantity_returned != NEW.quantity THEN
      RAISE EXCEPTION 'quantity_sold + quantity_returned harus sama dengan quantity';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- 4. AUTH RPC FUNCTIONS

CREATE OR REPLACE FUNCTION public.verify_public_password(
  p_identifier text,
  p_password text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, extensions
AS $$
DECLARE
  v_user_id uuid;
  v_db_password_hash text;
  v_role text;
  v_is_active boolean;
  v_session_version int;
  v_jwt_secret text;
  v_payload_json text;
  v_payload_base64 text;
  v_signature_hex text;
  v_token text;
BEGIN
  v_jwt_secret := COALESCE(
    NULLIF(current_setting('app.settings.jwt_secret', true), ''),
    'sheress_super_secret_jwt_key_2026'
  );
  SELECT id, password_hash, role, is_active, session_version
  INTO v_user_id, v_db_password_hash, v_role, v_is_active, v_session_version
  FROM public.users
  WHERE (LOWER(email) = LOWER(p_identifier) OR LOWER(username) = LOWER(p_identifier))
    AND password_hash IS NOT NULL;
  IF v_user_id IS NULL OR NOT v_is_active THEN
    RETURN NULL;
  END IF;
  IF crypt(p_password, v_db_password_hash) = v_db_password_hash THEN
    v_payload_json := json_build_object(
      'sub', v_user_id, 'role', v_role, 'sv', v_session_version,
      'exp', extract(epoch from now())::integer + 2592000
    )::text;
    v_payload_base64 := public.base64_encode(v_payload_json);
    v_signature_hex := encode(hmac(v_payload_base64::text, v_jwt_secret::text, 'sha256'), 'hex');
    v_token := v_payload_base64 || '.' || v_signature_hex;
    RETURN jsonb_build_object('user_id', v_user_id, 'token', v_token);
  END IF;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_user_jwt(p_token text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, extensions
AS $$
DECLARE
  v_jwt_secret text;
  v_parts text[];
  v_payload_base64 text;
  v_signature_hex text;
  v_calculated_signature text;
  v_payload_json text;
  v_payload json;
  v_user_id uuid;
  v_token_version int;
  v_db_version int;
  v_is_active boolean;
  v_exp int;
BEGIN
  v_jwt_secret := COALESCE(
    NULLIF(current_setting('app.settings.jwt_secret', true), ''),
    'sheress_super_secret_jwt_key_2026'
  );
  v_parts := string_to_array(p_token, '.');
  IF array_length(v_parts, 1) != 2 THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Format token tidak valid');
  END IF;
  v_payload_base64 := v_parts[1];
  v_signature_hex := v_parts[2];
  v_calculated_signature := encode(hmac(v_payload_base64, v_jwt_secret, 'sha256'), 'hex');
  IF v_calculated_signature != v_signature_hex THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Tanda tangan token tidak cocok');
  END IF;
  BEGIN
    v_payload_json := public.base64_decode(v_payload_base64);
    v_payload := v_payload_json::json;
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Payload JSON tidak valid');
  END;
  v_exp := (v_payload->>'exp')::integer;
  IF extract(epoch from now())::integer > v_exp THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Token telah kedaluwarsa');
  END IF;
  v_user_id := (v_payload->>'sub')::uuid;
  v_token_version := (v_payload->>'sv')::integer;
  SELECT session_version, is_active INTO v_db_version, v_is_active
  FROM public.users WHERE id = v_user_id;
  IF v_db_version IS NULL OR NOT v_is_active OR v_db_version != v_token_version THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Sesi kedaluwarsa atau user nonaktif');
  END IF;
  RETURN jsonb_build_object('valid', true, 'user_id', v_user_id, 'role', v_payload->>'role');
END;
$$;

CREATE OR REPLACE FUNCTION public.create_public_user(
  p_email text, p_username text, p_role text, p_password text
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE v_user_id uuid;
BEGIN
  v_user_id := gen_random_uuid();
  INSERT INTO public.users (id, email, username, role, password_hash)
  VALUES (v_user_id, p_email, p_username, p_role,
    extensions.crypt(p_password, extensions.gen_salt('bf')));
  RETURN v_user_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_public_user_password(
  p_user_id uuid, p_new_password text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.users
  SET password_hash = extensions.crypt(p_new_password, extensions.gen_salt('bf')),
      updated_at = now()
  WHERE id = p_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_public_user(text, text, text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_public_user_password(uuid, text) TO anon, authenticated;
-- 5. CUD NOTIFICATION TRIGGER FUNCTION

CREATE OR REPLACE FUNCTION public.handle_cud_owner_notification()
RETURNS trigger AS $$
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
  v_auth_header text;
  v_headers_raw text;
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
    v_headers_raw := current_setting('request.headers', true);
    IF NULLIF(v_headers_raw, '') IS NOT NULL THEN
      v_auth_header := v_headers_raw::json->>'authorization';
    ELSE
      v_auth_header := NULL;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    v_auth_header := NULL;
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
        'Authorization', COALESCE(v_auth_header, 'Bearer ' || COALESCE(NULLIF(current_setting('app.settings.jwt_secret', true), ''), 'sheress_super_secret_jwt_key_2026')),
        'X-Webhook-Signature', COALESCE(NULLIF(current_setting('app.settings.jwt_secret', true), ''), 'sheress_super_secret_jwt_key_2026')
      )
    );
  EXCEPTION WHEN OTHERS THEN
    NULL;
  END;

  IF (TG_OP = 'DELETE') THEN RETURN OLD; END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- 6. TRIGGERS

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE TRIGGER on_auth_user_update
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.sync_user_email();

CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_businesses_updated_at
  BEFORE UPDATE ON public.businesses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_debtors_updated_at
  BEFORE UPDATE ON public.debtors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_debts_updated_at
  BEFORE UPDATE ON public.debts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_consignors_updated_at
  BEFORE UPDATE ON public.consignors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER set_consignments_updated_at
  BEFORE UPDATE ON public.consignments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_check_qty_balance
  BEFORE INSERT OR UPDATE ON public.consignment_items
  FOR EACH ROW EXECUTE FUNCTION public.check_qty_balance();

CREATE TRIGGER trg_cud_owner_notification_transactions
  AFTER INSERT OR UPDATE OR DELETE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_cud_owner_notification();

CREATE TRIGGER trg_cud_owner_notification_debts
  AFTER INSERT OR UPDATE OR DELETE ON public.debts
  FOR EACH ROW EXECUTE FUNCTION public.handle_cud_owner_notification();

CREATE TRIGGER trg_cud_owner_notification_consignments
  AFTER INSERT OR UPDATE OR DELETE ON public.consignments
  FOR EACH ROW EXECUTE FUNCTION public.handle_cud_owner_notification();

-- 7. ROW LEVEL SECURITY (RLS)

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debtors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debt_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignment_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignment_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE owner_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.owner_activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY anon_all ON public.users FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.businesses FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.user_businesses FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.categories FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.transactions FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.debtors FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.debts FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.debt_payments FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignors FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignments FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignment_items FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignment_settlements FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON push_tokens FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON owner_notifications FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.owner_activity_logs FOR ALL TO public USING (true) WITH CHECK (true);

-- 8. STORAGE (QRIS bucket)

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'qris-images', 'qris-images', true, 5242880,
  ARRAY['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp', 'image/heic', 'image/heif']::text[]
) ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Anyone can view QRIS images" ON storage.objects;
CREATE POLICY "Anyone can view QRIS images"
  ON storage.objects FOR SELECT USING (bucket_id = 'qris-images');

DROP POLICY IF EXISTS "Users can upload QRIS images" ON storage.objects;
CREATE POLICY "Users can upload QRIS images"
  ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'qris-images');

DROP POLICY IF EXISTS "Users can update QRIS images" ON storage.objects;
CREATE POLICY "Users can update QRIS images"
  ON storage.objects FOR UPDATE
  USING (bucket_id = 'qris-images')
  WITH CHECK (bucket_id = 'qris-images');

DROP POLICY IF EXISTS "Owners can delete QRIS images" ON storage.objects;
CREATE POLICY "Owners can delete QRIS images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'qris-images'
    AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
  );

-- 9. GRANT PERMISSIONS

GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.verify_public_password(text, text) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verify_user_jwt(text) TO anon, authenticated;

-- 10. REALTIME

ALTER PUBLICATION supabase_realtime ADD TABLE public.consignments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignment_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignors;
-- 11. SEED DATA

INSERT INTO public.businesses (name, description, qris_image_url) VALUES
  ('Agen Minuman Alkali', 'Sheress - Agen Minuman Alkali', 'assets/images/qris/business_1_qris.svg'),
  ('Teh Solo', 'Sheress - Teh Solo', 'assets/images/qris/business_2_qris.svg'),
  ('Warung Kopi', 'Sheress - Warung Kopi', 'assets/images/qris/business_3_qris.svg')
ON CONFLICT DO NOTHING;

DO $$
DECLARE b RECORD;
BEGIN
  FOR b IN SELECT id FROM public.businesses LOOP
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, 'Penjualan Harian', 'income'),
      (b.id, 'Penjualan Grosir', 'income'),
      (b.id, 'Pendapatan Lain', 'income'),
      (b.id, 'Bahan Baku', 'expense'),
      (b.id, 'Operasional', 'expense'),
      (b.id, 'Gaji Karyawan', 'expense'),
      (b.id, 'Transportasi', 'expense'),
      (b.id, 'Lain-lain', 'expense'),
      (b.id, 'Komisi Titipan', 'income'),
      (b.id, 'Bayar Titipan', 'expense')
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;

INSERT INTO public.users (id, email, username, display_name, role, password_hash, is_active)
VALUES
  ('d0000000-0000-0000-0000-000000000001', 'owner@ssrs.com', 'owner_sheress', 'Owner Sheress', 'owner',
    extensions.crypt('password123', extensions.gen_salt('bf')), true),
  ('d0000000-0000-0000-0000-000000000002', 'manager@ssrs.com', 'manager_sheress', 'Manager Sheress', 'manager',
    extensions.crypt('password123', extensions.gen_salt('bf')), true),
  ('d0000000-0000-0000-0000-000000000003', 'staff@ssrs.com', 'staff_sheress', 'Staff Sheress', 'staff',
    extensions.crypt('password123', extensions.gen_salt('bf')), true)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email, username = EXCLUDED.username,
  display_name = EXCLUDED.display_name, role = EXCLUDED.role,
  password_hash = COALESCE(EXCLUDED.password_hash, public.users.password_hash),
  is_active = true;

INSERT INTO public.user_businesses (user_id, business_id)
SELECT demo.user_id, b.id
FROM (VALUES
  ('d0000000-0000-0000-0000-000000000001'::uuid, 'Agen Minuman Alkali'),
  ('d0000000-0000-0000-0000-000000000001'::uuid, 'Teh Solo'),
  ('d0000000-0000-0000-0000-000000000001'::uuid, 'Warung Kopi'),
  ('d0000000-0000-0000-0000-000000000002'::uuid, 'Agen Minuman Alkali'),
  ('d0000000-0000-0000-0000-000000000002'::uuid, 'Teh Solo'),
  ('d0000000-0000-0000-0000-000000000003'::uuid, 'Warung Kopi')
) AS demo(user_id, business_name)
JOIN public.businesses b ON b.name = demo.business_name
ON CONFLICT (user_id, business_id) DO NOTHING;