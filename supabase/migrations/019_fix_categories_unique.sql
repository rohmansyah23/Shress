-- ============================================================
-- 019_fix_categories_unique.sql
-- Remove duplicate categories and add unique constraint
-- ============================================================

-- Remove duplicate rows, keep the one with the smallest id
DELETE FROM public.categories a
USING public.categories b
WHERE a.id > b.id
  AND a.business_id = b.business_id
  AND a.name = b.name
  AND a.type = b.type;

-- Add unique constraint to prevent future duplicates
ALTER TABLE public.categories
  ADD CONSTRAINT categories_business_name_type_unique
  UNIQUE (business_id, name, type);
