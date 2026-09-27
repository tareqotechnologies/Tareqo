# 18 — Migrações de persistência dos add-ons no Supabase de produção (runbook)

> **⚠️ CONSOLIDADO (Set/2026):** os objetos destas migrações foram **fundidos** no
> `schema.sql` (PARTE 1.9 — instalação nova) e no `upgrade.sql` (PARTE 31 — bases
> existentes), com correções de idempotência (políticas com
> `DROP POLICY IF EXISTS`, Realtime com guarda `pg_publication_tables`).
> Os arquivos originais foram **arquivados** em `supabase/archived_migrations/`
> (somente leitura, histórico). **Não aplique os arquivos arquivados em bases
> novas** — use os scripts consolidados; o runbook abaixo permanece como
> referência do que cada objeto faz e de como foi verificado no live.

> **Objetivo:** aplicar as migrações que tornam os add-ons **realmente persistentes**
> no projeto de produção (`bcyolmheltzlddfwgqcq`), seguindo as mesmas convenções
> das migrações anteriores (Partes de `upgrade.sql`): `CREATE TABLE IF NOT EXISTS`,
> `DROP POLICY/TRIGGER IF EXISTS` + `CREATE`, `CREATE OR REPLACE FUNCTION`,
> triggers de `user_id`/`store_id` com os helpers do schema (`set_tenant_user_id`,
> `set_record_store_id`, `is_my_store`).

Três migrações independentes, uma por add-on:

| Migração (arquivada em `supabase/archived_migrations/`) | Add-on | Tabelas / RPC | Estado live |
| -------- | ------ | ------------- | ----------- |
| `20260905_custom_invoice_persistence.sql` | Factura Personalizada | `custom_invoices` + trigger de numeração | ✅ **Aplicada + verificada** (REST/RLS) |
| `20260905_quotation_persistence.sql` | Cotação / Orçamento | `quotations` + trigger de numeração | ✅ **Aplicada + verificada** (REST/RLS) |
| `20260905_employee_mgmt_persistence.sql` | Gestão de Funcionários | `employee_attendance`, `employee_commission_rates`, `employee_targets` + RPC `get_employee_commission_summary` | ⏳ **Pendente de aplicação** |

> **Estado atual (Set/2026):** com a consolidação, instalar o schema do zero
> (`schema.sql`) já cria TODOS estes objetos (PARTE 1.9). Na base live existente,
> aplicar a **PARTE 31 do `upgrade.sql`** cobre os três add-ons + billing +
> mensagens admin de uma vez (idempotente — pode reexecutar). A ordem entre os
> módulos não importa (são independentes).

> A ordem de aplicação entre as três não importa (são independentes e idempotentes).
> No SQLite o mesmo schema chega via **migração v3 (facturas), v4 (cotações) e v5
> (funcionários)** em `lib/core/database/app_database_io.dart`.

---

## 1. Factura Personalizada (`20260905_custom_invoice_persistence.sql`)

- **1.1** — tabela `custom_invoices`: `id TEXT PRIMARY KEY` (sem DEFAULT — o **app**
  envia o id gerado por `AppIds.newId('ci')`; ver Passo 4), `store_id` (FK `stores`),
  `user_id` (FK `auth.users`, preenchido pelo trigger), `invoice_number BIGINT`,
  `payload JSONB` (corpo completo da factura: cliente, itens, descontos, impostos),
  `created_at`; **UNIQUE `(store_id, invoice_number)`** — a numeração sequencial é do
  banco: o trigger `custom_invoices_numbering` atribui `MAX+1` por loja na inserção
  (o número enviado pelo cliente é ignorado — o banco é a autoridade, como nas vendas).
- **1.2** — RLS + políticas: leitura/inserção via `is_my_store` (o trigger
  `set_tenant_user_id` preenche `user_id`); sem UPDATE/DELETE no cliente.
- **1.3** — função de leitura `get_next_custom_invoice_number(store_id)` (MAX+1 puro,
  para previews) e índice por loja.

## 2. Cotação (`20260905_quotation_persistence.sql`)

- **2.1** — tabela `quotations`: mesma anatomia da factura (`id`, `store_id`,
  `user_id`, `quotation_number`, `payload JSONB`, `created_at`) + **UNIQUE
  `(store_id, quotation_number)`** e trigger `quotations_numbering` (MAX+1 por loja).
- **2.2** — RLS: leitura/inserção via `is_my_store`; **UPDATE** de registros da
  própria loja (`is_my_store`) — necessário para as **transições de estado**
  (rascunho → enviada → aceite/rejeitada) que o app grava no repositório.
- **2.3** — `get_next_quotation_number(store_id)` + índice por loja.

## 3. Gestão de Funcionários (`20260905_employee_mgmt_persistence.sql`)

- **3.1** — `employee_attendance`: registo de ponto — `UNIQUE (store_id, user_id,
  work_date)` (clock-in insere, clock-out faz UPDATE da MESMA linha);
  `user_id` é o **sujeito** (o funcionário), por isso o trigger de actor é o
  **`set_employee_attendance_actor`** (`recorded_by` = `auth.uid()`) — o
  `set_tenant_user_id` (que força `user_id = auth.uid()`) sobrescreveria o
  funcionário sendo registado.
- **3.2** — `employee_commission_rates`: taxa por funcionário em **pontos-base**
  (500 = 5%, matemática inteira) — `UNIQUE (store_id, user_id)`.
- **3.3** — `employee_targets`: meta mensal de vendas por funcionário (`month`
  = `YYYY-MM`) — `UNIQUE (store_id, user_id, month)`.
- **3.4** — RPC `get_employee_commission_summary(store_id, month)` `SECURITY
  DEFINER` com guarda `is_my_store`: **comissões CALCULADAS das vendas reais**
  (`sales.user_id` = vendedor, status ativa, do mês) × taxa — nunca armazenadas
  (padrão H2 de `get_cash_flow`/`get_sales_report`).
- **3.5** — RLS nas 3 tabelas via `is_my_store` + `is_store_employee_active` no
  INSERT (não se registra ponto/rate/meta de quem não é funcionário activo da loja).

---

## Passo 4 — Correção necessária antes de usar em SaaS (já aplicada no código)

A migração declara `id TEXT PRIMARY KEY` **sem DEFAULT**, mas os datasources remotos
não enviavam o `id` no INSERT → em modo Supabase **toda gravação falhava** com
`23502 NOT NULL` (o SQLite enviava o id; o bug era só no caminho remoto). Corrigido em:

- `lib/data/datasources/remote/supabase_custom_invoice_data_source.dart`
- `lib/data/datasources/remote/supabase_quotation_data_source.dart`

(`'id': invoice.id` / `'id': quotation.id` no payload do insert.) Se o código voltar a
falhar ao gravar em SaaS, confira que o id está no payload.

---

## Passo 5 — Verificação live (read-only, sem tocar em dados)

Usando a anon key do app (mesmo caminho do PostgREST):

```bash
# Tabelas existem e anon não vê linhas (RLS filtra leituras)
curl -s -H "apikey: $ANON" "https://bcyolmheltzlddfwgqcq.supabase.co/rest/v1/custom_invoices?select=id"   # → []
curl -s -H "apikey: $ANON" "https://bcyolmheltzlddfwgqcq.supabase.co/rest/v1/quotations?select=id"     # → []

# RLS ativo: INSERT anon deve ser REJEITADO com 42501 (payload com user_id
# inexistente em auth.users — mesmo se o RLS falhasse, a FK rejeitaria; nunca
# grava nada)
curl -s -X POST -H "apikey: $ANON" -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON" \
  -d '{"id":"probe","store_id":"st1","payload":{},"user_id":"00000000-0000-0000-0000-000000000000"}' \
  "https://bcyolmheltzlddfwgqcq.supabase.co/rest/v1/custom_invoices"   # → 42501 RLS

# Funções de numeração presentes (SELECT MAX+1 puro, sem escrita)
curl -s -X POST -H "apikey: $ANON" -H "Content-Type: application/json" \
  -d '{"store_id":"st1"}' \
  "https://bcyolmheltzlddfwgqcq.supabase.co/rest/v1/rpc/get_next_custom_invoice_number"  # → 1
```

Verificação executada em 2026-09-05: **RLS confirmado ativo** nas duas tabelas
(`42501 new row violates row-level security policy`) e ambas as funções de numeração
respondendo. As tabelas de funcionários seguem o mesmo padrão — após aplicar a
migração do Passo 3, repita as sondas com `employee_attendance` e a RPC.

---

## Passo 6 — Publicação

- O app precisa estar na versão com os add-ons persistentes (v2.1.0+20) para USAR
  as tabelas/RPCs — clientes antigos não quebram (as migrações só adicionam).
- Aplicar a migração `20260905_employee_mgmt_persistence.sql` **antes** de vender o
  add-on Gestão de Funcionários no marketplace (a UI já está desbloqueada).