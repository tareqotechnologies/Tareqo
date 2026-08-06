# Changelog

Todas as mudanças relevantes do Dumbhanengue ERP são registradas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) — o projeto ainda não segue [SemVer](https://semver.org/) estrito (versionamento 1.0.0+1 até o primeiro release).

## [1.0.0+1] — Em desenvolvimento

### Adicionado (Aug 6, 2026 — sessão final: escala, resiliência, UX, releases)
- **KPIs do dashboard no servidor (W5/H2)**: nova RPC `SECURITY DEFINER get_dashboard_kpis(store_id, period_start)` — soma de vendas, saldo de caixa, pendências e stock num único `SELECT`, filtrada por `is_my_store` (elimina o `fold` client-side sobre tabelas inteiras). Novo `dashboardKpisProvider` usa a RPC no modo Supabase com **fallback local automático**; as 7 telas de mutação (venda, compra, dívida, quitação, transação, produto) invalidam o provider pós-escrita. Migração `supabase/migrations/009_dashboard_kpis.sql` + passo **[10/10]** no `sql_check.sh` (baseline + delta após `process_sale`).
- **Cliente HTTP com timeout + retry (W6/M11)**: novo `TimeoutRetryHttpClient` (`lib/core/network/`) injetado no `Supabase.initialize` — timeouts globais (10s connect / 30s receção) + retry com backoff para leituras idempotentes (GET/HEAD) em timeout/5xx/429. 5 testes. **Bug real corrigido:** o request é clonado a cada tentativa (o `http` não permite finalizar o mesmo `Request` duas vezes — `Can't finalize a finalized Request`).
- **Pull-to-refresh (W8)**: `RefreshIndicator` nas listas de Financeiro, Fiado e Relatórios (Produtos/Vendas/Compras/Clientes já tinham) — `refresh()` dos notifiers respetivos.
- **Acessibilidade (W8)**: teste de **escala de texto 2.0** (`test/presentation/screens/accessibility_text_scale_test.dart`) — o login continua utilizável com fonte máxima; limiar de stock baixo extraído para a constante nomeada `lowStockThreshold` (M8).
- **Ícones de app (W7/M2)**: ícone adaptativo Android (mipmap-anydpi-v26 + drawables), conjunto iOS completo (AppIcon.appiconset, 21 imagens) e web (favicon + manifest); originais em `assets/branding/` + gerador `tool/generate_icons_test.dart`; ícones default do template removidos.
- **Pipeline iOS (W1)**: `ios/Podfile` + lane `ios_testflight` no Fastfile + workflow `.github/workflows/ios.yml` (runner macOS: analyze → test → build+sign iOS → TestFlight, secrets do App Store Connect). `integration_test/access_levels_web_test.dart` (E2E browser do gating de acesso) + `test_driver/`.
- **Guia de go-live (W3)**: `docs/{pt,en}/14-go-live-ops.md` — secrets do CI (`KEYSTORE_BASE64`, senhas do keystore, `PLAY_*`), export base64 do keystore, checklist Play Console/2FA/e-mail de confirmação, passos do TestFlight.
- **`startOfDay` partilhado (W11/L2)**: helper central em `lib/core/utils/period_utils.dart` — remove a cópia duplicada em `finance_providers`/`reports_providers`.
- **Suíte completa: 301/301 testes** (era 287) · `flutter analyze` 0 issues · `sql_check.sh` **10/10** passos contra Postgres 16 real.

### Adicionado (Aug 6, 2026 — auditoria de follow-up)
- **Sessão do Supabase em armazenamento seguro**: nova `SecureSupabaseLocalStorage` (`lib/core/security/secure_supabase_local_storage.dart`) persiste a sessão (access + refresh tokens) no **Keychain/Keystore** via `flutter_secure_storage`, em vez do default do SDK (`shared_preferences` — texto claro). Conectada no `SupabaseBootstrap` via `authOptions: FlutterAuthClientOptions(localStorage: …)` (plataformas nativas; web mantém o default — limitação documentada). O **code verifier do PKCE** também passou a usar o armazenamento seguro (`SecureGotrueAsyncStorage`) — nenhum material de autenticação fica em texto claro no dispositivo.
  > ⚠️ **Nota de migração:** instalações que já tinham uma sessão persistida no `shared_preferences` serão deslogadas UMA vez após esta mudança (a sessão passa a viver no Keychain/Keystore).
- **Migração 004** (`supabase/migrations/004_settle_debt_realization_date.sql`): `settle_debt` carimba a **data de realização** (`date = now()`) na pendência vinculada — alinhando o fluxo de caixa do modo SaaS ao modo local (SQLite). `schema.sql` atualizado na mesma semântica.
- **Teste** de `SecureSupabaseLocalStorage` (5 casos: persist, hasAccessToken, accessToken, remove, initialize) — `test/core/security/secure_supabase_local_storage_test.dart`.
- **`CHANGELOG.md`** (este arquivo).

### Adicionado (Aug 6, 2026 — matriz de acesso)
- **Níveis de acesso distintos por papel** (dono/gerente/funcionário):
  - **UI:** novo `currentAccessLevelProvider` (`account_providers.dart`) resolve o nível do usuário logado (dono via `tenants.owner_user_id`, ou o **maior cargo** entre os vínculos em `store_employees`). O dashboard oculta os cards de **Compras/Relatórios para funcionários** e o card de **Lojas para quem não é dono** (gerente continua com operação completa, sem gestão).
  - **Servidor (autoridade):** novo helper `SECURITY DEFINER` `public.is_manager_of_store(store_id)` (dono OU funcionário com `role = 'manager'`); a RPC `process_purchase` passou a exigir `is_manager_of_store`; as políticas RLS de `purchases`/`purchase_items` (leitura E escrita) também — um funcionário não registra nem lê compras, mesmo chamando o PostgREST diretamente. Migração `supabase/migrations/007_manager_purchase_gate.sql` (idempotente) + `schema.sql` atualizado.
  - **Testes:** regressão `[8/8]` no `sql_check.sh` (funcionário bloqueado em compras — helper, RPC e RLS; gerente autorizado com efeitos completos) + testes de widget do dashboard (funcionário não vê Compras/Relatórios/Lojas; gerente vê Compras/Relatórios mas não Lojas).

### Corrigido (Aug 6, 2026)
- **RLS sem recursão (regressão `54001 max_stack_depth`)**: os helpers `public.is_my_store`/`public.is_tenant_owner` passaram a ser `SECURITY DEFINER` com `search_path` fixado — chamados DENTRO das políticas RLS e consultando tabelas com políticas próprias (`stores`/`tenants`/`store_employees`), formavam um ciclo entre tabelas que, em varreduras completas (listagens sem WHERE do PostgREST), estourava a pilha num Supabase com schema antigo. O definer quebra o ciclo **por construção** (mesmo padrão de `is_super_admin` e das RPCs do dinheiro). Migração `006` (`supabase/migrations/006_rls_helpers_security_definer.sql`) + smoke test de varredura completa no `sql_check.sh` (dono/funcionário/anon, sem WHERE).
- **Cadastro de funcionário no modo SaaS**: substituído o `auth.signUp` (que enviava e-mail de confirmação e sofria rate limit `over_email_send_rate_limit` — o cadastro falhava, e a conta ficava pendente `email_not_confirmed`) pela RPC `create_employee_account` (`SECURITY DEFINER`): a conta nasce confirmada, sem e-mail, sem substituir a sessão do dono (elimina o bug S1) e com o **vínculo em `store_employees` criado na MESMA transação** — se o limite do plano for atingido, a conta é desfeita junto (sem contas órfãs). **v2 (Aug 6):** a conta passou a ser criada por **inserção direta em `auth.users` + `auth.identities`** com hash bcrypt (pgcrypto) — o Supabase atual **removeu** a função interna `auth.admin_create_user` (a Admin API do GoTrue é HTTP/assíncrona e quebraria a atomicidade); colunas estáveis do GoTrue, `confirmed_at` é coluna gerada (nunca inserida), e-mail duplicado vira mensagem amigável (pré-checagem + índice único parcial tratado no `EXCEPTION`). **v3 (Aug 6):** `search_path = public, extensions` — o pgcrypto vive no schema `extensions` em projetos Supabase geridos. **v4 (Aug 6):** o INSERT em `auth.users` preenche **todas as 22 colunas** que o struct `User` do GoTrue lê (`SELECT *` + scan de campos não-anuláveis) — colunas como `confirmation_token`, `recovery_token`, `email_change_*`, `phone_change_*`, `reauthentication_token`, `is_sso_user`/`is_anonymous` que ficavam `NULL` rebentavam o login do funcionário com `500 Database error querying schema`. Migração `005` reescrita (DROP + CREATE OR REPLACE — reaplicável, também sobre as versões anteriores) + smoke test no `sql_check.sh` (vínculo, idempotência e rollback do limite) com stub de `auth` atualizado (usuários + identidades + índice único).
- **Conflito de Heroes dos FABs** (`There are multiple heroes that share the same tag…` no arranque — o `IndexedStack` do AppShell mantém 6 seções vivas, todas com o hero tag padrão): `heroTag` único por tela (dashboard, produtos, vendas, financeiro, fiado, clientes, compras, lojas).
- Comentários/`doc comments` desatualizados: nome do trigger em `supabase_employee_data_source.dart` (`set_employee_tenant_from_store` → `trg_store_employees_tenant`/`set_employee_tenant`), referência a e-mail de super admin em `supabase_tenant_data_source.dart` (papel é baseado em banco desde a auditoria C3), comentário duplicado da facade em `app_database.dart` e erro de digitação (`//////`) em `money.dart`.
- `scripts/sql_check.sh`: nova assertiva de **data de realização** pós-`settle_debt` (regressão da 004).

### Adicionado (Aug 5, 2026 — auditoria)
- RLS **por loja** (`is_my_store`) em todas as tabelas de negócio (C2) — funcionários passam a ver/gravar dados da própria loja.
- Papel de **super admin baseado em banco** (`public.super_admins` + `is_super_admin()` SECURITY DEFINER) — substitui e-mail hardcoded (C3).
- RPC atômico **`settle_debt`** (C4) — quitação de fiado + resolução da pendência em uma transação.
- **Sentry** (`lib/core/observability/crash_reporting.dart`) com DSN via `--dart-define` (H4).
- Helper **`Money`** (aritmética em centavos) nos acúmulos de use cases e somas da UI (H1).
- Fail-fast em release para defines do Supabase ausentes (S2/H5).
- **Anti-spam** de tenants pendentes (`idx_tenants_one_pending`, S3).
- Trilha de auditoria `decided_by` + trigger (S4).
- `android:allowBackup=false` + data-extraction rules (S6); R8/minify ativos (S7).
- **Flavors `dev`/`prod`** + dart-define-from-file + guardas de release (main.dart, Gradle, SupabaseBootstrap) (2.4/7.2).
- CI: gate de cobertura 45%, build APK flavor dev, SQL/RLS check executando os RPCs ([4/4]).
- Release: `.github/workflows/release.yml` (tag `v*` → Fastlane → AAB prod assinado → Internal testing) + Fastfile + secrets de keystore/play.
- Fix do bug de **precedência de operadores no Postgres** (`'t' || (p->>'id')` — 22P02) nos RPCs atômicos (1.17).
- Corrigido build de release quebrado: `sentry_flutter` 8.14.2 → **9.26.0**; `sqlite3_flutter_libs` 0.5.27 → **0.6.0+eol** (8.2).

### Adicionado (Aug 4, 2026 — auditoria original)
- Armazenamento seguro de segredos (`SecureStorageService`), IDs sem colisão (`AppIds`), `IUnitOfWork` com transações reentrantes no SQLite, testes de 175+ casos e 11 capítulos de documentação bilingue.

---

*Auditorias de prontidão de produção: `docs/pt/AUDIT_REPORT.md` (detalhada) e `docs/pt/PRODUCTION_CHECKLIST.md` (checklist vivo).*
