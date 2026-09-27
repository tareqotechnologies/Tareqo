# 17 — Migração do Fecho de Caixa diário no Supabase de produção (runbook)

> **Objetivo:** aplicar a **Parte 25** de `supabase/upgrade.sql` no projeto de
> produção (`bcyolmheltzlddfwgqcq`) — habilita o **fecho de caixa diário
> (Z-report)** no banco EXISTENTE: tabela `cash_closings` (um fecho por loja
> por dia) + RPC `close_cash_register` que calcula NO SERVIDOR o esperado na
> gaveta e persiste o fecho atomicamente.
>
> O que a Parte 25 faz (idempotente — mesmas convenções das Partes 7/8/22):
> 1. **25.1** — tabela `cash_closings` (snapshot do dia: total de vendas,
> esperado na gaveta, contagem física, abertura por forma de pagamento em
> JSONB) com **UNIQUE `(store_id, closing_date)`** — refazer o fecho do
> mesmo dia ATUALIZA, nunca duplica;
> 2. **25.2** — RLS + políticas: leitura para dono/funcionários da loja;
> escrita via RPC (INSERT de loja própria; UPDATE/DELETE só de registros
> próprios — defesa em profundidade);
> 3. **25.3** — índice `idx_cash_closings_store` (varredura por loja);
> 4. **25.4** — triggers `user_id`/`store_id` (mesmos helpers do schema);
> 5. **25.5** — RPC `close_cash_register(text, timestamptz, bigint)`
> `SECURITY DEFINER` com guarda **`is_manager_of_store`** (fecho é
> operação GERENCIAL — dono/gerente), cálculo server-side do esperado
> (Σ vendas ATIVAS em **dinheiro** do dia — cartão/M-Pesa/E-Mola/
> transferência não passam pela gaveta física) e UPSERT em UMA transação.
>
> A mesma aplicação traz também a **Parte 26**: a RPC de leitura
> `get_cash_closing_summary(text, timestamptz)` — PRÉVIA do Z-report
> agregada NO SERVIDOR (mesmo critério do `close_cash_register`, guarda
> `is_my_store`), para lojas com histórico grande não carregarem as vendas
> no cliente (escala H2, padrão `get_cash_flow`/`get_sales_report`).
>
> O script é **100% idempotente** e a Parte 25 segue as mesmas convenções
> das Partes 7/8/22 (CREATE TABLE IF NOT EXISTS, DROP POLICY IF EXISTS +
> CREATE POLICY, DROP TRIGGER IF EXISTS + CREATE TRIGGER, CREATE OR REPLACE
> FUNCTION). O passo **[18/18]** do `sql_check.sh` (que EXECUTA a RPC como
> `app_user` e verifica total, esperado, abertura por forma, UPSERT sem
> duplicar e a rejeição de funcionário) roda no **CI** (job `sql-check`, job
> Postgres 16 descartável) — a sintaxe já foi validada localmente (`bash -n`).
> É seguro reexecutar quantas vezes precisar.
>
> **Atenção:** **Sem janela de compatibilidade dura** (diferente da W11): a Parte 25
> só ADICIONA tabela + RPC — nenhum dado existente é reescrito. O app
> precisa estar na versão com o fecho de caixa para USAR a RPC, mas clientes
> antigos não quebram ao gravar. Ainda assim, publique a versão nova junto
> (Passo 6) para o recurso aparecer.

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
- **App compilado na versão com o fecho de caixa** pronta para publicar
 (ver Passo 6).

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
 --schema=public -f backup_pre_fecho.sql
```

## Passo 2 — Pré-flight (read-only, SQL Editor)

**2.1 A Parte 25 já foi aplicada?** Se a tabela `cash_closings` já existir,
a migração já rodou → pule para o Passo 4 (e confira o Passo 6):

```sql
SELECT to_regclass('public.cash_closings') AS cash_closings_ja_existe;
-- Esperado: NULL (não aplicada) ou public.cash_closings (já aplicada).
```

**2.2 Fechos já existentes?** (bancos que tiverem registros de um teste
manual da RPC antes do runbook):

```sql
SELECT count(*) AS fechos_existentes FROM public.cash_closings;
```

**2.3 Amostra do dia** (para conferir depois que o cálculo server-side do
esperado bate com as vendas em dinheiro — anote o total de vendas em
dinheiro de HOJE). Atenção: A query usa `date_trunc('day', now())` no fuso do
SERVIDOR (UTC no Supabase), enquanto a RPC recebe o início do dia LOCAL do
cliente convertido a UTC — para lojas em MZN (UTC+2) os dois "dias" podem
divergir perto da meia-noite. A amostra é informativa; a autoridade é a RPC:

```sql
SELECT COALESCE(SUM(total_amount), 0) AS vendas_dinheiro_hoje
FROM public.sales
WHERE status = 'active'
 AND payment_method = 'cash'
 AND date_time >= date_trunc('day', now())
 AND date_time < date_trunc('day', now()) + interval '1 day';
```

## Passo 3 — Aplicar o `supabase/upgrade.sql`

### Opção A — psql via pooler, UMA transação (recomendada — convenção do projeto) ✓

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transação única: se **qualquer** parte falhar, **tudo** é revertido
 — nenhum estado parcial.
- Esperado: sem erros (a Parte 25 emite apenas NOTICEs de "already exists"
 nas colunas/tabelas já criadas — normal, é a idempotência agindo).

### Opção B — SQL Editor do Dashboard

1. Abra o **SQL Editor** no projeto.
2. Cole o **conteúdo completo** de `supabase/upgrade.sql`.
3. Execute. O editor roda o script como um único lote; em caso de erro, ele
 para e mostra a mensagem. Como o script é idempotente, corrigir e
 reexecutar é seguro.

## Passo 4 — Verificação pós-migração (read-only)

**4.1 Rodar o script de verificação live** (read-only, agora com **34
checks**, incluindo os 3 novos do fecho de caixa 32–34):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Esperado: **VERIFICAÇÃO CONCLUÍDA — todos os checks passaram**, incluindo:
 - 32 — tabela `cash_closings` + RLS ON + UNIQUE `(store_id, closing_date)`;
 - 33 — RPC `close_cash_register` `SECURITY DEFINER` + guarda
 `is_manager_of_store` + cálculo server-side sobre `sales`;
 - 34 — triggers `user_id`/`store_id` + índice `idx_cash_closings_store`.

**4.2 Conferência manual (SQL Editor):**

```sql
-- 1) Tabela + unicidade (deve existir; um fecho por loja/dia):
SELECT conname, pg_get_constraintdef(oid) AS def
FROM pg_constraint
WHERE conrelid = 'public.cash_closings'::regclass
 AND contype = 'u';

-- 2) RPC no ar + SECURITY DEFINER + search_path fixo:
SELECT p.proname, p.prosecdef, p.proconfig
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'close_cash_register';

-- 3) Nenhum fecho foi criado pela migração (ela NÃO insere dados):
SELECT count(*) AS fechos_apos_migracao FROM public.cash_closings;
-- Esperado: 0 (ou o número do Passo 2.2, inalterado).
```

**4.3 Contagem de linhas das tabelas de negócio** — se anotou no Passo 2.3,
confira que nada mudou (a Parte 25 não toca dados existentes).

## Passo 5 — Idempotência (opcional, confirma que reaplicar não duplica)

Repita o Passo 3 e depois confira que a tabela continua com **um** conjunto
de objetos (sem duplicar nada):

```sql
-- Objetos únicos (sem duplicatas):
SELECT count(*) AS triggers_fecho FROM pg_trigger
WHERE tgrelid = 'public.cash_closings'::regclass;
-- Esperado: 2 (trg_cash_closings_user_id + trg_cash_closings_store_id).

SELECT count(*) AS policies_fecho FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'cash_closings';
-- Esperado: 4 (select/insert/update/delete).
```

## Passo 6 — Publicar o app (Z-report)

A Parte 25 não reescreve dados, mas o recurso só aparece na UI nova:

1. **Publicar a versão do app com o fecho de caixa** — botão no Financeiro
 (dono/gerente) → sheet Z-report com conferência física.
2. Clientes antigos continuam funcionando (a RPC é aditiva); o recurso
 simplesmente não aparece até a atualização.
3. O app novo continua **100% compatível offline** (SQLite local já cria a
 tabela `cash_closings` na abertura do banco).

## Rollback (só se necessário)

> A Parte 25 é **aditiva** (tabela + RPC — nenhum dado existente é
> reescrito). Se precisar reverter, basta **não publicar** o app novo (o
> recurso não aparece) e, se quiser remover a tabela, restaurar do backup do
> Passo 1. Não há migração destrutiva a desfazer.

---

## Checklist final

| # | Item | Verificação |
|---|------|-------------|
| 1 | Backup feito | arquivo `backup_pre_fecho.sql` existe |
| 2 | Pré-flight limpo | `cash_closings` não existe; amostra anotada |
| 3 | `upgrade.sql` aplicado | sem erros (transação única) |
| 4 | `sql_check_live.sh` | ✓ todos os 35 checks (fecho 32–34 + prévia server-side 35) |
| 5 | Unicidade por loja/dia | UNIQUE `(store_id, closing_date)` presente |
| 6 | Reaplicação sem efeito | idempotência confirmada (Passo 5) |
| 7 | App publicado | versão com fecho de caixa publicada |
| 8 | Fecho funcionando | dono/gerente fecham o caixa; funcionário bloqueado (servidor) |
