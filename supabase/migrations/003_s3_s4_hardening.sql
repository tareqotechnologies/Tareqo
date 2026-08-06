-- ============================================================================
-- 003 — Endurecimento do schema: anti-spam de tenants pendentes (S3) e
--       trilha de auditoria das decisões de admin (S4).
--
-- Origem: auditoria forense (docs/pt/AUDIT_REPORT.md, itens S3 e S4).
-- As mesmas alterações já estão aplicadas em supabase/schema.sql; este
-- ficheiro é o delta idempotente para aplicar no projeto de PRODUÇÃO.
--
-- ⚠️ Executar no SQL Editor do dashboard do projeto (supabase.com).
-- Seguro reexecutar (ADD COLUMN IF NOT EXISTS / CREATE UNIQUE INDEX IF NOT
-- EXISTS / CREATE OR REPLACE FUNCTION / DROP TRIGGER IF EXISTS + CREATE).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Guarda prévia (S3): se existirem duplicados pendentes na base de
-- produção, o CREATE UNIQUE INDEX falharia com erro críptico. Detectamos
-- antes e abortamos com mensagem clara para resolução manual.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  dup_owners INTEGER;
BEGIN
  SELECT count(*) INTO dup_owners
  FROM (
    SELECT owner_user_id
    FROM public.tenants
    WHERE status = 'pending'
    GROUP BY owner_user_id
    HAVING count(*) > 1
  ) duplicates;
  IF dup_owners > 0 THEN
    RAISE EXCEPTION
      'S3: % utilizador(es) têm MAIS DE UM tenant pendente. Resolva os duplicados (mantenha o mais antigo e rejeite os restantes) antes de aplicar esta migração.',
      dup_owners;
  END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- S3 — Anti-spam: no máximo UM tenant PENDENTE por utilizador (impede DoS
-- na fila de aprovação manual + abuso de signup). Aprovados/rejeitados
-- não contam.
-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS idx_tenants_one_pending
  ON public.tenants (owner_user_id) WHERE status = 'pending';

-- ---------------------------------------------------------------------------
-- S4 — Trilha de auditoria das decisões de admin: regista QUEM aprovou ou
-- rejeitou cada tenant/upgrade. A coluna `decided_by` é carimbada com o
-- auth.uid() do super admin no momento da decisão (pending → approved /
-- rejected), via trigger. O RLS já restringe o UPDATE a super admins.
-- ---------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.tenants
  ADD COLUMN IF NOT EXISTS decided_by UUID;
ALTER TABLE IF EXISTS public.plan_requests
  ADD COLUMN IF NOT EXISTS decided_by UUID;

CREATE OR REPLACE FUNCTION public.set_decided_by()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Só carimba quando a decisão acontece (pending → approved/rejected) e
  -- há sessão (JWT). Decisões repetidas não sobrescrevem o primeiro ator.
  IF auth.uid() IS NOT NULL
     AND NEW.status IN ('approved', 'rejected')
     AND OLD.status = 'pending' THEN
    NEW.decided_by := auth.uid();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tenants_decided_by ON public.tenants;
CREATE TRIGGER trg_tenants_decided_by
  BEFORE UPDATE OF status ON public.tenants
  FOR EACH ROW EXECUTE FUNCTION public.set_decided_by();

DROP TRIGGER IF EXISTS trg_plan_requests_decided_by ON public.plan_requests;
CREATE TRIGGER trg_plan_requests_decided_by
  BEFORE UPDATE OF status ON public.plan_requests
  FOR EACH ROW EXECUTE FUNCTION public.set_decided_by();
