# 19 — Configuração do Supabase de produção (passo a passo)

> **Objetivo:** subir um projeto Supabase de PRODUÇÃO completo em ~20 minutos,
> executando apenas **2 scripts SQL** (+ 1 utilitário). Desde a consolidação de
> Set/2026, o schema inteiro — tabelas, RLS, RPCs, triggers, storage, Realtime,
> add-ons (facturas personalizadas, cotações, gestão de funcionários), billing e
> mensagens admin — vive em **`supabase/schema.sql`**. O `supabase/upgrade.sql`
> contém o MESMO estado final em formato idempotente para bases existentes.
>
> **Antes da consolidação** eram 13 arquivos (schema + upgrade + 7 migrações +
> 3 utilitários) com ordem de aplicação e dependências entre eles. **Agora:**
> instalação nova = 1 script; base existente = 1 script; utilitários à parte.

---

## 0. Panorama dos arquivos (estado atual)

| Arquivo | Quando usar | O que contém |
|---|---|---|
| `supabase/schema.sql` | **Projeto NOVO** (1ª instalação) | Tudo: PARTE 1 (estrutura + RLS + RPCs + storage), PARTE 1.9 (add-ons + billing + admin_messages), PARTE 2 (catálogo de planos). Idempotente, roda em 1 transação |
| `supabase/upgrade.sql` | **Base EXISTENTE** (p.ex. o live atual) | 31 partes idempotentes que levam qualquer versão anterior ao estado atual. **Pode reexecutar à vontade** (aplicação dupla validada no CI) |
| `supabase/promote_super_admin.sql` | Depois do 1º cadastro no app | Promove um e-mail a super admin (papel na tabela `super_admins`) |
| `supabase/cleanup_demo_data.sql` | Opcional (manutenção) | Remove dados de demonstração |
| `supabase/reset_tenant_data.sql` | Opcional (manutenção) | Zera os dados de UM tenant |
| `supabase/test_notification.sql` | Opcional (debug) | Insere notificação de teste |
| `supabase/archived_migrations/` | **NUNCA aplicar** | Histórico das 7 migrações fundidas nos 2 scripts acima |

> **Regra de ouro:** instalação nova → `schema.sql` APENAS. Base existente →
> `upgrade.sql` APENAS. Nunca os dois "por garantia": rodar `schema.sql` numa
> base que já tem dados é seguro (idempotente), mas desnecessário.

---

## 1. Pré-requisitos

- [ ] Conta no [supabase.com](https://supabase.com) (plano conforme a demanda; o free tier serve para validar)
- [ ] Acesso ao repositório (para `env/prod.env`, builds e CI)
- [ ] 20 minutos e o SQL Editor do Supabase à mão

---

## 2. Criar o projeto de produção

1. **supabase.com → New project**;
2. **Name:** `tareqo-prod` (ou o padrão da sua organização);
3. **Database Password:** gere uma forte e **guarde no gerenciador de senhas** — não é usada pelo app, mas é necessária para backup/psql;
4. **Region:** a mais próxima dos usuários (Moçambique → `eu-central-1` ou `af-south-1` costumam ser as menores latências);
5. Aguarde o provisionamento (~2 min) e anote o **Project ref** (ex.: `abcdefghijklmnop`) e a **URL** (`https://<ref>.supabase.co`).

> ⚠️ **Nunca reutilize** o projeto de desenvolvimento para produção. O app de
> produção deve apontar EXCLUSIVAMENTE para o projeto de produção (guarda A1:
> o build exige credenciais explícitas + marcador `SUPABASE_CREDENTIALS_EXPLICIT=true`).

---

## 3. Aplicar o schema (projeto NOVO) — `schema.sql`

1. Dashboard do projeto **de produção** → ícone **SQL Editor** → **New query**;
2. Abra `supabase/schema.sql` no repositório, **copie TODO o conteúdo** e cole no editor;
3. **Run** (Ctrl+Enter). O script inteiro roda em UMA transação (`BEGIN … COMMIT`):
   se qualquer parte falhar, NADA é aplicado — corrija e rode de novo;
4. Resultado esperado: `Success. No rows returned` (ou notices de idempotência).

**O que foi criado** (confira em **Table Editor**):

| Grupo | Objetos |
|---|---|
| Núcleo multi-tenant | `tenants`, `stores`, `store_employees`, `plans`, `plan_requests`, `super_admins`, `audit_log` |
| Negócio | `products`, `stock_lots`, `sales`, `sale_items`, `sale_lot_consumption`, `purchases`, `purchase_items`, `customers`, `debts`, `financial_transactions`, `cash_closings` |
| Add-ons (PARTE 1.9) | `tenant_addons`, `custom_invoices`, `quotations`, `employee_attendance`, `employee_commission_rates`, `employee_targets` |
| Billing/admin (PARTE 1.9) | `invoices`, `invoice_notifications`, `admin_messages` + colunas `plan_expires_at`/`next_invoice_at` em `tenants` |
| Segurança | RLS habilitado em TODAS as tabelas + ~100 políticas; triggers anti-forja (`user_id`/`store_id`/`tenant`); helpers `SECURITY DEFINER` (`is_my_store`, `is_tenant_owner`, `is_manager_of_store`, `is_super_admin`, `is_store_employee_active`) |
| RPCs de dinheiro | `process_sale`, `cancel_sale`, `register_debt`, `settle_debt`, `process_purchase`, `adjust_product_stock`, `close_cash_register`, `get_cash_closing_summary`, `create_employee_account`, `set_employee_active`, `update_tenant_settings` + agregações (`get_dashboard_kpis`, `get_cash_flow`, `get_sales_report`, `get_employee_commission_summary`, `get_audit_log`) |
| Storage | Bucket público `product-images` + 4 políticas (leitura pública; escrita só da própria loja) |
| Realtime | `store_employees`, `invoices`, `invoice_notifications`, `admin_messages` publicados |
| Catálogo | Planos `pl1` (Essencial), `pl2` (Profissional), `pl3` (Empresa) |

> O ERP **não semeia** dados de demonstração: cada tenant nasce vazio e registra
> apenas dados reais. Os 3 planos são a única exceção (o onboarding precisa deles).

---

## 4. (Opcional, recomendado) Reforço em base existente — `upgrade.sql`

Use **apenas** se estiver atualizando um projeto que JÁ tem dados (ex.: o live
`dotklbpqmlnhcdifiukd`), para levá-lo ao mesmo estado final:

1. SQL Editor → cole TODO o `supabase/upgrade.sql` → **Run**;
2. Pode rodar **2x sem erro** (idempotência validada pelo CI e pelo
   `scripts/sql_check_live.sh`); se já aplicou partes dele antes, ele só cria o que falta.

---

## 5. Promover o super admin

O papel de super admin vive na tabela `super_admins` (nunca em e-mail hardcoded):

1. **Cadastre-se no app** (ou peça ao dono) com o e-mail que será o super admin — o usuário precisa existir em `auth.users`;
2. Abra `supabase/promote_super_admin.sql`, edite a linha `v_email text := 'SEU_EMAIL_AQUI';` com o e-mail EXATO;
3. SQL Editor → cole → **Run**;
4. Confira a saída: `OK: <email> promovido a super admin` e a consulta final lista quem é super admin.

> Revogar depois: `DELETE FROM public.super_admins WHERE user_id = (SELECT id FROM auth.users WHERE lower(email) = lower('...'));` (instruções no fim do próprio script).

---

## 6. Credenciais no app (`env/prod.env`)

1. Copie o exemplo: `cp env/prod.env.example env/prod.env`;
2. Preencha com os valores do projeto **de produção**:

   ```env
   SUPABASE_URL=https://bcyolmheltzlddfwgqcq.supabase.co
   # Use a publishable (anon) key REAL do dashboard do SEU projeto
   # (Settings → API) — nunca cole chaves em documentos versionados.
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.<resto-do-JWT-do-seu-projeto>
   SUPABASE_CREDENTIALS_EXPLICIT=true
   SENTRY_DSN=https://106274b6c1b7a252ae4f52d4c02996fb@o4512052158791680.ingest.de.sentry.io/4512052160888912
   ```

   - A **anon key** fica em Project Settings → API. É pública por design — a segurança vem do RLS;
   - **`SUPABASE_CREDENTIALS_EXPLICIT=true` é OBRIGATÓRIO**: sem ele, o app
     falha no boot em release (guarda A1 — impede release apontando para os
     defaults de dev por acidente);
3. `env/prod.env` é **ignorado pelo git** (nunca commitado — verificado no histórico completo). Não o adicione.

---

## 7. Build de produção (Android/iOS)

**Android (local):**

```bash
flutter build appbundle --release --flavor prod --dart-define-from-file=env/prod.env --obfuscate --split-debug-info=build/symbols
```

Ou via script (obfuscação obrigatória + valida o marcador):

```bash
bash scripts/build_android.sh prod
```

**iOS:** `bash scripts/build_ios.sh prod` (exige macOS) — ou o CI
(`.github/workflows/ipa.yml` → fastlane → TestFlight), que injeta os defines
dos secrets do GitHub (`SUPABASE_URL_PROD`, `SUPABASE_ANON_KEY_PROD`,
`SENTRY_DSN`, `SUPABASE_CREDENTIALS_EXPLICIT`).

> Confira antes: Play Store → keystore de upload configurada (o Gradle BLOQUEIA
> `prodRelease` sem assinatura — comportamento correto); App Store → bundle id
> e certificados no Fastfile.

---

## 8. Validação pós-instalação (checklist funcional)

### 8.1 No Supabase (SQL Editor)

```sql
-- 1. Catálogo de planos presente (onboarding depende):
SELECT id, name, price_monthly, max_stores, max_employees FROM public.plans ORDER BY id;
-- Esperado: pl1/pl2/pl3.

-- 2. RLS ligado em todas as tabelas de negócio:
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false;
-- Esperado: só audit_log (intencional — leitura apenas via RPC get_audit_log).

-- 3. Bucket de fotos existe:
SELECT id, public FROM storage.buckets WHERE id = 'product-images';  -- t

-- 4. Realtime publicado:
SELECT tablename FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND schemaname = 'public';
-- Esperado: store_employees, invoices, invoice_notifications, admin_messages.

-- 5. Quem é super admin:
SELECT sa.user_id, u.email FROM public.super_admins sa JOIN auth.users u ON u.id = sa.user_id;
```

### 8.2 No app (fumaça de ponta a ponta)

1. Login com o super admin → painel admin carrega tenants/planos;
2. Cadastro de um tenant de teste → aprovação no painel → login do dono;
3. Criar loja + produto → **venda** (dinheiro e M-Pesa) → conferir `sales` + `financial_transactions` + baixa de estoque/lote;
4. **Fiado**: registrar dívida → quitar → conferir `debts.is_paid` e a pendência `paid`;
5. **Compra** (dono/gerente) → estoque sobe com lote novo;
6. **Fecho de caixa** do dia → Z-report consistente;
7. Foto de produto → upload no bucket `product-images` e URL em `products.image_path`;
8. Add-ons: activar factura personalizada/cotação/gestão de funcionários no painel → testar cada módulo;
9. Desativar um funcionário → ele perde o acesso NA HORA (is_my_store).

### 8.3 Validação automatizada (opcional, mas recomendado)

`scripts/sql_check_live.sh` roda as mesmas assertivas do CI contra o projeto real
(leia o cabeçalho do script: preencha host/senha do projeto de produção).

---

## 9. Configurações de plataforma recomendadas (Dashboard)

| Onde | O quê | Por quê |
|---|---|---|
| Authentication → Providers | Apenas **Email** (confirmação conforme o app usa) | Menor superfície de ataque |
| Authentication → URL Configuration | URL do app/deep link de reset de senha | Fluxo "esqueci a senha" |
| Auth → Rate limits | Defaults já razoáveis; não aumentar | Anti-força-bruta |
| Database → Backups | Verificar política do plano (PITR se disponível) | **Dados financeiros** — restauração é inegociável |
| Settings → API | Nunca expor a `service_role` key no app | Ela ignora o RLS |
| Logs → API | Acompanhar 4xx/5xx na primeira semana | Detectar RLS mal configurado / bugs |

---

## 10. Manutenção futura (como evoluir o schema)

1. Toda mudança nova de banco entra como **nova PARTE** idempotente do
   `upgrade.sql` (padrão das Partes 1–31: `CREATE TABLE IF NOT EXISTS`,
   `ADD COLUMN IF NOT EXISTS`, `DROP POLICY IF EXISTS` + `CREATE`,
   `DROP TRIGGER IF EXISTS` + `CREATE`, `CREATE OR REPLACE FUNCTION`,
   Realtime com guarda `pg_publication_tables`);
2. A MESMA mudança vai para o `schema.sql` na seção correspondente
   (projetos novos já nascem com ela);
3. Rode o CI (job `sql-check`: aplica `schema.sql` + `upgrade.sql` **2x** num
   PostgreSQL real com as assertivas do dinheiro/RLS) — se passar, é seguro
   aplicar no live;
4. **Nunca edite** uma PARTE já aplicada em produção — sempre adicione uma nova.

---

## 11. Problemas comuns

| Sintoma | Causa provável | Correção |
|---|---|---|
| `Success` mas tabela X sumiu do Table Editor | Transação abortou no meio (erro antes do COMMIT) | Rode `schema.sql` de novo; o SQL Editor mostra o erro exato da primeira falha |
| App fecha no boot em release | `SUPABASE_CREDENTIALS_EXPLICIT=true` ausente no `env/prod.env` | Adicione o marcador e rebuild (guarda A1) |
| Login funciona mas listas vazias | RLS ativo e usuário sem tenant aprovado/loja | Aprovar o tenant no painel (super admin) |
| `new row violates row-level security policy` ao inserir | Trigger anti-forja corrigiu `store_id`/`user_id`, ou limite do plano | Conferir vínculo em `store_employees` e limites do plano |
| Super admin não vê painel | Papel não promovido | Refazer o passo 5 |
| Upload de foto falha | Caminho fora de `<storeId>/...` no bucket | O PRIMEIRO segmento do caminho DEVE ser o `store_id` (política de escrita) |
| Sem notificações em tempo real | Publicação Realtime ausente | Rodar `upgrade.sql` (guarda `pg_publication_tables` cria) |

---

## 12. Resumo executivo

| Passo | Ação | Tempo |
|---|---|---|
| 1 | Criar projeto Supabase | 3 min |
| 2 | Rodar `schema.sql` (tudo em 1) | 2 min |
| 3 | (Base existente) rodar `upgrade.sql` | 2 min |
| 4 | Promover super admin | 2 min |
| 5 | Preencher `env/prod.env` (+ marcador) | 2 min |
| 6 | Build prod com defines | 5 min |
| 7 | Checklist funcional (seção 8.2) | 10 min |

**Total: ~20–25 min** para um Supabase de produção completo, seguro (RLS +
SECURITY DEFINER em tudo) e com o mesmo comportamento validado nos 862 testes
e no smoke test de PostgreSQL do CI.
