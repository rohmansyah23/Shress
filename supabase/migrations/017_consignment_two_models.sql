-- ============================================================
-- 017: Consignment Two Models — Hutang & Harian (Idempotent)
-- ============================================================

-- 1a. Tambah kolom di consignments (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'type'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN type varchar(10) DEFAULT 'debt'
      CHECK (type IN ('debt', 'daily'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'report_status'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN report_status varchar(20) DEFAULT 'pending'
      CHECK (report_status IN ('pending', 'reported', 'settled'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'income_transaction_id'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN income_transaction_id bigint REFERENCES public.transactions(id) ON DELETE SET NULL;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignments' AND column_name = 'expense_transaction_id'
  ) THEN
    ALTER TABLE public.consignments
      ADD COLUMN expense_transaction_id bigint REFERENCES public.transactions(id) ON DELETE SET NULL;
  END IF;
END $$;

-- 1b. Tambah kolom di consignment_items (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignment_items' AND column_name = 'quantity_sold'
  ) THEN
    ALTER TABLE public.consignment_items
      ADD COLUMN quantity_sold int DEFAULT 0 CHECK (quantity_sold >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignment_items' AND column_name = 'quantity_returned'
  ) THEN
    ALTER TABLE public.consignment_items
      ADD COLUMN quantity_returned int DEFAULT 0 CHECK (quantity_returned >= 0);
  END IF;
END $$;

-- 1b-2. Drop old CHECK constraint if it exists (prevents 0+0 != quantity on insert)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.consignment_items'::regclass
      AND conname = 'check_qty_balance'
      AND contype = 'c'
  ) THEN
    ALTER TABLE public.consignment_items DROP CONSTRAINT check_qty_balance;
  END IF;
END $$;

-- 1b-3. Add description column to consignment_items
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'consignment_items' AND column_name = 'description'
  ) THEN
    ALTER TABLE public.consignment_items ADD COLUMN description text;
  END IF;
END $$;

-- 1c. Trigger function: validasi qty balance (hanya saat lapor, bukan saat insert awal)
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

-- 1d. Trigger (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_check_qty_balance'
  ) THEN
    CREATE TRIGGER trg_check_qty_balance
      BEFORE INSERT OR UPDATE ON public.consignment_items
      FOR EACH ROW EXECUTE FUNCTION public.check_qty_balance();
  END IF;
END $$;

-- 1e. Seed kategori baru (idempotent via ON CONFLICT)
DO $$
DECLARE b RECORD;
BEGIN
  FOR b IN SELECT id FROM public.businesses LOOP
    INSERT INTO public.categories (business_id, name, type) VALUES
      (b.id, 'Komisi Titipan', 'income'),
      (b.id, 'Bayar Titipan', 'expense')
    ON CONFLICT DO NOTHING;
  END LOOP;
END $$;
