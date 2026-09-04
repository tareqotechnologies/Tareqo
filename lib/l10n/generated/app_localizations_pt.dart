// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

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
  String get onboardingCurrencyLabel => 'Moeda';

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
  String get storeSelectorSectionTitle => 'Loja activa';

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
      'Sua conta foi desactivada pelo proprietário.';

  @override
  String get authBlockedSignOut => 'Sair';

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
  String get loginConfirmError => 'As senhas não coincidem.';

  @override
  String get loginSignUp => 'Cadastrar';

  @override
  String get loginSignIn => 'Entrar';

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
  String get dashboardOwnerFallback => 'Dono';

  @override
  String get commonUnits => 'un.';

  @override
  String get dashboardQuickActions => 'Ações rápidas';

  @override
  String get dashboardModuleCustomers => 'Clientes';

  @override
  String get dashboardModulePurchases => 'Compras';

  @override
  String get dashboardModuleReports => 'Relatórios';

  @override
  String get dashboardModuleStores => 'Lojas';

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
  String get employeesUpdateError =>
      'Não foi possível atualizar o funcionário. Tente novamente.';

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
  String employeeDeactivateConfirm(Object name) {
    return 'Desactivar $name? Perde acesso imediatamente.';
  }

  @override
  String employeeReactivateConfirm(Object name) {
    return 'Reactivar $name? Volta a ter acesso à loja.';
  }

  @override
  String get employeeDeactivated => 'Funcionário desactivado.';

  @override
  String get employeeReactivated => 'Funcionário reactivado.';

  @override
  String get employeeDeactivateAction => 'Desactivar';

  @override
  String get employeeReactivateAction => 'Reactivar';

  @override
  String get employeeDetailEmail => 'E-mail';

  @override
  String get employeeDetailStore => 'Loja';

  @override
  String get employeeDetailRole => 'Nível de acesso';

  @override
  String get employeeDetailStatus => 'Estado';

  @override
  String get employeeDetailActive => 'Activo';

  @override
  String get employeeDetailInactive => 'Inactivo';

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
  String get addStorePhoneLabel => 'Telefone (opcional)';

  @override
  String get addStoreEmailLabel => 'E-mail (opcional)';

  @override
  String get addStoreNuitLabel => 'NUIT (opcional)';

  @override
  String get addStoreCityLabel => 'Cidade (opcional)';

  @override
  String get storeDetailPhone => 'Telefone';

  @override
  String get storeDetailEmail => 'E-mail';

  @override
  String get storeDetailNuit => 'NUIT';

  @override
  String get storeDetailCity => 'Cidade';

  @override
  String get storeDetailAddress => 'Endereço';

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
  String get commonCopied => 'Copiado para a área de transferência';

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
  String get productsFilterAll => 'Todos';

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
  String get productsSalePrice => 'Preço de venda';

  @override
  String get productsStockQuantity => 'Quantidade em estoque';

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
  String get productsInactive => 'Inactivo';

  @override
  String get productsFilterTooltip => 'Filtrar';

  @override
  String get productsFilterAdvanced => 'Filtros avançados';

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
  String get productsActiveLabel => 'Produto activo';

  @override
  String get productsActiveHint => 'Desactive para tirar do PDV e compras.';

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
  String get productsPhotoTake => 'Tirar fotografia';

  @override
  String get productsPhotoGallery => 'Escolher da galeria';

  @override
  String get productsPhotoRemove => 'Remover fotografia';

  @override
  String get productsPurchasePriceError => 'Informe o preço de compra';

  @override
  String get productsSalePriceError => 'Informe o preço de venda';

  @override
  String get productsStockError => 'Quantidade inválida';

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
  String get financialPeriodBalance => 'Saldo líquido do período';

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
  String get periodYesterday => 'Ontem';

  @override
  String get periodWeek => 'Esta semana';

  @override
  String get paymentFilterCard => 'Cartão';

  @override
  String get paymentFilterAll => 'Todas';

  @override
  String get salesStatusPaid => 'Pago';

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
  String get adminPlansLoadError => 'Não foi possível carregar os planos.';

  @override
  String get adminPlansEmptyTitle => 'Nenhum plano criado';

  @override
  String get adminPlansEmptySubtitle =>
      'Crie o primeiro plano para liberar assinaturas.';

  @override
  String get adminPlanInactive => 'Inactivo';

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
  String get adminPlanActiveTitle => 'Plano activo';

  @override
  String get adminPlanActiveSubtitle =>
      'Desactive para impedir novas assinaturas.';

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
  String get productsCodeLabel => 'Código de barras (PLU)';

  @override
  String get productsCodeHint => 'Balanças etiquetadoras (ex.: 12345)';

  @override
  String get productsCodeError => 'Código inválido: use até 5 dígitos.';

  @override
  String get productsWeighLabel => 'Venda por peso (fração)';

  @override
  String get productsWeighHint => 'Aceita quantidades decimais (ex.: 1,75 kg)';

  @override
  String get productsUnitLabel => 'Unidade de venda';

  @override
  String get productsStockWeightHint => 'Em unidades da venda (ex.: 1,75)';

  @override
  String get productsExpiryLabel => 'Validade';

  @override
  String get productsExpiryAdd => 'Definir validade';

  @override
  String get productsExpiryHelp => 'Data de validade do produto';

  @override
  String get productsExpiryClear => 'Remover validade';

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
  String dashboardExpiredIn(int days) {
    return 'Venceu há $days dia(s)';
  }

  @override
  String dashboardExpiresIn(int days) {
    return 'Vence em $days dia(s)';
  }

  @override
  String get adminNavDashboard => 'Visão Geral';

  @override
  String get adminNavAuditLog => 'Registo de Auditoria';

  @override
  String get adminDashboardTitle => 'Visão Geral';

  @override
  String get adminDashboardTotalTenants => 'Total de tenants';

  @override
  String get adminDashboardActiveTenants => 'Activos';

  @override
  String get adminDashboardPendingTenants => 'Aguardando aprovação';

  @override
  String get adminDashboardPendingUpgrades => 'Upgrades pendentes';

  @override
  String get adminDashboardTotalPlans => 'Planos';

  @override
  String get adminDashboardLoadError =>
      'Não foi possível carregar a visão geral.';

  @override
  String get adminAuditLogEmpty => 'Nenhuma ação registada.';

  @override
  String get adminAuditLogEmptySubtitle =>
      'Ações administrativas aparecerão aqui.';

  @override
  String get adminTenantDetailOwner => 'ID do proprietário';

  @override
  String get adminTenantDetailPlan => 'Plano';

  @override
  String get adminTenantDetailStores => 'Lojas';

  @override
  String get adminTenantDetailEmployees => 'Funcionários';

  @override
  String get adminTenantDetailStatus => 'Estado';

  @override
  String get adminTenantDetailCreated => 'Criado em';

  @override
  String get adminTenantDetailCurrency => 'Moeda';

  @override
  String get adminTenantDetailLanguage => 'Idioma';

  @override
  String get adminTenantDetailRejectionReason => 'Motivo da rejeição';

  @override
  String get adminTenantDetailApprovedAt => 'Aprovado em';

  @override
  String adminTenantDetailStoresCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lojas',
      one: '1 loja',
    );
    return '$_temp0';
  }

  @override
  String adminTenantDetailEmployeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count funcionários',
      one: '1 funcionário',
    );
    return '$_temp0';
  }

  @override
  String get adminTenantSearchHint => 'Buscar tenants...';

  @override
  String get adminTenantDetailNoStores => 'Nenhuma loja criada';

  @override
  String get adminTenantDetailNoEmployees => 'Nenhum funcionário vinculado';

  @override
  String get adminTenantDetailActivity => 'Atividade recente';

  @override
  String get adminTenantDetailNoActivity =>
      'Nenhuma atividade recente para este tenant';

  @override
  String adminTenantDetailActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ações recentes',
      one: '1 ação recente',
    );
    return '$_temp0';
  }

  @override
  String adminTenantDetailEmployeeRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'manager': 'Gestor',
      'other': 'Funcionário',
    });
    return '$_temp0';
  }

  @override
  String get adminAuditLogAction => 'Ação';

  @override
  String get adminAuditLogEntity => 'Entidade';

  @override
  String get adminAuditLogDate => 'Data';

  @override
  String get adminAuditLogActor => 'Responsável';

  @override
  String get adminBulkSelectAll => 'Selecionar todos';

  @override
  String get adminBulkDeselectAll => 'Desmarcar todos';

  @override
  String adminBulkApprove(Object count) {
    return 'Aprovar ($count)';
  }

  @override
  String adminBulkReject(Object count) {
    return 'Rejeitar ($count)';
  }

  @override
  String adminBulkRejectTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants',
      one: 'tenant',
    );
    return 'Rejeitar $count $_temp0';
  }

  @override
  String adminBulkApproveSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants aprovados',
      one: 'tenant aprovado',
    );
    return '$count $_temp0';
  }

  @override
  String adminBulkRejectSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants rejeitados',
      one: 'tenant rejeitado',
    );
    return '$count $_temp0';
  }

  @override
  String get adminBulkApproveError =>
      'Erro ao aprovar tenants. Alguns podem não ter sido processados.';

  @override
  String get adminBulkRejectError =>
      'Erro ao rejeitar tenants. Alguns podem não ter sido processados.';

  @override
  String get adminActionManagePlans => 'Gerir Planos';

  @override
  String get adminActionViewAuditLog => 'Ver Registo de Auditoria';

  @override
  String get adminTenantRequests => 'Solicitações de Tenant';

  @override
  String get adminPlanUpgrades => 'Upgrades de Plano';

  @override
  String adminPendingActionRequired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ações necessárias',
      one: '1 ação necessária',
    );
    return '$_temp0';
  }

  @override
  String get adminAuditLogAll => 'Todos';

  @override
  String get adminAuditLogTenants => 'Tenants';

  @override
  String get adminAuditLogPlans => 'Planos';

  @override
  String get adminAuditLogUpgrades => 'Upgrades';

  @override
  String get adminAuditLogApproved => 'Aprovados';

  @override
  String get adminAuditLogRejected => 'Rejeitados';

  @override
  String get adminAuditLogToday => 'Hoje';

  @override
  String get adminAuditLogYesterday => 'Ontem';

  @override
  String get adminAuditLogThisWeek => 'Esta semana';

  @override
  String get adminAuditLogOlder => 'Mais antigo';

  @override
  String get adminAuditLogSearchHint => 'Pesquisar registo de auditoria...';

  @override
  String get adminAuditLogNoResults => 'Nenhuma entrada corresponde ao filtro.';

  @override
  String get adminDashboardPlanDistribution => 'Distribuição de planos';

  @override
  String get adminDashboardRecentActivity => 'Atividade recente';

  @override
  String get adminGrowthTrends => 'Tendências de Crescimento';

  @override
  String get adminGrowthThisWeek => 'Esta semana';

  @override
  String get adminGrowthLastWeek => 'Semana passada';

  @override
  String get adminGrowthThisMonth => 'Este mês';

  @override
  String get adminGrowthLastMonth => 'Mês passado';

  @override
  String get adminGrowthNewTenants => 'Novos tenants';

  @override
  String get adminGrowthApprovals => 'Aprovações';

  @override
  String adminGrowthUp(String count) {
    return '+$count';
  }

  @override
  String adminGrowthDown(String count) {
    return '-$count';
  }

  @override
  String get adminGrowthFlat => 'Sem alteração';

  @override
  String get adminGrowthRegistrationsTrend => 'Registos (últimas 8 semanas)';

  @override
  String get adminGrowthActivityTrend => 'Atividade (últimas 8 semanas)';

  @override
  String get adminGrowthNoData => 'Dados insuficientes para mostrar tendências';

  @override
  String get adminNavInvoices => 'Facturas';

  @override
  String get adminInvoicesTitle => 'Facturas de Cobrança';

  @override
  String get adminInvoicesEmpty => 'Nenhuma factura gerada ainda.';

  @override
  String get adminInvoicesEmptyPending => 'Nenhuma factura pendente.';

  @override
  String get adminInvoicesLoadError => 'Não foi possível carregar as facturas.';

  @override
  String get adminInvoiceSearchHint => 'Pesquisar facturas...';

  @override
  String get adminInvoiceAmount => 'Valor:';

  @override
  String get adminInvoiceDue => 'Vencimento:';

  @override
  String get adminInvoicePaidAt => 'Pago em:';

  @override
  String get adminInvoiceMarkPaid => 'Marcar como paga';

  @override
  String get adminInvoiceMarkedPaid => 'Factura marcada como paga!';

  @override
  String get adminInvoiceMarkPaidError =>
      'Não foi possível marcar como paga. Tente novamente.';

  @override
  String get adminInvoiceCancel => 'Cancelar';

  @override
  String get adminInvoiceCancelled => 'Factura cancelada.';

  @override
  String get adminInvoiceCancelError =>
      'Não foi possível cancelar a factura. Tente novamente.';

  @override
  String get adminInvoiceCancelTitle => 'Cancelar factura?';

  @override
  String adminInvoiceCancelConfirm(String period) {
    return 'Cancelar a factura de $period?';
  }

  @override
  String get adminInvoiceCancelConfirmButton => 'Sim, cancelar';

  @override
  String get invoiceStatusPending => 'Pendente';

  @override
  String get invoiceStatusPaid => 'Paga';

  @override
  String get invoiceStatusExpired => 'Expirada';

  @override
  String get invoiceStatusCancelled => 'Cancelada';

  @override
  String get notificationInvoiceGenerated => 'Nova factura gerada';

  @override
  String get notificationInvoiceDueSoon => 'Factura para vencer';

  @override
  String get notificationInvoiceExpired => 'Factura expirada';

  @override
  String get notificationInvoicePaid => 'Factura paga';

  @override
  String get notificationMarkAllRead => 'Marcar todas como lidas';

  @override
  String get notificationNoNotifications => 'Sem notificações';

  @override
  String get notificationNoNotificationsHint =>
      'As notificações de facturas aparecerão aqui.';

  @override
  String get notificationTabAll => 'Todas';

  @override
  String get notificationTabUnread => 'Não lidas';

  @override
  String get notificationTitle => 'Notificações';

  @override
  String get menuNotifications => 'Notificações';

  @override
  String notificationSinceDaysAgo(int count) {
    return '$count dias atrás';
  }

  @override
  String get notificationYesterday => 'Ontem';

  @override
  String get notificationJustNow => 'Agora mesmo';

  @override
  String get adminMessagesTitle => 'Mensagens para Tenants';

  @override
  String get adminMessagesSendSuccess => 'Mensagem enviada!';

  @override
  String get adminMessagesSendError =>
      'Não foi possível enviar a mensagem. Tente novamente.';

  @override
  String get adminMessagesTenantLabel => 'Tenant';

  @override
  String get adminMessagesTenantError => 'Selecione um tenant.';

  @override
  String get adminMessagesTypeLabel => 'Tipo';

  @override
  String get adminMessagesTitleLabel => 'Título';

  @override
  String get adminMessagesTitleError => 'Digite um título.';

  @override
  String get adminMessagesBodyLabel => 'Mensagem';

  @override
  String get adminMessagesBodyError => 'Digite o corpo da mensagem.';

  @override
  String get adminMessagesSubmit => 'Enviar';

  @override
  String get adminNavMessages => 'Mensagens';

  @override
  String get customInvoiceTitle => 'Factura Personalizada';

  @override
  String get customInvoiceEmpty => 'Nenhuma factura';

  @override
  String get customInvoiceEmptySubtitle =>
      'Crie facturas profissionais com layout\npersonalizado para os seus clientes';

  @override
  String get customInvoiceTemplateTooltip => 'Modelo da Factura';

  @override
  String get customInvoiceNewFab => 'Nova Factura';

  @override
  String customInvoiceItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get customInvoiceWhatsApp => 'WhatsApp';

  @override
  String get customInvoiceCreate => 'Criar Factura';

  @override
  String get customInvoiceClientSection => 'Cliente';

  @override
  String get customInvoiceClientName => 'Nome do cliente';

  @override
  String get customInvoicePhone => 'Telefone';

  @override
  String get customInvoiceTaxIdOptional => 'NIF / NUIT (opcional)';

  @override
  String get customInvoiceProductSection => 'Produto';

  @override
  String get customInvoiceProductPlaceholder => 'Sem produtos cadastrados';

  @override
  String customInvoiceProductOption(Object price, Object stock, Object unit) {
    return 'Estoque: $stock $unit  •  $price';
  }

  @override
  String get customInvoicePrice => 'Preço (MT)';

  @override
  String get customInvoiceQty => 'Qtd';

  @override
  String get customInvoiceAddItem => 'Adicionar';

  @override
  String get customInvoiceDiscount => 'Desconto (MT)';

  @override
  String get customInvoiceTax => 'IVA (MT)';

  @override
  String customInvoiceBillTotal(Object total) {
    return 'Total: $total';
  }

  @override
  String customInvoiceNumberPrefix(Object number) {
    return 'Nº $number';
  }

  @override
  String get customInvoiceTemplateSaved => 'Modelo guardado com sucesso';

  @override
  String get customInvoiceTemplateLogoSection => 'Logotipo da Empresa';

  @override
  String get customInvoiceTemplateLogoHint => 'Toque para carregar logotipo';

  @override
  String get customInvoiceTemplateColorSection => 'Cor Principal';

  @override
  String get customInvoiceTemplateCompanySection => 'Dados da Empresa';

  @override
  String get customInvoiceTemplateCompanyName => 'Nome da Empresa';

  @override
  String get customInvoiceTemplateAddress => 'Morada';

  @override
  String get customInvoiceTemplateTaxId => 'NIF / NUIT';

  @override
  String get customInvoiceTemplateStyle => 'Estilo';

  @override
  String get customInvoiceTemplateStyleClassic => 'Clássico';

  @override
  String get customInvoiceTemplateStyleModern => 'Moderno';

  @override
  String get customInvoiceTemplateStyleCompact => 'Compacto';

  @override
  String get customInvoiceTemplateSave => 'Salvar Modelo';

  @override
  String get customInvoicePreviewCompanyFallback => 'Nome da Empresa';

  @override
  String get quotationTitle => 'Cotações / Orçamentos';

  @override
  String get quotationEmpty => 'Nenhuma cotação';

  @override
  String get quotationEmptySubtitle =>
      'Crie cotações e orçamentos para os seus clientes';

  @override
  String get quotationTemplateTooltip => 'Modelo da Cotação';

  @override
  String get quotationNewFab => 'Nova Cotação';

  @override
  String quotationItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get quotationValidity => 'Validade';

  @override
  String quotationDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get quotationSend => 'Enviar';

  @override
  String get quotationAccept => 'Aceitar';

  @override
  String get quotationReject => 'Rejeitar';

  @override
  String get quotationStatusDraft => 'Rascunho';

  @override
  String get quotationStatusSent => 'Enviada';

  @override
  String get quotationStatusAccepted => 'Aceite';

  @override
  String get quotationStatusRejected => 'Rejeitada';

  @override
  String get quotationPhoneOptional => 'Telefone (opcional)';

  @override
  String quotationNumberPrefix(Object number) {
    return 'Nº $number';
  }

  @override
  String get quotationSave => 'Salvar Cotação';

  @override
  String get quotationTemplatePhone => 'Telefone';

  @override
  String get quotationTemplatePreview => 'Cotação • Preview';

  @override
  String get quotationTemplatePreviewBadge => 'Preview';

  @override
  String get paletteBlue => 'Azul';

  @override
  String get paletteGreen => 'Verde';

  @override
  String get paletteRed => 'Vermelho';

  @override
  String get paletteAmber => 'Âmbar';

  @override
  String get paletteSlate => 'Slate';

  @override
  String get paletteViolet => 'Violeta';

  @override
  String get paletteTeal => 'Teal';

  @override
  String get paletteIndigo => 'Indigo';

  @override
  String get customInvoicePdf => 'PDF';

  @override
  String get imageSourceGallery => 'Galeria';

  @override
  String get imageSourceCamera => 'Câmara';

  @override
  String get businessFallbackName => 'Minha Empresa';

  @override
  String get customInvoiceWhatsAppHeader => '═══ FACTURA ═══';

  @override
  String get customInvoiceNumberShort => 'Nº';

  @override
  String get customInvoiceClientLabel => 'Cliente';

  @override
  String get customInvoicePhoneLabel => 'Tel';

  @override
  String get customInvoiceTotalLabel => 'TOTAL';

  @override
  String get customInvoiceNew => 'Nova Factura';

  @override
  String get customInvoiceTemplateTitle => 'Modelo da Factura';

  @override
  String get commonPreview => 'Preview';

  @override
  String get quotationWhatsAppHeader => '═══ COTAÇÃO ═══';

  @override
  String get quotationTemplateTitle => 'Modelo da Cotação';

  @override
  String get employeeMgmtTitle => 'Gestão de Funcionários';

  @override
  String get employeeMgmtTabAttendance => 'Ponto';

  @override
  String get employeeMgmtTabCommissions => 'Comissões';

  @override
  String get employeeMgmtTabTargets => 'Metas';

  @override
  String get employeePresentCount => 'Presentes';

  @override
  String get employeeAbsentCount => 'Ausentes';

  @override
  String get employeeClockInAction => 'Entrar';

  @override
  String get employeeClockOutAction => 'Sair';

  @override
  String get employeeClockOutInProgress => 'Em curso';

  @override
  String get employeeAttendanceSection => 'Registo de Ponto';

  @override
  String get employeeRecordsSection => 'Registos de Hoje';

  @override
  String get employeeSalesMonth => 'Vendas do Mês';

  @override
  String get employeeCommissionTitle => 'Comissões';

  @override
  String get employeeCommissionPerEmployee => 'Comissão por Funcionário';

  @override
  String employeeCommissionRate(Object amount, Object rate) {
    return '$rate% sobre $amount';
  }

  @override
  String get employeeTargetsActive => 'Metas Activas';

  @override
  String get employeeTargetsReached => 'Atingidas';

  @override
  String get employeeTargetsPending => 'Pendentes';

  @override
  String get employeeTargetsMonth => 'Metas do Mês';

  @override
  String get employeeTargetsEmptyTitle => 'Nenhuma meta definida';

  @override
  String get employeeTargetsEmptySubtitle =>
      'Defina metas mensais de vendas para cada funcionário';

  @override
  String get employeeTargetAdd => 'Adicionar Meta';

  @override
  String employeeTargetMeta(Object amount) {
    return 'Meta: $amount';
  }

  @override
  String employeeTargetAchieved(Object amount) {
    return 'Realizado: $amount';
  }

  @override
  String get employeeTargetNewTitle => 'Nova Meta';

  @override
  String get employeeTargetEmployee => 'Funcionário';

  @override
  String get employeeTargetAllHave =>
      'Todos os funcionários já possuem meta definida';

  @override
  String get employeeTargetMonthly => 'Meta Mensal (MT)';

  @override
  String get employeeTargetSave => 'Salvar Meta';

  @override
  String get employeeRoleSales => 'Vendedor';

  @override
  String get addonsTitle => 'Add-ons';

  @override
  String get addonsSubtitle => 'Add-ons activos e disponíveis no seu plano';

  @override
  String get addonsManagedByAdmin =>
      'A activação de add-ons é gerida pelo administrador do sistema.';

  @override
  String get addonsIncluded => 'Incluído';

  @override
  String get addonsActive => 'Activo';

  @override
  String addonsPerMonth(Object amount) {
    return '$amount MT/mês';
  }

  @override
  String get addonCategoryInvoicing => 'Facturação';

  @override
  String get addonCategoryQuotation => 'Cotação';

  @override
  String get addonCategoryReports => 'Relatórios';

  @override
  String get addonCategoryEmployees => 'Funcionários';

  @override
  String get addonCategoryMultiStore => 'Multi-Loja';

  @override
  String get addonCategoryPayments => 'Pagamentos';

  @override
  String get commonTotal => 'Total';

  @override
  String get addonCustomInvoiceName => 'Factura Personalizada';

  @override
  String get addonCustomInvoiceDesc =>
      'Crie facturas profissionais com logotipo, layout customizável e exportação em PDF. Inclui templates prontos e personalização de cores, fontes e campos.';

  @override
  String get addonQuotationName => 'Cotação / Orçamento';

  @override
  String get addonQuotationDesc =>
      'Crie e envie cotações e orçamentos para clientes antes da venda. Inclui conversão automática para venda, validade configurável e envio por SMS/WhatsApp.';

  @override
  String get addonReportsName => 'Relatórios Avançados';

  @override
  String get addonReportsDesc =>
      'Relatórios financeiros, de vendas e estoque com filtros avançados, comparativos período a período e exportação em PDF/Excel. Inclui gráficos interativos e dashboards personalizados.';

  @override
  String get addonEmployeesName => 'Gestão de Funcionários';

  @override
  String get addonEmployeesDesc =>
      'Controle de ponto (entrada/saída), cálculo automático de comissões por venda, definição de metas mensais e relatório de desempenho individual.';

  @override
  String get addonMultiStoreName => 'Multi-Loja Avançado';

  @override
  String get addonMultiStoreDesc =>
      'Transferência de estoque entre lojas, relatórios consolidados comparando lojas, gestão centralizada de preços e promoções e alertas de reposição automática.';

  @override
  String get addonMobileMoneyName => 'Integração M-Pesa / E-Mola';

  @override
  String get addonMobileMoneyDesc =>
      'Pagamentos automáticos via mobile money com reconciliação automática, notificações de recebimento em tempo real e relatório de transações mobile money.';

  @override
  String get transfersTitle => 'Transferências entre Lojas';

  @override
  String get transfersEmpty => 'Sem transferências';

  @override
  String get transfersEmptySubtitle =>
      'Transfira estoque entre lojas do\nmesmo tenant de forma rastreável';

  @override
  String get transfersNewFab => 'Nova Transferência';

  @override
  String get transfersOriginStore => 'Loja de Origem';

  @override
  String get transfersDestStore => 'Loja de Destino';

  @override
  String get transfersProduct => 'Produto';

  @override
  String get transfersProductPlaceholder => 'Sem produtos cadastrados';

  @override
  String get transfersQuantity => 'Quantidade';

  @override
  String get transfersAddItem => 'Adicionar';

  @override
  String get transfersExecuting => 'A transferir...';

  @override
  String get transfersExecute => 'Executar Transferência';

  @override
  String get transfersNoStoresTitle => 'Cadastre pelo menos 2 lojas';

  @override
  String get transfersNoStoresSubtitle =>
      'É necessário ter 2+ lojas para\ntransferir estoque entre elas';

  @override
  String transfersSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produtos transferidos',
      one: '1 produto transferido',
    );
    return '$_temp0 com sucesso';
  }

  @override
  String transfersError(Object error) {
    return 'Erro na transferência: $error';
  }

  @override
  String get transferStatusPending => 'Pendente';

  @override
  String get transferStatusInTransit => 'Em Trânsito';

  @override
  String get transferStatusReceived => 'Recebida';

  @override
  String get transferStatusCancelled => 'Cancelada';

  @override
  String get paymentsTitle => 'M-Pesa / E-Mola';

  @override
  String get paymentsEmpty => 'Sem transacções';

  @override
  String get paymentsEmptySubtitle =>
      'Registe pagamentos recebidos via\nM-Pesa ou E-Mola para reconciliação';

  @override
  String get paymentsNewFab => 'Registar Pagamento';

  @override
  String get paymentsStatusConfirmed => 'Confirmada';

  @override
  String get paymentsStatusPending => 'Pendente';

  @override
  String get paymentsStatusRejected => 'Rejeitada';

  @override
  String get paymentsConfirm => 'Confirmar';

  @override
  String get paymentsReject => 'Rejeitar';

  @override
  String paymentsReference(Object code) {
    return 'Ref: $code';
  }

  @override
  String get paymentsSheetTitle => 'Registar Pagamento';

  @override
  String get paymentsSenderPhone => 'Telefone do remetente';

  @override
  String get paymentsAmount => 'Valor (MT)';

  @override
  String get paymentsConfirmationCode => 'Código de confirmação';

  @override
  String get reportsAdvancedTitle => 'Relatórios Avançados';

  @override
  String get reportsTabSales => 'Vendas';

  @override
  String get reportsTabFinancial => 'Financeiro';

  @override
  String get reportsTabStock => 'Estoque';

  @override
  String get reportsKpiProducts => 'Produtos';

  @override
  String get reportsKpiLowStock => 'Estoque Baixo';

  @override
  String get reportsKpiTotalItems => 'Total Itens';

  @override
  String get reportsKpiStockValue => 'Valor Estoque';

  @override
  String get reportsKpiRevenue => 'Receitas';

  @override
  String get reportsKpiExpenses => 'Despesas';

  @override
  String get reportsKpiNetProfit => 'Lucro Líquido';

  @override
  String get reportsStockByQty => 'Produtos por Estoque';

  @override
  String get reportsCashFlow => 'Fluxo de Caixa';

  @override
  String get reportsCashFlowChart => 'Gráfico de fluxo de caixa';

  @override
  String get reportsNoProducts => 'Sem produtos cadastrados';

  @override
  String get reportsStockHealthy => 'Todos os produtos com estoque adequado';

  @override
  String get reportsExportSales => 'Exportar Relatório (PDF)';

  @override
  String get reportsExportFinancial => 'Exportar Financeiro (PDF)';

  @override
  String get reportsExportStock => 'Exportar Estoque (PDF)';

  @override
  String get reportsNoSalesData => 'Sem dados para este período';

  @override
  String get reportsPeriodYear => 'Este Ano';

  @override
  String get reportsKpiStockOut => 'Sem Estoque';

  @override
  String get reportsKpiTotalProducts => 'Total Produtos';

  @override
  String pdfGeneratedOn(Object date) {
    return 'Gerado: $date';
  }

  @override
  String get pdfIndicators => 'Indicadores';

  @override
  String pdfFooter(Object date) {
    return 'Documento gerado pelo TAREQO — $date';
  }

  @override
  String get pdfInvoiceDocWord => 'FACTURA';

  @override
  String get pdfInvoiceSubjectWord => 'Factura';

  @override
  String get pdfInvoiceFileBase => 'factura';

  @override
  String get pdfQuotationDocWord => 'COTAÇÃO';

  @override
  String get pdfQuotationSubjectWord => 'Cotação';

  @override
  String get pdfQuotationFileBase => 'cotacao';

  @override
  String get pdfClientHeading => 'CLIENTE';

  @override
  String pdfPhoneLine(Object value) {
    return 'Tel: $value';
  }

  @override
  String pdfEmailLine(Object value) {
    return 'Email: $value';
  }

  @override
  String pdfNifLine(Object value) {
    return 'NIF: $value';
  }

  @override
  String get pdfItemHeader => 'Item';

  @override
  String get pdfUnitPriceHeader => 'Preço Unit.';

  @override
  String get pdfSubtotalHeader => 'Subtotal';

  @override
  String get pdfDiscountLabel => 'Desconto';

  @override
  String get pdfTaxLabel => 'IVA';

  @override
  String pdfPaymentLine(Object value) {
    return 'Pagamento: $value';
  }

  @override
  String pdfReferenceLine(Object value) {
    return 'Ref: $value';
  }

  @override
  String get pdfNotesHeading => 'Notas';

  @override
  String get pdfGeneralConditionsHeading => 'Condições Gerais';

  @override
  String pdfValidityDaysLeft(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias restantes',
      one: '1 dia restante',
    );
    return '$_temp0';
  }

  @override
  String pdfConditionValidBullet(Object date) {
    return 'Esta cotação é válida até $date.';
  }

  @override
  String get pdfConditionPricesBullet =>
      'Preços sujeitos a alteração após o prazo de validade.';

  @override
  String get pdfConditionContactBullet =>
      'Para aceitar esta cotação, entre em contacto connosco.';

  @override
  String get quotationStatusExpired => 'Expirada';

  @override
  String get quotationStatusConverted => 'Convertida em Venda';

  @override
  String get pdfConditionsNotesHeading => 'Condições / Notas';

  @override
  String get adminAddonsActivateBtn => 'Activar';

  @override
  String get adminAddonsActivateBulk => 'Activar add-on';

  @override
  String get adminAddonsActivePill => 'Activos';

  @override
  String get adminAddonsDeactivateBtn => 'Desactivar';

  @override
  String get adminAddonsInactivePill => 'Inactivos';

  @override
  String adminAddonsLoadError(Object error) {
    return 'Erro: $error';
  }

  @override
  String get adminAddonsNoTenantsSearchSub => 'Tente outro termo de busca';

  @override
  String get adminAddonsNoTenantsTitle => 'Nenhum tenant encontrado';

  @override
  String get adminAddonsNoTenantsYetSub => 'Nenhum tenant aprovado ainda';

  @override
  String adminAddonsUpdateError(Object error) {
    return 'Erro ao actualizar add-on: $error';
  }

  @override
  String get adminBackToList => 'Voltar à lista';

  @override
  String get adminMessagesBodyHint => 'Escreva a mensagem…';

  @override
  String get adminMessagesTenantHint => 'Selecionar tenant...';

  @override
  String get adminMessagesTitleExample => 'Ex: Cotação de Plano Pro';

  @override
  String get adminNavRevenue => 'Receitas';

  @override
  String get adminPlansActive => 'Activos';

  @override
  String get adminPlansInactive => 'Inactivos';

  @override
  String get adminRevenueActiveTenants => 'Tenants Activos';

  @override
  String get adminRevenueActiveTenantsSub => 'Total na plataforma';

  @override
  String get adminRevenueAvailableAddOns => 'Add-ons Disponíveis';

  @override
  String get adminRevenueAvailableAddOnsSub => 'No catálogo activo';

  @override
  String get adminRevenueMaxMonthly => 'Receita mensal máxima';

  @override
  String get adminRevenueMaxMonthlySub => 'Se todos activassem todos';

  @override
  String get adminRevenuePotential => 'Receita Potencial';

  @override
  String get adminRevenuePotentialSub => 'Por tenant/mês (todos os add-ons)';

  @override
  String get adminTenantsMonthlyValue => 'Valor mensal';

  @override
  String get adminTenantsNextInvoice => 'Próxima factura';

  @override
  String get adminTenantsPlanExpiresOn => 'Plano expira em';

  @override
  String get adminTenantsTrialEndsOn => 'Trial termina em';

  @override
  String get commonId => 'ID';

  @override
  String dashboardSaleEntry(Object number) {
    return 'Venda $number';
  }

  @override
  String get loginConfirmPasswordHint => 'Repita a senha';

  @override
  String get loginConfirmPasswordLabel => 'Confirmar senha';

  @override
  String get loginEmailHint => 'Digite seu email';

  @override
  String get loginForgotPassword => 'Esqueceu sua senha?';

  @override
  String get loginNameHint => 'Digite seu nome';

  @override
  String get loginPasswordHint => 'Digite sua senha';

  @override
  String get loginPromptHaveAccount => 'Já tem uma conta?';

  @override
  String get loginPromptNoAccount => 'Ainda não tem uma conta?';

  @override
  String get loginTagline => 'Gestão simples para o seu negócio';

  @override
  String get mfaCodeFieldLabel => 'Código MFA';

  @override
  String get mfaCodeHint =>
      'Digite o código de 6 dígitos do seu aplicativo autenticador:';

  @override
  String get mfaCodeLengthError => 'Digite o código de 6 dígitos';

  @override
  String get mfaConfirmPrompt =>
      'Digite o código do aplicativo para confirmar:';

  @override
  String get mfaDigitsFieldLabel => 'Código de 6 dígitos';

  @override
  String mfaExpiresIn(num seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds segundos',
      one: '1 segundo',
    );
    return 'Código expira em $_temp0';
  }

  @override
  String mfaInitError(Object error) {
    return 'Erro ao inicializar MFA: $error';
  }

  @override
  String get mfaInvalidCode => 'Código inválido. Tente novamente.';

  @override
  String get mfaManualEntryTitle => 'Ou digite este código manualmente:';

  @override
  String get mfaQrScanHelp =>
      'Use seu aplicativo autenticador (Google Authenticator, Authy, etc.) para escanear este código QR:';

  @override
  String get mfaQrScanTitle => 'Escaneie o QR Code';

  @override
  String get mfaSetupSuccess => 'MFA configurado com sucesso!';

  @override
  String get mfaSetupTitle => 'Configurar Autenticação em Dois Fatores';

  @override
  String get mfaVerify => 'Verificar';

  @override
  String get mfaVerifyAndEnable => 'Verificar e Activar';

  @override
  String mfaVerifyError(Object error) {
    return 'Erro ao verificar código: $error';
  }

  @override
  String get securityBiometricDisabledSub =>
      'Use impressão digital ou reconhecimento facial';

  @override
  String get securityBiometricEnabledSub =>
      'Activada — Impressão digital ou rosto';

  @override
  String get securityBiometricTitle => 'Autenticação Biométrica';

  @override
  String get securityBiometricUnavailable => 'Não disponível neste dispositivo';

  @override
  String get securityTwoFactorDisabledSub =>
      'Adicione uma camada extra de segurança';

  @override
  String get securityTwoFactorEnabledSub =>
      'Activada — Use um app autenticador';

  @override
  String get securityTwoFactorTitle => 'Autenticação em Dois Fatores';

  @override
  String get transfersRowDate => 'Data';

  @override
  String get transfersRowDest => 'Destino';

  @override
  String get transfersRowOrigin => 'Origem';

  @override
  String get transfersRowStatus => 'Estado';

  @override
  String adminAddonsBulkActivated(Object addonName, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$addonName activado em $_temp0';
  }

  @override
  String adminAddonsBulkDeactivated(Object addonName, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$addonName desactivado em $_temp0';
  }

  @override
  String adminAddonsBulkSheetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants selecionados',
      one: '1 tenant selecionado',
    );
    return '$_temp0';
  }

  @override
  String get adminAddonsBulkSheetTitle => 'Activar add-on em lote';

  @override
  String get adminAddonsListHint =>
      'Toque num tenant para gerir os seus add-ons. Toque no ícone ✓ para seleção múltipla.';

  @override
  String adminAddOnsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count add-ons',
      one: '1 add-on',
    );
    return '$_temp0';
  }

  @override
  String get adminRevenueByAddOn => 'Receita por Add-on';

  @override
  String get adminRevenueByCategory => 'Distribuição por Categoria';

  @override
  String get adminRevenuePerMonth => 'potencial/mês';

  @override
  String get adminPlanPerMonthSuffix => '/mês';

  @override
  String adminTenantCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$_temp0';
  }

  @override
  String adminTenantCycleActiveLeft(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias restantes',
      one: '1 dia restante',
    );
    return 'Activo: $_temp0';
  }

  @override
  String get adminTenantCycleExpired => 'Expirado';

  @override
  String adminTenantCycleExpiresIn(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return 'Expira em $_temp0';
  }

  @override
  String adminTenantCycleTrialLeft(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias restantes',
      one: '1 dia restante',
    );
    return 'Trial: $_temp0';
  }
}
