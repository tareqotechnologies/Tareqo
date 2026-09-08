-- Cotações/orçamentos (add-on `ao_quotation`).
-- Documento por loja com número sequencial DENTRO da loja (MAX+1 sob
-- advisory lock — mesmo padrão das vendas/facturas de cobrança e das
-- facturas personalizadas). O corpo completo (items snapshot, estado,
-- desconto, validade) é guardado como JSONB: a cotação é um documento.
--
-- RLS: dono + funcionários da loja leem/escrevem via `is_my_store`;
-- UPDATE é necessário para as transições de estado (rascunho → enviada →
-- aceite/rejeitada); DELETE só de registros PRÓPRIOS (o app não apaga).

CREATE TABLE IF NOT EXISTS public.quotations (
  id                TEXT PRIMARY KEY,
  user_id           UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id          TEXT NOT NULL,
  quotation_number  BIGINT NOT NULL DEFAULT 0,
  payload           JSONB NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Duas cotações da MESMA loja nunca recebem o mesmo número.
  CONSTRAINT uq_quotations_store_number UNIQUE (store_id, quotation_number)
);

CREATE INDEX IF NOT EXISTS idx_quotations_store
  ON public.quotations (store_id, created_at DESC);

-- user_id = usuário logado (reforço anti-forja; função do schema base).
DROP TRIGGER IF EXISTS trg_quotations_user_id ON public.quotations;
CREATE TRIGGER trg_quotations_user_id
  BEFORE INSERT ON public.quotations
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

-- store_id = loja do usuário (se o valor enviado não for da loja dele,
-- cai para a primeira loja acessível — função do schema base).
DROP TRIGGER IF EXISTS trg_quotations_store_id ON public.quotations;
CREATE TRIGGER trg_quotations_store_id
  BEFORE INSERT ON public.quotations
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

-- Número sequencial da cotação DENTRO da loja, com advisory lock por loja
-- (previne condição de corrida — duas escritas concorrentes nunca recebem
-- o mesmo número). Número 0 no payload = atribuir; número já preenchido
-- (restauração) é preservado.
CREATE OR REPLACE FUNCTION public.get_next_quotation_number(
  p_store_id TEXT
)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_next BIGINT;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtext('quotation_number'),
    hashtext(p_store_id)
  );

  SELECT COALESCE(MAX(quotation_number), 0) + 1
  INTO v_next
  FROM public.quotations
  WHERE store_id = p_store_id;

  RETURN v_next;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_quotation_number()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.quotation_number = 0 THEN
    NEW.quotation_number := public.get_next_quotation_number(NEW.store_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_quotations_number ON public.quotations;
CREATE TRIGGER trg_quotations_number
  BEFORE INSERT ON public.quotations
  FOR EACH ROW EXECUTE FUNCTION public.set_quotation_number();

-- RLS
ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS quotations_select ON public.quotations;
CREATE POLICY quotations_select ON public.quotations
  FOR SELECT USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS quotations_insert ON public.quotations;
CREATE POLICY quotations_insert ON public.quotations
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS quotations_update ON public.quotations;
CREATE POLICY quotations_update ON public.quotations
  FOR UPDATE USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS quotations_delete ON public.quotations;
CREATE POLICY quotations_delete ON public.quotations
  FOR DELETE USING (auth.uid() = user_id);