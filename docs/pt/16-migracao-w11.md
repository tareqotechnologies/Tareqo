# 16 — Migração W11 no Supabase de produção (runbook)

> **Objetivo:** aplicar a **Parte 22** de `supabase/upgrade.sql` no projeto de
> produção (`bcyolmheltzlddfwgqcq`) — leva o banco EXISTENTE ao estado W11:
> **FIFO por lotes + controlo de validade** e **vendas por peso (balanças)**,
> com TODAS as quantidades convertidas de unidades inteiras para
> **MILÉSIMOS** (×1000).
>
> O que a Parte 22 faz (idempotente — mesmas convenções das Partes 7/8):
> 1. **22.1** — novas colunas em `products` (`code`/PLU, `venda_por_fracao`,
> `unit_label`) e `purchase_items.expiry_date` (validade opcional por item);
> 2. **22.2** — tabela `stock_lots` (lote = entrada de mercadoria: validade,
> quantidade inicial/atual, custo de aquisição) + índices FIFO;
> 3. **22.3** — migração **×1000** de TODAS as quantidades (produtos, itens de
> venda e de compra) + **backfill de lote inicial** para cada produto com
> estoque (invariante `stock = Σ lotes` vale desde o primeiro dia);
> 4. **22.4** — RLS + políticas + triggers da `stock_lots`;
> 5. **22.5/22.6/22.7** — RPCs recriadas: `process_sale` com **baixa FIFO** por
> lotes, `process_purchase` **criando lotes** na entrada, `get_sales_report`
> com matemática em milésimos.
>
> O script é **100% idempotente** e foi validado contra Postgres 16 real
> (Docker, config exata do CI): `sql_check.sh` completo verde (incluindo a
> reaplicação do `upgrade.sql` 2× sem dupla multiplicação e a migração
> `25.50 → 2550` + `5 → 5000` sem efeitos colaterais). É seguro reexecutar
> quantas vezes precisar.
>
> **Atenção:** **IMPORTANTE — leia antes de aplicar:** a Parte 22.3 multiplica
> **quantidades existentes por 1000** (5 unidades → 5000 milésimos). Depois
> dela, **nenhum cliente antigo** (versões pré-W11 do app) deve gravar dados
> — a versão nova do app deve ser publicada em conjunto (ver Passo 6).

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
- **App compilado na versão W11** pronta para publicar (ver Passo 6).

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
 --schema=public -f backup_pre_w11.sql
```

## Passo 2 — Pré-flight (read-only, SQL Editor)

**2.1 A W11 já foi aplicada?** Se a coluna `stock_lots` já existir, a
migração já rodou → pule para o Passo 4 (e confira o Passo 6):

```sql
SELECT to_regclass('public.stock_lots') AS stock_lots_ja_existe;
-- Esperado: NULL (não aplicada) ou public.stock_lots (já aplicada).
```

**2.2 Amostra das quantidades atuais** (para conferir depois que o ×1000
aconteceu — anote alguns valores):

```sql
SELECT id, name, stock_quantity FROM public.products
ORDER BY created_at DESC LIMIT 5;
```

**2.3 Contagem de linhas** (para conferir depois que nada sumiu):

```sql
SELECT 'products' t, count(*) FROM public.products UNION ALL
SELECT 'sales', count(*) FROM public.sales UNION ALL
SELECT 'sale_items', count(*) FROM public.sale_items UNION ALL
SELECT 'purchases', count(*) FROM public.purchases UNION ALL
SELECT 'purchase_items', count(*) FROM public.purchase_items;
```

## Passo 3 — Aplicar o `supabase/upgrade.sql`

### Opção A — psql via pooler, UMA transação (recomendada — convenção do projeto) ✓

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transação única: se **qualquer** parte falhar, **tudo** é revertido
 — nenhum estado parcial.
- Esperado: sem erros (a Parte 22 emite apenas NOTICEs de "already exists"
 nas colunas/tabelas já criadas — normal, é a idempotência agindo).
- A migração ×1000 + backfill roda **apenas quando `stock_lots` está vazio**
 (guarda da Parte 22.3) — reexecutar o script é um no-op.

### Opção B — SQL Editor do Dashboard

1. Abra o **SQL Editor** no projeto.
2. Cole o **conteúdo completo** de `supabase/upgrade.sql`.
3. Execute. O editor roda o script como um único lote; em caso de erro, ele
 para e mostra a mensagem. Como o script é idempotente, corrigir e
 reexecutar é seguro.

## Passo 4 — Verificação pós-migração (read-only)

**4.1 Rodar o script de verificação live** (read-only; na época da W11 eram
**31 checks** — o script evoluiu e hoje tem 35, os novos 32–35 do fecho de
caixa (32–34 + a prévia server-side 35) somam-se sem afetar estes):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Esperado: **VERIFICAÇÃO CONCLUÍDA — todos os checks passaram**, incluindo
 os 7 novos W11 (25–31):
 - 25 — colunas `products.code` / `venda_por_fracao` / `unit_label`;
 - 26 — `purchase_items.expiry_date`;
 - 27 — tabela `stock_lots` + RLS ON + índice FIFO;
 - 28 — `process_sale` com baixa FIFO por lotes em milésimos;
 - 29 — `process_purchase` criando lotes;
 - 30 — `get_sales_report` com matemática em milésimos;
 - 31 — **invariante `stock = Σ lotes ativos`** (informa quantos produtos
 têm estoque diferente da soma dos lotes — esperado `0` logo após a
 migração).

**4.2 Conferência manual (SQL Editor):**

```sql
-- 1) Quantidades migradas para MILÉSIMOS? (5 unidades → 5000)
SELECT id, name, stock_quantity FROM public.products
ORDER BY created_at DESC LIMIT 5;
-- Compare com a amostra do Passo 2.2: os valores devem estar ×1000.

-- 2) Invariante W11: estoque do produto = Σ lotes ativos?
SELECT count(*) AS produtos_com_estoque_fora_da_soma_dos_lotes
FROM public.products p
WHERE p.stock_quantity > 0
 AND COALESCE((
 SELECT SUM(l.current_quantity) FROM public.stock_lots l
 WHERE l.product_id = p.id AND l.store_id = p.store_id
 AND l.current_quantity > 0
 ), 0) <> p.stock_quantity;
-- Esperado: 0.

-- 3) Lotes backfilled (sem validade — produtos não perecíveis)?
SELECT count(*) AS lotes_iniciais, count(*) FILTER (WHERE expiry_date IS NULL) AS sem_validade
FROM public.stock_lots;

-- 4) RPCs W11 no ar?
SELECT p.proname
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
 AND p.proname IN ('process_sale','process_purchase','get_sales_report')
ORDER BY 1;
```

**4.3 Contagem de linhas** — comparar com o Passo 2.3 (nada deve ter sumido).

## Passo 5 — Idempotência (opcional, confirma que reaplicar não duplica)

Repita o Passo 3 e depois confira que **não** houve dupla multiplicação:

```sql
-- Um produto conhecido: ex. 5 unidades devem valer 5000 (uma só vez)
SELECT id, name, stock_quantity FROM public.products
ORDER BY created_at DESC LIMIT 3;
-- E o número de lotes NÃO pode ter dobrado:
SELECT count(*) FROM public.stock_lots;
```

## Passo 6 — Publicar o app W11 (IMPORTANTE — janela de compatibilidade)

A migração muda o **contrato de quantidades** (unidades → milésimos) no
banco. Para não misturar escalas:

1. **Publicar a versão W11 do app imediatamente após o Passo 3** — o app
 novo é o único que lê/escreve quantidades corretas.
2. Clientes antigos abertos podem falhar ao gravar (quantidade fora de
 escala) — a migração é uma **janela de manutenção curta**: aplicar
 `upgrade.sql` e publicar o app o quanto antes.
3. O app W11 continua **100% compatível offline** (SQLite local já migra
 sozinho via migração W11 do `AppDatabase`).

## Rollback (só se necessário)

> **Atenção:** Não existe rollback automático da Parte 22.3 (×1000 + lotes) — a
> restauração é via **backup** (Passo 1). Se precisar reverter, restaure o
> banco do `backup_pre_w11.sql` **e** publique a versão antiga do app.

---

## Checklist final

| # | Item | Verificação |
|---|------|-------------|
| 1 | Backup feito | arquivo `backup_pre_w11.sql` existe |
| 2 | Pré-flight limpo | `stock_lots` não existe; amostra de quantidades anotada |
| 3 | `upgrade.sql` aplicado | sem erros (transação única) |
| 4 | `sql_check_live.sh` | ✓ todos os checks (incluindo W11 25–31) |
| 5 | Invariante `stock = Σ lotes ativos` | `produtos_com_estoque_fora_da_soma_dos_lotes` = 0 |
| 6 | Reaplicação sem efeito | idempotência confirmada (Passo 5) |
| 7 | App W11 publicado | sem clientes antigos gravando na mesma janela |
| 8 | App em modo Supabase | PDV com peso/balança e alertas de validade funcionando |
