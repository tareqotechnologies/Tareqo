-- ============================================================================
-- SQL para criar notificação de teste no Supabase
-- ============================================================================
-- Copie e cole este script no SQL Editor do Supabase e clique em "Run"
-- https://supabase.com/dashboard/project/dotklbpqmlnhcdifiukd/sql/new
-- ============================================================================

-- 1. Verificar se existe um tenant aprovado
SELECT id, owner_user_id, business_name, status 
FROM public.tenants 
WHERE status = 'approved' 
LIMIT 5;

-- 2. Criar notificação de teste (substitua 'SEU_TENANT_ID' pelo ID real)
-- Primeiro, obtenha o tenant_id do resultado acima e substitua abaixo:

DO $$
DECLARE
  v_tenant_id TEXT;
  v_tenant_name TEXT;
BEGIN
  -- Buscar o primeiro tenant aprovado
  SELECT id, business_name INTO v_tenant_id, v_tenant_name
  FROM public.tenants 
  WHERE status = 'approved' 
  LIMIT 1;
  
  IF v_tenant_id IS NULL THEN
    RAISE NOTICE 'Nenhum tenant aprovado encontrado. Crie um tenant primeiro.';
    RETURN;
  END IF;
  
  -- Criar notificação de teste 1: Factura gerada
  INSERT INTO public.invoice_notifications (id, tenant_id, type, title, body, is_read)
  VALUES (
    'test_notif_' || gen_random_uuid()::text,
    v_tenant_id,
    'invoiceGenerated',
    'Nova factura gerada',
    'Factura Agosto 2026 no valor de 5,000.00 MZN foi gerada para ' || v_tenant_name || '.',
    false
  );
  
  -- Criar notificação de teste 2: Factura para vencer
  INSERT INTO public.invoice_notifications (id, tenant_id, type, title, body, is_read)
  VALUES (
    'test_notif_' || gen_random_uuid()::text,
    v_tenant_id,
    'invoiceDueSoon',
    'Factura para vencer',
    'A factura de Julho 2026 vence em 3 dias. Regularize o pagamento.',
    false
  );
  
  -- Criar notificação de teste 3: Factura paga
  INSERT INTO public.invoice_notifications (id, tenant_id, type, title, body, is_read)
  VALUES (
    'test_notif_' || gen_random_uuid()::text,
    v_tenant_id,
    'invoicePaid',
    'Factura paga',
    'A factura de Junho 2026 foi registada como paga. Obrigado!',
    true
  );
  
  RAISE NOTICE '✅ 3 notificações de teste criadas para o tenant: % (%)', v_tenant_name, v_tenant_id;
END $$;

-- 3. Verificar as notificações criadas
SELECT 
  id,
  tenant_id,
  type,
  title,
  body,
  is_read,
  created_at
FROM public.invoice_notifications
WHERE id LIKE 'test_notif_%'
ORDER BY created_at DESC;

-- ============================================================================
-- OPCIONAL: Criar factura de teste associada à notificação
-- ============================================================================

DO $$
DECLARE
  v_tenant_id TEXT;
  v_plan_id TEXT;
  v_invoice_id TEXT;
BEGIN
  SELECT t.id, t.plan_id INTO v_tenant_id, v_plan_id
  FROM public.tenants t
  WHERE t.status = 'approved'
  LIMIT 1;
  
  IF v_tenant_id IS NULL THEN
    RAISE NOTICE 'Nenhum tenant aprovado encontrado.';
    RETURN;
  END IF;
  
  -- Criar factura de teste
  v_invoice_id := 'test_inv_' || gen_random_uuid()::text;
  
  INSERT INTO public.invoices (id, tenant_id, plan_id, amount_cents, status, due_date, period)
  VALUES (
    v_invoice_id,
    v_tenant_id,
    v_plan_id,
    500000, -- 5,000.00 MZN (em centavos)
    'pending',
    now() + interval '7 days',
    'Agosto 2026'
  );
  
  RAISE NOTICE '✅ Factura de teste criada: % (5,000.00 MZN)', v_invoice_id;
END $$;

-- Verificar facturas criadas
SELECT 
  id,
  number,
  tenant_id,
  amount_cents / 100.0 as amount_mzn,
  status,
  period,
  due_date,
  created_at
FROM public.invoices
WHERE id LIKE 'test_inv_%'
ORDER BY created_at DESC;
