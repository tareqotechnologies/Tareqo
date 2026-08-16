import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dumbhanengue ERP'**
  String get appTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo!'**
  String get onboardingTitle;

  /// No description provided for @onboardingHeading.
  ///
  /// In pt, this message translates to:
  /// **'Ative seu negócio no ERP'**
  String get onboardingHeading;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um plano, informe o nome do seu negócio e defina a moeda e o idioma. Seu acesso será liberado após a aprovação (prazo de até 24h).'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingBusinessLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do negócio'**
  String get onboardingBusinessLabel;

  /// No description provided for @onboardingBusinessError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do seu negócio.'**
  String get onboardingBusinessError;

  /// No description provided for @onboardingPlanLabel.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o plano'**
  String get onboardingPlanLabel;

  /// No description provided for @onboardingPlansError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os planos.'**
  String get onboardingPlansError;

  /// Resumo dos limites do plano
  ///
  /// In pt, this message translates to:
  /// **'{stores} loja(s) · {employees} funcionário(s)'**
  String onboardingPlanDetails(int stores, int employees);

  /// No description provided for @onboardingSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar acesso'**
  String get onboardingSubmit;

  /// Feedback após enviar a solicitação de acesso
  ///
  /// In pt, this message translates to:
  /// **'Solicitação de {business} enviada! Aguarde a aprovação (até 24h).'**
  String onboardingSuccess(String business);

  /// No description provided for @onboardingChoosePlanError.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um plano para continuar.'**
  String get onboardingChoosePlanError;

  /// No description provided for @onboardingGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar a solicitação. Tente novamente.'**
  String get onboardingGenericError;

  /// No description provided for @onboardingLanguageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get onboardingLanguageLabel;

  /// No description provided for @onboardingLanguageHint.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do aplicativo'**
  String get onboardingLanguageHint;

  /// No description provided for @onboardingCurrencyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Moeda'**
  String get onboardingCurrencyLabel;

  /// No description provided for @onboardingCurrencyHint.
  ///
  /// In pt, this message translates to:
  /// **'Moeda usada nos valores'**
  String get onboardingCurrencyHint;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In pt, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @currencyBrl.
  ///
  /// In pt, this message translates to:
  /// **'Real (BRL)'**
  String get currencyBrl;

  /// No description provided for @currencyUsd.
  ///
  /// In pt, this message translates to:
  /// **'Dólar (USD)'**
  String get currencyUsd;

  /// No description provided for @currencyEur.
  ///
  /// In pt, this message translates to:
  /// **'Euro (EUR)'**
  String get currencyEur;

  /// No description provided for @currencyMzn.
  ///
  /// In pt, this message translates to:
  /// **'Metical (MZN)'**
  String get currencyMzn;

  /// No description provided for @settingsSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar ajustes'**
  String get settingsSave;

  /// No description provided for @settingsSaved.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes salvos!'**
  String get settingsSaved;

  /// No description provided for @settingsGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar os ajustes. Tente novamente.'**
  String get settingsGenericError;

  /// No description provided for @settingsSupportSection.
  ///
  /// In pt, this message translates to:
  /// **'Suporte'**
  String get settingsSupportSection;

  /// No description provided for @settingsSupportEntry.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda e documentação'**
  String get settingsSupportEntry;

  /// No description provided for @settingsSupportEntryHint.
  ///
  /// In pt, this message translates to:
  /// **'Guia do Usuário e Troubleshooting — leitura sem internet'**
  String get settingsSupportEntryHint;

  /// No description provided for @supportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Tudo o que precisa para tirar o máximo do app: o guia completo do usuário e a resolução dos problemas mais comuns.'**
  String get supportSubtitle;

  /// No description provided for @supportUserGuide.
  ///
  /// In pt, this message translates to:
  /// **'Guia do Usuário'**
  String get supportUserGuide;

  /// No description provided for @supportUserGuideHint.
  ///
  /// In pt, this message translates to:
  /// **'Manual simples e completo: login, lojas, produtos (com foto), vendas, fiado, financeiro, fecho de caixa, relatórios e FAQ'**
  String get supportUserGuideHint;

  /// No description provided for @supportTroubleshooting.
  ///
  /// In pt, this message translates to:
  /// **'Troubleshooting'**
  String get supportTroubleshooting;

  /// No description provided for @supportTroubleshootingHint.
  ///
  /// In pt, this message translates to:
  /// **'Resolução de problemas comuns: login, fotos, vendas, estoque, caixa, conexão e mensagens de erro'**
  String get supportTroubleshootingHint;

  /// No description provided for @supportReadingError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o documento. Tente novamente.'**
  String get supportReadingError;

  /// No description provided for @commonSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar...'**
  String get commonSearch;

  /// No description provided for @commonRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get commonRetry;

  /// No description provided for @commonSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get commonSignOut;

  /// No description provided for @appSheetClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get appSheetClose;

  /// No description provided for @storeSwitcherTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Trocar de loja'**
  String get storeSwitcherTooltip;

  /// No description provided for @storeSelectorSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Loja ativa'**
  String get storeSelectorSectionTitle;

  /// No description provided for @storeSelectorSectionHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a loja cujos dados aparecem nos módulos (vendas, estoque, financeiro).'**
  String get storeSelectorSectionHint;

  /// No description provided for @tenantPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando aprovação'**
  String get tenantPendingTitle;

  /// No description provided for @tenantPendingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'A solicitação de acesso de \"{business}\" foi enviada com sucesso. O super admin vai analisar e você receberá acesso em até 24h.'**
  String tenantPendingSubtitle(String business);

  /// No description provided for @tenantPendingHint.
  ///
  /// In pt, this message translates to:
  /// **'Assim que aprovado, você poderá criar lojas, contratar funcionários e começar a operar.'**
  String get tenantPendingHint;

  /// No description provided for @tenantRejectedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação rejeitada'**
  String get tenantRejectedTitle;

  /// No description provided for @tenantRejectedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'A solicitação de acesso de \"{business}\" não foi aprovada.'**
  String tenantRejectedSubtitle(String business);

  /// No description provided for @authBlockedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesso suspenso'**
  String get authBlockedTitle;

  /// No description provided for @authBlockedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta de funcionário foi desativada pelo dono do estabelecimento. Se tiver dúvidas, fale com ele.'**
  String get authBlockedMessage;

  /// No description provided for @authBlockedSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get authBlockedSignOut;

  /// No description provided for @authErrorRestoreSession.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível restaurar sua sessão'**
  String get authErrorRestoreSession;

  /// No description provided for @authErrorCheckConnection.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão e tente novamente.'**
  String get authErrorCheckConnection;

  /// No description provided for @authErrorLoadAccount.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar sua conta'**
  String get authErrorLoadAccount;

  /// No description provided for @splashLoading.
  ///
  /// In pt, this message translates to:
  /// **'A abrir a sua sessão…'**
  String get splashLoading;

  /// No description provided for @loginSubtitleSignUp.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua conta para começar'**
  String get loginSubtitleSignUp;

  /// No description provided for @loginSubtitleSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Gestão simples para o seu negócio'**
  String get loginSubtitleSignIn;

  /// No description provided for @loginNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get loginNameLabel;

  /// No description provided for @loginEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail válido.'**
  String get loginEmailError;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordError.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter ao menos 8 caracteres.'**
  String get loginPasswordError;

  /// No description provided for @loginPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Mín. 8 caracteres com minúscula, maiúscula, número e símbolo.'**
  String get loginPasswordHint;

  /// No description provided for @loginWeakPasswordError.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve conter letras minúsculas, maiúsculas, números e símbolos.'**
  String get loginWeakPasswordError;

  /// No description provided for @loginRateLimitError.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas seguidas. Aguarde cerca de 1 hora e tente novamente.'**
  String get loginRateLimitError;

  /// No description provided for @loginShowPassword.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar senha'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar senha'**
  String get loginHidePassword;

  /// No description provided for @loginConfirmLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get loginConfirmLabel;

  /// No description provided for @loginConfirmError.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem.'**
  String get loginConfirmError;

  /// No description provided for @loginSignUp.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get loginSignUp;

  /// No description provided for @loginSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginSignIn;

  /// No description provided for @loginSwitchToSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Já tenho conta — entrar'**
  String get loginSwitchToSignIn;

  /// No description provided for @loginSwitchToSignUp.
  ///
  /// In pt, this message translates to:
  /// **'Não tenho conta — cadastrar'**
  String get loginSwitchToSignUp;

  /// No description provided for @loginSignUpSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Conta criada! Confirme seu e-mail para entrar.'**
  String get loginSignUpSuccess;

  /// No description provided for @loginSignUpError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar a conta. Tente novamente.'**
  String get loginSignUpError;

  /// No description provided for @loginSignInError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar. Verifique e-mail e senha.'**
  String get loginSignInError;

  /// No description provided for @loginSecurityNote.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados ficam protegidos com criptografia.'**
  String get loginSecurityNote;

  /// No description provided for @loginForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu a senha?'**
  String get loginForgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Redefinir senha'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Informe o e-mail da sua conta. Enviamos um link para você criar uma nova senha.'**
  String get forgotPasswordHint;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Enviar link'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In pt, this message translates to:
  /// **'Se existir uma conta com este e-mail, enviamos um link para redefinir a senha.'**
  String get forgotPasswordSent;

  /// No description provided for @forgotPasswordError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar o link. Tente novamente.'**
  String get forgotPasswordError;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Definir nova senha'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Mín. 8 caracteres com minúscula, maiúscula, número e símbolo.'**
  String get setNewPasswordHint;

  /// No description provided for @setNewPasswordSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Salvar nova senha'**
  String get setNewPasswordSubmit;

  /// No description provided for @setNewPasswordSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Senha atualizada!'**
  String get setNewPasswordSuccess;

  /// No description provided for @setNewPasswordError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar a senha. Tente novamente.'**
  String get setNewPasswordError;

  /// No description provided for @setNewPasswordSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get setNewPasswordSignOut;

  /// No description provided for @changePasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Trocar senha'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nova senha'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar nova senha'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Senha alterada com sucesso!'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordWrongCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual incorreta. Tente novamente.'**
  String get changePasswordWrongCurrent;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Alterar senha'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar a senha. Tente novamente.'**
  String get changePasswordError;

  /// No description provided for @securitySectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Segurança'**
  String get securitySectionTitle;

  /// No description provided for @securityChangePassword.
  ///
  /// In pt, this message translates to:
  /// **'Trocar senha'**
  String get securityChangePassword;

  /// No description provided for @securityChangePasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Atualize a senha da sua conta'**
  String get securityChangePasswordHint;

  /// No description provided for @appNavHome.
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get appNavHome;

  /// No description provided for @appNavProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get appNavProducts;

  /// No description provided for @appNavSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get appNavSales;

  /// No description provided for @appNavFinancial.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get appNavFinancial;

  /// No description provided for @appNavCredit.
  ///
  /// In pt, this message translates to:
  /// **'Crédito'**
  String get appNavCredit;

  /// No description provided for @appNavCustomers.
  ///
  /// In pt, this message translates to:
  /// **'Clientes'**
  String get appNavCustomers;

  /// No description provided for @syncPendingCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 operação aguardando sincronização} other{{count} operações aguardando sincronização}}'**
  String syncPendingCount(int count);

  /// No description provided for @syncNow.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar'**
  String get syncNow;

  /// No description provided for @syncOfflineSaved.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. A operação foi salva e será sincronizada automaticamente.'**
  String get syncOfflineSaved;

  /// No description provided for @syncDone.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 operação sincronizada} other{{count} operações sincronizadas}}'**
  String syncDone(int count);

  /// No description provided for @syncStillOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão — as operações continuam pendentes.'**
  String get syncStillOffline;

  /// No description provided for @dashboardGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name} 👋'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardSignOutTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get dashboardSignOutTooltip;

  /// No description provided for @dashboardOwnerFallback.
  ///
  /// In pt, this message translates to:
  /// **'Dono'**
  String get dashboardOwnerFallback;

  /// No description provided for @dashboardTotalSales.
  ///
  /// In pt, this message translates to:
  /// **'Total de vendas'**
  String get dashboardTotalSales;

  /// No description provided for @dashboardAllTime.
  ///
  /// In pt, this message translates to:
  /// **'Todo o histórico'**
  String get dashboardAllTime;

  /// No description provided for @dashboardCashBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo em caixa'**
  String get dashboardCashBalance;

  /// No description provided for @dashboardReceivables.
  ///
  /// In pt, this message translates to:
  /// **'A receber (fiado)'**
  String get dashboardReceivables;

  /// No description provided for @dashboardStockLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estoque em produtos'**
  String get dashboardStockLabel;

  /// No description provided for @commonUnits.
  ///
  /// In pt, this message translates to:
  /// **'un.'**
  String get commonUnits;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In pt, this message translates to:
  /// **'Ações rápidas'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardQuickNewSale.
  ///
  /// In pt, this message translates to:
  /// **'Nova venda'**
  String get dashboardQuickNewSale;

  /// No description provided for @dashboardQuickAddProduct.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar produto'**
  String get dashboardQuickAddProduct;

  /// No description provided for @dashboardQuickAddTransaction.
  ///
  /// In pt, this message translates to:
  /// **'Registrar transação'**
  String get dashboardQuickAddTransaction;

  /// No description provided for @dashboardQuickAddDebt.
  ///
  /// In pt, this message translates to:
  /// **'Registrar fiado'**
  String get dashboardQuickAddDebt;

  /// No description provided for @dashboardModules.
  ///
  /// In pt, this message translates to:
  /// **'Módulos'**
  String get dashboardModules;

  /// No description provided for @dashboardModuleCustomers.
  ///
  /// In pt, this message translates to:
  /// **'Clientes'**
  String get dashboardModuleCustomers;

  /// No description provided for @dashboardModulePurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get dashboardModulePurchases;

  /// No description provided for @dashboardModuleReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get dashboardModuleReports;

  /// No description provided for @dashboardModuleStores.
  ///
  /// In pt, this message translates to:
  /// **'Lojas'**
  String get dashboardModuleStores;

  /// No description provided for @dashboardRecentSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas recentes'**
  String get dashboardRecentSales;

  /// No description provided for @dashboardViewAll.
  ///
  /// In pt, this message translates to:
  /// **'Ver todas'**
  String get dashboardViewAll;

  /// No description provided for @dashboardNoSales.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma venda ainda — registre a primeira!'**
  String get dashboardNoSales;

  /// No description provided for @dashboardRecentPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Compras recentes'**
  String get dashboardRecentPurchases;

  /// No description provided for @dashboardNoPurchases.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma compra ainda — registre a primeira!'**
  String get dashboardNoPurchases;

  /// No description provided for @dashboardLowStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque baixo'**
  String get dashboardLowStock;

  /// No description provided for @dashboardSaleItems.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} itens}}'**
  String dashboardSaleItems(int count);

  /// No description provided for @weekdayMonday.
  ///
  /// In pt, this message translates to:
  /// **'Segunda-feira'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In pt, this message translates to:
  /// **'Terça-feira'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In pt, this message translates to:
  /// **'Quarta-feira'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In pt, this message translates to:
  /// **'Quinta-feira'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In pt, this message translates to:
  /// **'Sexta-feira'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In pt, this message translates to:
  /// **'Sábado'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In pt, this message translates to:
  /// **'Domingo'**
  String get weekdaySunday;

  /// No description provided for @storesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Lojas'**
  String get storesTitle;

  /// No description provided for @storesTabStores.
  ///
  /// In pt, this message translates to:
  /// **'Lojas'**
  String get storesTabStores;

  /// No description provided for @storesTabEmployees.
  ///
  /// In pt, this message translates to:
  /// **'Funcionários'**
  String get storesTabEmployees;

  /// No description provided for @storesTabUpgrades.
  ///
  /// In pt, this message translates to:
  /// **'Upgrades'**
  String get storesTabUpgrades;

  /// No description provided for @storesTabSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get storesTabSettings;

  /// No description provided for @storesAddStore.
  ///
  /// In pt, this message translates to:
  /// **'Nova loja'**
  String get storesAddStore;

  /// No description provided for @storesAddEmployee.
  ///
  /// In pt, this message translates to:
  /// **'Novo funcionário'**
  String get storesAddEmployee;

  /// No description provided for @storesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as lojas.'**
  String get storesLoadError;

  /// No description provided for @storesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma loja criada'**
  String get storesEmptyTitle;

  /// No description provided for @storesEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie a primeira loja do seu negócio.'**
  String get storesEmptySubtitle;

  /// No description provided for @employeesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os funcionários.'**
  String get employeesLoadError;

  /// No description provided for @employeesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum funcionário vinculado'**
  String get employeesEmptyTitle;

  /// No description provided for @employeesEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie a conta do funcionário e escolha a loja.'**
  String get employeesEmptySubtitle;

  /// No description provided for @roleManager.
  ///
  /// In pt, this message translates to:
  /// **'Gerente'**
  String get roleManager;

  /// No description provided for @roleEmployee.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário'**
  String get roleEmployee;

  /// No description provided for @employeeActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get employeeActive;

  /// No description provided for @employeeInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get employeeInactive;

  /// No description provided for @employeeDeactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Desativar {name}? O funcionário perde o acesso imediatamente e não poderá vender até ser reativado.'**
  String employeeDeactivateConfirm(Object name);

  /// No description provided for @employeeReactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Reativar {name}? O funcionário volta a ter acesso à loja.'**
  String employeeReactivateConfirm(Object name);

  /// No description provided for @employeeDeactivated.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário desativado.'**
  String get employeeDeactivated;

  /// No description provided for @employeeReactivated.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário reativado.'**
  String get employeeReactivated;

  /// No description provided for @employeeDeactivateAction.
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get employeeDeactivateAction;

  /// No description provided for @employeeReactivateAction.
  ///
  /// In pt, this message translates to:
  /// **'Reativar'**
  String get employeeReactivateAction;

  /// No description provided for @upgradesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os pedidos de upgrade.'**
  String get upgradesLoadError;

  /// No description provided for @upgradesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pedido de upgrade'**
  String get upgradesEmptyTitle;

  /// No description provided for @upgradesEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Solicite um plano maior no card acima.'**
  String get upgradesEmptySubtitle;

  /// No description provided for @statusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In pt, this message translates to:
  /// **'Aprovado'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitado'**
  String get statusRejected;

  /// No description provided for @upgradesRequestedOn.
  ///
  /// In pt, this message translates to:
  /// **'Solicitado em {date}'**
  String upgradesRequestedOn(String date);

  /// No description provided for @planCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get planCardTitle;

  /// No description provided for @planCardUpgrade.
  ///
  /// In pt, this message translates to:
  /// **'Upgrade'**
  String get planCardUpgrade;

  /// No description provided for @planCardStores.
  ///
  /// In pt, this message translates to:
  /// **'Lojas'**
  String get planCardStores;

  /// No description provided for @planCardEmployees.
  ///
  /// In pt, this message translates to:
  /// **'Funcionários'**
  String get planCardEmployees;

  /// No description provided for @planDetails.
  ///
  /// In pt, this message translates to:
  /// **'{stores} lojas · {employees} funcionários'**
  String planDetails(int stores, int employees);

  /// No description provided for @addStoreTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova loja'**
  String get addStoreTitle;

  /// No description provided for @addStoreNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da loja'**
  String get addStoreNameLabel;

  /// No description provided for @addStoreNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome da loja.'**
  String get addStoreNameError;

  /// No description provided for @addStoreAddressLabel.
  ///
  /// In pt, this message translates to:
  /// **'Endereço (opcional)'**
  String get addStoreAddressLabel;

  /// No description provided for @addStoreSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Loja {name} criada!'**
  String addStoreSuccess(String name);

  /// No description provided for @addStoreError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar a loja. Tente novamente.'**
  String get addStoreError;

  /// No description provided for @addStoreSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Criar loja'**
  String get addStoreSubmit;

  /// No description provided for @addEmployeeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo funcionário'**
  String get addEmployeeTitle;

  /// No description provided for @addEmployeeNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get addEmployeeNameLabel;

  /// No description provided for @addEmployeeNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do funcionário.'**
  String get addEmployeeNameError;

  /// No description provided for @addEmployeeEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get addEmployeeEmailLabel;

  /// No description provided for @addEmployeeEmailError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um e-mail válido.'**
  String get addEmployeeEmailError;

  /// No description provided for @addEmployeePasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha de acesso'**
  String get addEmployeePasswordLabel;

  /// No description provided for @addEmployeePasswordError.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter ao menos 8 caracteres.'**
  String get addEmployeePasswordError;

  /// No description provided for @addEmployeeStoreLabel.
  ///
  /// In pt, this message translates to:
  /// **'Loja'**
  String get addEmployeeStoreLabel;

  /// No description provided for @addEmployeeNoStores.
  ///
  /// In pt, this message translates to:
  /// **'Crie uma loja antes de cadastrar funcionários.'**
  String get addEmployeeNoStores;

  /// No description provided for @addEmployeeRoleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cargo'**
  String get addEmployeeRoleLabel;

  /// No description provided for @addEmployeeSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário cadastrado! A conta de acesso foi criada.'**
  String get addEmployeeSuccess;

  /// No description provided for @addEmployeeError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cadastrar o funcionário. Verifique se o e-mail já não está em uso.'**
  String get addEmployeeError;

  /// No description provided for @addEmployeeSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar funcionário'**
  String get addEmployeeSubmit;

  /// No description provided for @upgradeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Upgrade de plano'**
  String get upgradeTitle;

  /// No description provided for @upgradeSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o novo plano. O super admin precisará aprovar o pedido antes de o plano ser alterado.'**
  String get upgradeSubtitle;

  /// No description provided for @upgradeMaxReached.
  ///
  /// In pt, this message translates to:
  /// **'Você já está no plano máximo disponível.'**
  String get upgradeMaxReached;

  /// No description provided for @upgradeChooseError.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o plano de destino.'**
  String get upgradeChooseError;

  /// No description provided for @upgradeSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Pedido de upgrade enviado! O super admin vai analisar.'**
  String get upgradeSuccess;

  /// No description provided for @upgradeError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar o pedido. Tente novamente.'**
  String get upgradeError;

  /// No description provided for @upgradeSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Solicitar upgrade'**
  String get upgradeSubmit;

  /// No description provided for @commonCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get commonDescription;

  /// No description provided for @commonNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado'**
  String get commonNoResults;

  /// No description provided for @commonNoResultsHint.
  ///
  /// In pt, this message translates to:
  /// **'Tente buscar por outro termo.'**
  String get commonNoResultsHint;

  /// No description provided for @commonSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get commonSave;

  /// No description provided for @commonSoldOut.
  ///
  /// In pt, this message translates to:
  /// **'Esgotado'**
  String get commonSoldOut;

  /// No description provided for @periodToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get periodMonth;

  /// No description provided for @periodAll.
  ///
  /// In pt, this message translates to:
  /// **'Tudo'**
  String get periodAll;

  /// No description provided for @paymentCash.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro'**
  String get paymentCash;

  /// No description provided for @paymentDebitCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de débito'**
  String get paymentDebitCard;

  /// No description provided for @paymentCreditCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de crédito'**
  String get paymentCreditCard;

  /// No description provided for @paymentEMola.
  ///
  /// In pt, this message translates to:
  /// **'E-Mola'**
  String get paymentEMola;

  /// No description provided for @paymentMPesa.
  ///
  /// In pt, this message translates to:
  /// **'M-Pesa'**
  String get paymentMPesa;

  /// No description provided for @paymentTransfer.
  ///
  /// In pt, this message translates to:
  /// **'Transferência'**
  String get paymentTransfer;

  /// No description provided for @purchasesSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar compra...'**
  String get purchasesSearchHint;

  /// No description provided for @productsFilterTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar produtos'**
  String get productsFilterTooltip;

  /// No description provided for @productsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar produto...'**
  String get productsSearchHint;

  /// No description provided for @productsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os produtos.'**
  String get productsLoadError;

  /// No description provided for @productsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto cadastrado'**
  String get productsEmptyTitle;

  /// No description provided for @productsEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Novo produto\" para começar.'**
  String get productsEmptySubtitle;

  /// No description provided for @productsAddNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo produto'**
  String get productsAddNew;

  /// No description provided for @productsBuySell.
  ///
  /// In pt, this message translates to:
  /// **'Compra: {buy} · Venda: {sell}'**
  String productsBuySell(String buy, String sell);

  /// No description provided for @productsAdded.
  ///
  /// In pt, this message translates to:
  /// **'Produto adicionado!'**
  String get productsAdded;

  /// No description provided for @productsAddedNoPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Produto adicionado! (foto não enviada — sem permissão de armazenamento)'**
  String get productsAddedNoPhoto;

  /// No description provided for @productsAddError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível adicionar o produto. Tente novamente.'**
  String get productsAddError;

  /// No description provided for @productsNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do produto.'**
  String get productsNameError;

  /// No description provided for @productsDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get productsDescriptionLabel;

  /// No description provided for @productsPurchasePrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço de compra'**
  String get productsPurchasePrice;

  /// No description provided for @productsPurchasePriceError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o preço de compra.'**
  String get productsPurchasePriceError;

  /// No description provided for @productsSalePrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço de venda'**
  String get productsSalePrice;

  /// No description provided for @productsSalePriceError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o preço de venda.'**
  String get productsSalePriceError;

  /// No description provided for @productsStockQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade em estoque'**
  String get productsStockQuantity;

  /// No description provided for @productsStockError.
  ///
  /// In pt, this message translates to:
  /// **'Informe uma quantidade válida.'**
  String get productsStockError;

  /// No description provided for @productsAddSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar produto'**
  String get productsAddSubmit;

  /// No description provided for @productsEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar produto'**
  String get productsEditTitle;

  /// No description provided for @productsEditSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get productsEditSubmit;

  /// No description provided for @productsEditSaved.
  ///
  /// In pt, this message translates to:
  /// **'Produto atualizado!'**
  String get productsEditSaved;

  /// No description provided for @productsEditSavedNoPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Produto atualizado! (foto não enviada — sem permissão de armazenamento)'**
  String get productsEditSavedNoPhoto;

  /// No description provided for @productsEditError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o produto. Tente novamente.'**
  String get productsEditError;

  /// No description provided for @productsPhotoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Foto do produto'**
  String get productsPhotoLabel;

  /// No description provided for @productsPhotoTake.
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto'**
  String get productsPhotoTake;

  /// No description provided for @productsPhotoGallery.
  ///
  /// In pt, this message translates to:
  /// **'Da galeria'**
  String get productsPhotoGallery;

  /// No description provided for @productsPhotoRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover foto'**
  String get productsPhotoRemove;

  /// No description provided for @productsInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get productsInactive;

  /// No description provided for @productsActiveLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto ativo'**
  String get productsActiveLabel;

  /// No description provided for @productsActiveHint.
  ///
  /// In pt, this message translates to:
  /// **'Desative para tirar o produto do PDV e das compras (o estoque é preservado).'**
  String get productsActiveHint;

  /// No description provided for @productsStockAdjustHint.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste manual: define o estoque exato, criando/consumindo lotes FIFO.'**
  String get productsStockAdjustHint;

  /// No description provided for @productsSectionInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações'**
  String get productsSectionInfo;

  /// No description provided for @productsSectionPricing.
  ///
  /// In pt, this message translates to:
  /// **'Preços'**
  String get productsSectionPricing;

  /// No description provided for @productsSectionStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque'**
  String get productsSectionStock;

  /// No description provided for @productsSectionStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get productsSectionStatus;

  /// No description provided for @customersSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar cliente...'**
  String get customersSearchHint;

  /// No description provided for @customersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os clientes.'**
  String get customersLoadError;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cliente cadastrado'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Novo cliente\" para começar.'**
  String get customersEmptySubtitle;

  /// No description provided for @customersAddNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo cliente'**
  String get customersAddNew;

  /// No description provided for @customersCreditLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fiado {amount}'**
  String customersCreditLabel(String amount);

  /// No description provided for @customersAdded.
  ///
  /// In pt, this message translates to:
  /// **'Cliente {name} cadastrado!'**
  String customersAdded(String name);

  /// No description provided for @customersAddError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cadastrar o cliente. Tente novamente.'**
  String get customersAddError;

  /// No description provided for @customersNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do cliente.'**
  String get customersNameError;

  /// No description provided for @customersPhoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Telefone (opcional)'**
  String get customersPhoneLabel;

  /// No description provided for @customersEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail (opcional)'**
  String get customersEmailLabel;

  /// No description provided for @customersAddSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar cliente'**
  String get customersAddSubmit;

  /// No description provided for @purchasesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compras'**
  String get purchasesTitle;

  /// No description provided for @purchasesAddNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova compra'**
  String get purchasesAddNew;

  /// No description provided for @purchasesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as compras.'**
  String get purchasesLoadError;

  /// No description provided for @purchasesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma compra registrada'**
  String get purchasesEmptyTitle;

  /// No description provided for @purchasesEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Nova compra\" para registrar a entrada de mercadoria e abastecer o estoque.'**
  String get purchasesEmptySubtitle;

  /// Contagem de compras de hoje no resumo da tela de compras
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 compras} =1{1 compra} other{{count} compras}}'**
  String purchasesHeaderCount(int count);

  /// No description provided for @purchasesHeaderVsYesterday.
  ///
  /// In pt, this message translates to:
  /// **'vs ontem'**
  String get purchasesHeaderVsYesterday;

  /// Chip do card de compra: unidades adicionadas ao estoque
  ///
  /// In pt, this message translates to:
  /// **'Estoque +{units} {unit}'**
  String purchasesStockAdded(int units, String unit);

  /// No description provided for @purchasesEmptyFilteredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma compra encontrada'**
  String get purchasesEmptyFilteredTitle;

  /// No description provided for @purchasesEmptyFilteredSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste o filtro de período.'**
  String get purchasesEmptyFilteredSubtitle;

  /// No description provided for @purchasesClearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get purchasesClearFilters;

  /// No description provided for @purchasesSupplierError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o fornecedor da compra.'**
  String get purchasesSupplierError;

  /// No description provided for @purchasesCartItemUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Um item do carrinho não está mais disponível. Tente novamente.'**
  String get purchasesCartItemUnavailable;

  /// No description provided for @purchasesRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Compra registrada: {amount}!'**
  String purchasesRegistered(String amount);

  /// No description provided for @purchasesProductNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Produto {id} não encontrado no catálogo.'**
  String purchasesProductNotFound(String id);

  /// No description provided for @purchasesRegisterError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar a compra. Tente novamente.'**
  String get purchasesRegisterError;

  /// No description provided for @purchasesSupplierLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fornecedor'**
  String get purchasesSupplierLabel;

  /// No description provided for @purchasesNoProductsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto para comprar'**
  String get purchasesNoProductsTitle;

  /// No description provided for @purchasesNoProductsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre produtos para registrar compras.'**
  String get purchasesNoProductsSubtitle;

  /// No description provided for @purchasesConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar compra'**
  String get purchasesConfirm;

  /// No description provided for @purchasesStockLabel.
  ///
  /// In pt, this message translates to:
  /// **'{quantity} {unit} em estoque'**
  String purchasesStockLabel(int quantity, String unit);

  /// No description provided for @reportsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get reportsTitle;

  /// No description provided for @reportsRevenue.
  ///
  /// In pt, this message translates to:
  /// **'Faturamento'**
  String get reportsRevenue;

  /// No description provided for @reportsProfit.
  ///
  /// In pt, this message translates to:
  /// **'Lucro bruto'**
  String get reportsProfit;

  /// No description provided for @reportsMargin.
  ///
  /// In pt, this message translates to:
  /// **'Margem'**
  String get reportsMargin;

  /// No description provided for @reportsBestSellers.
  ///
  /// In pt, this message translates to:
  /// **'Mais vendidos'**
  String get reportsBestSellers;

  /// No description provided for @reportsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o relatório.'**
  String get reportsLoadError;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem vendas no período'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Registre vendas para ver o relatório.'**
  String get reportsEmptySubtitle;

  /// No description provided for @reportsSalesPerDay.
  ///
  /// In pt, this message translates to:
  /// **'Vendas por dia'**
  String get reportsSalesPerDay;

  /// No description provided for @reportsRevenueLabel.
  ///
  /// In pt, this message translates to:
  /// **'{amount} vendidos'**
  String reportsRevenueLabel(String amount);

  /// No description provided for @reportsExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get reportsExport;

  /// No description provided for @reportsExportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get reportsExportCsv;

  /// No description provided for @reportsExportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get reportsExportPdf;

  /// No description provided for @reportsExportDone.
  ///
  /// In pt, this message translates to:
  /// **'Relatório exportado!'**
  String get reportsExportDone;

  /// No description provided for @reportsExportError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível exportar o relatório. Tente novamente.'**
  String get reportsExportError;

  /// No description provided for @reportsExportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de vendas'**
  String get reportsExportTitle;

  /// No description provided for @reportsExportFileName.
  ///
  /// In pt, this message translates to:
  /// **'relatorio_vendas'**
  String get reportsExportFileName;

  /// No description provided for @reportsExportStore.
  ///
  /// In pt, this message translates to:
  /// **'Loja'**
  String get reportsExportStore;

  /// No description provided for @reportsExportPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get reportsExportPeriod;

  /// No description provided for @reportsExportGeneratedAt.
  ///
  /// In pt, this message translates to:
  /// **'Gerado em'**
  String get reportsExportGeneratedAt;

  /// No description provided for @reportsExportSummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get reportsExportSummary;

  /// No description provided for @reportsExportRank.
  ///
  /// In pt, this message translates to:
  /// **'Posição'**
  String get reportsExportRank;

  /// No description provided for @reportsExportProduct.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get reportsExportProduct;

  /// No description provided for @reportsExportQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get reportsExportQuantity;

  /// No description provided for @reportsExportRevenue.
  ///
  /// In pt, this message translates to:
  /// **'Receita'**
  String get reportsExportRevenue;

  /// No description provided for @reportsExportDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get reportsExportDay;

  /// No description provided for @reportsExportTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get reportsExportTotal;

  /// No description provided for @financialTitle.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get financialTitle;

  /// No description provided for @financialRegister.
  ///
  /// In pt, this message translates to:
  /// **'Registrar'**
  String get financialRegister;

  /// No description provided for @financialIncome.
  ///
  /// In pt, this message translates to:
  /// **'Entradas'**
  String get financialIncome;

  /// No description provided for @financialExpense.
  ///
  /// In pt, this message translates to:
  /// **'Saídas'**
  String get financialExpense;

  /// No description provided for @financialBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo'**
  String get financialBalance;

  /// No description provided for @financialTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Movimentações'**
  String get financialTransactions;

  /// No description provided for @financialLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as movimentações.'**
  String get financialLoadError;

  /// No description provided for @financialEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação'**
  String get financialEmptyTitle;

  /// No description provided for @financialEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Registre entradas e saídas para acompanhar o fluxo de caixa.'**
  String get financialEmptySubtitle;

  /// No description provided for @financialReceivePendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Receber pendência?'**
  String get financialReceivePendingTitle;

  /// No description provided for @financialReceivePendingBody.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar o recebimento de {amount}? A movimentação passa a contar no caixa realizado.'**
  String financialReceivePendingBody(String amount);

  /// No description provided for @financialReceive.
  ///
  /// In pt, this message translates to:
  /// **'Receber'**
  String get financialReceive;

  /// No description provided for @financialReceived.
  ///
  /// In pt, this message translates to:
  /// **'Movimentação recebida!'**
  String get financialReceived;

  /// No description provided for @financialReceiveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível receber a pendência. Tente novamente.'**
  String get financialReceiveError;

  /// No description provided for @financialPay.
  ///
  /// In pt, this message translates to:
  /// **'Pagar'**
  String get financialPay;

  /// No description provided for @financialPayPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pagar pendência?'**
  String get financialPayPendingTitle;

  /// No description provided for @financialPayPendingBody.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar o pagamento de {amount}? A movimentação passa a contar no caixa realizado.'**
  String financialPayPendingBody(String amount);

  /// No description provided for @financialPaid.
  ///
  /// In pt, this message translates to:
  /// **'Saída paga!'**
  String get financialPaid;

  /// No description provided for @financialPayError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível pagar a pendência. Tente novamente.'**
  String get financialPayError;

  /// No description provided for @financialAddTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registrar movimentação'**
  String get financialAddTitle;

  /// No description provided for @financialIncomingType.
  ///
  /// In pt, this message translates to:
  /// **'Entrada'**
  String get financialIncomingType;

  /// No description provided for @financialOutgoingType.
  ///
  /// In pt, this message translates to:
  /// **'Saída'**
  String get financialOutgoingType;

  /// No description provided for @financialDescriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get financialDescriptionLabel;

  /// No description provided for @financialDescriptionError.
  ///
  /// In pt, this message translates to:
  /// **'Informe a descrição.'**
  String get financialDescriptionError;

  /// No description provided for @financialCategoryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Categoria (opcional)'**
  String get financialCategoryLabel;

  /// No description provided for @financialAmountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Valor'**
  String get financialAmountLabel;

  /// No description provided for @financialAmountError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um valor maior que zero.'**
  String get financialAmountError;

  /// No description provided for @financialPendingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pendente (fiado)'**
  String get financialPendingLabel;

  /// No description provided for @financialPendingHint.
  ///
  /// In pt, this message translates to:
  /// **'Não conta no caixa realizado até ser recebido.'**
  String get financialPendingHint;

  /// No description provided for @financialRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Movimentação registrada!'**
  String get financialRegistered;

  /// No description provided for @financialRegisterError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar a movimentação. Tente novamente.'**
  String get financialRegisterError;

  /// No description provided for @financialDefaultCategoryIncome.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get financialDefaultCategoryIncome;

  /// No description provided for @financialDefaultCategoryExpense.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get financialDefaultCategoryExpense;

  /// No description provided for @cashClosingAction.
  ///
  /// In pt, this message translates to:
  /// **'Fecho de caixa'**
  String get cashClosingAction;

  /// No description provided for @cashClosingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fecho de caixa do dia'**
  String get cashClosingTitle;

  /// No description provided for @cashClosingDaySummary.
  ///
  /// In pt, this message translates to:
  /// **'Resumo do dia'**
  String get cashClosingDaySummary;

  /// No description provided for @cashClosingTotalSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas do dia'**
  String get cashClosingTotalSales;

  /// No description provided for @cashClosingExpectedCash.
  ///
  /// In pt, this message translates to:
  /// **'Esperado na gaveta'**
  String get cashClosingExpectedCash;

  /// No description provided for @cashClosingExpectedCashHint.
  ///
  /// In pt, this message translates to:
  /// **'Só vendas em dinheiro — cartão, M-Pesa, E-Mola e transferência não passam pela gaveta física.'**
  String get cashClosingExpectedCashHint;

  /// No description provided for @cashClosingByMethod.
  ///
  /// In pt, this message translates to:
  /// **'Por forma de pagamento'**
  String get cashClosingByMethod;

  /// No description provided for @cashClosingCountedCash.
  ///
  /// In pt, this message translates to:
  /// **'Dinheiro contado'**
  String get cashClosingCountedCash;

  /// No description provided for @cashClosingCountedCashHint.
  ///
  /// In pt, this message translates to:
  /// **'Conte o dinheiro físico da gaveta e informe aqui.'**
  String get cashClosingCountedCashHint;

  /// No description provided for @cashClosingDifference.
  ///
  /// In pt, this message translates to:
  /// **'Diferença'**
  String get cashClosingDifference;

  /// No description provided for @cashClosingConfers.
  ///
  /// In pt, this message translates to:
  /// **'Caixa confere'**
  String get cashClosingConfers;

  /// No description provided for @cashClosingSurplus.
  ///
  /// In pt, this message translates to:
  /// **'Sobra de {amount}'**
  String cashClosingSurplus(String amount);

  /// No description provided for @cashClosingShortage.
  ///
  /// In pt, this message translates to:
  /// **'Falta de {amount}'**
  String cashClosingShortage(String amount);

  /// No description provided for @cashClosingConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar fecho'**
  String get cashClosingConfirm;

  /// No description provided for @cashClosingUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar fecho'**
  String get cashClosingUpdate;

  /// No description provided for @cashClosingClosedAt.
  ///
  /// In pt, this message translates to:
  /// **'Fechado em'**
  String get cashClosingClosedAt;

  /// No description provided for @cashClosingSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Caixa fechado!'**
  String get cashClosingSuccess;

  /// No description provided for @cashClosingUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Fecho atualizado!'**
  String get cashClosingUpdated;

  /// No description provided for @cashClosingError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível fechar o caixa. Tente novamente.'**
  String get cashClosingError;

  /// No description provided for @cashClosingEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma venda registrada neste dia.'**
  String get cashClosingEmpty;

  /// No description provided for @cashClosingHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de fechos'**
  String get cashClosingHistory;

  /// No description provided for @cashClosingHistoryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum fecho registrado ainda.'**
  String get cashClosingHistoryEmpty;

  /// No description provided for @debtsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crédito (fiado)'**
  String get debtsTitle;

  /// No description provided for @debtsAddDebt.
  ///
  /// In pt, this message translates to:
  /// **'Registrar fiado'**
  String get debtsAddDebt;

  /// No description provided for @debtsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome do cliente...'**
  String get debtsSearchHint;

  /// No description provided for @debtsTabPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get debtsTabPending;

  /// No description provided for @debtsTabSettled.
  ///
  /// In pt, this message translates to:
  /// **'Quitadas'**
  String get debtsTabSettled;

  /// No description provided for @debtsTotalPending.
  ///
  /// In pt, this message translates to:
  /// **'Total a receber'**
  String get debtsTotalPending;

  /// No description provided for @debtsNoPendingCustomers.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cliente pendente'**
  String get debtsNoPendingCustomers;

  /// No description provided for @debtsPendingCustomers.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 cliente pendente} other{{count} clientes pendentes}}'**
  String debtsPendingCustomers(int count);

  /// No description provided for @debtsPendingSection.
  ///
  /// In pt, this message translates to:
  /// **'Dívidas pendentes'**
  String get debtsPendingSection;

  /// No description provided for @debtsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as dívidas.'**
  String get debtsLoadError;

  /// No description provided for @debtsEmptyPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum fiado pendente 🎉'**
  String get debtsEmptyPendingTitle;

  /// No description provided for @debtsEmptyPendingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cliente está devendo no momento.'**
  String get debtsEmptyPendingSubtitle;

  /// No description provided for @debtsTotalSettled.
  ///
  /// In pt, this message translates to:
  /// **'Total quitado'**
  String get debtsTotalSettled;

  /// No description provided for @debtsSettledCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 baixa registrada} other{{count} baixas registradas}}'**
  String debtsSettledCount(int count);

  /// No description provided for @debtsSettledSection.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de quitações'**
  String get debtsSettledSection;

  /// No description provided for @debtsHistoryLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o histórico.'**
  String get debtsHistoryLoadError;

  /// No description provided for @debtsEmptySettledTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma quitação ainda'**
  String get debtsEmptySettledTitle;

  /// No description provided for @debtsEmptySettledSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Quando um fiado for quitado, ele aparece aqui.'**
  String get debtsEmptySettledSubtitle;

  /// No description provided for @debtsSettleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quitar dívida?'**
  String get debtsSettleTitle;

  /// No description provided for @debtsSettleBody.
  ///
  /// In pt, this message translates to:
  /// **'Receber {amount} de {name}? Será registrada uma entrada no caixa.'**
  String debtsSettleBody(String amount, String name);

  /// No description provided for @debtsSettle.
  ///
  /// In pt, this message translates to:
  /// **'Quitar'**
  String get debtsSettle;

  /// No description provided for @debtsSettled.
  ///
  /// In pt, this message translates to:
  /// **'Fiado de {name} quitado — {amount} no caixa.'**
  String debtsSettled(String name, String amount);

  /// No description provided for @debtsNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Esta dívida não está mais pendente.'**
  String get debtsNotFound;

  /// No description provided for @debtsSettleError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível quitar a dívida. Tente novamente.'**
  String get debtsSettleError;

  /// No description provided for @debtsLate.
  ///
  /// In pt, this message translates to:
  /// **'Atrasada'**
  String get debtsLate;

  /// No description provided for @debtsDueToday.
  ///
  /// In pt, this message translates to:
  /// **'Vence hoje'**
  String get debtsDueToday;

  /// No description provided for @debtsDueIn.
  ///
  /// In pt, this message translates to:
  /// **'Em {days, plural, =1{1 dia} other{{days} dias}}'**
  String debtsDueIn(int days);

  /// No description provided for @debtsSettleAction.
  ///
  /// In pt, this message translates to:
  /// **'Quitar dívida'**
  String get debtsSettleAction;

  /// No description provided for @debtsSettledLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quitada'**
  String get debtsSettledLabel;

  /// No description provided for @debtsSettledOn.
  ///
  /// In pt, this message translates to:
  /// **'Quitada em {date}'**
  String debtsSettledOn(String date);

  /// No description provided for @debtsDueDateHelp.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento do fiado'**
  String get debtsDueDateHelp;

  /// No description provided for @debtsRegisteredFor.
  ///
  /// In pt, this message translates to:
  /// **'Fiado registrado para {name}!'**
  String debtsRegisteredFor(String name);

  /// No description provided for @debtsPendingEntryError.
  ///
  /// In pt, this message translates to:
  /// **'Fiado registrado, mas a pendência no Financeiro não pôde ser criada. Verifique as movimentações.'**
  String get debtsPendingEntryError;

  /// No description provided for @debtsRegisterError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar o fiado. Tente novamente.'**
  String get debtsRegisterError;

  /// No description provided for @debtsCustomerLinkLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cliente vinculado (opcional)'**
  String get debtsCustomerLinkLabel;

  /// No description provided for @debtsNoCustomer.
  ///
  /// In pt, this message translates to:
  /// **'Sem vínculo'**
  String get debtsNoCustomer;

  /// No description provided for @debtsCustomerNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do cliente'**
  String get debtsCustomerNameLabel;

  /// No description provided for @debtsCustomerNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do cliente.'**
  String get debtsCustomerNameError;

  /// No description provided for @debtsDueDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento'**
  String get debtsDueDateLabel;

  /// No description provided for @salesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get salesTitle;

  /// No description provided for @salesNewSale.
  ///
  /// In pt, this message translates to:
  /// **'Nova venda'**
  String get salesNewSale;

  /// No description provided for @salesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as vendas.'**
  String get salesLoadError;

  /// No description provided for @salesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma venda registrada'**
  String get salesEmptyTitle;

  /// No description provided for @salesEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Nova venda\" para registrar a primeira.'**
  String get salesEmptySubtitle;

  /// No description provided for @salesSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar venda...'**
  String get salesSearchHint;

  /// No description provided for @periodYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get periodYesterday;

  /// No description provided for @paymentFilterCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get paymentFilterCard;

  /// No description provided for @salesStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Pago'**
  String get salesStatusPaid;

  /// Contagem de transações de hoje no resumo da tela de vendas
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 transações} =1{1 transação} other{{count} transações}}'**
  String salesHeaderTransactions(int count);

  /// No description provided for @salesHeaderVsYesterday.
  ///
  /// In pt, this message translates to:
  /// **'vs ontem'**
  String get salesHeaderVsYesterday;

  /// No description provided for @salesEmptyFilteredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma venda encontrada'**
  String get salesEmptyFilteredTitle;

  /// No description provided for @salesEmptyFilteredSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste a busca ou os filtros.'**
  String get salesEmptyFilteredSubtitle;

  /// No description provided for @salesClearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get salesClearFilters;

  /// Linha-resumo quando há filtro ativo na lista de vendas
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 venda} other{{count} vendas}} · Total {total}'**
  String salesFilteredSummary(int count, String total);

  /// No description provided for @salesItemUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Um item do carrinho não está mais disponível. Tente novamente.'**
  String get salesItemUnavailable;

  /// No description provided for @salesRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Venda registrada: {amount}!'**
  String salesRegistered(String amount);

  /// No description provided for @salesInsufficientStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque insuficiente{product}. Disponível: {available}.'**
  String salesInsufficientStock(String product, int available);

  /// No description provided for @salesStockFor.
  ///
  /// In pt, this message translates to:
  /// **'para {name}'**
  String salesStockFor(String name);

  /// No description provided for @salesProductNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Produto {id} não encontrado no estoque.'**
  String salesProductNotFound(String id);

  /// No description provided for @salesRegisterError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar a venda. Tente novamente.'**
  String get salesRegisterError;

  /// No description provided for @salesSearchProducts.
  ///
  /// In pt, this message translates to:
  /// **'Buscar produto...'**
  String get salesSearchProducts;

  /// No description provided for @salesNoProductsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto para vender'**
  String get salesNoProductsTitle;

  /// No description provided for @salesNoProductsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre produtos para registrar vendas.'**
  String get salesNoProductsSubtitle;

  /// No description provided for @salesConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar venda'**
  String get salesConfirm;

  /// No description provided for @saleDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da venda'**
  String get saleDetailTitle;

  /// No description provided for @saleDetailId.
  ///
  /// In pt, this message translates to:
  /// **'Venda {id}'**
  String saleDetailId(String id);

  /// No description provided for @saleDetailTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'Total da venda'**
  String get saleDetailTotalLabel;

  /// No description provided for @saleDetailItems.
  ///
  /// In pt, this message translates to:
  /// **'Itens'**
  String get saleDetailItems;

  /// No description provided for @saleDetailTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get saleDetailTotal;

  /// No description provided for @saleDetailSnapshot.
  ///
  /// In pt, this message translates to:
  /// **'Preços congelados no momento da venda.'**
  String get saleDetailSnapshot;

  /// No description provided for @salesStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Anulada'**
  String get salesStatusCancelled;

  /// No description provided for @saleDetailCancelAction.
  ///
  /// In pt, this message translates to:
  /// **'Anular venda'**
  String get saleDetailCancelAction;

  /// No description provided for @saleDetailCancelConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Anular esta venda?'**
  String get saleDetailCancelConfirmTitle;

  /// Confirmação de anulação de venda — avisa que estoque e caixa serão estornados
  ///
  /// In pt, this message translates to:
  /// **'O estoque dos itens será devolvido e a entrada no caixa estornada ({amount}). Esta ação não pode ser desfeita.'**
  String saleDetailCancelConfirmBody(String amount);

  /// No description provided for @saleDetailCancelConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Sim, anular'**
  String get saleDetailCancelConfirm;

  /// No description provided for @saleDetailCancelledAt.
  ///
  /// In pt, this message translates to:
  /// **'Anulada em'**
  String get saleDetailCancelledAt;

  /// No description provided for @saleCancelledSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Venda anulada.'**
  String get saleCancelledSuccess;

  /// No description provided for @saleNotFoundError.
  ///
  /// In pt, this message translates to:
  /// **'Esta venda não existe mais.'**
  String get saleNotFoundError;

  /// No description provided for @saleCancelError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível anular a venda. Tente novamente.'**
  String get saleCancelError;

  /// No description provided for @saleDetailShareAction.
  ///
  /// In pt, this message translates to:
  /// **'Partilhar recibo'**
  String get saleDetailShareAction;

  /// No description provided for @saleDetailShareTitle.
  ///
  /// In pt, this message translates to:
  /// **'Partilhar recibo'**
  String get saleDetailShareTitle;

  /// No description provided for @saleDetailShareImage.
  ///
  /// In pt, this message translates to:
  /// **'Partilhar como imagem'**
  String get saleDetailShareImage;

  /// No description provided for @saleDetailShareWhatsApp.
  ///
  /// In pt, this message translates to:
  /// **'WhatsApp'**
  String get saleDetailShareWhatsApp;

  /// No description provided for @saleDetailShareError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível partilhar o recibo. Tente novamente.'**
  String get saleDetailShareError;

  /// No description provided for @saleDetailShareWhatsAppError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o WhatsApp. Tente novamente.'**
  String get saleDetailShareWhatsAppError;

  /// No description provided for @saleDetailReceiptTitle.
  ///
  /// In pt, this message translates to:
  /// **'RECIBO DE VENDA'**
  String get saleDetailReceiptTitle;

  /// No description provided for @saleDetailReceiptTitleCancelled.
  ///
  /// In pt, this message translates to:
  /// **'RECIBO DE VENDA (ANULADA)'**
  String get saleDetailReceiptTitleCancelled;

  /// No description provided for @saleDetailReceiptPayment.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento'**
  String get saleDetailReceiptPayment;

  /// No description provided for @saleDetailReceiptThanks.
  ///
  /// In pt, this message translates to:
  /// **'Obrigado pela preferência!'**
  String get saleDetailReceiptThanks;

  /// No description provided for @adminTitle.
  ///
  /// In pt, this message translates to:
  /// **'Painel do Super Admin'**
  String get adminTitle;

  /// No description provided for @adminNavRequests.
  ///
  /// In pt, this message translates to:
  /// **'Solicitações'**
  String get adminNavRequests;

  /// No description provided for @adminNavPlans.
  ///
  /// In pt, this message translates to:
  /// **'Planos'**
  String get adminNavPlans;

  /// No description provided for @adminNavUpgrades.
  ///
  /// In pt, this message translates to:
  /// **'Upgrades'**
  String get adminNavUpgrades;

  /// No description provided for @adminTenantsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tenants'**
  String get adminTenantsTitle;

  /// No description provided for @adminPendingOnly.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get adminPendingOnly;

  /// No description provided for @adminAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get adminAll;

  /// No description provided for @adminAwaitingCount.
  ///
  /// In pt, this message translates to:
  /// **'{count} aguardando aprovação'**
  String adminAwaitingCount(int count);

  /// No description provided for @adminTenantsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum tenant registrado ainda.'**
  String get adminTenantsEmpty;

  /// No description provided for @adminRequestsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as solicitações.'**
  String get adminRequestsLoadError;

  /// No description provided for @adminNothingPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nada aguardando aprovação'**
  String get adminNothingPendingTitle;

  /// No description provided for @adminNothingPendingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Novas solicitações de tenant aparecem aqui.'**
  String get adminNothingPendingSubtitle;

  /// No description provided for @adminTenantsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os tenants.'**
  String get adminTenantsLoadError;

  /// No description provided for @adminRejectError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível rejeitar a solicitação.'**
  String get adminRejectError;

  /// No description provided for @adminApproveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível aprovar a solicitação.'**
  String get adminApproveError;

  /// No description provided for @adminAccessApproved.
  ///
  /// In pt, this message translates to:
  /// **'Acesso de {name} aprovado!'**
  String adminAccessApproved(String name);

  /// No description provided for @adminRequestRejected.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação de {name} rejeitada.'**
  String adminRequestRejected(String name);

  /// No description provided for @adminRejectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar {name}'**
  String adminRejectTitle(String name);

  /// No description provided for @adminRejectReasonLabel.
  ///
  /// In pt, this message translates to:
  /// **'Motivo da rejeição'**
  String get adminRejectReasonLabel;

  /// No description provided for @adminRejectReasonHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: informações incompletas no cadastro'**
  String get adminRejectReasonHint;

  /// No description provided for @adminApprove.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar'**
  String get adminReject;

  /// No description provided for @adminPlanLabel.
  ///
  /// In pt, this message translates to:
  /// **'Plano: {plan}'**
  String adminPlanLabel(String plan);

  /// No description provided for @adminPlanSolicited.
  ///
  /// In pt, this message translates to:
  /// **'Plano: {plan} · Solicitado: {date}'**
  String adminPlanSolicited(String plan, String date);

  /// No description provided for @adminPlansTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planos'**
  String get adminPlansTitle;

  /// No description provided for @adminPlanNewTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Novo plano'**
  String get adminPlanNewTooltip;

  /// No description provided for @adminPlansLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os planos.'**
  String get adminPlansLoadError;

  /// No description provided for @adminPlansEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum plano criado'**
  String get adminPlansEmptyTitle;

  /// No description provided for @adminPlansEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie o primeiro plano para liberar assinaturas.'**
  String get adminPlansEmptySubtitle;

  /// No description provided for @adminPlanInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inativo'**
  String get adminPlanInactive;

  /// No description provided for @adminPlanDetails.
  ///
  /// In pt, this message translates to:
  /// **'{price}/mês · {stores} loja(s) · {employees} funcionário(s)'**
  String adminPlanDetails(String price, int stores, int employees);

  /// No description provided for @adminPlanNameError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do plano.'**
  String get adminPlanNameError;

  /// No description provided for @adminPlanPriceError.
  ///
  /// In pt, this message translates to:
  /// **'Informe um preço válido (≥ 0).'**
  String get adminPlanPriceError;

  /// No description provided for @adminPlanStoresError.
  ///
  /// In pt, this message translates to:
  /// **'O plano deve permitir ao menos 1 loja.'**
  String get adminPlanStoresError;

  /// No description provided for @adminPlanEmployeesError.
  ///
  /// In pt, this message translates to:
  /// **'O plano deve permitir ao menos 1 funcionário.'**
  String get adminPlanEmployeesError;

  /// No description provided for @adminPlanCreated.
  ///
  /// In pt, this message translates to:
  /// **'Plano {name} criado!'**
  String adminPlanCreated(String name);

  /// No description provided for @adminPlanUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Plano {name} atualizado!'**
  String adminPlanUpdated(String name);

  /// No description provided for @adminPlanSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar o plano. Tente novamente.'**
  String get adminPlanSaveError;

  /// No description provided for @adminPlanNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo plano'**
  String get adminPlanNewTitle;

  /// No description provided for @adminPlanEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar plano'**
  String get adminPlanEditTitle;

  /// No description provided for @adminPlanNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do plano'**
  String get adminPlanNameLabel;

  /// No description provided for @adminPlanPriceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Preço mensal'**
  String get adminPlanPriceLabel;

  /// No description provided for @adminPlanMaxStores.
  ///
  /// In pt, this message translates to:
  /// **'Máx. lojas'**
  String get adminPlanMaxStores;

  /// No description provided for @adminPlanMaxEmployees.
  ///
  /// In pt, this message translates to:
  /// **'Máx. funcionários'**
  String get adminPlanMaxEmployees;

  /// No description provided for @adminPlanActiveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Plano ativo'**
  String get adminPlanActiveTitle;

  /// No description provided for @adminPlanActiveSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Desative para impedir novas assinaturas.'**
  String get adminPlanActiveSubtitle;

  /// No description provided for @adminPlanCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar plano'**
  String get adminPlanCreate;

  /// No description provided for @adminUpgradesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Upgrades de plano'**
  String get adminUpgradesTitle;

  /// No description provided for @adminUpgradesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os pedidos de upgrade.'**
  String get adminUpgradesLoadError;

  /// No description provided for @adminUpgradesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum upgrade pendente'**
  String get adminUpgradesEmptyTitle;

  /// No description provided for @adminUpgradesEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Pedidos de mudança de plano aparecem aqui.'**
  String get adminUpgradesEmptySubtitle;

  /// No description provided for @adminUpgradeApproved.
  ///
  /// In pt, this message translates to:
  /// **'Upgrade aprovado — plano do tenant atualizado!'**
  String get adminUpgradeApproved;

  /// No description provided for @adminUpgradeRejected.
  ///
  /// In pt, this message translates to:
  /// **'Upgrade rejeitado.'**
  String get adminUpgradeRejected;

  /// No description provided for @adminUpgradeProcessError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível processar o pedido.'**
  String get adminUpgradeProcessError;

  /// No description provided for @adminPlanRequested.
  ///
  /// In pt, this message translates to:
  /// **'Solicitado'**
  String get adminPlanRequested;

  /// No description provided for @adminPlanCurrent.
  ///
  /// In pt, this message translates to:
  /// **'Atual'**
  String get adminPlanCurrent;

  /// No description provided for @productsCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de barras (PLU)'**
  String get productsCodeLabel;

  /// No description provided for @productsCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Balanças etiquetadoras (ex.: 12345)'**
  String get productsCodeHint;

  /// No description provided for @productsCodeError.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido: use até 5 dígitos.'**
  String get productsCodeError;

  /// No description provided for @productsWeighLabel.
  ///
  /// In pt, this message translates to:
  /// **'Venda por peso (fração)'**
  String get productsWeighLabel;

  /// No description provided for @productsWeighHint.
  ///
  /// In pt, this message translates to:
  /// **'Aceita quantidades decimais (ex.: 1,75 kg)'**
  String get productsWeighHint;

  /// No description provided for @productsUnitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade de venda'**
  String get productsUnitLabel;

  /// No description provided for @productsStockWeightHint.
  ///
  /// In pt, this message translates to:
  /// **'Em unidades da venda (ex.: 1,75)'**
  String get productsStockWeightHint;

  /// No description provided for @productsExpiryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get productsExpiryLabel;

  /// No description provided for @productsExpiryAdd.
  ///
  /// In pt, this message translates to:
  /// **'Definir validade'**
  String get productsExpiryAdd;

  /// No description provided for @productsExpiryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Data de validade do produto'**
  String get productsExpiryHelp;

  /// No description provided for @productsExpiryClear.
  ///
  /// In pt, this message translates to:
  /// **'Remover validade'**
  String get productsExpiryClear;

  /// No description provided for @salesBarcodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de barras'**
  String get salesBarcodeLabel;

  /// No description provided for @salesBarcodeScan.
  ///
  /// In pt, this message translates to:
  /// **'Ler com a câmera'**
  String get salesBarcodeScan;

  /// No description provided for @salesBarcodeNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Produto não encontrado para este código.'**
  String get salesBarcodeNotFound;

  /// No description provided for @salesBarcodeInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Código de balança inválido.'**
  String get salesBarcodeInvalid;

  /// Erro ao adicionar mais do que o estoque disponível
  ///
  /// In pt, this message translates to:
  /// **'Limite de estoque atingido para {product}.'**
  String salesStockLimit(String product);

  /// No description provided for @salesQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get salesQuantityLabel;

  /// No description provided for @salesQuantityHint.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade (ex.: 1,75)'**
  String get salesQuantityHint;

  /// No description provided for @purchasesExpiryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get purchasesExpiryLabel;

  /// No description provided for @purchasesExpiryAdd.
  ///
  /// In pt, this message translates to:
  /// **'Definir validade'**
  String get purchasesExpiryAdd;

  /// No description provided for @purchasesExpiryHelp.
  ///
  /// In pt, this message translates to:
  /// **'Data de validade do lote'**
  String get purchasesExpiryHelp;

  /// No description provided for @dashboardExpiryAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get dashboardExpiryAlerts;

  /// Lote vencido — dias desde o vencimento
  ///
  /// In pt, this message translates to:
  /// **'Venceu há {days} dia(s)'**
  String dashboardExpiredIn(int days);

  /// Lote a expirar — dias restantes
  ///
  /// In pt, this message translates to:
  /// **'Vence em {days} dia(s)'**
  String dashboardExpiresIn(int days);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
