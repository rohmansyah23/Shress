-- Enable Realtime for consignment-related tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignment_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.consignors;
