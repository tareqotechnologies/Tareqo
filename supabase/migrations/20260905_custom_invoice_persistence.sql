-- Facturas personalizadas (add-on `ao_custom_invoice`).
-- Documento por loja com número sequencial DENTRO da loja (MAX+1 sob
-- advisory lock — mesmo padrão das vendas/facturas de cobrança). O corpo
-- completo (items snapshot, descontos, notas, pagamento) é guardado como
-- JSONB: a factura é um documento, não um agregado com RPCs de dinheiro.
--
-- RLS: dono + funcionários da loja leem/escrevem via `is_my_store`;
-- DELETE só de registros PRÓPRIOS (o app não apaga — zero impacto).

CREATE TABLE IF NOT EXISTS public.custom_invoices (
  id             TEXT PRIMARY KEY,
  user_id        UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  store_id       TEXT NOT NULL,
  invoice_number BIGINT NOT NULL DEFAULT 0,
  payload        JSONB NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Duas facturas da MESMA loja nunca recebem o mesmo número.
  CONSTRAINT uq_custom_invoices_store_number UNIQUE (store_id, invoice_number)
);

CREATE INDEX IF NOT EXISTS idx_custom_invoices_store
  ON public.custom_invoices (store_id, created_at DESC);

-- user_id = usuário logado (reforço anti-forja; função do schema base).
DROP TRIGGER IF EXISTS trg_custom_invoices_user_id
  ON public.custom_invoices;
CREATE TRIGGER trg_custom_invoices_user_id
  BEFORE INSERT ON public.custom_invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_tenant_user_id();

-- store_id = loja do usuário (se o valor enviado não for da loja dele,
-- cai para a primeira loja acessível — função do schema base).
DROP TRIGGER IF EXISTS trg_custom_invoices_store_id
  ON public.custom_invoices;
CREATE TRIGGER trg_custom_invoices_store_id
  BEFORE INSERT ON public.custom_invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_record_store_id();

-- Número sequencial da factura DENTRO da loja, com advisory lock por loja
-- (previne condição de corrida — duas escritas concorrentes nunca recebem
-- o mesmo número). Número 0 no payload = atribuir; número já preenchido
-- (restauração) é preservado.
CREATE OR REPLACE FUNCTION public.get_next_custom_invoice_number(
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
    hashtext('custom_invoice_number'),
    hashtext(p_store_id)
  );

  SELECT COALESCE(MAX(invoice_number), 0) + 1
  INTO v_next
  FROM public.custom_invoices
  WHERE store_id = p_store_id;

  RETURN v_next;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_custom_invoice_number()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.invoice_number = 0 THEN
    NEW.invoice_number := public.get_next_custom_invoice_number(NEW.store_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_custom_invoices_number
  ON public.custom_invoices;
CREATE TRIGGER trg_custom_invoices_number
  BEFORE INSERT ON public.custom_invoices
  FOR EACH ROW EXECUTE FUNCTION public.set_custom_invoice_number();

-- RLS
ALTER TABLE public.custom_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS custom_invoices_select ON public.custom_invoices;
CREATE POLICY custom_invoices_select ON public.custom_invoices
  FOR SELECT USING (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS custom_invoices_insert ON public.custom_invoices;
CREATE POLICY custom_invoices_insert ON public.custom_invoices
  FOR INSERT WITH CHECK (
    auth.uid() = user_id OR public.is_my_store(store_id)
  );

DROP POLICY IF EXISTS custom_invoices_delete ON public.custom_invoices;
CREATE POLICY custom_invoices_delete ON public.custom_invoices
  FOR DELETE USING (auth.uid() = user_id);
