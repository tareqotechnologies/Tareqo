// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Dumbhanengue ERP';

  @override
  String get onboardingTitle => 'Bem-vindo!';

  @override
  String get onboardingHeading => 'Ative seu negócio no ERP';

  @override
  String get onboardingSubtitle =>
      'Escolha um plano, informe o nome do seu negócio e defina a moeda e o idioma. Seu acesso será liberado após a aprovação (prazo de até 24h).';

  @override
  String get onboardingBusinessLabel => 'Nome do negócio';

  @override
  String get onboardingBusinessError => 'Informe o nome do seu negócio.';

  @override
  String get onboardingPlanLabel => 'Escolha o plano';

  @override
  String get onboardingPlansError => 'Não foi possível carregar os planos.';

  @override
  String onboardingPlanDetails(int stores, int employees) {
    return '$stores loja(s) · $employees funcionário(s)';
  }

  @override
  String get onboardingSubmit => 'Solicitar acesso';

  @override
  String onboardingSuccess(String business) {
    return 'Solicitação de $business enviada! Aguarde a aprovação (até 24h).';
  }

  @override
  String get onboardingChoosePlanError => 'Escolha um plano para continuar.';

  @override
  String get onboardingGenericError =>
      'Não foi possível enviar a solicitação. Tente novamente.';

  @override
  String get onboardingLanguageLabel => 'Idioma';

  @override
  String get onboardingLanguageHint => 'Idioma do aplicativo';

  @override
  String get onboardingCurrencyLabel => 'Moeda';

  @override
  String get onboardingCurrencyHint => 'Moeda usada nos valores';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get currencyBrl => 'Real (BRL)';

  @override
  String get currencyUsd => 'Dólar (USD)';

  @override
  String get currencyEur => 'Euro (EUR)';

  @override
  String get currencyMzn => 'Metical (MZN)';

  @override
  String get settingsSave => 'Salvar ajustes';

  @override
  String get settingsSaved => 'Ajustes salvos!';

  @override
  String get settingsGenericError =>
      'Não foi possível salvar os ajustes. Tente novamente.';

  @override
  String get commonSearch => 'Buscar...';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonSignOut => 'Sair da conta';

  @override
  String get appSheetClose => 'Fechar';

  @override
  String get storeSelectorActiveTooltip => 'Loja ativa';

  @override
  String get tenantPendingTitle => 'Aguardando aprovação';

  @override
  String tenantPendingSubtitle(String business) {
    return 'A solicitação de acesso de \"$business\" foi enviada com sucesso. O super admin vai analisar e você receberá acesso em até 24h.';
  }

  @override
  String get tenantPendingHint =>
      'Assim que aprovado, você poderá criar lojas, contratar funcionários e começar a operar.';

  @override
  String get tenantRejectedTitle => 'Solicitação rejeitada';

  @override
  String tenantRejectedSubtitle(String business) {
    return 'A solicitação de acesso de \"$business\" não foi aprovada.';
  }

  @override
  String get authErrorRestoreSession => 'Não foi possível restaurar sua sessão';

  @override
  String get authErrorCheckConnection =>
      'Verifique sua conexão e tente novamente.';

  @override
  String get authErrorLoadAccount => 'Não foi possível carregar sua conta';

  @override
  String get loginSubtitleSignUp => 'Crie sua conta para começar';

  @override
  String get loginSubtitleSignIn => 'Gestão simples para o seu negócio';

  @override
  String get loginNameLabel => 'Nome';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginEmailError => 'Informe um e-mail válido.';

  @override
  String get loginPasswordLabel => 'Senha';

  @override
  String get loginPasswordError => 'A senha deve ter ao menos 8 caracteres.';

  @override
  String get loginShowPassword => 'Mostrar senha';

  @override
  String get loginHidePassword => 'Ocultar senha';

  @override
  String get loginConfirmLabel => 'Confirmar senha';

  @override
  String get loginConfirmError => 'As senhas não coincidem.';

  @override
  String get loginSignUp => 'Cadastrar';

  @override
  String get loginSignIn => 'Entrar';

  @override
  String get loginSwitchToSignIn => 'Já tenho conta — entrar';

  @override
  String get loginSwitchToSignUp => 'Não tenho conta — cadastrar';

  @override
  String get loginSignUpSuccess =>
      'Conta criada! Confirme seu e-mail para entrar.';

  @override
  String get loginSignUpError =>
      'Não foi possível criar a conta. Tente novamente.';

  @override
  String get loginSignInError =>
      'Não foi possível entrar. Verifique e-mail e senha.';

  @override
  String get loginSecurityNote =>
      'Seus dados ficam protegidos com criptografia.';

  @override
  String get appNavHome => 'Início';

  @override
  String get appNavProducts => 'Produtos';

  @override
  String get appNavSales => 'Vendas';

  @override
  String get appNavFinancial => 'Financeiro';

  @override
  String get appNavCredit => 'Crédito';

  @override
  String get appNavCustomers => 'Clientes';

  @override
  String dashboardGreeting(String name) {
    return 'Olá, $name 👋';
  }

  @override
  String get dashboardSignOutTooltip => 'Sair';

  @override
  String get dashboardOwnerFallback => 'Dono';

  @override
  String get dashboardTotalSales => 'Total de vendas';

  @override
  String get dashboardAllTime => 'Todo o histórico';

  @override
  String get dashboardCashBalance => 'Saldo em caixa';

  @override
  String get dashboardReceivables => 'A receber (fiado)';

  @override
  String get dashboardStockLabel => 'Estoque em produtos';

  @override
  String get commonUnits => 'un.';

  @override
  String get dashboardQuickActions => 'Ações rápidas';

  @override
  String get dashboardQuickNewSale => 'Nova venda';

  @override
  String get dashboardQuickAddProduct => 'Adicionar produto';

  @override
  String get dashboardQuickAddTransaction => 'Registrar transação';

  @override
  String get dashboardQuickAddDebt => 'Registrar fiado';

  @override
  String get dashboardModules => 'Módulos';

  @override
  String get dashboardModuleCustomers => 'Clientes';

  @override
  String get dashboardModulePurchases => 'Compras';

  @override
  String get dashboardModuleReports => 'Relatórios';

  @override
  String get dashboardModuleStores => 'Lojas';

  @override
  String get dashboardRecentSales => 'Vendas recentes';

  @override
  String get dashboardNoSales => 'Nenhuma venda ainda — registre a primeira!';

  @override
  String get dashboardLowStock => 'Estoque baixo';

  @override
  String dashboardSaleItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMonday => 'Segunda-feira';

  @override
  String get weekdayTuesday => 'Terça-feira';

  @override
  String get weekdayWednesday => 'Quarta-feira';

  @override
  String get weekdayThursday => 'Quinta-feira';

  @override
  String get weekdayFriday => 'Sexta-feira';

  @override
  String get weekdaySaturday => 'Sábado';

  @override
  String get weekdaySunday => 'Domingo';

  @override
  String get storesTitle => 'Lojas';

  @override
  String get storesTabStores => 'Lojas';

  @override
  String get storesTabEmployees => 'Funcionários';

  @override
  String get storesTabUpgrades => 'Upgrades';

  @override
  String get storesTabSettings => 'Ajustes';

  @override
  String get storesAddStore => 'Nova loja';

  @override
  String get storesAddEmployee => 'Novo funcionário';

  @override
  String get storesLoadError => 'Não foi possível carregar as lojas.';

  @override
  String get storesEmptyTitle => 'Nenhuma loja criada';

  @override
  String get storesEmptySubtitle => 'Crie a primeira loja do seu negócio.';

  @override
  String get employeesLoadError => 'Não foi possível carregar os funcionários.';

  @override
  String get employeesEmptyTitle => 'Nenhum funcionário vinculado';

  @override
  String get employeesEmptySubtitle =>
      'Crie a conta do funcionário e escolha a loja.';

  @override
  String get roleManager => 'Gerente';

  @override
  String get roleEmployee => 'Funcionário';

  @override
  String get upgradesLoadError =>
      'Não foi possível carregar os pedidos de upgrade.';

  @override
  String get upgradesEmptyTitle => 'Nenhum pedido de upgrade';

  @override
  String get upgradesEmptySubtitle => 'Solicite um plano maior no card acima.';

  @override
  String get statusPending => 'Pendente';

  @override
  String get statusApproved => 'Aprovado';

  @override
  String get statusRejected => 'Rejeitado';

  @override
  String upgradesRequestedOn(String date) {
    return 'Solicitado em $date';
  }

  @override
  String get planCardTitle => 'Plano';

  @override
  String get planCardUpgrade => 'Upgrade';

  @override
  String get planCardStores => 'Lojas';

  @override
  String get planCardEmployees => 'Funcionários';

  @override
  String planDetails(int stores, int employees) {
    return '$stores lojas · $employees funcionários';
  }

  @override
  String get addStoreTitle => 'Nova loja';

  @override
  String get addStoreNameLabel => 'Nome da loja';

  @override
  String get addStoreNameError => 'Informe o nome da loja.';

  @override
  String get addStoreAddressLabel => 'Endereço (opcional)';

  @override
  String addStoreSuccess(String name) {
    return 'Loja $name criada!';
  }

  @override
  String get addStoreError => 'Não foi possível criar a loja. Tente novamente.';

  @override
  String get addStoreSubmit => 'Criar loja';

  @override
  String get addEmployeeTitle => 'Novo funcionário';

  @override
  String get addEmployeeNameLabel => 'Nome completo';

  @override
  String get addEmployeeNameError => 'Informe o nome do funcionário.';

  @override
  String get addEmployeeEmailLabel => 'E-mail';

  @override
  String get addEmployeeEmailError => 'Informe um e-mail válido.';

  @override
  String get addEmployeePasswordLabel => 'Senha de acesso';

  @override
  String get addEmployeePasswordError =>
      'A senha deve ter ao menos 8 caracteres.';

  @override
  String get addEmployeeStoreLabel => 'Loja';

  @override
  String get addEmployeeNoStores =>
      'Crie uma loja antes de cadastrar funcionários.';

  @override
  String get addEmployeeRoleLabel => 'Cargo';

  @override
  String get addEmployeeSuccess =>
      'Funcionário cadastrado! A conta de acesso foi criada.';

  @override
  String get addEmployeeError =>
      'Não foi possível cadastrar o funcionário. Verifique se o e-mail já não está em uso.';

  @override
  String get addEmployeeSubmit => 'Cadastrar funcionário';

  @override
  String get upgradeTitle => 'Upgrade de plano';

  @override
  String get upgradeSubtitle =>
      'Escolha o novo plano. O super admin precisará aprovar o pedido antes de o plano ser alterado.';

  @override
  String get upgradeMaxReached => 'Você já está no plano máximo disponível.';

  @override
  String get upgradeChooseError => 'Escolha o plano de destino.';

  @override
  String get upgradeSuccess =>
      'Pedido de upgrade enviado! O super admin vai analisar.';

  @override
  String get upgradeError =>
      'Não foi possível enviar o pedido. Tente novamente.';

  @override
  String get upgradeSubmit => 'Solicitar upgrade';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDescription => 'Descrição';

  @override
  String get commonNoResults => 'Nenhum resultado';

  @override
  String get commonNoResultsHint => 'Tente buscar por outro termo.';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonSoldOut => 'Esgotado';

  @override
  String get periodToday => 'Hoje';

  @override
  String get periodWeek => '7 dias';

  @override
  String get periodMonth => 'Este mês';

  @override
  String get periodAll => 'Tudo';

  @override
  String get paymentCash => 'Dinheiro';

  @override
  String get paymentDebitCard => 'Cartão de débito';

  @override
  String get paymentCreditCard => 'Cartão de crédito';

  @override
  String get paymentPix => 'Pix';

  @override
  String get paymentTransfer => 'Transferência';

  @override
  String get productsSearchHint => 'Buscar produto...';

  @override
  String get productsLoadError => 'Não foi possível carregar os produtos.';

  @override
  String get productsEmptyTitle => 'Nenhum produto cadastrado';

  @override
  String get productsEmptySubtitle => 'Toque em \"Novo produto\" para começar.';

  @override
  String get productsAddNew => 'Novo produto';

  @override
  String productsBuySell(String buy, String sell) {
    return 'Compra: $buy · Venda: $sell';
  }

  @override
  String get productsAdded => 'Produto adicionado!';

  @override
  String get productsAddError =>
      'Não foi possível adicionar o produto. Tente novamente.';

  @override
  String get productsNameError => 'Informe o nome do produto.';

  @override
  String get productsDescriptionLabel => 'Descrição (opcional)';

  @override
  String get productsPurchasePrice => 'Preço de compra';

  @override
  String get productsPurchasePriceError => 'Informe o preço de compra.';

  @override
  String get productsSalePrice => 'Preço de venda';

  @override
  String get productsSalePriceError => 'Informe o preço de venda.';

  @override
  String get productsStockQuantity => 'Quantidade em estoque';

  @override
  String get productsStockError => 'Informe uma quantidade válida.';

  @override
  String get productsAddSubmit => 'Adicionar produto';

  @override
  String get customersSearchHint => 'Buscar cliente...';

  @override
  String get customersLoadError => 'Não foi possível carregar os clientes.';

  @override
  String get customersEmptyTitle => 'Nenhum cliente cadastrado';

  @override
  String get customersEmptySubtitle =>
      'Toque em \"Novo cliente\" para começar.';

  @override
  String get customersAddNew => 'Novo cliente';

  @override
  String customersCreditLabel(String amount) {
    return 'Fiado $amount';
  }

  @override
  String customersAdded(String name) {
    return 'Cliente $name cadastrado!';
  }

  @override
  String get customersAddError =>
      'Não foi possível cadastrar o cliente. Tente novamente.';

  @override
  String get customersNameError => 'Informe o nome do cliente.';

  @override
  String get customersPhoneLabel => 'Telefone (opcional)';

  @override
  String get customersEmailLabel => 'E-mail (opcional)';

  @override
  String get customersAddSubmit => 'Cadastrar cliente';

  @override
  String get purchasesTitle => 'Compras';

  @override
  String get purchasesAddNew => 'Nova compra';

  @override
  String get purchasesLoadError => 'Não foi possível carregar as compras.';

  @override
  String get purchasesEmptyTitle => 'Nenhuma compra registrada';

  @override
  String get purchasesEmptySubtitle =>
      'Toque em \"Nova compra\" para registrar a entrada de mercadoria e abastecer o estoque.';

  @override
  String get purchasesSupplierError => 'Informe o fornecedor da compra.';

  @override
  String get purchasesCartItemUnavailable =>
      'Um item do carrinho não está mais disponível. Tente novamente.';

  @override
  String purchasesRegistered(String amount) {
    return 'Compra registrada: $amount!';
  }

  @override
  String purchasesProductNotFound(String id) {
    return 'Produto $id não encontrado no catálogo.';
  }

  @override
  String get purchasesRegisterError =>
      'Não foi possível registrar a compra. Tente novamente.';

  @override
  String get purchasesSupplierLabel => 'Fornecedor';

  @override
  String get purchasesNoProductsTitle => 'Nenhum produto para comprar';

  @override
  String get purchasesNoProductsSubtitle =>
      'Cadastre produtos para registrar compras.';

  @override
  String get purchasesConfirm => 'Confirmar compra';

  @override
  String purchasesStockLabel(int quantity, String unit) {
    return '$quantity $unit em estoque';
  }

  @override
  String get reportsTitle => 'Relatórios';

  @override
  String get reportsRevenue => 'Faturamento';

  @override
  String get reportsProfit => 'Lucro bruto';

  @override
  String get reportsMargin => 'Margem';

  @override
  String get reportsBestSellers => 'Mais vendidos';

  @override
  String get reportsLoadError => 'Não foi possível carregar o relatório.';

  @override
  String get reportsEmptyTitle => 'Sem vendas no período';

  @override
  String get reportsEmptySubtitle => 'Registre vendas para ver o relatório.';

  @override
  String get reportsSalesPerDay => 'Vendas por dia';

  @override
  String reportsRevenueLabel(String amount) {
    return '$amount vendidos';
  }

  @override
  String get financialTitle => 'Financeiro';

  @override
  String get financialRegister => 'Registrar';

  @override
  String get financialIncome => 'Entradas';

  @override
  String get financialExpense => 'Saídas';

  @override
  String get financialBalance => 'Saldo';

  @override
  String get financialTransactions => 'Movimentações';

  @override
  String get financialLoadError =>
      'Não foi possível carregar as movimentações.';

  @override
  String get financialEmptyTitle => 'Nenhuma movimentação';

  @override
  String get financialEmptySubtitle =>
      'Registre entradas e saídas para acompanhar o fluxo de caixa.';

  @override
  String get financialReceivePendingTitle => 'Receber pendência?';

  @override
  String financialReceivePendingBody(String amount) {
    return 'Confirmar o recebimento de $amount? A movimentação passa a contar no caixa realizado.';
  }

  @override
  String get financialReceive => 'Receber';

  @override
  String get financialReceived => 'Movimentação recebida!';

  @override
  String get financialReceiveError =>
      'Não foi possível receber a pendência. Tente novamente.';

  @override
  String get financialAddTitle => 'Registrar movimentação';

  @override
  String get financialIncomingType => 'Entrada';

  @override
  String get financialOutgoingType => 'Saída';

  @override
  String get financialDescriptionLabel => 'Descrição';

  @override
  String get financialDescriptionError => 'Informe a descrição.';

  @override
  String get financialCategoryLabel => 'Categoria (opcional)';

  @override
  String get financialAmountLabel => 'Valor';

  @override
  String get financialAmountError => 'Informe um valor maior que zero.';

  @override
  String get financialPendingLabel => 'Pendente (fiado)';

  @override
  String get financialPendingHint =>
      'Não conta no caixa realizado até ser recebido.';

  @override
  String get financialRegistered => 'Movimentação registrada!';

  @override
  String get financialRegisterError =>
      'Não foi possível registrar a movimentação. Tente novamente.';

  @override
  String get financialDefaultCategoryIncome => 'Vendas';

  @override
  String get financialDefaultCategoryExpense => 'Despesas';

  @override
  String get debtsTitle => 'Crédito (fiado)';

  @override
  String get debtsAddDebt => 'Registrar fiado';

  @override
  String get debtsTabPending => 'Pendentes';

  @override
  String get debtsTabSettled => 'Quitadas';

  @override
  String get debtsTotalPending => 'Total a receber';

  @override
  String get debtsNoPendingCustomers => 'Nenhum cliente pendente';

  @override
  String debtsPendingCustomers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clientes pendentes',
      one: '1 cliente pendente',
    );
    return '$_temp0';
  }

  @override
  String get debtsPendingSection => 'Dívidas pendentes';

  @override
  String get debtsLoadError => 'Não foi possível carregar as dívidas.';

  @override
  String get debtsEmptyPendingTitle => 'Nenhum fiado pendente 🎉';

  @override
  String get debtsEmptyPendingSubtitle =>
      'Nenhum cliente está devendo no momento.';

  @override
  String get debtsTotalSettled => 'Total quitado';

  @override
  String debtsSettledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count baixas registradas',
      one: '1 baixa registrada',
    );
    return '$_temp0';
  }

  @override
  String get debtsSettledSection => 'Histórico de quitações';

  @override
  String get debtsHistoryLoadError => 'Não foi possível carregar o histórico.';

  @override
  String get debtsEmptySettledTitle => 'Nenhuma quitação ainda';

  @override
  String get debtsEmptySettledSubtitle =>
      'Quando um fiado for quitado, ele aparece aqui.';

  @override
  String get debtsSettleTitle => 'Quitar dívida?';

  @override
  String debtsSettleBody(String amount, String name) {
    return 'Receber $amount de $name? Será registrada uma entrada no caixa.';
  }

  @override
  String get debtsSettle => 'Quitar';

  @override
  String debtsSettled(String name, String amount) {
    return 'Fiado de $name quitado — $amount no caixa.';
  }

  @override
  String get debtsNotFound => 'Esta dívida não está mais pendente.';

  @override
  String get debtsSettleError =>
      'Não foi possível quitar a dívida. Tente novamente.';

  @override
  String get debtsLate => 'Atrasada';

  @override
  String get debtsDueToday => 'Vence hoje';

  @override
  String debtsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return 'Em $_temp0';
  }

  @override
  String get debtsSettleAction => 'Quitar dívida';

  @override
  String get debtsSettledLabel => 'Quitada';

  @override
  String debtsSettledOn(String date) {
    return 'Quitada em $date';
  }

  @override
  String get debtsDueDateHelp => 'Vencimento do fiado';

  @override
  String debtsRegisteredFor(String name) {
    return 'Fiado registrado para $name!';
  }

  @override
  String get debtsPendingEntryError =>
      'Fiado registrado, mas a pendência no Financeiro não pôde ser criada. Verifique as movimentações.';

  @override
  String get debtsRegisterError =>
      'Não foi possível registrar o fiado. Tente novamente.';

  @override
  String get debtsCustomerLinkLabel => 'Cliente vinculado (opcional)';

  @override
  String get debtsNoCustomer => 'Sem vínculo';

  @override
  String get debtsCustomerNameLabel => 'Nome do cliente';

  @override
  String get debtsCustomerNameError => 'Informe o nome do cliente.';

  @override
  String get debtsDueDateLabel => 'Vencimento';

  @override
  String get salesTitle => 'Vendas';

  @override
  String get salesNewSale => 'Nova venda';

  @override
  String get salesLoadError => 'Não foi possível carregar as vendas.';

  @override
  String get salesEmptyTitle => 'Nenhuma venda registrada';

  @override
  String get salesEmptySubtitle =>
      'Toque em \"Nova venda\" para registrar a primeira.';

  @override
  String get salesItemUnavailable =>
      'Um item do carrinho não está mais disponível. Tente novamente.';

  @override
  String salesRegistered(String amount) {
    return 'Venda registrada: $amount!';
  }

  @override
  String salesInsufficientStock(String product, int available) {
    return 'Estoque insuficiente$product. Disponível: $available.';
  }

  @override
  String salesStockFor(String name) {
    return 'para $name';
  }

  @override
  String salesProductNotFound(String id) {
    return 'Produto $id não encontrado no estoque.';
  }

  @override
  String get salesRegisterError =>
      'Não foi possível registrar a venda. Tente novamente.';

  @override
  String get salesSearchProducts => 'Buscar produto...';

  @override
  String get salesNoProductsTitle => 'Nenhum produto para vender';

  @override
  String get salesNoProductsSubtitle =>
      'Cadastre produtos para registrar vendas.';

  @override
  String get salesConfirm => 'Confirmar venda';

  @override
  String get saleDetailTitle => 'Detalhes da venda';

  @override
  String saleDetailId(String id) {
    return 'Venda $id';
  }

  @override
  String get saleDetailTotalLabel => 'Total da venda';

  @override
  String get saleDetailItems => 'Itens';

  @override
  String get saleDetailTotal => 'Total';

  @override
  String get saleDetailSnapshot => 'Preços congelados no momento da venda.';

  @override
  String get adminTitle => 'Painel do Super Admin';

  @override
  String get adminNavRequests => 'Solicitações';

  @override
  String get adminNavPlans => 'Planos';

  @override
  String get adminNavUpgrades => 'Upgrades';

  @override
  String get adminTenantsTitle => 'Tenants';

  @override
  String get adminPendingOnly => 'Pendentes';

  @override
  String get adminAll => 'Todos';

  @override
  String adminAwaitingCount(int count) {
    return '$count aguardando aprovação';
  }

  @override
  String get adminTenantsEmpty => 'Nenhum tenant registrado ainda.';

  @override
  String get adminRequestsLoadError =>
      'Não foi possível carregar as solicitações.';

  @override
  String get adminNothingPendingTitle => 'Nada aguardando aprovação';

  @override
  String get adminNothingPendingSubtitle =>
      'Novas solicitações de tenant aparecem aqui.';

  @override
  String get adminTenantsLoadError => 'Não foi possível carregar os tenants.';

  @override
  String get adminRejectError => 'Não foi possível rejeitar a solicitação.';

  @override
  String get adminApproveError => 'Não foi possível aprovar a solicitação.';

  @override
  String adminAccessApproved(String name) {
    return 'Acesso de $name aprovado!';
  }

  @override
  String adminRequestRejected(String name) {
    return 'Solicitação de $name rejeitada.';
  }

  @override
  String adminRejectTitle(String name) {
    return 'Rejeitar $name';
  }

  @override
  String get adminRejectReasonLabel => 'Motivo da rejeição';

  @override
  String get adminRejectReasonHint =>
      'Ex.: informações incompletas no cadastro';

  @override
  String get adminApprove => 'Aprovar';

  @override
  String get adminReject => 'Rejeitar';

  @override
  String adminPlanLabel(String plan) {
    return 'Plano: $plan';
  }

  @override
  String adminPlanSolicited(String plan, String date) {
    return 'Plano: $plan · Solicitado: $date';
  }

  @override
  String get adminPlansTitle => 'Planos';

  @override
  String get adminPlanNewTooltip => 'Novo plano';

  @override
  String get adminPlansLoadError => 'Não foi possível carregar os planos.';

  @override
  String get adminPlansEmptyTitle => 'Nenhum plano criado';

  @override
  String get adminPlansEmptySubtitle =>
      'Crie o primeiro plano para liberar assinaturas.';

  @override
  String get adminPlanInactive => 'Inativo';

  @override
  String adminPlanDetails(String price, int stores, int employees) {
    return '$price/mês · $stores loja(s) · $employees funcionário(s)';
  }

  @override
  String get adminPlanNameError => 'Informe o nome do plano.';

  @override
  String get adminPlanPriceError => 'Informe um preço válido (≥ 0).';

  @override
  String get adminPlanStoresError => 'O plano deve permitir ao menos 1 loja.';

  @override
  String get adminPlanEmployeesError =>
      'O plano deve permitir ao menos 1 funcionário.';

  @override
  String adminPlanCreated(String name) {
    return 'Plano $name criado!';
  }

  @override
  String adminPlanUpdated(String name) {
    return 'Plano $name atualizado!';
  }

  @override
  String get adminPlanSaveError =>
      'Não foi possível salvar o plano. Tente novamente.';

  @override
  String get adminPlanNewTitle => 'Novo plano';

  @override
  String get adminPlanEditTitle => 'Editar plano';

  @override
  String get adminPlanNameLabel => 'Nome do plano';

  @override
  String get adminPlanPriceLabel => 'Preço mensal';

  @override
  String get adminPlanMaxStores => 'Máx. lojas';

  @override
  String get adminPlanMaxEmployees => 'Máx. funcionários';

  @override
  String get adminPlanActiveTitle => 'Plano ativo';

  @override
  String get adminPlanActiveSubtitle =>
      'Desative para impedir novas assinaturas.';

  @override
  String get adminPlanCreate => 'Criar plano';

  @override
  String get adminUpgradesTitle => 'Upgrades de plano';

  @override
  String get adminUpgradesLoadError =>
      'Não foi possível carregar os pedidos de upgrade.';

  @override
  String get adminUpgradesEmptyTitle => 'Nenhum upgrade pendente';

  @override
  String get adminUpgradesEmptySubtitle =>
      'Pedidos de mudança de plano aparecem aqui.';

  @override
  String get adminUpgradeApproved =>
      'Upgrade aprovado — plano do tenant atualizado!';

  @override
  String get adminUpgradeRejected => 'Upgrade rejeitado.';

  @override
  String get adminUpgradeProcessError => 'Não foi possível processar o pedido.';

  @override
  String get adminPlanRequested => 'Solicitado';

  @override
  String get adminPlanCurrent => 'Atual';
}
