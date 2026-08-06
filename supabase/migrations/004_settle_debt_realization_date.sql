-- ============================================================================
-- 004 — settle_debt: data de REALIZAÇÃO da pendência vinculada
-- ----------------------------------------------------------------------------
-- Alinhamento entre os modos local (SQLite) e SaaS (Supabase) na quitação de
-- fiado (auditoria Aug 6):
--
--   ANTES:  o RPC `settle_debt` marcava `status = 'paid'` na pendência
--           vinculada, MAS mantinha a `date` original (data do registro da
--           pendência). O datasource SQLite local (`markAsPaid`) carimba
--           `date = now()` — o caixa realizado reconhece o dinheiro quando
--           ele ENTRA. Os dois modos divergiam no período de fluxo de caixa.
--   DEPOIS: o RPC também carimba `date = now()` na pendência vinculada —
--           mesma semântica local. GetCashFlowUseCase e relatórios passam a
--           contar o recebimento no período da quitação em AMBOS os modos.
--
-- Idempotente: CREATE OR REPLACE FUNCTION — pode reexecutar à vontade.
-- ⚠️ Executar no SQL Editor do dashboard do projeto (supabase.com) ou via
--    `supabase db push`. O supabase/schema.sql já contém esta alteração.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.settle_debt(p_debt_id text, p_store text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_debt public.debts%ROWTYPE;
  v_lang text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sessão necessária para quitar o fiado.';
  END IF;
  IF NOT public.is_my_store(p_store) THEN
    RAISE EXCEPTION 'A loja % não pertence ao usuário logado.', p_store;
  END IF;
  SELECT t.language INTO v_lang
  FROM public.stores s
  JOIN public.tenants t ON t.id = s.tenant_id
  WHERE s.id = p_store;
  IF v_lang IS NULL OR v_lang NOT IN ('pt', 'en') THEN
    v_lang := 'pt';
  END IF;

  SELECT * INTO v_debt FROM public.debts
  WHERE id = p_debt_id AND store_id = p_store;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Dívida % não encontrada na loja %.', p_debt_id, p_store;
  END IF;

  -- Idempotência: retry após sucesso (ex.: timeout no cliente) não
  -- duplica a entrada no caixa.
  IF v_debt.is_paid THEN
    RETURN;
  END IF;

  -- 1. Baixa da dívida (guarda de concorrência: só baixa se ainda
  --    pendente — se outra chamada já quitou, retorna sem efeito).
  UPDATE public.debts SET is_paid = TRUE, paid_at = now()
  WHERE id = p_debt_id AND store_id = p_store
    AND NOT is_paid;
  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- 2. Pendência vinculada (debt_id): marca a MESMA transação como paga
  --    (nunca cria duplicata no caixa) e carimba a DATA DE REALIZAÇÃO
  --    (`date = now()`) — mesma semântica do datasource SQLite local
  --    (markAsPaid): o caixa realizado reconhece o dinheiro quando ele
  --    ENTRA, não quando a pendência foi registrada (auditoria Aug 6 —
  --    alinhamento entre os modos local e SaaS).
  UPDATE public.financial_transactions
  SET status = 'paid', date = now()
  WHERE debt_id = p_debt_id AND store_id = p_store
    AND status = 'pending';

  -- 3. Fiado antigo SEM nenhuma transação vinculada (pendente ou paga):
  --    registra a entrada direto. Se já existir uma transação vinculada
  --    (mesmo paga), nada é feito — idempotente. O id usa o sufixo
  --    '_settle' para nunca colidir com a pendência do register_debt
  --    ('t' || debt_id) nem com ids do AppIds ('t<ts>_<hex>').
  IF NOT EXISTS (
    SELECT 1 FROM public.financial_transactions
    WHERE debt_id = p_debt_id AND store_id = p_store
  ) THEN
    INSERT INTO public.financial_transactions
      (id, user_id, store_id, description, amount, type, category,
       date, status, debt_id)
    VALUES ('t' || p_debt_id || '_settle', v_uid, p_store,
            CASE WHEN v_lang = 'en'
                 THEN 'Credit received — ' || v_debt.person_name
                 ELSE 'Recebimento de fiado — ' || v_debt.person_name END,
            v_debt.amount, 'income',
            CASE WHEN v_lang = 'en' THEN 'Credit' ELSE 'Fiado' END,
            now(), 'paid', p_debt_id);
  END IF;
END;
$$;
