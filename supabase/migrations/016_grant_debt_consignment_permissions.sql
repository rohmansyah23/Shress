-- ============================================================
-- 016: Add GRANT permissions for debt/consignment tables
-- Tables were created in 015 but missing GRANT for Data API access
-- ============================================================

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
