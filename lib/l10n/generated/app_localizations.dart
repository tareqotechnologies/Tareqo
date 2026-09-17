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

  /// No description provided for @onboardingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo!'**
  String get onboardingTitle;

  /// No description provided for @onboardingHeading.
  ///
  /// In pt, this message translates to:
  /// **'Configure seu negócio'**
  String get onboardingHeading;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o plano, nome e moeda. Aprovação em até 24h.'**
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
  /// **'Solicitação de {business} enviada! Aguarde aprovação (até 24h).'**
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

  /// No description provided for @onboardingCurrencyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Moeda'**
  String get onboardingCurrencyLabel;

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
  /// **'Salvar'**
  String get settingsSave;

  /// No description provided for @settingsSaved.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes salvos!'**
  String get settingsSaved;

  /// No description provided for @settingsGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente novamente.'**
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
  /// **'Guia do Usuário e Troubleshooting — offline'**
  String get settingsSupportEntryHint;

  /// No description provided for @supportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Guia do usuário e solução de problemas.'**
  String get supportSubtitle;

  /// No description provided for @supportUserGuide.
  ///
  /// In pt, this message translates to:
  /// **'Guia do Usuário'**
  String get supportUserGuide;

  /// No description provided for @supportUserGuideHint.
  ///
  /// In pt, this message translates to:
  /// **'Login, lojas, produtos, vendas, fiado, financeiro e relatórios'**
  String get supportUserGuideHint;

  /// No description provided for @supportTroubleshooting.
  ///
  /// In pt, this message translates to:
  /// **'Troubleshooting'**
  String get supportTroubleshooting;

  /// No description provided for @supportTroubleshootingHint.
  ///
  /// In pt, this message translates to:
  /// **'Problemas comuns: login, vendas, estoque e conexão'**
  String get supportTroubleshootingHint;

  /// No description provided for @supportReadingError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o documento.'**
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
  /// **'Terminar sessão'**
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

  /// Rótulo de acessibilidade da pílula de loja única no app bar (leitor de tela)
  ///
  /// In pt, this message translates to:
  /// **'Loja: {store}'**
  String storeSwitcherA11yLabel(String store);

  /// No description provided for @storeSelectorSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Loja activa'**
  String get storeSelectorSectionTitle;

  /// No description provided for @tenantPendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando aprovação'**
  String get tenantPendingTitle;

  /// No description provided for @tenantPendingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação de \"{business}\" enviada. Aguarde até 24h.'**
  String tenantPendingSubtitle(String business);

  /// No description provided for @tenantPendingHint.
  ///
  /// In pt, this message translates to:
  /// **'Depois da aprovação, crie lojas e comece a operar.'**
  String get tenantPendingHint;

  /// No description provided for @tenantRejectedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Solicitação rejeitada'**
  String get tenantRejectedTitle;

  /// No description provided for @tenantRejectedSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'A solicitação de \"{business}\" não foi aprovada.'**
  String tenantRejectedSubtitle(String business);

  /// No description provided for @authBlockedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesso suspenso'**
  String get authBlockedTitle;

  /// No description provided for @authBlockedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta foi desactivada pelo proprietário.'**
  String get authBlockedMessage;

  /// No description provided for @authBlockedSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get authBlockedSignOut;

  /// No description provided for @authErrorCheckConnection.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão e tente novamente.'**
  String get authErrorCheckConnection;

  /// No description provided for @authErrorLoadAccount.
  ///
  /// In pt, this message translates to:
  /// **'Conta não carregada'**
  String get authErrorLoadAccount;

  /// No description provided for @splashLoading.
  ///
  /// In pt, this message translates to:
  /// **'A abrir a sua sessão…'**
  String get splashLoading;

  /// No description provided for @appLockTitle.
  ///
  /// In pt, this message translates to:
  /// **'TAREQO bloqueado'**
  String get appLockTitle;

  /// No description provided for @appLockMessage.
  ///
  /// In pt, this message translates to:
  /// **'Toque no sensor ou use o reconhecimento facial para desbloquear o TAREQO.'**
  String get appLockMessage;

  /// No description provided for @appLockUnlock.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear'**
  String get appLockUnlock;

  /// No description provided for @appLockError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível autenticar. Tente novamente ou termine a sessão.'**
  String get appLockError;

  /// No description provided for @biometricSignInTitle.
  ///
  /// In pt, this message translates to:
  /// **'Autenticação Biométrica'**
  String get biometricSignInTitle;

  /// No description provided for @biometricHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque no sensor'**
  String get biometricHint;

  /// No description provided for @biometricCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get biometricCancel;

  /// No description provided for @biometricFallbackTitle.
  ///
  /// In pt, this message translates to:
  /// **'Usar senha'**
  String get biometricFallbackTitle;

  /// No description provided for @biometricGoToSettingsButton.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get biometricGoToSettingsButton;

  /// No description provided for @biometricGoToSettingsDescription.
  ///
  /// In pt, this message translates to:
  /// **'Configure a autenticação biométrica'**
  String get biometricGoToSettingsDescription;

  /// No description provided for @biometricLockOut.
  ///
  /// In pt, this message translates to:
  /// **'Tente novamente mais tarde'**
  String get biometricLockOut;

  /// No description provided for @biometricReason.
  ///
  /// In pt, this message translates to:
  /// **'Autenticação biométrica'**
  String get biometricReason;

  /// No description provided for @loginSubtitleSignUp.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua conta para começar'**
  String get loginSubtitleSignUp;

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

  /// No description provided for @loginWeakPasswordError.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve conter letras, números e símbolos.'**
  String get loginWeakPasswordError;

  /// No description provided for @loginRateLimitError.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde 1 hora e tente novamente.'**
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

  /// No description provided for @loginNoConnection.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Verifique o Wi-Fi/dados móveis e tente novamente.'**
  String get loginNoConnection;

  /// No description provided for @loginSignInError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar. Verifique e-mail e senha.'**
  String get loginSignInError;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In pt, this message translates to:
  /// **'Redefinir senha'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail. Enviaremos um link para redefinir.'**
  String get forgotPasswordHint;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Enviar link'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In pt, this message translates to:
  /// **'Se existir uma conta, enviamos um link.'**
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

  /// No description provided for @setNewPasswordSamePassword.
  ///
  /// In pt, this message translates to:
  /// **'A nova senha deve ser diferente da atual.'**
  String get setNewPasswordSamePassword;

  /// No description provided for @setNewPasswordSessionExpired.
  ///
  /// In pt, this message translates to:
  /// **'O link de recuperação expirou ou já foi usado. Peça um novo link.'**
  String get setNewPasswordSessionExpired;

  /// No description provided for @setNewPasswordRateLimited.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde um momento e tente de novo.'**
  String get setNewPasswordRateLimited;

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

  /// No description provided for @passwordSameAsCurrent.
  ///
  /// In pt, this message translates to:
  /// **'A nova senha deve ser diferente da atual.'**
  String get passwordSameAsCurrent;

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

  /// No description provided for @appNavSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get appNavSales;

  /// No description provided for @appNavWallet.
  ///
  /// In pt, this message translates to:
  /// **'Carteira'**
  String get appNavWallet;

  /// No description provided for @appNavMenu.
  ///
  /// In pt, this message translates to:
  /// **'Menu'**
  String get appNavMenu;

  /// No description provided for @appNavProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get appNavProducts;

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

  /// No description provided for @fabMenuTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova ação'**
  String get fabMenuTitle;

  /// No description provided for @fabMenuSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'O que deseja fazer?'**
  String get fabMenuSubtitle;

  /// No description provided for @menuSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma área para continuar'**
  String get menuSubtitle;

  /// No description provided for @commonSignOutConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Terminar sessão?'**
  String get commonSignOutConfirmTitle;

  /// No description provided for @commonSignOutConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'Vai sair da sua conta neste dispositivo.'**
  String get commonSignOutConfirmMessage;

  /// No description provided for @fabMenuNewSale.
  ///
  /// In pt, this message translates to:
  /// **'Nova venda'**
  String get fabMenuNewSale;

  /// No description provided for @fabMenuNewSaleHint.
  ///
  /// In pt, this message translates to:
  /// **'Carrinho · baixa de estoque · caixa'**
  String get fabMenuNewSaleHint;

  /// No description provided for @fabMenuExpense.
  ///
  /// In pt, this message translates to:
  /// **'Registrar despesa'**
  String get fabMenuExpense;

  /// No description provided for @fabMenuExpenseHint.
  ///
  /// In pt, this message translates to:
  /// **'Saída de caixa com categoria'**
  String get fabMenuExpenseHint;

  /// No description provided for @fabMenuAddProduct.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar produto'**
  String get fabMenuAddProduct;

  /// No description provided for @fabMenuAddProductHint.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo · preço · estoque inicial'**
  String get fabMenuAddProductHint;

  /// No description provided for @fabMenuAddDebt.
  ///
  /// In pt, this message translates to:
  /// **'Registrar fiado'**
  String get fabMenuAddDebt;

  /// No description provided for @fabMenuAddDebtHint.
  ///
  /// In pt, this message translates to:
  /// **'A receber ou a pagar'**
  String get fabMenuAddDebtHint;

  /// No description provided for @fabMenuAddCustomer.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar cliente'**
  String get fabMenuAddCustomer;

  /// No description provided for @fabMenuAddCustomerHint.
  ///
  /// In pt, this message translates to:
  /// **'Contactos · fiado vinculado'**
  String get fabMenuAddCustomerHint;

  /// No description provided for @fabMenuCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get fabMenuCancel;

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
  /// **'Sem conexão. Operação salva e será sincronizada automaticamente.'**
  String get syncOfflineSaved;

  /// No description provided for @syncDone.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 operação sincronizada} other{{count} operações sincronizadas}}'**
  String syncDone(int count);

  /// No description provided for @syncStillOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão — operações pendentes.'**
  String get syncStillOffline;

  /// No description provided for @dashboardGreeting.
  ///
  /// In pt, this message translates to:
  /// **'Olá, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardOwnerFallback.
  ///
  /// In pt, this message translates to:
  /// **'Dono'**
  String get dashboardOwnerFallback;

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

  /// No description provided for @dashboardLowStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque baixo'**
  String get dashboardLowStock;

  /// No description provided for @dashboardKpisError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os indicadores.'**
  String get dashboardKpisError;

  /// No description provided for @dashboardActivityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividade de hoje'**
  String get dashboardActivityTitle;

  /// No description provided for @dashboardActivityEvents.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 evento} other{{count} eventos}}'**
  String dashboardActivityEvents(num count);

  /// No description provided for @dashboardActivityMinutesAgo.
  ///
  /// In pt, this message translates to:
  /// **'há {count} min'**
  String dashboardActivityMinutesAgo(Object count);

  /// No description provided for @dashboardMetricSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get dashboardMetricSales;

  /// No description provided for @dashboardMetricCash.
  ///
  /// In pt, this message translates to:
  /// **'Caixa'**
  String get dashboardMetricCash;

  /// No description provided for @dashboardMetricReceivables.
  ///
  /// In pt, this message translates to:
  /// **'A receber'**
  String get dashboardMetricReceivables;

  /// No description provided for @dashboardFiadoCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 fiado} other{{count} fiados}}'**
  String dashboardFiadoCount(int count);

  /// No description provided for @dashboardActivityEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atividade registrada ainda.'**
  String get dashboardActivityEmpty;

  /// No description provided for @dashboardStockEntry.
  ///
  /// In pt, this message translates to:
  /// **'Estoque · {product}'**
  String dashboardStockEntry(String product);

  /// No description provided for @dashboardStockEntryDetail.
  ///
  /// In pt, this message translates to:
  /// **'Entrada de {quantity} · {time}'**
  String dashboardStockEntryDetail(String quantity, String time);

  /// No description provided for @dashboardFiadoPayment.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento fiado'**
  String get dashboardFiadoPayment;

  /// No description provided for @dashboardExpenseRow.
  ///
  /// In pt, this message translates to:
  /// **'Despesa · {description}'**
  String dashboardExpenseRow(String description);

  /// No description provided for @dashboardLowStockDetail.
  ///
  /// In pt, this message translates to:
  /// **'{name} · {quantity} restantes'**
  String dashboardLowStockDetail(String name, String quantity);

  /// No description provided for @dashboardAlertBadge.
  ///
  /// In pt, this message translates to:
  /// **'Alerta'**
  String get dashboardAlertBadge;

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

  /// No description provided for @employeesUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o funcionário. Tente novamente.'**
  String get employeesUpdateError;

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

  /// No description provided for @employeeDeactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Desactivar {name}? Perde acesso imediatamente.'**
  String employeeDeactivateConfirm(Object name);

  /// No description provided for @employeeReactivateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Reactivar {name}? Volta a ter acesso à loja.'**
  String employeeReactivateConfirm(Object name);

  /// No description provided for @employeeDeactivated.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário desactivado.'**
  String get employeeDeactivated;

  /// No description provided for @employeeReactivated.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário reactivado.'**
  String get employeeReactivated;

  /// No description provided for @employeeDeactivateAction.
  ///
  /// In pt, this message translates to:
  /// **'Desactivar'**
  String get employeeDeactivateAction;

  /// No description provided for @employeeReactivateAction.
  ///
  /// In pt, this message translates to:
  /// **'Reactivar'**
  String get employeeReactivateAction;

  /// No description provided for @employeeDetailEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get employeeDetailEmail;

  /// No description provided for @employeeDetailStore.
  ///
  /// In pt, this message translates to:
  /// **'Loja'**
  String get employeeDetailStore;

  /// No description provided for @employeeDetailRole.
  ///
  /// In pt, this message translates to:
  /// **'Nível de acesso'**
  String get employeeDetailRole;

  /// No description provided for @employeeDetailStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get employeeDetailStatus;

  /// No description provided for @employeeDetailActive.
  ///
  /// In pt, this message translates to:
  /// **'Activo'**
  String get employeeDetailActive;

  /// No description provided for @employeeDetailInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inactivo'**
  String get employeeDetailInactive;

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

  /// No description provided for @addStorePhoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Telefone (opcional)'**
  String get addStorePhoneLabel;

  /// No description provided for @addStoreEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail (opcional)'**
  String get addStoreEmailLabel;

  /// No description provided for @addStoreNuitLabel.
  ///
  /// In pt, this message translates to:
  /// **'NUIT (opcional)'**
  String get addStoreNuitLabel;

  /// No description provided for @addStoreCityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cidade (opcional)'**
  String get addStoreCityLabel;

  /// No description provided for @storeDetailPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get storeDetailPhone;

  /// No description provided for @storeDetailEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get storeDetailEmail;

  /// No description provided for @storeDetailNuit.
  ///
  /// In pt, this message translates to:
  /// **'NUIT'**
  String get storeDetailNuit;

  /// No description provided for @storeDetailCity.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get storeDetailCity;

  /// No description provided for @storeDetailAddress.
  ///
  /// In pt, this message translates to:
  /// **'Endereço'**
  String get storeDetailAddress;

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
  /// **'Funcionário cadastrado! Conta de acesso criada.'**
  String get addEmployeeSuccess;

  /// No description provided for @addEmployeeError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cadastrar. Verifique o e-mail.'**
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
  /// **'Escolha o novo plano. Aguarda aprovação do super admin.'**
  String get upgradeSubtitle;

  /// No description provided for @upgradeMaxReached.
  ///
  /// In pt, this message translates to:
  /// **'Você já está no plano máximo.'**
  String get upgradeMaxReached;

  /// No description provided for @upgradeChooseError.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o plano de destino.'**
  String get upgradeChooseError;

  /// No description provided for @upgradeSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Pedido de upgrade enviado!'**
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

  /// No description provided for @commonCopied.
  ///
  /// In pt, this message translates to:
  /// **'Copiado para a área de transferência'**
  String get commonCopied;

  /// No description provided for @commonConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get commonDelete;

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

  /// No description provided for @productsFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get productsFilterAll;

  /// No description provided for @productsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar produto...'**
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

  /// No description provided for @productsAdded.
  ///
  /// In pt, this message translates to:
  /// **'Produto adicionado!'**
  String get productsAdded;

  /// No description provided for @productsAddedNoPhoto.
  ///
  /// In pt, this message translates to:
  /// **'Produto adicionado! (sem permissão de armazenamento)'**
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

  /// No description provided for @productsSalePrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço de venda'**
  String get productsSalePrice;

  /// No description provided for @productsStockQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade em estoque'**
  String get productsStockQuantity;

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
  /// **'Produto atualizado! (sem permissão de armazenamento)'**
  String get productsEditSavedNoPhoto;

  /// No description provided for @productsEditError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o produto. Tente novamente.'**
  String get productsEditError;

  /// No description provided for @productsInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inactivo'**
  String get productsInactive;

  /// No description provided for @productsFilterTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar'**
  String get productsFilterTooltip;

  /// No description provided for @productsFilterAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Filtros avançados'**
  String get productsFilterAdvanced;

  /// No description provided for @productsFilterStockType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de estoque'**
  String get productsFilterStockType;

  /// No description provided for @productsFilterStockTypeAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get productsFilterStockTypeAll;

  /// No description provided for @productsFilterStockTypeWeight.
  ///
  /// In pt, this message translates to:
  /// **'Peso (kg/g/l/ml)'**
  String get productsFilterStockTypeWeight;

  /// No description provided for @productsFilterStockTypeUnit.
  ///
  /// In pt, this message translates to:
  /// **'Unidade (un)'**
  String get productsFilterStockTypeUnit;

  /// No description provided for @productsFilterAvailability.
  ///
  /// In pt, this message translates to:
  /// **'Disponibilidade'**
  String get productsFilterAvailability;

  /// No description provided for @productsFilterAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Em estoque'**
  String get productsFilterAvailable;

  /// No description provided for @productsFilterLowStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque baixo'**
  String get productsFilterLowStock;

  /// No description provided for @productsFilterOutOfStock.
  ///
  /// In pt, this message translates to:
  /// **'Esgotado'**
  String get productsFilterOutOfStock;

  /// No description provided for @productsFilterPriceRange.
  ///
  /// In pt, this message translates to:
  /// **'Faixa de preço'**
  String get productsFilterPriceRange;

  /// No description provided for @productsFilterMinPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço mínimo'**
  String get productsFilterMinPrice;

  /// No description provided for @productsFilterMaxPrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço máximo'**
  String get productsFilterMaxPrice;

  /// No description provided for @productsFilterApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get productsFilterApply;

  /// No description provided for @productsFilterInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inactivos'**
  String get productsFilterInactive;

  /// No description provided for @productsHeaderCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 produto} other{{count} produtos}}'**
  String productsHeaderCount(int count);

  /// No description provided for @productsClearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar filtros'**
  String get productsClearFilters;

  /// No description provided for @productsEmptyFilteredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado'**
  String get productsEmptyFilteredTitle;

  /// No description provided for @productsEmptyFilteredSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste a pesquisa ou os filtros.'**
  String get productsEmptyFilteredSubtitle;

  /// No description provided for @productsFilteredCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 produto} other{{count} produtos}}'**
  String productsFilteredCount(int count);

  /// No description provided for @productsActiveLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto activo'**
  String get productsActiveLabel;

  /// No description provided for @productsActiveHint.
  ///
  /// In pt, this message translates to:
  /// **'Desactive para tirar do PDV e compras.'**
  String get productsActiveHint;

  /// No description provided for @productsStockAdjustHint.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste manual: define o estoque exato (FIFO).'**
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

  /// No description provided for @productsPhotoTake.
  ///
  /// In pt, this message translates to:
  /// **'Tirar fotografia'**
  String get productsPhotoTake;

  /// No description provided for @productsPhotoGallery.
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get productsPhotoGallery;

  /// No description provided for @productsPhotoRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover fotografia'**
  String get productsPhotoRemove;

  /// No description provided for @productsPurchasePriceError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o preço de compra'**
  String get productsPurchasePriceError;

  /// No description provided for @productsSalePriceError.
  ///
  /// In pt, this message translates to:
  /// **'Informe o preço de venda'**
  String get productsSalePriceError;

  /// No description provided for @productsStockError.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade inválida'**
  String get productsStockError;

  /// No description provided for @customersHeaderCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 cliente} other{{count} clientes}}'**
  String customersHeaderCount(int count);

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

  /// No description provided for @customersEditTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar cliente'**
  String get customersEditTitle;

  /// No description provided for @customersEditSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cliente {name} atualizado!'**
  String customersEditSuccess(Object name);

  /// No description provided for @customersEditError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o cliente. Tente novamente.'**
  String get customersEditError;

  /// No description provided for @customersEditSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Salvar alterações'**
  String get customersEditSubmit;

  /// No description provided for @customersDeleteConfirmTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover cliente?'**
  String get customersDeleteConfirmTitle;

  /// No description provided for @customersDeleteConfirmMessage.
  ///
  /// In pt, this message translates to:
  /// **'{name} será removido permanentemente. Registros de fiado são preservados.'**
  String customersDeleteConfirmMessage(Object name);

  /// No description provided for @customersDeleteSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cliente removido.'**
  String get customersDeleteSuccess;

  /// No description provided for @customersDeleteError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível remover o cliente. Tente novamente.'**
  String get customersDeleteError;

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
  /// **'Toque em \"Nova compra\" para registrar.'**
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
  /// **'Ajuste a busca ou os filtros.'**
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
  /// **'Item do carrinho não disponível. Tente novamente.'**
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

  /// No description provided for @financialPeriodBalance.
  ///
  /// In pt, this message translates to:
  /// **'Saldo líquido do período'**
  String get financialPeriodBalance;

  /// No description provided for @financialTransactions.
  ///
  /// In pt, this message translates to:
  /// **'Movimentos do período'**
  String get financialTransactions;

  /// No description provided for @financialLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as movimentações.'**
  String get financialLoadError;

  /// No description provided for @financialCashFlowError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o fluxo de caixa.'**
  String get financialCashFlowError;

  /// No description provided for @financialEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma movimentação'**
  String get financialEmptyTitle;

  /// No description provided for @financialEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Registre entradas e saídas para acompanhar o caixa.'**
  String get financialEmptySubtitle;

  /// No description provided for @financialReceivePendingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Receber pendência?'**
  String get financialReceivePendingTitle;

  /// No description provided for @financialReceivePendingBody.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar recebimento de {amount}?'**
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
  /// **'Não foi possível receber. Tente novamente.'**
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
  /// **'Confirmar pagamento de {amount}?'**
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
  /// **'Não conta no caixa até ser recebido.'**
  String get financialPendingHint;

  /// No description provided for @financialRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Movimentação registrada!'**
  String get financialRegistered;

  /// No description provided for @financialRegisterError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registrar. Tente novamente.'**
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

  /// No description provided for @financialDetailDescription.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get financialDetailDescription;

  /// No description provided for @financialDetailCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get financialDetailCategory;

  /// No description provided for @financialDetailNumber.
  ///
  /// In pt, this message translates to:
  /// **'Nº movimento'**
  String get financialDetailNumber;

  /// No description provided for @financialDetailDate.
  ///
  /// In pt, this message translates to:
  /// **'Data e hora'**
  String get financialDetailDate;

  /// No description provided for @financialDetailStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get financialDetailStatus;

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
  /// **'Só vendas em dinheiro.'**
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
  /// **'Conte o dinheiro da gaveta e informe aqui.'**
  String get cashClosingCountedCashHint;

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

  /// No description provided for @debtsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crédito (fiado)'**
  String get debtsTitle;

  /// No description provided for @debtsHeaderSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Fiado a receber e a pagar'**
  String get debtsHeaderSubtitle;

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

  /// No description provided for @debtsOverdueStat.
  ///
  /// In pt, this message translates to:
  /// **'Atrasados'**
  String get debtsOverdueStat;

  /// No description provided for @debtsSettledStat.
  ///
  /// In pt, this message translates to:
  /// **'Baixas'**
  String get debtsSettledStat;

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
  /// **'Nenhum fiado pendente'**
  String get debtsEmptyPendingTitle;

  /// No description provided for @debtsEmptyPendingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Fiados aparecerão aqui.'**
  String get debtsEmptyPendingSubtitle;

  /// No description provided for @debtsTotalSettled.
  ///
  /// In pt, this message translates to:
  /// **'Total quitado'**
  String get debtsTotalSettled;

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
  /// **'Fiados quitados aparecerão aqui.'**
  String get debtsEmptySettledSubtitle;

  /// No description provided for @debtsSettleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quitar dívida?'**
  String get debtsSettleTitle;

  /// No description provided for @debtsSettleBody.
  ///
  /// In pt, this message translates to:
  /// **'Receber {amount} de {name}?'**
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
  /// **'Não foi possível quitar. Tente novamente.'**
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

  /// No description provided for @debtsDueAgo.
  ///
  /// In pt, this message translates to:
  /// **'Venceu há {days, plural, =1{1 dia} other{{days} dias}}'**
  String debtsDueAgo(int days);

  /// No description provided for @debtsDueTodayDesc.
  ///
  /// In pt, this message translates to:
  /// **'Vence hoje'**
  String get debtsDueTodayDesc;

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
  /// **'Fiado registrado, mas a pendência não pôde ser criada.'**
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

  /// Cabeçalho da secção de itens do carrinho no PDV fullscreen
  ///
  /// In pt, this message translates to:
  /// **'Carrinho · {count, plural, =1{1 item} other{{count} itens}}'**
  String salesCartSection(int count);

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

  /// No description provided for @periodYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get periodYesterday;

  /// No description provided for @periodWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get periodWeek;

  /// No description provided for @paymentFilterCard.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get paymentFilterCard;

  /// No description provided for @paymentFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get paymentFilterAll;

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

  /// Contagem de vendas de hoje no cabeçalho do PDV fullscreen
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{0 vendas} =1{1 venda} other{{count} vendas}}'**
  String salesPdvCount(int count);

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
  /// **'Item do carrinho não disponível. Tente novamente.'**
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
  /// **'Estoque será devolvido e caixa estornado ({amount}).'**
  String saleDetailCancelConfirmBody(String amount);

  /// No description provided for @saleDetailCancelConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Sim, anular'**
  String get saleDetailCancelConfirm;

  /// No description provided for @saleDetailCancelBiometricReason.
  ///
  /// In pt, this message translates to:
  /// **'Confirme a sua identidade para anular a venda.'**
  String get saleDetailCancelBiometricReason;

  /// No description provided for @saleDetailCancelBiometricFailed.
  ///
  /// In pt, this message translates to:
  /// **'Identidade não confirmada. A venda não foi anulada.'**
  String get saleDetailCancelBiometricFailed;

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
  /// **'Nada pendente'**
  String get adminNothingPendingTitle;

  /// No description provided for @adminNothingPendingSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Novas solicitações aparecem aqui.'**
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
  /// **'Ex.: informações incompletas'**
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
  /// **'Inactivo'**
  String get adminPlanInactive;

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
  /// **'Plano activo'**
  String get adminPlanActiveTitle;

  /// No description provided for @adminPlanActiveSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Desactive para impedir novas assinaturas.'**
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
  /// **'Upgrade aprovado — plano atualizado!'**
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

  /// No description provided for @salesBarcodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Etiquetas de balança e PLUs — câmera ou leitor USB'**
  String get salesBarcodeHint;

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

  /// No description provided for @adminNavDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Visão Geral'**
  String get adminNavDashboard;

  /// No description provided for @adminNavAuditLog.
  ///
  /// In pt, this message translates to:
  /// **'Registo de Auditoria'**
  String get adminNavAuditLog;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Visão Geral'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardTotalTenants.
  ///
  /// In pt, this message translates to:
  /// **'Total de tenants'**
  String get adminDashboardTotalTenants;

  /// No description provided for @adminDashboardActiveTenants.
  ///
  /// In pt, this message translates to:
  /// **'Activos'**
  String get adminDashboardActiveTenants;

  /// No description provided for @adminDashboardPendingTenants.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando aprovação'**
  String get adminDashboardPendingTenants;

  /// No description provided for @adminDashboardPendingUpgrades.
  ///
  /// In pt, this message translates to:
  /// **'Upgrades pendentes'**
  String get adminDashboardPendingUpgrades;

  /// No description provided for @adminDashboardTotalPlans.
  ///
  /// In pt, this message translates to:
  /// **'Planos'**
  String get adminDashboardTotalPlans;

  /// No description provided for @adminDashboardLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a visão geral.'**
  String get adminDashboardLoadError;

  /// No description provided for @adminAuditLogEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma ação registada.'**
  String get adminAuditLogEmpty;

  /// No description provided for @adminAuditLogEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Ações administrativas aparecerão aqui.'**
  String get adminAuditLogEmptySubtitle;

  /// No description provided for @adminTenantDetailOwner.
  ///
  /// In pt, this message translates to:
  /// **'ID do proprietário'**
  String get adminTenantDetailOwner;

  /// No description provided for @adminTenantDetailPlan.
  ///
  /// In pt, this message translates to:
  /// **'Plano'**
  String get adminTenantDetailPlan;

  /// No description provided for @adminTenantDetailStores.
  ///
  /// In pt, this message translates to:
  /// **'Lojas'**
  String get adminTenantDetailStores;

  /// No description provided for @adminTenantDetailEmployees.
  ///
  /// In pt, this message translates to:
  /// **'Funcionários'**
  String get adminTenantDetailEmployees;

  /// No description provided for @adminTenantDetailStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get adminTenantDetailStatus;

  /// No description provided for @adminTenantDetailCreated.
  ///
  /// In pt, this message translates to:
  /// **'Criado em'**
  String get adminTenantDetailCreated;

  /// No description provided for @adminTenantDetailCurrency.
  ///
  /// In pt, this message translates to:
  /// **'Moeda'**
  String get adminTenantDetailCurrency;

  /// No description provided for @adminTenantDetailLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get adminTenantDetailLanguage;

  /// No description provided for @adminTenantDetailRejectionReason.
  ///
  /// In pt, this message translates to:
  /// **'Motivo da rejeição'**
  String get adminTenantDetailRejectionReason;

  /// No description provided for @adminTenantDetailApprovedAt.
  ///
  /// In pt, this message translates to:
  /// **'Aprovado em'**
  String get adminTenantDetailApprovedAt;

  /// No description provided for @adminTenantDetailStoresCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 loja} other{{count} lojas}}'**
  String adminTenantDetailStoresCount(int count);

  /// No description provided for @adminTenantDetailEmployeesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 funcionário} other{{count} funcionários}}'**
  String adminTenantDetailEmployeesCount(int count);

  /// No description provided for @adminTenantSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar tenants...'**
  String get adminTenantSearchHint;

  /// No description provided for @adminTenantDetailNoStores.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma loja criada'**
  String get adminTenantDetailNoStores;

  /// No description provided for @adminTenantDetailNoEmployees.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum funcionário vinculado'**
  String get adminTenantDetailNoEmployees;

  /// No description provided for @adminTenantDetailActivity.
  ///
  /// In pt, this message translates to:
  /// **'Atividade recente'**
  String get adminTenantDetailActivity;

  /// No description provided for @adminTenantDetailNoActivity.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atividade recente para este tenant'**
  String get adminTenantDetailNoActivity;

  /// No description provided for @adminTenantDetailActivityCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 ação recente} other{{count} ações recentes}}'**
  String adminTenantDetailActivityCount(int count);

  /// No description provided for @adminTenantDetailEmployeeRole.
  ///
  /// In pt, this message translates to:
  /// **'{role, select, manager{Gestor} other{Funcionário}}'**
  String adminTenantDetailEmployeeRole(String role);

  /// No description provided for @adminAuditLogAction.
  ///
  /// In pt, this message translates to:
  /// **'Ação'**
  String get adminAuditLogAction;

  /// No description provided for @adminAuditLogEntity.
  ///
  /// In pt, this message translates to:
  /// **'Entidade'**
  String get adminAuditLogEntity;

  /// No description provided for @adminAuditLogDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get adminAuditLogDate;

  /// No description provided for @adminAuditLogActor.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get adminAuditLogActor;

  /// No description provided for @adminBulkSelectAll.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar todos'**
  String get adminBulkSelectAll;

  /// No description provided for @adminBulkDeselectAll.
  ///
  /// In pt, this message translates to:
  /// **'Desmarcar todos'**
  String get adminBulkDeselectAll;

  /// No description provided for @adminBulkApprove.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar ({count})'**
  String adminBulkApprove(Object count);

  /// No description provided for @adminBulkReject.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar ({count})'**
  String adminBulkReject(Object count);

  /// No description provided for @adminBulkRejectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar {count} {count, plural, =1{tenant} other{tenants}}'**
  String adminBulkRejectTitle(int count);

  /// No description provided for @adminBulkApproveSuccess.
  ///
  /// In pt, this message translates to:
  /// **'{count} {count, plural, =1{tenant aprovado} other{tenants aprovados}}'**
  String adminBulkApproveSuccess(int count);

  /// No description provided for @adminBulkRejectSuccess.
  ///
  /// In pt, this message translates to:
  /// **'{count} {count, plural, =1{tenant rejeitado} other{tenants rejeitados}}'**
  String adminBulkRejectSuccess(int count);

  /// No description provided for @adminBulkApproveError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao aprovar tenants. Alguns podem não ter sido processados.'**
  String get adminBulkApproveError;

  /// No description provided for @adminBulkRejectError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao rejeitar tenants. Alguns podem não ter sido processados.'**
  String get adminBulkRejectError;

  /// No description provided for @adminActionManagePlans.
  ///
  /// In pt, this message translates to:
  /// **'Gerir Planos'**
  String get adminActionManagePlans;

  /// No description provided for @adminActionViewAuditLog.
  ///
  /// In pt, this message translates to:
  /// **'Ver Registo de Auditoria'**
  String get adminActionViewAuditLog;

  /// No description provided for @adminTenantRequests.
  ///
  /// In pt, this message translates to:
  /// **'Solicitações de Tenant'**
  String get adminTenantRequests;

  /// No description provided for @adminPlanUpgrades.
  ///
  /// In pt, this message translates to:
  /// **'Upgrades de Plano'**
  String get adminPlanUpgrades;

  /// No description provided for @adminPendingActionRequired.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 ação necessária} other{{count} ações necessárias}}'**
  String adminPendingActionRequired(int count);

  /// No description provided for @adminAuditLogAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get adminAuditLogAll;

  /// No description provided for @adminAuditLogTenants.
  ///
  /// In pt, this message translates to:
  /// **'Tenants'**
  String get adminAuditLogTenants;

  /// No description provided for @adminAuditLogPlans.
  ///
  /// In pt, this message translates to:
  /// **'Planos'**
  String get adminAuditLogPlans;

  /// No description provided for @adminAuditLogUpgrades.
  ///
  /// In pt, this message translates to:
  /// **'Upgrades'**
  String get adminAuditLogUpgrades;

  /// No description provided for @adminAuditLogApproved.
  ///
  /// In pt, this message translates to:
  /// **'Aprovados'**
  String get adminAuditLogApproved;

  /// No description provided for @adminAuditLogRejected.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitados'**
  String get adminAuditLogRejected;

  /// No description provided for @adminAuditLogToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get adminAuditLogToday;

  /// No description provided for @adminAuditLogYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get adminAuditLogYesterday;

  /// No description provided for @adminAuditLogThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get adminAuditLogThisWeek;

  /// No description provided for @adminAuditLogOlder.
  ///
  /// In pt, this message translates to:
  /// **'Mais antigo'**
  String get adminAuditLogOlder;

  /// No description provided for @adminAuditLogSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar registo de auditoria...'**
  String get adminAuditLogSearchHint;

  /// No description provided for @adminAuditLogNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma entrada corresponde ao filtro.'**
  String get adminAuditLogNoResults;

  /// No description provided for @adminDashboardPlanDistribution.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição de planos'**
  String get adminDashboardPlanDistribution;

  /// No description provided for @adminDashboardRecentActivity.
  ///
  /// In pt, this message translates to:
  /// **'Atividade recente'**
  String get adminDashboardRecentActivity;

  /// No description provided for @adminGrowthTrends.
  ///
  /// In pt, this message translates to:
  /// **'Tendências de Crescimento'**
  String get adminGrowthTrends;

  /// No description provided for @adminGrowthTrendsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tendências (8 semanas)'**
  String get adminGrowthTrendsLabel;

  /// No description provided for @adminGrowthThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Esta semana'**
  String get adminGrowthThisWeek;

  /// No description provided for @adminGrowthLastWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana passada'**
  String get adminGrowthLastWeek;

  /// No description provided for @adminGrowthThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get adminGrowthThisMonth;

  /// No description provided for @adminGrowthLastMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês passado'**
  String get adminGrowthLastMonth;

  /// No description provided for @adminGrowthNewTenants.
  ///
  /// In pt, this message translates to:
  /// **'Novos tenants'**
  String get adminGrowthNewTenants;

  /// No description provided for @adminGrowthApprovals.
  ///
  /// In pt, this message translates to:
  /// **'Aprovações'**
  String get adminGrowthApprovals;

  /// No description provided for @adminGrowthUp.
  ///
  /// In pt, this message translates to:
  /// **'+{count}'**
  String adminGrowthUp(String count);

  /// No description provided for @adminGrowthDown.
  ///
  /// In pt, this message translates to:
  /// **'-{count}'**
  String adminGrowthDown(String count);

  /// No description provided for @adminGrowthFlat.
  ///
  /// In pt, this message translates to:
  /// **'Sem alteração'**
  String get adminGrowthFlat;

  /// No description provided for @adminGrowthRegistrationsTrend.
  ///
  /// In pt, this message translates to:
  /// **'Registos (últimas 8 semanas)'**
  String get adminGrowthRegistrationsTrend;

  /// No description provided for @adminGrowthActivityTrend.
  ///
  /// In pt, this message translates to:
  /// **'Atividade (últimas 8 semanas)'**
  String get adminGrowthActivityTrend;

  /// No description provided for @adminGrowthNoData.
  ///
  /// In pt, this message translates to:
  /// **'Dados insuficientes para mostrar tendências'**
  String get adminGrowthNoData;

  /// No description provided for @adminNavInvoices.
  ///
  /// In pt, this message translates to:
  /// **'Facturas'**
  String get adminNavInvoices;

  /// No description provided for @adminInvoicesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Facturas de Cobrança'**
  String get adminInvoicesTitle;

  /// No description provided for @adminInvoicesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma factura gerada ainda.'**
  String get adminInvoicesEmpty;

  /// No description provided for @adminInvoicesEmptyPending.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma factura pendente.'**
  String get adminInvoicesEmptyPending;

  /// No description provided for @adminInvoicesLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as facturas.'**
  String get adminInvoicesLoadError;

  /// No description provided for @adminInvoiceSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar facturas...'**
  String get adminInvoiceSearchHint;

  /// No description provided for @adminInvoiceAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor:'**
  String get adminInvoiceAmount;

  /// No description provided for @adminInvoiceDue.
  ///
  /// In pt, this message translates to:
  /// **'Vencimento:'**
  String get adminInvoiceDue;

  /// No description provided for @adminInvoicePaidAt.
  ///
  /// In pt, this message translates to:
  /// **'Pago em:'**
  String get adminInvoicePaidAt;

  /// No description provided for @adminInvoiceMarkPaid.
  ///
  /// In pt, this message translates to:
  /// **'Marcar como paga'**
  String get adminInvoiceMarkPaid;

  /// No description provided for @adminInvoiceMarkedPaid.
  ///
  /// In pt, this message translates to:
  /// **'Factura marcada como paga!'**
  String get adminInvoiceMarkedPaid;

  /// No description provided for @adminInvoiceMarkPaidError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível marcar como paga. Tente novamente.'**
  String get adminInvoiceMarkPaidError;

  /// No description provided for @adminInvoiceCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get adminInvoiceCancel;

  /// No description provided for @adminInvoiceCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Factura cancelada.'**
  String get adminInvoiceCancelled;

  /// No description provided for @adminInvoiceCancelError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cancelar a factura. Tente novamente.'**
  String get adminInvoiceCancelError;

  /// No description provided for @adminInvoiceCancelTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar factura?'**
  String get adminInvoiceCancelTitle;

  /// No description provided for @adminInvoiceCancelConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar a factura de {period}?'**
  String adminInvoiceCancelConfirm(String period);

  /// No description provided for @adminInvoiceCancelConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'Sim, cancelar'**
  String get adminInvoiceCancelConfirmButton;

  /// No description provided for @invoiceStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get invoiceStatusPending;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirada'**
  String get invoiceStatusExpired;

  /// No description provided for @invoiceStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get invoiceStatusCancelled;

  /// No description provided for @notificationInvoiceGenerated.
  ///
  /// In pt, this message translates to:
  /// **'Nova factura gerada'**
  String get notificationInvoiceGenerated;

  /// No description provided for @notificationInvoiceDueSoon.
  ///
  /// In pt, this message translates to:
  /// **'Factura para vencer'**
  String get notificationInvoiceDueSoon;

  /// No description provided for @notificationInvoiceExpired.
  ///
  /// In pt, this message translates to:
  /// **'Factura expirada'**
  String get notificationInvoiceExpired;

  /// No description provided for @notificationInvoicePaid.
  ///
  /// In pt, this message translates to:
  /// **'Factura paga'**
  String get notificationInvoicePaid;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In pt, this message translates to:
  /// **'Marcar todas como lidas'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationNoNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Sem notificações'**
  String get notificationNoNotifications;

  /// No description provided for @notificationNoNotificationsHint.
  ///
  /// In pt, this message translates to:
  /// **'As notificações de facturas aparecerão aqui.'**
  String get notificationNoNotificationsHint;

  /// No description provided for @notificationTabAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get notificationTabAll;

  /// No description provided for @notificationTabUnread.
  ///
  /// In pt, this message translates to:
  /// **'Não lidas'**
  String get notificationTabUnread;

  /// No description provided for @notificationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationTitle;

  /// No description provided for @menuNotifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get menuNotifications;

  /// No description provided for @notificationSinceDaysAgo.
  ///
  /// In pt, this message translates to:
  /// **'{count} dias atrás'**
  String notificationSinceDaysAgo(int count);

  /// No description provided for @notificationYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get notificationYesterday;

  /// No description provided for @notificationJustNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora mesmo'**
  String get notificationJustNow;

  /// No description provided for @notificationAdminLabelQuote.
  ///
  /// In pt, this message translates to:
  /// **'Cotação'**
  String get notificationAdminLabelQuote;

  /// No description provided for @notificationAdminLabelValidity.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get notificationAdminLabelValidity;

  /// No description provided for @notificationAdminLabelExpiring.
  ///
  /// In pt, this message translates to:
  /// **'Expira'**
  String get notificationAdminLabelExpiring;

  /// No description provided for @notificationAdminLabelGeneral.
  ///
  /// In pt, this message translates to:
  /// **'Geral'**
  String get notificationAdminLabelGeneral;

  /// No description provided for @notificationAddonExpiringTitle.
  ///
  /// In pt, this message translates to:
  /// **'Add-on a expirar'**
  String get notificationAddonExpiringTitle;

  /// No description provided for @notificationAddonExpiredTitle.
  ///
  /// In pt, this message translates to:
  /// **'Add-on expirado'**
  String get notificationAddonExpiredTitle;

  /// No description provided for @notificationIconInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Factura'**
  String get notificationIconInvoice;

  /// No description provided for @notificationIconDue.
  ///
  /// In pt, this message translates to:
  /// **'Vence'**
  String get notificationIconDue;

  /// No description provided for @notificationIconExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirada'**
  String get notificationIconExpired;

  /// No description provided for @notificationIconPaid.
  ///
  /// In pt, this message translates to:
  /// **'Paga'**
  String get notificationIconPaid;

  /// No description provided for @notificationIconExpiring.
  ///
  /// In pt, this message translates to:
  /// **'A expirar'**
  String get notificationIconExpiring;

  /// No description provided for @notificationIconExpiredShort.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get notificationIconExpiredShort;

  /// No description provided for @notificationDaysShort.
  ///
  /// In pt, this message translates to:
  /// **'{days}d'**
  String notificationDaysShort(int days);

  /// No description provided for @adminMessagesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mensagens para Tenants'**
  String get adminMessagesTitle;

  /// No description provided for @adminMessagesSendSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem enviada!'**
  String get adminMessagesSendSuccess;

  /// No description provided for @adminMessagesSendError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar a mensagem. Tente novamente.'**
  String get adminMessagesSendError;

  /// No description provided for @adminMessagesTenantLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tenant'**
  String get adminMessagesTenantLabel;

  /// No description provided for @adminMessagesTenantError.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um tenant.'**
  String get adminMessagesTenantError;

  /// No description provided for @adminMessagesTypeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tipo'**
  String get adminMessagesTypeLabel;

  /// No description provided for @adminMessagesTitleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Título'**
  String get adminMessagesTitleLabel;

  /// No description provided for @adminMessagesTitleError.
  ///
  /// In pt, this message translates to:
  /// **'Digite um título.'**
  String get adminMessagesTitleError;

  /// No description provided for @adminMessagesBodyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem'**
  String get adminMessagesBodyLabel;

  /// No description provided for @adminMessagesBodyError.
  ///
  /// In pt, this message translates to:
  /// **'Digite o corpo da mensagem.'**
  String get adminMessagesBodyError;

  /// No description provided for @adminMessagesSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get adminMessagesSubmit;

  /// No description provided for @adminNavMessages.
  ///
  /// In pt, this message translates to:
  /// **'Mensagens'**
  String get adminNavMessages;

  /// No description provided for @customInvoiceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Factura Personalizada'**
  String get customInvoiceTitle;

  /// No description provided for @customInvoiceEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma factura'**
  String get customInvoiceEmpty;

  /// No description provided for @customInvoiceEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie facturas profissionais com layout\npersonalizado para os seus clientes'**
  String get customInvoiceEmptySubtitle;

  /// No description provided for @customInvoiceLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as facturas.'**
  String get customInvoiceLoadError;

  /// No description provided for @customInvoiceLoadErrorHint.
  ///
  /// In pt, this message translates to:
  /// **'Verifique a conexão e tente novamente.'**
  String get customInvoiceLoadErrorHint;

  /// No description provided for @customInvoiceCreated.
  ///
  /// In pt, this message translates to:
  /// **'Factura nº {number} criada!'**
  String customInvoiceCreated(int number);

  /// No description provided for @customInvoiceSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar a factura. Tente novamente.'**
  String get customInvoiceSaveError;

  /// No description provided for @customInvoiceTemplateTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Modelo da Factura'**
  String get customInvoiceTemplateTooltip;

  /// No description provided for @customInvoiceNewFab.
  ///
  /// In pt, this message translates to:
  /// **'Nova Factura'**
  String get customInvoiceNewFab;

  /// No description provided for @customInvoiceItemsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} itens}}'**
  String customInvoiceItemsCount(num count);

  /// No description provided for @customInvoiceWhatsApp.
  ///
  /// In pt, this message translates to:
  /// **'WhatsApp'**
  String get customInvoiceWhatsApp;

  /// No description provided for @customInvoiceCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar Factura'**
  String get customInvoiceCreate;

  /// No description provided for @customInvoiceClientSection.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get customInvoiceClientSection;

  /// No description provided for @customInvoiceClientName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do cliente'**
  String get customInvoiceClientName;

  /// No description provided for @customInvoicePhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get customInvoicePhone;

  /// No description provided for @customInvoiceTaxIdOptional.
  ///
  /// In pt, this message translates to:
  /// **'NIF / NUIT (opcional)'**
  String get customInvoiceTaxIdOptional;

  /// No description provided for @customInvoiceProductSection.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get customInvoiceProductSection;

  /// No description provided for @customInvoiceProductPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Sem produtos cadastrados'**
  String get customInvoiceProductPlaceholder;

  /// No description provided for @customInvoiceProductOption.
  ///
  /// In pt, this message translates to:
  /// **'Estoque: {stock} {unit}  •  {price}'**
  String customInvoiceProductOption(Object price, Object stock, Object unit);

  /// No description provided for @customInvoicePrice.
  ///
  /// In pt, this message translates to:
  /// **'Preço (MT)'**
  String get customInvoicePrice;

  /// No description provided for @customInvoiceQty.
  ///
  /// In pt, this message translates to:
  /// **'Qtd'**
  String get customInvoiceQty;

  /// No description provided for @customInvoiceAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get customInvoiceAddItem;

  /// No description provided for @customInvoiceDiscount.
  ///
  /// In pt, this message translates to:
  /// **'Desconto (MT)'**
  String get customInvoiceDiscount;

  /// No description provided for @customInvoiceTax.
  ///
  /// In pt, this message translates to:
  /// **'IVA (MT)'**
  String get customInvoiceTax;

  /// No description provided for @customInvoiceBillTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total: {total}'**
  String customInvoiceBillTotal(Object total);

  /// No description provided for @customInvoiceNumberPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Nº {number}'**
  String customInvoiceNumberPrefix(Object number);

  /// No description provided for @customInvoiceTemplateSaved.
  ///
  /// In pt, this message translates to:
  /// **'Modelo guardado com sucesso'**
  String get customInvoiceTemplateSaved;

  /// No description provided for @customInvoiceTemplateLogoSection.
  ///
  /// In pt, this message translates to:
  /// **'Logotipo da Empresa'**
  String get customInvoiceTemplateLogoSection;

  /// No description provided for @customInvoiceTemplateLogoHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque para carregar logotipo'**
  String get customInvoiceTemplateLogoHint;

  /// No description provided for @customInvoiceTemplateColorSection.
  ///
  /// In pt, this message translates to:
  /// **'Cor Principal'**
  String get customInvoiceTemplateColorSection;

  /// No description provided for @customInvoiceTemplateCompanySection.
  ///
  /// In pt, this message translates to:
  /// **'Dados da Empresa'**
  String get customInvoiceTemplateCompanySection;

  /// No description provided for @customInvoiceTemplateCompanyName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Empresa'**
  String get customInvoiceTemplateCompanyName;

  /// No description provided for @customInvoiceTemplateAddress.
  ///
  /// In pt, this message translates to:
  /// **'Morada'**
  String get customInvoiceTemplateAddress;

  /// No description provided for @customInvoiceTemplateTaxId.
  ///
  /// In pt, this message translates to:
  /// **'NIF / NUIT'**
  String get customInvoiceTemplateTaxId;

  /// No description provided for @customInvoiceTemplateStyle.
  ///
  /// In pt, this message translates to:
  /// **'Estilo'**
  String get customInvoiceTemplateStyle;

  /// No description provided for @customInvoiceTemplateStyleClassic.
  ///
  /// In pt, this message translates to:
  /// **'Clássico'**
  String get customInvoiceTemplateStyleClassic;

  /// No description provided for @customInvoiceTemplateStyleModern.
  ///
  /// In pt, this message translates to:
  /// **'Moderno'**
  String get customInvoiceTemplateStyleModern;

  /// No description provided for @customInvoiceTemplateStyleCompact.
  ///
  /// In pt, this message translates to:
  /// **'Compacto'**
  String get customInvoiceTemplateStyleCompact;

  /// No description provided for @customInvoiceTemplateSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Modelo'**
  String get customInvoiceTemplateSave;

  /// No description provided for @customInvoicePreviewCompanyFallback.
  ///
  /// In pt, this message translates to:
  /// **'Nome da Empresa'**
  String get customInvoicePreviewCompanyFallback;

  /// No description provided for @quotationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cotações / Orçamentos'**
  String get quotationTitle;

  /// No description provided for @quotationEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cotação'**
  String get quotationEmpty;

  /// No description provided for @quotationEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie cotações e orçamentos para os seus clientes'**
  String get quotationEmptySubtitle;

  /// No description provided for @quotationLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as cotações.'**
  String get quotationLoadError;

  /// No description provided for @quotationLoadErrorHint.
  ///
  /// In pt, this message translates to:
  /// **'Verifique a conexão e tente novamente.'**
  String get quotationLoadErrorHint;

  /// No description provided for @quotationCreated.
  ///
  /// In pt, this message translates to:
  /// **'Cotação nº {number} criada!'**
  String quotationCreated(int number);

  /// No description provided for @quotationSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar a cotação. Tente novamente.'**
  String get quotationSaveError;

  /// No description provided for @quotationStatusSaved.
  ///
  /// In pt, this message translates to:
  /// **'Estado da cotação actualizado'**
  String get quotationStatusSaved;

  /// No description provided for @quotationStatusError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível actualizar a cotação. Tente novamente.'**
  String get quotationStatusError;

  /// No description provided for @quotationTemplateTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Modelo da Cotação'**
  String get quotationTemplateTooltip;

  /// No description provided for @quotationNewFab.
  ///
  /// In pt, this message translates to:
  /// **'Nova Cotação'**
  String get quotationNewFab;

  /// No description provided for @quotationItemsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} itens}}'**
  String quotationItemsCount(num count);

  /// No description provided for @quotationValidity.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get quotationValidity;

  /// No description provided for @quotationDays.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{1 dia} other{{days} dias}}'**
  String quotationDays(num days);

  /// No description provided for @quotationSend.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get quotationSend;

  /// No description provided for @quotationAccept.
  ///
  /// In pt, this message translates to:
  /// **'Aceitar'**
  String get quotationAccept;

  /// No description provided for @quotationReject.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitar'**
  String get quotationReject;

  /// No description provided for @quotationStatusDraft.
  ///
  /// In pt, this message translates to:
  /// **'Rascunho'**
  String get quotationStatusDraft;

  /// No description provided for @quotationStatusSent.
  ///
  /// In pt, this message translates to:
  /// **'Enviada'**
  String get quotationStatusSent;

  /// No description provided for @quotationStatusAccepted.
  ///
  /// In pt, this message translates to:
  /// **'Aceite'**
  String get quotationStatusAccepted;

  /// No description provided for @quotationStatusRejected.
  ///
  /// In pt, this message translates to:
  /// **'Rejeitada'**
  String get quotationStatusRejected;

  /// No description provided for @quotationPhoneOptional.
  ///
  /// In pt, this message translates to:
  /// **'Telefone (opcional)'**
  String get quotationPhoneOptional;

  /// No description provided for @quotationNumberPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Nº {number}'**
  String quotationNumberPrefix(Object number);

  /// No description provided for @quotationSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Cotação'**
  String get quotationSave;

  /// No description provided for @quotationTemplatePhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get quotationTemplatePhone;

  /// No description provided for @quotationTemplatePreview.
  ///
  /// In pt, this message translates to:
  /// **'Cotação • Preview'**
  String get quotationTemplatePreview;

  /// No description provided for @quotationTemplatePreviewBadge.
  ///
  /// In pt, this message translates to:
  /// **'Preview'**
  String get quotationTemplatePreviewBadge;

  /// No description provided for @paletteBlue.
  ///
  /// In pt, this message translates to:
  /// **'Azul'**
  String get paletteBlue;

  /// No description provided for @paletteGreen.
  ///
  /// In pt, this message translates to:
  /// **'Verde'**
  String get paletteGreen;

  /// No description provided for @paletteRed.
  ///
  /// In pt, this message translates to:
  /// **'Vermelho'**
  String get paletteRed;

  /// No description provided for @paletteAmber.
  ///
  /// In pt, this message translates to:
  /// **'Âmbar'**
  String get paletteAmber;

  /// No description provided for @paletteSlate.
  ///
  /// In pt, this message translates to:
  /// **'Slate'**
  String get paletteSlate;

  /// No description provided for @paletteViolet.
  ///
  /// In pt, this message translates to:
  /// **'Violeta'**
  String get paletteViolet;

  /// No description provided for @paletteTeal.
  ///
  /// In pt, this message translates to:
  /// **'Teal'**
  String get paletteTeal;

  /// No description provided for @paletteIndigo.
  ///
  /// In pt, this message translates to:
  /// **'Indigo'**
  String get paletteIndigo;

  /// No description provided for @customInvoicePdf.
  ///
  /// In pt, this message translates to:
  /// **'PDF'**
  String get customInvoicePdf;

  /// No description provided for @imageSourceGallery.
  ///
  /// In pt, this message translates to:
  /// **'Galeria'**
  String get imageSourceGallery;

  /// No description provided for @imageSourceCamera.
  ///
  /// In pt, this message translates to:
  /// **'Câmara'**
  String get imageSourceCamera;

  /// No description provided for @businessFallbackName.
  ///
  /// In pt, this message translates to:
  /// **'Minha Empresa'**
  String get businessFallbackName;

  /// No description provided for @customInvoiceWhatsAppHeader.
  ///
  /// In pt, this message translates to:
  /// **'═══ FACTURA ═══'**
  String get customInvoiceWhatsAppHeader;

  /// No description provided for @customInvoiceNumberShort.
  ///
  /// In pt, this message translates to:
  /// **'Nº'**
  String get customInvoiceNumberShort;

  /// No description provided for @customInvoiceClientLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get customInvoiceClientLabel;

  /// No description provided for @customInvoicePhoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tel'**
  String get customInvoicePhoneLabel;

  /// No description provided for @customInvoiceTotalLabel.
  ///
  /// In pt, this message translates to:
  /// **'TOTAL'**
  String get customInvoiceTotalLabel;

  /// No description provided for @customInvoiceNew.
  ///
  /// In pt, this message translates to:
  /// **'Nova Factura'**
  String get customInvoiceNew;

  /// No description provided for @customInvoiceTemplateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelo da Factura'**
  String get customInvoiceTemplateTitle;

  /// No description provided for @commonPreview.
  ///
  /// In pt, this message translates to:
  /// **'Preview'**
  String get commonPreview;

  /// No description provided for @quotationWhatsAppHeader.
  ///
  /// In pt, this message translates to:
  /// **'═══ COTAÇÃO ═══'**
  String get quotationWhatsAppHeader;

  /// No description provided for @quotationTemplateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelo da Cotação'**
  String get quotationTemplateTitle;

  /// No description provided for @employeeMgmtTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Funcionários'**
  String get employeeMgmtTitle;

  /// No description provided for @employeeMgmtTabAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Ponto'**
  String get employeeMgmtTabAttendance;

  /// No description provided for @employeeMgmtTabCommissions.
  ///
  /// In pt, this message translates to:
  /// **'Comissões'**
  String get employeeMgmtTabCommissions;

  /// No description provided for @employeeMgmtTabTargets.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get employeeMgmtTabTargets;

  /// No description provided for @employeePresentCount.
  ///
  /// In pt, this message translates to:
  /// **'Presentes'**
  String get employeePresentCount;

  /// No description provided for @employeeAbsentCount.
  ///
  /// In pt, this message translates to:
  /// **'Ausentes'**
  String get employeeAbsentCount;

  /// No description provided for @employeeClockInAction.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get employeeClockInAction;

  /// No description provided for @employeeClockOutAction.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get employeeClockOutAction;

  /// No description provided for @employeeClockOutInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Em curso'**
  String get employeeClockOutInProgress;

  /// No description provided for @employeeAttendanceSection.
  ///
  /// In pt, this message translates to:
  /// **'Registo de Ponto'**
  String get employeeAttendanceSection;

  /// No description provided for @employeeRecordsSection.
  ///
  /// In pt, this message translates to:
  /// **'Registos de Hoje'**
  String get employeeRecordsSection;

  /// No description provided for @employeeAttendanceEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum funcionário vinculado a esta loja. Crie contas no módulo Lojas.'**
  String get employeeAttendanceEmpty;

  /// No description provided for @employeeMgmtLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os dados de funcionários.'**
  String get employeeMgmtLoadError;

  /// No description provided for @employeeMgmtNoStoreTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem loja activa'**
  String get employeeMgmtNoStoreTitle;

  /// No description provided for @employeeMgmtNoStoreAttendance.
  ///
  /// In pt, this message translates to:
  /// **'Conclua o onboarding para registar o ponto.'**
  String get employeeMgmtNoStoreAttendance;

  /// No description provided for @employeeMgmtNoStoreCommissions.
  ///
  /// In pt, this message translates to:
  /// **'Conclua o onboarding para ver comissões.'**
  String get employeeMgmtNoStoreCommissions;

  /// No description provided for @employeeMgmtNoStoreTargets.
  ///
  /// In pt, this message translates to:
  /// **'Conclua o onboarding para definir metas.'**
  String get employeeMgmtNoStoreTargets;

  /// No description provided for @employeeClockInError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registar a entrada.'**
  String get employeeClockInError;

  /// No description provided for @employeeClockOutError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registar a saída.'**
  String get employeeClockOutError;

  /// No description provided for @employeeSalesMonth.
  ///
  /// In pt, this message translates to:
  /// **'Vendas do Mês'**
  String get employeeSalesMonth;

  /// No description provided for @employeeCommissionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comissões'**
  String get employeeCommissionTitle;

  /// No description provided for @employeeCommissionPerEmployee.
  ///
  /// In pt, this message translates to:
  /// **'Comissão por Funcionário'**
  String get employeeCommissionPerEmployee;

  /// No description provided for @employeeCommissionRate.
  ///
  /// In pt, this message translates to:
  /// **'{rate}% sobre {amount}'**
  String employeeCommissionRate(int rate, String amount);

  /// No description provided for @employeeCommissionNoRate.
  ///
  /// In pt, this message translates to:
  /// **'Sem taxa definida'**
  String get employeeCommissionNoRate;

  /// No description provided for @employeeCommissionSetRate.
  ///
  /// In pt, this message translates to:
  /// **'Definir Taxa'**
  String get employeeCommissionSetRate;

  /// No description provided for @employeeCommissionRateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de comissão (%)'**
  String get employeeCommissionRateLabel;

  /// No description provided for @employeeCommissionRateSaved.
  ///
  /// In pt, this message translates to:
  /// **'Taxa de comissão actualizada.'**
  String get employeeCommissionRateSaved;

  /// No description provided for @employeeCommissionRateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar a taxa.'**
  String get employeeCommissionRateError;

  /// No description provided for @employeeTargetsActive.
  ///
  /// In pt, this message translates to:
  /// **'Metas Activas'**
  String get employeeTargetsActive;

  /// No description provided for @employeeTargetsReached.
  ///
  /// In pt, this message translates to:
  /// **'Atingidas'**
  String get employeeTargetsReached;

  /// No description provided for @employeeTargetsPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendentes'**
  String get employeeTargetsPending;

  /// No description provided for @employeeTargetsMonth.
  ///
  /// In pt, this message translates to:
  /// **'Metas do Mês'**
  String get employeeTargetsMonth;

  /// No description provided for @employeeTargetsEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma meta definida'**
  String get employeeTargetsEmptyTitle;

  /// No description provided for @employeeTargetsEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Defina metas mensais de vendas para cada funcionário'**
  String get employeeTargetsEmptySubtitle;

  /// No description provided for @employeeTargetAdd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar Meta'**
  String get employeeTargetAdd;

  /// No description provided for @employeeTargetMeta.
  ///
  /// In pt, this message translates to:
  /// **'Meta: {amount}'**
  String employeeTargetMeta(String amount);

  /// No description provided for @employeeTargetNewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova Meta'**
  String get employeeTargetNewTitle;

  /// No description provided for @employeeTargetEmployee.
  ///
  /// In pt, this message translates to:
  /// **'Funcionário'**
  String get employeeTargetEmployee;

  /// No description provided for @employeeTargetAllHave.
  ///
  /// In pt, this message translates to:
  /// **'Todos os funcionários já possuem meta definida'**
  String get employeeTargetAllHave;

  /// No description provided for @employeeTargetMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Meta Mensal (MT)'**
  String get employeeTargetMonthly;

  /// No description provided for @employeeTargetSave.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Meta'**
  String get employeeTargetSave;

  /// No description provided for @employeeTargetProgress.
  ///
  /// In pt, this message translates to:
  /// **'{progress}% da meta'**
  String employeeTargetProgress(int progress);

  /// No description provided for @employeeTargetSaved.
  ///
  /// In pt, this message translates to:
  /// **'Meta definida.'**
  String get employeeTargetSaved;

  /// No description provided for @employeeTargetRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Meta removida.'**
  String get employeeTargetRemoved;

  /// No description provided for @employeeTargetError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar a meta.'**
  String get employeeTargetError;

  /// No description provided for @employeeRoleSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendedor'**
  String get employeeRoleSales;

  /// No description provided for @addonsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Add-ons'**
  String get addonsTitle;

  /// No description provided for @addonsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Add-ons activos e disponíveis no seu plano'**
  String get addonsSubtitle;

  /// No description provided for @addonsManagedByAdmin.
  ///
  /// In pt, this message translates to:
  /// **'A activação de add-ons é gerida pelo administrador do sistema.'**
  String get addonsManagedByAdmin;

  /// No description provided for @addonsIncluded.
  ///
  /// In pt, this message translates to:
  /// **'Incluído'**
  String get addonsIncluded;

  /// No description provided for @addonsActive.
  ///
  /// In pt, this message translates to:
  /// **'Activo'**
  String get addonsActive;

  /// No description provided for @addonsPerMonth.
  ///
  /// In pt, this message translates to:
  /// **'{amount} MT/mês'**
  String addonsPerMonth(Object amount);

  /// No description provided for @addonCategoryInvoicing.
  ///
  /// In pt, this message translates to:
  /// **'Facturação'**
  String get addonCategoryInvoicing;

  /// No description provided for @addonCategoryQuotation.
  ///
  /// In pt, this message translates to:
  /// **'Cotação'**
  String get addonCategoryQuotation;

  /// No description provided for @addonCategoryReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get addonCategoryReports;

  /// No description provided for @addonCategoryEmployees.
  ///
  /// In pt, this message translates to:
  /// **'Funcionários'**
  String get addonCategoryEmployees;

  /// No description provided for @addonCategoryMultiStore.
  ///
  /// In pt, this message translates to:
  /// **'Multi-Loja'**
  String get addonCategoryMultiStore;

  /// No description provided for @addonCategoryPayments.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos'**
  String get addonCategoryPayments;

  /// No description provided for @commonTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @addonCustomInvoiceName.
  ///
  /// In pt, this message translates to:
  /// **'Factura Personalizada'**
  String get addonCustomInvoiceName;

  /// No description provided for @addonCustomInvoiceDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crie facturas profissionais com logotipo, layout customizável e exportação em PDF. Inclui templates prontos e personalização de cores, fontes e campos.'**
  String get addonCustomInvoiceDesc;

  /// No description provided for @addonQuotationName.
  ///
  /// In pt, this message translates to:
  /// **'Cotação / Orçamento'**
  String get addonQuotationName;

  /// No description provided for @addonQuotationDesc.
  ///
  /// In pt, this message translates to:
  /// **'Crie e envie cotações e orçamentos para clientes antes da venda. Inclui conversão automática para venda, validade configurável e envio por SMS/WhatsApp.'**
  String get addonQuotationDesc;

  /// No description provided for @addonReportsName.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios Avançados'**
  String get addonReportsName;

  /// No description provided for @addonReportsDesc.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios financeiros, de vendas e estoque com filtros avançados, comparativos período a período e exportação em PDF/Excel. Inclui gráficos interativos e dashboards personalizados.'**
  String get addonReportsDesc;

  /// No description provided for @addonEmployeesName.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de Funcionários'**
  String get addonEmployeesName;

  /// No description provided for @addonEmployeesDesc.
  ///
  /// In pt, this message translates to:
  /// **'Controle de ponto (entrada/saída), cálculo automático de comissões por venda, definição de metas mensais e relatório de desempenho individual.'**
  String get addonEmployeesDesc;

  /// No description provided for @addonMultiStoreName.
  ///
  /// In pt, this message translates to:
  /// **'Multi-Loja Avançado'**
  String get addonMultiStoreName;

  /// No description provided for @addonMultiStoreDesc.
  ///
  /// In pt, this message translates to:
  /// **'Transferência de estoque entre lojas, relatórios consolidados comparando lojas, gestão centralizada de preços e promoções e alertas de reposição automática.'**
  String get addonMultiStoreDesc;

  /// No description provided for @addonMobileMoneyName.
  ///
  /// In pt, this message translates to:
  /// **'Integração M-Pesa / E-Mola'**
  String get addonMobileMoneyName;

  /// No description provided for @addonMobileMoneyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Pagamentos automáticos via mobile money com reconciliação automática, notificações de recebimento em tempo real e relatório de transações mobile money.'**
  String get addonMobileMoneyDesc;

  /// No description provided for @transfersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Transferências entre Lojas'**
  String get transfersTitle;

  /// No description provided for @transfersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem transferências'**
  String get transfersEmpty;

  /// No description provided for @transfersEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Transfira estoque entre lojas do\nmesmo tenant de forma rastreável'**
  String get transfersEmptySubtitle;

  /// No description provided for @transfersNewFab.
  ///
  /// In pt, this message translates to:
  /// **'Nova Transferência'**
  String get transfersNewFab;

  /// No description provided for @transfersOriginStore.
  ///
  /// In pt, this message translates to:
  /// **'Loja de Origem'**
  String get transfersOriginStore;

  /// No description provided for @transfersDestStore.
  ///
  /// In pt, this message translates to:
  /// **'Loja de Destino'**
  String get transfersDestStore;

  /// No description provided for @transfersProduct.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get transfersProduct;

  /// No description provided for @transfersProductPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'Sem produtos cadastrados'**
  String get transfersProductPlaceholder;

  /// No description provided for @transfersQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get transfersQuantity;

  /// No description provided for @transfersAddItem.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get transfersAddItem;

  /// No description provided for @transfersExecuting.
  ///
  /// In pt, this message translates to:
  /// **'A transferir...'**
  String get transfersExecuting;

  /// No description provided for @transfersExecute.
  ///
  /// In pt, this message translates to:
  /// **'Executar Transferência'**
  String get transfersExecute;

  /// No description provided for @transfersNoStoresTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre pelo menos 2 lojas'**
  String get transfersNoStoresTitle;

  /// No description provided for @transfersNoStoresSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'É necessário ter 2+ lojas para\ntransferir estoque entre elas'**
  String get transfersNoStoresSubtitle;

  /// No description provided for @transfersSuccess.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 produto transferido} other{{count} produtos transferidos}} com sucesso'**
  String transfersSuccess(num count);

  /// No description provided for @transfersError.
  ///
  /// In pt, this message translates to:
  /// **'Erro na transferência: {error}'**
  String transfersError(Object error);

  /// No description provided for @transferStatusPending.
  ///
  /// In pt, this message translates to:
  /// **'Pendente'**
  String get transferStatusPending;

  /// No description provided for @transferStatusInTransit.
  ///
  /// In pt, this message translates to:
  /// **'Em Trânsito'**
  String get transferStatusInTransit;

  /// No description provided for @transferStatusReceived.
  ///
  /// In pt, this message translates to:
  /// **'Recebida'**
  String get transferStatusReceived;

  /// No description provided for @transferStatusCancelled.
  ///
  /// In pt, this message translates to:
  /// **'Cancelada'**
  String get transferStatusCancelled;

  /// No description provided for @paymentsTitle.
  ///
  /// In pt, this message translates to:
  /// **'M-Pesa / E-Mola'**
  String get paymentsTitle;

  /// No description provided for @paymentsIntegrationBlocked.
  ///
  /// In pt, this message translates to:
  /// **'Integração M-Pesa/E-Mola ainda não configurada — a reconciliação real exige a API do provedor. Até lá, os dados apresentados aqui são locais e demonstrativos.'**
  String get paymentsIntegrationBlocked;

  /// No description provided for @reportsAdvancedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios Avançados'**
  String get reportsAdvancedTitle;

  /// No description provided for @reportsTabSales.
  ///
  /// In pt, this message translates to:
  /// **'Vendas'**
  String get reportsTabSales;

  /// No description provided for @reportsTabFinancial.
  ///
  /// In pt, this message translates to:
  /// **'Financeiro'**
  String get reportsTabFinancial;

  /// No description provided for @reportsTabStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque'**
  String get reportsTabStock;

  /// No description provided for @reportsKpiProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get reportsKpiProducts;

  /// No description provided for @reportsKpiLowStock.
  ///
  /// In pt, this message translates to:
  /// **'Estoque Baixo'**
  String get reportsKpiLowStock;

  /// No description provided for @reportsKpiTotalItems.
  ///
  /// In pt, this message translates to:
  /// **'Total Itens'**
  String get reportsKpiTotalItems;

  /// No description provided for @reportsKpiStockValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor Estoque'**
  String get reportsKpiStockValue;

  /// No description provided for @reportsKpiRevenue.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get reportsKpiRevenue;

  /// No description provided for @reportsKpiExpenses.
  ///
  /// In pt, this message translates to:
  /// **'Despesas'**
  String get reportsKpiExpenses;

  /// No description provided for @reportsKpiNetProfit.
  ///
  /// In pt, this message translates to:
  /// **'Lucro Líquido'**
  String get reportsKpiNetProfit;

  /// No description provided for @reportsStockByQty.
  ///
  /// In pt, this message translates to:
  /// **'Produtos por Estoque'**
  String get reportsStockByQty;

  /// No description provided for @reportsCashFlow.
  ///
  /// In pt, this message translates to:
  /// **'Fluxo de Caixa'**
  String get reportsCashFlow;

  /// No description provided for @reportsCashFlowChart.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de fluxo de caixa'**
  String get reportsCashFlowChart;

  /// No description provided for @reportsNoProducts.
  ///
  /// In pt, this message translates to:
  /// **'Sem produtos cadastrados'**
  String get reportsNoProducts;

  /// No description provided for @reportsStockHealthy.
  ///
  /// In pt, this message translates to:
  /// **'Todos os produtos com estoque adequado'**
  String get reportsStockHealthy;

  /// No description provided for @reportsExportSales.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Relatório (PDF)'**
  String get reportsExportSales;

  /// No description provided for @reportsExportFinancial.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Financeiro (PDF)'**
  String get reportsExportFinancial;

  /// No description provided for @reportsExportStock.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Estoque (PDF)'**
  String get reportsExportStock;

  /// No description provided for @reportsNoSalesData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados para este período'**
  String get reportsNoSalesData;

  /// No description provided for @reportsPeriodYear.
  ///
  /// In pt, this message translates to:
  /// **'Este Ano'**
  String get reportsPeriodYear;

  /// No description provided for @reportsKpiStockOut.
  ///
  /// In pt, this message translates to:
  /// **'Sem Estoque'**
  String get reportsKpiStockOut;

  /// No description provided for @reportsKpiTotalProducts.
  ///
  /// In pt, this message translates to:
  /// **'Total Produtos'**
  String get reportsKpiTotalProducts;

  /// No description provided for @pdfGeneratedOn.
  ///
  /// In pt, this message translates to:
  /// **'Gerado: {date}'**
  String pdfGeneratedOn(Object date);

  /// No description provided for @pdfIndicators.
  ///
  /// In pt, this message translates to:
  /// **'Indicadores'**
  String get pdfIndicators;

  /// No description provided for @pdfFooter.
  ///
  /// In pt, this message translates to:
  /// **'Documento gerado pelo TAREQO — {date}'**
  String pdfFooter(Object date);

  /// No description provided for @pdfInvoiceDocWord.
  ///
  /// In pt, this message translates to:
  /// **'FACTURA'**
  String get pdfInvoiceDocWord;

  /// No description provided for @pdfInvoiceSubjectWord.
  ///
  /// In pt, this message translates to:
  /// **'Factura'**
  String get pdfInvoiceSubjectWord;

  /// No description provided for @pdfInvoiceFileBase.
  ///
  /// In pt, this message translates to:
  /// **'factura'**
  String get pdfInvoiceFileBase;

  /// No description provided for @pdfQuotationDocWord.
  ///
  /// In pt, this message translates to:
  /// **'COTAÇÃO'**
  String get pdfQuotationDocWord;

  /// No description provided for @pdfQuotationSubjectWord.
  ///
  /// In pt, this message translates to:
  /// **'Cotação'**
  String get pdfQuotationSubjectWord;

  /// No description provided for @pdfQuotationFileBase.
  ///
  /// In pt, this message translates to:
  /// **'cotacao'**
  String get pdfQuotationFileBase;

  /// No description provided for @pdfClientHeading.
  ///
  /// In pt, this message translates to:
  /// **'CLIENTE'**
  String get pdfClientHeading;

  /// No description provided for @pdfPhoneLine.
  ///
  /// In pt, this message translates to:
  /// **'Tel: {value}'**
  String pdfPhoneLine(Object value);

  /// No description provided for @pdfEmailLine.
  ///
  /// In pt, this message translates to:
  /// **'Email: {value}'**
  String pdfEmailLine(Object value);

  /// No description provided for @pdfNifLine.
  ///
  /// In pt, this message translates to:
  /// **'NIF: {value}'**
  String pdfNifLine(Object value);

  /// No description provided for @pdfItemHeader.
  ///
  /// In pt, this message translates to:
  /// **'Item'**
  String get pdfItemHeader;

  /// No description provided for @pdfUnitPriceHeader.
  ///
  /// In pt, this message translates to:
  /// **'Preço Unit.'**
  String get pdfUnitPriceHeader;

  /// No description provided for @pdfSubtotalHeader.
  ///
  /// In pt, this message translates to:
  /// **'Subtotal'**
  String get pdfSubtotalHeader;

  /// No description provided for @pdfDiscountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desconto'**
  String get pdfDiscountLabel;

  /// No description provided for @pdfTaxLabel.
  ///
  /// In pt, this message translates to:
  /// **'IVA'**
  String get pdfTaxLabel;

  /// No description provided for @pdfPaymentLine.
  ///
  /// In pt, this message translates to:
  /// **'Pagamento: {value}'**
  String pdfPaymentLine(Object value);

  /// No description provided for @pdfReferenceLine.
  ///
  /// In pt, this message translates to:
  /// **'Ref: {value}'**
  String pdfReferenceLine(Object value);

  /// No description provided for @pdfNotesHeading.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get pdfNotesHeading;

  /// No description provided for @pdfGeneralConditionsHeading.
  ///
  /// In pt, this message translates to:
  /// **'Condições Gerais'**
  String get pdfGeneralConditionsHeading;

  /// No description provided for @pdfValidityDaysLeft.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{1 dia restante} other{{days} dias restantes}}'**
  String pdfValidityDaysLeft(num days);

  /// No description provided for @pdfConditionValidBullet.
  ///
  /// In pt, this message translates to:
  /// **'Esta cotação é válida até {date}.'**
  String pdfConditionValidBullet(Object date);

  /// No description provided for @pdfConditionPricesBullet.
  ///
  /// In pt, this message translates to:
  /// **'Preços sujeitos a alteração após o prazo de validade.'**
  String get pdfConditionPricesBullet;

  /// No description provided for @pdfConditionContactBullet.
  ///
  /// In pt, this message translates to:
  /// **'Para aceitar esta cotação, entre em contacto connosco.'**
  String get pdfConditionContactBullet;

  /// No description provided for @quotationStatusExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirada'**
  String get quotationStatusExpired;

  /// No description provided for @quotationStatusConverted.
  ///
  /// In pt, this message translates to:
  /// **'Convertida em Venda'**
  String get quotationStatusConverted;

  /// No description provided for @pdfConditionsNotesHeading.
  ///
  /// In pt, this message translates to:
  /// **'Condições / Notas'**
  String get pdfConditionsNotesHeading;

  /// No description provided for @adminAddonsActivateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Activar'**
  String get adminAddonsActivateBtn;

  /// No description provided for @adminAddonsActivateBulk.
  ///
  /// In pt, this message translates to:
  /// **'Activar add-on'**
  String get adminAddonsActivateBulk;

  /// No description provided for @adminAddonsActivePill.
  ///
  /// In pt, this message translates to:
  /// **'Activos'**
  String get adminAddonsActivePill;

  /// No description provided for @adminAddonsDeactivateBtn.
  ///
  /// In pt, this message translates to:
  /// **'Desactivar'**
  String get adminAddonsDeactivateBtn;

  /// No description provided for @adminAddonsInactivePill.
  ///
  /// In pt, this message translates to:
  /// **'Inactivos'**
  String get adminAddonsInactivePill;

  /// No description provided for @adminAddonsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Erro: {error}'**
  String adminAddonsLoadError(Object error);

  /// No description provided for @adminAddonsNoTenantsSearchSub.
  ///
  /// In pt, this message translates to:
  /// **'Tente outro termo de busca'**
  String get adminAddonsNoTenantsSearchSub;

  /// No description provided for @adminAddonsNoTenantsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum tenant encontrado'**
  String get adminAddonsNoTenantsTitle;

  /// No description provided for @adminAddonsNoTenantsYetSub.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum tenant aprovado ainda'**
  String get adminAddonsNoTenantsYetSub;

  /// No description provided for @adminAddonsUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao actualizar add-on: {error}'**
  String adminAddonsUpdateError(Object error);

  /// No description provided for @adminBackToList.
  ///
  /// In pt, this message translates to:
  /// **'Voltar à lista'**
  String get adminBackToList;

  /// No description provided for @adminMessagesBodyHint.
  ///
  /// In pt, this message translates to:
  /// **'Escreva a mensagem…'**
  String get adminMessagesBodyHint;

  /// No description provided for @adminMessagesTenantHint.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar tenant...'**
  String get adminMessagesTenantHint;

  /// No description provided for @adminMessagesTitleExample.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Cotação de Plano Pro'**
  String get adminMessagesTitleExample;

  /// No description provided for @adminNavRevenue.
  ///
  /// In pt, this message translates to:
  /// **'Receitas'**
  String get adminNavRevenue;

  /// No description provided for @adminPlansActive.
  ///
  /// In pt, this message translates to:
  /// **'Activos'**
  String get adminPlansActive;

  /// No description provided for @adminPlansInactive.
  ///
  /// In pt, this message translates to:
  /// **'Inactivos'**
  String get adminPlansInactive;

  /// No description provided for @adminRevenueActiveTenants.
  ///
  /// In pt, this message translates to:
  /// **'Tenants Activos'**
  String get adminRevenueActiveTenants;

  /// No description provided for @adminRevenueActiveTenantsSub.
  ///
  /// In pt, this message translates to:
  /// **'Total na plataforma'**
  String get adminRevenueActiveTenantsSub;

  /// No description provided for @adminRevenueAvailableAddOns.
  ///
  /// In pt, this message translates to:
  /// **'Add-ons Disponíveis'**
  String get adminRevenueAvailableAddOns;

  /// No description provided for @adminRevenueAvailableAddOnsSub.
  ///
  /// In pt, this message translates to:
  /// **'No catálogo activo'**
  String get adminRevenueAvailableAddOnsSub;

  /// No description provided for @adminRevenueMaxMonthly.
  ///
  /// In pt, this message translates to:
  /// **'Receita mensal máxima'**
  String get adminRevenueMaxMonthly;

  /// No description provided for @adminRevenueMaxMonthlySub.
  ///
  /// In pt, this message translates to:
  /// **'Se todos activassem todos'**
  String get adminRevenueMaxMonthlySub;

  /// No description provided for @adminRevenuePotential.
  ///
  /// In pt, this message translates to:
  /// **'Receita Potencial'**
  String get adminRevenuePotential;

  /// No description provided for @adminRevenuePotentialSub.
  ///
  /// In pt, this message translates to:
  /// **'Por tenant/mês (todos os add-ons)'**
  String get adminRevenuePotentialSub;

  /// No description provided for @adminTenantsMonthlyValue.
  ///
  /// In pt, this message translates to:
  /// **'Valor mensal'**
  String get adminTenantsMonthlyValue;

  /// No description provided for @adminTenantsNextInvoice.
  ///
  /// In pt, this message translates to:
  /// **'Próxima factura'**
  String get adminTenantsNextInvoice;

  /// No description provided for @adminTenantsPlanExpiresOn.
  ///
  /// In pt, this message translates to:
  /// **'Plano expira em'**
  String get adminTenantsPlanExpiresOn;

  /// No description provided for @adminTenantsTrialEndsOn.
  ///
  /// In pt, this message translates to:
  /// **'Trial termina em'**
  String get adminTenantsTrialEndsOn;

  /// No description provided for @commonId.
  ///
  /// In pt, this message translates to:
  /// **'ID'**
  String get commonId;

  /// No description provided for @dashboardSaleEntry.
  ///
  /// In pt, this message translates to:
  /// **'Venda {number}'**
  String dashboardSaleEntry(Object number);

  /// No description provided for @loginConfirmPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Repita a senha'**
  String get loginConfirmPasswordHint;

  /// No description provided for @loginConfirmPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get loginConfirmPasswordLabel;

  /// No description provided for @loginEmailHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu email'**
  String get loginEmailHint;

  /// No description provided for @loginForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueceu sua senha?'**
  String get loginForgotPassword;

  /// No description provided for @loginNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite seu nome'**
  String get loginNameHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite sua senha'**
  String get loginPasswordHint;

  /// No description provided for @loginPromptHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get loginPromptHaveAccount;

  /// No description provided for @loginPromptNoAccount.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tem uma conta?'**
  String get loginPromptNoAccount;

  /// No description provided for @loginTagline.
  ///
  /// In pt, this message translates to:
  /// **'Gestão simples para o seu negócio'**
  String get loginTagline;

  /// No description provided for @loginSecurityFooter.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados são protegidos com criptografia.'**
  String get loginSecurityFooter;

  /// No description provided for @mfaCodeFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código MFA'**
  String get mfaCodeFieldLabel;

  /// No description provided for @mfaCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código de 6 dígitos do seu aplicativo autenticador:'**
  String get mfaCodeHint;

  /// No description provided for @mfaCodeLengthError.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código de 6 dígitos'**
  String get mfaCodeLengthError;

  /// No description provided for @mfaConfirmPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código do aplicativo para confirmar:'**
  String get mfaConfirmPrompt;

  /// No description provided for @mfaDigitsFieldLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de 6 dígitos'**
  String get mfaDigitsFieldLabel;

  /// No description provided for @mfaExpiresIn.
  ///
  /// In pt, this message translates to:
  /// **'Código expira em {seconds, plural, =1{1 segundo} other{{seconds} segundos}}'**
  String mfaExpiresIn(num seconds);

  /// No description provided for @mfaInitError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao inicializar MFA: {error}'**
  String mfaInitError(Object error);

  /// No description provided for @mfaInvalidCode.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido. Tente novamente.'**
  String get mfaInvalidCode;

  /// No description provided for @mfaManualEntryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ou digite este código manualmente:'**
  String get mfaManualEntryTitle;

  /// No description provided for @mfaQrScanHelp.
  ///
  /// In pt, this message translates to:
  /// **'Use seu aplicativo autenticador (Google Authenticator, Authy, etc.) para escanear este código QR:'**
  String get mfaQrScanHelp;

  /// No description provided for @mfaQrScanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escaneie o QR Code'**
  String get mfaQrScanTitle;

  /// No description provided for @mfaSetupSuccess.
  ///
  /// In pt, this message translates to:
  /// **'MFA configurado com sucesso!'**
  String get mfaSetupSuccess;

  /// No description provided for @mfaSetupTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurar Autenticação em Dois Fatores'**
  String get mfaSetupTitle;

  /// No description provided for @mfaVerify.
  ///
  /// In pt, this message translates to:
  /// **'Verificar'**
  String get mfaVerify;

  /// No description provided for @mfaVerifyAndEnable.
  ///
  /// In pt, this message translates to:
  /// **'Verificar e Activar'**
  String get mfaVerifyAndEnable;

  /// No description provided for @mfaVerifyError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao verificar código: {error}'**
  String mfaVerifyError(Object error);

  /// No description provided for @securityBiometricDisabledSub.
  ///
  /// In pt, this message translates to:
  /// **'Use impressão digital ou reconhecimento facial'**
  String get securityBiometricDisabledSub;

  /// No description provided for @securityBiometricEnabledSub.
  ///
  /// In pt, this message translates to:
  /// **'Activada — Impressão digital ou rosto'**
  String get securityBiometricEnabledSub;

  /// No description provided for @securityBiometricTitle.
  ///
  /// In pt, this message translates to:
  /// **'Autenticação Biométrica'**
  String get securityBiometricTitle;

  /// No description provided for @securityBiometricUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Não disponível neste dispositivo'**
  String get securityBiometricUnavailable;

  /// No description provided for @securityTwoFactorDisabledSub.
  ///
  /// In pt, this message translates to:
  /// **'Adicione uma camada extra de segurança'**
  String get securityTwoFactorDisabledSub;

  /// No description provided for @securityTwoFactorEnabledSub.
  ///
  /// In pt, this message translates to:
  /// **'Activada — Use um app autenticador'**
  String get securityTwoFactorEnabledSub;

  /// No description provided for @securityTwoFactorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Autenticação em Dois Fatores'**
  String get securityTwoFactorTitle;

  /// No description provided for @settingsHapticsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Feedback tátil'**
  String get settingsHapticsTitle;

  /// No description provided for @settingsHapticsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Vibração ao concluir vendas, pagamentos e confirmações'**
  String get settingsHapticsSubtitle;

  /// No description provided for @settingsMfaEnforceError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar a exigência de MFA. Verifique a conexão e tente de novo.'**
  String get settingsMfaEnforceError;

  /// No description provided for @settingsMfaEnforceSubOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligado — vendas e caixa funcionam só com senha'**
  String get settingsMfaEnforceSubOff;

  /// No description provided for @settingsMfaEnforceSubOn.
  ///
  /// In pt, this message translates to:
  /// **'Exigido — escritas de dinheiro pedem código do autenticador'**
  String get settingsMfaEnforceSubOn;

  /// No description provided for @settingsMfaEnforceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Exigir MFA para operações de dinheiro'**
  String get settingsMfaEnforceTitle;

  /// No description provided for @transfersRowDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get transfersRowDate;

  /// No description provided for @transfersRowDest.
  ///
  /// In pt, this message translates to:
  /// **'Destino'**
  String get transfersRowDest;

  /// No description provided for @transfersRowOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Origem'**
  String get transfersRowOrigin;

  /// No description provided for @transfersRowStatus.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get transfersRowStatus;

  /// No description provided for @adminAddonsBulkActivated.
  ///
  /// In pt, this message translates to:
  /// **'{addonName} activado em {count, plural, =1{1 tenant} other{{count} tenants}}'**
  String adminAddonsBulkActivated(Object addonName, num count);

  /// No description provided for @adminAddonsBulkDeactivated.
  ///
  /// In pt, this message translates to:
  /// **'{addonName} desactivado em {count, plural, =1{1 tenant} other{{count} tenants}}'**
  String adminAddonsBulkDeactivated(Object addonName, num count);

  /// No description provided for @adminAddonsBulkSheetCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 tenant selecionado} other{{count} tenants selecionados}}'**
  String adminAddonsBulkSheetCount(num count);

  /// No description provided for @adminAddonsBulkSheetTitle.
  ///
  /// In pt, this message translates to:
  /// **'Activar add-on em lote'**
  String get adminAddonsBulkSheetTitle;

  /// No description provided for @adminAddonsEditPriceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar preço mensal'**
  String get adminAddonsEditPriceTitle;

  /// No description provided for @adminAddonsEditPriceTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Editar preço'**
  String get adminAddonsEditPriceTooltip;

  /// No description provided for @adminAddonsPriceUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Preço de {addonName} actualizado para {price}/mês'**
  String adminAddonsPriceUpdated(Object addonName, Object price);

  /// No description provided for @adminAddonsPriceSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar o preço. Tente novamente.'**
  String get adminAddonsPriceSaveError;

  /// No description provided for @adminAddonsListHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque num tenant para gerir os seus add-ons. Toque no ícone ✓ para seleção múltipla.'**
  String get adminAddonsListHint;

  /// No description provided for @adminAddOnsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 add-on} other{{count} add-ons}}'**
  String adminAddOnsCount(num count);

  /// No description provided for @adminRevenueByAddOn.
  ///
  /// In pt, this message translates to:
  /// **'Receita por Add-on'**
  String get adminRevenueByAddOn;

  /// No description provided for @adminRevenueByCategory.
  ///
  /// In pt, this message translates to:
  /// **'Distribuição por Categoria'**
  String get adminRevenueByCategory;

  /// No description provided for @adminRevenuePerMonth.
  ///
  /// In pt, this message translates to:
  /// **'potencial/mês'**
  String get adminRevenuePerMonth;

  /// No description provided for @adminPlanPerMonthSuffix.
  ///
  /// In pt, this message translates to:
  /// **'/mês'**
  String get adminPlanPerMonthSuffix;

  /// No description provided for @adminTenantCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 tenant} other{{count} tenants}}'**
  String adminTenantCount(num count);

  /// No description provided for @adminTenantCycleActiveLeft.
  ///
  /// In pt, this message translates to:
  /// **'Activo: {days, plural, =1{1 dia restante} other{{days} dias restantes}}'**
  String adminTenantCycleActiveLeft(num days);

  /// No description provided for @adminTenantCycleExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get adminTenantCycleExpired;

  /// No description provided for @adminTenantCycleExpiresIn.
  ///
  /// In pt, this message translates to:
  /// **'Expira em {days, plural, =1{1 dia} other{{days} dias}}'**
  String adminTenantCycleExpiresIn(num days);

  /// No description provided for @adminTenantCycleTrialLeft.
  ///
  /// In pt, this message translates to:
  /// **'Trial: {days, plural, =1{1 dia restante} other{{days} dias restantes}}'**
  String adminTenantCycleTrialLeft(num days);
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
