-- ============================================================================
-- 006 — RLS: helpers com SECURITY DEFINER (correção da regressão 54001)
-- ============================================================================
-- Diagnóstico (Aug 6, 2026): num projeto Supabase com schema antigo/misturado,
-- SELECTs em varreduras completas (sem WHERE) nas tabelas de negócio
-- (products, sales, stores, store_employees, tenants, ...) rebentavam com
--
--   ERROR: 54001: stack depth limit exceeded  (max_stack_depth 2048kB)
--
-- Causa: as políticas RLS de `stores`/`tenants`/`store_employees` chamam
-- `public.is_tenant_owner()` e `public.is_my_store()`, que POR SUA VEZ
-- consultam essas MESMAS tabelas — um ciclo entre tabelas. Conforme o plano
-- de execução/versão do Postgres (Supabase cloud), o OR das políticas não
-- curto-circuita e a recursão estoura a pilha. Com SECURITY DEFINER + 
-- `search_path` fixado, as consultas internas ignoram o RLS e o ciclo fica
-- impossível por construção (mesmo padrão já usado por `is_super_admin` e
-- pelas RPCs do dinheiro).
--
-- Segurança: as funções apenas devolvem um BOOLEAN sobre um id fornecido
-- pelo chamador (dono do tenant? acesso à loja?) — não exfiltram dados.
--
-- ⚠️ Idempotente (CREATE OR REPLACE) — pode reexecutar à vontade.
-- ⚠️ Depois desta migração, recomendamos reaplicar o `supabase/schema.sql`
--    completo: o projeto pode também estar a faltar as RPCs atômicas
--    (process_sale/register_debt/settle_debt/process_purchase e
--    create_employee_account), que não existiam no schema antigo.
-- ============================================================================

-- Helper: o usuário é dono do tenant [target_tenant_id]?
CREATE OR REPLACE FUNCTION public.is_tenant_owner(target_tenant_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.tenants t
    WHERE t.id = target_tenant_id AND t.owner_user_id = auth.uid()
  );
$$;

-- Helper: o usuário tem acesso à loja [target_store_id]? (dono do tenant
-- vale para todas as lojas; funcionário vale para a loja do vínculo).
CREATE OR REPLACE FUNCTION public.is_my_store(target_store_id TEXT)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.stores s
    WHERE s.id = target_store_id
      AND (
        public.is_tenant_owner(s.tenant_id)
        OR EXISTS (
          SELECT 1 FROM public.store_employees e
          WHERE e.store_id = s.id AND e.user_id = auth.uid()
        )
      )
  );
$$;
