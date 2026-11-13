-- ============================================================================
-- fix_product_images_rls_2026_11.sql — "sem permissão de armazenamento"
-- (403/RLS) ao salvar foto de produto
-- ============================================================================
-- SINTOMA: o cadastro/edição de produto conclui, mas o snackbar mostra
-- "Produto adicionado! (sem permissão de armazenamento)" e a foto não sobe.
--
-- CAUSA RAIZ: o cliente sobe a foto com `upsert: true` e o Storage exige
-- SELECT + INSERT + UPDATE nesse modo (ele verifica se o objeto já existe
-- antes do INSERT ... ON CONFLICT DO UPDATE). A política
-- `product_images_public_read` tentava evitar o listing do linter com
-- `name = foldername(name)[1] || '/' || foldername(name)[2]`, mas
-- `storage.foldername` EXCLUI o nome do arquivo: para `<storeId>/<prod>.jpg`
-- o índice [2] é NULL, a expressão inteira vira NULL e a policy negava
-- TODA leitura. Resultado: todo upload com upsert levava 403, mesmo com
-- INSERT/UPDATE corretos e com `is_my_store` funcionando (o INSERT do
-- produto passa porque a policy também aceita `auth.uid() = user_id`).
--
-- CORREÇÃO: a leitura usa a MESMA guarda `is_my_store` da escrita. O upsert
-- volta a funcionar; a listagem do Storage API só expõe objetos da própria
-- loja; o GET pela URL pública continua no CDN (bucket público, não passa
-- por esta policy).
--
-- IDEMPOTENTE — pode rodar quantas vezes quiser.
-- Como rodar: Supabase Dashboard → SQL Editor → colar → Run.
-- ============================================================================

BEGIN;

-- 1. Bucket público (cria se não existir; garante public = TRUE se já existir).
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', TRUE)
ON CONFLICT (id) DO UPDATE SET public = TRUE;

-- 2. Helper usado nas policies precisa de EXECUTE para o papel autenticado
--    (as policies da tabela public.products também dependem dele).
GRANT EXECUTE ON FUNCTION public.is_my_store(text) TO authenticated;

-- 3. SELECT — obrigatório para o upsert do Storage. Restrito à loja do
--    usuário (primeiro segmento do caminho = store_id).
DROP POLICY IF EXISTS product_images_public_read ON storage.objects;
CREATE POLICY product_images_public_read ON storage.objects
  FOR SELECT USING (
    bucket_id = 'product-images'
    AND public.is_my_store((storage.foldername(name))[1])
  );

-- 4. Escrita — recriadas por segurança (idempotente). O caminho é
--    `<storeId>/<productId>.jpg`; um prefixo fixo ('products/...') seria
--    negado porque foldername[1] deixaria de ser o store_id.
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

COMMIT;

-- ============================================================================
-- VERIFICAÇÃO (resultado esperado: 4 políticas, bucket public = TRUE)
-- ============================================================================
SELECT id, name, public FROM storage.buckets WHERE id = 'product-images';

SELECT policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
  AND policyname LIKE 'product_images_%'
ORDER BY policyname;

-- EXECUTE de is_my_store para authenticated (esperado: true).
SELECT has_function_privilege(
  'authenticated', 'public.is_my_store(text)', 'EXECUTE'
) AS is_my_store_executavel;
