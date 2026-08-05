# 07 — Security

This document covers the app's security decisions: **secure storage** of secrets, responsibility limits between the app and Supabase, and per-platform best practices.

---

## Secure storage (`SecureStorageService`)

`lib/core/security/secure_storage_service.dart` encapsulates the **encrypted** persistence of access tokens, refresh tokens and API keys.

### Architecture

```text
SecureStorageService
  └─ SecureStorageBackend (interface)          ← abstracted for testing
       ├─ FlutterSecureStorageBackend          ← real: flutter_secure_storage
       └─ (in-memory backend in tests)
```

- **Centralized keys** in `SecureStorageKeys`: `accessToken`, `refreshToken`, `apiKey` — avoids typos and lets you audit exactly what is treated as sensitive.
- **API:** `write`, `read`, `delete`, `contains`.
- **Registered in GetIt** (`ServiceLocator`) — single access point for the data/presentation layer.

### Why not use `shared_preferences` for sensitive data?

| Aspect | `shared_preferences` | `flutter_secure_storage` |
| ------ | -------------------- | ------------------------ |
| Physical location | Plain-text preferences file | **Keychain** (iOS/macOS) and **Android Keystore** |
| Encryption | None — value readable on disk | Encrypted; on Android the key (AES-GCM) is generated and kept in the Keystore, tied to the hardware |
| Access | Any process with read access to the file | Protected by the OS; on iOS may require biometrics (Face ID/Touch ID) |
| Backup/extraction | Plain-text values readable from backups, root/JB or APK extraction | End-to-end encrypted |
| Ideal use case | UI preferences (theme, language, filters) | Session tokens, refresh tokens, API keys, secrets |

### Why this protects the merchant's account

1. **The token is the password.** With the session token (or refresh token) in hand, an attacker accesses the account without needing the password.
2. **Encryption tied to the device:** the master key lives in the **Android Keystore** (hardware-backed, TEE) / **Keychain** with secure enclave — copying the file is not enough without the hardware key.
3. **High attack cost:** compromising the OS/hardware is not viable at scale (the same trust banks use).
4. **User-conditioned access (iOS):** the Keychain can require biometrics.

---

## Responsibility limit (don't duplicate the session!)

The **Supabase session** (sign-in access + refresh token) **is already persisted internally** by `supabase_flutter` in its own `flutter_secure_storage` instance (keys `sb-...-auth-token`), with automatic renewal.

That's why `SecureStorageService` **must not store those tokens**. It exists for **app secrets**:

- API keys of external services (e.g.: payment gateway);
- configuration secrets;
- any credential the data/presentation layer needs to keep.

Keeping this boundary avoids **two places storing the session** (a source of conflict and audit confusion).

---

## RLS (Row Level Security) on Supabase

- The anon key is **public by design** — embedded in the client. The real security comes from the database:
  ```sql
  -- per-tenant isolation rule
  user_id = auth.uid()
  ```
- Even if a UI bug leaks data, the **database filters it**.
- **Never** put the *service role key* in the client (it bypasses RLS).

---

## Per-platform caveats (technical accuracy)

| Platform | Mechanism | Protection level |
| -------- | --------- | ---------------- |
| Android/iOS | Android Keystore (AES-GCM, key in TEE) / Keychain with enclave | **Hardware-backed** — where critical data should live |
| Windows | DPAPI (tied to the OS user account) | Reasonable, no dedicated enclave |
| Linux | libsecret | Reasonable, no dedicated enclave |
| Web | Encryption key kept in `localStorage` | **Weakest** — not hardware-backed |

> ⚠️ For **critical secrets, prioritize mobile**; on web, restrict what is stored or combine with server-side measures.

---

## Other project practices

- **Generic auth errors in the UI:** `debugPrint` with details for diagnosis; friendly SnackBar for the user (does not expose provider internals).
- **Business rules in the domain, guards in the database:** non-negative values are validated in use cases **and** by `CHECK` constraints in SQLite (defense in depth).
- **Parameterized SQL** in all SQLite datasources (prepared statements — never string concatenation), preventing SQL injection.

---

## Related documents

- [Authentication](06-authentication.md) — session flow and where each token lives.
- [Data layer](04-data.md) — schema and database guards.
- [Architecture](02-architecture.md) — where security fits in the structure.
