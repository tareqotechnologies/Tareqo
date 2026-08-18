# 06 — Authentication

Authentication is the first step of the **SaaS multi-tenant** model: each merchant is a *tenant*, and the user's identity is what separates each store's data (in the future, via Row Level Security on Supabase's Postgres).

---

## General flow

```text
main.dart
 └─ SupabaseBootstrap.initialize() # Supabase.initialize(url, anonKey)
 └─ ServiceLocator.initialize() # registers IAuthRepository → AuthRepositoryImpl → SupabaseAuthRemoteDataSourceImpl
 └─ runApp(ProviderScope(...))

AuthGate (root screen)
 └─ authStateProvider (StreamProvider<AppUser?>)
 ├─ loading → splash (restoring persisted session)
 ├─ user == null → LoginScreen
 └─ user != null → routes by role (see Multi-tenancy) ├─ super admin (DB-backed role) → AdminShell
 ├─ no tenant → TenantOnboardingScreen (pick a plan)
 ├─ tenant pending → TenantPendingScreen (≤ 24h)
 ├─ tenant rejected → TenantRejectedScreen (reason)
 └─ tenant approved → AppShell (ERP)
```

The full chain (all conversion of the Supabase `User` into the domain `AppUser` happens in the datasource):

```text
LoginScreen → SignInUseCase → IAuthRepository → AuthRepositoryImpl → AuthRemoteDataSource → SupabaseAuthRemoteDataSourceImpl → gotrue (Supabase)
```

---

## Configuration

`lib/core/config/supabase_config.dart`:

```dart
static const String url = String.fromEnvironment(
 'SUPABASE_URL', defaultValue: 'https://dotklbpqmlnhcdifiukd.supabase.co',
);
static const String anonKey = String.fromEnvironment(
 'SUPABASE_ANON_KEY', defaultValue: 'eyJ...', // anon key public by design
);
static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
```

- The **anon key is public by design** in Supabase (it is embedded in the client) — the real security comes from **RLS**. **Never** put the *service role key* in the client.
- **Flavors (dev/prod):** credentials are provided via `--dart-define-from-file` (`env/dev.env` committed, `env/prod.env` gitignored). `FLUTTER_APP_FLAVOR` is a **reserved define** injected from `--flavor` — do not set it manually:

```bash
flutter run --flavor dev --dart-define-from-file=env/dev.env
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env
```

- **Fail-fast in release (S2):** a **release** build with the embedded defaults (or without `--flavor prod`) throws at startup — a published APK can never silently point at the dev project. In debug the defaults are fine for development.
- Without credentials, `SupabaseBootstrap.initialize()` only logs a warning; the app opens and `authStateProvider` emits `null` (signed out) — sign in fails with a friendly message instead of crashing.

---

## Implemented flows

### Sign in (`SignInUseCase` → `signInWithPassword`)

1. `LoginScreen._submit()` validates the form (email with domain/TLD, password **≥ 8** characters, confirmation match on signup);
2. Calls `signInUseCaseProvider` → `IAuthRepository.signIn` → gotrue;
3. **Success:** the `authStateChanges` stream emits the `AppUser` → `AuthGate` switches to `AppShell` **automatically** (the screen does not navigate manually);
4. **Failure:** detailed log via `debugPrint` + generic SnackBar ("Não foi possível entrar. Verifique e-mail e senha.") — does not expose provider internals.

### Sign up (`SignUpUseCase` → `signUp`)

1. Form with name (optional), email and password;
2. `signUp(email, password, data: {'full_name': ...})`;
3. With **email confirmation enabled** (Supabase default), `response.user` may be `null` — the account is created but the session only comes after confirmation. The UI shows: *"Conta criada! Confirme seu e-mail para entrar."*
4. In that case the datasource returns an `AppUser` with a **placeholder id** (`fallbackEmail`) — **no data must be associated with this id**; the real session arrives after confirmation.
5. **Deep link (Aug 8):** the confirmation link in the email points to `dumbhanengue://callback` (the project `site_url`) — the OS opens the app, and the `DeepLinkHandler` (`lib/core/network/deep_link_handler.dart`, `app_links` package) hands the URI to gotrue (`getSessionFromUrl`), which completes the confirmation and the session stream reacts on its own. Without this, the link landed on `http://localhost:3000` (default) and the confirmation never completed.

> **Email send rate limit (Aug 8):** on the free plan, when the sending quota
> is exhausted (~2/hour), GoTrue answers **429 "email rate limit exceeded"** —
> the `LoginScreen` catches it (`AuthApiException` with `statusCode 429`) and
> shows *"Too many attempts in a row. Please wait about an hour and try
> again."* (`loginRateLimitError` key, pt/en) instead of the generic error. It
> is transient: sign-up resumes on the next window. For production, see the
> custom SMTP plan in [Go-Live](14-go-live-ops.md) §2.6.

### Sign out (`SignOutUseCase` → `signOut`)

"Sign out" button on the dashboard → `signOutUseCaseProvider.call()` → the stream emits `null` → `AuthGate` returns to the login.

---

## Persistent session (how the app "remembers" the user)

1. **Storage:** the session is persisted via a **custom `LocalStorage` wired into `Supabase.initialize`** — [`SecureSupabaseLocalStorage`](../pt/07-seguranca.md) backs it with **`flutter_secure_storage` (Keychain/Keystore)** on native platforms (the SDK default would use `shared_preferences` plaintext — fixed Aug 6). The PKCE code verifier uses the same secure backend. On **web** the SDK default (`window.localStorage`) is kept — `flutter_secure_storage` 10.x has no web support (documented limitation).
2. **Boot restore:** `onAuthStateChange` re-emits the saved session. The `AuthGate` reacts: session restored → straight to the dashboard, no new login.
3. **Automatic renewal:** gotrue renews the access token with the refresh token before it expires.
4. **Reactivity:** sign in/out emit events on the same stream; navigation and any session-dependent state react automatically.

> **Warning:** **Migration note:** installations with a session previously stored by the SDK default will sign out **once** after upgrading (the session moves to the Keychain/Keystore).

---

## Access approval (owner → tenant)

After signing up, the owner goes through **onboarding** (`TenantOnboardingScreen`): picks the plan and enters the business name → creates the request (`RequestTenantAccessUseCase`). The `AuthGate` then routes by tenant status: `pending` (waiting screen ≤ 24h), `rejected` (reason) or `approved` (full ERP). The super admin decides requests in the admin panel — details in [Multi-tenancy and Super Admin](11-multitenancy.md).

## Deactivated employee (access suspended)

The **owner** activates/deactivates employees in the **Employees** tab of the Stores module (switch + confirmation; `set_employee_active` RPC). For a deactivated employee, the block is **two-layered**:

- **App:** the `AuthGate` resolves the user's links in `store_employees`; if all have `is_active = false`, it shows the **"Access suspended"** screen (`_BlockedEmployeeScreen` — with a sign-out button) instead of the ERP. The block is **reactive and instant**: in Supabase mode the app subscribes to **Realtime** (`postgres_changes` on `store_employees` filtered by `user_id = auth.uid()`) — when the owner deactivates the employee on ANOTHER device, the event arrives immediately and the session drops onto the suspended screen **without restarting the app** (reactivation restores access through the same flow). A **fallback timer** (30s, `employeePollIntervalProvider`, centralized in the `employeesPollingProvider`) re-fetches the links in local mode and when the websocket is down — and the whole polling (timer + Realtime) is **cancelled on sign-out** (`autoDispose`), with nothing running in the background;
- **Server (authority):** `is_my_store`/`is_manager_of_store` require an **active** link — RLS and RPC guards deny every operation in the stores, even for a modified client calling PostgREST directly.

Implementation details (the `store_employees.is_active` column, RPC and helpers) in [Multi-tenancy and Super Admin](11-multitenancy.md).

---

## Multi-tenant and RLS (why authentication comes first)

1. **Data isolation:** without login there is no way to separate each store's data in the same database;
2. **Security in the database:** Supabase applies the JWT in **Row Level Security** — `auth.uid() = user_id` **or** `public.is_my_store(store_id)` (tenant owner = all stores; linked employee = their store) — even if the UI leaks data, the database filters it;
3. **Revenue model:** identity identifies who pays, which plan and which quotas apply;
4. **Onboarding/retention:** persistent session reduces daily friction.

> ✓ **Current state:** authentication + **full SaaS sync** are implemented — business modules (products, sales, finance, credit, customers, purchases) persist per tenant **and per store** in Supabase with RLS + anti-forgery triggers and atomic money RPCs.

---

## Related documents

- [Security](07-security.md) — secure storage and session responsibility limits.
- [Domain](03-domain.md) — `IAuthRepository` and the auth use cases.
- [Presentation](05-presentation.md) — `AuthGate` and `LoginScreen`.
- [Multi-tenancy and Super Admin](11-multitenancy.md) — tenant approval, plans, stores and employees.
