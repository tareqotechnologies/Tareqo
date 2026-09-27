# 25 — Migração da ficha técnica + produção (`recipes`/`production_orders`) no Supabase de produção (runbook)

> **Objetivo:** aplicar a **PARTE 35 — produção: ficha técnica + ordens
> (Fase 2)** no projeto de produção (`dotklbpqmlnhcdifiukd`), usando o
> `supabase/upgrade.sql` consolidado — mesmas convenções dos runbooks 15
> (W4/H2), 16 (W11), 17 (fecho de caixa), 20 (MFA aal2) e 24 (tipo do
> produto/Fase 1).
>
> O que esta aplicação traz (idempotente):
> 1. **4 tabelas novas** por loja: `recipes` (a ficha técnica — UNIQUE
>    `(store_id, product_id)`), `recipe_items` (componentes, FK CASCADE,
>    UNIQUE `(recipe_id, product_id)`), `production_orders` (histórico, com
>    snapshot de custo) e `production_order_items` (componentes consumidos por
>    ordem, UNIQUE `(production_id, product_id)`);
> 2. **RLS** `ENABLE` nas 4 tabelas + **políticas manager** (`is_manager_of_store`;
>    INSERT/UPDATE exigem `mfa_ok()`) — produção é **gerencial**, como compras;
> 3. **4 índices** (`recipes(store_id)`, `recipe_items(recipe_id)`,
>    `production_orders(store_id, date_time DESC)`,
>    `production_order_items(production_id)`);
> 4. **RPC `process_production(p_order jsonb, p_items jsonb)`**
>    `SECURITY DEFINER` — baixa os componentes em ordem FIFO e cria o lote do
>    produto acabado **em UMA transação** + `GRANT EXECUTE … TO authenticated`.
>
> **Sem janela de compatibilidade dura:** a migração é **puramente aditiva**
> (tabelas novas, nenhum dado existente é lido, alterado ou reclassificado).
> O app antigo simplesmente não tem o módulo Produção; o app novo (Fase 2)
> lê/escreve as tabelas. Publicar o app antes ou depois da migração é
> indiferente — sem o módulo a produção apenas não existe.

---

## Passo 0 — Pré-requisitos

- Acesso ao Dashboard do projeto + **senha do banco**
  (Settings → Database → Connection string).
- O host direto do projeto é **IPv6-only** → usar o **pooler**
  `aws-0-eu-north-1.pooler.supabase.com`.
- `psql` local **ou** Docker (`postgres:16` já traz `psql`).
- Atenção: **NUNCA** rodar `scripts/sql_check.sh` contra o banco live — ele faz
  `DROP SCHEMA public CASCADE`. A verificação live é só
  `scripts/sql_check_live.sh` (read-only, checks 1–44).
- **App compilado na versão com a Fase 2** pronto para publicar (ver Passo 6)
  — só é necessário para o módulo Produção aparecer no menu.
- **Dependência das Fases anteriores:** a coluna `products.type` (Fase 1,
  PARTE 34) precisa existir — a produção usa `isProducible`
  (`manufactured`/`composite`) e o custo pelo `purchase_price` do componente.
  Se ainda não aplicou, rode também o runbook 24.

Defina a URL (substitua `SENHA`):

```bash
export SUPABASE_DB_URL='postgresql://postgres.dotklbpqmlnhcdifiukd:SENHA@aws-0-eu-north-1.pooler.supabase.com:6543/postgres?sslmode=require'
```

## Passo 1 — Backup (obrigatório)

- **Opção rápida:** Dashboard → Database → **Backups** → "Create a backup"
  (ou habilitar PITR).
- **Opção via CLI** (porta **5432** *session* do pooler, adequada a `pg_dump`):

```bash
pg_dump "postgresql://postgres.dotklbpqmlnhcdifiukd:SENHA@aws-0-eu-north-1.pooler.supabase.com:5432/postgres?sslmode=require" \
  --schema=public -f backup_pre_production.sql
```

## Passo 2 — Pré-flight (read-only, SQL Editor)

**2.1 As tabelas/RPC já existem?** (a migração é idempotente — isto só enquadra
o cenário; esperado: ausentes ANTES da migração):

```sql
-- 4 tabelas da produção (esperado: 0 linhas antes).
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items')
ORDER BY tablename;

-- RPC atômica (esperado: 0 linhas antes).
SELECT proname FROM pg_proc
WHERE proname = 'process_production';
```

**2.2 Amostra de integridade** (anote — a migração não deve alterar nenhuma
linha):

```sql
SELECT
  (SELECT count(*) FROM public.products)   AS produtos,
  (SELECT count(*) FROM public.sales)      AS vendas,
  (SELECT count(*) FROM public.purchases)  AS compras,
  (SELECT count(*) FROM public.stock_lots WHERE current_quantity > 0) AS lotes_ativos;
```

**2.3 Fase 1 aplicada?** (o custo/produção dependem de `products.type`):

```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Esperado: type | text | 'resale'::text  (senão rode o runbook 24 primeiro)
```

## Passo 3 — Aplicar o `supabase/upgrade.sql`

### Opção A — psql via pooler, UMA transação (recomendada — convenção do projeto)

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transação única: se **qualquer** parte falhar, **tudo** é revertido
  — nenhum estado parcial.
- A PARTE 35 é `CREATE TABLE/INDEX IF NOT EXISTS` + `DROP POLICY IF EXISTS` +
  `CREATE OR REPLACE FUNCTION` + `GRANT` — na 2ª execução é no-op.

### Opção B — SQL Editor do Dashboard

1. Abra o **SQL Editor** no projeto.
2. Cole o **conteúdo completo** de `supabase/upgrade.sql`.
3. Execute. Em caso de erro, o editor para e mostra a mensagem; como o
   script é idempotente, corrigir e reexecutar é seguro.

### Opção C — script isolado (só a PARTE 35)

Para aplicar **apenas** esta migração (ex.: banco que já está nas Partes
anteriores), rode o script dedicado — mesmo conteúdo da PARTE 35:

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_production_2026_09_27.sql
```

## Passo 4 — Verificação pós-migração (read-only)

**4.1 Rodar o script de verificação live** (read-only, agora com **44
checks** — o novo é o 44):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Esperado: **VERIFICAÇÃO CONCLUÍDA — todos os checks passaram**, incluindo o
  **44** — as 4 tabelas existem, com RLS ativo nas 4, e
  `process_production(jsonb,jsonb)` é `SECURITY DEFINER` com `EXECUTE` para
  `authenticated`.

**4.2 Conferência manual (SQL Editor):**

```sql
-- 1) As 4 tabelas + RLS ativo (esperado: 4 linhas, rls = true):
SELECT c.relname, c.relrowsecurity AS rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname IN ('recipes','recipe_items','production_orders','production_order_items')
ORDER BY c.relname;

-- 2) Políticas manager nas tabelas (esperado: 16 policies — SELECT/INSERT/
--    UPDATE/DELETE por tabela):
SELECT tablename, count(*) AS policies
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items')
GROUP BY tablename ORDER BY tablename;

-- 3) RPC SECURITY DEFINER + EXECUTE para authenticated:
SELECT p.proname, p.prosecdef,
       has_function_privilege('authenticated',
         'public.process_production(jsonb,jsonb)', 'EXECUTE') AS exec_ok
FROM pg_proc p
WHERE p.proname = 'process_production';
-- Esperado: process_production | true | true
```

**4.3 Conferência de integridade** — repita o 2.2: contagens de
produtos/vendas/compras/lotes **idênticas** (a migração não toca linhas
existentes).

**4.4 Probe REST (o app novo lê/escreve as tabelas):** com a anon key e a
sessão do dono, o `SELECT` das novas tabelas já responde (vazio ou com
fichas):

```bash
curl -s "$SUPABASE_URL/rest/v1/recipes?select=id,product_id,yield_quantity&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Esperado: `[]` (sem fichas) — em banco sem a migração, o PostgREST devolve
  **`42P01` (relation "public.recipes" does not exist)**.

## Passo 5 — Idempotência (opcional, confirma que reaplicar não duplica)

Repita o Passo 3 e depois confira:

```sql
-- Ainda exatamente 4 tabelas de produção:
SELECT count(*) AS tabelas
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('recipes','recipe_items','production_orders','production_order_items');
-- Esperado: 4.

-- Ainda exatamente UMA process_production:
SELECT count(*) AS rpcs FROM pg_proc WHERE proname = 'process_production';
-- Esperado: 1.
```

## Passo 6 — Publicar o app (Fase 2) e usar a produção

A migração sozinha não muda o comportamento de nada (tabelas novas e vazias):

1. **Publicar a versão do app com a Fase 2.** O módulo **Produção** aparece no
   menu para dono/gerente (gate `accessLevel != employee`).
2. **Montar as fichas técnicas** (Produção → Nova ficha): escolher o produto
   **acabado** (só `manufactured`/`composite`), o rendimento da base e os
   componentes/quantidades. Uma ficha por produto acabado.
3. **Registrar a produção** (Produção → Produzir): informar as bases — os
   componentes baixam FIFO e o lote do acabado nasce com o custo calculado
   pelo preço de compra **atual** dos componentes.
4. **Conferir os fluxos:** o acabado passa a ser vendável no PDV (revenda/
   produzido/composto) e as matérias-primas/embalagens aparecem em Compras.

> A ordem de produção **não movimenta o caixa** — os componentes já foram
> pagos na compra; a produção só transforma estoque.

## Rollback (só se necessário)

> A migração é **puramente aditiva** (tabelas/índices novos, RPC nova) e
> idempotente. Reverter significa apenas NÃO publicar o app novo; os dados
> existentes continuam válidos. Para remover de verdade:
>
> 1. **Fichas, ordens e componentes gravados serão perdidos** (são dados NOVOS
>    desta fase — não havia nada antes). Faça o backup do Passo 1 antes.
> 2. Remover os objetos (destrutivo):
>    ```sql
>    DROP FUNCTION IF EXISTS public.process_production(jsonb, jsonb);
>    DROP TABLE IF EXISTS public.production_order_items;
>    DROP TABLE IF EXISTS public.production_orders;
>    DROP TABLE IF EXISTS public.recipe_items;
>    DROP TABLE IF EXISTS public.recipes;
>    ```
> 3. NÃO reverter a coluna `products.type` nem os lotes por causa da produção:
>    eles são das Fases 1/W11 e continuam válidos sem este módulo.

---

## Checklist final

| # | Item | Verificação |
|---|------|-------------|
| 1 | Backup feito | arquivo `backup_pre_production.sql` existe |
| 2 | Pré-flight | 4 tabelas + RPC ausentes (2.1); contagens anotadas (2.2); `products.type` presente (2.3) |
| 3 | `upgrade.sql` aplicado | sem erros (transação única) — ou o script isolado no Passo 3C |
| 4 | `sql_check_live.sh` | ✓ todos os 44 checks (produção: 44) |
| 5 | Tabelas + RLS | 4 tabelas com `relrowsecurity = true` (4.2.1) |
| 6 | Políticas manager | 16 policies, INSERT/UPDATE com `mfa_ok()` (4.2.2) |
| 7 | RPC atômica | `process_production` SECURITY DEFINER + EXECUTE a authenticated (4.2.3) |
| 8 | Dados intactos | contagens de produtos/vendas/compras/lotes iguais (4.3) |
| 9 | Probe REST | `GET /rest/v1/recipes` responde `[]` (4.4) |
| 10 | Reaplicação sem efeito | idempotência confirmada (Passo 5) |
| 11 | App Fase 2 publicado | módulo Produção visível para dono/gerente |
| 12 | Fichas + produção | dono/gerente monta a ficha e produz; lote do acabado nasce com custo |
