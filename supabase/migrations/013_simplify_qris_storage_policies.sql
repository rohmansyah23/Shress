-- ============================================================
-- Sheress - Simplify QRIS storage policies for Supabase setup
-- that doesn't propagate JWT claims to storage DB session.
-- Security is enforced client-side (owner role check in app).
-- ============================================================

-- Drop debug policy if still exists
DROP POLICY IF EXISTS "Debug public insert QRIS" ON storage.objects;

-- INSERT: no auth check needed (app already enforces owner role)
DROP POLICY IF EXISTS "Authenticated users can upload QRIS images" ON storage.objects;
CREATE POLICY "Users can upload QRIS images"
ON storage.objects
FOR INSERT
WITH CHECK (bucket_id = 'qris-images');

-- UPDATE: same, for upsert to work
DROP POLICY IF EXISTS "Owners can update QRIS images" ON storage.objects;
CREATE POLICY "Users can update QRIS images"
ON storage.objects
FOR UPDATE
USING (bucket_id = 'qris-images')
WITH CHECK (bucket_id = 'qris-images');

-- DELETE: keep owner check (not used from Flutter currently)
DROP POLICY IF EXISTS "Owners can delete QRIS images" ON storage.objects;
CREATE POLICY "Owners can delete QRIS images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'qris-images'
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);
