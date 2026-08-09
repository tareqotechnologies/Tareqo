# Decisões de Arquitetura — Dumbhanengue ERP

> Este documento registra o **"porquê"** das principais decisões técnicas do Dumbhanengue ERP: cada escolha de arquitetura, modelagem e segurança é justificada aqui. Para a visão geral e o catálogo completo, veja os documentos [01-visao-geral](01-visao-geral.md) a [11-multitenancy](11-multitenancy.md).

---

## Por que Clean Architecture?

Adotamos a Clean Architecture para o Dumbhanengue porque um ERP é, por natureza, um sistema de longa vida, com regras de negócio complexas e em constante evolução: módulos como estoque, vendas, compras, financeiro e relatórios precisam ser desenvolvidos, testados e substituídos de forma independente, sem que mudanças em um módulo provoquem efeitos colaterais nos demais.

Ao separar o código em três camadas — **domain** (entidades, contratos de repositórios e casos de uso, livres de qualquer dependência de framework), **data** (implementações concretas de fontes de dados remotas e locais, como Supabase e SQLite) e **presentation** (telas, widgets e estado via Riverpod) — a arquitetura garante que a regra de negócio fique no centro do sistema e não dependa de detalhes de infraestrutura. Isso traz quatro ganhos diretos:

1. **Testabilidade** — os casos de uso podem ser testados com mocks, sem servidor nem banco de dados;
2. **Substituibilidade** — a fonte de dados pode migrar de uma API REST para um banco local sem tocar no domínio;
3. **Manutenibilidade** — cada desenvolvedor trabalha em módulos isolados com contratos claros entre camadas;
4. **Escalabilidade da equipe** — as interfaces do domínio funcionam como "contratos" que permitem trabalho paralelo.

### Como cada pasta é utilizada

```
lib/
├── main.dart                    # Bootstrap: ProviderScope (Riverpod) + GetIt
├── app.dart                     # Widget raiz (MaterialApp, tema, locale/moeda do tenant)
│
├── core/                        # Preocupações transversais (não pertencem a nenhuma camada)
│   ├── config/                  # Configuração (Supabase, preferências do tenant)
│   ├── database/                # Abertura do SQLite, schema e transações (Unit of Work)
│   ├── di/                      # Service Locator (GetIt) — registro central de dependências
│   ├── i18n/                    # Chaves de tradução e helpers de localização
│   ├── security/                # Armazenamento seguro (Keychain/Keystore)
│   ├── theme/                   # Tema Material 3 da aplicação
│   └── utils/                   # Helpers genéricos (formatação de moeda/data, ids...)
│
├── domain/                      # NÚCLEO: regras de negócio puras, sem dependências externas
│   ├── entities/                # Entidades imutáveis (Product, Sale, Tenant...) via Freezed
│   ├── repositories/            # Contratos abstratos (interfaces) de persistência (ex.: IProductRepository)
│   └── usecases/                # Casos de uso — orquestram as regras de negócio
│
├── data/                        # Implementações concretas do que o domínio define
│   ├── datasources/
│   │   ├── remote/              # Fontes de dados remotas (Supabase/REST)
│   │   └── local/               # Fontes de dados locais (SQLite, memória)
│   ├── models/                  # DTOs serializáveis — criados apenas quando o formato da API diverge do domínio
│   ├── repositories/            # Implementações das interfaces do domínio
│   └── services/                # Serviços de integração (contas de funcionário, processadores atômicos)
│
└── presentation/                # Tudo que o usuário vê e interage
    ├── controllers/             # Estado: providers/notifiers do Riverpod
    ├── screens/                 # Telas por módulo (auth, dashboard, produtos, vendas, financeiro...)
    └── widgets/                 # Widgets compartilhados (KpiCard, EmptyState, StatusChip, AppSheet...)
```

> **Regra de Dependência:** o fluxo de dependências aponta sempre para dentro. `presentation → domain` (via contratos), `data → domain` (implementa contratos), e o `domain` não conhece nenhuma das outras camadas.

## Por que contratos (interfaces abstratas) no domínio?

No domínio, `IProductRepository` é declarada como uma **interface abstrata** — apenas a assinatura dos métodos (`getAll`, `add`) — e **não** como uma classe concreta. Isso porque:

1. **Inversão de Dependência (DIP):** o domínio não pode conhecer detalhes de infraestrutura. A classe concreta (ex.: `ProductRepositoryImpl`, usando SQLite ou Supabase) vive na camada `data` e *implementa* o contrato. A regra de negócio depende de uma abstração, nunca de uma implementação.
2. **Desacoplamento e substituibilidade:** a fonte de dados pode trocar de API REST para banco local (ou vice-versa) sem alterar uma linha do domínio ou da UI — basta criar outra classe que implemente o mesmo contrato.
3. **Testabilidade:** nos testes de casos de uso, injetamos um *mock/fake* do `IProductRepository` (sem servidor nem banco), isolando a lógica de negócio e tornando os testes rápidos e determinísticos.
4. **Contrato de integração:** a interface funciona como um acordo entre camadas/equipes — a `data` sabe exatamente o que implementar, a `presentation` sabe exatamente o que consumir, permitindo trabalho paralelo.

Diferente da herança (em que a classe concreta "é um" contrato), a interface declara apenas **o que** o sistema precisa, deixando o **como** para a camada de dados.

## Por que a validação de preço vive no Use Case (e não na UI)?

O `AddProductUseCase` valida que `salePrice >= purchasePrice` antes de persistir. Essa regra foi colocada deliberadamente no caso de uso — e **não** na tela de cadastro:

1. **A regra de negócio pertence ao domínio.** A UI é apenas apresentação. Se a validação vivesse na tela, cada cliente (mobile, web, desktop) precisaria reimplementá-la — e qualquer mudança na regra exigiria alterar todas as telas.
2. **Centralização e consistência.** Todo ponto de entrada (formulário, importação, futura API) passa pelo mesmo caso de uso. Evita que um produto inválido entre no sistema por uma rota que não validou.
3. **Integridade do dado.** A validação acontece o mais perto possível do dado, garantindo que o estado do sistema nunca contenha um produto com preço de venda menor que o de compra — independentemente de onde o dado veio.
4. **Testabilidade.** A regra é testada isoladamente com testes unitários (caso de uso + fake do repositório), sem UI e sem widgets — rápidos e determinísticos.
5. **Reutilização entre plataformas.** O mesmo caso de uso serve à UI Flutter, a scripts de migração e a uma futura API REST.

Na prática, a UI fica **fina**: ela apenas captura a exceção lançada pelo caso de uso e exibe a mensagem ao usuário.

## Por que começar com uma lista em memória e depois migrar para SQLite?

O `ProductRepositoryImpl` começou com um datasource em memória — escolha deliberada:

1. **Foco nas regras de negócio primeiro.** Sem setup de banco, migrações ou drivers, validamos a arquitetura e a lógica de domínio antes de investir em infraestrutura.
2. **Iteração rápida de ponta a ponta.** UI → use case → repositório → datasource já funcionam no primeiro dia, permitindo demonstrar o fluxo completo do ERP.
3. **Sem compromisso prematuro.** Só decidimos entre SQLite, Hive, drift ou API quando conhecemos os requisitos reais (consultas, concorrência, sincronização) — evitando a *premature commitment* a uma tecnologia.
4. **Testes determinísticos.** Dados em memória tornam os testes rápidos, previsíveis e sem dependência de ambiente.

A migração para SQLite foi concluída seguindo a **Inversão de Dependência**: foram criados `*SqliteDataSourceImpl` implementando **os mesmos contratos** (SQL parametrizado com `package:sqlite3`), e o `ServiceLocator` trocou os registros — **nenhuma alteração em domain, casos de uso, repositórios ou UI**.

```dart
// lib/core/di/service_locator.dart — persistência ativa
final database = await AppDatabase.openAppDatabase();
if (database != null) {
  _registerSqlitePersistence(database);   // SQLite (plataformas nativas)
} else {
  _registerInMemoryPersistence();         // fallback: web / falha da lib nativa
}
```

Detalhes da implementação:

- **`lib/core/database/app_database.dart`** — abre `dumbhanengue.db` em `getApplicationDocumentsDirectory()`, cria o schema (`CREATE TABLE IF NOT EXISTS` com `CHECK` de não-negatividade como salvaguarda final), não semeia dados (o banco nasce vazio — só dados reais) e expõe `runInTransaction` (BEGIN/COMMIT/ROLLBACK) para gravações atômicas (ex.: venda + itens).
- **Vendas** são persistidas em tabelas normalizadas (`sales` + `sale_items`) numa **única transação**.
- **Enums** são persistidos pelo nome; **datas** como epoch millis; **booleanos** como 0/1.
- **Web**: o sqlite3 nativo não roda no navegador (o `dart:ffi` não existe lá), então `AppDatabase` usa **import condicional** e o app cai automaticamente para os datasources em memória (mesmos contratos — a UI continua igual).
- **Testes**: na VM Windows o próprio `package:sqlite3` já cai para a `winsqlite3.dll` do sistema, então os testes rodam sem setup manual.

## Por que Riverpod para o gerenciamento de estado?

A camada de apresentação usa **Riverpod** (`Notifier`/`FutureProvider`/`StreamProvider`) para gerenciar o estado:

1. **Reatividade declarativa.** A tela declara o que observar (`ref.watch(productsProvider)`) e o Riverpod reconstroi apenas os widgets afetados — sem `setState` manual, `InheritedWidget` ou streams manuais.
2. **AsyncValue embutido.** Os providers assíncronos expõem o estado como `AsyncValue` (`loading` / `error` / `data`), tornando o tratamento de carregamento, erro e retry declarativo e consistente em todas as telas.
3. **Composição tipada de providers.** Providers podem depender de outros providers, formando um grafo tipado, com escopo controlado via `ProviderScope` e *auto-dispose* quando desejado.
4. **Testabilidade.** Em testes, basta sobrescrever os providers (`overrideWithValue`/`overrideWith`) — sem tocar no GetIt nem em datasources.

### Como o Riverpod se comunica com o domínio sem violar as regras de dependência

O fluxo de dependências aponta **sempre para dentro**:

```
ProductListScreen (widget)
      ↓ ref.watch
productsProvider (provider)
      ↓ ref.read
getProductsUseCaseProvider → GetProductsUseCase (domínio)
      ↓
IProductRepository (contrato do domínio)
      ↓ (implementação injetada via GetIt no bootstrap)
ProductRepositoryImpl → ProductLocalDataSource (camada data)
```

A `presentation` conhece **apenas abstrações do domínio** — entidade, caso de uso e contrato — nunca datasources, SQLite ou implementações concretas. O GetIt apenas entrega as instâncias; quem decide as dependências é o grafo de providers. Por isso, trocar a persistência ou a implementação do repositório **não altera nenhuma linha da apresentação**.

## Por que a venda armazena o preço no momento da venda (snapshot)?

Cada `SaleItem` guarda o `productName` e o `unitPrice` **na data da venda**, além do `productId`. Não basta referenciar apenas o produto:

1. **Variação de preço histórica.** O preço de um produto muda (promoções, reajustes, inflação). Se a venda referenciasse só o produto, um relatório futuro mostraria o preço **atual**, não o que foi cobrado na época — distorcendo receitas, margens e impostos.
2. **Integridade fiscal e contábil.** A venda é um registro legal: o total cobrado não pode mudar retroativamente por causa de uma alteração na tabela de preços. Guardar `totalAmount` + os itens congelados garante isso.
3. **Relatórios e auditoria.** Análises históricas ("quanto vendi de caneta em março?", "qual foi a margem naquele período?") exigem o preço vigente na data da venda.
4. **Evolução do catálogo.** Produtos são renomeados, descontinuados ou têm o id reutilizado. O snapshot (nome + preço) preserva o contexto real da transação.
5. **Padrão de mercado.** É o comportamento clássico de ERPs e PDVs: *line items* são a "fotografia" do item no instante da venda, com referência (`productId`) apenas para rastreabilidade.

**Conclusão:** guardamos `productId` para rastreabilidade, mas os valores exibidos e somados (`unitPrice`, `totalAmount`) são os do momento da venda — o histórico nunca é corrompido por mudanças futuras no catálogo.

## Como garantir que o estoque nunca fique negativo (ProcessSaleUseCase)

O `ProcessSaleUseCase` integra Vendas, Estoque e Financeiro com uma **ordem deliberada de operações** para garantir integridade:

1. **Validação da venda** — rejeita venda sem itens e total divergente de `Σ(quantidade × preço unitário)`, **sem persistir nada**;
2. **Pré-validação de estoque** — antes de qualquer mutação, confere se **todos** os itens da venda têm estoque suficiente. Se algum faltar, lança exceção **sem persistir nada** — nunca sobra uma venda "órfã";
3. **Registro da venda** — `ISaleRepository.registerSale`;
4. **Baixa do estoque** — para cada item, decremento que **revalida o estoque internamente** (defesa contra chamadas diretas) antes de persistir o valor absoluto;
5. **Entrada no caixa** — registra a `FinancialTransaction` de entrada (categoria "Vendas", `paid`).

Tudo roda dentro de um **`IUnitOfWork`** (unit-of-work): venda + itens, baixa de estoque e entrada no caixa são gravados em **uma única transação SQLite** — ou tudo é persistido, ou nada. O `BEGIN IMMEDIATE` adquire a trava de escrita **antes** da pré-validação de estoque, fechando a janela de concorrência (TOCTOU). Em memória (web) o unit of work é um no-op.

O `UpdateProductStockUseCase` é a **única porta de entrada** para mutar estoque, e o repositório recebe um **valor absoluto** (não um delta) — duas camadas de proteção: o use case nunca calcula um estoque negativo e o repositório apenas persiste. O `CHECK (stock_quantity >= 0)` do schema permanece como salvaguarda final.

### Como as camadas se comunicam sem acoplamento

O `ProcessSaleUseCase` depende **apenas de abstrações**: o contrato `ISaleRepository` e o `UpdateProductStockUseCase` (que depende do contrato `IProductRepository`). Nenhum deles conhece datasources ou SQLite. A composição acontece na **fiação** (ServiceLocator/GetIt), nunca dentro das regras de negócio.

## Por que quantidades em MILÉSIMOS inteiros (W11)?

A W4 eliminou o `double` do dinheiro (centavos inteiros); a W11 faz o mesmo com as **quantidades**: `1000` = 1 unidade/kg, tudo `int`.

1. **Mesma filosofia dos centavos.** Balanças e PDVs por peso produzem frações (1,75 kg); `double` acumula erros de arredondamento em somas longas (carrinho, relatórios, baixas FIFO). Milésimos inteiros tornam a aritmética **exata** em todas as camadas.
2. **Paridade Dart ↔ SQL.** O contrato é um só: `quantidade × preço ~/ 1000` (divisão inteira) no Dart **e** nas RPCs do servidor — total do carrinho, caixa e relatórios batem byte a byte.
3. **Borda de conversão concentrada.** `Quantity` (`lib/core/utils/quantity.dart`) concentra conversões e formatação ("1,75 kg"); o resto do app só enxerga `int`.

## Por que FIFO por lotes com validade?

Perecíveis e validade são o dia a dia de uma mercearia: o estoque precisa sair na ordem certa, ou o comerciante vende mercadoria vencida (prejuízo + risco sanitário).

1. **O lote é a unidade de rastreio.** Cada entrada de mercadoria cria um `StockLot` (quantidade inicial/atual, validade, custo de aquisição) — dá para saber quanto sobrou de cada entrada e qual vence antes.
2. **Baixa FIFO determinística.** O `FifoStockUseCase` (e o `process_sale` no servidor) consome lotes em ordem `validade ASC → entrada ASC → id`; o excedente passa ao lote seguinte; a soma dos lotes é **pré-validada antes de qualquer mutação** (sem baixa parcial).
3. **Invariante `stock = Σ lotes`.** O `products.stock_quantity` é sempre a soma dos lotes ativos — verificada por teste (`sql_check.sh`) e pela query read-only do `sql_check_live.sh`. A migração W11 cria um lote inicial (`lot-mig-…`) para cada produto com estoque, então a invariante vale desde o primeiro dia.
4. **Alertas de validade.** O dashboard mostra **vermelho** (lote vencido com estoque) e **amarelo** (vence em < 30 dias) — ação preventiva antes do prejuízo.

## Por que o formato de balança `20PPPPPWWWWW`?

É o padrão das balanças etiquetadoras de mercado: prefixo `20`, 5 dígitos do produto (PLU) e 5 do valor da pesagem.

1. **Zero configuração no PDV.** A leitura (scanner USB ou câmera) cai no campo de código; o `ScaleBarcode` identifica o padrão, extrai o PLU e **deriva a fração** `peso = valor ÷ preço` — nunca cobra a mais, mesmo quando a balança grava valor monetário.
2. **Segurança do fallback.** Só é tratado como balança quando o produto existe e é `vendaPorFracao`; EAN-12 que comece com `20` (códigos normais) cai no caminho comum. PLUs são normalizados (zeros à esquerda) na busca (`123` ≡ `00123`).
3. **Milésimos de ponta a ponta.** A fração entra no carrinho em milésimos — total, baixa FIFO e relatórios usam a mesma aritmética inteira.

## Por que a escala tipográfica segue Apple HIG e Material (34/28/22/20/17/15/13/11)?

A `TextTheme` do app não é um conjunto de tamanhos arbitrários: ela segue uma **escala modular** inspirada no Human Interface Guidelines (Apple) e no Material Design (Google), adaptada às necessidades de um ERP/PDV de balcão — onde tablets ficam a poucos centímetros dos olhos e a hierarquia precisa ser lida de relance.

1. **Hierarquia por proporção, não por excesso de tamanhos.** A escala (34/28/22/20/17/15/13/11 sp) cria níveis claros — Large Title 34 (login, boas-vindas, fechos de caixa consolidados), Título 1 28 (cabeçalhos de páginas/seções), Título 2 22 (cartões de resumo, cabeçalhos de modais), Título 3 20 (subtítulos) — e o corpo usa poucos tamanhos (17/15/13) com **variação de peso** (w400 para texto, w600 para valores e rótulos importantes), a regra de ouro dos ecossistemas Apple/Google. Em vez de inflar a quantidade de tamanhos, a hierarquia vem do contraste de pesos.
2. **Alinhamento numérico (`tabularFigures`).** Preços (MZN) e quantidades (kg/unidades) aparecem em colunas — relatórios, carrinho, chips de estado. O `FontFeature.tabularFigures()` dá a **todos os dígitos a mesma largura** (largura tabular), fazendo as colunas de valores alinharem dígito a dígito, como em planilhas. É aplicado aos estilos **numéricos** (`displaySmall`, `headlineMedium/Small`, `titleLarge/Medium`, `bodyLarge/Medium/Small`) e deliberadamente **não** aos rótulos (`titleSmall`, `labelLarge/Medium/Small`), que não carregam números.
3. **Legibilidade em qualquer ecrã.** `sp` é *scale-independent pixel*: respeita a escala de acessibilidade de texto do SO. A suíte valida até fonte 2.0× sem overflow — tanto no tablet de balcão quanto no telemóvel.
4. **Escala travada por teste.** O `typography_scale_test.dart` audita tamanho, peso e a presença/ausência de `tabularFigures` em cada papel tipográfico (claro e escuro) — qualquer regressão na escala quebra o teste deliberadamente.

## Por que uma entidade financeira separada da venda?

O `FinancialTransaction` (entrada/saída de caixa) é um conceito **financeiro**; a `Sale` é um evento **operacional**. Separar os dois é deliberado:

1. **Nem toda entrada vem de venda, nem toda saída é mercadoria.** Empréstimos, aportes, juros e devoluções são entradas; aluguel, energia, salários, impostos e manutenção são saídas que **não têm item, estoque ou produto associado**. Misturá-los na entidade `Sale` forçaria campos vazios e regras incoerentes.
2. **Despesas fixas têm natureza própria.** São periódicas, recorrentes e categorizáveis. A entidade própria (`description`, `category`, `date`) permite responder *"quanto gastei com energia este ano?"* sem contaminar o modelo de venda.
3. **Fluxo de caixa real.** O saldo correto = **entradas (vendas + outras) − saídas (fixas + variáveis)**. Com uma única entidade financeira, o `GetCashFlowUseCase` agrega tudo em um período — a `Sale` continua servindo para relatórios operacionais.
4. **Responsabilidade única.** `Sale` = operação (itens, estoque, pagamento); `FinancialTransaction` = dinheiro (direção, categoria, valor). Cada um evolui com seus próprios requisitos sem quebrar o outro.
5. **Auditoria e rastreabilidade.** Cada movimento tem identidade, categoria e data próprias, facilitando conciliação e relatórios por categoria.

**Resumo:** a venda registra *o que aconteceu* (itens e estoque); a transação financeira registra *o dinheiro que entrou ou saiu*. Dois modelos, duas responsabilidades, um fluxo de caixa preciso.

## Controle de crédito ("fiado") e o capital de giro

O controle de crédito responde à pergunta mais importante do pequeno comerciante: **quem me deve, quanto e quando vence?**

### Estrutura

- **`Debt` (dívida/fiado)** — registro de promessa de pagamento com `personName`, `amount`, `dueDate` e `isCustomerDebt`:
  - `isCustomerDebt: true` → **a receber** (o cliente deve ao comerciante);
  - `isCustomerDebt: false` → **a pagar** (o comerciante deve ao fornecedor).
- **`GetPendingDebtsUseCase`** — filtra e lista apenas o que está **a receber de clientes**, respondendo *"quanto tenho para receber e de quem"* de forma imediata.
- **`FinancialTransaction.status`** (`paid`/`pending`) — separa o dinheiro que **já entrou no caixa** daquele que é apenas **expectativa de entrada**. Ao registrar um fiado, o `AddDebtUseCase` cria a pendência vinculada na hora (`debtId`): entrada pendente para contas a receber e saída pendente para contas a pagar. Pendências também podem ser criadas na tela de Financeiro (switch "Pendente (fiado)"); quando recebidas, são marcadas como `paid` pelo botão **"Receber"** (ou pela baixa do fiado) — o caixa realizado passa a contar a entrada na **data do recebimento**.
- **`Debt.isPaid`** — estado da baixa: quando o cliente paga, o `SettleDebtUseCase` marca a dívida como `isPaid: true`. Se a dívida tiver uma transação **pendente vinculada**, a baixa marca a **mesma** transação como paga; caso contrário, registra a entrada no caixa. Nunca há duplicata.

### Impacto no capital de giro

Valor a receber é **capital imobilizado**: a mercadoria já saiu (e foi paga ao fornecedor), mas o dinheiro ainda não voltou. Com essa estrutura o comerciante consegue:

1. **Saber exatamente quanto está "parado" nas mãos dos clientes** — soma das dívidas a receber — e confrontar com o que tem no caixa, evitando superestimar o fluxo de caixa;
2. **Planejar compras sem depender do fiado** — se o capital de giro está imobilizado, o comerciante pode adiar compras ou negociar prazos com fornecedores;
3. **Priorizar cobranças** — `dueDate` permite listar o que vence primeiro e identificar inadimplentes;
4. **Calcular o ciclo financeiro** — o intervalo entre comprar (a pagar), vender (fiado) e receber (a receber) define quanto capital de giro é necessário.

## Por que a autenticação é o primeiro passo do modelo SaaS?

1. **Multi-tenant desde o primeiro dia.** Cada comerciante é um *tenant*: sem login não há como separar os dados de cada cliente no mesmo banco. A autenticação fornece a identidade que isola os dados.
2. **Segurança imposta no banco (RLS).** O Supabase usa o JWT do usuário em *Row Level Security* do Postgres: a regra de isolamento (`auth.uid() = user_id`) é aplicada pelo banco, não apenas pela UI — mesmo que um bug na UI vaze dados, o banco os filtra.
3. **Modelo de receita.** O SaaS cobra por assinatura/plano; a autenticação identifica quem paga, qual plano e quais limites aplicar.
4. **Onboarding e retenção.** Cadastro → login → dados próprios do usuário; sessão persistente melhora a experiência e reduz atrito diário.

### Como a sessão permanece ativa (persistência de sessão)

1. **Armazenamento seguro.** O `supabase_flutter` persiste a sessão automaticamente: `flutter_secure_storage` (Android/iOS) e `localStorage` (web) — sem código extra.
2. **Restauração no boot.** Ao abrir o app, o stream de auth reemite a sessão salva. O `AuthGate` reage: sessão restaurada → dashboard direto, sem novo login.
3. **Renovação automática do JWT.** O gotrue renova o access token com o refresh token antes de expirar.
4. **Reatividade.** Login/logout emitem eventos no mesmo stream; a navegação e qualquer estado dependente da sessão reagem automaticamente.

As credenciais do projeto de desenvolvimento já estão embutidas em `SupabaseConfig` (a anon key é pública por design no Supabase — a segurança real vem do RLS; **nunca** coloque a service role key no cliente). Para apontar para outro projeto (ex.: produção):

```bash
flutter run --dart-define=SUPABASE_URL=https://seu-projeto.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Moeda e idioma do tenant (apresentação)

O dono escolhe a **moeda** (BRL, USD, EUR, MZN — **padrão MZN**, metical, mercado-alvo Moçambique) e o **idioma** (pt, en) no onboarding e pode alterar em **Lojas → Ajustes**. As preferências vivem na tabela `tenants` (`currency_code`, `language`) e propagam para o app inteiro: o locale do `MaterialApp` e a formatação de moeda (`Formatters`) seguem o `tenantSettingsProvider` — funcionários herdam a escolha do dono. A gravação passa pela RPC `update_tenant_settings` (SECURITY DEFINER, guarda `is_tenant_owner`): a política RLS `tenants_update` só permite o super admin alterar a linha do tenant, então o UPDATE direto do dono era bloqueado (ajustes que não salvavam) — a RPC limita o UPDATE às colunas de apresentação.

## Armazenamento seguro: por que não usar `shared_preferences` para dados sensíveis?

O `SecureStorageService` encapsula a persistência **criptografada** de tokens de acesso, tokens de renovação e chaves de API. Nunca se usa `shared_preferences` para esse tipo de dado.

### Diferença técnica entre armazenamento comum e seguro

| Aspecto | `shared_preferences` (comum) | `flutter_secure_storage` (seguro) |
| ------- | ---------------------------- | --------------------------------- |
| **Local físico** | Arquivo de preferências em texto plano (XML/JSON/plist) | **Keychain** (iOS/macOS) e **Android Keystore** |
| **Criptografia** | Nenhuma — o valor fica legível em disco | Dados criptografados; no Android, a chave (AES-GCM) é gerada e guardada dentro do Keystore, amarrada ao hardware |
| **Acesso** | Qualquer processo com permissão de leitura no arquivo | Protegido pelo SO: só o app autenticado acessa; no iOS o acesso pode exigir biometria |
| **Backup/extração** | Valores em texto claro podem ser lidos em backups, root/JB ou extração de APK | Criptografados de ponta a ponta; no iOS ficam no enclave seguro do hardware |
| **Caso de uso ideal** | Preferências de UI (tema, idioma, filtros) — nada sensível | Tokens de sessão, refresh tokens, chaves de API, segredos |

### Por que isso é vital para proteger a conta do comerciante

1. **O token é a senha.** Com o token de sessão em mãos, um atacante acessa a conta como se fosse o comerciante. Guardar esse token em texto claro transforma um backup, um dispositivo com root ou um APK extraído numa porta de entrada para a conta e os dados financeiros.
2. **A criptografia está amarrada ao dispositivo.** No Android, a chave mestra vive no **Android Keystore** (hardware-backed, TEE); no iOS, no **Keychain** com o enclave seguro. Mesmo que o arquivo seja copiado, sem a chave do hardware o conteúdo é inútil.
3. **Custo de ataque alto.** Roubar um token protegido exige comprometer o SO/hardware — inviável em escala.
4. **Acesso condicionado ao usuário (iOS).** O Keychain pode exigir Face ID/Touch ID — mais uma barreira.

### Como o serviço foi desenhado

- **Backend abstraído** (`SecureStorageBackend`): a implementação real usa o Keychain/Keystore via `flutter_secure_storage`; nos testes usamos um backend em memória.
- **Chaves centralizadas** em `SecureStorageKeys`: evita erros de digitação e permite auditar exatamente o que é tratado como sensível.

### Limite de responsabilidade (importante para não duplicar a sessão)

A **sessão do Supabase** já é persistida internamente pelo `supabase_flutter` na própria instância do `flutter_secure_storage`. Por isso o `SecureStorageService` **não** deve gravar esses tokens — ele existe para **segredos do aplicativo**: chaves de API de serviços externos, segredos de configuração e credenciais da camada data/presentation. Manter essa fronteira evita dois lugares gravando a sessão.

### Ressalva de plataforma (precisão técnica)

- **Android/iOS (mobile):** hardware-backed — Android Keystore (AES-GCM, chave na TEE) e Keychain com enclave seguro. É onde dados críticos devem residir.
- **Windows:** DPAPI (vinculado à conta do usuário do SO) e **Linux:** libsecret. Proteção razoável, sem enclave dedicado.
- **Web:** mais fraco — a implementação web guarda a chave de criptografia no `localStorage` (não é hardware-backed). **Para segredos críticos, priorize mobile.**

## Dependências iniciais

| Pacote | Papel | Camada |
| ------ | ----- | ------ |
| `flutter_riverpod` | Gerenciamento de estado reativo | presentation |
| `flutter_localizations` + `intl` | Internacionalização (pt/en) e formatação | presentation/core |
| `freezed` + `json_serializable` | Modelos imutáveis e serialização JSON (geração de código) | domain/data |
| `get_it` | Injeção de dependência (Service Locator) | core |
| `supabase_flutter` | Autenticação SaaS, banco de dados e realtime | data |
| `flutter_secure_storage` | Persistência criptografada de tokens e chaves | core |
| `sqlite3` + `sqlite3_flutter_libs` | Persistência local relacional | data |
| `mobile_scanner` | Leitura de código de barras por câmera no PDV (balanças/PLU, W11) | presentation |
| `path_provider` | Caminho do diretório de documentos | data/core |

### Geração de código (Freezed)

Sempre que criar ou alterar uma classe anotada com `@freezed`, gere os arquivos:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Camada de apresentação (resumo)

O app possui navegação adaptativa (`AppShell` com `NavigationRail` em telas largas e `NavigationBar` em telas estreitas) e módulos funcionais:

1. **Início** — dashboard com KPIs (vendas, saldo em caixa por período, fiado a receber, estoque), ações rápidas, vendas recentes e alerta de estoque baixo;
2. **Produtos** — busca, listagem com preços/estoque e cadastro via bottom sheet;
3. **Vendas** — histórico e fluxo de **nova venda** (carrinho + forma de pagamento → baixa de estoque + entrada no caixa, atomicamente);
4. **Financeiro** — fluxo de caixa por período (hoje/7 dias/mês/tudo) com entradas, saídas e saldo, movimentações e recebimento de pendências;
5. **Crédito (fiado)** — total a receber, dívidas por vencimento, registro de fiado e **baixa** com histórico de quitações;
6. **Lojas** — gestão do tenant: lojas, funcionários, plano e **Ajustes** (idioma + moeda do dono);
7. **Compras** — entrada de mercadorias com atualização de estoque e saída no caixa.

O visual é minimalista (Material 3): superfícies neutras, cards com borda sutil, cantos arredondados e formatação monetária localizada (`Formatters`).
