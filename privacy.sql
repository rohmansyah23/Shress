ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON public.users;
CREATE POLICY anon_all ON public.users FOR ALL TO public USING (true) WITH CHECK (true);

ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON public.businesses;
CREATE POLICY anon_all ON public.businesses FOR ALL TO public USING (true) WITH CHECK (true);

ALTER TABLE public.user_businesses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON public.user_businesses;
CREATE POLICY anon_all ON public.user_businesses FOR ALL TO public USING (true) WITH CHECK (true);

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON public.categories;
CREATE POLICY anon_all ON public.categories FOR ALL TO public USING (true) WITH CHECK (true);

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON public.transactions;
CREATE POLICY anon_all ON public.transactions FOR ALL TO public USING (true) WITH CHECK (true);

ALTER TABLE public.financial_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS anon_all ON public.financial_reports;
CREATE POLICY anon_all ON public.financial_reports FOR ALL TO public USING (true) WITH CHECK (true);

---
