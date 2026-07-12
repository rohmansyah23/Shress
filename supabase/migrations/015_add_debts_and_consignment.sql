-- ============================================================
-- 015: Piutang (Debts) & Konsinyasi (Consignment) tables
-- ============================================================

-- ==================== PIUTANG ====================

CREATE TABLE public.debtors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_debtors_business ON public.debtors(business_id);

CREATE TABLE public.debts (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debtor_id    int NOT NULL REFERENCES public.debtors(id) ON DELETE CASCADE,
  business_id  int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  amount       decimal(15,2) NOT NULL CHECK (amount > 0),
  paid_amount  decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
  description  text,
  status       varchar(20) NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'partial', 'paid')),
  debt_date    date NOT NULL DEFAULT CURRENT_DATE,
  due_date     date,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_debts_business ON public.debts(business_id);
CREATE INDEX idx_debts_debtor ON public.debts(debtor_id);
CREATE INDEX idx_debts_status ON public.debts(status);

CREATE TABLE public.debt_payments (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  debt_id       bigint NOT NULL REFERENCES public.debts(id) ON DELETE CASCADE,
  amount        decimal(15,2) NOT NULL CHECK (amount > 0),
  payment_date  date NOT NULL DEFAULT CURRENT_DATE,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes         text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_debt_payments_debt ON public.debt_payments(debt_id);

-- Trigger: auto-update updated_at for debtors
CREATE TRIGGER set_debtors_updated_at
  BEFORE UPDATE ON public.debtors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Trigger: auto-update updated_at for debts
CREATE TRIGGER set_debts_updated_at
  BEFORE UPDATE ON public.debts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ==================== KONSINYASI ====================

CREATE TABLE public.consignors (
  id          int GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  name        varchar(255) NOT NULL,
  phone       varchar(50),
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignors_business ON public.consignors(business_id);

CREATE TABLE public.consignments (
  id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignor_id      int NOT NULL REFERENCES public.consignors(id) ON DELETE CASCADE,
  business_id       int NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id           uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  total_amount      decimal(15,2) NOT NULL CHECK (total_amount > 0),
  settled_amount    decimal(15,2) NOT NULL DEFAULT 0.00 CHECK (settled_amount >= 0),
  description       text,
  status            varchar(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'settled', 'cancelled')),
  consignment_date  date NOT NULL DEFAULT CURRENT_DATE,
  due_date          date,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignments_business ON public.consignments(business_id);
CREATE INDEX idx_consignments_consignor ON public.consignments(consignor_id);
CREATE INDEX idx_consignments_status ON public.consignments(status);

CREATE TABLE public.consignment_items (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id  bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  product_name    varchar(255) NOT NULL,
  quantity        int NOT NULL CHECK (quantity > 0),
  agreed_price    decimal(15,2) NOT NULL CHECK (agreed_price > 0),
  selling_price   decimal(15,2),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignment_items_consignment ON public.consignment_items(consignment_id);

CREATE TABLE public.consignment_settlements (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  consignment_id   bigint NOT NULL REFERENCES public.consignments(id) ON DELETE CASCADE,
  amount           decimal(15,2) NOT NULL CHECK (amount > 0),
  settlement_date  date NOT NULL DEFAULT CURRENT_DATE,
  user_id          uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  notes            text,
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_consignment_settlements_consignment ON public.consignment_settlements(consignment_id);

-- Trigger: auto-update updated_at for consignors
CREATE TRIGGER set_consignors_updated_at
  BEFORE UPDATE ON public.consignors
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Trigger: auto-update updated_at for consignments
CREATE TRIGGER set_consignments_updated_at
  BEFORE UPDATE ON public.consignments
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ==================== RLS (consistent with existing open policies) ====================

ALTER TABLE public.debtors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debt_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignment_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consignment_settlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY anon_all ON public.debtors FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.debts FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.debt_payments FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignors FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignments FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignment_items FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY anon_all ON public.consignment_settlements FOR ALL TO public USING (true) WITH CHECK (true);

-- ==================== GRANT permissions for Data API access ====================

GRANT ALL ON TABLE public.debtors TO anon;
GRANT ALL ON TABLE public.debtors TO authenticated;
GRANT ALL ON TABLE public.debtors TO service_role;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debtors_id_seq TO service_role;

GRANT ALL ON TABLE public.debts TO anon;
GRANT ALL ON TABLE public.debts TO authenticated;
GRANT ALL ON TABLE public.debts TO service_role;
GRANT ALL ON SEQUENCE public.debts_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debts_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debts_id_seq TO service_role;

GRANT ALL ON TABLE public.debt_payments TO anon;
GRANT ALL ON TABLE public.debt_payments TO authenticated;
GRANT ALL ON TABLE public.debt_payments TO service_role;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO anon;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.debt_payments_id_seq TO service_role;

GRANT ALL ON TABLE public.consignors TO anon;
GRANT ALL ON TABLE public.consignors TO authenticated;
GRANT ALL ON TABLE public.consignors TO service_role;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignors_id_seq TO service_role;

GRANT ALL ON TABLE public.consignments TO anon;
GRANT ALL ON TABLE public.consignments TO authenticated;
GRANT ALL ON TABLE public.consignments TO service_role;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignments_id_seq TO service_role;

GRANT ALL ON TABLE public.consignment_items TO anon;
GRANT ALL ON TABLE public.consignment_items TO authenticated;
GRANT ALL ON TABLE public.consignment_items TO service_role;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignment_items_id_seq TO service_role;

GRANT ALL ON TABLE public.consignment_settlements TO anon;
GRANT ALL ON TABLE public.consignment_settlements TO authenticated;
GRANT ALL ON TABLE public.consignment_settlements TO service_role;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO anon;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.consignment_settlements_id_seq TO service_role;
