# 11 — Multi-tenancy, Planos e Super Admin

A camada de **Contas** transforma o Dumbhanengue em um SaaS com aprovação manual: donos se cadastram, escolhem um plano e **aguardam a aprovação do super admin** (prazo de até 24h) antes de gerenciar lojas e funcionários.

```text
Dono se cadastra → escolhe plano + nome do negócio → tenant PENDING
 │
 Super admin aprova/rejeita (≤ 24h)
 │
 ┌───────────┴───────────┐
 Aprovado Rejeitado
 │ │
 Dono cria lojas e Dono vê o motivo
 funcionários (limites e pode sair
 do plano) (refazer cadastro)
```

---

## Papéis

| Papel | Como é identificado | O que pode fazer |
| ----- | ------------------- | ---------------- |
| **Super admin** | Papel em banco (`public.super_admins`) | Aprovar/rejeitar tenants, decidir upgrades de plano e criar/editar planos (painel administrativo) |
| **Dono** | `tenants.owner_user_id = auth.uid()` | **Acesso total:** solicitar acesso, criar lojas, criar contas de funcionários, pedir upgrade de plano e operar o ERP. Único papel que gerencia lojas/funcionários/plano/ajustes (módulo Lojas) |
| **Gerente** | Vínculo em `store_employees` com `role = 'manager'` | **Operação completa:** vendas, produtos (incl. **criar**), financeiro, fiado, clientes, **compras e relatórios** — mas SEM gestão de lojas/funcionários/plano/ajustes (só do dono) |
| **Funcionário** | Vínculo em `store_employees` com `role = 'employee'` | **Apenas operação diária:** vendas, produtos (lista/vende, **não cria**), financeiro, fiado e clientes — SEM criar produtos, SEM compras, SEM relatórios, SEM gestão |

### Matriz de acesso (Aug 7)

| Módulo | Dono | Gerente | Funcionário |
| ------ | ---- | ------- | ----------- |
| Vendas / Produtos (listar/vender) / Financeiro / Fiado / Clientes | ✓ | ✓ | ✓ |
| **Criar produto** (FAB "Novo produto") | ✓ | ✓ | ✗ |
| Compras | ✓ | ✓ | ✗ |
| Relatórios | ✓ | ✓ | ✗ |
| Lojas (lojas/funcionários/plano/ajustes) | ✓ | ✗ | ✗ |

- **UI (apenas UX):** o dashboard oculta os cards de Compras/Relatórios para funcionários e o card de Lojas para quem não é dono — o `currentAccessLevelProvider` (`account_providers.dart`) resolve o nível do usuário logado a partir de `tenants.owner_user_id` ou do maior cargo entre os vínculos em `store_employees`;
- **Produtos (Aug 7):** o funcionário comum **não cria produto** — só lista e vende. O FAB "Novo produto" (e a ação no estado vazio) é ocultado para `currentAccessLevelProvider == employee`; dono e gerente mantêm o cadastro. O servidor também restringe o INSERT (`products_insert` via `is_my_store`);
- **Servidor (autoridade):** a RPC `process_purchase` e as políticas RLS de `purchases`/`purchase_items` exigem `public.is_manager_of_store(store_id)` (dono ou gerente). Mesmo um cliente modificado que chame o PostgREST direto é bloqueado — o banco é o portão final. A gestão de lojas/funcionários/plano/ajustes já era exclusiva do dono via políticas `is_tenant_owner`.

Consolidado em `supabase/upgrade.sql` (Partes 4 e 19 — helpers + guardas de RPC + políticas).

### Super admin (papel baseado em banco)

O papel do super admin vive na **tabela `public.super_admins`** do banco (Supabase) — **nunca** em e-mail hardcoded:

- O `AuthGate` consulta o papel do usuário logado via RPC `is_super_admin` (`admin_providers.dart` → `isSuperAdminProvider`) e, se confirmado, abre o `AdminShell`;
- **Toda decisão administrativa é autorizada pelo RLS no servidor** (`public.is_super_admin()` consulta a tabela) — o cliente apenas decide a navegação;
- Para promover um usuário a super admin (SQL Editor do projeto):

```sql
INSERT INTO public.super_admins (user_id)
SELECT id FROM auth.users WHERE email = 'admin@seudominio.com'
ON CONFLICT (user_id) DO NOTHING;
```

- A tabela tem RLS habilitado **sem nenhuma política** + `REVOKE` explícito: só a função `SECURITY DEFINER` a acessa — o PostgREST não a expõe a anon/authenticated.

---

## Entidades (domínio)

| Entidade | Campos principais | Papel |
| -------- | ----------------- | ----- |
| `Plan` | `priceMonthly`, `maxStores`, `maxEmployees`, `isActive` | Limita a estrutura de cada tenant (nº de lojas e funcionários) |
| `Tenant` | `ownerUserId`, `businessName`, `planId`, `status` (`pending/approved/rejected`), `rejectionReason`, `approvedAt` | A unidade organizacional — o "contrato de acesso" do dono |
| `Store` | `tenantId`, `name`, `address` | Lojas do tenant — cada loja tem **estoque, vendas, caixa, fiado, clientes e compras próprios** (escopo por `store_id`) |
| `StoreEmployee` | `tenantId`, `storeId`, `userId`, `fullName`, `email`, `role` (`manager/employee`) | Vínculo de conta de usuário a uma loja |
| `PlanRequest` | `tenantId`, `currentPlanId`, `requestedPlanId`, `status` | Pedido de upgrade decidido pelo super admin |

> ✓ **Fase 2 implementada:** os módulos de negócio (produtos, vendas, financeiro, fiado, clientes, compras) são escopados por **loja** (`store_id`) — cada registro carrega a loja à qual pertence, o app filtra por loja em toda leitura/escrita e o servidor (trigger anti-forja + RLS) impede que um usuário escreva em lojas de fora do seu acesso. O seletor de loja ativa (no topo de todas as telas) troca o escopo dos dados exibidos.

---

## Casos de uso (camada de Contas)

| Caso de uso | Papel | Regra principal |
| ----------- | ----- | --------------- |
| `RequestTenantAccessUseCase` | Dono | Cria o tenant com `status = pending` (valida nome do negócio e plano) |
| `GetMyTenantUseCase` | Dono/Funcionário | Resolve o tenant do usuário (como dono ou via `store_employees`) |
| `ApproveTenantUseCase` / `RejectTenantUseCase` | Super admin | Aprova (marca `approved_at`) ou rejeita (grava `rejection_reason`) |
| `GetPendingTenantsUseCase` / `GetAllTenantsUseCase` | Super admin | Lista solicitações / histórico de tenants |
| `AddStoreUseCase` | Dono | **Limite do plano:** lança `PlanLimitExceededException` se `maxStores` atingido; exige tenant aprovado |
| `AddEmployeeUseCase` | Dono | **Limite do plano:** `maxEmployees` por tenant; a loja precisa pertencer ao tenant |
| `GetStoresUseCase` / `GetEmployeesUseCase` | Dono | Lista lojas/funcionários do tenant |
| `RequestPlanUpgradeUseCase` | Dono | Valida plano diferente do atual, tenant aprovado e ausência de pedido pendente |
| `DecidePlanRequestUseCase` | Super admin | Aprovar → troca o plano do tenant; rejeitar → apenas marca o pedido |
| `GetPendingPlanRequestsUseCase` | Super admin | Lista upgrades pendentes |
| `AddPlanUseCase` / `UpdatePlanUseCase` | Super admin | Cria/edita planos (valida nome, limites ≥ 1 e preço ≥ 0) |
| `GetPlansUseCase` / `GetAllPlansUseCase` | Todos/Admin | Planos ativos (escolha) / todos os planos (painel) |

---

## Fluxo de acesso do dono (AuthGate)

```text
Sessão ativa (AppUser)
 ├─ papel is_super_admin (RPC) = true → AdminShell (painel do super admin)
 └─ senão → GetMyTenantUseCase(user.id)
 ├─ null → TenantOnboardingScreen (escolher plano + negócio)
 ├─ status pending → TenantPendingScreen ("aguardando aprovação ≤ 24h")
 ├─ status rejected → TenantRejectedScreen (motivo da rejeição)
 └─ status approved → AppShell (ERP) — acesso à gestão de Lojas
```

As telas de estado (`pending`/`rejected`) não expõem o ERP: o dono só operacionaliza após a aprovação.

---

## Painel do Super Admin

`lib/presentation/screens/admin/` — shell com 3 abas:

1. **Solicitações** (`admin_tenants_screen.dart`): cards de tenants `pending` com botões **Aprovar** / **Rejeitar** (dialog pede o motivo) + alternância para o histórico completo;
2. **Planos** (`admin_plans_screen.dart`): CRUD de planos (nome, preço mensal, máx. lojas, máx. funcionários, ativo/inativo);
3. **Upgrades** (`admin_plan_requests_screen.dart`): pedidos de mudança de plano com **Aprovar** (aplica o novo plano ao tenant) / **Rejeitar**.

Providers de estado em `lib/presentation/controllers/admin_providers.dart` (`pendingTenantsProvider`, `allTenantsProvider`, `allPlansProvider`, `pendingPlanRequestsProvider`).

---

## Gestão de Lojas (dono)

`lib/presentation/screens/stores/stores_screen.dart` (acessado pelo card **Lojas** no dashboard):

- **Card do plano:** nome, descrição, medidores de uso (`lojas usadas/máx` e `funcionários usados/máx`) e botão **Upgrade**;
- **Aba Lojas:** lista e criação de lojas (sheet com nome + endereço) — respeita `maxStores`;
- **Aba Funcionários:** lista com loja, cargo e status; criação via sheet com **nome, e-mail e senha** (o dono cria a conta de acesso) + escolha de loja e cargo (`manager`/`employee`) — respeita `maxEmployees`;
- **Aba Upgrades:** histórico dos pedidos do tenant (pendente/aprovado/rejeitado).

> **Ativação/desativação de funcionários (Aug 7):** o DONO ativa e desativa pelo **interruptor** no card do funcionário (com diálogo de confirmação — "Desativar Carlos?"). O funcionário desativado perde o acesso **imediatamente**: o **app** mostra a tela "Acesso suspenso" no AuthGate (com sair da conta) e o **servidor** nega toda operação nas lojas — `is_my_store`/`is_manager_of_store` passam a exigir vínculo **ativo** (`is_active = TRUE`), então RLS e guardas das RPCs bloqueiam até um cliente modificado. O bloqueio no app é **reativo e instantâneo**: no modo Supabase o `AuthGate` assina Realtime (`postgres_changes` em `store_employees` filtrado pelo usuário — a tabela é publicada no `supabase_realtime`, Parte 20 do upgrade) e derruba a sessão do funcionário logado em OUTRO dispositivo na hora em que o dono desativa; no modo local (e com websocket fora do ar) um timer de 30s re-busca os vínculos como fallback. A coluna `store_employees.is_active` nasce `DEFAULT TRUE` (funcionários existentes seguem ativos) e a mudança de status vai pela RPC `set_employee_active` (SECURITY DEFINER, só o dono; idempotente).

> **Criação da conta do funcionário:** o app chama a RPC `create_employee_account` (`SECURITY DEFINER` no schema), que cria a conta no servidor por **inserção direta em `auth.users` + `auth.identities`** (hash bcrypt via pgcrypto, `email_confirmed_at = now()` — confirmação imediata, sem e-mail, nada de rate limit; o Supabase atual removeu a função interna `auth.admin_create_user`, e a Admin API do GoTrue é HTTP/assíncrona — quebraria a atomicidade) **e o vínculo em `store_employees` na MESMA transação** — se o vínculo falhar (ex.: limite de funcionários do plano atingido), a conta é desfeita junto: **sem contas órfãs**. A senha é definida pelo dono e a sessão do dono nunca é substituída. Em dev sem Supabase, id sintético + vínculo via repositório (memória).

---

## Escopo por loja (Fase 2 — implementada)

Cada entidade de negócio ganhou `storeId` (default `'st1'`); todos os `getAll` dos repositórios/datasources exigem `storeId` e os sheets de criação (venda, fiado, transação, produto, cliente, compra) carimbam a **loja ativa**.

### Loja ativa e seletor

- `ActiveStoreNotifier` / `activeStoreIdProvider` (em `account_providers.dart`): resolve a loja ativa do usuário — a **primeira loja** do tenant por padrão; se a loja selecionada sumir da lista, volta automaticamente para a primeira (nunca fica órfã);
- `StoreSelectorBar` (`lib/presentation/widgets/store_selector_bar.dart`): barra no **topo de todas as telas** do `AppShell` com um chip por loja (visível apenas quando o tenant tem 2+ lojas); tocar num chip troca a loja ativa;
- Todos os providers de módulo (`productsProvider`, `salesListProvider`, `cashFlowProvider`, `pendingDebtsProvider`, `customersProvider`, `purchasesProvider`) escopam pela loja ativa — trocar a loja recarrega os dados automaticamente;
- O **dashboard** exibe o nome da loja ativa sob o cumprimento, deixando claro a qual loja os indicadores pertencem.

### Envolvidos (app)

| Camada | Mudanças |
| ------ | -------- |
| Entidades | `Product`, `Sale`, `FinancialTransaction`, `Debt`, `Customer`, `Purchase` com `storeId` (default `'st1'` para compatibilidade de testes) |
| Contratos | `getAll({required String storeId})` nos 6 repositórios e datasources locais |
| SQLite | coluna `store_id` + migração para bancos existentes + seed com dados em `st1` e `st2` |
| Supabase | colunas `store_id` + trigger anti-forja `set_record_store_id` + índices por loja + seed multi-loja |
| Use cases | getters recebem `storeId`; `ProcessSale`/`ProcessPurchase`/`AddDebt`/`SettleDebt` herdam/carimbam a loja |
| UI | `StoreSelectorBar` + providers escopados + sheets carimbando a loja ativa |

---

## Banco (Supabase — `supabase/schema.sql`)

Novas tabelas: `plans`, `tenants`, `stores`, `store_employees`, `plan_requests` — todas com **RLS** e **triggers anti-forja**:

| Tabela | RLS (resumo) | Trigger |
| ------ | ------------- | ------- |
| `plans` | Leitura: autenticados · escrita: super admin | — |
| `tenants` | Dono/funcionário lê · todos criam a própria solicitação (`owner_user_id = auth.uid()`) · super admin decide | `set_tenant_owner` (dono = `auth.uid()`) |
| `stores` | Dono do tenant/funcionários leem · dono/super admin escrevem | `set_store_tenant` (tenant = do dono) |
| `store_employees` | Funcionário lê a si mesmo · dono/super admin gerem | `set_employee_tenant` (tenant herdado da loja) |
| `plan_requests` | Dono lê/cria · super admin decide | `set_plan_request_tenant` (tenant do dono) |

As tabelas de negócio (`products`, `sales`, `financial_transactions`, `debts`, `customers`, `purchases`) ganharam a coluna `store_id` + índices por loja e o trigger **`set_record_store_id`** (Fase 2):

- **Defesa em profundidade:** se o cliente enviar um `store_id` que não é do usuário (dono do tenant ou funcionário vinculado), o trigger reescreve para a primeira loja acessível — ninguém escreve em loja de fora do próprio acesso;
- **Helper `public.is_my_store(store_id)`:** dono do tenant vale para todas as lojas do tenant; funcionário vale para a loja do vínculo **somente com `is_active = TRUE`** (Aug 7 — funcionário desativado perde o acesso na hora);
- **Helper `public.is_manager_of_store(store_id)` (Aug 6; exigência de vínculo ativo em Aug 7):** dono do tenant ou funcionário vinculado com `role = 'manager'` **e ativo** — usado na guarda do `process_purchase` e nas políticas RLS de compras (nível gerencial);
- Sem sessão (ex.: seed via SQL Editor) o valor informado é preservado.

- **Helper `public.is_super_admin()`:** consulta a tabela `public.super_admins` (papel em banco) — `SECURITY DEFINER` para dispensar o RLS da própria tabela;
- **Helper `public.is_tenant_owner(tenant_id)`:** verifica `tenants.owner_user_id = auth.uid()`;
- **`is_my_store`/`is_tenant_owner` são `SECURITY DEFINER`** (`search_path` fixado): rodam DENTRO das políticas e consultam tabelas que têm políticas próprias (`stores`/`tenants`/`store_employees`) — como definers ignoram o RLS internamente, quebrando o ciclo entre tabelas e impedindo o `54001 max_stack_depth` em varreduras completas (regressão encontrada em Aug 6 num Supabase cloud com schema antigo; consolidado em `supabase/upgrade.sql`, Parte 3);
- **Guardas nos triggers:** quando não há sessão (ex.: inserts via SQL Editor), o valor informado é preservado — o catálogo da Parte 2 continua funcionando.

### Catálogo (sem seed)

- 3 planos (`pl1` Essencial, `pl2` Profissional, `pl3` Empresa) — o **catálogo real** de assinatura, inserido na Parte 2 do `schema.sql` e espelhado no `PlanCatalog` local (modo sem Supabase);
- **Nenhum dado de demonstração:** o banco não semeia tenant, lojas, funcionários nem dados de negócio. Todo usuário novo passa pelo fluxo real: cadastro → onboarding (escolher plano) → solicitação `pending` → aprovação manual do super admin.
- Bases que já receberam o seed antigo são limpas com `supabase/cleanup_demo_data.sql`.

---

## Limites de plano (onde são aplicados)

| Recurso | Fase 1 (app) | Fase 2 (servidor) |
| ------- | ------------ | ----------------- |
| Máx. lojas | `AddStoreUseCase` (lança `PlanLimitExceededException`) | Trigger/RPC no Postgres |
| Máx. funcionários | `AddEmployeeUseCase` | Trigger/RPC no Postgres |

O `CHECK (max_stores >= 1)` e `CHECK (max_employees >= 1)` no banco são a salvaguarda final contra planos inválidos.

---

## Documentos relacionados

- [Autenticação](06-autenticacao.md) — sessão e o papel do `AuthGate`.
- [Camada de dados](04-dados.md) — schema e datasources.
- [Apresentação](05-apresentacao.md) — telas e providers.
- [Guia do desenvolvedor](10-guia-desenvolvedor.md) — como promover um super admin e adicionar módulos.
