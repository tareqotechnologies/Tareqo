# 📚 Dumbhanengue ERP Documentation (English)

Welcome to the complete documentation of **Dumbhanengue ERP** — a business management system (inventory, sales, finance and credit/"fiado" tracking) built in Flutter with **Clean Architecture**.

> 🌐 **Language:** This is the English version. The Portuguese documentation lives in ([`docs/pt/`](../pt/README.md)).
>
> 📌 **Audit docs:** the production-readiness audit reports ([`docs/pt/AUDIT_REPORT.md`](../pt/AUDIT_REPORT.md)) and the live checklist ([`docs/pt/PRODUCTION_CHECKLIST.md`](../pt/PRODUCTION_CHECKLIST.md)) are maintained in Portuguese (the project's primary language) and are the authoritative source for audit status. An English summary of the latest audit status (Update 6 + pending production items) is available in [15-audit-status.md](15-audit-status.md), the W4 + H2 live migration runbook in [16-migracao-w4-h2.md](16-migracao-w4-h2.md), the W11 live migration runbook (FIFO lots + scale/weight sales) in [18-migracao-w11.md](18-migracao-w11.md), and the production readiness checklist in [17-production-checklist.md](17-production-checklist.md). The English chapters were synced with the Aug 5/6 changes (flavors, store-scoped RLS, DB-backed super admin, atomic RPCs, secure session storage, CI/CD, W4/H2/W10, SQL consolidation) — the Portuguese docs remain the primary reference.

This folder gathers every document about the app: from what it does to how each layer works, with code examples, diagrams and practical guides for developers.

---

## Document index

| # | Document | What it explains |
| - | -------- | ---------------- |
| 01 | [Overview](01-overview.md) | What the app is, goals, features, target audience, platforms and stack |
| 02 | [Architecture](02-architecture.md) | Clean Architecture: layers, dependency rule, data flow and structural decisions |
| 03 | [Domain](03-domain.md) | Entities, enums, repository contracts and all use cases (business rules) |
| 04 | [Data layer](04-data.md) | Datasources (in-memory + SQLite), repositories, database schema, migrations, seed and Unit of Work |
| 05 | [Presentation](05-presentation.md) | Riverpod providers, screens (Home, Products, Sales, Finance, Credit), widgets, navigation and theme |
| 06 | [Authentication](06-authentication.md) | Sign in/sign up with Supabase, persistent session, AuthGate and SaaS multi-tenant flow |
| 07 | [Security](07-security.md) | Secure storage (Keychain/Keystore), RLS, what to never do |
| 08 | [Business flows](08-business-flows.md) | Atomic sale processing, the "credit" cycle, cash flow and stock control |
| 09 | [Testing](09-testing.md) | Testing strategy, structure, how to run and patterns used |
| 10 | [Developer guide](10-developer-guide.md) | Setup, commands, code generation (Freezed), conventions and how to add new modules |
| 11 | [Multi-tenancy and Super Admin](11-multitenancy.md) | Plans, tenant approval, stores, employees, plan upgrades and the super admin panel |
| 12 | [Architecture decisions](12-architecture-decisions.md) | The "why" behind each technical decision: Clean Architecture, contracts, price snapshot, atomic stock, credit, SaaS auth and secure storage |
| 13 | [Build and release per platform](13-build-and-release.md) | How to build the app on Android, iOS, Windows and Web: requirements, signing, deploy and a publishing checklist |
| 14 | [Go-live operations](14-go-live-ops.md) | Pre-launch and launch-day ops: Supabase project setup, environment variables, SQL apply, verification scripts, rollback and monitoring |
| 15 | [Audit status & pending items](15-audit-status.md) | English summary of the latest audit status (Update 6: SQL consolidation + real-DB validation) and the pending production-checklist items |
| 16 | [W4 + H2 live migration runbook](16-migracao-w4-h2.md) | Step-by-step runbook to apply `supabase/upgrade.sql` to the production project (backup, pre-flight, apply, verify, rollback) |
| 17 | [Production readiness checklist](17-production-checklist.md) | English mirror of the production checklist: data integrity, security, architecture, performance, testing, ops, dependencies and docs status |
| 18 | [W11 live migration runbook](18-migracao-w11.md) | Step-by-step runbook for Part 22 (FIFO lots + expiry + scale/weight sales): millesimals, lot backfill, post-migration verification and the publish window |

---

## Start here

- **New to the app?** → [Overview](01-overview.md)
- **Want to understand how the code is organized?** → [Architecture](02-architecture.md)
- **Want to run the project and work on the code?** → [Developer guide](10-developer-guide.md)

> 💡 The `README.md` at the project root is the presentation document; this `docs/` folder is the complete reference manual.

## Quick maps

- **Folder structure** → see the diagram in [Architecture](02-architecture.md#folder-structure).
- **Database schema** → see the tables in [Data layer](04-data.md#database-schema).
- **Use cases** → full catalog in [Domain](03-domain.md#use-case-catalog).
- **Screens** → description of each one in [Presentation](05-presentation.md#screens).
