# 08 — Fluxos de Negócio

Este documento explica como os casos de uso se combinam nos fluxos reais do sistema: **venda** (inclui a **anulação**), **fiado**, **fluxo de caixa**, **estoque** e **fecho de caixa diário (Z-report)** — e as decisões de negócio por trás de cada um.

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

### Anulação de venda (estorno — `cancel_sale`)

O `CancelSaleUseCase` **desfaz** uma venda registrada: devolve o estoque aos lotes exatos, estorna o caixa e marca a venda como **anulada** no histórico (ela permanece visível com o selo "Anulada", mas sai de relatórios, KPIs e do resumo do dia). É operação **gerencial** (dono/gerente) — funcionário comum não anula.

```text
SaleDetailScreen (detalhe da venda ATIVA + usuário dono/gerente)
  │  confirmação (AlertDialog mostra o valor da venda)
  ▼
CancelSaleUseCase
  │
  ├─ MODO SUPABASE (ISaleCancellationProcessor → RPC cancel_sale, UMA transação):
  │    ├─ delegação IMEDIATA (sem validação client-side) — o servidor valida
  │    │   existência + idempotência: guarda is_manager_of_store (funcionário
  │    │   NÃO anula — o servidor é a autoridade, mesmo que um cliente
  │    │   modificado contorne a UI)
  │    ├─ lê e TRAVA a venda FOR UPDATE (escopo por loja); inexistente ou já
  │    │   anulada → no-op (nunca lança SaleNotFoundException)
  │    ├─ devolve o estoque aos LOTES EXATOS consumidos (sale_lot_consumption):
  │    │    └─ por lote (FOR UPDATE): current_quantity += devolvido
  │    │       e stock_quantity do produto += devolvido — a invariante
  │    │       `stock = Σ lotes` nunca quebra
  │    ├─ estorno no caixa: SAÍDA (expense) no valor da venda, categoria Vendas,
  │    │   status paid, descrição "Estorno de venda — <forma>" — o par
  │    │   (entrada original + estorno) fecha o caixa em ZERO
  │    └─ marca a venda: status = 'cancelled', cancelled_at = now()
  │
  └─ MODO LOCAL (SQLite/memória, dentro de IUnitOfWork):
       ├─ validação: getById → senão SaleNotFoundException; já anulada →
       │  retorna (no-op idempotente)
       ├─ FifoStockUseCase.restoreLot para cada LotConsumption
       ├─ markCancelled(saleId, storeId)
       └─ add FinancialTransaction(expense, "Estorno de venda — …", categoria Vendas)
  ▼
Venda anulada → UI: selo "Anulada", total riscado, permanece no histórico
  └─ SAI de relatórios, KPIs e do resumo do dia (status != 'active' é filtrado)
  └─ invalida salesListProvider, productsProvider, transactionsProvider,
     cashFlowProvider e dashboardKpisProvider (telas recarregam)
```

### Decisões de negócio da anulação

| Decisão | Por quê |
| ------- | ------- |
| **Devolve aos lotes EXATOS** | O consumo de lotes é gravado no registro da venda (`sale_lot_consumption`) — a anulação devolve cada lote à sua quantidade original, **preservando validade e custo** (sem misturar lotes) |
| **Estorno fecha o caixa em zero** | A entrada original (Vendas, paid) + a saída de estorno (Vendas, paid) se compensam — o caixa do dia não fica inflado por venda cancelada |
| **Venda anulada permanece no histórico** | Trilha de auditoria: o registro continua visível com o selo "Anulada" e o momento da anulação (`cancelledAt`) |
| **Sai de relatórios/KPIs/resumo do dia** | Todos os agregados filtram `status = 'active'` (client-side e RPCs) — anulada nunca conta como faturamento |
| **Idempotência** | Anular duas vezes é um **no-op** — nunca cria estorno duplicado nem devolve estoque duas vezes (no Supabase, venda inexistente ou já anulada também é no-op, sem exceção) |
| **Anulação é gerencial** | Como compras e fecho de caixa: `is_manager_of_store` no servidor; `canCancelSalesProvider` no app é só orientação de UX |
| **Servidor é a autoridade no SaaS** | O cliente envia só `sale_id` + `store_id`; a RPC valida sessão, guarda e executa o estorno em UMA transação |

> **Verificação:** `sql_check.sh` (17.x) executa `cancel_sale` como `app_user` e confere: estoque/lote restaurados, `cancelled_at` preenchido, **segunda anulação sem duplicar**, venda anulada **fora** do KPI/relatório (delta em centavos) e **funcionário rejeitado** ao anular.

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

### 4.1 Total do produto (camada histórica)

- **`UpdateProductStockUseCase`** é a porta que muta o **total** `stock_quantity` do produto:
  - `ensureSufficientStock(productId, quantity)` — pré-validação sem mutação;
  - `increase`/`decrease` — revalidam e gravam **valor absoluto**;
- **`IProductRepository.updateStock`** recebe **valor absoluto** (não delta) — duas camadas de proteção;
- **`CHECK (stock_quantity >= 0)`** no SQLite é a salvaguarda final;
- A UI bloqueia adicionar ao carrinho além do estoque (`soldOut`) e sinaliza estoque baixo (`< 5` un.) no dashboard e na listagem.

### 4.2 FIFO por lotes + validade (W11)

Desde o **W11**, o estoque tem camada de **lotes**: cada entrada de mercadoria cria um `StockLot` (validade opcional, custo de aquisição, quantidade inicial/atual) e o total do produto é a **soma dos lotes ativos** (`stock = Σ lotes`). O `FifoStockUseCase` é a porta única que orquestra os dois:

```text
Entrada (compra)
  └─ increase: valida produto → cria LOTE novo (validade opcional, custo)
     └─ aumenta o total do produto (mesma quantidade)

Baixa (venda)
  └─ decrease: pré-valida a SOMA dos lotes (nada é mutado se faltar)
     └─ consome os lotes em ordem FIFO:
        1º data_validade ASC (mais próximo do vencimento primeiro)
        2º sem validade no fim — por data_entrada ASC
     └─ se um lote não cobre, o excedente abate do lote SEGUINTE
     └─ reduz o total do produto na mesma quantidade
```

**Por que FIFO por validade?** O lote que vence primeiro deve sair primeiro — evita prejuízo por mercadoria vencida parada no estoque e é o comportamento esperado pelo comerciante (e pela fiscalização sanitária). Lotes sem validade (não perecíveis) são consumidos por antiguidade de entrada.

**Alertas no dashboard:** lotes ativos com `expiryDate` são classificados por urgência — **vermelho** para já vencidos (com estoque) e **amarelo** para vencimento em menos de 30 dias (`expiryAlertsProvider`, janela `expiryWarningDays = 30`). O comerciante sabe o que precisa sair (promoção/descarte) antes de vencer.

> **Em Supabase**, a baixa FIFO roda na **RPC `process_sale`** (lotes travados com `FOR UPDATE`, ordem FIFO idêntica) e a entrada cria lotes na **RPC `process_purchase`** — mesmo contrato do caminho local, validado pelo `sql_check.sh`.

### 4.3 Vendas por peso / balanças etiquetadoras (W11)

Produtos marcados com **`vendaPorFracao: true`** (ex.: arroz, feijão, queijo — unidade `kg`) aceitam **quantidades decimais** no PDV (ex.: 1,75 kg). Além do stepper de 0,1 e da edição manual, o PDV intercepta leituras de **balanças etiquetadoras** no formato `20PPPPPWWWWW`:

```text
20 PP PPP P WW WWW
│  └────┬──┘  └─┬──┘
pref  código   valor total
'20'  produto  da pesagem (5 dígitos, em CENTAVOS)
```

O fluxo no PDV (`_handleBarcode`):

```text
leitura → 20 + 5 + 5 dígitos?
  ├─ NÃO → busca pelo code/PLU normal (adiciona 1 unidade)
  └─ SIM → busca o produto pelo PLU (normalizando zeros à esquerda:
           "00123" ≡ "123")
      ├─ produto não é venda_por_fracao? → NÃO intercepta (cai no
      │   fluxo normal — evita confundir EAN-12 que comece com "20")
      └─ é por peso → deriva a QUANTIDADE:
           qtd(milésimos) = valor_total_centavos × 1000 ~/ preço_unitário
           (divisão inteira — nunca cobra a mais por arredondamento)
         e adiciona ao carrinho (limitada ao estoque)
```

> A balança imprime o **valor total** da pesagem (não o peso); a fração de peso é derivada matematicamente de `valor ÷ preço unitário` — ex.: etiqueta de 200,00 a 80,00/kg → 2,5 kg → 2500 milésimos.

---

## 5. Fecho de caixa diário (Z-report)

O `CloseCashRegisterUseCase` registra o **fecho do dia** da loja com a **conferência do dinheiro físico** na gaveta. É uma operação **gerencial** (dono/gerente) — funcionário comum não fecha. O fluxo tem duas fases: a **prévia** (leitura) e a **confirmação** (escrita).

> **Prévia server-side (H2):** o resumo do dia chega da RPC `get_cash_closing_summary` (ver [Arquitetura — Agregações server-side](02-arquitetura.md)) — o app nunca lista o histórico de vendas para somar no dispositivo. Esta seção cobre a **confirmação**.

```text
CashClosingSheet (Financeiro → Fecho de caixa)
  │  1. PRÉVIA — cashClosingSummaryProvider → get_cash_closing_summary (server-side)
  │     └─ total do dia (todas as formas) · esperado na gaveta (só DINHEIRO)
  │        · abertura por forma (JSONB) · fecho já registrado (se houver)
  │  2. O usuário (dono/gerente) digita a CONTAGEM FÍSICA da gaveta
  │     └─ diferença AO VIVO: confere / sobra / falta (conforme o esperado)
  ▼
CloseCashRegisterUseCase
  ├─ valida countedCashCents >= 0 → senão InvalidCashCountException
  │
  ├─ MODO SUPABASE (ICashClosingProcessor → RPC close_cash_register, UMA transação):
  │    ├─ guarda is_manager_of_store — funcionário NÃO fecha (servidor é a autoridade,
  │    │   mesmo que um cliente modificado contorne a UI)
  │    ├─ valida a sessão e a contagem não-negativa NO SERVIDOR
  │    ├─ calcula NO SERVIDOR (o cliente NUNCA envia valores calculados):
  │    │    └─ esperado = Σ vendas ATIVAS em DINHEIRO no dia [p_day, p_day+1)
  │    │       · total = Σ vendas ATIVAS (todas as formas)
  │    │       · abertura = jsonb_object_agg por forma (relatório Z)
  │    └─ UPSERT em cash_closings (UNIQUE store_id + closing_date):
  │         refazer o fecho do dia ATUALIZA a contagem física, sem duplicar
  │    └─ devolve o fecho registrado (JSONB) → UI exibe o resultado
  │
  └─ MODO LOCAL (SQLite/memória):
       └─ aggregateCashClosingDay (MESMO critério da RPC: ativas, anuladas fora)
          → ICashClosingRepository.save (UPSERT por loja + dia)
  ▼
Fecho persistido → UI mostra o resultado (no SaaS, os valores exibidos são
  o RETORNO da RPC — o servidor é a autoridade)
  └─ invalida cashClosingSummaryProvider + cashClosingHistoryProvider
     (prévia e histórico são re-buscados com o fecho novo)
```

### Decisões de negócio

| Decisão | Por quê |
| ------- | ------- |
| **Esperado = só dinheiro** | Cartão/M-Pesa/E-Mola/transferência **não passam pela gaveta física** — o esperado compara só o que deveria estar em espécie |
| **Contagem nunca negativa** | O dono pode fechar com a gaveta **zerada**, mas nunca com valor negativo (erro de digitação) — validado no cliente **e** no servidor |
| **Vendas anuladas ficam de fora** | O estorno (`cancel_sale`) já ajustou o caixa — incluir anuladas inflaria o fecho (mesmo critério de relatórios e KPIs) |
| **UPSERT por loja + dia** | Refazer o fecho do dia (ex.: digitou errado) **atualiza** a contagem e os snapshots, sem criar linha duplicada |
| **Fecho é gerencial** | Como compras e anulação: `is_manager_of_store` no servidor — a matriz de acesso no app (`canCloseCashRegisterProvider`) é só orientação de UX |
| **Servidor calcula, cliente só envia a contagem** | `p_store_id`, `p_day` (início do dia local em UTC) e `p_counted_cash_cents` — nenhum total calculado sai do dispositivo |
| **Critério único prévia/confirmação** | `aggregateCashClosingDay` (local) espelha exatamente o que a RPC calcula — a prévia e o fecho nunca divergem |

> **Verificação:** `sql_check.sh` (19.1–19.6) executa `close_cash_register`/`get_cash_closing_summary` como `app_user` e confere valores (total, esperado, abertura, UPSERT sem duplicar, funcionário rejeitado ao fechar); `sql_check_live.sh` (35/35) valida a RPC no live; testes de contrato cobrem o payload e o mapeamento (`cash_closing_supabase_data_source_test.dart`) e o use case (`close_cash_register_use_case_test.dart`).

---

## Documentos relacionados

- [Domínio](03-dominio.md) — casos de uso e exceções em detalhe.
- [Camada de dados](04-dados.md) — Unit of Work, schema e transações re-entrantes.
- [Apresentação](05-apresentacao.md) — como as telas consomem esses fluxos.
