/* ════════════════════════════════════════════════════════════
   TAREQO — i18n (pt / en / fr)
   Dicionário + motor de tradução do site institucional.
   Uso: TAREQO_I18N.apply('en') · TAREQO_I18N.t('nav.cta')
   Idioma resolvido por: ?lang= no URL > localStorage > navegador > pt.
   Terminologia alinhada com lib/l10n (app Flutter).
   ════════════════════════════════════════════════════════════ */
(function (global) {
  'use strict';

  var LANGS = ['pt', 'en', 'fr'];
  var DEFAULT_LANG = 'pt';
  var STORAGE_KEY = 'tareqo.lang';

  /* ── Título e descrição por idioma (SEO) ─────────────────── */
  var META = {
    pt: {
      title: 'TAREQO — ERP para comerciantes | Estoque, Vendas, Financeiro',
      description: 'TAREQO é o ERP offline-first para pequenos comerciantes: estoque, vendas, compras, fluxo de caixa, crédito fiado, multi-loja e relatórios — em pt/en/fr e MZN, BRL, USD, EUR.'
    },
    en: {
      title: 'TAREQO — ERP for merchants | Inventory, Sales, Finance',
      description: 'TAREQO is the offline-first ERP for small merchants: inventory, sales, purchases, cash flow, store credit, multi-store and reports — in pt/en/fr and MZN, BRL, USD, EUR.'
    },
    fr: {
      title: 'TAREQO — ERP pour commerçants | Stock, Ventes, Finances',
      description: 'TAREQO est l’ERP offline-first pour petits commerçants : stock, ventes, achats, trésorerie, crédit client, multi-magasins et rapports — en pt/en/fr et MZN, BRL, USD, EUR.'
    }
  };

  /* ── Dicionário (chaves planas = data-i18n do index.html) ── */
  var DICT = {

    /* ─────────────────────────── PT ─────────────────────────── */
    pt: {
      'nav.features': 'Funcionalidades',
      'nav.addons': 'Add-ons',
      'nav.how': 'Como funciona',
      'nav.pricing': 'Planos',
      'nav.faq': 'FAQ',
      'nav.contact': 'Contacto',
      'nav.cta': 'Descarregar',
      'nav.menuOpen': 'Abrir menu',
      'nav.menuClose': 'Fechar menu',

      'hero.badge': 'ERP offline-first para comerciantes',
      'hero.title.a': 'Gestão completa do seu negócio,',
      'hero.title.b': 'na palma da mão.',
      'hero.subtitle': 'Estoque, vendas, compras, fluxo de caixa, crédito fiado e relatórios — num só aplicativo. Funciona 100% offline e sincroniza com segurança quando tem internet.',
      'hero.cta1': 'Descarregar para Android',
      'hero.cta.ios': 'Descarregar para iOS',
      'hero.cta2': 'Ver funcionalidades',
      'hero.note': 'Sem cartão de crédito · Plano gratuito · pt / en / fr',

      'stats.langs': 'idiomas (pt · en · fr)',
      'stats.currencies': 'moedas (MZN · BRL · USD · EUR)',
      'stats.offline': 'offline-first',
      'stats.security': 'biometria + MFA',

      'ph.today': 'Hoje',
      'ph.sales': 'Vendas',
      'ph.cash': 'Caixa',
      'ph.receivable': 'A receber',
      'ph.week': 'Vendas da semana',
      'ph.viewall': 'Ver tudo',
      'ph.lowstock': 'Estoque baixo',

      't1': 'Funciona 100% offline',
      't2': 'Multi-loja & equipa',
      't3': 'pt · en · fr',
      't4': 'MZN · BRL · USD · EUR',
      't5': 'Biometria + 2FA',
      't6': 'PDF & WhatsApp',

      'modules.kicker': 'Módulos',
      'modules.title': 'Tudo o que o seu negócio precisa',
      'modules.subtitle': 'Módulos integrados que trabalham juntos — cada venda baixa estoque e entra no caixa em uma transação atômica.',

      'm1.t': 'Dashboard',
      'm1.d': 'KPIs de vendas, caixa, a receber e estoque em tempo real, com ações rápidas e alerta de estoque baixo.',
      'm2.t': 'Produtos',
      'm2.d': 'Catálogo com busca, códigos/PLU para balanças, fotos e preços validados. Leia de código de barras.',
      'm3.t': 'Vendas',
      'm3.d': 'Carrinho rápido com forma de pagamento. Venda, baixa de estoque e caixa numa única transação atômica.',
      'm4.t': 'Compras',
      'm4.d': 'Entrada de mercadorias com atualização automática de estoque e registo da saída no caixa.',
      'm5.t': 'Financeiro',
      'm5.d': 'Fluxo de caixa por período, entradas e saídas detalhadas, e recebimento de pendências num toque.',
      'm6.t': 'Crédito (fiado)',
      'm6.d': 'A receber e a pagar com vencimento, baixa parcial ou total e histórico completo de quitações.',
      'm7.t': 'Lojas & Equipa',
      'm7.d': 'Gestão de várias lojas e funcionários por tenant, com plano, idioma e moeda à sua escolha.',
      'm8.t': 'Relatórios',
      'm8.d': 'Relatórios de vendas, produtos e financeiro para decisões rápidas — com exportação em PDF.',

      'addons.kicker': 'Add-ons',
      'addons.title': 'Expanda com add-ons',
      'addons.subtitle': 'Ative apenas o que o seu negócio precisa. Geridos pelo painel de administração, disponíveis conforme o plano.',
      'addons.soon': 'Em breve',

      'a1.t': 'Factura Personalizada',
      'a1.d': 'Facturas com o seu logótipo e cores, numeração sequencial por loja, exportação em PDF e envio por WhatsApp.',
      'a2.t': 'Cotações / Orçamentos',
      'a2.d': 'Crie e envie orçamentos com templates personalizáveis e acompanhe o estado: rascunho → enviada → aceite/rejeitada.',
      'a3.t': 'Relatórios Avançados',
      'a3.d': 'KPIs financeiros, produtos por estoque, fluxo de caixa e alertas de estoque baixo numa vista executiva.',
      'a4.t': 'Gestão de Funcionários',
      'a4.d': 'Ponto de entrada/saída, comissões calculadas sobre vendas reais e metas mensais com barra de progresso.',
      'a5.t': 'Transferências entre Lojas',
      'a5.d': 'Mova estoque entre lojas com baixa na origem e entrada no destino, e histórico completo de transferências.',
      'a6.t': 'M-Pesa & E-Mola',
      'a6.d': 'Reconciliação de pagamentos mobile money com confirmação ou rejeição — integração a caminho.',

      'how.kicker': 'Como funciona',
      'how.title': 'A vender em minutos',
      'how.subtitle': 'Sem instalação complicada, sem formação de dias. Três passos e está a faturar.',

      's1.t': 'Crie a sua conta',
      's1.d': 'Descarregue o aplicativo, registe-se e configure a sua loja — idioma e moeda à sua escolha.',
      's2.t': 'Adicione os produtos',
      's2.d': 'Cadastre o catálogo com preços e estoque — digite, fotografe ou leia o código de barras.',
      's3.t': 'Venda e acompanhe',
      's3.d': 'Cada venda baixa estoque e entra no caixa. O dashboard mostra o pulso do negócio em tempo real.',

      'sec.kicker': 'Segurança',
      'sec.title': 'Os seus dados, protegidos de ponta a ponta',
      'sec.subtitle': 'Segurança de nível empresarial, simples de usar — mesmo num telemóvel.',

      'se1.t': 'Isolamento por tenant',
      'se1.d': 'Row Level Security no servidor: cada loja só acede aos próprios dados — garantido pelo banco, não pelo app.',
      'se2.t': 'Biometria + MFA',
      'se2.d': 'Bloqueio por impressão digital/rosto ao afastar o telemóvel e autenticação em dois fatores (TOTP) com QR code.',
      'se3.t': 'Segredos encriptados',
      'se3.d': 'Sessões guardadas no Keychain/Keystore do aparelho e payloads offline cifrados com AES-GCM.',
      'se4.t': 'Transações atômicas',
      'se4.d': 'Venda = estoque − caixa numa transação só. RPCs atômicas no servidor impedem dados pela metade.',

      'pr.kicker': 'Planos',
      'pr.title': 'Comece grátis, cresça quando quiser',
      'pr.subtitle': 'Do caderno ao controlo profissional — cada plano desbloqueia mais gestão para o seu negócio.',
      'pr.month': '/mês',
      'pr.popular': 'Mais escolhido',
      'pr.disclaimer': 'Preços em Meticais, IVA incluído. Cancele quando quiser.',

      'pr.p1.t': 'Grátis',
      'pr.p1.d': 'Para pequenos negócios que estão a começar a organizar a sua operação.',
      'pr.p1.f1': 'Dashboard com visão geral das vendas',
      'pr.p1.f2': 'Registo de produtos e categorias',
      'pr.p1.f3': 'Controlo básico de estoque',
      'pr.p1.f4': 'Registo de vendas',
      'pr.p1.f5': 'Gestão de clientes',
      'pr.p1.f6': 'Controlo de caixa',
      'pr.p1.f7': 'Crédito fiado',
      'pr.p1.f8': 'Histórico de transações',
      'pr.p1.f9': 'Funcionamento offline',
      'pr.p1.f10': 'Sincronização automática quando a internet estiver disponível',
      'pr.p1.f11': 'Idiomas: português, inglês e francês',
      'pr.p1.f12': 'Moedas: MZN, BRL, USD e EUR',
      'pr.cta1': 'Começar gratuitamente',
      'pr.p1.note': 'Ideal para substituir cadernos, folhas de cálculo e processos manuais por uma solução simples e organizada.',

      'pr.p2.t': 'Profissional',
      'pr.p2.d': 'Para negócios que estão a crescer e precisam de mais controlo sobre a operação.',
      'pr.p2.priceNote': 'Tudo o que precisa para gerir vendas, estoque, equipa, caixa e clientes com mais eficiência.',
      'pr.p2.f1': 'Relatórios avançados para decisões mais rápidas',
      'pr.p2.f2': 'Faturas e orçamentos profissionais',
      'pr.p2.f3': 'Gestão de equipa e permissões',
      'pr.p2.f4': 'Controlo de várias lojas',
      'pr.p2.f5': 'Transferência de estoque entre unidades',
      'pr.p2.f6': 'Gestão financeira detalhada',
      'pr.p2.f7': 'Sincronização segura na nuvem',
      'pr.p2.f8': 'Suporte prioritário por WhatsApp',
      'pr.cta2': 'Começar com o Profissional',
      'pr.p2.note': 'O plano completo para transformar a gestão diária do seu negócio.',

      'pr.p3.t': 'Empresarial',
      'pr.p3.d': 'Para redes, distribuidores e empresas que precisam de controlo avançado, personalização e suporte dedicado.',
      'pr.p3.price': 'Sob consulta',
      'pr.p3.priceNote': 'Valor definido de acordo com o número de lojas, utilizadores, volume de transações, integrações, suporte e personalização.',
      'pr.p3.f1': 'Tudo do Plano Profissional, além de:',
      'pr.p3.f2': 'Múltiplas lojas e unidades com utilizadores personalizados',
      'pr.p3.f3': 'Permissões avançadas e fluxos de aprovação',
      'pr.p3.f4': 'Relatórios consolidados e comparação entre lojas',
      'pr.p3.f5': 'Indicadores personalizados e integrações sob contrato',
      'pr.p3.f6': 'M-Pesa e E-Mola, quando disponível',
      'pr.p3.f7': 'Onboarding, migração de dados e treinamento da equipa',
      'pr.p3.f8': 'Suporte prioritário dedicado e maior capacidade',
      'pr.cta3': 'Falar com um especialista',
      'pr.p3.note': 'Uma solução de gestão preparada para acompanhar a expansão da sua empresa.',

      'pr.cmp.title': 'Comparação resumida',
      'pr.cmp.feat': 'Funcionalidade',
      'pr.cmp.yes': 'Sim',
      'pr.cmp.no': 'Não',
      'pr.cmp.basic': 'Básica',
      'pr.cmp.advanced': 'Avançada',
      'pr.cmp.advPerm': 'Avançada',
      'pr.cmp.custom': 'Personalizada',
      'pr.cmp.whenAvail': 'Conforme disponibilidade',
      'pr.cmp.byContract': 'Conforme contrato',
      'pr.cmp.std': 'Padrão',
      'pr.cmp.waPriority': 'Prioritário por WhatsApp',
      'pr.cmp.dedicated': 'Dedicado',
      'pr.cmp.guided': 'Guiado',
      'pr.cmp.assisted': 'Assistido',
      'pr.cmp.personalized': 'Personalizado',
      'pr.cmp.optional': 'Opcional',
      'pr.cmp.inContract': 'Incluída conforme contrato',
      'pr.cmp.r1': 'Dashboard de vendas e caixa',
      'pr.cmp.r2': 'Gestão de produtos',
      'pr.cmp.r3': 'Controlo de estoque',
      'pr.cmp.r4': 'Registo de vendas',
      'pr.cmp.r5': 'Crédito fiado',
      'pr.cmp.r6': 'Funcionamento offline',
      'pr.cmp.r7': 'Sincronização na nuvem',
      'pr.cmp.r8': 'Relatórios avançados',
      'pr.cmp.r9': 'Faturas personalizadas',
      'pr.cmp.r10': 'Exportação em PDF',
      'pr.cmp.r11': 'Cotações e orçamentos',
      'pr.cmp.r12': 'Gestão de funcionários',
      'pr.cmp.r13': 'Permissões por função',
      'pr.cmp.r14': 'Gestão de várias lojas',
      'pr.cmp.r15': 'Transferência entre lojas',
      'pr.cmp.r16': 'Comissões e metas',
      'pr.cmp.r17': 'M-Pesa e E-Mola',
      'pr.cmp.r18': 'Suporte',
      'pr.cmp.r19': 'Onboarding',
      'pr.cmp.r20': 'Migração de dados',

      'ts.kicker': 'Quem usa',
      'ts.title': 'Feito para o comerciante',
      'ts.subtitle': 'De quiosques a redes de lojas — gestão séria, sem papelada.',
      'ts.q1': '“Antes era caderno e calculadora. Agora vejo o caixa do dia num toque — e sei exatamente o que falta no estoque.”',
      'ts.a1': 'Amélia C. — Loja de conveniência, Maputo',
      'ts.q2': '“A internet cai e o TAREQO continua a vender. Quando volta, tudo sincroniza sozinho.”',
      'ts.a2': 'Yusuf M. — Mercado, Nampula',
      'ts.q3': '“Envio orçamentos em PDF pelo WhatsApp e ganhei clientes que antes não conseguia responder a tempo.”',
      'ts.a3': 'Sofia R. — Boutique, Beira',

      'faq.title': 'Perguntas frequentes',
      'faq.q1': 'O TAREQO funciona sem internet?',
      'faq.a1': 'Sim. Toda a operação — vendas, estoque, caixa, crédito — funciona 100% offline no seu aparelho (SQLite). Quando a internet volta, os dados sincronizam automaticamente e com segurança.',
      'faq.q2': 'Em que plataformas está disponível?',
      'faq.a2': 'Android e iOS, com suporte a desktop. Um único tenant acessível de vários aparelhos — os dados de cada loja ficam sempre coerentes.',
      'faq.q3': 'Posso gerir várias lojas e funcionários?',
      'faq.a3': 'Sim. Cada conta (tenant) gere várias lojas e funcionários, com escopo de dados isolado por loja. O add-on de Transferências move estoque entre lojas, e o de Funcionários controla ponto, comissões e metas.',
      'faq.q4': 'Que moedas e idiomas são suportados?',
      'faq.a4': 'Moedas: MZN (Metical), BRL, USD e EUR — escolhidas pelo dono da conta. Idiomas: português, inglês e francês, em todo o aplicativo.',
      'faq.q5': 'Os meus dados estão seguros?',
      'faq.a5': 'Sim. Autenticação com 2FA (TOTP), bloqueio biométrico, sessões encriptadas no aparelho, criptografia AES-GCM dos dados offline e Row Level Security no servidor — cada loja só vê os próprios dados.',
      'faq.q6': 'Quanto custa?',
      'faq.a6': 'O plano Grátis cobre a operação essencial de uma loja. Os planos Profissional e Empresarial desbloqueiam add-ons, multi-loja e suporte prioritário — veja a secção de Planos.',

      'ct.kicker': 'Contacto',
      'ct.title': 'Fale connosco',
      'ct.subtitle': 'Dúvidas, demonstração ou planos — respondemos em 1 dia útil.',
      'ct.name': 'Nome',
      'ct.name.ph': 'O seu nome',
      'ct.biz': 'Negócio',
      'ct.biz.ph': 'Nome da loja',
      'ct.email': 'E-mail',
      'ct.email.ph': 'voce@exemplo.com',
      'ct.msg': 'Mensagem',
      'ct.msg.ph': 'Como podemos ajudar?',
      'ct.send': 'Enviar mensagem',
      'ct.note': 'Ao enviar, abre-se o seu aplicativo de e-mail com a mensagem pronta.',
      'ct.subject': 'Contacto do site',
      'ct.wa.t': 'WhatsApp',
      'ct.wa.d': 'Resposta rápida de segunda a sábado, 8h–18h (CAT).',
      'ct.mail.t': 'E-mail',
      'ct.docs.t': 'Documentação',
      'ct.docs.d': 'Guias do utilizador e solução de problemas em pt, en e fr — também dentro do aplicativo.',

      'cta.title.a': 'Pronto para organizar o seu negócio',
      'cta.title.b': ' em minutos?',
      'cta.sub': 'Descarregue o TAREQO e faça a primeira venda hoje.',
      'cta.btn': 'Descarregar grátis',
      'cta.btn.ios': 'Descarregar para iOS',

      'ft.tagline': 'O ERP do comerciante — estoque, vendas, caixa e relatórios, offline e na nuvem.',
      'ft.product': 'Produto',
      'ft.resources': 'Recursos',
      'ft.res1': 'Documentação (PT)',
      'ft.res2': 'Documentation (EN)',
      'ft.res3': 'Documentation (FR)',
      'ft.res4': 'Guia do utilizador',
      'ft.company': 'Empresa',
      'ft.changelog': 'Novidades',
      'ft.lic': 'Licença MIT',
      'ft.rights': '© 2026 TAREQO. Todos os direitos reservados.',
      'ft.made': 'Feito com Flutter · Clean Architecture · Supabase'
    },

    /* ─────────────────────────── EN ─────────────────────────── */
    en: {
      'nav.features': 'Features',
      'nav.addons': 'Add-ons',
      'nav.how': 'How it works',
      'nav.pricing': 'Pricing',
      'nav.faq': 'FAQ',
      'nav.contact': 'Contact',
      'nav.cta': 'Download',
      'nav.menuOpen': 'Open menu',
      'nav.menuClose': 'Close menu',

      'hero.badge': 'Offline-first ERP for merchants',
      'hero.title.a': 'Run your whole business,',
      'hero.title.b': 'in the palm of your hand.',
      'hero.subtitle': 'Inventory, sales, purchases, cash flow, store credit and reports — in one app. Works 100% offline and syncs securely whenever you have internet.',
      'hero.cta1': 'Download for Android',
      'hero.cta.ios': 'Download for iOS',
      'hero.cta2': 'See features',
      'hero.note': 'No credit card · Free plan · pt / en / fr',

      'stats.langs': 'languages (pt · en · fr)',
      'stats.currencies': 'currencies (MZN · BRL · USD · EUR)',
      'stats.offline': 'offline-first',
      'stats.security': 'biometrics + MFA',

      'ph.today': 'Today',
      'ph.sales': 'Sales',
      'ph.cash': 'Cash',
      'ph.receivable': 'Receivable',
      'ph.week': 'This week’s sales',
      'ph.viewall': 'View all',
      'ph.lowstock': 'Low stock',

      't1': 'Works 100% offline',
      't2': 'Multi-store & team',
      't3': 'pt · en · fr',
      't4': 'MZN · BRL · USD · EUR',
      't5': 'Biometrics + 2FA',
      't6': 'PDF & WhatsApp',

      'modules.kicker': 'Modules',
      'modules.title': 'Everything your business needs',
      'modules.subtitle': 'Integrated modules that work together — every sale decrements stock and posts to cash in a single atomic transaction.',

      'm1.t': 'Dashboard',
      'm1.d': 'Real-time KPIs for sales, cash, receivables and stock, with quick actions and low-stock alerts.',
      'm2.t': 'Products',
      'm2.d': 'Catalog with search, PLU/codes for scales, photos and validated prices. Barcode scanning built in.',
      'm3.t': 'Sales',
      'm3.d': 'Fast cart with payment methods. Sale, stock decrement and cash in one atomic transaction.',
      'm4.t': 'Purchases',
      'm4.d': 'Receive goods with automatic stock updates and the cash outflow recorded.',
      'm5.t': 'Finance',
      'm5.d': 'Cash flow per period, detailed inflows and outflows, and one-tap collection of open balances.',
      'm6.t': 'Credit (tabs)',
      'm6.d': 'Receivables and payables with due dates, partial or full settlement, and a complete payment history.',
      'm7.t': 'Stores & Team',
      'm7.d': 'Manage multiple stores and employees per tenant, with the plan, language and currency you choose.',
      'm8.t': 'Reports',
      'm8.d': 'Sales, product and financial reports for fast decisions — with PDF export.',

      'addons.kicker': 'Add-ons',
      'addons.title': 'Grow with add-ons',
      'addons.subtitle': 'Enable only what your business needs. Managed from the admin panel, available depending on your plan.',
      'addons.soon': 'Coming soon',

      'a1.t': 'Custom Invoices',
      'a1.d': 'Invoices with your logo and colors, sequential numbering per store, PDF export and WhatsApp sharing.',
      'a2.t': 'Quotations',
      'a2.d': 'Create and send quotations with customizable templates and track their status: draft → sent → accepted/rejected.',
      'a3.t': 'Advanced Reports',
      'a3.d': 'Financial KPIs, stock by product, cash flow and low-stock alerts in one executive view.',
      'a4.t': 'Employee Management',
      'a4.d': 'Clock in/out, commissions calculated on real sales, and monthly targets with progress bars.',
      'a5.t': 'Store Transfers',
      'a5.d': 'Move stock between stores with decrement at the origin, receipt at the destination, and a full transfer history.',
      'a6.t': 'M-Pesa & E-Mola',
      'a6.d': 'Mobile money payment reconciliation with confirm or reject — integration on the way.',

      'how.kicker': 'How it works',
      'how.title': 'Selling in minutes',
      'how.subtitle': 'No complicated setup, no days of training. Three steps and you’re invoicing.',

      's1.t': 'Create your account',
      's1.d': 'Download the app, sign up and set up your store — language and currency of your choice.',
      's2.t': 'Add your products',
      's2.d': 'Register your catalog with prices and stock — type, photograph or scan the barcode.',
      's3.t': 'Sell and track',
      's3.d': 'Every sale decrements stock and posts to cash. The dashboard shows your business pulse in real time.',

      'sec.kicker': 'Security',
      'sec.title': 'Your data, protected end to end',
      'sec.subtitle': 'Enterprise-grade security, simple to use — even on a phone.',

      'se1.t': 'Tenant isolation',
      'se1.d': 'Row Level Security on the server: each store only accesses its own data — enforced by the database, not the app.',
      'se2.t': 'Biometrics + MFA',
      'se2.d': 'Fingerprint/face lock when you step away, and two-factor authentication (TOTP) with a QR code.',
      'se3.t': 'Encrypted secrets',
      'se3.d': 'Sessions stored in the device’s Keychain/Keystore and offline payloads encrypted with AES-GCM.',
      'se4.t': 'Atomic transactions',
      'se4.d': 'Sale = stock − cash in a single transaction. Atomic RPCs on the server prevent half-written data.',

      'pr.kicker': 'Pricing',
      'pr.title': 'Start free, grow when you want',
      'pr.subtitle': 'From notebook to professional control — every plan unlocks more management for your business.',
      'pr.month': '/month',
      'pr.popular': 'Most chosen',
      'pr.disclaimer': 'Prices in Meticais, VAT included. Cancel anytime.',

      'pr.p1.t': 'Free',
      'pr.p1.d': 'For small businesses starting to organize their operation.',
      'pr.p1.f1': 'Sales dashboard with an overview at a glance',
      'pr.p1.f2': 'Product and category registration',
      'pr.p1.f3': 'Basic stock control',
      'pr.p1.f4': 'Sales recording',
      'pr.p1.f5': 'Customer management',
      'pr.p1.f6': 'Cash control',
      'pr.p1.f7': 'Store credit (fiado)',
      'pr.p1.f8': 'Transaction history',
      'pr.p1.f9': 'Works offline',
      'pr.p1.f10': 'Automatic sync when internet is available',
      'pr.p1.f11': 'Languages: Portuguese, English and French',
      'pr.p1.f12': 'Currencies: MZN, BRL, USD and EUR',
      'pr.cta1': 'Start for free',
      'pr.p1.note': 'Ideal for replacing notebooks, spreadsheets and manual processes with a simple, organized solution.',

      'pr.p2.t': 'Professional',
      'pr.p2.d': 'For businesses that are growing and need more control over their operation.',
      'pr.p2.priceNote': 'Everything you need to manage sales, stock, team, cash and customers more efficiently.',
      'pr.p2.f1': 'Advanced reports for faster decisions',
      'pr.p2.f2': 'Professional invoices and quotations',
      'pr.p2.f3': 'Team management and permissions',
      'pr.p2.f4': 'Multiple-store control',
      'pr.p2.f5': 'Stock transfers between units',
      'pr.p2.f6': 'Detailed financial management',
      'pr.p2.f7': 'Secure cloud sync',
      'pr.p2.f8': 'Priority WhatsApp support',
      'pr.cta2': 'Get started with Professional',
      'pr.p2.note': 'The complete plan to transform the daily management of your business.',

      'pr.p3.t': 'Business',
      'pr.p3.d': 'For chains, distributors and companies that need advanced control, customization and dedicated support.',
      'pr.p3.price': 'On request',
      'pr.p3.priceNote': 'Pricing based on number of stores, users, transaction volume, integrations, support level and customization.',
      'pr.p3.f1': 'Everything in Professional, plus:',
      'pr.p3.f2': 'Multiple stores and units with custom user counts',
      'pr.p3.f3': 'Advanced permissions and approval flows',
      'pr.p3.f4': 'Consolidated reports and store-to-store comparison',
      'pr.p3.f5': 'Custom KPIs and contract-based integrations',
      'pr.p3.f6': 'M-Pesa and E-Mola, when available',
      'pr.p3.f7': 'Onboarding, data migration and team training',
      'pr.p3.f8': 'Dedicated priority support and higher capacity',
      'pr.cta3': 'Talk to a specialist',
      'pr.p3.note': 'A management solution built to keep up with your company’s growth.',

      'pr.cmp.title': 'Quick comparison',
      'pr.cmp.feat': 'Feature',
      'pr.cmp.yes': 'Yes',
      'pr.cmp.no': 'No',
      'pr.cmp.basic': 'Basic',
      'pr.cmp.advanced': 'Advanced',
      'pr.cmp.advPerm': 'Advanced',
      'pr.cmp.custom': 'Custom',
      'pr.cmp.whenAvail': 'When available',
      'pr.cmp.byContract': 'Per contract',
      'pr.cmp.std': 'Standard',
      'pr.cmp.waPriority': 'Priority via WhatsApp',
      'pr.cmp.dedicated': 'Dedicated',
      'pr.cmp.guided': 'Guided',
      'pr.cmp.assisted': 'Assisted',
      'pr.cmp.personalized': 'Personalized',
      'pr.cmp.optional': 'Optional',
      'pr.cmp.inContract': 'Included per contract',
      'pr.cmp.r1': 'Sales and cash dashboard',
      'pr.cmp.r2': 'Product management',
      'pr.cmp.r3': 'Stock control',
      'pr.cmp.r4': 'Sales recording',
      'pr.cmp.r5': 'Store credit',
      'pr.cmp.r6': 'Offline operation',
      'pr.cmp.r7': 'Cloud sync',
      'pr.cmp.r8': 'Advanced reports',
      'pr.cmp.r9': 'Custom invoices',
      'pr.cmp.r10': 'PDF export',
      'pr.cmp.r11': 'Quotations and estimates',
      'pr.cmp.r12': 'Employee management',
      'pr.cmp.r13': 'Role-based permissions',
      'pr.cmp.r14': 'Multi-store management',
      'pr.cmp.r15': 'Store-to-store transfers',
      'pr.cmp.r16': 'Commissions and goals',
      'pr.cmp.r17': 'M-Pesa and E-Mola',
      'pr.cmp.r18': 'Support',
      'pr.cmp.r19': 'Onboarding',
      'pr.cmp.r20': 'Data migration',

      'ts.kicker': 'Who uses it',
      'ts.title': 'Built for the merchant',
      'ts.subtitle': 'From kiosks to store chains — serious management, zero paperwork.',
      'ts.q1': '“It used to be notebook and calculator. Now I see the day’s cash in one tap — and know exactly what’s missing in stock.”',
      'ts.a1': 'Amélia C. — Convenience store, Maputo',
      'ts.q2': '“The internet drops and TAREQO keeps selling. When it’s back, everything syncs by itself.”',
      'ts.a2': 'Yusuf M. — Market, Nampula',
      'ts.q3': '“I send PDF quotations on WhatsApp and won customers I used to lose for answering too late.”',
      'ts.a3': 'Sofia R. — Boutique, Beira',

      'faq.title': 'Frequently asked questions',
      'faq.q1': 'Does TAREQO work without internet?',
      'faq.a1': 'Yes. The whole operation — sales, stock, cash, credit — works 100% offline on your device (SQLite). When internet returns, data syncs automatically and securely.',
      'faq.q2': 'Which platforms is it available on?',
      'faq.a2': 'Android and iOS, with desktop support. One tenant accessible from several devices — each store’s data always stays consistent.',
      'faq.q3': 'Can I manage multiple stores and employees?',
      'faq.a3': 'Yes. Each account (tenant) manages multiple stores and employees, with the data scope isolated per store. The Store Transfers add-on moves stock between stores, and Employee Management tracks time clock, commissions and targets.',
      'faq.q4': 'Which currencies and languages are supported?',
      'faq.a4': 'Currencies: MZN (Metical), BRL, USD and EUR — chosen by the account owner. Languages: Portuguese, English and French, throughout the app.',
      'faq.q5': 'Is my data safe?',
      'faq.a5': 'Yes. 2FA authentication (TOTP), biometric lock, encrypted sessions on the device, AES-GCM encryption of offline data and Row Level Security on the server — each store only sees its own data.',
      'faq.q6': 'How much does it cost?',
      'faq.a6': 'The Free plan covers the essential operation of one store. The Professional and Business plans unlock add-ons, multi-store and priority support — see the Pricing section.',

      'ct.kicker': 'Contact',
      'ct.title': 'Talk to us',
      'ct.subtitle': 'Questions, demo or plans — we reply within 1 business day.',
      'ct.name': 'Name',
      'ct.name.ph': 'Your name',
      'ct.biz': 'Business',
      'ct.biz.ph': 'Store name',
      'ct.email': 'Email',
      'ct.email.ph': 'you@example.com',
      'ct.msg': 'Message',
      'ct.msg.ph': 'How can we help?',
      'ct.send': 'Send message',
      'ct.note': 'On submit, your email app opens with the message ready to send.',
      'ct.subject': 'Website contact',
      'ct.wa.t': 'WhatsApp',
      'ct.wa.d': 'Quick replies Monday to Saturday, 8am–6pm (CAT).',
      'ct.mail.t': 'Email',
      'ct.docs.t': 'Documentation',
      'ct.docs.d': 'User guides and troubleshooting in pt, en and fr — also inside the app.',

      'cta.title.a': 'Ready to get your business organized',
      'cta.title.b': ' in minutes?',
      'cta.sub': 'Download TAREQO and make your first sale today.',
      'cta.btn': 'Download free',
      'cta.btn.ios': 'Download for iOS',

      'ft.tagline': 'The merchant’s ERP — stock, sales, cash and reports, offline and in the cloud.',
      'ft.product': 'Product',
      'ft.resources': 'Resources',
      'ft.res1': 'Documentation (PT)',
      'ft.res2': 'Documentation (EN)',
      'ft.res3': 'Documentation (FR)',
      'ft.res4': 'User guide',
      'ft.company': 'Company',
      'ft.changelog': 'What’s new',
      'ft.lic': 'MIT License',
      'ft.rights': '© 2026 TAREQO. All rights reserved.',
      'ft.made': 'Built with Flutter · Clean Architecture · Supabase'
    },

    /* ─────────────────────────── FR ─────────────────────────── */
    fr: {
      'nav.features': 'Fonctionnalités',
      'nav.addons': 'Add-ons',
      'nav.how': 'Comment ça marche',
      'nav.pricing': 'Tarifs',
      'nav.faq': 'FAQ',
      'nav.contact': 'Contact',
      'nav.cta': 'Télécharger',
      'nav.menuOpen': 'Ouvrir le menu',
      'nav.menuClose': 'Fermer le menu',

      'hero.badge': 'ERP offline-first pour commerçants',
      'hero.title.a': 'Gérez tout votre commerce,',
      'hero.title.b': 'dans le creux de la main.',
      'hero.subtitle': 'Stock, ventes, achats, trésorerie, crédit client et rapports — dans une seule application. Fonctionne 100 % hors ligne et se synchronise en toute sécurité dès que vous avez Internet.',
      'hero.cta1': 'Télécharger pour Android',
      'hero.cta.ios': 'Télécharger pour iOS',
      'hero.cta2': 'Voir les fonctionnalités',
      'hero.note': 'Sans carte bancaire · Plan gratuit · pt / en / fr',

      'stats.langs': 'langues (pt · en · fr)',
      'stats.currencies': 'devises (MZN · BRL · USD · EUR)',
      'stats.offline': 'priorité hors ligne',
      'stats.security': 'biométrie + MFA',

      'ph.today': 'Aujourd’hui',
      'ph.sales': 'Ventes',
      'ph.cash': 'Caisse',
      'ph.receivable': 'À recevoir',
      'ph.week': 'Ventes de la semaine',
      'ph.viewall': 'Tout voir',
      'ph.lowstock': 'Stock faible',

      't1': 'Fonctionne 100 % hors ligne',
      't2': 'Multi-magasins & équipe',
      't3': 'pt · en · fr',
      't4': 'MZN · BRL · USD · EUR',
      't5': 'Biométrie + 2FA',
      't6': 'PDF & WhatsApp',

      'modules.kicker': 'Modules',
      'modules.title': 'Tout ce dont votre commerce a besoin',
      'modules.subtitle': 'Des modules intégrés qui travaillent ensemble — chaque vente décrémente le stock et alimente la caisse en une seule transaction atomique.',

      'm1.t': 'Tableau de bord',
      'm1.d': 'KPI en temps réel des ventes, caisse, créances et stock, avec actions rapides et alertes de stock faible.',
      'm2.t': 'Produits',
      'm2.d': 'Catalogue avec recherche, codes/PLU pour balances, photos et prix validés. Lecture de codes-barres.',
      'm3.t': 'Ventes',
      'm3.d': 'Panier rapide avec modes de paiement. Vente, décrément de stock et caisse en une seule transaction atomique.',
      'm4.t': 'Achats',
      'm4.d': 'Réception de marchandises avec mise à jour automatique du stock et sortie de caisse enregistrée.',
      'm5.t': 'Finances',
      'm5.d': 'Trésorerie par période, entrées et sorties détaillées, et encaissement des impayés en un geste.',
      'm6.t': 'Crédit',
      'm6.d': 'À recevoir et à payer avec échéance, règlement partiel ou total, et historique complet des paiements.',
      'm7.t': 'Magasins & Équipe',
      'm7.d': 'Gestion de plusieurs magasins et employés par tenant, avec plan, langue et devise au choix.',
      'm8.t': 'Rapports',
      'm8.d': 'Rapports de ventes, produits et finances pour décider vite — export PDF inclus.',

      'addons.kicker': 'Add-ons',
      'addons.title': 'Étendez avec des add-ons',
      'addons.subtitle': 'Activez uniquement ce dont votre commerce a besoin. Gérés depuis le panneau d’administration, disponibles selon le plan.',
      'addons.soon': 'Bientôt',

      'a1.t': 'Factures personnalisées',
      'a1.d': 'Factures à votre logo et vos couleurs, numérotation séquentielle par magasin, export PDF et envoi par WhatsApp.',
      'a2.t': 'Devis',
      'a2.d': 'Créez et envoyez des devis avec modèles personnalisables et suivez leur statut : brouillon → envoyé → accepté/refusé.',
      'a3.t': 'Rapports avancés',
      'a3.d': 'KPI financiers, produits en stock, trésorerie et alertes de stock faible dans une vue exécutive.',
      'a4.t': 'Gestion des employés',
      'a4.d': 'Pointage entrée/sortie, commissions calculées sur les ventes réelles et objectifs mensuels avec barre de progression.',
      'a5.t': 'Transferts entre magasins',
      'a5.d': 'Déplacez le stock entre magasins avec décrément à l’origine, réception à la destination, et historique complet des transferts.',
      'a6.t': 'M-Pesa & E-Mola',
      'a6.d': 'Rapprochement des paiements mobile money avec confirmation ou rejet — intégration en cours.',

      'how.kicker': 'Comment ça marche',
      'how.title': 'Vendez en quelques minutes',
      'how.subtitle': 'Pas d’installation compliquée, pas de formation interminable. Trois étapes et vous facturez.',

      's1.t': 'Créez votre compte',
      's1.d': 'Téléchargez l’application, inscrivez-vous et configurez votre magasin — langue et devise au choix.',
      's2.t': 'Ajoutez vos produits',
      's2.d': 'Enregistrez votre catalogue avec prix et stock — saisissez, photographiez ou scannez le code-barres.',
      's3.t': 'Vendez et suivez',
      's3.d': 'Chaque vente décrémente le stock et alimente la caisse. Le tableau de bord suit le pouls de votre activité en temps réel.',

      'sec.kicker': 'Sécurité',
      'sec.title': 'Vos données, protégées de bout en bout',
      'sec.subtitle': 'Une sécurité de niveau entreprise, simple d’utilisation — même sur un téléphone.',

      'se1.t': 'Isolation par tenant',
      'se1.d': 'Row Level Security côté serveur : chaque magasin n’accède qu’à ses propres données — garanti par la base, pas par l’application.',
      'se2.t': 'Biométrie + MFA',
      'se2.d': 'Verrouillage par empreinte/visage quand vous vous éloignez, et authentification à deux facteurs (TOTP) avec QR code.',
      'se3.t': 'Secrets chiffrés',
      'se3.d': 'Sessions stockées dans le Keychain/Keystore de l’appareil et données hors ligne chiffrées en AES-GCM.',
      'se4.t': 'Transactions atomiques',
      'se4.d': 'Vente = stock − caisse en une seule transaction. Des RPC atomiques côté serveur empêchent les écritures partielles.',

      'pr.kicker': 'Tarifs',
      'pr.title': 'Commencez gratuitement, évoluez à votre rythme',
      'pr.subtitle': 'Du carnet au contrôle professionnel — chaque plan débloque plus de gestion pour votre commerce.',
      'pr.month': '/mois',
      'pr.popular': 'Le plus choisi',
      'pr.disclaimer': 'Prix en Meticais, TVA incluse. Résiliez à tout moment.',

      'pr.p1.t': 'Gratuit',
      'pr.p1.d': 'Pour les petits commerces qui commencent à organiser leur activité.',
      'pr.p1.f1': 'Tableau de bord avec vue d’ensemble des ventes',
      'pr.p1.f2': 'Enregistrement de produits et catégories',
      'pr.p1.f3': 'Gestion de stock basique',
      'pr.p1.f4': 'Enregistrement des ventes',
      'pr.p1.f5': 'Gestion des clients',
      'pr.p1.f6': 'Contrôle de caisse',
      'pr.p1.f7': 'Crédit client',
      'pr.p1.f8': 'Historique des transactions',
      'pr.p1.f9': 'Fonctionne hors ligne',
      'pr.p1.f10': 'Synchronisation automatique dès qu’Internet est disponible',
      'pr.p1.f11': 'Langues : portugais, anglais et français',
      'pr.p1.f12': 'Devises : MZN, BRL, USD et EUR',
      'pr.cta1': 'Commencer gratuitement',
      'pr.p1.note': 'Idéal pour remplacer carnets, tableurs et processus manuels par une solution simple et organisée.',

      'pr.p2.t': 'Professionnel',
      'pr.p2.d': 'Pour les commerces en croissance qui ont besoin de plus de contrôle sur l’activité.',
      'pr.p2.priceNote': 'Tout ce qu’il faut pour gérer ventes, stock, équipe, caisse et clients avec plus d’efficacité.',
      'pr.p2.f1': 'Rapports avancés pour décider plus vite',
      'pr.p2.f2': 'Factures et devis professionnels',
      'pr.p2.f3': 'Gestion d’équipe et permissions',
      'pr.p2.f4': 'Contrôle de plusieurs magasins',
      'pr.p2.f5': 'Transferts de stock entre unités',
      'pr.p2.f6': 'Gestion financière détaillée',
      'pr.p2.f7': 'Synchronisation cloud sécurisée',
      'pr.p2.f8': 'Support prioritaire par WhatsApp',
      'pr.cta2': 'Choisir Professionnel',
      'pr.p2.note': 'Le plan complet pour transformer la gestion quotidienne de votre commerce.',

      'pr.p3.t': 'Entreprise',
      'pr.p3.d': 'Pour les réseaux, distributeurs et entreprises qui ont besoin d’un contrôle avancé, de personnalisation et d’un support dédié.',
      'pr.p3.price': 'Sur devis',
      'pr.p3.priceNote': 'Valeur définie selon le nombre de magasins, d’utilisateurs, le volume de transactions, les intégrations, le support et la personnalisation.',
      'pr.p3.f1': 'Tout du plan Professionnel, plus :',
      'pr.p3.f2': 'Magasins et unités multiples avec utilisateurs personnalisés',
      'pr.p3.f3': 'Permissions avancées et flux d’approbation',
      'pr.p3.f4': 'Rapports consolidés et comparaison entre magasins',
      'pr.p3.f5': 'Indicateurs personnalisés et intégrations sur contrat',
      'pr.p3.f6': 'M-Pesa et E-Mola, selon disponibilité',
      'pr.p3.f7': 'Onboarding, migration de données et formation de l’équipe',
      'pr.p3.f8': 'Support prioritaire dédié et capacité supérieure',
      'pr.cta3': 'Parler à un spécialiste',
      'pr.p3.note': 'Une solution de gestion prête à accompagner l’expansion de votre entreprise.',

      'pr.cmp.title': 'Comparaison rapide',
      'pr.cmp.feat': 'Fonctionnalité',
      'pr.cmp.yes': 'Oui',
      'pr.cmp.no': 'Non',
      'pr.cmp.basic': 'Basique',
      'pr.cmp.advanced': 'Avancée',
      'pr.cmp.advPerm': 'Avancée',
      'pr.cmp.custom': 'Personnalisée',
      'pr.cmp.whenAvail': 'Selon disponibilité',
      'pr.cmp.byContract': 'Selon contrat',
      'pr.cmp.std': 'Standard',
      'pr.cmp.waPriority': 'Prioritaire par WhatsApp',
      'pr.cmp.dedicated': 'Dédié',
      'pr.cmp.guided': 'Guidé',
      'pr.cmp.assisted': 'Assisté',
      'pr.cmp.personalized': 'Personnalisé',
      'pr.cmp.optional': 'Optionnelle',
      'pr.cmp.inContract': 'Incluse selon contrat',
      'pr.cmp.r1': 'Tableau de bord ventes et caisse',
      'pr.cmp.r2': 'Gestion des produits',
      'pr.cmp.r3': 'Gestion du stock',
      'pr.cmp.r4': 'Enregistrement des ventes',
      'pr.cmp.r5': 'Crédit client',
      'pr.cmp.r6': 'Fonctionnement hors ligne',
      'pr.cmp.r7': 'Synchronisation cloud',
      'pr.cmp.r8': 'Rapports avancés',
      'pr.cmp.r9': 'Factures personnalisées',
      'pr.cmp.r10': 'Exportation PDF',
      'pr.cmp.r11': 'Devis et chiffrages',
      'pr.cmp.r12': 'Gestion des employés',
      'pr.cmp.r13': 'Permissions par rôle',
      'pr.cmp.r14': 'Gestion multi-magasins',
      'pr.cmp.r15': 'Transferts entre magasins',
      'pr.cmp.r16': 'Commissions et objectifs',
      'pr.cmp.r17': 'M-Pesa et E-Mola',
      'pr.cmp.r18': 'Support',
      'pr.cmp.r19': 'Onboarding',
      'pr.cmp.r20': 'Migration de données',

      'ts.kicker': 'Qui l’utilise',
      'ts.title': 'Conçu pour le commerçant',
      'ts.subtitle': 'Des kiosques aux réseaux de magasins — une gestion sérieuse, sans paperasse.',
      'ts.q1': '« Avant, c’était carnet et calculatrice. Maintenant je vois la caisse du jour en un geste — et je sais exactement ce qu’il manque en stock. »',
      'ts.a1': 'Amélia C. — Supérette, Maputo',
      'ts.q2': '« Internet tombe et TAREQO continue de vendre. Quand il revient, tout se synchronise tout seul. »',
      'ts.a2': 'Yusuf M. — Marché, Nampula',
      'ts.q3': '« J’envoie des devis en PDF par WhatsApp et j’ai gagné des clients à qui je ne pouvais pas répondre à temps. »',
      'ts.a3': 'Sofia R. — Boutique, Beira',

      'faq.title': 'Questions fréquentes',
      'faq.q1': 'TAREQO fonctionne-t-il sans Internet ?',
      'faq.a1': 'Oui. Toute l’opération — ventes, stock, caisse, crédit — fonctionne 100 % hors ligne sur votre appareil (SQLite). Quand Internet revient, les données se synchronisent automatiquement et en toute sécurité.',
      'faq.q2': 'Sur quelles plates-formes est-il disponible ?',
      'faq.a2': 'Android et iOS, avec prise en charge desktop. Un seul tenant accessible depuis plusieurs appareils — les données de chaque magasin restent toujours cohérentes.',
      'faq.q3': 'Puis-je gérer plusieurs magasins et employés ?',
      'faq.a3': 'Oui. Chaque compte (tenant) gère plusieurs magasins et employés, avec un périmètre de données isolé par magasin. L’add-on Transferts déplace le stock entre magasins, et celui des Employés gère pointage, commissions et objectifs.',
      'faq.q4': 'Quelles devises et langues sont prises en charge ?',
      'faq.a4': 'Devises : MZN (Metical), BRL, USD et EUR — choisies par le propriétaire du compte. Langues : portugais, anglais et français, dans toute l’application.',
      'faq.q5': 'Mes données sont-elles en sécurité ?',
      'faq.a5': 'Oui. Authentification 2FA (TOTP), verrouillage biométrique, sessions chiffrées sur l’appareil, chiffrement AES-GCM des données hors ligne et Row Level Security côté serveur — chaque magasin ne voit que ses données.',
      'faq.q6': 'Combien ça coûte ?',
      'faq.a6': 'Le plan Gratuit couvre l’essentiel d’un magasin. Les plans Professionnel et Entreprise débloquent les add-ons, le multi-magasins et le support prioritaire — voir la section Tarifs.',

      'ct.kicker': 'Contact',
      'ct.title': 'Parlons-en',
      'ct.subtitle': 'Questions, démo ou tarifs — nous répondons en 1 jour ouvré.',
      'ct.name': 'Nom',
      'ct.name.ph': 'Votre nom',
      'ct.biz': 'Commerce',
      'ct.biz.ph': 'Nom du magasin',
      'ct.email': 'E-mail',
      'ct.email.ph': 'vous@exemple.com',
      'ct.msg': 'Message',
      'ct.msg.ph': 'Comment pouvons-nous aider ?',
      'ct.send': 'Envoyer le message',
      'ct.note': 'À l’envoi, votre application e-mail s’ouvre avec le message prêt.',
      'ct.subject': 'Contact du site',
      'ct.wa.t': 'WhatsApp',
      'ct.wa.d': 'Réponse rapide du lundi au samedi, 8h–18h (CAT).',
      'ct.mail.t': 'E-mail',
      'ct.docs.t': 'Documentation',
      'ct.docs.d': 'Guides utilisateur et dépannage en pt, en et fr — aussi dans l’application.',

      'cta.title.a': 'Prêt à organiser votre commerce',
      'cta.title.b': ' en quelques minutes ?',
      'cta.sub': 'Téléchargez TAREQO et réalisez votre première vente aujourd’hui.',
      'cta.btn': 'Télécharger gratuitement',
      'cta.btn.ios': 'Télécharger pour iOS',

      'ft.tagline': 'L’ERP du commerçant — stock, ventes, caisse et rapports, hors ligne et dans le cloud.',
      'ft.product': 'Produit',
      'ft.resources': 'Ressources',
      'ft.res1': 'Documentation (PT)',
      'ft.res2': 'Documentation (EN)',
      'ft.res3': 'Documentation (FR)',
      'ft.res4': 'Guide utilisateur',
      'ft.company': 'Entreprise',
      'ft.changelog': 'Nouveautés',
      'ft.lic': 'Licence MIT',
      'ft.rights': '© 2026 TAREQO. Tous droits réservés.',
      'ft.made': 'Réalisé avec Flutter · Clean Architecture · Supabase'
    }
  };

  var current = DEFAULT_LANG;

  function normalize(raw) {
    if (!raw) return null;
    var lang = String(raw).toLowerCase();
    for (var i = 0; i < LANGS.length; i++) {
      if (lang === LANGS[i] || lang.indexOf(LANGS[i] + '-') === 0) return LANGS[i];
    }
    return null;
  }

  function stored() {
    try { return global.localStorage.getItem(STORAGE_KEY); }
    catch (e) { return null; }
  }

  /** Idioma pedido no URL (?lang=xx) — tem prioridade máxima (links partilháveis). */
  function paramLang() {
    try {
      var search = global.location && global.location.search;
      if (!search) return null;
      return normalize(new URLSearchParams(search).get('lang'));
    } catch (e) {
      return null;
    }
  }

  function detect() {
    return paramLang()
      || normalize(stored())
      || normalize(global.navigator && global.navigator.language)
      || DEFAULT_LANG;
  }

  /** Mantém ?lang= no URL para que a vista atual seja partilhável. */
  function syncUrl() {
    try {
      if (!global.location || !global.history
        || typeof global.history.replaceState !== 'function') return;
      var url = new URL(global.location.href);
      var inUrl = url.searchParams.get('lang');
      if (current === DEFAULT_LANG) {
        // pt é o conteúdo canónico — URL fica limpo
        if (inUrl !== null) {
          url.searchParams.delete('lang');
          global.history.replaceState(null, '', url.href);
        }
      } else if (inUrl !== current) {
        url.searchParams.set('lang', current);
        global.history.replaceState(null, '', url.href);
      }
    } catch (e) { /* file:// ou sem History API — ignora */ }
  }

  function lookup(lang, key) {
    var dict = DICT[lang];
    return dict ? dict[key] : undefined;
  }

  /** Traduz uma chave com fallback para pt. */
  function t(key, lang) {
    var value = lookup(lang || current, key);
    if (value === undefined) value = lookup(DEFAULT_LANG, key);
    return value;
  }

  /** Aplica um idioma a toda a página (texto, placeholders, <title>, meta). */
  function apply(lang) {
    current = normalize(lang) || DEFAULT_LANG;
    var dict = DICT[current];

    global.document.documentElement.setAttribute('lang', current);

    var meta = META[current];
    if (meta) {
      var title = global.document.querySelector('title');
      if (title && meta.title) title.textContent = meta.title;
      var desc = global.document.querySelector('meta[name="description"]');
      if (desc && meta.description) desc.setAttribute('content', meta.description);
    }

    var nodes = global.document.querySelectorAll('[data-i18n]');
    for (var i = 0; i < nodes.length; i++) {
      var key = nodes[i].getAttribute('data-i18n');
      var value = dict[key] !== undefined ? dict[key] : lookup(DEFAULT_LANG, key);
      if (value !== undefined && value !== null) nodes[i].textContent = value;
    }

    var phNodes = global.document.querySelectorAll('[data-i18n-ph]');
    for (var j = 0; j < phNodes.length; j++) {
      var phKey = phNodes[j].getAttribute('data-i18n-ph');
      var phValue = dict[phKey] !== undefined ? dict[phKey] : lookup(DEFAULT_LANG, phKey);
      if (phValue !== undefined && phValue !== null) phNodes[j].setAttribute('placeholder', phValue);
    }

    var btns = global.document.querySelectorAll('.lang-btn');
    for (var k = 0; k < btns.length; k++) {
      btns[k].classList.toggle('is-active', btns[k].getAttribute('data-lang') === current);
    }

    try { global.localStorage.setItem(STORAGE_KEY, current); }
    catch (e) { /* modo privado — ignora */ }

    // Reflete o idioma no URL (?lang=xx) para links partilháveis
    syncUrl();

    // Notifica ouvintes (ex.: main.js atualiza aria-labels do menu)
    if (typeof global.CustomEvent === 'function') {
      global.document.dispatchEvent(new global.CustomEvent('tareqo:lang', { detail: { lang: current } }));
    }
  }

  current = detect();

  var api = {
    apply: apply,
    t: t,
    detect: detect,
    get lang() { return current; },
    DICT: DICT
  };

  global.TAREQO_I18N = api;
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
})(typeof window !== 'undefined' ? window : typeof globalThis !== 'undefined' ? globalThis : this);
