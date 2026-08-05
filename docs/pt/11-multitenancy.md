# 11 — Multi-tenancy, Planos e Super Admin

A camada de **Contas** transforma o Dumbhanengue em um SaaS com aprovação manual: donos se cadastram, escolhem um plano e **aguardam a aprovação do super admin** (prazo de até 24h) antes de gerenciar lojas e funcionários.

```text
Dono se cadastra → escolhe plano + nome do negócio → tenant PENDING
                                                          │
                              Super admin aprova/rejeita (≤ 24h)
                                                          │
                                              ┌───────────┴───────────┐
                                         Aprovado                Rejeitado
                                              │                        │
                              Dono cria lojas e          Dono vê o motivo
                              funcionários (limites      e pode sair
                              do plano)                  (refazer cadastro)
```

---

## Papéis

| Papel | Como é identificado | O que pode fazer |
| ----- | ------------------- | ---------------- |
| **Super admin** | Papel em banco (`public.super_admins`) | Aprovar/rejeitar tenants, decidir upgrades de plano e criar/editar planos (painel administrativo) |
| **Dono** | `tenants.owner_user_id = auth.uid()` | Solicitar acesso, criar lojas, criar contas de funcionários, pedir upgrade de plano e operar o ERP |
| **Funcionário** | Vínculo em `store_employees` | Faz login e opera o ERP — escopo por **loja** (`store_id`) |

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

> ✅ **Fase 2 implementada:** os módulos de negócio (produtos, vendas, financeiro, fiado, clientes, compras) são escopados por **loja** (`store_id`) — cada registro carrega a loja à qual pertence, o app filtra por loja em toda leitura/escrita e o servidor (trigger anti-forja + RLS) impede que um usuário escreva em lojas de fora do seu acesso. O seletor de loja ativa (no topo de todas as telas) troca o escopo dos dados exibidos.

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
       ├─ null             → TenantOnboardingScreen (escolher plano + negócio)
       ├─ status pending   → TenantPendingScreen ("aguardando aprovação ≤ 24h")
       ├─ status rejected  → TenantRejectedScreen (motivo da rejeição)
       └─ status approved  → AppShell (ERP) — acesso à gestão de Lojas
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
- **Aba Funcionários:** lista com loja e cargo; criação via sheet com **nome, e-mail e senha** (o dono cria a conta de acesso) + escolha de loja e cargo (`manager`/`employee`) — respeita `maxEmployees`;
- **Aba Upgrades:** histórico dos pedidos do tenant (pendente/aprovado/rejeitado).

> **Criação da conta do funcionário:** o app usa o cadastro do Supabase (`EmployeeAccountService`) com o e-mail/senha definidos pelo dono. Se a confirmação de e-mail estiver ativa no projeto, o funcionário recebe um e-mail para confirmar antes do primeiro login. Em dev sem Supabase, um id sintético é usado (memória).

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
- **Helper `public.is_my_store(store_id)`:** dono do tenant vale para todas as lojas do tenant; funcionário vale para a loja do vínculo;
- Sem sessão (ex.: seed via SQL Editor) o valor informado é preservado.

- **Helper `public.is_super_admin()`:** consulta a tabela `public.super_admins` (papel em banco) — `SECURITY DEFINER` para dispensar o RLS da própria tabela;
- **Helper `public.is_tenant_owner(tenant_id)`:**
  verifica `tenants.owner_user_id = auth.uid()`;
- **Guardas nos triggers:** quando não há sessão (ex.: seed via SQL Editor), o valor informado é preservado — o seed continua funcionando.

### Seed

- 3 planos (`pl1` Essencial, `pl2` Profissional, `pl3` Empresa — mesmos limites do `DemoSeed` local);
- Um **tenant demo já aprovado** para o primeiro usuário (`tn_demo`, plano `pl2`), com **duas lojas** (`st1` Loja Centro, `st2` Loja Shopping — para demonstrar o seletor e o escopo por loja) e o dono como gerente da Loja Centro (`e1`). Para testar o fluxo de aprovação, cadastre uma **nova conta**;
- Dados de negócio distribuídos entre as lojas (ex.: 7 produtos — 5 em `st1`, 2 em `st2`).

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
