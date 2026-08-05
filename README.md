# Dumbhanengue ERP

> Sistema de gestão empresarial multi-tenant (estoque, vendas, compras, financeiro, crédito e relatórios) construído em **Flutter** com **Clean Architecture** — com persistência local (SQLite), SaaS autenticado (Supabase + RLS) e interface **pt/en**.

<p align="center">
  <a href="docs/pt/README.md"><strong>📚 Documentação (pt)</strong></a> ·
  <a href="docs/en/README.md"><strong>📚 Documentation (en)</strong></a> ·
  <a href="README.en.md"><strong>🌐 English version</strong></a>
</p>

---

## Visão geral

O **Dumbhanengue ERP** é um aplicativo para pequenos comerciantes administrarem o negócio: controle de **estoque**, **vendas** (com baixa atômica de estoque e entrada no caixa), **compras**, **fluxo de caixa**, **clientes**, **crédito/fiado** e **relatórios**. O dono gerencia **lojas e funcionários** por tenant, escolhe o **idioma (pt/en)** e a **moeda (BRL, USD, EUR, MZN)**, e cada loja tem escopo próprio de dados — tudo isolado por autenticação e *Row Level Security* no servidor.

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
| **i18n** | `flutter_localizations` (pt/en) + moeda por tenant |
| **Segurança** | `flutter_secure_storage` (Keychain/Keystore) para segredos |

## Começando

```bash
flutter pub get
flutter run                              # modo dev (persistência local)
flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co \
             --dart-define=SUPABASE_ANON_KEY=eyJ...   # modo SaaS (Supabase)
```

> A anon key do Supabase é **pública por design** (a segurança real vem do RLS). **Nunca** embuta a *service role key* no cliente.

## Testes

```bash
flutter analyze
flutter test
```

O projeto tem **mais de 200 testes** (unitários de domínio, repositórios, providers e widgets) e CI no GitHub Actions.

## Documentação

- **Português:** [`docs/pt/`](docs/pt/README.md) — visão geral, arquitetura, domínio, dados, apresentação, autenticação, segurança, fluxos de negócio, testes, guia do desenvolvedor, multi-tenancy e [decisões de arquitetura](docs/pt/12-decisoes-de-arquitetura.md).
- **English:** [`docs/en/`](docs/en/README.md) — same content, in English.

## Licença

Distribuído sob licença **MIT**. Consulte o arquivo `LICENSE` para mais informações.
