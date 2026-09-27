# 03 — Domínio

A camada `lib/domain/` é o **núcleo** do sistema: regras de negócio puras, sem dependências de Flutter, Dio, SQLite ou Riverpod. Ela contém:

- **Entidades** — objetos imutáveis (`Freezed`);
- **Contratos de repositório** — interfaces abstratas;
- **Casos de uso** — orquestração das regras de negócio;
- **Exceções de domínio** — erros de negócio lançados pelos casos de uso.

---

## Entidades

Todas as entidades são classes `@freezed` (imutáveis, com `copyWith`, `==`/`hashCode` e serialização JSON via `fromJson`/`toJson` — ver `build.yaml` com `explicit_to_json: true`).

> **Fase 2 do multi-tenancy:** as entidades de negócio (`Product`, `Sale`, `FinancialTransaction`, `Debt`, `Customer`, `Purchase`) carregam **`storeId`** — a loja a que pertencem (default `'st1'`). Os `getAll` dos repositórios exigem `storeId`, então cada leitura/escrita é escopada pela loja ativa. Ver [Multi-tenancy](11-multitenancy.md#escopo-por-loja-fase-2--implementada).

### `Product` (produto)

| Campo | Tipo | Observação |
| ----- | ---- | ---------- |
| `id` | `String` | Chave primária (gerada como `p<microsecondsSinceEpoch>` na UI) |
| `storeId` | `String` | Loja a que pertence (default `'st1'` — Fase 2) |
| `name` | `String` | Obrigatório |
| `description` | `String` | Default `''` |
| `purchasePriceCents` | `int` | Preço de compra em CENTAVOS inteiros (W4) |
| `salePriceCents` | `int` | Preço de venda em CENTAVOS inteiros (W4) |
| `stockQuantity` | `int` | Estoque em MILÉSIMOS de unidade (W11): `1000` = 1 unidade ou 1 kg. Default `0` |
| `code` | `String` | Código de barras/PLU do produto (opcional, numérico, até 5 dígitos) — usado pelas balanças etiquetadoras e pelo campo de código do PDV. Default `''` |
| `vendaPorFracao` | `bool` | Venda por FRAÇÃO (peso/granel): quando `true`, o PDV aceita decimais (ex.: 1,75 kg) e intercepta códigos de balança. Default `false` |
| `unitLabel` | `String` | Unidade dos produtos por peso (`kg`, `g`, `l`, `ml`…). `'un'` (padrão) = unidade inteira normal |
| `type` | `ProductType` | Tipo estrutural do produto (Fase 1 — pastelaria/produção). Default `resale` por compatibilidade: produtos antigos já eram compráveis e vendáveis. Ver papéis abaixo |

**Tipo do produto (`ProductType`) — Fase 1.** O papel do produto na operação, em vez de tratar tudo como item de compra e venda: `rawMaterial` (matéria-prima), `resale` (comprado pronto para revenda — o default/legado), `manufactured` (produzido internamente), `composite` (montado a partir de componentes) e `packaging` (embalagem/material de consumo). Três papéis derivados governam os fluxos: `isPurchasable` (matéria-prima, revenda, embalagem — entram por compra), `isSellable` (revenda, produzido, composto — vão ao balcão) e `isProducible` (produzido e composto — podem ser o produto ACABADO de uma ficha técnica, **Fase 2**); a revenda é o único tipo comprado **e** vendido. O valor é persistido **pelo nome do enum** (`resale`, `rawMaterial`…); valor desconhecido cai no default `resale` (nunca lança).

**Regra de negócio associada:** `salePriceCents >= purchasePriceCents` — validada no `AddProductUseCase`. O estoque em milésimos segue a mesma filosofia dos centavos (W4): `int` exato, sem artefatos de `double` em somas, baixa FIFO e comparações.

### `StockLot` (lote FIFO — W11)

Cada **entrada de mercadoria cria um lote** associado ao produto — a base do controlo de validade e da baixa FIFO no PDV:

| Campo | Tipo | Observação |
| ----- | ---- | ---------- |
| `id` | `String` | `lot<microsecondsSinceEpoch>` (Dart) / `lot-<compra>-<produto>` (RPC) |
| `storeId` | `String` | Loja dona do lote (default `'st1'` — Fase 2) |
| `productId` | `String` | Produto do lote |
| `entryDate` | `DateTime` | Data de ENTRADA (data da compra) — critério FIFO quando não há validade |
| `expiryDate` | `DateTime?` | Data de VALIDADE — `null` para não perecíveis |
| `initialQuantity` | `int` | Quantidade INICIAL recebida (milésimos) — referência histórica |
| `currentQuantity` | `int` | Quantidade ATUAL disponível (milésimos) — diminui a cada baixa FIFO |
| `costPriceCents` | `int` | Custo de aquisição em CENTAVOS inteiros (W4) |

**Invariante central do módulo:** `product.stockQuantity = Σ lotes ativos` (soma de `currentQuantity` dos lotes com estoque). Ela nasce do backfill da migração W11 e é mantida pelas RPCs/use cases — nunca diverge.

### `Recipe` (ficha técnica) + `RecipeItem` — Fase 2

A **ficha técnica** (receita/BOM) descreve como produzir um produto acabado (`manufactured`/`composite`): quantos milésimos do produto a base rende e quais componentes consome.

| `Recipe` | Tipo | Observação |
| -------- | ---- | ---------- |
| `id` | `String` | Identificador da ficha |
| `storeId` | `String` | Loja dona da ficha (default `'st1'`) |
| `productId` | `String` | Produto **ACABADO** que a ficha produz (`isProducible`) — uma produção cria um lote novo dele |
| `yieldQuantity` | `int` | Rendimento da base, em MILÉSIMOS (W11): `1000` = 1 unidade. Deve ser > 0 |
| `items` | `List<RecipeItem>` | Componentes consumidos por base (ao menos um) |
| `isActive` | `bool` | Ficha ativa (default `true`); inativa fica no histórico mas não aparece para produzir |
| `createdAt` / `updatedAt` | `DateTime` / `DateTime?` | Datas |

| `RecipeItem` | Tipo | Observação |
| ----------- | ---- | ---------- |
| `productId` | `String` | Produto COMPONENTE consumido |
| `quantity` | `int` | Quantidade consumida por base, em MILÉSIMOS (W11) |

> **Sem snapshot de preço:** a ficha é **configuração** (não documento histórico) — o nome exibido vem do catálogo vivo e o custo é calculado no momento da produção a partir do preço de compra ATUAL. O snapshot vive na ordem de produção.

### `ProductionOrder` (ordem de produção) + `ProductionItem` — Fase 2

A **ordem de produção** é o documento HISTÓRICO de uma execução: baixou os componentes (FIFO por lotes) e criou um lote do produto acabado.

| `ProductionOrder` | Tipo | Observação |
| ----------------- | ---- | ---------- |
| `id` | `String` | `prod<microsecondsSinceEpoch>` |
| `storeId` | `String` | Loja da ordem (default `'st1'`) |
| `productId` / `productName` | `String` | Produto acabado (nome é snapshot) |
| `quantity` | `int` | Quantidade produzida, em MILÉSIMOS (W11) = `yieldQuantity × bases` |
| `recipeId` | `String?` | Ficha de origem (opcional — produção avulsa) |
| `costPriceCents` | `int` | Custo por unidade do acabado (CENTAVOS, W4) — vira o `cost_price` do lote criado |
| `totalCostCents` | `int` | Custo total = Σ (componente × custo unitário), em CENTAVOS |
| `dateTime` | `DateTime` | Momento da produção |
| `items` | `List<ProductionItem>` | Snapshot dos componentes consumidos |

| `ProductionItem` | Tipo | Observação |
| --------------- | ---- | ---------- |
| `productId` | `String` | Componente consumido |
| `productName` | `String` | **Snapshot** do nome na data |
| `quantity` | `int` | Quantidade consumida, em MILÉSIMOS (W11) |
| `unitCostCents` | `int` | **Snapshot** do custo unitário (CENTAVOS) na data |

> **Snapshot de propósito**, como `SaleItem`/`PurchaseItem`: o custo do lote produzido fica auditável mesmo se o catálogo mudar depois.

### `Sale` (venda) + `SaleItem` (item)

```dart
enum PaymentMethod {
 cash('Dinheiro'), debitCard('Cartão de débito'),
 creditCard('Cartão de crédito'), mPesa('M-Pesa'), eMola('E-Mola'),
 transfer('Transferência');
}
```

| `Sale` | Tipo | Observação |
| ------ | ---- | ---------- |
| `id` | `String` | `s<microsecondsSinceEpoch>` |
| `storeId` | `String` | Loja da venda (default `'st1'` — Fase 2) |
| `items` | `List<SaleItem>` | Snapshot dos itens vendidos |
| `totalAmountCents` | `int` | Soma dos itens no momento da venda, em CENTAVOS (W4) |
| `paymentMethod` | `PaymentMethod` | Forma de pagamento |
| `dateTime` | `DateTime` | Momento da venda |

| `SaleItem` | Tipo | Observação |
| ---------- | ---- | ---------- |
| `productId` | `String` | Apenas rastreabilidade |
| `productName` | `String` | **Snapshot** do nome na data da venda |
| `quantity` | `int` | Quantidade em MILÉSIMOS (W11) — 1000 = 1 unidade/kg; decimais possíveis para produtos por peso |
| `unitPriceCents` | `int` | **Snapshot** do preço unitário em CENTAVOS na data da venda (W4) |

> **Por que snapshot?** Alterações futuras de preço/nome no catálogo não podem corromper o histórico: relatórios e auditoria usam o valor cobrado **na época**, não o atual. Ver [Fluxos de negócio](08-fluxos-de-negocio.md).

### `Debt` (dívida/"fiado")

| Campo | Tipo | Observação |
| ----- | ---- | ---------- |
| `id` | `String` | `d<microsecondsSinceEpoch>` |
| `storeId` | `String` | Loja da dívida (default `'st1'` — Fase 2) |
| `personName` | `String` | Nome do cliente (ou fornecedor) |
| `amount` | `int` | `@Assert('amount >= 0')` — em CENTAVOS (W4) |
| `dueDate` | `DateTime` | Vencimento |
| `isCustomerDebt` | `bool` | `true` = a receber (cliente); `false` = a pagar (fornecedor) |
| `isPaid` | `bool` | Default `false` — quitada ou não |
| `paidAt` | `DateTime?` | Data da baixa (alimenta o histórico de quitações) |

### `FinancialTransaction` (movimentação financeira)

```dart
enum TransactionType { income('Entrada'), expense('Saída') }
enum TransactionStatus { paid('Pago'), pending('Pendente') }
```

| Campo | Tipo | Observação |
| ----- | ---- | ---------- |
| `id` | `String` | `t<microsecondsSinceEpoch>` |
| `storeId` | `String` | Loja do movimento (default `'st1'` — Fase 2) |
| `description` | `String` | Ex.: "Venda M-Pesa", "Aluguel da loja" |
| `amount` | `int` | **Sempre magnitude positiva** (em CENTAVOS, W4); direção vem de `type` |
| `type` | `TransactionType` | Entrada ou saída |
| `category` | `String` | Ex.: "Vendas", "Contas", "Compras", "Fiado" |
| `date` | `DateTime` | Data do movimento (recebimento no caso de baixa) |
| `status` | `TransactionStatus` | Default `paid`; `pending` = "fiado"/pendência |
| `debtId` | `String?` | Vínculo com a `Debt` que originou a pendência |

> **Entidade separada da `Sale`?** Sim, deliberadamente: nem toda entrada vem de venda (aportes, juros) e nem toda saída é mercadoria (aluguel, luz, salários). `Sale` = evento operacional (itens/estoque); `FinancialTransaction` = movimento de dinheiro (direção/categoria). Ver [Fluxos de negócio](08-fluxos-de-negocio.md).

### `AppUser` (usuário autenticado)

| Campo | Tipo | Observação |
| ----- | ---- | ---------- |
| `id` | `String` | UID do Supabase (ou placeholder antes da confirmação de e-mail) |
| `email` | `String` | |
| `fullName` | `String` | Default `''` — vindo de `user_metadata.full_name` |

> Abstrai o `User` do Supabase/gotrue: o domínio e a UI nunca dependem do provedor de autenticação.

---

## Contratos de repositório (interfaces)

Vivem em `lib/domain/repositories/`. Declaram **o que** o sistema precisa, nunca **como**.

| Contrato | Métodos |
| -------- | ------- |
| `IProductRepository` | `getAll(storeId)`, `getById(id)`, `add(product)`, `updateStock(id, newQuantity)` |
| `IStockLotRepository` | `getActiveByProduct(productId, storeId)` (ordem FIFO), `getByStore(storeId)` (alertas de validade), `add(lot)`, `updateQuantity(lotId, newQuantity, storeId)` |
| `ISaleRepository` | `registerSale(sale)`, `getAll(storeId)` |
| `IDebtRepository` | `getAll(storeId)`, `add(debt)`, `markAsPaid(id)` |
| `IFinancialTransactionRepository` | `getByPeriod(storeId, start, end)`, `getAll(storeId)`, `add(transaction)`, `markAsPaid(id)` |
| `ICustomerRepository` | `getAll(storeId)`, `add(customer)` |
| `IPurchaseRepository` | `getAll(storeId)`, `add(purchase)` |
| `IAuthRepository` | `signUp(...)`, `signIn(...)`, `signOut()`, `authStateChanges` (Stream) |
| `IProductionRepository` | `getRecipes(storeId)`, `saveRecipe(recipe)`, `deleteRecipe(id, storeId)`, `getProductionOrders(storeId)`, `addProductionOrder(order)` (Fase 2) |
| `IProductionProcessor` | `process(order)` — processador **atômico** de produção (só o Supabase registra, via RPC) (Fase 2) |
| `IUnitOfWork` | `run<T>(action)` — executa ação em uma transação atômica |

> Os métodos de leitura (`getAll`/`getByPeriod`) recebem **`storeId`** obrigatório: os módulos de negócio são escopados pela loja ativa (Fase 2).

Regras documentadas nos contratos:
- `IDebtRepository.markAsPaid` — **não deve ser chamado direto da UI**; a baixa passa pelo `SettleDebtUseCase` (que também registra a entrada no caixa).
- `IFinancialTransactionRepository.markAsPaid` — a **data passa a ser a do recebimento** (a realização no caixa acontece quando o dinheiro entra).
- `IProductRepository.updateStock` — recebe **valor absoluto**; a validação de não negatividade é responsabilidade do domínio (use cases).

---

## Catálogo de casos de uso

### Produtos

| Caso de uso | Comportamento |
| ----------- | ------------- |
| `GetProductsUseCase` | `getAll(storeId)` do repositório. |
| `AddProductUseCase` | Valida `salePriceCents >= purchasePriceCents`; lança `InvalidPriceException` (nada é persistido) antes de `add`. Quando há **estoque inicial**, cria também o **lote inicial** correspondente (invariante `stock = Σ lotes`). |
| `UpdateProductStockUseCase` | **Única porta de entrada para mutar o total do estoque** (agora por baixo do `FifoStockUseCase`). `ensureSufficientStock`, `increase`/`decrease` (revalidam e gravam **valor absoluto**). Lança `ProductNotFoundException` / `InsufficientStockException`. |
| `FifoStockUseCase` | **Orquestra estoque + lotes (W11).** `increase(productId, qty)` — cria lote novo (validade opcional + custo) e aumenta o total; `decrease(productId, qty)` — pré-valida a soma dos lotes, abate em ordem FIFO (`data_validade` mais próxima primeiro; sem validade por `data_entrada`) e reduz o total; `ensureSufficientStock` — pré-validação pela soma dos lotes. Lança `ProductNotFoundException` / `InsufficientStockException` (com a quantidade REAL disponível). |
| `GetStockLotsUseCase` | Leitura dos lotes ativos da loja (ordem FIFO) — alimenta os **alertas de validade** do dashboard (vencidos / < 30 dias). |

### Produção (ficha técnica) — Fase 2

| Caso de uso | Comportamento |
| ----------- | ------------- |
| `GetRecipesUseCase` | Lista as fichas técnicas da loja (mais recentes primeiro). |
| `GetProductionOrdersUseCase` | Lista o histórico de ordens de produção da loja. |
| `SaveRecipeUseCase` | Valida a ficha (produto acabado não vazio, rendimento > 0, ao menos um componente, quantidade > 0, **sem autocomposição** e **sem componente duplicado**) e grava ficha + itens em `IUnitOfWork`. Lança `InvalidRecipeException`. |
| `DeleteRecipeUseCase` | Remove a ficha da loja. |
| `ProcessProductionUseCase` | Executa uma ordem a partir da ficha: `producedQuantity = yieldQuantity × bases`; consome cada componente (`quantidade × bases`) em ordem FIFO e cria o **lote** do produto acabado com o custo calculado. Com `IProductionProcessor` (Supabase) delega à RPC atômica; sem ele, roda em `IUnitOfWork`. Lança `InvalidProductionException`, `ProductNotFoundException` / `InsufficientStockException`. **Não movimenta o caixa.** |

### Vendas

| Caso de uso | Comportamento |
| ----------- | ------------- |
| `ProcessSaleUseCase` | Fluxo atômico completo (ver [Fluxos](08-fluxos-de-negocio.md#processamento-de-venda)): valida venda → pré-valida estoque (soma dos lotes) → registra venda → **baixa FIFO dos lotes** → entrada no caixa, tudo dentro de `IUnitOfWork`. Lança `InvalidSaleException`, `InsufficientStockException`, `ProductNotFoundException`. |

### Financeiro

| Caso de uso | Comportamento |
| ----------- | ------------- |
| `AddFinancialTransactionUseCase` | Valida `amount > 0` (`InvalidAmountException`); depois `add`. |
| `GetCashFlowUseCase` | Retorna `CashFlow(income, expense, balance)` para `[start, end]`, considerando **apenas transações `paid`** (caixa realizado). Lança `InvalidPeriodException` se `start > end`. |
| `MarkTransactionAsPaidUseCase` | Marca transação pendente como paga (botão "Receber"). |

### Crédito (fiado)

| Caso de uso | Comportamento |
| ----------- | ------------- |
| `GetPendingDebtsUseCase` | Filtra `isCustomerDebt == true && !isPaid` (a receber de clientes). |
| `GetSettledDebtsUseCase` | Filtra `isCustomerDebt == true && isPaid` (histórico de quitações). |
| `AddDebtUseCase` | Valida `amount > 0` (`InvalidDebtAmountException`); registra a dívida **e** cria a **pendência financeira vinculada** (`debtId`): entrada pendente para cliente, saída pendente para fornecedor. Se a pendência falhar após a dívida, lança `PendingEntryRegistrationException` (a UI **não** sugere nova tentativa — duplicaria o fiado). |
| `SettleDebtUseCase` | Quita a dívida (marca `isPaid` + `paidAt`) e registra a **entrada no caixa** (categoria "Fiado"). Se existir pendência vinculada, marca a **mesma** transação como paga (sem duplicata). **Idempotente** — dívida já quitada não gera segunda entrada. Lança `DebtNotFoundException`. Ordem deliberada: baixa antes da entrada (nunca cobrar o cliente duas vezes). |

### Autenticação

| Caso de uso | Comportamento |
| ----------- | ------------- |
| `SignUpUseCase` | Cria conta (e-mail/senha/nome). |
| `SignInUseCase` | Autentica com e-mail/senha. |
| `SignOutUseCase` | Encerra a sessão. |

---

## Exceções de domínio (catálogo)

| Exceção | Lançada por | Quando |
| ------- | ----------- | ------ |
| `InvalidPriceException` | `AddProductUseCase` | Preço de venda < preço de compra |
| `InvalidSaleException` | `ProcessSaleUseCase` | Venda sem itens ou total divergente |
| `ProductNotFoundException` | `UpdateProductStockUseCase` / `FifoStockUseCase` | Produto inexistente |
| `InsufficientStockException` | `UpdateProductStockUseCase` / `FifoStockUseCase` | Estoque insuficiente (com `available`/`requested` — a soma real dos lotes) |
| `InvalidAmountException` | `AddFinancialTransactionUseCase` | Valor ≤ 0 |
| `InvalidPeriodException` | `GetCashFlowUseCase` | Período invertido |
| `InvalidDebtAmountException` | `AddDebtUseCase` | Valor ≤ 0 |
| `PendingEntryRegistrationException` | `AddDebtUseCase` | Fiado gravado, pendência falhou |
| `DebtNotFoundException` | `SettleDebtUseCase` | Dívida inexistente |
| `InvalidRecipeException` | `SaveRecipeUseCase` | Ficha sem produto/componentes, rendimento/quantidade ≤ 0, autocomposição ou componente duplicado |
| `InvalidProductionException` | `ProcessProductionUseCase` | Produto acabado não producível, componente ausente/desativado, bases ≤ 0 ou autocomposição |

As telas capturam essas exceções e exibem mensagens amigáveis; nenhuma exceção de infraestrutura chega à UI.

---

## Documentos relacionados

- [Arquitetura](02-arquitetura.md) — onde o domínio se encaixa.
- [Fluxos de negócio](08-fluxos-de-negocio.md) — como os casos de uso se combinam em fluxos reais.
- [Testes](09-testes.md) — casos de uso testados com fakes dos contratos.
