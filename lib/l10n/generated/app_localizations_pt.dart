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
  String get onboardingHeading => 'Configure seu negócio';

  @override
  String get onboardingSubtitle =>
      'Escolha o plano, nome e moeda. Aprovação em até 24h.';

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
    return 'Solicitação de $business enviada! Aguarde aprovação (até 24h).';
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
  String get languageFrench => 'Français';

  @override
  String get currencyBrl => 'Real (BRL)';

  @override
  String get currencyUsd => 'Dólar (USD)';

  @override
  String get currencyEur => 'Euro (EUR)';

  @override
  String get currencyMzn => 'Metical (MZN)';

  @override
  String get settingsSave => 'Salvar';

  @override
  String get settingsSaved => 'Ajustes salvos!';

  @override
  String get settingsGenericError =>
      'Não foi possível salvar. Tente novamente.';

  @override
  String get settingsSupportSection => 'Suporte';

  @override
  String get settingsSupportEntry => 'Ajuda e documentação';

  @override
  String get settingsSupportEntryHint =>
      'Guia do Usuário e Troubleshooting — offline';

  @override
  String get supportTitle => 'Ajuda';

  @override
  String get supportSubtitle => 'Guia do usuário e solução de problemas.';

  @override
  String get supportUserGuide => 'Guia do Usuário';

  @override
  String get supportUserGuideHint =>
      'Login, lojas, produtos, vendas, fiado, financeiro e relatórios';

  @override
  String get supportTroubleshooting => 'Troubleshooting';

  @override
  String get supportTroubleshootingHint =>
      'Problemas comuns: login, vendas, estoque e conexão';

  @override
  String get supportReadingError => 'Não foi possível abrir o documento.';

  @override
  String get commonSearch => 'Buscar...';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonSignOut => 'Terminar sessão';

  @override
  String get appSheetClose => 'Fechar';

  @override
  String get storeSwitcherTooltip => 'Trocar de loja';

  @override
  String get storeSelectorSectionTitle => 'Loja ativa';

  @override
  String get storeSelectorSectionHint => 'Escolha a loja ativa.';

  @override
  String get tenantPendingTitle => 'Aguardando aprovação';

  @override
  String tenantPendingSubtitle(String business) {
    return 'Solicitação de \"$business\" enviada. Aguarde até 24h.';
  }

  @override
  String get tenantPendingHint =>
      'Depois da aprovação, crie lojas e comece a operar.';

  @override
  String get tenantRejectedTitle => 'Solicitação rejeitada';

  @override
  String tenantRejectedSubtitle(String business) {
    return 'A solicitação de \"$business\" não foi aprovada.';
  }

  @override
  String get authBlockedTitle => 'Acesso suspenso';

  @override
  String get authBlockedMessage =>
      'Sua conta foi desativada pelo proprietário.';

  @override
  String get authBlockedSignOut => 'Sair';

  @override
  String get authErrorRestoreSession => 'Sessão não restaurada';

  @override
  String get authErrorCheckConnection =>
      'Verifique sua conexão e tente novamente.';

  @override
  String get authErrorLoadAccount => 'Conta não carregada';

  @override
  String get splashLoading => 'A abrir a sua sessão…';

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
  String get loginPasswordHint =>
      'Mín. 8 caracteres com minúscula, maiúscula, número e símbolo.';

  @override
  String get loginWeakPasswordError =>
      'A senha deve conter letras, números e símbolos.';

  @override
  String get loginRateLimitError =>
      'Muitas tentativas. Aguarde 1 hora e tente novamente.';

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
  String get loginSecurityNote => 'Dados protegidos com criptografia.';

  @override
  String get loginForgotPassword => 'Esqueceu a senha?';

  @override
  String get forgotPasswordTitle => 'Redefinir senha';

  @override
  String get forgotPasswordHint =>
      'Informe seu e-mail. Enviaremos um link para redefinir.';

  @override
  String get forgotPasswordSubmit => 'Enviar link';

  @override
  String get forgotPasswordSent => 'Se existir uma conta, enviamos um link.';

  @override
  String get forgotPasswordError =>
      'Não foi possível enviar o link. Tente novamente.';

  @override
  String get setNewPasswordTitle => 'Definir nova senha';

  @override
  String get setNewPasswordHint =>
      'Mín. 8 caracteres com minúscula, maiúscula, número e símbolo.';

  @override
  String get setNewPasswordSubmit => 'Salvar nova senha';

  @override
  String get setNewPasswordSuccess => 'Senha atualizada!';

  @override
  String get setNewPasswordError =>
      'Não foi possível atualizar a senha. Tente novamente.';

  @override
  String get setNewPasswordSignOut => 'Sair da conta';

  @override
  String get changePasswordTitle => 'Trocar senha';

  @override
  String get changePasswordCurrentLabel => 'Senha atual';

  @override
  String get changePasswordNewLabel => 'Nova senha';

  @override
  String get changePasswordConfirmLabel => 'Confirmar nova senha';

  @override
  String get changePasswordSuccess => 'Senha alterada com sucesso!';

  @override
  String get changePasswordWrongCurrent =>
      'Senha atual incorreta. Tente novamente.';

  @override
  String get changePasswordSubmit => 'Alterar senha';

  @override
  String get changePasswordError =>
      'Não foi possível alterar a senha. Tente novamente.';

  @override
  String get securitySectionTitle => 'Segurança';

  @override
  String get securityChangePassword => 'Trocar senha';

  @override
  String get securityChangePasswordHint => 'Atualize a senha da sua conta';

  @override
  String get appNavHome => 'Início';

  @override
  String get appNavSales => 'Vendas';

  @override
  String get appNavWallet => 'Carteira';

  @override
  String get appNavMenu => 'Menu';

  @override
  String get appNavProducts => 'Produtos';

  @override
  String get appNavFinancial => 'Financeiro';

  @override
  String get appNavCredit => 'Crédito';

  @override
  String get appNavCustomers => 'Clientes';

  @override
  String get fabMenuTitle => 'Nova ação';

  @override
  String get fabMenuSubtitle => 'O que deseja fazer?';

  @override
  String get menuSubtitle => 'Escolha uma área para continuar';

  @override
  String get commonSignOutConfirmTitle => 'Terminar sessão?';

  @override
  String get commonSignOutConfirmMessage =>
      'Vai sair da sua conta neste dispositivo.';

  @override
  String get fabMenuNewSale => 'Nova venda';

  @override
  String get fabMenuNewSaleHint => 'Carrinho · baixa de estoque · caixa';

  @override
  String get fabMenuExpense => 'Registrar despesa';

  @override
  String get fabMenuExpenseHint => 'Saída de caixa com categoria';

  @override
  String get fabMenuAddProduct => 'Adicionar produto';

  @override
  String get fabMenuAddProductHint => 'Catálogo · preço · estoque inicial';

  @override
  String get fabMenuAddDebt => 'Registrar fiado';

  @override
  String get fabMenuAddDebtHint => 'A receber ou a pagar';

  @override
  String get fabMenuAddCustomer => 'Adicionar cliente';

  @override
  String get fabMenuAddCustomerHint => 'Contactos · fiado vinculado';

  @override
  String get fabMenuCancel => 'Cancelar';

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações aguardando sincronização',
      one: '1 operação aguardando sincronização',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Sincronizar';

  @override
  String get syncOfflineSaved =>
      'Sem conexão. Operação salva e será sincronizada automaticamente.';

  @override
  String syncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operações sincronizadas',
      one: '1 operação sincronizada',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline => 'Sem conexão — operações pendentes.';

  @override
  String dashboardGreeting(String name) {
    return 'Olá, $name';
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
  String get dashboardViewAll => 'Ver todas';

  @override
  String get dashboardNoSales => 'Nenhuma venda ainda — registre a primeira!';

  @override
  String get dashboardRecentPurchases => 'Compras recentes';

  @override
  String get dashboardNoPurchases =>
      'Nenhuma compra ainda — registre a primeira!';

  @override
  String get dashboardLowStock => 'Estoque baixo';

  @override
  String get dashboardKpisError => 'Não foi possível carregar os indicadores.';

  @override
  String get dashboardActivityTitle => 'Atividade de hoje';

  @override
  String dashboardActivityEvents(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0';
  }

  @override
  String dashboardActivityMinutesAgo(Object count) {
    return 'há $count min';
  }

  @override
  String dashboardActivityHoursAgo(Object count) {
    return 'há $count h';
  }

  @override
  String get dashboardDateToday => 'Hoje';

  @override
  String get dashboardMetricSales => 'Vendas';

  @override
  String get dashboardMetricCash => 'Caixa';

  @override
  String get dashboardMetricReceivables => 'A receber';

  @override
  String dashboardFiadoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fiados',
      one: '1 fiado',
    );
    return '$_temp0';
  }

  @override
  String get dashboardActivityEmpty => 'Nenhuma atividade registrada ainda.';

  @override
  String get dashboardActivitySeeAll => 'Ver todas';

  @override
  String dashboardStockEntry(String product) {
    return 'Estoque · $product';
  }

  @override
  String dashboardStockEntryDetail(String quantity, String time) {
    return 'Entrada de $quantity · $time';
  }

  @override
  String get dashboardFiadoPayment => 'Pagamento fiado';

  @override
  String dashboardExpenseRow(String description) {
    return 'Despesa · $description';
  }

  @override
  String dashboardLowStockDetail(String name, String quantity) {
    return '$name · $quantity restantes';
  }

  @override
  String get dashboardAlertBadge => 'Alerta';

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
  String get employeeActive => 'Ativo';

  @override
  String get employeeInactive => 'Inativo';

  @override
  String employeeDeactivateConfirm(Object name) {
    return 'Desativar $name? Perde acesso imediatamente.';
  }

  @override
  String employeeReactivateConfirm(Object name) {
    return 'Reativar $name? Volta a ter acesso à loja.';
  }

  @override
  String get employeeDeactivated => 'Funcionário desativado.';

  @override
  String get employeeReactivated => 'Funcionário reativado.';

  @override
  String get employeeDeactivateAction => 'Desativar';

  @override
  String get employeeReactivateAction => 'Reativar';

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
      'Funcionário cadastrado! Conta de acesso criada.';

  @override
  String get addEmployeeError =>
      'Não foi possível cadastrar. Verifique o e-mail.';

  @override
  String get addEmployeeSubmit => 'Cadastrar funcionário';

  @override
  String get upgradeTitle => 'Upgrade de plano';

  @override
  String get upgradeSubtitle =>
      'Escolha o novo plano. Aguarda aprovação do super admin.';

  @override
  String get upgradeMaxReached => 'Você já está no plano máximo.';

  @override
  String get upgradeChooseError => 'Escolha o plano de destino.';

  @override
  String get upgradeSuccess => 'Pedido de upgrade enviado!';

  @override
  String get upgradeError =>
      'Não foi possível enviar o pedido. Tente novamente.';

  @override
  String get upgradeSubmit => 'Solicitar upgrade';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonDelete => 'Apagar';

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
  String get periodWeek => 'Esta semana';

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
  String get paymentEMola => 'E-Mola';

  @override
  String get paymentMPesa => 'M-Pesa';

  @override
  String get paymentTransfer => 'Transferência';

  @override
  String get purchasesSearchHint => 'Buscar compra...';

  @override
  String get productsFilterTooltip => 'Filtrar';

  @override
  String get productsFilterAll => 'Todos';

  @override
  String productsFilterAllCount(int count) {
    return 'Todos os produtos · $count';
  }

  @override
  String productsFilterLowCount(int count) {
    return 'Stock baixo · $count';
  }

  @override
  String get productsColProduct => 'Produto / SKU';

  @override
  String get productsColPrice => 'Preço · Stock';

  @override
  String get productsSearchHint => 'Pesquisar produto...';

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
  String get productsAddedNoPhoto =>
      'Produto adicionado! (sem permissão de armazenamento)';

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
  String get productsPurchasePriceError => 'Informe o preço de compra';

  @override
  String get productsSalePrice => 'Preço de venda';

  @override
  String get productsSalePriceError => 'Informe o preço de venda';

  @override
  String get productsStockQuantity => 'Quantidade em estoque';

  @override
  String get productsStockError => 'Quantidade inválida';

  @override
  String get productsAddSubmit => 'Adicionar produto';

  @override
  String get productsEditTitle => 'Editar produto';

  @override
  String get productsEditSubmit => 'Salvar alterações';

  @override
  String get productsEditSaved => 'Produto atualizado!';

  @override
  String get productsEditSavedNoPhoto =>
      'Produto atualizado! (sem permissão de armazenamento)';

  @override
  String get productsEditError =>
      'Não foi possível atualizar o produto. Tente novamente.';

  @override
  String get productsPhotoLabel => 'Foto do produto';

  @override
  String get productsPhotoTake => 'Tirar fotografia';

  @override
  String get productsPhotoGallery => 'Escolher da galeria';

  @override
  String get productsPhotoRemove => 'Remover fotografia';

  @override
  String get productsInactive => 'Inativo';

  @override
  String get productsStockOut => 'Esgotado';

  @override
  String get productsStockLow => 'Baixo';

  @override
  String get productsFilterAdvanced => 'Filtros avançados';

  @override
  String get productsFilterClear => 'Limpar tudo';

  @override
  String get productsFilterStockType => 'Tipo de estoque';

  @override
  String get productsFilterStockTypeAll => 'Todos';

  @override
  String get productsFilterStockTypeWeight => 'Peso (kg/g/l/ml)';

  @override
  String get productsFilterStockTypeUnit => 'Unidade (un)';

  @override
  String get productsFilterAvailability => 'Disponibilidade';

  @override
  String get productsFilterAvailable => 'Em estoque';

  @override
  String get productsFilterLowStock => 'Estoque baixo';

  @override
  String get productsFilterOutOfStock => 'Esgotado';

  @override
  String get productsFilterPriceRange => 'Faixa de preço';

  @override
  String get productsFilterMinPrice => 'Preço mínimo';

  @override
  String get productsFilterMaxPrice => 'Preço máximo';

  @override
  String get productsFilterApply => 'Aplicar';

  @override
  String get productsFilterInactive => 'Inactivos';

  @override
  String productsFilterInactiveCount(int count) {
    return 'Inactivos · $count';
  }

  @override
  String productsHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produtos',
      one: '1 produto',
    );
    return '$_temp0';
  }

  @override
  String get productsClearFilters => 'Limpar filtros';

  @override
  String get productsEmptyFilteredTitle => 'Nenhum produto encontrado';

  @override
  String get productsEmptyFilteredSubtitle =>
      'Ajuste a pesquisa ou os filtros.';

  @override
  String productsFilteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produtos',
      one: '1 produto',
    );
    return '$_temp0';
  }

  @override
  String get productsSummaryActive => 'Activos';

  @override
  String get productsSummaryLowStock => 'Stock baixo';

  @override
  String get productsSummaryInactive => 'Inactivos';

  @override
  String get productsActiveLabel => 'Produto ativo';

  @override
  String get productsActiveHint => 'Desative para tirar do PDV e compras.';

  @override
  String get productsStockAdjustHint =>
      'Ajuste manual: define o estoque exato (FIFO).';

  @override
  String get productsSectionInfo => 'Informações';

  @override
  String get productsSectionPricing => 'Preços';

  @override
  String get productsSectionStock => 'Estoque';

  @override
  String get productsSectionStatus => 'Status';

  @override
  String get productsAddNewTitle => 'Novo produto';

  @override
  String get productsSave => 'Guardar';

  @override
  String get productsSaving => 'A guardar...';

  @override
  String get productsSaved => 'Produto guardado com sucesso';

  @override
  String get productsSavedNoPhoto =>
      'Produto guardado! (sem permissão de armazenamento)';

  @override
  String get productsPhotoLabelNew => 'Fotografia do produto';

  @override
  String get productsPhotoHint => 'Toque para adicionar';

  @override
  String get productsSectionBasic => 'Informações básicas';

  @override
  String get productsSectionPricingNew => 'Preços';

  @override
  String get productsSectionStockNew => 'Stock';

  @override
  String get productsNameLabel => 'Nome do produto';

  @override
  String get productsNameHint => 'Ex.: Arroz tipo 1';

  @override
  String get productsNameErrorMsg => 'Obrigatório';

  @override
  String get productsDescriptionLabelNew => 'Descrição';

  @override
  String get productsDescriptionHint => 'Opcional';

  @override
  String get productsCodeLabel => 'Código de barras (PLU)';

  @override
  String get productsCodeHint => 'Balanças etiquetadoras (ex.: 12345)';

  @override
  String get productsCodeError => 'Código inválido: use até 5 dígitos.';

  @override
  String get productsPurchasePriceLabel => 'Preço de compra (MT)';

  @override
  String get productsSalePriceLabel => 'Preço de venda (MT)';

  @override
  String get productsPriceValidationError =>
      'O preço de venda deve ser superior ao de compra';

  @override
  String get productsStockQuantityLabel => 'Quantidade em stock';

  @override
  String get productsStockHint => 'Ex.: 50';

  @override
  String get productsStockWeightHint => 'Em unidades da venda (ex.: 1,75)';

  @override
  String get productsExpiryLabel => 'Validade';

  @override
  String get productsExpiryHint => 'Opcional';

  @override
  String get productsExpiryAdd => 'Definir validade';

  @override
  String get productsExpiryClear => 'Remover validade';

  @override
  String get productsWeighLabel => 'Venda por peso (fração)';

  @override
  String get productsWeighHint => 'Aceita quantidades decimais (ex.: 1,75 kg)';

  @override
  String get productsUnitLabel => 'Unidade de venda';

  @override
  String customersHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clientes',
      one: '1 cliente',
    );
    return '$_temp0';
  }

  @override
  String get customersColCustomer => 'Cliente';

  @override
  String get customersColContact => 'Contacto / Fiado';

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
  String get customersEditTitle => 'Editar cliente';

  @override
  String customersEditSuccess(Object name) {
    return 'Cliente $name atualizado!';
  }

  @override
  String get customersEditError =>
      'Não foi possível atualizar o cliente. Tente novamente.';

  @override
  String get customersEditSubmit => 'Salvar alterações';

  @override
  String get customersDeleteConfirmTitle => 'Remover cliente?';

  @override
  String customersDeleteConfirmMessage(Object name) {
    return '$name será removido permanentemente. Registros de fiado são preservados.';
  }

  @override
  String get customersDeleteSuccess => 'Cliente removido.';

  @override
  String get customersDeleteError =>
      'Não foi possível remover o cliente. Tente novamente.';

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
      'Toque em \"Nova compra\" para registrar.';

  @override
  String purchasesHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count compras',
      one: '1 compra',
      zero: '0 compras',
    );
    return '$_temp0';
  }

  @override
  String get purchasesHeaderVsYesterday => 'vs ontem';

  @override
  String purchasesStockAdded(int units, String unit) {
    return 'Estoque +$units $unit';
  }

  @override
  String get purchasesEmptyFilteredTitle => 'Nenhuma compra encontrada';

  @override
  String get purchasesEmptyFilteredSubtitle => 'Ajuste a busca ou os filtros.';

  @override
  String get purchasesClearFilters => 'Limpar filtros';

  @override
  String get purchasesSupplierError => 'Informe o fornecedor da compra.';

  @override
  String get purchasesCartItemUnavailable =>
      'Item do carrinho não disponível. Tente novamente.';

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
  String get reportsExport => 'Exportar';

  @override
  String get reportsExportCsv => 'Exportar CSV';

  @override
  String get reportsExportPdf => 'Exportar PDF';

  @override
  String get reportsExportDone => 'Relatório exportado!';

  @override
  String get reportsExportError =>
      'Não foi possível exportar o relatório. Tente novamente.';

  @override
  String get reportsExportTitle => 'Relatório de vendas';

  @override
  String get reportsExportFileName => 'relatorio_vendas';

  @override
  String get reportsExportStore => 'Loja';

  @override
  String get reportsExportPeriod => 'Período';

  @override
  String get reportsExportGeneratedAt => 'Gerado em';

  @override
  String get reportsExportSummary => 'Resumo';

  @override
  String get reportsExportRank => 'Posição';

  @override
  String get reportsExportProduct => 'Produto';

  @override
  String get reportsExportQuantity => 'Quantidade';

  @override
  String get reportsExportRevenue => 'Receita';

  @override
  String get reportsExportDay => 'Dia';

  @override
  String get reportsExportTotal => 'Total';

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
  String get financialPeriodBalance => 'Saldo líquido do período';

  @override
  String get financialSwipeHint => 'Deslize para saídas →';

  @override
  String get financialTransactions => 'Movimentos do período';

  @override
  String get financialLoadError =>
      'Não foi possível carregar as movimentações.';

  @override
  String get financialCashFlowError =>
      'Não foi possível carregar o fluxo de caixa.';

  @override
  String get financialEmptyTitle => 'Nenhuma movimentação';

  @override
  String get financialEmptySubtitle =>
      'Registre entradas e saídas para acompanhar o caixa.';

  @override
  String get financialReceivePendingTitle => 'Receber pendência?';

  @override
  String financialReceivePendingBody(String amount) {
    return 'Confirmar recebimento de $amount?';
  }

  @override
  String get financialReceive => 'Receber';

  @override
  String get financialReceived => 'Movimentação recebida!';

  @override
  String get financialReceiveError =>
      'Não foi possível receber. Tente novamente.';

  @override
  String get financialPay => 'Pagar';

  @override
  String get financialPayPendingTitle => 'Pagar pendência?';

  @override
  String financialPayPendingBody(String amount) {
    return 'Confirmar pagamento de $amount?';
  }

  @override
  String get financialPaid => 'Saída paga!';

  @override
  String get financialPayError =>
      'Não foi possível pagar a pendência. Tente novamente.';

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
  String get financialPendingHint => 'Não conta no caixa até ser recebido.';

  @override
  String get financialRegistered => 'Movimentação registrada!';

  @override
  String get financialRegisterError =>
      'Não foi possível registrar. Tente novamente.';

  @override
  String get financialDefaultCategoryIncome => 'Vendas';

  @override
  String get financialDefaultCategoryExpense => 'Despesas';

  @override
  String get financialDetailDescription => 'Descrição';

  @override
  String get financialDetailCategory => 'Categoria';

  @override
  String get financialDetailNumber => 'Nº movimento';

  @override
  String get financialDetailDate => 'Data e hora';

  @override
  String get financialDetailStatus => 'Estado';

  @override
  String get cashClosingAction => 'Fecho de caixa';

  @override
  String get cashClosingTitle => 'Fecho de caixa do dia';

  @override
  String get cashClosingDaySummary => 'Resumo do dia';

  @override
  String get cashClosingTotalSales => 'Vendas do dia';

  @override
  String get cashClosingExpectedCash => 'Esperado na gaveta';

  @override
  String get cashClosingExpectedCashHint => 'Só vendas em dinheiro.';

  @override
  String get cashClosingByMethod => 'Por forma de pagamento';

  @override
  String get cashClosingCountedCash => 'Dinheiro contado';

  @override
  String get cashClosingCountedCashHint =>
      'Conte o dinheiro da gaveta e informe aqui.';

  @override
  String get cashClosingDifference => 'Diferença';

  @override
  String get cashClosingConfers => 'Caixa confere';

  @override
  String cashClosingSurplus(String amount) {
    return 'Sobra de $amount';
  }

  @override
  String cashClosingShortage(String amount) {
    return 'Falta de $amount';
  }

  @override
  String get cashClosingConfirm => 'Confirmar fecho';

  @override
  String get cashClosingUpdate => 'Atualizar fecho';

  @override
  String get cashClosingClosedAt => 'Fechado em';

  @override
  String get cashClosingSuccess => 'Caixa fechado!';

  @override
  String get cashClosingUpdated => 'Fecho atualizado!';

  @override
  String get cashClosingError =>
      'Não foi possível fechar o caixa. Tente novamente.';

  @override
  String get cashClosingEmpty => 'Nenhuma venda registrada neste dia.';

  @override
  String get cashClosingHistory => 'Histórico de fechos';

  @override
  String get cashClosingHistoryEmpty => 'Nenhum fecho registrado ainda.';

  @override
  String get debtsTitle => 'Crédito (fiado)';

  @override
  String get debtsHeaderSubtitle => 'Fiado a receber e a pagar';

  @override
  String get debtsAddDebt => 'Registrar fiado';

  @override
  String get debtsSearchHint => 'Buscar por nome do cliente...';

  @override
  String get debtsTabPending => 'Pendentes';

  @override
  String get debtsTabSettled => 'Quitadas';

  @override
  String get debtsTotalPending => 'Total a receber';

  @override
  String get debtsOverdueStat => 'Atrasados';

  @override
  String get debtsSettledStat => 'Baixas';

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
  String get debtsEmptyPendingTitle => 'Nenhum fiado pendente';

  @override
  String get debtsEmptyPendingSubtitle => 'Fiados aparecerão aqui.';

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
  String get debtsEmptySettledSubtitle => 'Fiados quitados aparecerão aqui.';

  @override
  String get debtsSettleTitle => 'Quitar dívida?';

  @override
  String debtsSettleBody(String amount, String name) {
    return 'Receber $amount de $name?';
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
  String get debtsSettleError => 'Não foi possível quitar. Tente novamente.';

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
  String debtsDueAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return 'Venceu há $_temp0';
  }

  @override
  String get debtsDueTodayDesc => 'Vence hoje';

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
      'Fiado registrado, mas a pendência não pôde ser criada.';

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
  String salesCartSection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return 'Carrinho · $_temp0';
  }

  @override
  String get salesLoadError => 'Não foi possível carregar as vendas.';

  @override
  String get salesEmptyTitle => 'Nenhuma venda registrada';

  @override
  String get salesEmptySubtitle =>
      'Toque em \"Nova venda\" para registrar a primeira.';

  @override
  String get salesSearchHint => 'Pesquisar venda...';

  @override
  String get periodYesterday => 'Ontem';

  @override
  String get paymentFilterCard => 'Cartão';

  @override
  String get paymentFilterAll => 'Todas';

  @override
  String get salesStatusPaid => 'Pago';

  @override
  String get salesFilterAll => 'Todas';

  @override
  String get salesFilterActive => 'Ativas';

  @override
  String get salesFilterCancelled => 'Anuladas';

  @override
  String salesHeaderTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transações',
      one: '1 transação',
      zero: '0 transações',
    );
    return '$_temp0';
  }

  @override
  String salesPdvCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vendas',
      one: '1 venda',
      zero: '0 vendas',
    );
    return '$_temp0';
  }

  @override
  String get salesHeaderVsYesterday => 'vs ontem';

  @override
  String get salesEmptyFilteredTitle => 'Nenhuma venda encontrada';

  @override
  String get salesEmptyFilteredSubtitle => 'Ajuste a busca ou os filtros.';

  @override
  String get salesClearFilters => 'Limpar filtros';

  @override
  String salesFilteredSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vendas',
      one: '1 venda',
    );
    return '$_temp0 · Total $total';
  }

  @override
  String get salesItemUnavailable =>
      'Item do carrinho não disponível. Tente novamente.';

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
  String get salesStatusCancelled => 'Anulada';

  @override
  String get saleDetailCancelAction => 'Anular venda';

  @override
  String get saleDetailCancelConfirmTitle => 'Anular esta venda?';

  @override
  String saleDetailCancelConfirmBody(String amount) {
    return 'Estoque será devolvido e caixa estornado ($amount).';
  }

  @override
  String get saleDetailCancelConfirm => 'Sim, anular';

  @override
  String get saleDetailCancelledAt => 'Anulada em';

  @override
  String get saleCancelledSuccess => 'Venda anulada.';

  @override
  String get saleNotFoundError => 'Esta venda não existe mais.';

  @override
  String get saleCancelError =>
      'Não foi possível anular a venda. Tente novamente.';

  @override
  String get saleDetailShareAction => 'Partilhar recibo';

  @override
  String get saleDetailShareTitle => 'Partilhar recibo';

  @override
  String get saleDetailShareImage => 'Partilhar como imagem';

  @override
  String get saleDetailShareWhatsApp => 'WhatsApp';

  @override
  String get saleDetailShareError =>
      'Não foi possível partilhar o recibo. Tente novamente.';

  @override
  String get saleDetailShareWhatsAppError =>
      'Não foi possível abrir o WhatsApp. Tente novamente.';

  @override
  String get saleDetailReceiptTitle => 'RECIBO DE VENDA';

  @override
  String get saleDetailReceiptTitleCancelled => 'RECIBO DE VENDA (ANULADA)';

  @override
  String get saleDetailReceiptPayment => 'Pagamento';

  @override
  String get saleDetailReceiptThanks => 'Obrigado pela preferência!';

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
  String get adminNothingPendingTitle => 'Nada pendente';

  @override
  String get adminNothingPendingSubtitle => 'Novas solicitações aparecem aqui.';

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
  String get adminRejectReasonHint => 'Ex.: informações incompletas';

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
  String get adminUpgradeApproved => 'Upgrade aprovado — plano atualizado!';

  @override
  String get adminUpgradeRejected => 'Upgrade rejeitado.';

  @override
  String get adminUpgradeProcessError => 'Não foi possível processar o pedido.';

  @override
  String get adminPlanRequested => 'Solicitado';

  @override
  String get adminPlanCurrent => 'Atual';

  @override
  String get productsExpiryHelp => 'Data de validade do produto';

  @override
  String get salesBarcodeLabel => 'Código de barras';

  @override
  String get salesBarcodeHint =>
      'Etiquetas de balança e PLUs — câmera ou leitor USB';

  @override
  String get salesBarcodeScan => 'Ler com a câmera';

  @override
  String get salesBarcodeNotFound => 'Produto não encontrado para este código.';

  @override
  String get salesBarcodeInvalid => 'Código de balança inválido.';

  @override
  String salesStockLimit(String product) {
    return 'Limite de estoque atingido para $product.';
  }

  @override
  String get salesQuantityLabel => 'Quantidade';

  @override
  String get salesQuantityHint => 'Quantidade (ex.: 1,75)';

  @override
  String get purchasesExpiryLabel => 'Validade';

  @override
  String get purchasesExpiryAdd => 'Definir validade';

  @override
  String get purchasesExpiryHelp => 'Data de validade do lote';

  @override
  String get dashboardExpiryAlerts => 'Validade';

  @override
  String dashboardExpiredIn(int days) {
    return 'Venceu há $days dia(s)';
  }

  @override
  String dashboardExpiresIn(int days) {
    return 'Vence em $days dia(s)';
  }
}
