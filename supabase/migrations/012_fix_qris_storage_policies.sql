-- ============================================================
-- Sheress - Fix QRIS storage bucket RLS policies
-- Use auth.uid() IS NOT NULL instead of auth.role() = 'authenticated'
-- because auth.role() may not return 'authenticated' in some setups.
-- ============================================================

-- 1. Drop existing INSERT policy and recreate
DROP POLICY IF EXISTS "Authenticated users can upload QRIS images" ON storage.objects;
CREATE POLICY "Authenticated users can upload QRIS images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
);

-- 2. Drop existing UPDATE policy and recreate
DROP POLICY IF EXISTS "Owners can update QRIS images" ON storage.objects;
CREATE POLICY "Owners can update QRIS images"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
)
WITH CHECK (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);

-- 3. Drop existing DELETE policy and recreate
DROP POLICY IF EXISTS "Owners can delete QRIS images" ON storage.objects;
CREATE POLICY "Owners can delete QRIS images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'qris-images'
  AND auth.uid() IS NOT NULL
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);


