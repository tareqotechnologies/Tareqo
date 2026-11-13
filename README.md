# TAREQO ERP

[![Deploy web (GitHub Pages)](https://github.com/tareqotechnologies/Tareqo/actions/workflows/web.yml/badge.svg)](https://github.com/tareqotechnologies/Tareqo/actions/workflows/web.yml)

> Sistema de gestão empresarial multi-tenant (estoque, vendas, compras, financeiro, crédito e relatórios) construído em **Flutter** com **Clean Architecture** — com persistência local (SQLite), SaaS autenticado (Supabase + RLS) e interface **pt/en/fr**.

<p align="center">
 <a href="docs/pt/README.md"><strong> Documentação (pt)</strong></a> ·
 <a href="docs/en/README.md"><strong> Documentation (en)</strong></a> ·
 <a href="docs/fr/README.md"><strong> Documentation (fr)</strong></a> ·
 <a href="README.en.md"><strong> English version</strong></a>
</p>

---

## Visão geral

O **TAREQO ERP** é um aplicativo para pequenos comerciantes administrarem o negócio: controle de **estoque**, **vendas** (com baixa atômica de estoque e entrada no caixa), **compras**, **fluxo de caixa**, **clientes**, **crédito/fiado** e **relatórios**. O dono gerencia **lojas e funcionários** por tenant, escolhe o **idioma (pt/en/fr)** e a **moeda (BRL, USD, EUR, MZN)**, e cada loja tem escopo próprio de dados — tudo isolado por autenticação e *Row Level Security* no servidor.

## Funcionalidades

| Módulo | O que faz |
| ------ | --------- |
| **Início** | Dashboard com KPIs (vendas, saldo de caixa, a receber, estoque), ações rápidas e alerta de estoque baixo |
| **Produtos** | Busca, listagem e cadastro com validação de preço no domínio |
| **Vendas** | Carrinho + forma de pagamento; venda, baixa de estoque e caixa em **uma transação atômica** (com snapshot de preço) |
| **Compras** | Entrada de mercadorias com atualização de estoque e saída no caixa |
| **Financeiro** | Fluxo de caixa por período, entradas/saídas e recebimento de pendências |
| **Crédito (fiado)** | A receber/a pagar com vencimento, baixa e histórico de quitações |
| **Lojas** | Gestão do tenant: lojas, funcionários, plano e **Ajustes** (idioma + moeda) |
| **Admin** | Painel do super admin: aprovação de tenants, planos e upgrades |

## Stack

| Camada | Tecnologia |
| ------ | ---------- |
| **UI/Estado** | Flutter (Material 3) + Riverpod |
| **Arquitetura** | Clean Architecture (domain · data · presentation) |
| **Persistência local** | SQLite (`package:sqlite3`) com fallback em memória para web |
| **Backend SaaS** | Supabase (auth, Postgres + **RLS**, RPCs atômicas) |
| **i18n** | `flutter_localizations` (pt/en/fr) + moeda por tenant |
| **Segurança** | `flutter_secure_storage` (Keychain/Keystore) para segredos |

## Começando

```bash
flutter pub get
# Desenvolvimento (debug/hot reload) — flavor dev + defines do env/dev.env
flutter run --flavor dev --dart-define-from-file=env/dev.env

# Modo SaaS (Supabase): a anon key vem do env/dev.env (projeto de dev).
# Produção (release, assinada): usa env/prod.env (NUNCA versionado —
# veja env/prod.env.example) + key.properties (veja docs/13-build-e-publicacao).
# A1: todo release exige credenciais EXPLÍCITAS + o marcador
# SUPABASE_CREDENTIALS_EXPLICIT=true (já presentes em env/prod.env.example)
# — a guarda de release rejeita defaults embutidos em qualquer flavor.
flutter build appbundle --flavor prod --release \
 --dart-define-from-file=env/prod.env
```

> A anon key do Supabase é **pública por design** (a segurança real vem do RLS). **Nunca** embuta a *service role key* no cliente.
> A sessão do Supabase é persistida no **Keychain/Keystore** (criptografada) — nunca em texto claro.

## Testes

```bash
flutter analyze
flutter test
```

O projeto tem **mais de 280 testes** (unitários de domínio, repositórios, providers e widgets) e CI no GitHub Actions (analyze → test+coverage → build APK dev → SQL/RLS check). Publicação via tag `v*` → Fastlane (ver `docs/pt/13-build-e-publicacao.md`).

## Documentação

- **Português:** [`docs/pt/`](docs/pt/README.md) — visão geral, arquitetura, domínio, dados, apresentação, autenticação, segurança, fluxos de negócio, testes, guia do desenvolvedor, multi-tenancy e [decisões de arquitetura](docs/pt/12-decisoes-de-arquitetura.md).
- **English:** [`docs/en/`](docs/en/README.md) — same content, in English.
- **Français:** [`docs/fr/`](docs/fr/README.md) — le même contenu, en français.

## Licença

Distribuído sob licença **MIT**. Consulte o arquivo `LICENSE` para mais informações.
