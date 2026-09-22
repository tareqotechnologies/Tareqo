# Solução de Problemas — TAREQO ERP

Guia prático para resolver os problemas mais comuns do app no dia a dia. Para aprender a usar o sistema, veja o [Guia do Utilizador](GUIA_DO_USUARIO.md).

---

## Como usar este guia

1. Encontre o sintoma do problema na lista abaixo (entrada, vendas, stock, fotos...).
2. Siga os passos na ordem indicada — comece sempre pelo mais simples.
3. Se o problema persistir, veja a secção **Mensagens de erro comuns** e, por último, **Quando contactar o suporte**.

> **Atenção:** **Regra de ouro**: antes de qualquer coisa, verifique se o telefone está **com internet** e se o app está **atualizado** (loja de aplicativos). Muitos "erros" são só falta de conexão ou versão antiga.

---

## 1. Problemas de entrada e conta

### "Não consigo entrar"
1. Confirme o **e-mail** (sem espaços, tudo certo) e a **senha**.
2. Toque em **"Esqueceu a senha?"** se não lembrar — o link chega por e-mail (confira também o **spam/lixo eletrónico**).
3. Se é novo utilizador: a conta precisa estar **aprovada** (até 24h). Aprovação pendente = não entra.
4. Feche o app completamente e abra de novo (por vezes a sessão fica presa).

### "A minha conta foi desativada"
- O **dono** pode desativar funcionários — se for o seu caso, o acesso é bloqueado na hora.
- Fale com o dono do estabelecimento para ser reativado.

### "Escrevi o e-mail errado ao registar"
- Não há como alterar o e-mail do registo pelo app: fale com o **suporte** informando o e-mail correto e o nome do negócio.

---

## 2. Problemas com fotos de produto

### "A foto do produto não aparece na lista"
1. O produto pode ter sido salvo **sem foto** (o envio falhou — ex.: sem internet). Abra o produto → **Editar produto** → toque na área de foto → adicione de novo.
2. Confirme que a foto foi mesmo selecionada (a pré-visualização aparece antes de guardar).

### "Ao tirar foto / escolher da galeria, nada acontece"
1. O telefone pede **permissão de câmara/armazenamento** — aceite. Se recusou antes: **Definições do telefone → Aplicações → TAREQO → Permissões** e ative Câmara/Arquivos.
2. Feche e abra o app e tente de novo.

### "Aparece 'Produto adicionado! (foto não enviada…)'"
- O produto foi salvo ✓ — só a foto não subiu (sem internet ou erro temporário).
- Pode adicionar a foto **depois**, pela edição do produto.
- Se acontecer sempre, mesmo com internet, fale com o **suporte** (pode ser configuração do servidor).

---

## 3. Problemas com vendas

### "A venda não confirma / 'Não foi possível registar a venda'"
1. Verifique a **internet**.
2. Confirme que preencheu **todos os campos** (produto, quantidade, forma de pagamento).
3. Confirme que a **quantidade não é zero** e que o **total bate** com os itens.
4. Se a venda é de um produto **desativado**, reative-o (Produtos → Editar → **Produto ativo**).

### "Vendi por engano / o cliente não levou"
- Abra a venda → **Anular venda** (só dono/gerente). O stock volta e o caixa é estornado.
- **Funcionário não vê o botão Anular** — é uma operação gerencial; peça ao dono/gerente.

### "O stock não abateu / abateu a mais"
1. Confira no **detalhe da venda** se os itens estão corretos.
2. Vendas **anuladas** devolvem o stock — se anulou, o stock volta.
3. Verifique se houve **compras** (aumentam o stock) ou **ajustes manuais** na edição do produto.
4. Se ainda houver divergência, use o ajuste de stock na edição do produto (dono/gerente) para corrigir.

### "A balança etiquetadora não encontra o produto"
- Confirme o **código (PLU)** cadastrado no produto (até 5 dígitos, formato `20PPPPPWWWWW`).
- Confirme que o produto está **ativo** e na **loja ativa** correta.

---

## 4. Problemas com produtos e stock

### "O produto não aparece na lista / no PDV"
1. Puxe a tela para baixo para **atualizar** a lista.
2. Confirme que está na **loja ativa** certa (Lojas → Ajustes → Loja ativa).
3. Verifique se o produto não está **desativado** (Produtos → Editar → Produto ativo).

### "O stock está negativo ou errado"
- O sistema não permite vender mais do que existe — o erro "stock insuficiente" é o sistema protegendo você.
- Corrija divergências pelo **ajuste manual de stock** (edição do produto, dono/gerente).

### "O alerta de validade não aparece"
- O alerta aparece quando o produto tem **data de validade** definida (cadastro ou compra com lote).
- Produtos sem validade nunca geram alerta.

---

## 5. Problemas com dinheiro e financeiro

### "O saldo do caixa não bate"
1. Confirme se há **pendências** (receber/pagar) ainda não confirmadas — só contam quando **Receber/Pagar** é confirmado.
2. Vendas **anuladas** geram estorno — o par (venda + estorno) fecha em zero.
3. Compras e despesas saem do caixa — confira se não há despesa esquecida.
4. Confira a **loja ativa** — cada loja tem caixa separado.

### "O fecho de caixa mostra sobra/falta"
- O **esperado na gaveta** considera **só dinheiro físico** (cartão, M-Pesa, E-Mola, transferência não entram).
- **Sobra**: pode haver dinheiro extra (ex.: cliente pagou a mais, ou registo a menos).
- **Falta**: confira se algum pagamento em dinheiro não foi registado ou se houve retirada da gaveta.
- Errou a contagem? Pode **refazer o fecho do dia** — atualiza sem duplicar.

### "Não consigo fazer o fecho de caixa / registar compra"
- São operações **gerenciais** (dono/gerente). Funcionários não têm o botão — peça ao dono/gerente.

### "A pendência não entra no caixa quando recebo"
- Ao confirmar **Receber/Pagar**, a movimentação passa a contar no caixa **realizado**. Se não contar, atualize a tela (puxe para baixo) e confirme a loja ativa.

---

## 6. Problemas de conexão e sincronização

### "Os dados parecem antigos / não atualizam"
1. **Puxe a tela para baixo** nas listas para atualizar.
2. Troque de aba e volte (o app recarrega ao entrar na tela).
3. Verifique a internet do telefone.

### "Sem internet, consigo usar o app?"
- No modo **online** (padrão), o app precisa de conexão para registar vendas, produtos etc. Sem internet, as operações falham — tente de novo quando voltar a conexão.
- O **login** também exige internet.

### "O app fica 'carregando' para sempre"
1. Verifique a internet (teste abrindo outra página/aplicação).
2. Feche o app e abra de novo.
3. Se for a **primeira abertura** após atualização, aguarde — pode estar a sincronizar.

---

## 7. Problemas do app (trava, tela branca, lento)

### "O app trava ou fecha sozinho"
1. Feche o app (deslize para fora das apps recentes) e abra de novo.
2. **Reinicie o telefone** se continuar.
3. Verifique o **armazenamento** do telefone (muito cheio → app lento).
4. **Atualize o app** na loja de aplicativos — versões antigas podem ter erros já corrigidos.

### "Tela branca / não abre"
1. Feche e abra o app.
2. Verifique a internet (a tela de login precisa dela).
3. Se continuar, **desinstale e instale de novo** — os seus dados ficam no servidor e voltam ao entrar. Atenção: Desinstalar **não apaga** os dados do negócio (estão na nuvem), mas confirme o e-mail/senha antes.

### "O app mudou de idioma / moeda de repente"
- A **moeda** e o **idioma** são definidos pelo dono em **Lojas → Ajustes** e valem para o **negócio inteiro**, na hora. Se mudou de repente, foi uma alteração feita nas definições (ou noutro aparelho com a mesma conta de dono) — basta voltar a **Lojas → Ajustes** e escolher de novo.

---

## 8. Mensagens de erro comuns

> As mensagens abaixo são **aproximações** — a redação exata pode variar ligeiramente por versão do app. Procure pela ideia central.

| Mensagem que aparece (ex.:) | O que significa | O que fazer |
|----------------------|-----------------|-------------|
| **"Não foi possível entrar. Verifique as suas credenciais."** | E-mail ou senha errados | Recupere a senha ("Esqueceu a senha?") ou confira o e-mail |
| **"Acesso pendente de aprovação"** | Conta ainda não aprovada | Aguarde a aprovação (até 24h) ou fale com o suporte |
| **"Não foi possível adicionar o produto. Tente novamente."** | Erro ao guardar o produto | Verifique a internet, os campos obrigatórios e tente de novo |
| **"Produto adicionado! (foto não enviada…)"** | Produto salvo, mas a foto não subiu | Adicione a foto depois pela edição do produto |
| **"Stock insuficiente"** | Não há stock suficiente para a quantidade | Reduza a quantidade, compre mais ou ajuste o stock |
| **"O total da venda não corresponde aos itens"** | Soma dos itens ≠ total | Revise os itens e o total antes de confirmar |
| **"Não foi possível anular a venda. Tente novamente."** | Erro ao anular | Verifique a internet e se a venda ainda está ativa (não anulada) |
| **"Apenas o dono ou um gerente podem…"** | Operação restrita ao dono/gerente | Peça ao dono/gerente para executar |
| **"Não foi possível partilhar o recibo"** | Erro ao partilhar | Verifique se tem apps de partilha (WhatsApp) instalados |
| **"Não foi possível exportar o relatório"** | Erro ao gerar o CSV/PDF | Tente de novo; se persistir, contacte o suporte |
| **"Sessão expirada / entre de novo"** | Sessão antiga terminou | Faça login novamente |

---

## 9. Quando contactar o suporte

Contacte o suporte quando:

- A mensagem de erro **persiste** após tentar os passos acima.
- O erro envolve **dinheiro** (caixa, fecho, vendas) e a diferença não é explicável.
- Há suspeita de **dados errados no servidor** (ex.: venda que não aparece em outro aparelho).
- O app apresenta um erro **novo** ou um **comportamento estranho** depois de uma atualização.

**Para ajudar o suporte, tenha à mão:**
1. A **mensagem exata** que aparece no ecrã (ou um print/ecrã).
2. O que estava a fazer quando o erro aconteceu (ex.: "registar venda de 3 produtos").
3. O **telefone/modelo** e a **versão do app** (Definições do telefone → Aplicações → TAREQO).
4. A **loja** e o **horário** aproximado do problema.

---

*Baseado no Guia do Utilizador — para aprender a usar o app, veja o [Guia do Utilizador](GUIA_DO_USUARIO.md).*
