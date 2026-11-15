"""Standalone TAREQO WhatsApp Cloud API webhook."""

from __future__ import annotations

import hashlib
import hmac
import logging
import os

import requests
from flask import Flask, abort, request

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 128 * 1024
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("tareqo-whatsapp")

MENU = (
    "Olá! 👋 Sou o assistente virtual do TAREQO. Como posso ajudar?\n\n"
    "1️⃣ Conhecer o TAREQO\n2️⃣ Funcionalidades\n3️⃣ Como começar\n"
    "4️⃣ Ajuda com acesso ou problema\n5️⃣ Atendimento humano\n\n"
    "Responda com o número ou escreva sua dúvida."
)


def answer(message: str) -> str:
    text = message.strip().casefold()
    if text in {"oi", "olá", "ola", "bom dia", "boa tarde", "boa noite", "menu", "início", "inicio", "start", "0"}:
        return MENU
    if text.startswith(("1", "o que é", "sobre", "conhecer", "tareqo")):
        return (
            "O TAREQO é um sistema de gestão para pequenos comerciantes. "
            "Ajuda a controlar produtos, vendas, compras, caixa, clientes, crédito e relatórios. "
            "Quer saber sobre funcionalidades (2) ou como começar (3)?"
        )
    if text.startswith(("2", "funcionalidades", "recursos", "faz o quê", "faz o que")):
        return (
            "Com o TAREQO você pode gerir produtos e estoque, registar vendas e compras, "
            "acompanhar caixa e crédito de clientes e consultar relatórios. "
            "Também permite gerir lojas e funcionários."
        )
    if text.startswith(("3", "começar", "comecar", "cadastro", "registar", "registrar", "criar conta")):
        return (
            "Para começar, acesse o TAREQO e crie sua conta. Depois cadastre sua loja e seus produtos. "
            "Diga em qual país está e se já conseguiu acessar o aplicativo para eu orientar melhor."
        )
    if text.startswith(("4", "ajuda", "problema", "erro", "acesso", "senha", "login", "suporte")):
        return (
            "Posso ajudar. Descreva o problema e a mensagem que aparece. "
            "Por segurança, não envie sua senha, códigos de acesso ou dados de cartão."
        )
    if text.startswith(("5", "pessoa", "humano", "atendente", "equipe", "falar")) or any(
        phrase in text for phrase in ("atendente", "pessoa real", "falar com alguém", "falar com uma pessoa")
    ):
        return (
            "Anote seu nome e descreva o que precisa para a equipe TAREQO. "
            "Este bot ainda não transfere a conversa automaticamente. Não envie senhas nem códigos de acesso."
        )
    if any(word in text for word in ("preço", "preco", "plano", "valor", "pagamento", "custo")):
        return (
            "Não tenho uma tabela de preços atualizada. Para confirmar planos e valores, "
            "peça atendimento à equipe TAREQO."
        )
    if text in {"obrigado", "obrigada", "valeu", "thanks"}:
        return "Por nada! 😊 Se precisar, escreva MENU para ver as opções novamente."
    return "Não encontrei uma resposta segura para essa dúvida. Escreva MENU ou escolha 5 para ver as opções de atendimento."


def valid_meta_signature(raw_body: bytes, signature: str | None) -> bool:
    app_secret = os.getenv("META_APP_SECRET", "")
    if not app_secret or not signature or not signature.startswith("sha256="):
        return False
    digest = hmac.new(app_secret.encode(), raw_body, hashlib.sha256).hexdigest()
    expected = f"sha256={digest}"
    return hmac.compare_digest(signature, expected)


def send_text(recipient: str, body: str) -> None:
    access_token = os.getenv("WHATSAPP_ACCESS_TOKEN", "")
    phone_number_id = os.getenv("WHATSAPP_PHONE_NUMBER_ID", "")
    api_version = os.getenv("META_GRAPH_API_VERSION", "")
    if not all((access_token, phone_number_id, api_version)):
        raise RuntimeError("WhatsApp Cloud API environment variables are not configured")

    response = requests.post(
        f"https://graph.facebook.com/{api_version}/{phone_number_id}/messages",
        headers={"Authorization": f"Bearer {access_token}"},
        json={
            "messaging_product": "whatsapp",
            "recipient_type": "individual",
            "to": recipient,
            "type": "text",
            "text": {"preview_url": False, "body": body},
        },
        timeout=15,
    )
    if not response.ok:
        logger.error("Meta rejected message send (HTTP %s): %s", response.status_code, response.text[:1000])
        response.raise_for_status()


@app.get("/webhook")
def verify_webhook():
    mode = request.args.get("hub.mode")
    token = request.args.get("hub.verify_token")
    challenge = request.args.get("hub.challenge")
    verify_token = os.getenv("META_VERIFY_TOKEN", "")
    if mode == "subscribe" and verify_token and hmac.compare_digest(token or "", verify_token) and challenge:
        return challenge, 200, {"Content-Type": "text/plain; charset=utf-8"}
    abort(403)


@app.post("/webhook")
def receive_webhook():
    raw_body = request.get_data(cache=True)
    if not valid_meta_signature(raw_body, request.headers.get("X-Hub-Signature-256")):
        abort(401)

    payload = request.get_json(silent=True)
    if not isinstance(payload, dict) or payload.get("object") != "whatsapp_business_account":
        return {"ok": True}, 200

    for entry in payload.get("entry", []):
        for change in entry.get("changes", []):
            value = change.get("value") or {}
            for message in value.get("messages", []):
                if message.get("type") != "text" or not message.get("from"):
                    continue
                body = (message.get("text") or {}).get("body", "")
                if not body:
                    continue
                try:
                    send_text(message["from"], answer(body))
                except Exception:
                    logger.exception("Failed processing incoming WhatsApp message")
    return {"ok": True}, 200


@app.get("/health")
def health():
    return {"status": "ok"}, 200
