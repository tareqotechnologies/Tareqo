# 01 — Visão Geral

## O que é o TAREQO ERP?

O **TAREQO ERP** é um sistema de gestão empresarial voltado para **pequenos comerciantes**. Ele concentra em um único aplicativo as operações do dia a dia de uma loja:

- **Estoque** — cadastro e controle de produtos com **lotes FIFO e validade** (compra, venda, quantidade disponível, vencimento);
- **Vendas** — registro de vendas com carrinho, forma de pagamento e baixa automática de estoque;
- **Financeiro** — fluxo de caixa (entradas × saídas), movimentações e pendências;
- **Crédito ("fiado")** — controle de quem deve ao comerciante, quando vence e histórico de quitações.

O nome *TAREQO* é o apelido do projeto; o produto em si é um ERP enxuto, com foco em usabilidade e simplicidade.

---

## Objetivos do produto

1. **Responder às perguntas essenciais do comerciante:**
 - "Quanto vendi?" (total de vendas);
 - "Quanto tenho em caixa?" (saldo do fluxo de caixa);
 - "Quanto tenho a receber de fiado e de quem?" (crédito a receber);
 - "Quanto tenho em estoque e o que está acabando?" (estoque baixo).
2. **Evitar o "buraco negro do fiado":** transformar o crédito concedido em um número visível e gerenciável (quem deve, quanto, quando vence).
3. **Garantir integridade do negócio:** estoque nunca negativo, vendas atômicas, caixa sempre consistente.
4. **Ser um modelo SaaS multi-tenant:** autenticação por loja/comerciante (Supabase), preparado para RLS (Row Level Security).

---

## Funcionalidades

### Implementadas (v1.0.0)

| Módulo | Funcionalidades |
| ------ | --------------- |
| **Autenticação** | Cadastro e login com e-mail/senha (Supabase), sessão persistente e restaurada no boot, logout |
| **Início (Dashboard)** | KPIs (total de vendas, saldo em caixa, a receber de fiado, estoque), ações rápidas, vendas recentes, alerta de estoque baixo |
| **Produtos** | Listagem com busca local, cadastro via bottom sheet (com validação de preço), **código/PLU de balança e venda por peso** (W11), pull-to-refresh, chip de estoque baixo |
| **Estoque (FIFO, W11)** | **Lotes por entrada** com quantidade, validade e custo de aquisição; baixa no PDV em ordem **FIFO** (validade mais próxima primeiro); alertas de vencimento no dashboard (**vermelho** = vencido, **amarelo** = < 30 dias) |
| **Vendas** | Histórico de vendas, carrinho de nova venda (steppers de quantidade e **frações decimais** para produtos por peso), **leitura de código de barras de balanças etiquetadoras (`20PPPPPWWWWW`)** e 6 formas de pagamento, detalhe da venda com snapshot de preços |
| **Compras** | Entrada de mercadorias de fornecedores: carrinho com steppers, **validade opcional por item** (cria os lotes da entrada), **aumenta o estoque** e lança a saída no caixa (categoria "Compras") |
| **Financeiro** | Fluxo de caixa por período (Hoje / 7 dias / Este mês / Tudo), entradas/saídas/saldo, registro de movimentações, pendências com botão "Receber" |
| **Crédito (fiado)** | Total a receber, dívidas por vencimento (chips de atraso), registro de fiado **com vínculo opcional a um cliente**, baixa com confirmação, aba de histórico de quitações |
| **Clientes** | Cadastro (nome, telefone, e-mail), busca, total de fiado pendente por cliente no card |
| **Relatórios** | Faturamento, lucro bruto, margem %, produtos mais vendidos (top 5) e vendas por dia, com seletor de período |
| **Contas (SaaS)** | Dono se cadastra, escolhe plano e **aguarda aprovação do super admin (≤ 24h)**; aprovado, cria **lojas** e **funcionários** (com limites do plano) e solicita **upgrade de plano** |
| **Super Admin** | Painel administrativo: aprovar/rejeitar solicitações de tenant, decidir upgrades de plano e criar/editar planos (que limitam lojas e funcionários de cada tenant) |
| **Multi-loja (Fase 2)** | Escopo por **loja** (`store_id`) em produtos, vendas, financeiro, fiado, clientes e compras — cada loja com estoque, caixa e histórico próprios — com **seletor de loja ativa** no topo de todas as telas |

### Diferenciais de design

- **Navegação adaptativa:** `NavigationRail` em telas largas (web/desktop) e `NavigationBar` em telas estreitas (mobile), com 6 abas (Início, Produtos, Vendas, Financeiro, Crédito, Clientes) e acesso a Compras/Relatórios/Lojas pelo dashboard (seção "Módulos").
- **Acesso por papel:** super admin entra no painel administrativo; dono sem aprovação vê as telas de espera/motivo até a liberação; dono aprovado opera o ERP e gerencia lojas/funcionários.
- **Tema claro e escuro** (Material 3) com um único acento verde-esmeralda.
- **Formatação pt-BR:** moeda (`R$ 1.234,56`), datas (`04/08/2026`) e dias relativos (`Hoje`, `Ontem`).
- **100% dados reais:** o app não traz dados de demonstração — cada tenant começa vazio e registra apenas o que o usuário criar.

---

## Público-alvo e plataformas

- **Usuário final:** pequenos comerciantes (mercados, papelarias, armarinhos, lojas de bairro) que precisam controlar estoque, vendas e fiado.
- **Plataformas:** Android, iOS, Windows, Linux, macOS e **Web** (com fallback de persistência em memória).

---

## Stack e dependências

| Pacote | Papel | Camada |
| ------ | ----- | ------ |
| `flutter_riverpod` ^3.4.2 | Gerenciamento de estado reativo (AsyncNotifier) | presentation |
| `get_it` ^9.2.1 | Injeção de dependência (Service Locator) | core |
| `freezed` 3.2.x + `json_serializable` | Entidades imutáveis e serialização JSON (codegen) | domain/data |
| `supabase_flutter` ^2.16.0 | Autenticação SaaS e futuro backend (Postgres/RLS) | data |
| `flutter_secure_storage` ^10.3.1 | Persistência criptografada (Keychain/Keystore) | core |
| `sqlite3` + `sqlite3_flutter_libs` | Persistência local relacional (SQL parametrizado) | data |
| `path_provider` + `path` | Localização do arquivo do banco | core/data |
| `dio` ^5.11.0 | Cliente HTTP (reservado para APIs REST futuras) | data |
| `mobile_scanner` | Leitura de código de barras por câmera no PDV (balanças/PLU, W11) | presentation |

> SDK Dart `^3.12.2` (Flutter 3.x recente).

---

## Estado atual e próximos passos

O app está funcional de ponta a ponta. Com o Supabase configurado (padrão), os módulos de negócio **sincronizam no Postgres por tenant e por loja** — produtos, vendas, financeiro, fiado, clientes e compras — com RLS + triggers de isolamento (schema em `supabase/schema.sql`). A atomicidade cross-tabela (venda/compra + estoque + caixa) e a **baixa FIFO por lotes** rodam nas RPCs `SECURITY DEFINER` (`process_sale`, `process_purchase`) do servidor. Sem Supabase configurado, a persistência cai para **SQLite (nativas)** ou **memória (web)**.

Próximos passos:

1. Recorrência de despesas fixas (agendamento de aluguel/luz);
2. ~~Ação "Pagar" para saídas pendentes no Financeiro~~ ✓ **FEITO** — saídas pendentes (contas a pagar) ganham o botão "Pagar" (mesmo ciclo `pending → paid` das entradas, via `_settlePending` unificado);
3. Cache offline (leitura local + sincronização) para uso sem conexão;
4. ~~Aplicação dos limites de plano no servidor~~ ✓ **FEITO** — triggers `enforce_store_limit`/`enforce_employee_limit` no Postgres (ver 1.4 do checklist).

---

## Documentos relacionados

- [Arquitetura](02-arquitetura.md) — como o código está organizado.
- [Fluxos de negócio](08-fluxos-de-negocio.md) — como vendas, fiado e caixa funcionam por dentro.
- [Multi-tenancy e Super Admin](11-multitenancy.md) — planos, aprovação de acesso e gestão de lojas.
- [Guia do desenvolvedor](10-guia-desenvolvedor.md) — como rodar e evoluir o projeto.
