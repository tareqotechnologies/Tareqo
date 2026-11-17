// TAREQO WhatsApp Cloud API webhook (Supabase Edge Function / Deno).
// Configure WHATSAPP_VERIFY_TOKEN, WHATSAPP_ACCESS_TOKEN,
// WHATSAPP_PHONE_NUMBER_ID and WHATSAPP_API_VERSION as function secrets.
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

const menu = `Olá! 👋 Sou o assistente virtual do TAREQO. Como posso ajudar?\n\n1️⃣ Conhecer o TAREQO\n2️⃣ Funcionalidades\n3️⃣ Como começar\n4️⃣ Ajuda com acesso ou problema\n5️⃣ Falar com uma pessoa\n\nResponda com o número ou escreva sua dúvida.`;

function answer(input: string): string {
  const text = input.trim().toLocaleLowerCase("pt-BR");
  if (/^(oi|olá|ola|bom dia|boa tarde|boa noite|menu|início|inicio|start|0)$/.test(text)) return menu;
  if (/^(1|o que é|sobre|conhecer|tareqo)/.test(text)) {
    return "O TAREQO é um sistema de gestão para pequenos comerciantes. Ajuda a controlar produtos, vendas, compras, caixa, clientes, crédito e relatórios. Quer saber sobre funcionalidades (2) ou como começar (3)?";
  }
  if (/^(2|funcionalidades|recursos|faz o quê|faz o que)/.test(text)) {
    return "Com o TAREQO você pode gerir produtos e estoque, registar vendas e compras, acompanhar caixa e crédito de clientes e consultar relatórios. Também permite gerir lojas e funcionários. Os dados de cada loja ficam separados por conta.";
  }
  if (/^(3|começar|comecar|cadastro|registar|registrar|criar conta)/.test(text)) {
    return "Para começar, acesse o TAREQO e crie sua conta. Depois cadastre sua loja e seus produtos. Para orientá-lo melhor, diga em qual país está e se já conseguiu acessar o aplicativo.";
  }
  if (/^(4|ajuda|problema|erro|acesso|senha|login|suporte)/.test(text)) {
    return "Posso ajudar. Qual é o problema? Por segurança, não envie sua senha, códigos de acesso ou dados de cartão. Se puder, descreva a tela e a mensagem de erro; vou encaminhar para a equipe se não conseguir resolver.";
  }
  if (/^(5|pessoa|humano|atendente|equipe|falar)/.test(text) || /atendente|pessoa real|falar com (alguém|uma pessoa)/.test(text)) {
    return "Claro — vou encaminhar seu pedido para a equipe TAREQO. Conte brevemente o que precisa e informe seu nome. Não envie senhas nem códigos de acesso.";
  }
  if (/preço|preco|plano|valor|pagamento|custo/.test(text)) {
    return "Os planos e valores podem variar. Para receber a informação atualizada e adequada ao seu país, responda 5 para falar com a equipe TAREQO.";
  }
  if (/^(obrigad[oa]|valeu|thanks)/.test(text)) return "Por nada! 😊 Se precisar, escreva MENU para ver as opções novamente.";
  return "Ainda não encontrei uma resposta segura para essa dúvida. Escreva MENU para ver as opções ou responda 5 para falar com a equipe TAREQO.";
}

async function sendText(to: string, body: string) {
  const token = Deno.env.get("WHATSAPP_ACCESS_TOKEN");
  const phoneId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
  const version = Deno.env.get("WHATSAPP_API_VERSION") ?? "v22.0";
  if (!token || !phoneId) throw new Error("WhatsApp credentials are not configured");
  const response = await fetch(`https://graph.facebook.com/${version}/${phoneId}/messages`, {
    method: "POST",
    headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: JSON.stringify({ messaging_product: "whatsapp", recipient_type: "individual", to, type: "text", text: { preview_url: false, body } }),
  });
  if (!response.ok) console.error("WhatsApp send failed", response.status, await response.text());
}

async function hasValidSignature(rawBody: string, signature: string | null): Promise<boolean> {
  const appSecret = Deno.env.get("WHATSAPP_APP_SECRET");
  if (!appSecret || !signature?.startsWith("sha256=")) return false;
  const key = await crypto.subtle.importKey(
    "raw", new TextEncoder().encode(appSecret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const digest = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(rawBody)));
  const expected = `sha256=${Array.from(digest, (byte) => byte.toString(16).padStart(2, "0")).join("")}`;
  if (signature.length !== expected.length) return false;
  let mismatch = 0;
  for (let i = 0; i < signature.length; i++) mismatch |= signature.charCodeAt(i) ^ expected.charCodeAt(i);
  return mismatch === 0;
}

Deno.serve(async (request) => {
  const url = new URL(request.url);
  if (request.method === "GET") {
    const mode = url.searchParams.get("hub.mode");
    const token = url.searchParams.get("hub.verify_token");
    const challenge = url.searchParams.get("hub.challenge");
    if (mode === "subscribe" && token && token === Deno.env.get("WHATSAPP_VERIFY_TOKEN") && challenge) {
      return new Response(challenge, { status: 200 });
    }
    return new Response("Forbidden", { status: 403 });
  }
  if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });

  const rawBody = await request.text();
  if (!await hasValidSignature(rawBody, request.headers.get("x-hub-signature-256"))) {
    return new Response("Unauthorized", { status: 401 });
  }
  let payload: any;
  try { payload = JSON.parse(rawBody); } catch { return json({ error: "Invalid JSON" }, 400); }
  if (payload?.object !== "whatsapp_business_account") return json({ ok: true });

  // Acknowledge quickly; ignore delivery/read receipts and non-text messages.
  for (const entry of payload.entry ?? []) {
    for (const change of entry.changes ?? []) {
      for (const message of change.value?.messages ?? []) {
        if (message.type !== "text" || !message.from || !message.text?.body) continue;
        try { await sendText(message.from, answer(message.text.body)); }
        catch (error) { console.error("Could not process WhatsApp message", error); }
      }
    }
  }
  return json({ ok: true });
});
