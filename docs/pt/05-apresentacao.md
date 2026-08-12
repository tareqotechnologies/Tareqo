# 05 — Apresentação

A camada `lib/presentation/` contém tudo que o usuário vê e interage: **providers** (estado Riverpod), **telas** (por módulo), **widgets** compartilhados e a **navegação**.

---

## Estado com Riverpod

### Arquitetura do estado

- **Providers "ponte"** (ex.: `getProductsUseCaseProvider`) leem do GetIt e expõem o caso de uso como provider — substituíveis em testes via `overrideWith`/`overrideWithValue`.
- **AsyncNotifiers** (`AsyncNotifierProvider`) expõem o estado como **`AsyncValue`** (`loading` / `error` / `data`) — as telas reagem com `.when(...)` de forma declarativa.

### Providers por módulo

| Arquivo | Providers/Notifiers |
| ------- | ------------------- |
| `auth_providers.dart` | `authRepositoryProvider`, `signIn/signUp/signOutUseCaseProvider`, **`authStateProvider`** (`StreamProvider<AppUser?>`) |
| `products_providers.dart` | `getProductsUseCaseProvider`, `addProductUseCaseProvider`, **`productsProvider`** (`AsyncNotifier<List<Product>>`) |
| `sales_providers.dart` | `salesRepositoryProvider`, `processSaleUseCaseProvider`, **`salesListProvider`** (ordenado por data desc) |
| `finance_providers.dart` | `financeRepositoryProvider`, `getCashFlowUseCaseProvider`, `addTransactionUseCaseProvider`, `markTransactionAsPaidUseCaseProvider`, **`cashFlowPeriodProvider`** (enum `CashFlowPeriod`: today/week/month/all), **`cashFlowProvider`** (reconstrói quando o período muda), **`transactionsProvider`** |
| `debts_providers.dart` | `debtsRepositoryProvider`, `getPendingDebtsUseCaseProvider`, `addDebtUseCaseProvider`, `getSettledDebtsUseCaseProvider`, `settleDebtUseCaseProvider`, **`pendingDebtsProvider`** (por vencimento), **`settledDebtsProvider`** (por `paidAt` desc) |
| `expiry_alerts_provider.dart` | `getStockLotsUseCaseProvider`, **`expiryAlertsProvider`** (`AsyncNotifier<List<ExpiryAlert>>`) — alertas de validade por lote (W11) |

**Detalhes relevantes:**

- `cashFlowProvider` calcula o período assim (todos alinhados ao **início do dia**):
  - `today` → início de hoje;
  - `week` → início de hoje − 7 dias;
  - `month` → dia 1 do mês;
  - `all` → `DateTime(2000)` até agora.
- `authStateProvider`: sem credenciais Supabase, emite `Stream.value(null)` em vez de acessar `Supabase.instance` (evita `StateError`).
- Todos os notifiers têm `refresh()` (`invalidateSelf()` + `await future`).
- As listas são **copiadas antes de ordenar** (entidades/lista retornada são imutáveis).

---

## Navegação

### `AuthGate` (portão de autenticação)

`lib/presentation/screens/auth/auth_gate.dart` decide a tela raiz:

```text
authStateProvider.when:
  loading → _SplashScreen (restaurando sessão persistida)
  error   → LoginScreen
  data    → user == null ? LoginScreen : AppShell
```

### `AppShell` (casca adaptativa)

`lib/presentation/screens/shell/app_shell.dart`:

- **Telas largas (≥ 880px, web/desktop):** `NavigationRail` à esquerda.
- **Telas estreitas (mobile):** `NavigationBar` embaixo.
- As 5 seções ficam num **`IndexedStack`** (cada aba preserva estado: busca, scroll, formulários).
- `shellIndexProvider` (`ShellIndexNotifier`) permite **trocar de aba programaticamente** — usado pelas ações rápidas do dashboard.

### Seções (`AppSection`)

| Índice | Seção | Ícone | Tela |
| ------ | ----- | ----- | ---- |
| 0 | Início | `space_dashboard` | `DashboardScreen` |
| 1 | Produtos | `inventory_2` | `ProductListScreen` |
| 2 | Vendas | `point_of_sale` | `SalesScreen` |
| 3 | Financeiro | `account_balance_wallet` | `FinancialScreen` |
| 4 | Crédito | `receipt_long` | `DebtsScreen` |
| 5 | Clientes | `people` | `CustomersScreen` |

> **Compras** e **Relatórios** são telas empilhadas (`Navigator.push`) a partir da seção **"Módulos"** do dashboard — mantém a barra de navegação com 6 abas. O dashboard também navega para a aba Clientes pelo card correspondente.

---

## Telas

### 1. `DashboardScreen` (Início)

- Saudação com nome do usuário ("Olá, Maria 👋") + data do dia em pt-BR + botão **Sair**;
- **KPIs** em grid responsivo (2 colunas mobile / 4 em telas largas):
  - Total de vendas (todo o histórico);
  - Saldo em caixa (período selecionado no Financeiro);
  - A receber (fiado) — soma das pendências;
  - Estoque em produtos (soma das quantidades);
- **Ações rápidas:** Nova venda, Adicionar produto, Registrar transação, Registrar fiado (navegam via `shellIndexProvider`);
- **Vendas recentes** (3 últimas) e alerta de **estoque baixo** (`stockQuantity < 5000` milésimos = 5 unidades, via `Quantity.lowStockThresholdUnits`);
- **Alertas de validade (W11)** via `expiryAlertsProvider`: **vermelho** para lotes **vencidos** com estoque e **amarelo** para vencimento em **menos de 30 dias** (`expiryWarningDays`), ordenados por urgência (vencidos primeiro).

### 2. `ProductListScreen` (Produtos)

- Busca local (nome e descrição), pull-to-refresh, FAB "Novo produto";
- Cards com preço de compra/venda e chip de estoque (amarelo se `< 5` unidades = `< 5000` milésimos);
- Cadastro via **`_AddProductSheet`** (bottom sheet): nome, descrição, preços, estoque, **código/PLU da balança** (opcional), switch **"Venda por peso"** (`vendaPorFracao` — habilita frações decimais) e **unidade de venda** (`kg`/`un`) — captura `InvalidPriceException` e mostra a mensagem;
- Estoque exibido com **fração e unidade** para produtos por peso (ex.: `1,75 kg`).
- `EmptyState` para lista vazia e para busca sem resultado.

### 3. `SalesScreen` + `NewSaleSheet` + `SaleDetailScreen` (Vendas)

- **Lista:** cards com nº de itens, forma de pagamento, dia e total; toque abre o **detalhe**;
- **`NewSaleSheet`** (carrinho):
  - Busca e adiciona produtos com **steppers** (+/−) limitados ao estoque (`soldOut` desabilita); produtos por peso usam **passos de 0,1** e abrem **diálogo de quantidade decimal** (ex.: `1,75` kg);
  - **Campo de código de barras** (scanners USB tipo teclado disparam a busca no `onSubmitted`) + **leitura por câmera** via `BarcodeScanSheet` (`mobile_scanner`, onde suportado);
  - Intercepta o padrão de **balanças etiquetadoras `20PPPPPWWWWW`** (`ScaleBarcode`): extrai o PLU, deriva a fração pela pesagem (valor ÷ preço — nunca cobra a mais) e só interpreta como balança se o produto for `vendaPorFracao` — EAN-12 que comece com `20` cai no fallback normal; PLUs são normalizados (zeros à esquerda: `123` ≡ `00123`);
  - Forma de pagamento via `ChoiceChip`s (`PaymentMethod.values`);
  - Confirma via **`ProcessSaleUseCase`** → registra venda + **baixa FIFO do estoque (lotes)** + entrada no caixa;
  - Captura `InsufficientStockException` (mostra produto e disponível) e `ProductNotFoundException`;
  - Após sucesso, invalida `productsProvider`, `salesListProvider`, `transactionsProvider`, `cashFlowProvider`, `expiryAlertsProvider`;
- **`SaleDetailScreen`:** resumo (id, data, pagamento, total), itens com `quantidade × preço` e subtotal, e aviso "Preços congelados no momento da venda".

### 4. `FinancialScreen` + `AddTransactionSheet` (Financeiro)

- **SegmentedButton** de período (`CashFlowPeriod`);
- 3 KPIs: **Entradas**, **Saídas**, **Saldo** (cores semânticas verde/vermelho);
- Lista de **movimentações**: ícone direcional, descrição, categoria + dia, valor com sinal (+/−) e cor;
- Pendências (entrada com status `pending`) exibem chip "Pendente" + botão **"Receber"** (confirmação em diálogo → `MarkTransactionAsPaidUseCase` → invalida caixa/movimentações);
- **`AddTransactionSheet`:** tipo Entrada/Saída (SegmentedButton), descrição, categoria (default "Vendas"/"Despesas"), valor e switch **"Pendente (fiado)"** — captura `InvalidAmountException`.

### 5b. `CustomersScreen` (Clientes)

- Busca local (nome, telefone, e-mail), pull-to-refresh e FAB "Novo cliente";
- Cards com avatar (inicial), nome, contatos e **chip de fiado pendente** do cliente (soma das dívidas vinculadas via `Debt.customerId`);
- Cadastro via **`_AddCustomerSheet`**: nome (obrigatório), telefone e e-mail opcionais — captura `InvalidCustomerException`;
- **Integração com o fiado:** o `AddDebtSheet` permite **vincular** a dívida a um cliente (chips) — o `personName` vira o snapshot do nome e `customerId` guarda o vínculo.

### 5c. `PurchasesScreen` + `AddPurchaseSheet` (Compras)

- Lista de compras (fornecedor, nº de itens, dia e total);
- **`AddPurchaseSheet`**: fornecedor, busca de produtos com steppers e total (preço de compra); produtos por peso aceitam **fração decimal** e cada item pode receber **data de validade** (opcional — alimenta o lote FIFO da entrada) → **`ProcessPurchaseUseCase`** registra a compra, **aumenta o estoque criando lotes** e lança a **saída no caixa** (categoria "Compras"); captura `ProductNotFoundException`;
- Após sucesso, invalida compras, produtos, movimentações, caixa e alertas de validade.

### 5d. `ReportsScreen` (Relatórios)

- Seletor de período (`ReportPeriod`: Hoje / 7 dias / Este mês / Tudo);
- KPIs: **Faturamento**, **Lucro bruto** e **Margem %**;
- **Mais vendidos** (top 5 por quantidade, com receita) e **vendas por dia** — calculados pelo `GetSalesReportUseCase` a partir das vendas (snapshots) e do catálogo atual.

### 5. `DebtsScreen` + `AddDebtSheet` (Crédito)

- **Abas:** "Pendentes" e "Quitadas" (SegmentedButton local `_DebtView`);
- **Pendentes:** card resumo "Total a receber" (laranja) + lista de dívidas com avatar da inicial, chip de vencimento (`Atrasada` vermelho / `Vence hoje` amarelo / `Em N dias` verde) e botão **"Quitar dívida"** (diálogo de confirmação → `SettleDebtUseCase` → invalida fiado, histórico, caixa e saldo);
- **Quitadas:** card resumo "Total quitado" (verde) + histórico com `paidAt` ("Quitada em 25/07/2026");
- **`AddDebtSheet`:** nome do cliente, valor, vencimento (DatePicker) → `AddDebtUseCase` (registra dívida + pendência financeira vinculada); captura `InvalidDebtAmountException` e trata `PendingEntryRegistrationException` de forma especial (informa que o fiado foi registrado e pede conferência no Financeiro — sem sugerir nova tentativa).

---

## Widgets compartilhados

| Widget | Função |
| ------ | ------ |
| `showAppSheet` + `AppSheetHeader` | Bottom sheet padrão (cantos de 28px, SafeArea, padding de teclado, título + fechar) |
| `KpiCard` | Indicador: ícone colorido, valor (com `FittedBox` anti-overflow), rótulo, caption, estado loading ("—") |
| `StatusChip` | Pílula de status com fundo translúcido e ícone opcional |
| `EmptyState` | Estado vazio: ícone em caixa arredondada, título, subtítulo, ação opcional |
| `ErrorView` | Estado de erro: mensagem + detalhe técnico + botão "Tentar novamente" |
| `SearchField` | Campo de busca preenchido e arredondado (sem contorno) |
| `SectionHeader` | Título de seção com ação opcional à direita |
| `BarcodeScanSheet` | Leitor de código de barras por câmera (`mobile_scanner`) usado no PDV (W11) |

---

## Tema (Material 3)

`lib/core/theme/app_theme.dart`:

- **Seed:** verde-esmeralda profundo `#0E6B5A`; `ColorScheme.fromSeed` para claro/escuro;
- **Cores semânticas (`AppColors`):** `income` verde `#189A5E`, `expense` vermelho `#D64550`, `warning` laranja `#E08F2B`;
- **Diretrizes visuais:** superfícies neutras, cards com borda sutil sem sombra pesada (`elevation: 0`), cantos arredondados (14–20px), campos **preenchidos sem contorno**, botões `FilledButton` com altura 52;
- **Navegação:** `NavigationBar` (altura 68, indicador `primaryContainer`) e `NavigationRail` (`groupAlignment: -0.9`);
- **Tipografia:** escala modular (Apple HIG/SF Pro): **34** (Large Title — login/boas-vindas) → **28** (títulos de página) → **24** (KPIs/totais) → **22** (cartões/modais/AppBar) → **20** (subtítulos/seções) → **17/15/14/13/12/11** (corpo destacado/corpo/destaques/nota/labels/caption); hierarquia por tamanho + peso (w300 display, w400 corpo, w600+ valores), **`tabularFigures`** nos estilos numéricos (preços MZN e quantidades kg/un alinham dígito a dígito) e **três eixos de precisão** como o SF Pro: (1) **eixo óptico `opsz`** — a Inter é variável (14–32) e títulos ≥20px usam o corte *Display* (opsz 24–32) enquanto o corpo fica no corte *Texto*; (2) **tracking** negativo nos títulos (−0.15 a −0.6), neutro no corpo e positivo leve nos captions; (3) **entrelinha** na razão do SF Pro (~1.2 títulos, ~1.4 corpo); a decisão completa (tabela da escala, papéis e regras de ouro) está no [capítulo 12 — Decisões de Arquitetura](12-decisoes-de-arquitetura.md);
- **SnackBars flutuantes** com tema invertido (escuro no tema claro e vice-versa).

O tema é aplicado em `app.dart`:

```dart
MaterialApp(
  title: 'Dumbhanengue ERP',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: const AuthGate(),
)
```

---

## Formatação pt-BR (`Formatters`)

`lib/core/utils/formatters.dart`:

- `currency(int cents)` → `1.234,56` com símbolo do tenant (default `R$`, tenants em Moçambique usam `MTn`) — desde a W4, dinheiro é centavos inteiros;
- `date(DateTime)` → `04/08/2026`;
- `dateTime(DateTime)` → `04/08/2026 14:30`;
- `day(DateTime)` → `Hoje`, `Ontem` ou `04/08`.

---

## Documentos relacionados

- [Arquitetura](02-arquitetura.md) — como a apresentação conversa com o domínio.
- [Autenticação](06-autenticacao.md) — `AuthGate` e o fluxo de sessão.
- [Testes](09-testes.md) — testes de tela com providers sobrescritos.
