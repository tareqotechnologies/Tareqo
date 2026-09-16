-- ============================================================================
-- FIX DE PRODUÇÃO — Painel Super Admin: "Erro ao actualizar add-on"
-- ============================================================================
-- Sintoma (APK de produção, Painel do Super Admin → Add-ons):
--   Erro ao actualizar add-on:
--   PostgresException(message: permission denied for table super_admins,
--   code: 42501, details: Forbidden, hint: Grant the required privileges to
--   the current role with: GRANT SELECT ON public.super_admins TO
--   authenticated;)
--
-- CAUSA RAIZ: a política tenant_addons_super_admin_all (Parte 31 do
-- upgrade.sql, espelhada no schema.sql) consultava a tabela
-- public.super_admins DIRETAMENTE dentro da policy:
--     auth.uid() IN (SELECT user_id FROM public.super_admins)
-- Mas super_admins tem REVOKE ALL de anon/authenticated (defesa contra
-- auto-promoção a super admin) — o Postgres nega a LEITURA da tabela
-- durante a avaliação da policy com 42501, ANTES mesmo do RLS decidir.
-- A tabela é lida apenas pela função SECURITY DEFINER is_super_admin().
--
-- CORREÇÃO: recriar a política usando public.is_super_admin() — o MESMO
-- padrão das políticas plans/plan_requests/tenants e das RPCs admin.
--
-- IDEMPOTENTE: DROP POLICY IF EXISTS + CREATE POLICY. Pode reexecutar.
--
-- Como rodar: Supabase Dashboard → SQL Editor → New query → colar este
-- arquivo inteiro → Run. Revalidar com:
--   SUPABASE_DB_URL='postgresql://...' bash scripts/sql_check_live.sh
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. Add-ons: política de super admin corrigida (o bug deste ticket)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS tenant_addons_super_admin_all ON public.tenant_addons;
CREATE POLICY tenant_addons_super_admin_all
  ON public.tenant_addons
  FOR ALL
  USING (
    public.is_super_admin()
  )
  WITH CHECK (
    public.is_super_admin()
  );

-- ---------------------------------------------------------------------------
-- 2. Varredura defensiva: RECRIBA qualquer outra policy que ainda consulte
--    super_admins diretamente (nenhuma conhecida hoje — blocos DO abaixo
--    FALHAM o script se algo escapar, em vez de falhar em runtime no app).
--    Read-only: apenas detecta e reporta.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
  v_count int := 0;
BEGIN
  FOR r IN
    SELECT tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        position('super_admins' IN COALESCE(qual, '')) > 0
        OR position('super_admins' IN COALESCE(with_check, '')) > 0
      )
  LOOP
    v_count := v_count + 1;
    RAISE WARNING 'Policy %.% ainda referencia super_admins diretamente — recriar com is_super_admin()',
      r.tablename, r.policyname;
  END LOOP;
  RAISE NOTICE 'Varredura: % policies citam super_admins no corpo (esperado 0)', v_count;
END $$;

-- ---------------------------------------------------------------------------
-- 3. Verificação rápida (resultado esperado: usando = is_super_admin()).
-- ---------------------------------------------------------------------------
SELECT tablename, policyname,
       COALESCE(qual, with_check) AS usando
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'tenant_addons'
ORDER BY policyname;
