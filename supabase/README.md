# Supabase — scripts SQL do TAREQO ERP

> 📘 **Guia completo de configuração do Supabase de produção (passo a passo):**
> [`docs/pt/19-supabase-producao-passo-a-passo.md`](../docs/pt/19-supabase-producao-passo-a-passo.md)

## Arquivos

| Arquivo | Uso |
|---|---|
| **`schema.sql`** | **Instalação NOVA — único script necessário.** Cria tudo: tabelas, RLS, RPCs, triggers, storage (`product-images`), Realtime, add-ons e billing (PARTE 1.9) e o catálogo de planos. Idempotente, roda em 1 transação. |
| **`upgrade.sql`** | **Bases EXISTENTES.** As partes idempotentes (até à PARTE 38) que levam qualquer versão anterior ao estado atual. Pode ser reexecutado à vontade (o CI aplica 2x como regressão). |
| `fix_product_images_rls_2026_11.sql` | **PARTE 37 isolada** — corrige o 403/RLS do upload de foto (`product-images`) em bancos que já rodaram a versão anterior da política de SELECT. Idempotente. |
| `product_category_2026_11.sql` | **PARTE 38 isolada** — adiciona `products.category` (filtro por categoria na lista). Rodar antes de instalar o APK novo. Idempotente. |
| `promote_super_admin.sql` | Promove um e-mail a super admin (editar `SEU_EMAIL_AQUI`). |
| `cleanup_demo_data.sql` | (Opcional) Remove dados de demonstração. |
| `reset_tenant_data.sql` | (Opcional) Zera os dados de UM tenant. |
| `test_notification.sql` | (Opcional) Notificação de teste para debug de Realtime. |
| `add_notification_body_params_2026_09_27.sql` | **PARTE 33 isolada** — `invoice_notifications.body_params` (parâmetros para localizar a notificação na exibição) num banco que já está nas partes anteriores. Runbook: [`26`](../docs/pt/26-migracao-notificacoes-body-params.md). |
| `add_product_type_2026_09_27.sql` | **PARTE 34 isolada** — `products.type` + índice `idx_products_store_type` (Fase 1) num banco que já está nas partes anteriores. Runbook: [`24`](../docs/pt/24-migracao-tipo-produto.md). |
| `add_production_2026_09_27.sql` | **PARTE 35 isolada** — ficha técnica + produção (Fase 2: 4 tabelas, RLS gerencial e RPC `process_production`) num banco que já está nas partes anteriores. Runbook: [`25`](../docs/pt/25-migracao-producao.md). |
| `archived_migrations/` | **Histórico — NÃO aplicar.** As 7 migrações (add-ons + billing + admin_messages) cujos objetos foram fundidos no `schema.sql` (PARTE 1.9) e no `upgrade.sql` (PARTE 31), com correções de idempotência. |

## Banco de produção — como fornecer a `SUPABASE_DB_URL`

Dev e prod são projetos Supabase **SEPARADOS**: `env/dev.env` →
`dotklbpqmlnhcdifiukd` (**DEV**) e `env/prod.env` → `bcyolmheltzlddfwgqcq`
(**PRODUÇÃO**). Os runbooks (24/25/26) e o `scripts/sql_check_live.sh` precisam
de uma **connection string do banco** (nunca a anon key — ela não roda DDL).
Para apontar à produção, crie o arquivo **gitignored** `env/prod.db.env`:

```bash
# env/prod.db.env  (ignorado pelo git — NÃO versionar)
SUPABASE_DB_URL=postgresql://postgres.bcyolmheltzlddfwgqcq:SENHA@aws-0-<região>.pooler.supabase.com:6543/postgres?sslmode=require
```

- **SENHA** e **região**: Dashboard do projeto → Settings → Database (o host do
  pooler muda por projeto; o host direto é IPv6-only).
- A senha fica **só no arquivo** — não cole no chat/PR (a senha antiga de DEV
  vazou assim e foi rotacionada em Aug/2026).
- DEV já tem o caminho pronto: `env/db.env`.
- Uso: `set -a; . env/prod.db.env; set +a; bash scripts/sql_check_live.sh`
  (ou exporte `SUPABASE_DB_URL` à mão antes de rodar o `psql`/runbook).

## Regra de ouro

- Projeto **novo** → rodar **`schema.sql`** apenas.
- Projeto **existente** → rodar **`upgrade.sql`** apenas.

Nunca "por garantia" os dois: ambos são idempotentes, mas cada um já cobre
o estado final sozinho.

## Como evoluir (nova mudança de banco)

1. Adicione uma **nova PARTE idempotente** no `upgrade.sql` (nunca edite uma
   PARTE já aplicada em produção);
2. Replique a mudança na seção correspondente do `schema.sql` (projetos novos
   já nascem com ela);
3. Abra o PR — o job `sql-check` do CI aplica `schema.sql` + `upgrade.sql` 2x
   num PostgreSQL real e valida o RLS e os RPCs do dinheiro.
