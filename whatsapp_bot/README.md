# Bot WhatsApp TAREQO (Python)

Serviço independente do aplicativo Flutter e do Supabase. Recebe webhooks da WhatsApp Business Platform, responde a algumas dúvidas frequentes e valida a assinatura HMAC enviada pela Meta. A lógica não consulta contas ou dados internos do TAREQO.

## Rodar localmente

Requer Python 3.10 ou superior.

```powershell
cd whatsapp_bot
python -m venv .venv
.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Preencha `.env` com os valores do app/conta de WhatsApp da Meta. Carregue as variáveis no terminal antes de iniciar o servidor; o Flask não lê `.env` automaticamente:

```powershell
Get-Content .env | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
  $name, $value = $_ -split '=', 2
  [Environment]::SetEnvironmentVariable($name.Trim(), $value.Trim(), 'Process')
}
python -m flask --app app run --host 0.0.0.0 --port 8000
```

O endpoint local é `/webhook`; a Meta exige uma URL pública HTTPS para validar e enviar eventos. Em produção, rode atrás de um host Python com HTTPS e use `gunicorn app:app` (Linux). Defina as variáveis de ambiente no painel do host, sem gravar credenciais no repositório.

## Meta

Configure a URL pública terminada em `/webhook`, o mesmo `META_VERIFY_TOKEN` e assine o campo `messages`. Cadastre `META_APP_SECRET`, `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` e `META_GRAPH_API_VERSION` nas variáveis de ambiente do serviço.

O serviço Python separado não remove exigências da Meta para registrar números, limites, revisão do app ou recursos restritos. Use somente dados comerciais verdadeiros e siga a elegibilidade exibida no painel Meta. Para desenvolver enquanto o negócio não conclui alguma verificação, use apenas as opções de teste que a Meta disponibilizar para o app e os números de teste/permitidos.

## Atendimento humano

A opção 5 só explica como pedir atendimento; não cria ticket e não avisa uma pessoa. Antes de oferecer transferência automática, conecte um canal real de atendimento. Não peça senha, códigos de acesso ou dados de cartão pelo bot.
