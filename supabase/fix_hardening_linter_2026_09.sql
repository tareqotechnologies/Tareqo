-- ============================================================================
-- FIX DE PRODUÇÃO — Hardening de storage + funções expostas (linter Supabase)
-- ============================================================================
-- Corrige os warnings do database linter observados em 16/09/2026:
--
--  [0025] public_bucket_allows_listing
--    → bucket público `product-images` tinha policy SELECT ampla
--      (bucket_id = 'product-images'), permitindo LISTAR todos os arquivos.
--      O app nunca lista (Image.network no path exato de products.image_path)
--      — a policy passa a aceitar SOMENTE o objeto cujo nome exato é
--      conhecido: GET por URL pública continua, LIST fica vazio.
--
--  [0029] authenticated_security_definer_function_executable
--    → triggers e helpers internos que o app NUNCA chama via /rest/v1/rpc
--      perdem EXECUTE (set_record_store_id, log_audit_entry, enforce_*_limit,
--      get_next_*_number, mfa_enforced_for_user, mfa_verified_factor_count,
--      mfa_satisfied etc.). Nenhum deles é citado por uma policy RLS: a
--      execução é INTERNA (trigger, corpo de outra função), que não depende
--      do grant de EXECUTE do chamador.
--
--    ⚠️ EXCEÇÃO — os 5 helpers citados DENTRO de expressões de policy RLS
--      (is_my_store, is_tenant_owner, is_manager_of_store,
--      is_store_employee_active, mfa_ok) mantêm o EXECUTE de authenticated:
--      a policy é avaliada com os privilégios do papel que CONSULTA a tabela
--      (SECURITY DEFINER muda os privilégios dentro do corpo da função, não
--      o direito de chamá-la). Revogar o EXECUTE deles quebra TODA
--      leitura/escrita das tabelas cujas policies os citam com
--      42501 "permission denied for function". O WARN 0029 remanescente
--      desses helpers + das RPCs do app é aceito de propósito — a superfície
--      são guards booleanas e as RPCs com guarda interna.
--    ⚠️ is_super_admin() também fica exposta de propósito: o app chama
--      rpc('is_super_admin') no boot do painel admin e ela só devolve um
--      boolean da própria sessão (sem dados).
--
--  Bônus: rls_auto_enable() perde o EXECUTE de anon/authenticated. Ela FICA
--  no banco: o event trigger ensure_rls depende dela para ligar RLS
--  automaticamente em toda tabela nova em public (proteção recomendada pelo
--  próprio Supabase). O DROP quebraria o event trigger; a revogação satisfaz
--  o linter (não é API do app — nunca chamada via /rest/v1/rpc).
--
--  (*) get_cash_flow/get_sales_report/get_dashboard_kpis/get_audit_log etc.:
--      expostos de propósito — o app os consome; as guardas internas
--      (is_my_store/is_manager_of_store/is_super_admin/mfa_ok) são a
--      autoridade.
--
-- IDEMPOTENTE: DROP/CREATE POLICY + REVOKE/GRANT (no-op se já aplicado).
--
-- Como rodar: Supabase Dashboard → SQL Editor → colar este arquivo → Run.
-- Revalidar com: SUPABASE_DB_URL='...' bash scripts/sql_check_live.sh
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. [0025] Leitura do bucket SEM listing
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS product_images_public_read ON storage.objects;
CREATE POLICY product_images_public_read ON storage.objects
  FOR SELECT USING (
    bucket_id = 'product-images'
    AND name = ((storage.foldername(name))[1] || '/' ||
                (storage.foldername(name))[2])
  );

-- ---------------------------------------------------------------------------
-- 2. [0029] REVOKE EXECUTE das funções internas (não-API, fora de policies)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    -- Triggers (nunca chamados direto pelo app).
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_record_store_id() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_tenant_user_id() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_store_tenant() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_tenant_owner() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_employee_tenant() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_employee_attendance_actor() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_invoice_number() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_custom_invoice_number() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_quotation_number() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_decided_by() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.set_plan_request_tenant() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.log_audit_entry() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.prevent_scope_change() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.prevent_scope_change(text) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.enforce_store_limit() FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.enforce_employee_limit() FROM anon, authenticated';
    -- Helpers chamados só dentro de RPCs SECURITY DEFINER / triggers (não são
    -- API e NÃO aparecem em nenhuma policy RLS — ver varredura do corpo das
    -- policies: apenas is_my_store/is_tenant_owner/is_manager_of_store/
    -- is_store_employee_active/mfa_ok/is_super_admin são citados lá).
    -- TODOS os overloads: bases antigas podem ter assinaturas legadas
    -- (ex.: lock_products_or_raise com 4 args) — a guarda do check 42 é por
    -- NOME e aponta qualquer overload exposto.
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.lock_products_or_raise(jsonb, text, boolean) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.lock_products_or_raise(jsonb, text, uuid, boolean) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_next_invoice_number(text) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_next_custom_invoice_number(text) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.get_next_quotation_number(text) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.mfa_enforced_for_user(uuid) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.mfa_verified_factor_count(uuid) FROM anon, authenticated';
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.mfa_satisfied(uuid) FROM anon, authenticated';
    -- ⚠️ NÃO revogar aqui: is_my_store / is_tenant_owner / is_manager_of_store
    -- / is_store_employee_active / mfa_ok (citados em policies RLS) nem
    -- is_super_admin() (rpc do painel admin) — ver cabeçalho.
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2.5 CORRETIVO (obrigatório se a versão anterior deste fix já rodou):
-- devolve o EXECUTE de authenticated aos 5 helpers usados dentro de
-- expressões de policy RLS. Expressões de policy rodam com os privilégios do
-- papel que consulta a tabela — sem o grant, toda leitura/escrita das tabelas
-- protegidas por esses helpers falha com 42501 "permission denied for
-- function" (o linter 0029 deixa de apontá-los justamente porque o EXECUTE
-- foi revogado — a ausência do WARN NÃO é sinal de que a revogação foi
-- inofensiva).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    IF to_regprocedure('public.is_my_store(text)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_my_store(text) TO authenticated';
    END IF;
    IF to_regprocedure('public.is_tenant_owner(text)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_tenant_owner(text) TO authenticated';
    END IF;
    IF to_regprocedure('public.is_manager_of_store(text)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_manager_of_store(text) TO authenticated';
    END IF;
    IF to_regprocedure('public.is_store_employee_active(text, uuid)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.is_store_employee_active(text, uuid) TO authenticated';
    END IF;
    IF to_regprocedure('public.mfa_ok(uuid)') IS NOT NULL THEN
      EXECUTE 'GRANT EXECUTE ON FUNCTION public.mfa_ok(uuid) TO authenticated';
    END IF;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2.6 [0029] rls_auto_enable(): RESTINGE, não remova.
-- O event trigger ensure_rls (DDL de CREATE TABLE) depende dela para ligar
-- RLS em toda tabela nova em public — DROP FUNCTION falha com dependency
-- error e removeria a proteção. A revogação satisfaz o linter 0029: event
-- trigger dispara pelo sistema, sem depender do grant do chamador (mesmo
-- mecanismo das trigger functions comuns).
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF to_regprocedure('public.rls_auto_enable()') IS NOT NULL THEN
    EXECUTE 'REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM anon, authenticated';
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Verificação
--    (a) policy do bucket sem listing;
--    (b) funções internas RESTRICTAS executáveis por authenticated → 0 linhas;
--    (c) helpers de policy SEM EXECUTE de authenticated → 0 linhas (o app
--        quebraria com 42501 — ver seção 2.5).
-- ---------------------------------------------------------------------------
SELECT policyname, qual FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects'
  AND policyname = 'product_images_public_read';

-- (b) Esperado: 0 linhas.
SELECT p.proname AS funcao_interna_restrita
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'set_record_store_id','set_tenant_user_id','set_store_tenant',
    'set_tenant_owner','set_employee_tenant','set_employee_attendance_actor',
    'set_invoice_number','set_custom_invoice_number','set_quotation_number',
    'set_decided_by','set_plan_request_tenant','log_audit_entry',
    'prevent_scope_change','enforce_store_limit','enforce_employee_limit',
    'lock_products_or_raise','get_next_invoice_number',
    'get_next_custom_invoice_number','get_next_quotation_number',
    'mfa_enforced_for_user','mfa_verified_factor_count','mfa_satisfied'
  )
  AND has_function_privilege('authenticated', p.oid, 'EXECUTE');

-- (c) Esperado: 0 linhas.
SELECT p.proname AS helper_de_policy_sem_execute
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'is_my_store','is_tenant_owner','is_manager_of_store',
    'is_store_employee_active','mfa_ok','is_super_admin'
  )
  AND NOT has_function_privilege('authenticated', p.oid, 'EXECUTE');

-- (d) rls_auto_enable: se existir (event trigger ensure_rls), NÃO pode ser
--     executável por authenticated.
SELECT p.proname AS utilitaria_remanescente
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'rls_auto_enable'
  AND has_function_privilege('authenticated', p.oid, 'EXECUTE');
