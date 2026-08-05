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
| `purchasePrice` | `double` | Preço de compra |
| `salePrice` | `double` | Preço de venda |
| `stockQuantity` | `int` | Default `0` |

**Regra de negócio associada:** `salePrice >= purchasePrice` — validada no `AddProductUseCase`.

### `Sale` (venda) + `SaleItem` (item)

```dart
enum PaymentMethod {
  cash('Dinheiro'), debitCard('Cartão de débito'),
  creditCard('Cartão de crédito'), pix('Pix'), transfer('Transferência');
}
```

| `Sale` | Tipo | Observação |
| ------ | ---- | ---------- |
| `id` | `String` | `s<microsecondsSinceEpoch>` |
| `storeId` | `String` | Loja da venda (default `'st1'` — Fase 2) |
| `items` | `List<SaleItem>` | Snapshot dos itens vendidos |
| `totalAmount` | `double` | Soma dos itens no momento da venda |
| `paymentMethod` | `PaymentMethod` | Forma de pagamento |
| `dateTime` | `DateTime` | Momento da venda |

| `SaleItem` | Tipo | Observação |
| ---------- | ---- | ---------- |
| `productId` | `String` | Apenas rastreabilidade |
| `productName` | `String` | **Snapshot** do nome na data da venda |
| `quantity` | `int` | Quantidade |
| `unitPrice` | `double` | **Snapshot** do preço na data da venda |

> **Por que snapshot?** Alterações futuras de preço/nome no catálogo não podem corromper o histórico: relatórios e auditoria usam o valor cobrado **na época**, não o atual. Ver [Fluxos de negócio](08-fluxos-de-negocio.md).

### `Debt` (dívida/"fiado")

| Campo | Tipo | Observação |
| ----- | ---- | ---------- |
| `id` | `String` | `d<microsecondsSinceEpoch>` |
| `storeId` | `String` | Loja da dívida (default `'st1'` — Fase 2) |
| `personName` | `String` | Nome do cliente (ou fornecedor) |
| `amount` | `double` | `@Assert('amount >= 0')` |
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
| `description` | `String` | Ex.: "Venda via PIX", "Aluguel da loja" |
| `amount` | `double` | **Sempre magnitude positiva**; direção vem de `type` |
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
| `ISaleRepository` | `registerSale(sale)`, `getAll(storeId)` |
| `IDebtRepository` | `getAll(storeId)`, `add(debt)`, `markAsPaid(id)` |
| `IFinancialTransactionRepository` | `getByPeriod(storeId, start, end)`, `getAll(storeId)`, `add(transaction)`, `markAsPaid(id)` |
| `ICustomerRepository` | `getAll(storeId)`, `add(customer)` |
| `IPurchaseRepository` | `getAll(storeId)`, `add(purchase)` |
| `IAuthRepository` | `signUp(...)`, `signIn(...)`, `signOut()`, `authStateChanges` (Stream) |
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
| `AddProductUseCase` | Valida `salePrice >= purchasePrice`; lança `InvalidPriceException` (nada é persistido) antes de `add`. |
| `UpdateProductStockUseCase` | **Única porta de entrada para mutar estoque.** `ensureSufficientStock(productId, qty)` (pré-validação sem mutação) e `decrease(productId, qty)` (revalida e grava **valor absoluto** `estoque − qty`). Lança `ProductNotFoundException` / `InsufficientStockException`. |

### Vendas

| Caso de uso | Comportamento |
| ----------- | ------------- |
| `ProcessSaleUseCase` | Fluxo atômico completo (ver [Fluxos](08-fluxos-de-negocio.md#processamento-de-venda)): valida venda → pré-valida estoque → registra venda → baixa estoque → entrada no caixa, tudo dentro de `IUnitOfWork`. Lança `InvalidSaleException`, `InsufficientStockException`, `ProductNotFoundException`. |

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
| `ProductNotFoundException` | `UpdateProductStockUseCase` | Produto inexistente |
| `InsufficientStockException` | `UpdateProductStockUseCase` | Estoque insuficiente (com `available`/`requested`) |
| `InvalidAmountException` | `AddFinancialTransactionUseCase` | Valor ≤ 0 |
| `InvalidPeriodException` | `GetCashFlowUseCase` | Período invertido |
| `InvalidDebtAmountException` | `AddDebtUseCase` | Valor ≤ 0 |
| `PendingEntryRegistrationException` | `AddDebtUseCase` | Fiado gravado, pendência falhou |
| `DebtNotFoundException` | `SettleDebtUseCase` | Dívida inexistente |

As telas capturam essas exceções e exibem mensagens amigáveis; nenhuma exceção de infraestrutura chega à UI.

---

## Documentos relacionados

- [Arquitetura](02-arquitetura.md) — onde o domínio se encaixa.
- [Fluxos de negócio](08-fluxos-de-negocio.md) — como os casos de uso se combinam em fluxos reais.
- [Testes](09-testes.md) — casos de uso testados com fakes dos contratos.
