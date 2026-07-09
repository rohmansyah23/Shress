-- ============================================================
-- SSRS Finance - QRIS Storage Bucket Migration (v2)
-- Description: Creates storage bucket for QRIS images and
--              updates seed data to use Supabase Storage URLs.
-- Notes:
--   After running this migration, upload QRIS images to
--   the 'qris-images' bucket via:
--     supabase storage upload qris-images business_1_qris.svg
-- ============================================================

-- 1. CREATE QRIS STORAGE BUCKET
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'qris-images',
  'qris-images',
  true,                           -- public bucket (for serving images)
  5242880,                        -- 5 MB limit
  ARRAY['image/png', 'image/jpeg', 'image/svg+xml']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- 2. RLS: Allow authenticated users to SELECT (read) QRIS images
-- ============================================================
CREATE POLICY "Anyone can view QRIS images"
ON storage.objects
FOR SELECT
USING (bucket_id = 'qris-images');

-- 3. RLS: Only authenticated users can UPLOAD QRIS images
-- ============================================================
CREATE POLICY "Authenticated users can upload QRIS images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'qris-images'
  AND auth.role() = 'authenticated'
);

-- 4. RLS: Only owners can UPDATE/DELETE QRIS images
-- ============================================================
CREATE POLICY "Owners can update QRIS images"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'qris-images'
  AND auth.role() = 'authenticated'
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);

CREATE POLICY "Owners can delete QRIS images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'qris-images'
  AND auth.role() = 'authenticated'
  AND (SELECT role FROM public.users WHERE id = auth.uid()) = 'owner'
);

-- 5. UPDATE SEED DATA with Supabase Storage public URLs
-- ============================================================
-- After uploading images to the bucket, the public URL format is:
--   {SUPABASE_URL}/storage/v1/object/public/qris-images/{filename}
-- Update the placeholder URL with the actual Supabase project URL.
UPDATE public.businesses
SET qris_image_url = 'https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_1_qris.svg'
WHERE name = 'Agen Minuman Alkali';

UPDATE public.businesses
SET qris_image_url = 'https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_2_qris.svg'
WHERE name = 'Teh Solo';

UPDATE public.businesses
SET qris_image_url = 'https://YOUR-PROJECT.supabase.co/storage/v1/object/public/qris-images/business_3_qris.svg'
WHERE name = 'Warung Kopi';
