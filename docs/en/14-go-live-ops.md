# 14 — Go-Live: external operations (checklist)

> This chapter covers **everything that is not in the repository** — the
> steps that require the consoles (Google Play, Apple Developer, Supabase)
> and the CI secrets. The release code is ready (workflows + Fastlane);
> these steps are manual and one-time.

## 0. Current state

- ✓ Upload keystore generated (`android/app/upload-keystore.jks`, gitignored)
 + `android/key.properties` — Android signing ready.
- ✓ `release.yml` (Android → Play *Internal testing*) and `ios.yml`
 (iOS → TestFlight) ready; triggered by `v*` tags.
- ✗ CI secrets to configure; store accounts; console activations.

## 1. GitHub secrets (Settings → Secrets and variables → Actions)

| Secret | Source |
|---|---|
| `SUPABASE_URL_PROD` | production project URL (Supabase dashboard) |
| `SUPABASE_ANON_KEY_PROD` | production project anon key |
| `SENTRY_DSN` (optional) | Sentry project |
| `KEYSTORE_BASE64` | `base64 -w0 android/app/upload-keystore.jks` (already at `android/app/upload-keystore.jks.b64` — copy the content, then delete the file) |
| `KEYSTORE_PASSWORD` | `storePassword` from `android/key.properties` (PKCS12: same for `keyPassword`) |
| `KEY_ALIAS` | `keyAlias` from `android/key.properties` (default `upload`) |
| `PLAY_SERVICE_ACCOUNT_JSON` | Play Console service account (Google Play Developer API) — see §3 |
| `APPLE_ISSUER_ID` | App Store Connect → Users and Access → Integrations → App Store Connect API → Issuer ID |
| `APPLE_KEY_ID` | key id created on the same screen |
| `APPLE_KEY_CONTENT` | **base64** content of the `.p8` file for that API key |
| `APPLE_TEAM_ID` | Apple Developer → Membership → Team ID |

## 2. Supabase (production project)

1. **Email confirmation ON** — Authentication → Providers → Email →
 "Confirm email" **enabled** (mitigates self-registration; security prerequisite).
2. **2FA on the super admin account** — enable on the `super_admins` email
 account (or ideally TOTP in Supabase itself when available).
3. **`password_min_length = 8`** — Authentication → Settings (aligns with the client).
4. **Apply the consolidated upgrade** to the production project: SQL Editor ←
 contents of `supabase/upgrade.sql` (brings an EXISTING database to the
 current state — replaces the old migrations 002..011; 100% idempotent, safe
 to re-run). For brand-new projects, `supabase/schema.sql` alone is enough.
5. **Email rate limits (dev):** keep defaults. On the free plan sending is
 capped (~2 emails/hour) — when the quota is exhausted GoTrue answers
 **429 "email rate limit exceeded"** and the app shows the specific message
 *"Too many attempts in a row. Please wait about an hour and try again."*
 (`loginRateLimitError` key — sign-up resumes on the next window, no action
 needed; employee registration does not use email — the
 `create_employee_account` RPC).
6. **Custom SMTP in production (plan: Resend + own domain):** the free tier
 also caps confirmation emails (2/hour and 4/day) — unacceptable in
 production with real sign-ups. Before go-live:
 1. **Resend** → add your own domain (e.g. `dumbhanengue.com`) and complete
 the DNS verification (SPF + DKIM + DMARC). Warning: The test domain
 `onboarding@resend.dev` only delivers to the account email — not usable
 for real senders.
 2. **Resend** → create a **send-only** API key (`re_…`).
 3. **Supabase → Authentication → Emails → SMTP Settings**:

 | Field | Value |
 |---|---|
 | Host | `smtp.resend.com` |
 | Port | `587` |
 | Username | `resend` (fixed — the API key goes in Password) |
 | Password | the API key (`re_…`) |
 | From email | `no-reply@dumbhanengue.com` |
 | From name | `Dumbhanengue` |
 | Admin email | super admin email (recovery) |

 4. **Programmatic alternative (Management API):** `PATCH
 /v1/projects/{ref}/config/auth` with `smtp_host`, `smtp_port`,
 `smtp_user` (**`resend`**), `smtp_pass` (the API key), `smtp_sender_email`,
 `smtp_sender_name` and `smtp_admin_email` (token `sbp_…` from Settings →
 Access Tokens). Warning: **The PATCH replaces the whole config** — send all
 `smtp_*` fields at once (validated Aug 8: a partial PATCH wiped the SMTP).
 5. **Test:** trigger a sign-up and confirm the confirmation email is
 delivered; the Resend key can also be tested with a direct POST to
 `https://api.resend.com/emails`.

 > **Decision recorded (Aug 8):** `dumbhanengue.com` is **not registered**
 > (RDAP 404 — domain available) and the team chose **not to buy a domain
 > for now** — the confirmation email keeps going through the Resend SMTP
 > with the test domain `onboarding@resend.dev`, which **only delivers to
 > the Resend account email** (`jalaneoanalista@gmail.com`); any other email
 > in a sign-up gets a 403. Dev-test implications:
 >
 > - Only sign-ups with `jalaneoanalista@gmail.com` can be confirmed; other
 > emails never receive the link (the app stays on the confirmation screen).
 > - Testing alternative: `mailer_autoconfirm = true` on dev (new sign-ups
 > confirm instantly, no email) — used in the E2E tests.
 >
 > **Warning:** Important (myth debunked): paying for a Supabase plan does NOT solve
 > email delivery.** Supabase's built-in email service is severely limited
 > even on paid plans (~2 emails/hour; free tier restricted to organization
 > members) — the official recommendation is an external SMTP (what we
 > already use: Resend). The real unlock costs only the **domain registration
 > (~US$ 8–12/year)**: the Resend free tier already allows **1 verified
 > domain** (SPF/DKIM/DMARC) with 3,000 emails/month (100/day) — enough for
 > a small shop's go-live, **at no cost to Supabase**.

## 3. Google Play Console

1. Create the app with Application ID **`com.dumbhanengue.dumbhanengue`**
 (immutable after the first upload).
2. Enable **Play App Signing** and register the upload key SHA-256
 (from `keytool -list -v -keystore upload-keystore.jks`).
3. Create the service account with upload permission (Play Console → Setup →
 API access) and store the JSON in the `PLAY_SERVICE_ACCOUNT_JSON` secret.
4. Ship the first release: `git tag v1.0.0 && git push --tags` → CI builds
 and uploads to the **Internal testing** track.
5. Store assets: icon (already generated), feature graphic, screenshots,
 description, privacy policy + ToS (mandatory links).

## 4. Apple (iOS)

1. **Apple Developer Program** active + App ID `com.dumbhanengue.dumbhanengue`.
2. Configure automatic signing in Xcode (team) OR use `match`
 (alternative documented in the `ios beta` lane).
3. Create the App Store Connect API key (`.p8` file) and add the 3 Apple
 secrets (§1). The `fastlane ios beta` lane first validates the build
 without signing (`--no-codesign`), then signs and uploads.
4. **Note:** the iOS build requires macOS — CI uses `macos-14`. Locally
 (Windows) the IPA cannot be validated; validation happens in the workflow.

## 5. Before the first tag

- [ ] All §1 secrets filled
- [ ] Supabase: email confirmation ON + 2FA + migration 008 applied
- [ ] Custom SMTP on the production Supabase (Resend + own domain) — §2.6
- [ ] Play App Signing enabled + service account created
- [ ] Apple Developer + API keys created
- [ ] Privacy policy + ToS published (store links)
- [ ] `flutter test` green + `sql_check.sh` 9/9 (CI validates on every push)

## 6. After the first upload

- [ ] Test the Internal testing APK/AAB on a real device (owner, manager
 and employee — access matrix)
- [ ] Check Sentry (if DSN configured) for release errors
- [ ] Promote from Internal → Closed/Open testing after manual approval
