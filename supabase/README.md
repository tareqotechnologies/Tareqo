# Supabase — scripts SQL do TAREQO ERP

> 📘 **Guia completo de configuração do Supabase de produção (passo a passo):**
> [`docs/pt/19-supabase-producao-passo-a-passo.md`](../docs/pt/19-supabase-producao-passo-a-passo.md)

## Arquivos

| Arquivo | Uso |
|---|---|
| **`schema.sql`** | **Instalação NOVA — único script necessário.** Cria tudo: tabelas, RLS, RPCs, triggers, storage (`product-images`), Realtime, add-ons e billing (PARTE 1.9) e o catálogo de planos. Idempotente, roda em 1 transação. |
| **`upgrade.sql`** | **Bases EXISTENTES.** 31 partes idempotentes que levam qualquer versão anterior ao estado atual. Pode ser reexecutado à vontade (o CI aplica 2x como regressão). |
| `promote_super_admin.sql` | Promove um e-mail a super admin (editar `SEU_EMAIL_AQUI`). |
| `cleanup_demo_data.sql` | (Opcional) Remove dados de demonstração. |
| `reset_tenant_data.sql` | (Opcional) Zera os dados de UM tenant. |
| `test_notification.sql` | (Opcional) Notificação de teste para debug de Realtime. |
| `archived_migrations/` | **Histórico — NÃO aplicar.** As 7 migrações (add-ons + billing + admin_messages) cujos objetos foram fundidos no `schema.sql` (PARTE 1.9) e no `upgrade.sql` (PARTE 31), com correções de idempotência. |

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
