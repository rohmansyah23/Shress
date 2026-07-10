-- ============================================================
-- Sheress - Add more allowed MIME types for QRIS bucket
-- ============================================================

UPDATE storage.buckets
SET allowed_mime_types = ARRAY[
  'image/png',
  'image/jpeg',
  'image/svg+xml',
  'image/webp',
  'image/heic',
  'image/heif'
]::text[]
WHERE id = 'qris-images';
