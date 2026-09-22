# Guia do Utilizador — TAREQO ERP

Um guia simples e completo para usar o seu sistema de gestão do dia a dia: stock, vendas, clientes, dinheiro e relatórios — tudo em um só lugar.

> **Precisa resolver um problema?** Consulte o [Troubleshooting (resolução de problemas)](TROUBLESHOOTING.md).

---

## 1. Entrar no sistema

1. Abra o app **TAREQO** no seu telefone.
2. Digite o seu **e-mail** e a sua **senha**.
3. Toque em **Entrar**.

> **Primeira vez?** Toque em **Cadastrar**, preencha seus dados (nome, e-mail, senha, nome do negócio) e aguarde a **aprovação** do seu acesso — normalmente em até 24h. Só depois de aprovado você consegue entrar.

> **Esqueceu a senha?** Toque em **"Esqueceu sua senha?"** na tela de entrada e siga o link enviado para o seu e-mail.

### Autenticação em Dois Fatores (2FA)

Se a verificação em duas etapas estiver activada para a sua conta, depois de digitar a senha o app pede o **código do aplicativo autenticador** (ex.: Google Authenticator). Digite o código de 6 dígitos para entrar.

- Para activar ou gerir o 2FA: **Menu → Segurança → Autenticação em Dois Fatores**. Guarde a chave de reserva apresentada na configuração — ela permite entrar se você perder o telefone.
- No modo SaaS, o dono pode **exigir** o 2FA para operações de dinheiro: **Lojas → Ajustes**.

---

## 2. Tela inicial (Início)

A tela inicial mostra o resumo do seu negócio **na loja activa**, com uma **pílula de período** no topo (**Hoje** por padrão — toque para ver Semana, Mês ou Tudo) e o seletor da **loja activa**:

- **Vendas** do período (com comparação % com o período anterior)
- **Caixa** do período
- **A receber (fiado)** — com contador de clientes devedores
- **Atividade de hoje**: vendas, entradas de stock, pagamentos de fiado, despesas e alertas — toque num evento para ver os detalhes.

### Alertas de validade

- **Amarelo** = produto está **para vencer** (menos de 30 dias de validade).
- **Vermelho** = produto **já venceu** e ainda tem stock.
- Toque no alerta para ver qual é o produto e o lote envolvido.

### Ações rápidas

O botão **+** (canto da tela) abre o menu de ações: **Nova venda**, **Registar despesa**, **Adicionar produto**, **Adicionar cliente** e **Registar fiado**.

### Navegação

A barra inferior tem 4 abas: **Início**, **Vendas**, **Carteira** e **Menu**. Em telas largas (tablet/desktop) a navegação vira um painel lateral. Os módulos **Produtos**, **Crédito** e **Clientes** ficam dentro do **Menu** (a aba continua a ser destacada quando você os abre). Compras e Relatórios abrem a partir do Menu — só para **dono/gerente**.

---

## 3. Lojas — qual loja estou a ver?

O sistema pode ter **várias lojas** (ex.: Loja Central, Loja do Bairro). Cada loja tem o **seu próprio stock, vendas e caixa**.

- **Troca rápida:** toque na **pílula com o nome da loja** no topo do Início (e nos AppBars de Produtos, Vendas, Carteira e Clientes) e escolha a loja — tudo passa a mostrar os dados dela na hora.
- Também é possível trocar em **Menu → Lojas → aba Ajustes → seção "Loja activa"**.

> Com apenas uma loja, o seletor não aparece — não há o que escolher.

---

## 4. Produtos

### Cadastrar um produto

1. Abra **Menu → Produtos** → toque em **Novo produto**.
2. Preencha o **nome** e, se quiser, a **descrição**.
3. Informe o preço de **compra** e o preço de **venda**.
4. **Quantidade em stock**: informe quantas unidades você tem (ex.: `50`).
5. **Foto (opcional)**: toque na área de foto para **tirar uma foto** ou **escolher da galeria**. A foto aparece na lista de produtos e ajuda na hora do balcão.
6. **Validade (opcional)**: toque em **Definir validade** e escolha a data de vencimento. O sistema avisa quando estiver perto de vencer.
7. **Venda por peso?** Active **"Venda por peso (fração)"** para produtos vendidos por quilo/litro (ex.: arroz a granel, óleo) e escolha a unidade (kg, g, l, ml). O balcão passa a aceitar quantidades como `1,75 kg`.
8. **Código/PLU**: opcional — usado pelas balanças etiquetadoras (até 5 dígitos) e pelo leitor de código de barras.
9. Toque em **Adicionar produto**.

### Editar / desactivar um produto

- Toque num produto da lista → **Editar produto**.
- Pode alterar nome, preços, stock (**ajuste manual**), foto, validade e o status **Produto activo**.
- **Desactivar** (`Produto activo` desligado): o produto some do balcão e das compras, mas **permanece no histórico** com o stock guardado — dá para reactivar depois.
- Para remover a foto, toque em **Remover foto**.

> **Atenção:** Se a foto não enviar (ex.: sem internet), o produto é salvo mesmo assim — você verá um aviso e pode adicionar a foto depois pela edição.

> **Filtros:** no topo da lista de produtos, o ícone de filtro abre a busca por nome, status, tipo de stock, disponibilidade e faixa de preço.

---

## 5. Vendas (balcão)

1. Toque em **Nova venda** (aba **Vendas** ou no menu **+**).
2. Busque o produto ou **passe o código de barras** (câmera ou balança etiquetadora).
3. Ajuste a **quantidade** (produtos por peso aceitam decimais: `1,75`).
4. Escolha a **forma de pagamento**: Dinheiro, Cartão de débito, Cartão de crédito, M-Pesa, E-Mola ou Transferência.
5. Toque em **Confirmar venda**.

> ✓ O stock é abatido automaticamente — **primeiro o lote mais antigo** (FIFO), para nada vencer parado.

### Recibo e partilha

- Toque numa venda da lista para ver o **detalhe** (itens, total, forma de pagamento).
- **Partilhar recibo**: gere o recibo da venda e partilhe por **WhatsApp** ou outro app (também dá para partilhar como **imagem**).

### Anular uma venda (só dono/gerente)

Se uma venda foi feita por engano:

1. Abra o **detalhe** da venda → **Anular venda** → confirme.
2. O stock **volta aos lotes exactos** que foram vendidos (validade e custo preservados) e o caixa é **estornado**.
3. A venda **permanece no histórico** com a marca "Anulada" (para auditoria), mas **sai dos relatórios, indicadores e do resumo do dia**.

> No modo SaaS com MFA exigida, confirmar a venda (e outras operações de dinheiro) pode pedir o **código do autenticador** — é o servidor a proteger o seu caixa.

---

## 6. Compras (entrada de mercadoria) — dono/gerente

1. Abra **Menu → Compras** → toque em **Nova compra**.
2. Informe o **fornecedor**.
3. Adicione os produtos comprados e as quantidades.
4. **Validade (opcional)**: para produtos que vencem, escolha a data do lote.
5. Confirme a compra. O stock aumenta na hora e a despesa sai do caixa.

---

## 7. Clientes e Fiado (Crédito)

- **Clientes**: cadastre seus clientes com nome, telefone e e-mail (**Menu → Clientes**).
- **Registar fiado**: quando um cliente leva mercadoria para pagar depois, registe o valor e o vencimento (menu **+** → **Registar fiado**).
- Na aba **Carteira → Crédito** você vê:
  - **Pendentes** = quem ainda deve (total a receber).
  - **Quitadas** = histórico de quem já pagou.
- Quando o cliente pagar, toque em **Quitar dívida** — o dinheiro **entra no caixa automaticamente**.

---

## 8. Financeiro (Carteira)

A aba **Carteira** mostra as movimentações de dinheiro: **entradas**, **saídas** e o **saldo**.

- **Registar movimentação**: pelo **+** → **Registar despesa** (ou pela própria aba, para entradas).
- **Pendente**: deixe marcado se o valor ainda não foi recebido/pago — ele só conta no caixa **realizado** quando for recebido/pago.
- Nas pendências:
  - **Receber** (entradas pendentes): confirma que o dinheiro entrou → passa a contar no caixa.
  - **Pagar** (saídas pendentes — contas a pagar): confirma o pagamento → passa a contar no caixa.

### Fecho de caixa do dia (Z-report) — dono/gerente

Na **Carteira**, toque no card **Fecho de caixa** (ou na ação no topo):

1. O app mostra o **resumo do dia**: vendas totais, o **esperado na gaveta** (só dinheiro físico — cartão, M-Pesa, E-Mola e transferência não passam pela gaveta) e a abertura **por forma de pagamento**.
2. **Conte o dinheiro físico** da gaveta e digite o valor em **Dinheiro contado**.
3. O app mostra a **diferença** em tempo real: **Caixa confere**, **Sobra** ou **Falta**.
4. Toque em **Confirmar fecho**.

> Errou a contagem? Pode **refazer o fecho do dia** — o valor é actualizado, sem duplicar. Depois do fecho, o badge **"Caixa fechado!"** aparece na Carteira.

---

## 9. Relatórios — dono/gerente

Abra **Menu → Relatórios** e veja o desempenho do negócio:

- **Faturamento** (quanto vendeu no período)
- **Lucro bruto** e **margem**
- **Mais vendidos** (os produtos que mais saem)
- **Vendas por dia**

Use os filtros: **Hoje**, **7 dias**, **Este mês**, **Tudo**.

### Exportar e partilhar

Toque em **Exportar** → escolha **Exportar CSV** ou **Exportar PDF**. O relatório é gerado e você pode **partilhar** por WhatsApp, e-mail ou guardar no telefone.

---

## 10. Lojas e Funcionários (dono)

Abra **Menu → Lojas** — são 4 abas:

- **Lojas**: cadastre as suas lojas. Cada loja tem stock e caixa próprios.
- **Funcionários**: crie contas para quem trabalha com você e escolha o cargo:
  - **Gerente**: opera tudo, excepto gestão de lojas/funcionários.
  - **Funcionário**: só vende (não cadastra produtos, não vê relatórios, não faz compras, fecho de caixa nem anulações).
  - Desative um funcionário a qualquer momento — ele **perde o acesso na hora**.
- **Upgrades**: veja e peça a mudança de plano.
- **Ajustes**: troque a **Loja activa**, a **moeda** (MZN, BRL, USD, EUR), o **idioma** (Português/Inglês/Francês) e o **Exigir MFA para operações de dinheiro** (modo SaaS).

---

## 11. Segurança (todas as contas)

Em **Menu → Segurança** você encontra:

- **Autenticação em Dois Fatores**: activar/gerir o segundo fator (app autenticador). Com o 2FA activo, entrar e confirmar operações de dinheiro pede o código de 6 dígitos.
- **Trocar senha**: altere a sua senha (pede a senha actual para confirmar).
- **Autenticação Biométrica**: desbloqueie o app com impressão digital/rosto (se o dispositivo suportar).

---

## 12. Add-ons (dono)

O **Menu → Add-ons** mostra os extras activos no seu plano (geridos pelo administrador):

- **Factura Personalizada**: crie facturas com o layout da sua marca (logotipo, cores), numeração automática por loja e envio por **WhatsApp**.
- **Cotações / Orçamentos**: crie cotações com modelo personalizado e acompanhe o estado — **rascunho → enviada → aceite/rejeitada**. Exporta em PDF.
- **Relatórios Avançados**: KPIs financeiros, produtos por stock, fluxo de caixa e stock baixo.
- **Gestão de Funcionários**: registo de ponto (entrada/saída), **comissões calculadas sobre as vendas reais** de cada vendedor e metas mensais com progresso.
- **Transferências entre Lojas**: mova stock entre lojas do seu negócio — baixa na origem, entrada no destino, histórico rastreável.

---

## 13. Sincronização offline (modo SaaS)

Se a internet cair no momento de uma venda, compra, fiado, quitação ou anulação:

1. A operação é **guardada com segurança no aparelho** (o app avisa "salvo offline").
2. Assim que a conexão volta, o app **reenvia tudo automaticamente** — sem duplicar.
3. O **banner no Início** mostra quantas operações estão pendentes; toque em **Sincronizar** para reenviar na hora.

> Suas operações também podem pedir o **código 2FA** ao serem sincronizadas, se a MFA exigida estiver activa.

---

## 14. Dicas rápidas

- Confira sempre o **total** antes de confirmar uma venda.
- Atenção: Olhe os **alertas de validade** toda semana — produto vencido é prejuízo.
- Produtos com **foto** são muito mais fáceis de identificar no balcão.
- O app guarda a sua sessão com segurança — você só precisa entrar uma vez (e pode usar biometria para reabrir).
- Precisa de conexão para vender? No modo online sim — mas se a conexão cair, a venda **não se perde**: fica na fila offline (seção 13) e sobe sozinha.

---

## 15. Perguntas frequentes (FAQ)

**Esqueci a minha senha.**
Toque em **"Esqueceu sua senha?"** na tela de entrada e siga o link enviado por e-mail.

**Cadastrei-me mas não consigo entrar.**
Seu acesso precisa ser **aprovado** pelo administrador (até 24h). Confirme também que o e-mail/senha estão corretos. Se já passou de 24h, contacte o suporte.

**Pediu um código de 6 dígitos depois da senha.**
É a **Autenticação em Dois Fatores**. Abra o app autenticador e digite o código actual. Perdeu o telefone? Use a chave de reserva que guardou ao activar o 2FA.

**Um funcionário desactivado ainda entra?**
Não por muito tempo: o acesso é **derrubado na hora** quando o dono o desactiva. Se a sessão antiga ainda estiver aberta, feche e abra o app de novo.

**Vendi por engano. Como desfazer?**
Abra a venda → **Anular venda** (só dono/gerente). O stock volta aos lotes certos e o caixa é estornado. A venda fica no histórico marcada como **Anulada**.

**O meu stock não bate com o que contei.**
Confira se não houve vendas não anuladas, compras ou ajustes manuais de stock na edição do produto. Para corrigir uma divergência pequena, use o **ajuste de stock** na edição do produto (dono/gerente).

**A foto do produto não aparece.**
A foto pode não ter enviado por falta de internet no momento do cadastro (o produto é salvo mesmo assim). Abra o produto → **Editar produto** → adicione a foto de novo. Se continuar, veja o [Troubleshooting](TROUBLESHOOTING.md).

**O fecho de caixa mostra "Falta" de dinheiro.**
O "esperado na gaveta" considera **apenas vendas em dinheiro** — cartão, M-Pesa, E-Mola e transferência não entram. Confira se algum pagamento em dinheiro não foi registado ou se houve dinheiro retirado da gaveta.

**Posso ter mais de uma loja?**
Sim — o número de lojas depende do seu **plano** (veja em **Menu → Lojas → Upgrades**). Cada loja tem stock, vendas e caixa separados.

**As vendas anuladas contam nos relatórios?**
Não. Vendas anuladas ficam no histórico (auditoria), mas **saem** do faturamento, dos indicadores e do resumo do dia.

**Consigo exportar os relatórios?**
Sim — **Exportar CSV** ou **Exportar PDF** na tela de Relatórios, e partilhar por WhatsApp, e-mail etc.

**O que são Add-ons e como activo um?**
Add-ons são extras do seu plano (factura personalizada, cotações, relatórios avançados, gestão de funcionários, transferências). Eles são **activados pelo administrador** — para pedir, use **Menu → Lojas → Upgrades**. Depois de activos, aparecem em **Menu → Add-ons**.

**O app mudou de idioma/moeda do nada?**
A moeda e o idioma são definidos pelo dono em **Menu → Lojas → Ajustes** e valem para o negócio inteiro, na hora. Se mudou, foi uma alteração feita nas definições — pode voltar a alterar lá.

**A comissão do funcionário é calculada como?**
Pelas **vendas reais** dele (vendas registadas com a conta do funcionário activo), com a taxa definida pelo dono em **Menu → Add-ons → Gestão de Funcionários** (500 pontos = 5%).

---

*Dúvidas que não estão aqui? Veja o [Troubleshooting](TROUBLESHOOTING.md) ou fale com o dono do estabelecimento / suporte.*
