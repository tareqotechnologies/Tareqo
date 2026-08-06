# 14 — Go-Live: external operations (checklist)

> This chapter covers **everything that is not in the repository** — the
> steps that require the consoles (Google Play, Apple Developer, Supabase)
> and the CI secrets. The release code is ready (workflows + Fastlane);
> these steps are manual and one-time.

## 0. Current state

- ✅ Upload keystore generated (`android/app/upload-keystore.jks`, gitignored)
  + `android/key.properties` — Android signing ready.
- ✅ `release.yml` (Android → Play *Internal testing*) and `ios.yml`
  (iOS → TestFlight) ready; triggered by `v*` tags.
- ❌ CI secrets to configure; store accounts; console activations.

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
5. Email rate limits: keep defaults (employee registration does not use
   email — the `create_employee_account` RPC).

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
- [ ] Play App Signing enabled + service account created
- [ ] Apple Developer + API keys created
- [ ] Privacy policy + ToS published (store links)
- [ ] `flutter test` green + `sql_check.sh` 9/9 (CI validates on every push)

## 6. After the first upload

- [ ] Test the Internal testing APK/AAB on a real device (owner, manager
  and employee — access matrix)
- [ ] Check Sentry (if DSN configured) for release errors
- [ ] Promote from Internal → Closed/Open testing after manual approval
