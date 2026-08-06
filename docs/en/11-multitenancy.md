# 11 — Multi-tenancy, Plans and Super Admin

The **Accounts** layer turns Dumbhanengue into a SaaS with manual approval: owners sign up, pick a plan and **wait for the super admin to approve** (within 24h) before they can manage stores and employees.

```text
Owner signs up → picks plan + business name → tenant PENDING
                                                    │
                        Super admin approves/rejects (≤ 24h)
                                                    │
                                        ┌───────────┴───────────┐
                                     Approved               Rejected
                                        │                       │
                        Owner creates stores and      Owner sees the reason
                        employees (plan limits)       and can sign out
                                                      (re-register)
```

---

## Roles

| Role | How it is identified | What it can do |
| ---- | -------------------- | -------------- |
| **Super admin** | DB-backed role (`public.super_admins`) | Approve/reject tenants, decide plan upgrades and create/edit plans (admin panel) |
| **Owner** | `tenants.owner_user_id = auth.uid()` | **Full access:** request access, create stores, create employee accounts, request plan upgrades and operate the ERP. Only role that can manage stores/employees/plan/settings (`Stores` module) |
| **Manager** | Link in `store_employees` with `role = 'manager'` | **Full operations:** sells, products, finance, credit, customers, **purchases and reports** — but **no** store/employee/plan/settings management (owner only) |
| **Employee** | Link in `store_employees` with `role = 'employee'` | **Daily operations only:** sells, products, finance, credit and customers — **no** purchases, **no** reports, **no** management |

### Access-level matrix (Aug 6)

| Module | Owner | Manager | Employee |
| ------ | ----- | ------- | -------- |
| Sales / Products / Finance / Credit / Customers | ✅ | ✅ | ✅ |
| Purchases | ✅ | ✅ | ❌ |
| Reports | ✅ | ✅ | ❌ |
| Stores (stores/employees/plan/settings) | ✅ | ❌ | ❌ |

- **UI (UX only):** the dashboard hides the Purchases/Reports cards for employees and the Stores card for anyone who is not the owner — `currentAccessLevelProvider` (`account_providers.dart`) resolves the signed-in user's level from `tenants.owner_user_id` or the highest role among their `store_employees` links;
- **Server (authority):** the `process_purchase` RPC and the `purchases`/`purchase_items` RLS policies require `public.is_manager_of_store(store_id)` (owner or manager). Even a modified client that calls PostgREST directly is blocked — the DB is the final gate. Store/employee/plan/settings management was already owner-only via the `is_tenant_owner`-based RLS policies.

Consolidated in `supabase/upgrade.sql` (Part 4 — helper + RPC guard + policies).

### Super admin (DB-backed role)

The super admin role lives in the **`public.super_admins` table** in the database (Supabase) — **never** in a hardcoded email:

- The `AuthGate` resolves the signed-in user's role via the `is_super_admin` RPC (`admin_providers.dart` → `isSuperAdminProvider`) and opens `AdminShell` when confirmed;
- **Every administrative decision is authorized by server-side RLS** (`public.is_super_admin()` queries the table) — the client only decides navigation;
- To promote a user to super admin (project SQL Editor):

```sql
INSERT INTO public.super_admins (user_id)
SELECT id FROM auth.users WHERE email = 'admin@yourdomain.com'
ON CONFLICT (user_id) DO NOTHING;
```

- The table has RLS enabled with **no policies** + explicit `REVOKE`: only the `SECURITY DEFINER` function accesses it — PostgREST does not expose it to anon/authenticated.

---

## Entities (domain)

| Entity | Main fields | Role |
| ------ | ----------- | ---- |
| `Plan` | `priceMonthly`, `maxStores`, `maxEmployees`, `isActive` | Limits each tenant's structure (number of stores and employees) |
| `Tenant` | `ownerUserId`, `businessName`, `planId`, `status` (`pending/approved/rejected`), `rejectionReason`, `approvedAt` | The organizational unit — the owner's "access contract" |
| `Store` | `tenantId`, `name`, `address` | Tenant's stores — each store has its **own stock, sales, cash, credit, customers and purchases** (scoped by `store_id`) |
| `StoreEmployee` | `tenantId`, `storeId`, `userId`, `fullName`, `email`, `role` (`manager/employee`) | Links a user account to a store |
| `PlanRequest` | `tenantId`, `currentPlanId`, `requestedPlanId`, `status` | Upgrade request decided by the super admin |

> ✅ **Phase 2 implemented:** the business modules (products, sales, finance, credit, customers, purchases) are scoped by **store** (`store_id`) — every record carries the store it belongs to, the app filters by store on every read/write, and the server (anti-forgery trigger + RLS) prevents a user from writing to stores outside their access. The active-store selector (at the top of every screen) switches the scope of the displayed data.

---

## Use cases (Accounts layer)

| Use case | Role | Main rule |
| -------- | ---- | --------- |
| `RequestTenantAccessUseCase` | Owner | Creates the tenant with `status = pending` (validates business name and plan) |
| `GetMyTenantUseCase` | Owner/Employee | Resolves the user's tenant (as owner or via `store_employees`) |
| `ApproveTenantUseCase` / `RejectTenantUseCase` | Super admin | Approves (sets `approved_at`) or rejects (stores `rejection_reason`) |
| `GetPendingTenantsUseCase` / `GetAllTenantsUseCase` | Super admin | Lists requests / tenant history |
| `AddStoreUseCase` | Owner | **Plan limit:** throws `PlanLimitExceededException` when `maxStores` is reached; requires approved tenant |
| `AddEmployeeUseCase` | Owner | **Plan limit:** `maxEmployees` per tenant; the store must belong to the tenant |
| `GetStoresUseCase` / `GetEmployeesUseCase` | Owner | Lists tenant stores/employees |
| `RequestPlanUpgradeUseCase` | Owner | Validates a different plan, approved tenant and no pending request |
| `DecidePlanRequestUseCase` | Super admin | Approve → switches the tenant's plan; reject → only marks the request |
| `GetPendingPlanRequestsUseCase` | Super admin | Lists pending upgrades |
| `AddPlanUseCase` / `UpdatePlanUseCase` | Super admin | Creates/edits plans (validates name, limits ≥ 1 and price ≥ 0) |
| `GetPlansUseCase` / `GetAllPlansUseCase` | Everyone/Admin | Active plans (selection) / all plans (panel) |

---

## Owner access flow (AuthGate)

```text
Active session (AppUser)
  ├─ role is_super_admin (RPC) = true → AdminShell (super admin panel)
  └─ otherwise → GetMyTenantUseCase(user.id)
       ├─ null             → TenantOnboardingScreen (pick plan + business name)
       ├─ status pending   → TenantPendingScreen ("waiting for approval ≤ 24h")
       ├─ status rejected  → TenantRejectedScreen (rejection reason)
       └─ status approved  → AppShell (ERP) — access to Stores management
```

The state screens (`pending`/`rejected`) do not expose the ERP: the owner can only operate after approval.

---

## Super Admin Panel

`lib/presentation/screens/admin/` — shell with 3 tabs:

1. **Requests** (`admin_tenants_screen.dart`): pending tenant cards with **Approve** / **Reject** buttons (dialog asks for the reason) + toggle for the full history;
2. **Plans** (`admin_plans_screen.dart`): plan CRUD (name, monthly price, max stores, max employees, active/inactive);
3. **Upgrades** (`admin_plan_requests_screen.dart`): plan-change requests with **Approve** (applies the new plan to the tenant) / **Reject**.

State providers in `lib/presentation/controllers/admin_providers.dart` (`pendingTenantsProvider`, `allTenantsProvider`, `allPlansProvider`, `pendingPlanRequestsProvider`).

---

## Stores management (owner)

`lib/presentation/screens/stores/stores_screen.dart` (reached from the **Stores** card on the dashboard):

- **Plan card:** name, description, usage meters (`stores used/max` and `employees used/max`) and an **Upgrade** button;
- **Stores tab:** list and creation of stores (sheet with name + address) — respects `maxStores`;
- **Employees tab:** list with store and role; creation via sheet with **name, email and password** (the owner creates the access account) + store and role selection (`manager`/`employee`) — respects `maxEmployees`;
- **Upgrades tab:** the tenant's request history (pending/approved/rejected).

> **Employee account creation:** the app calls the `create_employee_account` RPC (`SECURITY DEFINER` in the schema), which creates the account server-side by **inserting directly into `auth.users` + `auth.identities`** (pgcrypto bcrypt hash, `email_confirmed_at = now()` — immediate confirmation, no confirmation email, no provider rate limits; current Supabase removed the `auth.admin_create_user` internal function, and the GoTrue Admin API is HTTP/async which would break atomicity) **and the store link in `store_employees` in the same transaction** — if the link fails (e.g. the plan's employee limit is reached), the account is rolled back too: **no orphan accounts**. The password is set by the owner and the owner's session is never replaced. In local dev without Supabase, a synthetic id + repository link is used (in-memory).

---

## Store scoping (Phase 2 — implemented)

Every business entity gained `storeId` (default `'st1'`); all repository/data-source `getAll` calls require `storeId` and the creation sheets (sale, credit, transaction, product, customer, purchase) stamp the **active store**.

### Active store and selector

- `ActiveStoreNotifier` / `activeStoreIdProvider` (in `account_providers.dart`): resolves the user's active store — the tenant's **first store** by default; if the selected store disappears from the list, it falls back to the first one (never dangles);
- `StoreSelectorBar` (`lib/presentation/widgets/store_selector_bar.dart`): a bar at the **top of every screen** in `AppShell` with one chip per store (visible only when the tenant has 2+ stores); tapping a chip switches the active store;
- All module providers (`productsProvider`, `salesListProvider`, `cashFlowProvider`, `pendingDebtsProvider`, `customersProvider`, `purchasesProvider`) are scoped by the active store — switching stores reloads the data automatically;
- The **dashboard** shows the active store's name under the greeting, making it clear which store the KPIs belong to.

### What changed (app)

| Layer | Changes |
| ----- | ------- |
| Entities | `Product`, `Sale`, `FinancialTransaction`, `Debt`, `Customer`, `Purchase` with `storeId` (default `'st1'` for test compatibility) |
| Contracts | `getAll({required String storeId})` in the 6 repositories and local data sources |
| SQLite | `store_id` column + migration for existing databases + seed with data in `st1` and `st2` |
| Supabase | `store_id` columns + anti-forgery trigger `set_record_store_id` + per-store indexes + multi-store seed |
| Use cases | getters accept `storeId`; `ProcessSale`/`ProcessPurchase`/`AddDebt`/`SettleDebt` inherit/stamp the store |
| UI | `StoreSelectorBar` + scoped providers + sheets stamping the active store |

---

## Database (Supabase — `supabase/schema.sql`)

New tables: `plans`, `tenants`, `stores`, `store_employees`, `plan_requests` — all with **RLS** and **anti-forgery triggers**:

| Table | RLS (summary) | Trigger |
| ----- | ------------- | ------- |
| `plans` | Read: authenticated · write: super admin | — |
| `tenants` | Owner/employee read · everyone creates their own request (`owner_user_id = auth.uid()`) · super admin decides | `set_tenant_owner` (owner = `auth.uid()`) |
| `stores` | Tenant owner/employees read · owner/super admin write | `set_store_tenant` (tenant = owner's) |
| `store_employees` | Employee reads self · owner/super admin manage | `set_employee_tenant` (tenant inherited from store) |
| `plan_requests` | Owner reads/creates · super admin decides | `set_plan_request_tenant` (owner's tenant) |

The business tables (`products`, `sales`, `financial_transactions`, `debts`, `customers`, `purchases`) gained the `store_id` column + per-store indexes and the **`set_record_store_id`** trigger (Phase 2):

- **Defense in depth:** if the client sends a `store_id` that is not the user's (tenant owner or linked employee), the trigger rewrites it to the first accessible store — nobody writes to a store outside their own access;
- **Helper `public.is_my_store(store_id)`:** a tenant owner is valid for all of the tenant's stores; an employee is valid for their linked store;
- **Helper `public.is_manager_of_store(store_id)` (Aug 6):** a tenant owner or a linked employee with `role = 'manager'` — used by the `process_purchase` guard and the purchases RLS policies (managerial level);
- Without a session (e.g. seeding via SQL Editor) the provided value is preserved.

- **Helper `public.is_super_admin()`:** queries the `public.super_admins` table (DB-backed role) — `SECURITY DEFINER` to bypass the table's own RLS;
- **Helper `public.is_tenant_owner(tenant_id)`:** checks `tenants.owner_user_id = auth.uid()`;
- **`is_my_store`/`is_tenant_owner` are `SECURITY DEFINER`** (`search_path` pinned): they run inside the policies and query tables that carry their own policies (`stores`/`tenants`/`store_employees`) — as definers they ignore RLS internally, which breaks the cross-table policy cycle and prevents `54001 max_stack_depth` on full-table scans (regression found Aug 6 on Supabase cloud with an older schema; consolidated in `supabase/upgrade.sql`, Part 3);
- **Trigger guards:** when there is no session (e.g. seeding via SQL Editor), the provided value is preserved — the seed keeps working.

### Seed

- 3 plans (`pl1` Essential, `pl2` Professional, `pl3` Enterprise — same limits as the local `DemoSeed`);
- One **already-approved demo tenant** for the first user (`tn_demo`, plan `pl2`), with **two stores** (`st1` Downtown Store, `st2` Mall Store — to demonstrate the selector and per-store scoping) and the owner as manager of the Downtown Store (`e1`). To test the approval flow, register a **new account**;
- Business data spread across the stores (e.g. 7 products — 5 in `st1`, 2 in `st2`).

---

## Plan limits (where they are enforced)

| Resource | Phase 1 (app) | Phase 2 (server) |
| -------- | ------------- | ---------------- |
| Max stores | `AddStoreUseCase` (throws `PlanLimitExceededException`) | PostgreSQL trigger/RPC |
| Max employees | `AddEmployeeUseCase` | PostgreSQL trigger/RPC |

The `CHECK (max_stores >= 1)` and `CHECK (max_employees >= 1)` constraints in the database are the final safeguard against invalid plans.

---

## Related documents

- [Authentication](06-authentication.md) — session and the AuthGate role.
- [Data layer](04-data.md) — schema and datasources.
- [Presentation](05-presentation.md) — screens and providers.
- [Developer guide](10-developer-guide.md) — how to promote a super admin and add modules.
