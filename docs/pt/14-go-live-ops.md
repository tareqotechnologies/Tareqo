# 14 — Go-Live: operações externas (checklist)

> Este capítulo cobre **tudo o que não está no repositório** — os passos que
> exigem as consolas (Google Play, Apple Developer, Supabase) e os secrets
> do CI. O código de release está pronto (workflows + Fastlane); estes
> passos são manuais e únicos.

## 0. Estado atual

- ✓ Keystore de upload gerado (`android/app/upload-keystore.jks`, gitignored)
 + `android/key.properties` — assinatura Android pronta.
- ✓ `release.yml` (Android → Play *Internal testing*) e `ios.yml`
 (iOS → TestFlight) prontos; disparados por tag `v*`.
- ✗ Secrets do CI por configurar; contas de loja; ativações nas consolas.

## 1. Secrets do GitHub (Settings → Secrets and variables → Actions)

| Secret | Origem |
|---|---|
| `SUPABASE_URL_PROD` | URL do projeto de produção (dashboard Supabase) |
| `SUPABASE_ANON_KEY_PROD` | anon key do projeto de produção |
| `SENTRY_DSN` (opcional) | projeto Sentry |
| `KEYSTORE_BASE64` | `base64 -w0 android/app/upload-keystore.jks` (já existe em `android/app/upload-keystore.jks.b64` — copiar o conteúdo, depois apagar o ficheiro) |
| `KEYSTORE_PASSWORD` | `storePassword` de `android/key.properties` (PKCS12: a mesma para `keyPassword`) |
| `KEY_ALIAS` | `keyAlias` de `android/key.properties` (padrão `upload`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | service account do Play Console (API Google Play Developer) — ver §3 |
| `APPLE_ISSUER_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → Issuer ID |
| `APPLE_KEY_ID` | id da API key criada no mesmo ecrã |
| `APPLE_KEY_CONTENT` | conteúdo **base64** do ficheiro `.p8` da mesma API key |
| `APPLE_TEAM_ID` | Apple Developer → Membership → Team ID |

## 2. Supabase (projeto de produção)

1. **Confirmação de e-mail ON** — Authentication → Providers → Email →
 "Confirm email" **ligado** (mitiga auto-registo e é pré-requisito de segurança).
2. **2FA na conta do super admin** — ativar na conta de e-mail do `super_admins`
 (ou, idealmente, TOTP no próprio Supabase quando disponível).
3. **`password_min_length = 8`** — Authentication → Settings (alinha com o cliente).
4. **Aplicar o upgrade consolidado** ao projeto de produção: SQL Editor ←
 conteúdo de `supabase/upgrade.sql` (leva um banco EXISTENTE ao estado
 atual — substitui as antigas migrações 002..011; 100% idempotente, seguro
 reexecutar). Para projetos novos, só o `supabase/schema.sql` basta.

> **📘 Set/2026:** o processo completo de configuração do Supabase de
> produção (criação do projeto, aplicação dos scripts, super admin,
> credenciais `env/prod.env`, build e validação) está consolidado no
> **[capítulo 19 — Supabase de produção passo a passo](19-supabase-producao-passo-a-passo.md)**.
> Os 7 arquivos de migração de add-ons/billing foram arquivados em
> `supabase/archived_migrations/` — o conteúdo foi fundido no `schema.sql`
> (PARTE 1.9) e no `upgrade.sql` (PARTE 31).
 → **Runbook completo (W4 centavos + H2 RPCs): [capítulo 15](15-migracao-w4-h2.md)**
 — backup, pré-flight, aplicação em transação única, verificação
 `sql_check_live.sh` 14/14 e rollback.
 → **Runbook W11 (FIFO por lotes + validade + vendas por peso):
 [capítulo 16](16-migracao-w11.md)** — mesma mecânica (backup, transação
 única `-1`, `sql_check_live.sh` com os checks 25–31) + a janela de
 publicação do app W11 logo após a migração.
5. **Rate limits de e-mail (dev):** deixar os padrões. No plano free o envio é
 limitado (~2 e-mails/hora) — quando a cota esgota, o GoTrue responde
 **429 "email rate limit exceeded"** e o app mostra a mensagem específica
 *"Muitas tentativas seguidas. Aguarde cerca de 1 hora e tente novamente."*
 (chave `loginRateLimitError` — o cadastro volta a funcionar na próxima
 janela, sem ação necessária; o cadastro de funcionário não usa e-mail —
 RPC `create_employee_account`).
6. **SMTP customizado em produção (plano: Resend + domínio próprio):** o free
 tier também limita os e-mails de confirmação (2/h e 4/dia) — inaceitável em
 produção com cadastros reais. Antes do go-live:
 1. **Resend** → adicionar o domínio próprio (ex.: `tareqo.com`) e
 concluir a verificação de DNS (SPF + DKIM + DMARC). Atenção: O domínio de
 teste `onboarding@resend.dev` só entrega para o e-mail da conta — não
 serve para remetentes reais.
 2. **Resend** → criar uma API key **restrita a envio** (send-only, `re_…`).
 3. **Supabase → Authentication → Emails → SMTP Settings**:

 | Campo | Valor |
 |---|---|
 | Host | `smtp.resend.com` |
 | Porta | `587` |
 | Username | `resend` (fixo — a API key vai no Password) |
 | Password | a API key (`re_…`) |
 | From e-mail | `no-reply@tareqo.com` |
 | From name | `TAREQO` |
 | Admin e-mail | e-mail do super admin (recuperação) |

 4. **Alternativa programática (Management API):** `PATCH
 /v1/projects/{ref}/config/auth` com `smtp_host`, `smtp_port`,
 `smtp_user` (**`resend`**), `smtp_pass` (a API key), `smtp_sender_email`,
 `smtp_sender_name` e `smtp_admin_email` (token `sbp_…` de Settings →
 Access Tokens). Atenção: **O PATCH substitui a config inteira** — envie todos
 os campos `smtp_*` de uma vez (validado em Aug 8: um PATCH parcial zerou
 o SMTP).
 5. **Teste:** disparar um cadastro e confirmar a entrega do e-mail de
 confirmação; a chave Resend também pode ser testada com um POST direto
 em `https://api.resend.com/emails`.

 > **Decisão registrada (Aug 8):** `tareqo.com` **não está registrado**
 > (RDAP 404 — domínio disponível) e o time optou por **não comprar domínio
 > por enquanto** — o e-mail de confirmação segue pelo SMTP do Resend com o
 > domínio de teste `onboarding@resend.dev`, que **só entrega para o e-mail
 > da conta Resend** (`jalaneoanalista@gmail.com`); qualquer outro e-mail no
 > cadastro recebe 403. Implicações para testes dev:
 >
 > - Só é possível confirmar cadastros feitos com `jalaneoanalista@gmail.com`;
 > outros e-mails não recebem o link (o app fica na tela de confirmação).
 > - Alternativa para testes: `mailer_autoconfirm = true` no dev (novos
 > cadastros confirmam sozinhos, sem e-mail) — usado nos testes E2E.
 >
 > **Atenção:** Importante (mito desfeito): pagar o plano do Supabase NÃO resolve o
 > envio de e-mail.** O serviço de e-mail padrão do Supabase é severamente
 > limitado mesmo nos planos pagos (~2 e-mails/hora; restrito a membros da
 > organização no free) — a recomendação oficial é SMTP externo (o que já
 > usamos: Resend). O desbloqueio real custa só o **registro do domínio
 > (~US$ 8–12/ano)**: o plano gratuito do Resend já permite **1 domínio
 > verificado** (SPF/DKIM/DMARC) com 3.000 e-mails/mês (100/dia) — suficiente
 > para o go-live de um comércio pequeno, **sem pagar nada ao Supabase**.

## 3. Google Play Console

1. Criar o app com o Application ID **`com.tareqo.tareqo`**
 (imutável após o primeiro upload).
2. Ativar o **Play App Signing** e registar o SHA-256 da chave de upload
 (de `keytool -list -v -keystore upload-keystore.jks`).
3. Criar a service account com permissão de upload (Play Console → Setup →
 API access) e guardar o JSON no secret `PLAY_SERVICE_ACCOUNT_JSON`.
4. Lançar o primeiro release: `git tag v1.0.0 && git push --tags` → o CI
 builda e envia para o track **Internal testing**.
5. Assets da loja: ícone (já gerado), feature graphic, screenshots,
 descrição, política de privacidade + ToS (links obrigatórios).

## 4. Apple (iOS)

1. **Apple Developer Program** ativo + App ID `com.tareqo.tareqo`.
2. Configurar a assinatura automática no Xcode (team) OU usar `match`
 (alternativa documentada na lane `ios beta`).
3. Criar a API key da App Store Connect (ficheiro `.p8`) e adicionar os 3
 secrets Apple (§1). A lane `fastlane ios beta` valida primeiro a
 compilação sem assinatura (`--no-codesign`) e só depois assina e envia.
4. **Nota:** o build iOS exige macOS — o CI usa `macos-14`. Localmente
 (Windows) não é possível validar o IPA; a validação acontece no workflow.

## 5. Antes do primeiro tag

- [ ] Secrets do §1 todos preenchidos
- [ ] Supabase: confirmação de e-mail ON + 2FA + migração 008 aplicada
- [ ] SMTP customizado no Supabase de produção (Resend + domínio próprio) — §2.6
- [ ] Play App Signing ativado + service account criada
- [ ] Apple Developer + API key criadas
- [ ] Política de privacidade + ToS publicadas (links nas lojas)
- [ ] `flutter test` verde + `sql_check.sh` 9/9 (CI valida em cada push)

## 6. Depois do primeiro upload

- [ ] Testar o APK/AAB do Internal testing num dispositivo real (dono,
 gerente e funcionário — matriz de acesso)
- [ ] Verificar no Sentry (se DSN configurado) que não há erros em release
- [ ] Promover de Internal → Closed/Open testing após aprovação manual
