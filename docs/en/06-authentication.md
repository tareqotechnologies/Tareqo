# 06 — Authentication

Authentication is the first step of the **SaaS multi-tenant** model: each merchant is a *tenant*, and the user's identity is what separates each store's data (in the future, via Row Level Security on Supabase's Postgres).

---

## General flow

```text
main.dart
  └─ SupabaseBootstrap.initialize()   # Supabase.initialize(url, anonKey)
  └─ ServiceLocator.initialize()      # registers IAuthRepository → AuthRepositoryImpl → SupabaseAuthRemoteDataSourceImpl
  └─ runApp(ProviderScope(...))

AuthGate (root screen)
  └─ authStateProvider (StreamProvider<AppUser?>)
       ├─ loading → splash (restoring persisted session)
       ├─ user == null → LoginScreen
       └─ user != null → routes by role (see Multi-tenancy)             ├─ super admin (DB-backed role) → AdminShell
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
  'SUPABASE_ANON_KEY', defaultValue: 'eyJ...',  // anon key public by design
);
static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
```

- The **anon key is public by design** in Supabase (it is embedded in the client) — the real security comes from **RLS**. **Never** put the *service role key* in the client.
- To point to another project (e.g.: production):

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

- Without credentials, `SupabaseBootstrap.initialize()` only logs a warning; the app opens and `authStateProvider` emits `null` (signed out) — sign in fails with a friendly message instead of crashing.

---

## Implemented flows

### Sign in (`SignInUseCase` → `signInWithPassword`)

1. `LoginScreen._submit()` validates the form (email with `@`, password ≥ 6 characters);
2. Calls `signInUseCaseProvider` → `IAuthRepository.signIn` → gotrue;
3. **Success:** the `authStateChanges` stream emits the `AppUser` → `AuthGate` switches to `AppShell` **automatically** (the screen does not navigate manually);
4. **Failure:** detailed log via `debugPrint` + generic SnackBar ("Não foi possível entrar. Verifique e-mail e senha.") — does not expose provider internals.

### Sign up (`SignUpUseCase` → `signUp`)

1. Form with name (optional), email and password;
2. `signUp(email, password, data: {'full_name': ...})`;
3. With **email confirmation enabled** (Supabase default), `response.user` may be `null` — the account is created but the session only comes after confirmation. The UI shows: *"Conta criada! Confirme seu e-mail para entrar."*
4. In that case the datasource returns an `AppUser` with a **placeholder id** (`fallbackEmail`) — **no data must be associated with this id**; the real session arrives after confirmation.

### Sign out (`SignOutUseCase` → `signOut`)

"Sign out" button on the dashboard → `signOutUseCaseProvider.call()` → the stream emits `null` → `AuthGate` returns to the login.

---

## Persistent session (how the app "remembers" the user)

1. **Storage:** `supabase_flutter` persists the session automatically — `flutter_secure_storage` (Android/iOS) and `localStorage` (web). Zero extra code.
2. **Boot restore:** `onAuthStateChange` re-emits the saved session (with `recoverSession` on web). The `AuthGate` reacts: session restored → straight to the dashboard, no new login.
3. **Automatic renewal:** gotrue renews the access token with the refresh token before it expires.
4. **Reactivity:** sign in/out emit events on the same stream; navigation and any session-dependent state react automatically.

---

## Access approval (owner → tenant)

After signing up, the owner goes through **onboarding** (`TenantOnboardingScreen`): picks the plan and enters the business name → creates the request (`RequestTenantAccessUseCase`). The `AuthGate` then routes by tenant status: `pending` (waiting screen ≤ 24h), `rejected` (reason) or `approved` (full ERP). The super admin decides requests in the admin panel — details in [Multi-tenancy and Super Admin](11-multitenancy.md).

---

## Multi-tenant and RLS (why authentication comes first)

1. **Data isolation:** without login there is no way to separate each store's data in the same database;
2. **Security in the database:** Supabase applies the JWT in **Row Level Security** (`user_id = auth.uid()`) — even if the UI leaks data, the database filters it;
3. **Revenue model:** identity identifies who pays, which plan and which quotas apply;
4. **Onboarding/retention:** persistent session reduces daily friction.

> ⚠️ **Current state:** authentication is implemented and functional, but the **business modules (products, sales, finance, credit) are not yet synced per tenant** — persistence is local (SQLite/in-memory). Syncing with Supabase and enabling RLS is the suggested next step (see [Overview](01-overview.md#current-state-and-next-steps)).

---

## Related documents

- [Security](07-security.md) — secure storage and session responsibility limits.
- [Domain](03-domain.md) — `IAuthRepository` and the auth use cases.
- [Presentation](05-presentation.md) — `AuthGate` and `LoginScreen`.
- [Multi-tenancy and Super Admin](11-multitenancy.md) — tenant approval, plans, stores and employees.
