# 15 — Migração W4 + H2 no Supabase de produção (runbook)

> **Objetivo:** aplicar **`supabase/upgrade.sql`** no projeto de produção
> (`bcyolmheltzlddfwgqcq`) — leva o banco EXISTENTE ao estado atual:
> **Parte 7** = W4 (dinheiro em centavos inteiros: `NUMERIC` → `BIGINT`) e
> **Parte 8** = H2 (RPCs `get_cash_flow` / `get_sales_report` + demais
> funções finais). Antigamente eram as migrações `010`/`011`; hoje o script
> consolidado substitui **todas** as migrações `002..011`.
>
> O script é **100% idempotente** e foi validado **12/12** em Postgres 16
> real (Docker, config exata do CI — scram/TCP), incluindo a migração
> `25.50 → 2550` sem dupla aplicação. É seguro reexecutar quantas vezes
> precisar.

---

## Passo 0 — Pré-requisitos

- Acesso ao Dashboard do projeto + **senha do banco**
 (Settings → Database → Connection string).
- O host direto do projeto é **IPv6-only** → usar o **pooler**
 `aws-0-eu-north-1.pooler.supabase.com`.
- `psql` local **ou** Docker (`postgres:16` já traz `psql`).
- Atenção: **NUNCA** rodar `scripts/sql_check.sh` contra o banco live — ele faz
 `DROP SCHEMA public CASCADE`. A verificação live é só
 `scripts/sql_check_live.sh` (read-only).

Defina a URL (substitua `SENHA`):

```bash
export SUPABASE_DB_URL='postgresql://postgres.bcyolmheltzlddfwgqcq:SENHA@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Passo 1 — Backup (obrigatório)

- **Opção rápida:** Dashboard → Database → **Backups** → "Create a backup"
 (ou habilitar PITR).
- **Opção via CLI** (porta **5432** *session* do pooler, adequada a `pg_dump`):

```bash
pg_dump "postgresql://postgres.bcyolmheltzlddfwgqcq:SENHA@aws-0-eu-north-1.pooler.supabase.com:5432/postgres?sslmode=require" \
 --schema=public -f backup_pre_w4.sql
```

## Passo 2 — Pré-flight (read-only, SQL Editor)

**2.1 Tipos atuais das colunas de dinheiro** (se já vierem `bigint`, a
migração já foi aplicada → pule para o Passo 4):

```sql
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
 AND column_name IN ('purchase_price','sale_price','total_amount','unit_price','amount','price_monthly')
ORDER BY 1, 2;
```

**2.2 Duplicados de tenants pendentes** — a guarda S3 (Parte 2 do
`upgrade.sql`) **aborta** o script se existirem. Confira antes:

```sql
SELECT owner_user_id, count(*)
FROM public.tenants
WHERE status = 'pending'
GROUP BY owner_user_id HAVING count(*) > 1;
```
→ Se retornar linhas: resolva os duplicados (mantenha o mais antigo,
rejeite os demais) **antes** de aplicar.

**2.3 Contagem de linhas** (para conferir depois que nada sumiu):

```sql
SELECT 'products' t, count(*) FROM public.products UNION ALL
SELECT 'sales', count(*) FROM public.sales UNION ALL
SELECT 'financial_transactions', count(*) FROM public.financial_transactions UNION ALL
SELECT 'debts', count(*) FROM public.debts;
```

## Passo 3 — Aplicar o `supabase/upgrade.sql`

### Opção A — psql via pooler, UMA transação (recomendada — convenção do projeto) ✓

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transação única: se **qualquer** parte falhar (ex.: guarda S3),
 **tudo** é revertido — nenhum estado parcial.
- Esperado: sem erros. Se abortar, a mensagem indica o motivo (ex.:
 duplicados pendentes); resolva e reaplique.

### Opção B — SQL Editor do Dashboard

1. Abra o **SQL Editor** no projeto.
2. Cole o **conteúdo completo** de `supabase/upgrade.sql`.
3. Execute. O editor roda o script como um único lote; em caso de erro,
 ele para e mostra a mensagem. Como o script é idempotente, corrigir e
 reexecutar é seguro.

## Passo 4 — Verificação pós-migração (read-only)

**4.1 Rodar o script de verificação live** (read-only, 14 checks):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Esperado: **VERIFICAÇÃO CONCLUÍDA — todos os checks passaram** (14/14),
 cobrindo: 9 colunas de dinheiro em `BIGINT`, zero valores fracionários,
 RPCs H2 presentes (`get_cash_flow`/`get_sales_report`/`get_dashboard_kpis`)
 com `SECURITY DEFINER` + retornos `BIGINT`.

**4.2 Conferência manual (SQL Editor):**

```sql
-- 1) Colunas já em centavos (bigint)?
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
 AND column_name IN ('purchase_price','sale_price','total_amount','unit_price','amount','price_monthly')
ORDER BY 1, 2;
-- Esperado: data_type = bigint nas 9 colunas.

-- 2) Nenhum valor fracionário sobrou?
SELECT 'products' t, count(*) FROM public.products WHERE purchase_price % 1 <> 0 OR sale_price % 1 <> 0
UNION ALL SELECT 'sales', count(*) FROM public.sales WHERE total_amount % 1 <> 0
UNION ALL SELECT 'financial_transactions', count(*) FROM public.financial_transactions WHERE amount % 1 <> 0
UNION ALL SELECT 'debts', count(*) FROM public.debts WHERE amount % 1 <> 0;
-- Esperado: todos 0.

-- 3) RPCs H2 presentes?
SELECT p.proname, pg_get_function_identity_arguments(p.oid) args
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
 AND p.proname IN ('get_cash_flow','get_sales_report','get_dashboard_kpis')
ORDER BY 1;
```

**4.3 Contagem de linhas** — comparar com o Passo 2.3 (nada deve ter sumido).

## Passo 5 — Idempotência (opcional, confirma que reaplicar não duplica)

Repita o Passo 3 e depois confira que **não** houve dupla multiplicação:

```sql
-- Um produto conhecido: ex. preço original 25.50 deve valer 2550 (uma só vez)
SELECT id, purchase_price, sale_price FROM public.products ORDER BY created_at LIMIT 3;
```

## Rollback (só se necessário)

Restaura as colunas para `NUMERIC(12,2)` dividindo por 100 (os RPCs antigos
em reais deixam de existir — o app em Supabase usaria o fallback client-side):

```sql
ALTER TABLE public.products ALTER COLUMN purchase_price TYPE NUMERIC(12,2) USING (purchase_price / 100.0);
ALTER TABLE public.products ALTER COLUMN sale_price TYPE NUMERIC(12,2) USING (sale_price / 100.0);
-- … repetir para sales.total_amount, sale_items.unit_price,
-- financial_transactions.amount, debts.amount, purchases.total_amount,
-- purchase_items.unit_price, plans.price_monthly
```

---

## Checklist final

| # | Item | Verificação |
|---|------|-------------|
| 1 | Backup feito | arquivo `backup_pre_w4.sql` existe |
| 2 | Pré-flight limpo | sem duplicados pendentes; tipos `numeric` |
| 3 | `upgrade.sql` aplicado | sem erros (transação única) |
| 4 | `sql_check_live.sh` | ✓ 14/14 |
| 5 | Reaplicação sem efeito | idempotência confirmada |
| 6 | App em modo Supabase | KPIs/relatórios/caixa com valores corretos |
