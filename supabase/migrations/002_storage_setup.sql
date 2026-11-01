-- ============================================================
-- Supabase Storage Setup for Menu Images
-- ============================================================

-- 1. Buat bucket 'products' untuk foto menu jika belum ada
INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Kebijakan RLS agar gambar bisa dilihat secara publik
DROP POLICY IF EXISTS "Public can view product images" ON storage.objects;
CREATE POLICY "Public can view product images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'products');

-- 3. Kebijakan RLS agar pengguna terautentikasi (Admin/Kasir) bisa mengunggah gambar
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
CREATE POLICY "Authenticated users can upload product images"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'products');

-- 4. Kebijakan RLS agar pengguna terautentikasi bisa memperbarui gambar
DROP POLICY IF EXISTS "Authenticated users can update product images" ON storage.objects;
CREATE POLICY "Authenticated users can update product images"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'products');

-- 5. Kebijakan RLS agar pengguna terautentikasi bisa menghapus gambar
DROP POLICY IF EXISTS "Authenticated users can delete product images" ON storage.objects;
CREATE POLICY "Authenticated users can delete product images"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'products');

