# 📚 Documentação do Dumbhanengue ERP

> 🌐 **Languages / Idiomas:** [English version → `docs/en/`](../en/README.md) · [Version française → `docs/fr/`](../fr/README.md) · Versão em português (esta página).

Bem-vindo à documentação completa do **Dumbhanengue ERP** — sistema de gestão empresarial (estoque, vendas, financeiro e controle de crédito/"fiado") construído em Flutter com **Clean Architecture**.

Este diretório reúne todos os documentos do app: do que ele faz até como cada camada funciona, com exemplos de código, diagramas e guias práticos para desenvolvedores.

---

## Índice de documentos

| # | Documento | O que explica |
| - | --------- | ------------- |
| 01 | [Visão geral](01-visao-geral.md) | O que é o app, objetivos, funcionalidades, público-alvo, plataformas e stack |
| 02 | [Arquitetura](02-arquitetura.md) | Clean Architecture: camadas, regra de dependência, fluxo de dados e decisões estruturais |
| 03 | [Domínio](03-dominio.md) | Entidades, enums, contratos de repositório e todos os casos de uso (regras de negócio) |
| 04 | [Camada de dados](04-dados.md) | Datasources (memória + SQLite), repositórios, schema do banco, migrações, seed e Unit of Work |
| 05 | [Apresentação](05-apresentacao.md) | Providers Riverpod, telas (Início, Produtos, Vendas, Financeiro, Crédito), widgets, navegação e tema |
| 06 | [Autenticação](06-autenticacao.md) | Login/cadastro com Supabase, sessão persistente, AuthGate e fluxo SaaS multi-tenant |
| 07 | [Segurança](07-seguranca.md) | Armazenamento seguro (Keychain/Keystore), RLS, o que nunca fazer |
| 08 | [Fluxos de negócio](08-fluxos-de-negocio.md) | Processamento de venda atômico, ciclo do "fiado", fluxo de caixa e controle de estoque |
| 09 | [Testes](09-testes.md) | Estratégia de testes, estrutura, como executar e padrões usados |
| 10 | [Guia do desenvolvedor](10-guia-desenvolvedor.md) | Setup, comandos, geração de código (Freezed), convenções e como adicionar novos módulos |
| 11 | [Multi-tenancy e Super Admin](11-multitenancy.md) | Planos, aprovação de tenants, lojas, funcionários, upgrade de plano e o painel do super admin |
| 12 | [Decisões de arquitetura](12-decisoes-de-arquitetura.md) | O "porquê" de cada decisão técnica: Clean Architecture, contratos, snapshot de preço, estoque atômico, fiado, autenticação SaaS e armazenamento seguro |
| 13 | [Build e publicação por plataforma](13-build-e-publicacao.md) | Como compilar o app em Android, iOS, Windows e Web, requisitos, assinatura, deploy e checklist de publicação |
| 14 | [Go-Live: operações externas](14-go-live-ops.md) | Checklist manual das consolas (Play, Apple, Supabase) e secrets do CI para o primeiro release |
| 15 | [Migração W4 + H2 no live](15-migracao-w4-h2.md) | Runbook passo a passo para aplicar `supabase/upgrade.sql` no projeto de produção + verificação pós-migração |
| 16 | [Migração W11 no live](16-migracao-w11.md) | Runbook da Parte 22 (FIFO por lotes + validade + vendas por peso): milésimos, backfill de lotes, verificação pós-migração e janela de publicação |
| 17 | [Migração do fecho de caixa no live](17-migracao-fecho-caixa.md) | Runbook da Parte 25 (Z-report): tabela `cash_closings` + RPC `close_cash_register` (cálculo server-side + guarda gerencial), verificação pós-migração (checks 32–34) e publicação |

---

## Para utilizadores finais

| Documento | O que é |
| --------- | ------- |
| [Guia do Usuário](GUIA_DO_USUARIO.md) | Manual simples e completo do app: login, lojas (loja ativa), produtos (com foto), vendas, compras, fiado, financeiro, fecho de caixa, relatórios e **FAQ** |
| [Troubleshooting](TROUBLESHOOTING.md) | Resolução de problemas comuns: entrada e conta, fotos, vendas, estoque, caixa, conexão, mensagens de erro e quando contactar o suporte |
| [Glossário pt/en/fr](GLOSSARIO.md) | Termos técnicos nas três línguas — negócio, pagamentos, acessos, autenticação, planos, banco de dados, arquitetura, testes e release |
| **Versões PDF (imprimir)** | [Guia do Usuário PDF](pdf/pt/GUIA_DO_USUARIO.pdf) · [Troubleshooting PDF](pdf/pt/TROUBLESHOOTING.pdf) — com capa e índice, prontos a entregar/ imprimir |

> 📖 **Glossário trilíngue:** [português](GLOSSARIO.md) · [english](../en/GLOSSARY.md) · [français](../fr/GLOSSAIRE.md)

> 🌐 **Em francês (nouvelle langue):** [Guide de l'utilisateur](GUIA_DO_USUARIO.md) → [`docs/fr/GUIDE_DE_L_UTILISATEUR.md`](../fr/GUIDE_DE_L_UTILISATEUR.md) · [Dépannage](TROUBLESHOOTING.md) → [`docs/fr/DEPANNAGE.md`](../fr/DEPANNAGE.md) — empacotados no app (leitura offline) e em PDF em `docs/pdf/fr/`. Todos os **capítulos técnicos** (01–19) também estão em francês em [`docs/fr/`](../fr/README.md).

---

## Comece por aqui

- **Não conhece o app?** → [Visão geral](01-visao-geral.md)
- **É utilizador final (dono/gerente/funcionário)?** → [Guia do Usuário](GUIA_DO_USUARIO.md) · [Troubleshooting](TROUBLESHOOTING.md)
- **Quer entender como o código está organizado?** → [Arquitetura](02-arquitetura.md)
- **Quer rodar o projeto e mexer no código?** → [Guia do desenvolvedor](10-guia-desenvolvedor.md)

> 💡 O `README.md` na raiz do projeto é o documento de apresentação; esta pasta `docs/pt/` é o manual completo de referência.

## Mapas rápidos

- **Estrutura de pastas** → veja o diagrama em [Arquitetura](02-arquitetura.md#estrutura-de-pastas).
- **Schema do banco** → veja as tabelas em [Camada de dados](04-dados.md#schema-do-banco).
- **Casos de uso** → catálogo completo em [Domínio](03-dominio.md#catálogo-de-casos-de-uso).
- **Telas** → descrição de cada uma em [Apresentação](05-apresentacao.md#telas).
