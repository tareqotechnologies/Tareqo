# Atendimento TAREQO no WhatsApp

Webhook inicial para WhatsApp Business Cloud API, implementado como Supabase Edge Function. O bot responde em português a dúvidas frequentes sobre o produto e oferece opção de encaminhamento humano. Não consulta dados de contas, não recebe credenciais do utilizador e não inventa valores de planos.

## Configuração

1. Crie/configure um número no WhatsApp Business Platform e associe o app Meta.
2. Faça deploy da função `whatsapp-webhook` no projeto Supabase do TAREQO com `supabase functions deploy whatsapp-webhook --no-verify-jwt`. A verificação JWT padrão não serve para chamadas Meta; a função valida a assinatura HMAC da Meta em cada POST.
3. Configure estes secrets no projeto Supabase (nunca no app Flutter):

   - `WHATSAPP_VERIFY_TOKEN`: segredo aleatório criado por você para a validação inicial do webhook.
   - `WHATSAPP_APP_SECRET`: App Secret do app Meta; usado para validar `X-Hub-Signature-256` em cada POST.
   - `WHATSAPP_ACCESS_TOKEN`: token da WhatsApp Cloud API.
   - `WHATSAPP_PHONE_NUMBER_ID`: ID do número de telefone no WhatsApp Manager.
   - `WHATSAPP_API_VERSION`: versão Graph API habilitada no app Meta, por exemplo `v22.0`.

4. No painel Meta, configure a URL pública `https://<projeto>.supabase.co/functions/v1/whatsapp-webhook`, informe o mesmo verify token e assine o campo `messages`.
5. Envie uma mensagem de teste a partir de um número permitido pela configuração do app Meta.

## Ajustar respostas

As intenções e mensagens ficam na função `answer` em `index.ts`. Atualize ali os textos, horários de atendimento e procedimento de transferência quando a equipe confirmar esses dados. A opção 5 informa que o cliente quer atendimento humano, mas este esqueleto ainda não cria ticket nem notifica um atendente: conecte-a ao canal de suporte escolhido antes de anunciar transferência automática.

O endpoint ignora eventos de status e mensagens que não sejam texto. Antes de produção, configure limites/monitoramento, política de privacidade e retenção dos dados de mensagens conforme a operação do TAREQO.
