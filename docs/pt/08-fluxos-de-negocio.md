# 08 — Fluxos de Negócio

Este documento explica como os casos de uso se combinam nos fluxos reais do sistema: **venda**, **fiado**, **fluxo de caixa** e **estoque** — e as decisões de negócio por trás de cada um.

---

## 1. Processamento de venda (fluxo atômico)

O `ProcessSaleUseCase` integra **Vendas + Estoque + Financeiro** com uma ordem deliberada de operações, tudo dentro de um **`IUnitOfWork`** (uma única transação — ou tudo é gravado, ou nada):

```text
1. Validação da venda
   ├─ rejeita venda sem itens
   └─ rejeita total divergente de Σ(quantidade × preço unitário)
      └─ comparação em CENTAVOS ((x * 100).round()) — evita falsos
         positivos de precisão de double (ex.: 2 × 9.9 + 9.9)

2. Pré-validação de estoque (SEM mutação)
   └─ para cada item: UpdateProductStockUseCase.ensureSufficientStock
      └─ se faltar → InsufficientStockException → rollback, nada gravado

3. Registro da venda (ISaleRepository.registerSale)
   └─ SQLite: tabelas sales + sale_items na mesma transação

4. Baixa do estoque (por item)
   └─ UpdateProductStockUseCase.decrease — revalida internamente
      (defesa contra chamadas diretas) e persiste VALOR ABSOLUTO
      (estoque − quantidade) via IProductRepository.updateStock

5. Entrada no caixa
   └─ FinancialTransaction(income, categoria "Vendas", status paid)
```

### Garantias

| Garantia | Como |
| -------- | ---- |
| **Atomicidade** | `IUnitOfWork` → `BEGIN IMMEDIATE` / `COMMIT` / `ROLLBACK` (SQLite); no-op em memória (web) |
| **Estoque nunca negativo** | `UpdateProductStockUseCase` é a única porta de mutação; revalida antes; repositório recebe valor absoluto; `CHECK (stock_quantity >= 0)` como salvaguarda final |
| **Sem venda "órfã"** | Pré-validação de estoque ocorre antes de qualquer gravação |
| **Sem janela TOCTOU** | `BEGIN IMMEDIATE` adquire a trava de escrita **antes** da pré-validação; fila FIFO serializa transações concorrentes no mesmo processo |
| **Sem transação aninhada inválida** | `AppDatabase` mantém contador de profundidade re-entrante (chamadas aninhadas juntam-se à externa) |

### Snapshot de preços

Cada `SaleItem` guarda `productName` e `unitPrice` **na data da venda** (além do `productId` para rastreabilidade). Isso preserva:

- preço histórico (relatórios futuros mostram o valor cobrado na época);
- integridade fiscal/contábil (o total não muda retroativamente);
- contexto real da transação mesmo após renomear/descontinuar produtos.

---

## 2. Ciclo do "fiado" (crédito)

### Registro (`AddDebtUseCase`)

1. Valida `amount > 0` (`InvalidDebtAmountException`);
2. Registra a **dívida** (`IDebtRepository.add`) — fonte de verdade do "a receber / a pagar";
3. Cria a **pendência financeira vinculada** (`debtId`):
   - cliente (`isCustomerDebt: true`) → **entrada pendente** (a receber);
   - fornecedor (`isCustomerDebt: false`) → **saída pendente** (a pagar).

> Se a pendência falhar **depois** da dívida, lança `PendingEntryRegistrationException` — a UI informa que o fiado foi registrado e pede conferência no Financeiro (nunca "tentar novamente", o que duplicaria o fiado).

### Baixa (`SettleDebtUseCase`)

```text
1. Busca a dívida (senão → DebtNotFoundException)
2. Idempotência: se já quitada, retorna (nunca duplica entrada no caixa)
3. Marca a dívida como paga (isPaid = true, paidAt = agora)
4. Entrada no caixa:
   ├─ existe pendência vinculada (debtId)?
   │    ├─ pendente → marca a MESMA transação como paga
   │    └─ já paga → nada (idempotente)
   └─ não existe → registra nova entrada (categoria "Fiado")
```

**Ordem deliberada:** a baixa acontece **antes** da entrada. Se algo falhar no meio, o pior cenário é um fiado baixado sem movimento no caixa (livro subestimado) — jamais o inverso, que permitiria **cobrar o cliente duas vezes**.

### Visualização

- `GetPendingDebtsUseCase` → dívidas a receber de clientes não quitadas (aba "Pendentes");
- `GetSettledDebtsUseCase` → dívidas a receber já quitadas (aba "Quitadas", histórico com `paidAt`).

### Impacto no capital de giro

Valor a receber é **capital imobilizado** (a mercadoria saiu, mas o dinheiro não voltou). A estrutura permite: saber quanto está parado com clientes, planejar compras sem depender do fiado, priorizar cobranças por vencimento e calcular o ciclo financeiro.

---

## 3. Fluxo de caixa (caixa realizado)

`GetCashFlowUseCase` calcula `CashFlow(income, expense, balance)` para um período `[start, end]`, considerando **apenas transações `paid`**:

```text
saldo = Σ(entradas paid) − Σ(saídas paid)
```

- Venda fiada (entrada `pending`) **só conta quando recebida**;
- Contas a pagar pendentes também não saem do caixa;
- Quando uma pendência é recebida (`MarkTransactionAsPaidUseCase` / baixa de fiado), a **data passa a ser a do recebimento** — a realização no caixa acontece quando o dinheiro entra.

### Por que `FinancialTransaction` é separada de `Sale`?

| | `Sale` | `FinancialTransaction` |
| - | ------ | ---------------------- |
| Natureza | Evento **operacional** (itens, estoque, pagamento) | Movimento de **dinheiro** (direção, categoria, valor) |
| Exemplos | venda com itens | venda, aluguel, luz, salários, impostos, aportes, fiado |
| Papel | relatórios operacionais (margem, ticket médio) | fluxo de caixa, pendências, conciliação |

Separar evita campos vazios e regras incoerentes (despesas não têm item/estoque) e dá responsabilidade única a cada modelo.

---

## 4. Controle de estoque

- **`UpdateProductStockUseCase`** é a **única porta de entrada** para mutar estoque:
  - `ensureSufficientStock(productId, quantity)` — pré-validação sem mutação;
  - `decrease(productId, quantity)` — revalida e grava **valor absoluto**;
- **`IProductRepository.updateStock`** recebe **valor absoluto** (não delta) — duas camadas de proteção;
- **`CHECK (stock_quantity >= 0)`** no SQLite é a salvaguarda final;
- A UI bloqueia adicionar ao carrinho além do estoque (`soldOut`) e sinaliza estoque baixo (`< 5` un.) no dashboard e na listagem.

---

## Documentos relacionados

- [Domínio](03-dominio.md) — casos de uso e exceções em detalhe.
- [Camada de dados](04-dados.md) — Unit of Work, schema e transações re-entrantes.
- [Apresentação](05-apresentacao.md) — como as telas consomem esses fluxos.
