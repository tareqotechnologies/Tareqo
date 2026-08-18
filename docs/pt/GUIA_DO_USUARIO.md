# Guia do Usuário — Dumbhanengue ERP

Um guia simples e completo para usar o seu sistema de gestão do dia a dia: estoque, vendas, clientes, dinheiro e relatórios — tudo em um só lugar.

> **Precisa resolver um problema?** Consulte o [Troubleshooting (resolução de problemas)](TROUBLESHOOTING.md).

---

## 1. Entrar no sistema

1. Abra o app **Dumbhanengue** no seu telefone.
2. Digite o seu **e-mail** e a sua **senha**.
3. Toque em **Entrar**.

> **Primeira vez?** Toque em **"Não tenho conta — cadastrar"**, preencha seus dados (nome, e-mail, senha, nome do negócio) e aguarde a **aprovação** do seu acesso — normalmente em até 24h. Só depois de aprovado você consegue entrar.

---

## 2. Tela inicial (Início)

A tela inicial mostra o resumo do seu negócio **na loja ativa**:

- **Total de vendas** do dia
- **Saldo em caixa**
- **A receber (fiado)**
- **Estoque em produtos**
- **Alertas** Atenção: (validade) — veja abaixo

### Alertas de validade
- ◔ **Amarelo** = produto está **para vencer** (menos de 30 dias de validade).
- ● **Vermelho** = produto **já venceu** e ainda tem estoque.
- Toque no alerta para ver qual é o produto e o lote envolvido.

### Ações rápidas
Os botões principais ficam na tela inicial: **Nova venda**, **Adicionar produto**, **Registrar transação** e **Registrar fiado**.

### Módulos
Use a barra inferior (ou os cards) para navegar: **Início**, **Vendas**, **Produtos**, **Financeiro**, **Crédito**, **Clientes**, **Lojas**, **Relatórios**. Alguns módulos só aparecem para **dono/gerente** (ex.: Compras e Relatórios).

---

## 3. Lojas — qual loja estou vendo?

O sistema pode ter **várias lojas** (ex.: Loja Central, Loja do Bairro). Cada loja tem o **seu próprio estoque, vendas e caixa**.

- O **Início** mostra o nome da loja ativa.
- Para trocar: **Lojas** → aba **Ajustes** → seção **"Loja ativa"** → toque na loja desejada.
- Tudo (estoque, vendas, financeiro, relatórios) passa a mostrar os dados da loja escolhida.

> Com apenas uma loja, essa seção não aparece — não há o que escolher.

---

## 4. Produtos

### Cadastrar um produto
1. Abra **Produtos** → toque em **Novo produto**.
2. Preencha o **nome** e, se quiser, a **descrição**.
3. Informe o preço de **compra** e o preço de **venda**.
4. **Quantidade em estoque**: informe quantas unidades você tem (ex.: `50`).
5. **Foto (opcional)**: toque na área de foto para **tirar uma foto** ou **escolher da galeria**. A foto aparece na lista de produtos e ajuda na hora do PDV.
6. **Validade (opcional)**: toque em **Definir validade** e escolha a data de vencimento. O sistema avisa quando estiver perto de vencer.
7. **Venda por peso?** Ative **"Venda por peso (fração)"** para produtos vendidos por quilo/litro (ex.: arroz a granel, óleo) e escolha a unidade (kg, g, l, ml). O caixa passa a aceitar quantidades como `1,75 kg`.
8. **Código de barras (PLU)**: opcional — usado pelas balanças etiquetadoras (formato `20PPPPPWWWWW`).
9. Toque em **Adicionar produto**.

### Editar / desativar um produto
- Toque num produto da lista → **Editar produto**.
- Pode alterar nome, preços, estoque (**ajuste manual**), foto, validade e o status **Produto ativo**.
- **Desativar** (`Produto ativo` desligado): o produto some do PDV e das compras, mas **permanece no histórico** com o estoque guardado — dá para reativar depois.
- Para remover a foto, toque em **Remover foto**.

> **Atenção:** Se a foto não enviar (ex.: sem internet), o produto é salvo mesmo assim — você verá um aviso e pode adicionar a foto depois pela edição.

---

## 5. Vendas (PDV)

1. Toque em **Nova venda**.
2. Busque o produto ou **passe o código de barras** (câmera ou balança etiquetadora).
3. Ajuste a **quantidade** (produtos por peso aceitam decimais: `1,75`).
4. Escolha a **forma de pagamento**: Dinheiro, Cartão de débito, Cartão de crédito, M-Pesa, E-Mola ou Transferência.
5. Toque em **Confirmar venda**.

> ✓ O estoque é abatido automaticamente — **primeiro o lote mais antigo** (FIFO), para nada vencer parado.

### Recibo e partilha
- Toque numa venda da lista para ver o **detalhe** (itens, total, forma de pagamento).
- **Partilhar recibo**: gere o recibo da venda e partilhe por **WhatsApp** ou outro app (também dá para partilhar como **imagem**).

### Anular uma venda (só dono/gerente)
Se uma venda foi feita por engano:
1. Abra o **detalhe** da venda → **Anular venda** → confirme.
2. O estoque **volta aos lotes exatos** que foram vendidos (validade e custo preservados) e o caixa é **estornado**.
3. A venda **permanece no histórico** com a marca "Anulada" (para auditoria), mas **sai dos relatórios, KPIs e do resumo do dia**.

---

## 6. Compras (entrada de mercadoria) — dono/gerente

1. Toque em **Nova compra**.
2. Informe o **fornecedor**.
3. Adicione os produtos comprados e as quantidades.
4. **Validade (opcional)**: para produtos que vencem, escolha a data do lote.
5. Confirme a compra. O estoque aumenta na hora e a despesa sai do caixa.

---

## 7. Clientes e Fiado (Crédito)

- **Clientes**: cadastre seus clientes com nome, telefone e e-mail.
- **Registrar fiado**: quando um cliente leva mercadoria para pagar depois, registre o valor e o vencimento.
- Na tela **Crédito** você vê:
 - **Pendentes** = quem ainda deve (total a receber).
 - **Quitadas** = histórico de quem já pagou.
- Quando o cliente pagar, toque em **Quitar dívida** — o dinheiro **entra no caixa automaticamente**.

---

## 8. Financeiro

- **Registrar movimentação**: entradas (dinheiro que entrou) e saídas (contas, despesas).
- **Pendente**: deixe marcado se o valor ainda não foi recebido/pago — ele só conta no caixa **realizado** quando for recebido/pago.
- A tela mostra **entradas**, **saídas** e o **saldo**.
- Nas pendências:
 - **Receber** (entradas pendentes): confirma que o dinheiro entrou → passa a contar no caixa.
 - **Pagar** (saídas pendentes — contas a pagar): confirma o pagamento → passa a contar no caixa.

### Fecho de caixa do dia (Z-report) — dono/gerente
No **Financeiro**, toque no card **Fecho de caixa** (ou na ação no topo):

1. O app mostra o **resumo do dia**: vendas totais, o **esperado na gaveta** (só dinheiro físico — cartão, M-Pesa, E-Mola e transferência não passam pela gaveta) e a abertura **por forma de pagamento**.
2. **Conte o dinheiro físico** da gaveta e digite o valor em **Dinheiro contado**.
3. O app mostra a **diferença** em tempo real: **Caixa confere**, **Sobra** ou **Falta**.
4. Toque em **Confirmar fecho**.

> Errou a contagem? Pode **refazer o fecho do dia** — o valor é atualizado, sem duplicar. Depois do fecho, o badge **"Caixa fechado!"** aparece no Financeiro.

---

## 9. Relatórios — dono/gerente

Veja o desempenho do negócio:

- **Faturamento** (quanto vendeu no período)
- **Lucro bruto** e **margem**
- **Mais vendidos** (os produtos que mais saem)
- **Vendas por dia**

Use os filtros: **Hoje**, **7 dias**, **Este mês**, **Tudo**.

### Exportar e partilhar
Toque em **Exportar** → escolha **Exportar CSV** ou **Exportar PDF**. O relatório é gerado e você pode **partilhar** por WhatsApp, e-mail ou guardar no telefone.

---

## 10. Lojas e Funcionários (dono/gerente)

Abra **Lojas** (card no Início) — são 4 abas:

- **Lojas**: cadastre as suas lojas. Cada loja tem estoque e caixa próprios.
- **Funcionários**: crie contas para quem trabalha com você e escolha o cargo:
 - **Gerente**: opera tudo, exceto gestão de lojas/funcionários.
 - **Funcionário**: só vende (não cadastra produtos, não vê relatórios, não faz compras, fecho de caixa nem anulações).
 - Desative um funcionário a qualquer momento — ele **perde o acesso na hora**.
- **Upgrades**: veja e peça a mudança de plano.
- **Ajustes**: troque a **Loja ativa**, a **moeda** (MZN, BRL, USD, EUR) e o **idioma** (Português/Inglês).

---

## 11. Dicas rápidas

- Confira sempre o **total** antes de confirmar uma venda.
- Atenção: Olhe os **alertas de validade** toda semana — produto vencido é prejuízo.
- Em qualquer lista (vendas, produtos, clientes...) **puxe a tela para baixo** para atualizar.
- Produtos com **foto** são muito mais fáceis de identificar no PDV.
- O app guarda a sua sessão com segurança — você só precisa entrar uma vez.
- Precisa de conexão para vender? **Sim** (no modo online) — as vendas são registradas na hora.

---

## 12. Perguntas frequentes (FAQ)

**Esqueci a minha senha.**
Toque em **"Esqueceu a senha?"** na tela de entrada e siga o link enviado por e-mail.

**Cadastrei-me mas não consigo entrar.**
Seu acesso precisa ser **aprovado** pelo administrador (até 24h). Confirme também que o e-mail/senha estão corretos. Se já passou de 24h, contacte o suporte.

**Um funcionário desativado ainda entra?**
Não por muito tempo: o acesso é **derrubado na hora** quando o dono o desativa. Se a sessão antiga ainda estiver aberta, feche e abra o app de novo.

**Vendi por engano. Como desfazer?**
Abra a venda → **Anular venda** (só dono/gerente). O estoque volta aos lotes certos e o caixa é estornado. A venda fica no histórico marcada como **Anulada**.

**O meu estoque não bate com o que contei.**
Confira se não houve vendas não anuladas, compras ou ajustes manuais de estoque na edição do produto. Para corrigir uma divergência pequena, use o **ajuste de estoque** na edição do produto (dono/gerente).

**A foto do produto não aparece.**
A foto pode não ter enviado por falta de internet no momento do cadastro (o produto é salvo mesmo assim). Abra o produto → **Editar produto** → adicione a foto de novo. Se continuar, veja o [Troubleshooting](TROUBLESHOOTING.md).

**O fecho de caixa mostra "Falta" de dinheiro.**
O "esperado na gaveta" considera **apenas vendas em dinheiro** — cartão, M-Pesa, E-Mola e transferência não entram. Confira se algum pagamento em dinheiro não foi registrado ou se houve dinheiro retirado da gaveta.

**Posso ter mais de uma loja?**
Sim — o número de lojas depende do seu **plano** (veja em **Lojas → Upgrades**). Cada loja tem estoque, vendas e caixa separados.

**As vendas anuladas contam nos relatórios?**
Não. Vendas anuladas ficam no histórico (auditoria), mas **saem** do faturamento, dos KPIs e do resumo do dia.

**Consigo exportar os relatórios?**
Sim — **Exportar CSV** ou **Exportar PDF** na tela de Relatórios, e partilhar por WhatsApp, e-mail etc.

**O app mudou de idioma/moeda do nada?**
A moeda e o idioma são definidos pelo dono em **Lojas → Ajustes** e valem para o negócio inteiro, na hora. Se mudou, foi uma alteração feita nas definições — pode voltar a alterar lá.

---

*Dúvidas que não estão aqui? Veja o [Troubleshooting](TROUBLESHOOTING.md) ou fale com o dono do estabelecimento / suporte.*
