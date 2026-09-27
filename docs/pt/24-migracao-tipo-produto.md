# 24 — Migração do tipo estrutural do produto (`products.type`) no Supabase de produção (runbook)

> **Objetivo:** aplicar a **PARTE 34 — tipo estrutural do produto (Fase 1)**
> no projeto de produção (`bcyolmheltzlddfwgqcq`), usando o
> `supabase/upgrade.sql` consolidado — mesmas convenções dos runbooks 15
> (W4/H2), 16 (W11), 17 (fecho de caixa), 18 (add-ons) e 20 (MFA aal2).
>
> O que esta aplicação traz (idempotente):
> 1. **Coluna `products.type`** (`TEXT NOT NULL DEFAULT 'resale'`) — o tipo
>    estrutural do produto pelo NOME do enum `ProductType` (`rawMaterial`,
>    `resale`, `manufactured`, `composite`, `packaging`);
> 2. **`DROP CONSTRAINT IF EXISTS products_type_check`** — limpa um CHECK de
>    enum que uma versão anterior do script tenha criado (não deve existir;
>    a validação de enum vive no cliente/datasource);
> 3. **Comentário da coluna** (`COMMENT ON COLUMN`) documentando os valores;
> 4. **Índice `idx_products_store_type (store_id, type)`** — mantém o filtro
>    por tipo constante na listagem do catálogo.
>
> **Sem janela de compatibilidade dura:** o default `'resale'` significa que
> produtos existentes já eram compráveis e vendáveis e **continuam
> funcionando exatamente igual** — nenhum dado é apagado nem reclassificado
> automaticamente. O app antigo nem seleciona nem envia a coluna (usa
> `DEFAULT 'resale'`); o app novo (Fase 1) lê/escreve o campo. Publicar o app
> antes ou depois da migração é indiferente.

---

## Registo de aplicação

| Data | Projeto | Estado |
|------|---------|--------|
| 2026-09-27 | **DEV** — `dotklbpqmlnhcdifiukd` | ✅ PARTE 34 aplicada: coluna `products.type` (TEXT NOT NULL DEFAULT `resale`) + índice `idx_products_store_type`; `scripts/sql_check_live.sh` → checks 1–44 passam; backfill one-off reclassificou 1 produto (`Oleo Maeva` → `rawMaterial`) |
| — | **PRODUÇÃO** — `bcyolmheltzlddfwgqcq` | ⏳ pendente — diagnóstico REST (2026-09-27): a coluna `products.type` já existe, mas o índice/CHECK não são observáveis via REST (confirmar com o check 43, que exige um `SUPABASE_DB_URL`). Projeto praticamente vazio (1 loja, 0 produtos) |

> **DEV vs. produção:** `env/dev.env` → `dotklbpqmlnhcdifiukd` (**DEV**) e
> `env/prod.env` → `bcyolmheltzlddfwgqcq` (**PRODUÇÃO**). Os exemplos abaixo
> usam a referência de **produção**; para DEV use `env/db.env`
> (`SUPABASE_DB_URL`). O host do pooler (`aws-0-<região>...`) deve ser o do
> projeto alvo (Dashboard → Settings → Database).

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
- ⚠️ **Ordem das partes:** o 44 é o check da **Fase 2** (produção, PARTE 35 —
  runbook 25). Se você aplicar **somente** a Fase 1 (PARTE 34), o 43 passará
  mas o **44 falhará** (tabelas de produção ausentes). O esperado é aplicar as
  duas partes (34 e 35) — ou aceitar o 44 como o único pendente até a Fase 2.
- **App compilado na versão com a Fase 1** pronto para publicar (ver Passo 6)
  — só é necessário para o campo aparecer no cadastro e para os fluxos por
  papel (compras/PDV).

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
  --schema=public -f backup_pre_product_type.sql
```

## Passo 2 — Pré-flight (read-only, SQL Editor)

**2.1 A coluna/índice já existem?** (a migração é idempotente — isto só
enquadra o cenário):

```sql
-- Coluna products.type (esperado: ausente antes da migração; se já existir,
-- com data_type=text / is_nullable=NO / column_default com 'resale'):
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';

-- Índice do filtro por tipo:
SELECT indexname FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';

-- CHECK de enum por engano (esperado: 0 linhas):
SELECT conname FROM pg_constraint
WHERE conrelid = 'public.products'::regclass
  AND conname = 'products_type_check';
```

**2.2 Amostra de integridade** (anote — a migração não deve alterar nenhuma
linha):

```sql
SELECT
  (SELECT count(*) FROM public.products)   AS produtos,
  (SELECT count(*) FROM public.sales)      AS vendas,
  (SELECT count(*) FROM public.purchases)  AS compras;

-- Nenhum produto deve ter sido reclassificado: depois da migração TODAS as
-- linhas ficam em 'resale' (o default), sem UPDATE algum.
SELECT type, count(*) FROM public.products GROUP BY type ORDER BY type;
```

## Passo 3 — Aplicar o `supabase/upgrade.sql`

### Opção A — psql via pooler, UMA transação (recomendada — convenção do projeto)

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transação única: se **qualquer** parte falhar, **tudo** é revertido
  — nenhum estado parcial.
- A PARTE 34 é `ADD COLUMN IF NOT EXISTS` + `DROP CONSTRAINT IF EXISTS` +
  `COMMENT` + `CREATE INDEX IF NOT EXISTS` + `ANALYZE` — na 2ª execução é
  no-op.

### Opção B — SQL Editor do Dashboard

1. Abra o **SQL Editor** no projeto.
2. Cole o **conteúdo completo** de `supabase/upgrade.sql`.
3. Execute. Em caso de erro, o editor para e mostra a mensagem; como o
   script é idempotente, corrigir e reexecutar é seguro.

### Opção C — script isolado (só a PARTE 34)

Para aplicar **apenas** esta migração (ex.: banco que já está nas Partes
anteriores), rode o script dedicado — mesmo conteúdo da PARTE 34:

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_product_type_2026_09_27.sql
```

## Passo 4 — Verificação pós-migração (read-only)

**4.1 Rodar o script de verificação live** (read-only, agora com **44
checks no total** — o da Fase 1 é o 43; o 44 é o da Fase 2/produção):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Esperado (com a PARTE 34 e a PARTE 35 aplicadas): **VERIFICAÇÃO CONCLUÍDA —
  todos os checks passaram**, incluindo o **43** — coluna `products.type`
  `TEXT NOT NULL DEFAULT 'resale'` (sem CHECK de enum) + índice
  `idx_products_store_type`.
- Aplicando **só** a Fase 1, o **44 falhará** (tabelas de produção ausentes) —
  aplique também a PARTE 35 pelo runbook 25.

**4.2 Conferência manual (SQL Editor):**

```sql
-- 1) Coluna com o tipo/default certos:
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Esperado: type | text | NO | 'resale'::text

-- 2) Índice presente:
SELECT indexdef FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';
-- Esperado: ... ON public.products (store_id, type)

-- 3) SEM CHECK de enum (o cliente valida; um tipo futuro não pode ficar
--    bloqueado pela restrição antiga):
SELECT conname FROM pg_constraint
WHERE conrelid = 'public.products'::regclass AND contype = 'c'
  AND pg_get_constraintdef(oid) ILIKE '%type%';
-- Esperado: 0 linhas.
```

**4.3 Conferência de integridade** — repita o 2.2: contagens de
produtos/vendas/compras idênticas e **todos** os produtos em `'resale'`
(nenhum reclassificado pela migração).

**4.4 Probe REST (o app novo lê/escreve o campo):** com a anon key e a
sessão do dono, o `SELECT` de um produto já devolve a coluna:

```bash
curl -s "$SUPABASE_URL/rest/v1/products?select=id,name,type&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Esperado: um item com `"type":"resale"`. Em banco sem a migração, o
  PostgREST devolve **`42703` (column products.type does not exist)** — prova
  de que a coluna existe.

## Passo 5 — Idempotência (opcional, confirma que reaplicar não duplica)

Repita o Passo 3 e depois confira:

```sql
-- Ainda exatamente UMA coluna type:
SELECT count(*) AS colunas_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
  AND column_name = 'type';
-- Esperado: 1.

-- Ainda exatamente UM índice idx_products_store_type:
SELECT count(*) AS indices
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'products'
  AND indexname = 'idx_products_store_type';
-- Esperado: 1.
```

## Passo 6 — Publicar o app (Fase 1) e reclassificar produtos

A migração não muda o comportamento de nada por si só (default `'resale'`):

1. **Publicar a versão do app com a Fase 1.** Produtos existentes continuam
   compráveis e vendáveis exatamente como antes.
2. **Reclassificar produto a produto** (Produtos → editar → "Tipo de
   produto"): matérias-primas, produzidos, compostos e embalagens ganham o
   papel correto. Recomenda-se começar pelos itens que sairão das listas
   padrão:
   - **matéria-prima/embalagem** deixam de aparecer no PDV;
   - **produzido/composto** deixam de aparecer nas Compras.
3. **Conferir os fluxos:** no PDV o catálogo mostra só papéis vendáveis
   (`isSellable`); nas Compras só papéis compráveis (`isPurchasable`). Se um
   papel ficar sem itens, o estado vazio explica o motivo em vez de dizer
   "sem produtos".
4. **Backfill opcional por SQL** (só se houver categorias conhecidas — o
   app não reclassifica nada sozinho):

```sql
-- Exemplo: tudo que está em 'resale' e tem "FARINHA" no nome vira matéria-prima.
UPDATE public.products SET type = 'rawMaterial'
WHERE type = 'resale' AND upper(name) LIKE '%FARINHA%';
```

> O `UPDATE` acima é **manual e explícito** — a migração nunca o executa.

**Backfill automático (recomendado para catálogos grandes):** o helper
one-off `tool/backfill_product_types.dart` generaliza o `LIKE` acima com uma
tabela ordenada de palavras-chave (`lib/domain/services/product_type_classifier.dart`):

```bash
# 1) Dry-run em DEV (nada é gravado) — revise o plano:
dart run tool/backfill_product_types.dart

# 2) Aplicar em DEV (só quem ainda está em 'resale'):
dart run tool/backfill_product_types.dart --apply

# 3) Em PRODUÇÃO: dry-run, revisão e só então --apply:
dart run tool/backfill_product_types.dart --prod
dart run tool/backfill_product_types.dart --prod --apply
```

- **Dry-run por padrão**: nada é gravado sem `--apply`.
- **Nunca desfaz** uma classificação já feita — por padrão só olha produtos em
  `resale` (use `--include-classified` para reaplicar as regras a todos).
- Restringe a uma loja com `--store <id>`.
- Usa a **sessão do dono** (RLS vigia) e as credenciais gitignored
  (`env/dev.env`/`env/test_accounts.env`; `--prod` usa `env/prod.env`).
- A regra que casou aparece no relatório (`(regra: farinha)`) — revise antes
  do `--apply`. Classificação é heurística: produtos de nome ambíguo devem ser
  corrigidos na UI depois.

## Rollback (só se necessário)

> A migração é **aditiva** (coluna com default, comentário e índice) e
> idempotente. Reverter significa apenas NÃO publicar o app novo; os dados
> continuam válidos. Para remover de verdade:
>
> 1. **Não há dados a desfazer:** nenhum produto foi reclassificado
>    automaticamente (só reclassificações MANUAIS feitas no Passo 6.4/app).
> 2. Remover a coluna (destrutivo — só se o app novo NÃO for publicado e
>    nenhum produto tiver sido reclassificado):
>    `ALTER TABLE public.products DROP COLUMN IF EXISTS type;`
>    `DROP INDEX IF EXISTS public.idx_products_store_type;`
> 3. Nas reclassificações manuais, reverta os `UPDATE` feitos à mão (ou
>    restaure o backup do Passo 1).

---

## Checklist final

| # | Item | Verificação |
|---|------|-------------|
| 1 | Backup feito | arquivo `backup_pre_product_type.sql` existe |
| 2 | Pré-flight | coluna/índice/CHECK catalogados (2.1); contagens e distribuição de `type` anotados (2.2) |
| 3 | `upgrade.sql` aplicado | sem erros (transação única) — ou o script isolado no Passo 3C |
| 4 | `sql_check_live.sh` | ✓ checks 1–43 (tipo do produto: 43). O 44 (produção) só passa com a PARTE 35 (runbook 25) |
| 5 | Sem CHECK de enum | 0 constraints de `type` (4.2.3) |
| 6 | Dados intactos | contagens iguais e todos os produtos em `resale` (4.3) |
| 7 | Probe REST | produto devolve `"type":"resale"` (4.4) |
| 8 | Reaplicação sem efeito | idempotência confirmada (Passo 5) |
| 9 | App Fase 1 publicado | campo "Tipo de produto" visível no cadastro |
| 10 | Reclassificação (opcional) | dono/gerente classifica produto a produto; PDV/Compras filtram por papel |
