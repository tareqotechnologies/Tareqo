# 20 — Migração do MFA server-side (aal2) no Supabase de produção (runbook)

> **Objetivo:** aplicar as guardas **MFA server-side (P1)** e a correção do
> **overload de `update_tenant_settings` (PGRST203)** no projeto de produção
> (`bcyolmheltzlddfwgqcq`), usando o `supabase/upgrade.sql` consolidado —
> mesmas convenções dos runbooks 15 (W4/H2), 16 (W11) e 17 (fecho de caixa).
>
> O que esta aplicação traz (idempotente):
> 1. **Coluna `tenants.mfa_enforced`** (BOOLEAN NOT NULL DEFAULT FALSE —
>    todas as lojas nascem SEM exigência; nenhum comportamento existente
>    muda até o dono ativar por tenant);
> 2. **4 helpers aal2** (`mfa_verified_factor_count`, `mfa_satisfied`,
>    `mfa_enforced_for_user`, `mfa_ok`) — `SECURITY DEFINER`, `STABLE`,
>    leem `auth.mfa_factors` (GoTrue) e o claim `aal` do JWT;
> 3. **Guardas `mfa_ok()` nas 7 RPCs do dinheiro** (`process_sale`,
>    `cancel_sale`, `register_debt`, `settle_debt`, `process_purchase`,
>    `adjust_product_stock`, `close_cash_register`);
> 4. **Guardas `mfa_ok()` nas políticas INSERT/UPDATE** das 6 tabelas de
>    dinheiro (`sales`, `sale_items`, `sale_lot_consumption`,
>    `financial_transactions`, `debts`, `purchases`) — PostgREST direto
>    também fica bloqueado;
> 5. **`update_tenant_settings(p_tenant_id, p_currency_code, p_language,
>    p_mfa_enforced)`** — só TRANSIÇÕES alteram a flag: ativação
>    (false→true) exige fator TOTP verificado no GoTrue; **desativação
>    (true→false) exige sessão aal2**; mesmo-valor é no-op;
> 6. **DROP da assinatura legada 3-arg** de `update_tenant_settings` —
>    elimina o PGRST203 (PostgREST não sabia escolher entre as assinaturas
>    3 e 4 args; qualquer chamada sem o 4º argumento falhava).
>
> **Sem janela de compatibilidade dura:** o default FALSE + falha ABERTA
> enquanto o tenant não ativa a exigência significam que clientes antigos e
> novos continuam gravando normalmente imediatamente após a migração. O
> app novo (P1) é necessário apenas para MATRICULAR o fator no GoTrue e
> ATIVAR a exigência por tenant.

---

## Passo 0 — Pré-requisitos

- Acesso ao Dashboard do projeto + **senha do banco**
  (Settings → Database → Connection string).
- O host direto do projeto é **IPv6-only** → usar o **pooler**
  `aws-0-eu-north-1.pooler.supabase.com`.
- `psql` local **ou** Docker (`postgres:16` já traz `psql`).
- Atenção: **NUNCA** rodar `scripts/sql_check.sh` contra o banco live — ele faz
  `DROP SCHEMA public CASCADE`. A verificação live é só
  `scripts/sql_check_live.sh` (read-only, checks 1–39).
- **App compilado na versão com o MFA server-side (P1)** pronto para
  publicar (ver Passo 6).

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
  --schema=public -f backup_pre_mfa.sql
```

## Passo 2 — Pré-flight (read-only, SQL Editor)

**2.1 Qual estado do MFA já está no live?** O projeto live já recebeu as
Partes anteriores (`upgrade.sql` aplicado Aug 6 e Aug 10). O CREATE OR
REPLACE com a nova assinatura pode ter criado o **overload** (3-arg + 4-arg
coexistindo — causa do PGRST203 observado em 13/09/2026). Rode:

```sql
-- Assinaturas existentes de update_tenant_settings:
SELECT p.oid::regprocedure AS assinatura, p.prosecdef
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'update_tenant_settings';
-- Possíveis resultados:
--   (a) só a 4-arg (text,text,text,boolean) → migração P1 já aplicada;
--   (b) 3-arg E 4-arg → OVERLOAD presente: esta aplicação CORRIGE;
--   (c) só a 3-arg (improvável) → aplica normalmente.

-- Coluna mfa_enforced já existe?
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'tenants'
  AND column_name = 'mfa_enforced';
-- Esperado se já aplicada: mfa_enforced | boolean | false
```

**2.2 Tenants existentes + estado atual da exigência** (anote — a migração
não deve alterar nenhum valor):

```sql
SELECT id, business_name, mfa_enforced FROM public.tenants ORDER BY created_at;
```

**2.3 Amostra de integridade** (confira depois que nada mudou):

```sql
SELECT
  (SELECT count(*) FROM public.sales)       AS vendas,
  (SELECT count(*) FROM public.purchases)   AS compras,
  (SELECT count(*) FROM public.products)    AS produtos;
```

## Passo 3 — Aplicar o `supabase/upgrade.sql`

### Opção A — psql via pooler, UMA transação (recomendada — convenção do projeto)

```bash
psql "$SUPABASE_DB_URL" -X -v ON_ERROR_STOP=1 -1 -f supabase/upgrade.sql
```

- `-1` = transação única: se **qualquer** parte falhar, **tudo** é revertido
  — nenhum estado parcial.
- O script recria as RPCs do dinheiro com as guardas `mfa_ok`, as políticas
  com `DROP POLICY IF EXISTS` + `CREATE POLICY`, e roda o
  `DROP FUNCTION IF EXISTS public.update_tenant_settings(text,text,text)`
  (idempotente — na 2ª execução é no-op).

### Opção B — SQL Editor do Dashboard

1. Abra o **SQL Editor** no projeto.
2. Cole o **conteúdo completo** de `supabase/upgrade.sql`.
3. Execute. Em caso de erro, o editor para e mostra a mensagem; como o
   script é idempotente, corrigir e reexecutar é seguro.

## Passo 4 — Verificação pós-migração (read-only)

**4.1 Rodar o script de verificação live** (read-only, agora com **39
checks** — os 4 novos do MFA são 36–39):

```bash
SUPABASE_DB_URL="$SUPABASE_DB_URL" bash scripts/sql_check_live.sh
```

- Esperado: **VERIFICAÇÃO CONCLUÍDA — todos os checks passaram**, incluindo:
  - **36** — coluna `tenants.mfa_enforced` + 4 helpers aal2
    (`SECURITY DEFINER`);
  - **37** — guardas `mfa_ok` presentes nas 7 RPCs do dinheiro;
  - **38** — policies INSERT/UPDATE das 6 tabelas de dinheiro com `mfa_ok`
    (≥ 11 policies);
  - **39** — assinatura **única** 4-arg de `update_tenant_settings`
    (overload legado 3-arg removido — causa raiz do PGRST203).

**4.2 Conferência manual (SQL Editor):**

```sql
-- 1) Overload eliminado (deve devolver EXATAMENTE 1 linha):
SELECT p.oid::regprocedure AS assinatura
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'update_tenant_settings';

-- 2) Semântica de transição: chamada com o valor ATUAL é no-op
--    (não lança, não muda nada — roda como o dono real via app; no SQL
--    Editor, apenas confirme que a função existe e é SECURITY DEFINER):
SELECT p.prosecdef, p.proconfig
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.oid = 'public.update_tenant_settings(text,text,text,boolean)'::regprocedure;
```

**4.3 Conferência de integridade** — repita o 2.3 e o 2.2: contagens de
vendas/compras/produtos idênticas e **nenhum** `mfa_enforced` alterado
(a migração não liga a exigência em nenhum tenant).

**4.4 Probe REST do PGRST203 (confirma o bug sumiu):** com a anon key,
a chamada SEM o 4º argumento agora resolve na assinatura única:

```bash
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/update_tenant_settings" \
  -H "apikey: $SUPABASE_ANON_KEY" -H "Content-Type: application/json" \
  -d '{"p_tenant_id":"probe","p_currency_code":"MZN","p_language":"pt"}'
```

- Antes: `PGRST203` (ambiguidade). Depois: erro de negócio
  (`is_tenant_owner` — o "probe" não é tenant seu) ou sucesso sem efeito;
  **nunca** PGRST203.

## Passo 5 — Idempotência (opcional, confirma que reaplicar não duplica)

Repita o Passo 3 e depois confira:

```sql
-- Ainda EXATAMENTE 1 assinatura:
SELECT count(*) AS assinaturas
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'update_tenant_settings';
-- Esperado: 1.

-- Helpers únicos (4):
SELECT count(*) AS helpers_mfa
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN ('mfa_verified_factor_count','mfa_satisfied',
                    'mfa_enforced_for_user','mfa_ok');
-- Esperado: 4.
```

## Passo 6 — Publicar o app (P1) e ativar por tenant

A migração não liga nada por si só; o fluxo de ativação é por decisão do
dono:

1. **Publicar a versão do app com P1** (matrícula no GoTrue, toggle em
   Lojas → Ajustes). Clientes antigos continuam funcionando (default
   FALSE = comportamento anterior).
2. **Dono matricula o fator:** Segurança → ativar 2FA (o secret é gerado
   pelo SERVIDOR e exibido como QR/entrada manual; o verify confirma no
   GoTrue).
3. **Dono ativa a exigência do tenant:** Lojas → Ajustes → "Exigir MFA
   para operações de dinheiro". A RPC valida fator verificado antes de
   ligar `mfa_enforced`.
4. **Desativação (se um dia necessária):** feita na app pelo dono com
   sessão aal2 — o servidor REJEITA desativar em sessão apenas-senha
   (invasor com senha roubada não desarma a proteção).

## Rollback (só se necessário)

> A migração é **aditiva + idempotente** (coluna com default FALSE, helpers,
> guardas e DROP de overload). Enquanto nenhum tenant ligar
> `mfa_enforced`, as guardas são **no-op** (`mfa_ok()` devolve TRUE) —
> reverter significa apenas NÃO publicar/ativar. Para remover de verdade:
>
> 1. Confirme que nenhum tenant está com `mfa_enforced = TRUE`:
>    `SELECT id FROM public.tenants WHERE mfa_enforced;` — se houver, desative
>    antes (requer aal2 do dono);
> 2. Restaure o backup do Passo 1 (restaura as assinaturas antigas, incl. o
>    overload — se o app P1 já estiver publicado, publique a versão anterior
>    junto: o app P1 sempre envia `p_mfa_enforced`, o que quebraria a 3-arg
>    legada).
>
> Não há migração destrutiva de dados a desfazer.

---

## Checklist final

| # | Item | Verificação |
|---|------|-------------|
| 1 | Backup feito | arquivo `backup_pre_mfa.sql` existe |
| 2 | Pré-flight | assinaturas/coluna catalogados (2.1); tenants + contagens anotados (2.2/2.3) |
| 3 | `upgrade.sql` aplicado | sem erros (transação única) |
| 4 | `sql_check_live.sh` | ✓ todos os 39 checks (MFA: 36–39) |
| 5 | Overload eliminado | exatamente 1 assinatura 4-arg (4.2.1); probe REST sem PGRST203 (4.4) |
| 6 | Dados intactos | contagens iguais (4.3); nenhum `mfa_enforced` alterado |
| 7 | Reaplicação sem efeito | idempotência confirmada (Passo 5) |
| 8 | App P1 publicado | matrícula GoTrue + toggle visíveis na app |
| 9 | Ativação por tenant (opcional) | dono com fator verificado liga a exigência; venda aal1 passa a ser rejeitada PELO SERVIDOR |
