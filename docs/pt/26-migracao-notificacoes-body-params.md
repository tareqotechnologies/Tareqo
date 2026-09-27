# 26 — Migração das notificações: `body_params` (PARTE 33) no Supabase de produção (runbook)

> **Objetivo:** aplicar a **PARTE 33 — notificações: `body_params`** no projeto de
> produção (`bcyolmheltzlddfwgqcq`), seguindo as mesmas convenções dos runbooks
> 15 (W4/H2), 16 (W11), 17 (fecho de caixa), 20 (MFA aal2), 24 (tipo do produto)
> e 25 (produção).
>
> O que esta aplicação traz (idempotente):
> 1. **Coluna `body_params` (JSONB)** em `invoice_notifications` — os parâmetros
>    de interpolação do corpo (período, valor, moeda, dias, add-on, datas) para a
>    UI reconstruir a mensagem **localizada** na exibição. O `body` persistido
>    permanece em PT como fallback; `NULL` = notificação legada (mostra o `body`).
> 2. **Comentário da coluna** (`COMMENT ON COLUMN`) documentando o contrato.
>
> **Sem janela de compatibilidade dura:** a migração é **puramente aditiva** (uma
> coluna nova; nenhum dado existente é lido, alterado ou reclassificado) e
> idempotente. ⚠️ O app NOVO **seleciona a coluna** — contra um banco não migrado
> o PostgREST falha com `42703`. **Publique o app depois da migração.**

---

## Registo de aplicação

| Data | Projeto | Estado |
|------|---------|--------|
| 2026-09-27 | **DEV** — `dotklbpqmlnhcdifiukd` | ✅ PARTE 33 aplicada (`invoice_notifications.body_params` presente) |
| — | **PRODUÇÃO** — `bcyolmheltzlddfwgqcq` | ⏳ pendente — diagnóstico REST (2026-09-27): coluna ausente; projeto praticamente vazio (1 loja, 0 produtos/vendas/compras) |

> **DEV vs. produção:** `env/dev.env` → `dotklbpqmlnhcdifiukd` (**DEV**) e
> `env/prod.env` → `bcyolmheltzlddfwgqcq` (**PRODUÇÃO**). Os exemplos abaixo usam
> a referência de **produção**; para DEV use `env/db.env` (`SUPABASE_DB_URL`).

Set a URL (substitua `SENHA` e a região):

```bash
export SUPABASE_DB_URL='postgresql://postgres.bcyolmheltzlddfwgqcq:SENHA@aws-0-<região>.pooler.supabase.com:6543/postgres?sslmode=require'
```

> **Onde guardar:** ponha esta linha num arquivo **gitignored** (`env/prod.db.env`)
> e exporte-a (ou passe-a inline) — **nunca** faça commit dela nem cole a senha no
> chat/PR (a senha antiga de DEV vazou assim e foi rotacionada em Aug/2026); a
> SENHA e a região vêm do Dashboard → Settings → Database. Para DEV o caminho já
> existe: `env/db.env` (`SUPABASE_DB_URL`). Alternativa sem arquivo:
> `set -a; . env/prod.db.env; set +a` antes de rodar o `psql`.

## Passo 0 — Pré-requisitos

- Dashboard + **senha do banco** (Settings → Database); host direto é IPv6-only →
  usar o **pooler**.
- `psql`, Docker (`postgres:16`) **ou** Python com `psycopg2`/`psycopg3` (o
  `scripts/sql_check_live.sh` tem fallback em Python).
- ⚠️ **NUNCA** rodar `scripts/sql_check.sh` contra o live (faz `DROP SCHEMA public
  CASCADE`). A verificação live é só `scripts/sql_check_live.sh`.

## Passo 1 — Backup (obrigatório)

Dashboard → Database → **Backups** → “Create a backup” (ou PITR), ou `pg_dump`
(porta **5432** do pooler).

## Passo 2 — Pré-flight (read-only)

```sql
-- Esperado ANTES da migração: 0 linhas.
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'invoice_notifications'
  AND column_name = 'body_params';
```

## Passo 3 — Aplicar

**Padrão (recomendado) — `upgrade.sql` completo.** É o caminho para um banco
atrasado em MAIS de uma parte (ex.: a produção, que está sem as partes 33 e 35):
leva a todas as partes que faltam de uma só vez. A PARTE 33 é a seção de
`body_params`.

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

**Alternativa — script isolado** (use APENAS quando o banco já está em dia e
falta só esta parte — evita reexecutar as demais partes à toa):

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 \
  -f supabase/add_notification_body_params_2026_09_27.sql
```

Ambos os comandos são `-1` = transação única: se algo falhar, tudo é revertido.
Repetir é seguro (idempotente).

## Passo 4 — Verificação (read-only)

```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'invoice_notifications'
  AND column_name = 'body_params';
-- Esperado: body_params | jsonb
```

**Probe REST** (com a sessão do dono):

```bash
curl -s "$SUPABASE_URL/rest/v1/invoice_notifications?select=id,body_params&limit=1" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $OWNER_ACCESS_TOKEN"
```

- Esperado: `200` (lista vazia ou notificações). Antes da migração: **`42703`**
  (`column invoice_notifications.body_params does not exist`).

## Rollback

```sql
ALTER TABLE public.invoice_notifications DROP COLUMN IF EXISTS body_params;
```

> Destrutivo — a coluna é aditiva e não altera dados existentes. Reverter só é
> necessário se o app novo NÃO for publicado.

---

## Checklist final

| # | Item | Verificação |
|---|------|-------------|
| 1 | Backup feito | backup do Passo 1 |
| 2 | Pré-flight | coluna ausente antes (Passo 2) |
| 3 | Script aplicado | sem erros (transação única) |
| 4 | Coluna presente | `body_params` do tipo `jsonb` (Passo 4) |
| 5 | Probe REST | `select=id,body_params` responde `200` |
| 6 | Reaplicação sem efeito | idempotência (`ADD COLUMN IF NOT EXISTS`) |
