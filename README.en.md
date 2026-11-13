# TAREQO ERP

[![Deploy web (GitHub Pages)](https://github.com/tareqotechnologies/Tareqo/actions/workflows/web.yml/badge.svg)](https://github.com/tareqotechnologies/Tareqo/actions/workflows/web.yml)

> Multi-tenant business management system (inventory, sales, purchases, finance, credit and reports) built in **Flutter** with **Clean Architecture** — with local persistence (SQLite), authenticated SaaS (Supabase + RLS) and a **pt/en/fr** interface.

<p align="center">
 <a href="docs/en/README.md"><strong> Documentation (en)</strong></a> ·
 <a href="docs/pt/README.md"><strong> Documentação (pt)</strong></a> ·
 <a href="docs/fr/README.md"><strong> Documentation (fr)</strong></a> ·
 <a href="README.md"><strong> Versão em português</strong></a>
</p>

---

## Overview

**TAREQO ERP** is an app for small merchants to run their business: **inventory** control, **sales** (with atomic stock decrement and cash inflow), **purchases**, **cash flow**, **customers**, **credit ("fiado")** and **reports**. The owner manages **stores and employees** per tenant, chooses the **language (pt/en/fr)** and **currency (BRL, USD, EUR, MZN)**, and each store has its own data scope — everything isolated by authentication and server-side *Row Level Security*.

## Features

| Module | What it does |
| ------ | ------------ |
| **Home** | Dashboard with KPIs (sales, cash balance, receivables, stock), quick actions and low-stock alerts |
| **Products** | Search, listing and registration with price validation in the domain |
| **Sales** | Cart + payment method; sale, stock decrement and cash in **one atomic transaction** (with price snapshot) |
| **Purchases** | Goods entry with stock update and cash outflow |
| **Finance** | Cash flow by period, inflows/outflows and receiving pending items |
| **Credit ("fiado")** | Receivables/payables with due dates, settlement and settlement history |
| **Stores** | Tenant management: stores, employees, plan and **Settings** (language + currency) |
| **Admin** | Super admin panel: tenant approval, plans and upgrades |

## Stack

| Layer | Technology |
| ----- | ---------- |
| **UI/State** | Flutter (Material 3) + Riverpod |
| **Architecture** | Clean Architecture (domain · data · presentation) |
| **Local persistence** | SQLite (`package:sqlite3`) with in-memory fallback for web |
| **SaaS backend** | Supabase (auth, Postgres + **RLS**, atomic RPCs) |
| **i18n** | `flutter_localizations` (pt/en/fr) + per-tenant currency |
| **Security** | `flutter_secure_storage` (Keychain/Keystore) for secrets |

## Getting started

```bash
flutter pub get
flutter run # dev mode (local persistence)
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
 --dart-define=SUPABASE_ANON_KEY=eyJ... # SaaS mode (Supabase)
```

> The Supabase anon key is **public by design** (real security comes from RLS). **Never** embed the *service role key* in the client.

## Tests

```bash
flutter analyze
flutter test
```

The project has **200+ tests** (domain units, repositories, providers and widgets) and CI on GitHub Actions.

## Documentation

- **English:** [`docs/en/`](docs/en/README.md) — overview, architecture, domain, data, presentation, authentication, security, business flows, testing, developer guide, multi-tenancy and [architecture decisions](docs/en/12-architecture-decisions.md).
- **Português:** [`docs/pt/`](docs/pt/README.md) — o mesmo conteúdo, em português.
- **Français:** [`docs/fr/`](docs/fr/README.md) — the same content, in French.

## License

Distributed under the **MIT** license. See the `LICENSE` file for details.
