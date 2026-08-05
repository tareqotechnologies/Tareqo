# 📚 Dumbhanengue ERP Documentation (English)

Welcome to the complete documentation of **Dumbhanengue ERP** — a business management system (inventory, sales, finance and credit/"fiado" tracking) built in Flutter with **Clean Architecture**.

> 🌐 **Language:** This is the English version. The Portuguese documentation lives in ([`docs/pt/`](../pt/README.md)).

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
