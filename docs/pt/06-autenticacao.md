# 06 — Autenticação

A autenticação é o primeiro passo do modelo **SaaS multi-tenant**: cada comerciante é um *tenant*, e a identidade do usuário é o que separa os dados de cada loja (no futuro, via Row Level Security no Postgres do Supabase).

---

## Fluxo geral

```text
main.dart
  └─ SupabaseBootstrap.initialize()   # Supabase.initialize(url, anonKey)
  └─ ServiceLocator.initialize()      # registra IAuthRepository → AuthRepositoryImpl → SupabaseAuthRemoteDataSourceImpl
  └─ runApp(ProviderScope(...))

AuthGate (tela raiz)
  └─ authStateProvider (StreamProvider<AppUser?>)
       ├─ loading → splash (restaurando sessão persistida)
       ├─ user == null → LoginScreen
       └─ user != null → roteia por papel (ver Multi-tenancy)             ├─ super admin (papel em banco) → AdminShell
            ├─ sem tenant → TenantOnboardingScreen (escolher plano)
            ├─ tenant pending → TenantPendingScreen (≤ 24h)
            ├─ tenant rejected → TenantRejectedScreen (motivo)
            └─ tenant approved → AppShell (ERP)
```

A cadeia completa (toda a conversão do `User` do Supabase para o `AppUser` do domínio acontece no datasource):

```text
LoginScreen → SignInUseCase → IAuthRepository → AuthRepositoryImpl → AuthRemoteDataSource → SupabaseAuthRemoteDataSourceImpl → gotrue (Supabase)
```

---

## Configuração

`lib/core/config/supabase_config.dart`:

```dart
static const String url = String.fromEnvironment(
  'SUPABASE_URL', defaultValue: 'https://dotklbpqmlnhcdifiukd.supabase.co',
);
static const String anonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY', defaultValue: 'eyJ...',  // anon key pública por design
);
static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
```

- A **anon key é pública por design** no Supabase (fica embutida no cliente) — a segurança real vem do **RLS**. **Nunca** coloque a *service role key* no cliente.
- Para apontar para outro projeto (ex.: produção):

```bash
flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJ...
```

- Sem credenciais, `SupabaseBootstrap.initialize()` apenas loga um aviso; o app abre e o `authStateProvider` emite `null` (deslogado) — o login falha com mensagem amigável em vez de quebrar.

---

## Fluxos implementados

### Login (`SignInUseCase` → `signInWithPassword`)

1. `LoginScreen._submit()` valida o formulário (e-mail com `@`, senha ≥ 6 caracteres);
2. Chama `signInUseCaseProvider` → `IAuthRepository.signIn` → gotrue;
3. **Sucesso:** o stream `authStateChanges` emite o `AppUser` → `AuthGate` troca para o `AppShell` **automaticamente** (a tela não navega manualmente);
4. **Falha:** log detalhado via `debugPrint` + SnackBar genérico ("Não foi possível entrar. Verifique e-mail e senha.") — não expõe detalhes internos do provedor.

### Cadastro (`SignUpUseCase` → `signUp`)

1. Formulário com nome (opcional), e-mail e senha;
2. `signUp(email, password, data: {'full_name': ...})`;
3. Com **confirmação de e-mail ativa** (padrão no Supabase), `response.user` pode ser `null` — a conta é criada mas a sessão só vem após confirmar. A UI mostra: *"Conta criada! Confirme seu e-mail para entrar."*
4. Nesse caso o datasource retorna um `AppUser` com **id placeholder** (`fallbackEmail`) — **nenhum dado deve ser associado a esse id**; a sessão real chega após a confirmação.

### Logout (`SignOutUseCase` → `signOut`)

Botão "Sair" no dashboard → `signOutUseCaseProvider.call()` → stream emite `null` → `AuthGate` volta para o login.

---

## Sessão persistente (como o app "lembra" o usuário)

1. **Armazenamento:** `supabase_flutter` persiste a sessão automaticamente — `flutter_secure_storage` (Android/iOS) e `localStorage` (web). Zero código extra.
2. **Restauração no boot:** `onAuthStateChange` reemite a sessão salva (com `recoverSession` na web). O `AuthGate` reage: sessão restaurada → dashboard direto, sem novo login.
3. **Renovação automática:** o gotrue renova o access token com o refresh token antes de expirar.
4. **Reatividade:** login/logout emitem eventos no mesmo stream; navegação e qualquer estado dependente reagem automaticamente.

---

## Aprovação de acesso (dono → tenant)

Após o cadastro, o dono passa pelo **onboarding** (`TenantOnboardingScreen`): escolhe o plano e informa o nome do negócio → cria a solicitação (`RequestTenantAccessUseCase`). O `AuthGate` então roteia pelo status do tenant: `pending` (tela de espera ≤ 24h), `rejected` (motivo) ou `approved` (ERP completo). O super admin decide as solicitações no painel administrativo — detalhes em [Multi-tenancy e Super Admin](11-multitenancy.md).

---

## Multi-tenant e RLS (por que a autenticação vem primeiro)

1. **Isolamento de dados:** sem login não há como separar os dados de cada loja no mesmo banco;
2. **Segurança no banco:** o Supabase aplica o JWT no **Row Level Security** (`user_id = auth.uid()`) — mesmo que a UI vaze dados, o banco os filtra;
3. **Modelo de receita:** a identidade identifica quem paga, qual plano e quais quotas aplicar;
4. **Onboarding/retenção:** sessão persistente reduz atrito diário.

> ⚠️ **Estado atual:** a autenticação está implementada e funcional, mas os **módulos de negócio (produtos, vendas, financeiro, fiado) ainda não são sincronizados por tenant** — a persistência é local (SQLite/memória). Sincronizar com o Supabase e ativar RLS é o próximo passo sugerido (ver [Visão geral](01-visao-geral.md#estado-atual-e-próximos-passos)).

---

## Documentos relacionados

- [Segurança](07-seguranca.md) — armazenamento seguro e limites de responsabilidade da sessão.
- [Domínio](03-dominio.md) — `IAuthRepository` e casos de uso de auth.
- [Apresentação](05-apresentacao.md) — `AuthGate` e `LoginScreen`.
- [Multi-tenancy e Super Admin](11-multitenancy.md) — aprovação de tenants, planos, lojas e funcionários.
