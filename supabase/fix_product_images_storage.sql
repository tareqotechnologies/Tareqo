-- ============================================================================
-- FIX DE PRODUÇÃO — Fotos de produto (Supabase Storage)
-- ============================================================================
-- Sintoma no APK: ao salvar produto com foto aparece
--   "Produto atualizado! (sem permissão de armazenamento)"
--   (en: "Product updated! (no storage permission)")
-- e a imagem NÃO é gravada — o app segue funcionando, só a foto falha.
--
-- CAUSA RAIZ: o bucket `product-images` (ou suas políticas RLS) não existe
-- no banco de produção. O esquema do app está CORRETO:
--   • Cliente sobe em `<storeId>/<productId>.jpg` — o PRIMEIRO segmento é o
--     store_id (`lib/data/services/product_image_store_supabase.dart`).
--   • Políticas de escrita validam `is_my_store((storage.foldername(name))[1])`
--     (`supabase/schema.sql` FOTOS DE PRODUTO / `upgrade.sql` sec. 27).
-- Sem bucket/policies, o Storage nega o upload (403 — "new row violates
-- row-level security policy" / bucket not found) e o app salva o produto
-- com o aviso de foto não enviada.
--
-- Nota: o aviso não se refere a permissão do CELULAR (câmera/arquivos) —
-- refere-se à permissão NO SERVIDOR (RLS do Storage).
--
-- IDEMPOTENTE: INSERT ON CONFLICT DO NOTHING + DROP/CREATE POLICY.
-- Pode ser executado quantas vezes quiser (SQL Editor do Supabase).
--
-- Como rodar: Supabase Dashboard → SQL Editor → New query → colar este
-- arquivo inteiro → Run. Em seguida revalidar com:
--   SUPABASE_DB_URL='postgresql://...' bash scripts/sql_check_live.sh
-- ============================================================================

-- 1. Bucket PÚBLICO `product-images` (no-op se já existir).
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Garante que o bucket existente é PÚBLICO (instalações antigas podem ter
-- criado privado; sem public=TRUE a URL do CDN não serve a imagem).
UPDATE storage.buckets SET public = TRUE WHERE id = 'product-images';

-- 2. Leitura (URL via CDN — products.image_path guarda essa URL).
--    O SELECT também é exigido pelo upload com `upsert: true`; restringir
--    à própria loja evita expor a listagem de outras lojas e mantém o
--    upsert funcionando (a URL pública do CDN não passa por esta policy).
DROP POLICY IF EXISTS product_images_public_read ON storage.objects;
CREATE POLICY product_images_public_read ON storage.objects
  FOR SELECT USING (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

-- 3. Escrita SÓ na pasta da loja do usuário autenticado:
--    path `<storeId>/<productId>.jpg` → (foldername(name))[1] = storeId.
DROP POLICY IF EXISTS product_images_auth_insert ON storage.objects;
CREATE POLICY product_images_auth_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

DROP POLICY IF EXISTS product_images_auth_update ON storage.objects;
CREATE POLICY product_images_auth_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

DROP POLICY IF EXISTS product_images_auth_delete ON storage.objects;
CREATE POLICY product_images_auth_delete ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

-- 4. Verificação rápida (opcional — resultado esperado: 4 policies + 1 bucket).
SELECT id, public FROM storage.buckets WHERE id = 'product-images';
SELECT policyname, cmd FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
  AND policyname LIKE 'product_images%'
ORDER BY policyname;
