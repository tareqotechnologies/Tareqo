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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Dumbhanengue ERP'**
  String get appTitle;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get onboardingTitle;

  /// No description provided for @onboardingHeading.
  ///
  /// In en, this message translates to:
  /// **'Set up your business'**
  String get onboardingHeading;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan, name and currency. Approval within 24h.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingBusinessLabel.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get onboardingBusinessLabel;

  /// No description provided for @onboardingBusinessError.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name.'**
  String get onboardingBusinessError;

  /// No description provided for @onboardingPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get onboardingPlanLabel;

  /// No description provided for @onboardingPlansError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the plans.'**
  String get onboardingPlansError;

  /// Plan limits summary
  ///
  /// In en, this message translates to:
  /// **'{stores} store(s) · {employees} employee(s)'**
  String onboardingPlanDetails(int stores, int employees);

  /// No description provided for @onboardingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get onboardingSubmit;

  /// Feedback after requesting access
  ///
  /// In en, this message translates to:
  /// **'Request for {business} sent! Wait for approval (within 24h).'**
  String onboardingSuccess(String business);

  /// No description provided for @onboardingChoosePlanError.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to continue.'**
  String get onboardingChoosePlanError;

  /// No description provided for @onboardingGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the request. Try again.'**
  String get onboardingGenericError;

  /// No description provided for @onboardingLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onboardingLanguageLabel;

  /// No description provided for @onboardingLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get onboardingLanguageHint;

  /// No description provided for @onboardingCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get onboardingCurrencyLabel;

  /// No description provided for @onboardingCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Currency used for amounts'**
  String get onboardingCurrencyHint;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @currencyBrl.
  ///
  /// In en, this message translates to:
  /// **'Brazilian Real (BRL)'**
  String get currencyBrl;

  /// No description provided for @currencyUsd.
  ///
  /// In en, this message translates to:
  /// **'US Dollar (USD)'**
  String get currencyUsd;

  /// No description provided for @currencyEur.
  ///
  /// In en, this message translates to:
  /// **'Euro (EUR)'**
  String get currencyEur;

  /// No description provided for @currencyMzn.
  ///
  /// In en, this message translates to:
  /// **'Mozambican Metical (MZN)'**
  String get currencyMzn;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved!'**
  String get settingsSaved;

  /// No description provided for @settingsGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. Try again.'**
  String get settingsGenericError;

  /// No description provided for @settingsSupportSection.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupportSection;

  /// No description provided for @settingsSupportEntry.
  ///
  /// In en, this message translates to:
  /// **'Help and documentation'**
  String get settingsSupportEntry;

  /// No description provided for @settingsSupportEntryHint.
  ///
  /// In en, this message translates to:
  /// **'User Guide and Troubleshooting — offline'**
  String get settingsSupportEntryHint;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get supportTitle;

  /// No description provided for @supportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'User guide and troubleshooting.'**
  String get supportSubtitle;

  /// No description provided for @supportUserGuide.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get supportUserGuide;

  /// No description provided for @supportUserGuideHint.
  ///
  /// In en, this message translates to:
  /// **'Sign-in, stores, products, sales, credit, finance and reports'**
  String get supportUserGuideHint;

  /// No description provided for @supportTroubleshooting.
  ///
  /// In en, this message translates to:
  /// **'Troubleshooting'**
  String get supportTroubleshooting;

  /// No description provided for @supportTroubleshootingHint.
  ///
  /// In en, this message translates to:
  /// **'Common issues: sign-in, sales, stock and connection'**
  String get supportTroubleshootingHint;

  /// No description provided for @supportReadingError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the document.'**
  String get supportReadingError;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get commonSearch;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonSignOut;

  /// No description provided for @appSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get appSheetClose;

  /// No description provided for @storeSwitcherTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch store'**
  String get storeSwitcherTooltip;

  /// No description provided for @storeSelectorSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Active store'**
  String get storeSelectorSectionTitle;

  /// No description provided for @storeSelectorSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the active store.'**
  String get storeSelectorSectionHint;

  /// No description provided for @tenantPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get tenantPendingTitle;

  /// No description provided for @tenantPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request for \"{business}\" sent. Wait up to 24h.'**
  String tenantPendingSubtitle(String business);

  /// No description provided for @tenantPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Once approved, create stores and start operating.'**
  String get tenantPendingHint;

  /// No description provided for @tenantRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get tenantRejectedTitle;

  /// No description provided for @tenantRejectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The request for \"{business}\" was not approved.'**
  String tenantRejectedSubtitle(String business);

  /// No description provided for @authBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access suspended'**
  String get authBlockedTitle;

  /// No description provided for @authBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account was deactivated by the owner.'**
  String get authBlockedMessage;

  /// No description provided for @authBlockedSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authBlockedSignOut;

  /// No description provided for @authErrorRestoreSession.
  ///
  /// In en, this message translates to:
  /// **'Session not restored'**
  String get authErrorRestoreSession;

  /// No description provided for @authErrorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get authErrorCheckConnection;

  /// No description provided for @authErrorLoadAccount.
  ///
  /// In en, this message translates to:
  /// **'Account not loaded'**
  String get authErrorLoadAccount;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Opening your session…'**
  String get splashLoading;

  /// No description provided for @loginSubtitleSignUp.
  ///
  /// In en, this message translates to:
  /// **'Create your account to get started'**
  String get loginSubtitleSignUp;

  /// No description provided for @loginSubtitleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Simple management for your business'**
  String get loginSubtitleSignIn;

  /// No description provided for @loginNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get loginNameLabel;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get loginEmailError;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get loginPasswordError;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters with lowercase, uppercase, number and symbol.'**
  String get loginPasswordHint;

  /// No description provided for @loginWeakPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Password must include letters, numbers and symbols.'**
  String get loginWeakPasswordError;

  /// No description provided for @loginRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait 1 hour and try again.'**
  String get loginRateLimitError;

  /// No description provided for @loginShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get loginShowPassword;

  /// No description provided for @loginHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get loginHidePassword;

  /// No description provided for @loginConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get loginConfirmLabel;

  /// No description provided for @loginConfirmError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get loginConfirmError;

  /// No description provided for @loginSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get loginSignUp;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginSignIn;

  /// No description provided for @loginSwitchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account — sign in'**
  String get loginSwitchToSignIn;

  /// No description provided for @loginSwitchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'No account yet — sign up'**
  String get loginSwitchToSignUp;

  /// No description provided for @loginSignUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created! Confirm your email to sign in.'**
  String get loginSignUpSuccess;

  /// No description provided for @loginSignUpError.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account. Try again.'**
  String get loginSignUpError;

  /// No description provided for @loginSignInError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your email and password.'**
  String get loginSignInError;

  /// No description provided for @loginSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Data protected with encryption.'**
  String get loginSecurityNote;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get loginForgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email. We\'ll send a reset link.'**
  String get forgotPasswordHint;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists, we\'ve sent a link.'**
  String get forgotPasswordSent;

  /// No description provided for @forgotPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the link. Try again.'**
  String get forgotPasswordError;

  /// No description provided for @setNewPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get setNewPasswordTitle;

  /// No description provided for @setNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters with lowercase, uppercase, number and symbol.'**
  String get setNewPasswordHint;

  /// No description provided for @setNewPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get setNewPasswordSubmit;

  /// No description provided for @setNewPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated!'**
  String get setNewPasswordSuccess;

  /// No description provided for @setNewPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the password. Try again.'**
  String get setNewPasswordError;

  /// No description provided for @setNewPasswordSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get setNewPasswordSignOut;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get changePasswordSuccess;

  /// No description provided for @changePasswordWrongCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect. Try again.'**
  String get changePasswordWrongCurrent;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordError.
  ///
  /// In en, this message translates to:
  /// **'Could not change the password. Try again.'**
  String get changePasswordError;

  /// No description provided for @securitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securitySectionTitle;

  /// No description provided for @securityChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get securityChangePassword;

  /// No description provided for @securityChangePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get securityChangePasswordHint;

  /// No description provided for @appNavHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get appNavHome;

  /// No description provided for @appNavSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get appNavSales;

  /// No description provided for @appNavWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get appNavWallet;

  /// No description provided for @appNavMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get appNavMenu;

  /// No description provided for @appNavProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get appNavProducts;

  /// No description provided for @appNavFinancial.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get appNavFinancial;

  /// No description provided for @appNavCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get appNavCredit;

  /// No description provided for @appNavCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get appNavCustomers;

  /// No description provided for @fabMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'New action'**
  String get fabMenuTitle;

  /// No description provided for @fabMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get fabMenuSubtitle;

  /// No description provided for @menuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an area to continue'**
  String get menuSubtitle;

  /// No description provided for @commonSignOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get commonSignOutConfirmTitle;

  /// No description provided for @commonSignOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will sign out of your account on this device.'**
  String get commonSignOutConfirmMessage;

  /// No description provided for @fabMenuNewSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get fabMenuNewSale;

  /// No description provided for @fabMenuNewSaleHint.
  ///
  /// In en, this message translates to:
  /// **'Cart · stock deduction · cash'**
  String get fabMenuNewSaleHint;

  /// No description provided for @fabMenuExpense.
  ///
  /// In en, this message translates to:
  /// **'Register expense'**
  String get fabMenuExpense;

  /// No description provided for @fabMenuExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'Cash outflow with category'**
  String get fabMenuExpenseHint;

  /// No description provided for @fabMenuAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get fabMenuAddProduct;

  /// No description provided for @fabMenuAddProductHint.
  ///
  /// In en, this message translates to:
  /// **'Catalog · price · initial stock'**
  String get fabMenuAddProductHint;

  /// No description provided for @fabMenuAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Register credit'**
  String get fabMenuAddDebt;

  /// No description provided for @fabMenuAddDebtHint.
  ///
  /// In en, this message translates to:
  /// **'Receivable or payable'**
  String get fabMenuAddDebtHint;

  /// No description provided for @fabMenuAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get fabMenuAddCustomer;

  /// No description provided for @fabMenuAddCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Contacts · linked credit'**
  String get fabMenuAddCustomerHint;

  /// No description provided for @fabMenuCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fabMenuCancel;

  /// No description provided for @syncPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 operation awaiting sync} other{{count} operations awaiting sync}}'**
  String syncPendingCount(int count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncOfflineSaved.
  ///
  /// In en, this message translates to:
  /// **'No connection. Saved — will sync automatically.'**
  String get syncOfflineSaved;

  /// No description provided for @syncDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 operation synced} other{{count} operations synced}}'**
  String syncDone(int count);

  /// No description provided for @syncStillOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection — operations pending.'**
  String get syncStillOffline;

  /// No description provided for @dashboardGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String dashboardGreeting(String name);

  /// No description provided for @dashboardSignOutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get dashboardSignOutTooltip;

  /// No description provided for @dashboardOwnerFallback.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get dashboardOwnerFallback;

  /// No description provided for @dashboardTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get dashboardTotalSales;

  /// No description provided for @dashboardAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get dashboardAllTime;

  /// No description provided for @dashboardCashBalance.
  ///
  /// In en, this message translates to:
  /// **'Cash balance'**
  String get dashboardCashBalance;

  /// No description provided for @dashboardReceivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables (credit)'**
  String get dashboardReceivables;

  /// No description provided for @dashboardStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock in products'**
  String get dashboardStockLabel;

  /// No description provided for @commonUnits.
  ///
  /// In en, this message translates to:
  /// **'u.'**
  String get commonUnits;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardQuickNewSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get dashboardQuickNewSale;

  /// No description provided for @dashboardQuickAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get dashboardQuickAddProduct;

  /// No description provided for @dashboardQuickAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get dashboardQuickAddTransaction;

  /// No description provided for @dashboardQuickAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Add credit'**
  String get dashboardQuickAddDebt;

  /// No description provided for @dashboardModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get dashboardModules;

  /// No description provided for @dashboardModuleCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get dashboardModuleCustomers;

  /// No description provided for @dashboardModulePurchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get dashboardModulePurchases;

  /// No description provided for @dashboardModuleReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get dashboardModuleReports;

  /// No description provided for @dashboardModuleStores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get dashboardModuleStores;

  /// No description provided for @dashboardRecentSales.
  ///
  /// In en, this message translates to:
  /// **'Recent sales'**
  String get dashboardRecentSales;

  /// No description provided for @dashboardViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardViewAll;

  /// No description provided for @dashboardNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales yet — record your first one!'**
  String get dashboardNoSales;

  /// No description provided for @dashboardRecentPurchases.
  ///
  /// In en, this message translates to:
  /// **'Recent purchases'**
  String get dashboardRecentPurchases;

  /// No description provided for @dashboardNoPurchases.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet — record your first one!'**
  String get dashboardNoPurchases;

  /// No description provided for @dashboardLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get dashboardLowStock;

  /// No description provided for @dashboardKpisError.
  ///
  /// In en, this message translates to:
  /// **'Could not load indicators.'**
  String get dashboardKpisError;

  /// No description provided for @dashboardActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s activity'**
  String get dashboardActivityTitle;

  /// No description provided for @dashboardActivityEvents.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String dashboardActivityEvents(num count);

  /// No description provided for @dashboardActivityMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String dashboardActivityMinutesAgo(Object count);

  /// No description provided for @dashboardActivityHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String dashboardActivityHoursAgo(Object count);

  /// No description provided for @dashboardDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardDateToday;

  /// No description provided for @dashboardMetricSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get dashboardMetricSales;

  /// No description provided for @dashboardMetricCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get dashboardMetricCash;

  /// No description provided for @dashboardMetricReceivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get dashboardMetricReceivables;

  /// No description provided for @dashboardFiadoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 tab} other{{count} tabs}}'**
  String dashboardFiadoCount(int count);

  /// No description provided for @dashboardActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet.'**
  String get dashboardActivityEmpty;

  /// No description provided for @dashboardActivitySeeAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dashboardActivitySeeAll;

  /// No description provided for @dashboardStockEntry.
  ///
  /// In en, this message translates to:
  /// **'Stock · {product}'**
  String dashboardStockEntry(String product);

  /// No description provided for @dashboardStockEntryDetail.
  ///
  /// In en, this message translates to:
  /// **'Inflow of {quantity} · {time}'**
  String dashboardStockEntryDetail(String quantity, String time);

  /// No description provided for @dashboardFiadoPayment.
  ///
  /// In en, this message translates to:
  /// **'Credit payment'**
  String get dashboardFiadoPayment;

  /// No description provided for @dashboardExpenseRow.
  ///
  /// In en, this message translates to:
  /// **'Expense · {description}'**
  String dashboardExpenseRow(String description);

  /// No description provided for @dashboardLowStockDetail.
  ///
  /// In en, this message translates to:
  /// **'{name} · {quantity} left'**
  String dashboardLowStockDetail(String name, String quantity);

  /// No description provided for @dashboardAlertBadge.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get dashboardAlertBadge;

  /// No description provided for @dashboardSaleItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String dashboardSaleItems(int count);

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @storesTitle.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get storesTitle;

  /// No description provided for @storesTabStores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get storesTabStores;

  /// No description provided for @storesTabEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get storesTabEmployees;

  /// No description provided for @storesTabUpgrades.
  ///
  /// In en, this message translates to:
  /// **'Upgrades'**
  String get storesTabUpgrades;

  /// No description provided for @storesTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get storesTabSettings;

  /// No description provided for @storesAddStore.
  ///
  /// In en, this message translates to:
  /// **'New store'**
  String get storesAddStore;

  /// No description provided for @storesAddEmployee.
  ///
  /// In en, this message translates to:
  /// **'New employee'**
  String get storesAddEmployee;

  /// No description provided for @storesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the stores.'**
  String get storesLoadError;

  /// No description provided for @storesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stores created'**
  String get storesEmptyTitle;

  /// No description provided for @storesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the first store of your business.'**
  String get storesEmptySubtitle;

  /// No description provided for @employeesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the employees.'**
  String get employeesLoadError;

  /// No description provided for @employeesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No employees linked'**
  String get employeesEmptyTitle;

  /// No description provided for @employeesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the employee account and pick a store.'**
  String get employeesEmptySubtitle;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @employeeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get employeeActive;

  /// No description provided for @employeeInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get employeeInactive;

  /// No description provided for @employeeDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}? Loses access immediately.'**
  String employeeDeactivateConfirm(Object name);

  /// No description provided for @employeeReactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reactivate {name}? Gets store access again.'**
  String employeeReactivateConfirm(Object name);

  /// No description provided for @employeeDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Employee deactivated.'**
  String get employeeDeactivated;

  /// No description provided for @employeeReactivated.
  ///
  /// In en, this message translates to:
  /// **'Employee reactivated.'**
  String get employeeReactivated;

  /// No description provided for @employeeDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get employeeDeactivateAction;

  /// No description provided for @employeeReactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get employeeReactivateAction;

  /// No description provided for @upgradesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the plan upgrade requests.'**
  String get upgradesLoadError;

  /// No description provided for @upgradesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No upgrade requests'**
  String get upgradesEmptyTitle;

  /// No description provided for @upgradesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request a bigger plan in the card above.'**
  String get upgradesEmptySubtitle;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @upgradesRequestedOn.
  ///
  /// In en, this message translates to:
  /// **'Requested on {date}'**
  String upgradesRequestedOn(String date);

  /// No description provided for @planCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planCardTitle;

  /// No description provided for @planCardUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get planCardUpgrade;

  /// No description provided for @planCardStores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get planCardStores;

  /// No description provided for @planCardEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get planCardEmployees;

  /// No description provided for @planDetails.
  ///
  /// In en, this message translates to:
  /// **'{stores} store(s) · {employees} employee(s)'**
  String planDetails(int stores, int employees);

  /// No description provided for @addStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'New store'**
  String get addStoreTitle;

  /// No description provided for @addStoreNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get addStoreNameLabel;

  /// No description provided for @addStoreNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the store name.'**
  String get addStoreNameError;

  /// No description provided for @addStoreAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address (optional)'**
  String get addStoreAddressLabel;

  /// No description provided for @addStoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Store {name} created!'**
  String addStoreSuccess(String name);

  /// No description provided for @addStoreError.
  ///
  /// In en, this message translates to:
  /// **'Could not create the store. Try again.'**
  String get addStoreError;

  /// No description provided for @addStoreSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create store'**
  String get addStoreSubmit;

  /// No description provided for @addEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'New employee'**
  String get addEmployeeTitle;

  /// No description provided for @addEmployeeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get addEmployeeNameLabel;

  /// No description provided for @addEmployeeNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the employee name.'**
  String get addEmployeeNameError;

  /// No description provided for @addEmployeeEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get addEmployeeEmailLabel;

  /// No description provided for @addEmployeeEmailError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get addEmployeeEmailError;

  /// No description provided for @addEmployeePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Access password'**
  String get addEmployeePasswordLabel;

  /// No description provided for @addEmployeePasswordError.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get addEmployeePasswordError;

  /// No description provided for @addEmployeeStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get addEmployeeStoreLabel;

  /// No description provided for @addEmployeeNoStores.
  ///
  /// In en, this message translates to:
  /// **'Create a store before adding employees.'**
  String get addEmployeeNoStores;

  /// No description provided for @addEmployeeRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get addEmployeeRoleLabel;

  /// No description provided for @addEmployeeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee registered! Access account created.'**
  String get addEmployeeSuccess;

  /// No description provided for @addEmployeeError.
  ///
  /// In en, this message translates to:
  /// **'Could not register. Check if the email is in use.'**
  String get addEmployeeError;

  /// No description provided for @addEmployeeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register employee'**
  String get addEmployeeSubmit;

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan upgrade'**
  String get upgradeTitle;

  /// No description provided for @upgradeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the new plan. Awaits super admin approval.'**
  String get upgradeSubtitle;

  /// No description provided for @upgradeMaxReached.
  ///
  /// In en, this message translates to:
  /// **'You are already on the highest plan.'**
  String get upgradeMaxReached;

  /// No description provided for @upgradeChooseError.
  ///
  /// In en, this message translates to:
  /// **'Choose the target plan.'**
  String get upgradeChooseError;

  /// No description provided for @upgradeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Upgrade request sent!'**
  String get upgradeSuccess;

  /// No description provided for @upgradeError.
  ///
  /// In en, this message translates to:
  /// **'Could not send the request. Try again.'**
  String get upgradeError;

  /// No description provided for @upgradeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Request upgrade'**
  String get upgradeSubmit;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get commonNoResults;

  /// No description provided for @commonNoResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try searching another term.'**
  String get commonNoResultsHint;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get commonSoldOut;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodMonth;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Debit card'**
  String get paymentDebitCard;

  /// No description provided for @paymentCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get paymentCreditCard;

  /// No description provided for @paymentEMola.
  ///
  /// In en, this message translates to:
  /// **'E-Mola'**
  String get paymentEMola;

  /// No description provided for @paymentMPesa.
  ///
  /// In en, this message translates to:
  /// **'M-Pesa'**
  String get paymentMPesa;

  /// No description provided for @paymentTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get paymentTransfer;

  /// No description provided for @purchasesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search purchases...'**
  String get purchasesSearchHint;

  /// No description provided for @productsFilterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get productsFilterTooltip;

  /// No description provided for @productsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productsFilterAll;

  /// No description provided for @productsFilterAllCount.
  ///
  /// In en, this message translates to:
  /// **'All · {count}'**
  String productsFilterAllCount(int count);

  /// No description provided for @productsFilterLowCount.
  ///
  /// In en, this message translates to:
  /// **'Low stock · {count}'**
  String productsFilterLowCount(int count);

  /// No description provided for @productsColProduct.
  ///
  /// In en, this message translates to:
  /// **'Product / SKU'**
  String get productsColProduct;

  /// No description provided for @productsColPrice.
  ///
  /// In en, this message translates to:
  /// **'Price · Stock'**
  String get productsColPrice;

  /// No description provided for @productsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search product...'**
  String get productsSearchHint;

  /// No description provided for @productsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the products.'**
  String get productsLoadError;

  /// No description provided for @productsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get productsEmptyTitle;

  /// No description provided for @productsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New product\" to get started.'**
  String get productsEmptySubtitle;

  /// No description provided for @productsAddNew.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get productsAddNew;

  /// No description provided for @productsBuySell.
  ///
  /// In en, this message translates to:
  /// **'Buy: {buy} · Sell: {sell}'**
  String productsBuySell(String buy, String sell);

  /// No description provided for @productsAdded.
  ///
  /// In en, this message translates to:
  /// **'Product added!'**
  String get productsAdded;

  /// No description provided for @productsAddedNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product added! (no storage permission)'**
  String get productsAddedNoPhoto;

  /// No description provided for @productsAddError.
  ///
  /// In en, this message translates to:
  /// **'Could not add the product. Try again.'**
  String get productsAddError;

  /// No description provided for @productsNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the product name.'**
  String get productsNameError;

  /// No description provided for @productsDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get productsDescriptionLabel;

  /// No description provided for @productsPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get productsPurchasePrice;

  /// No description provided for @productsPurchasePriceError.
  ///
  /// In en, this message translates to:
  /// **'Enter purchase price'**
  String get productsPurchasePriceError;

  /// No description provided for @productsSalePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale price'**
  String get productsSalePrice;

  /// No description provided for @productsSalePriceError.
  ///
  /// In en, this message translates to:
  /// **'Enter sale price'**
  String get productsSalePriceError;

  /// No description provided for @productsStockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Stock quantity'**
  String get productsStockQuantity;

  /// No description provided for @productsStockError.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity'**
  String get productsStockError;

  /// No description provided for @productsAddSubmit.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get productsAddSubmit;

  /// No description provided for @productsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get productsEditTitle;

  /// No description provided for @productsEditSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get productsEditSubmit;

  /// No description provided for @productsEditSaved.
  ///
  /// In en, this message translates to:
  /// **'Product updated!'**
  String get productsEditSaved;

  /// No description provided for @productsEditSavedNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product updated! (no storage permission)'**
  String get productsEditSavedNoPhoto;

  /// No description provided for @productsEditError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the product. Try again.'**
  String get productsEditError;

  /// No description provided for @productsPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get productsPhotoLabel;

  /// No description provided for @productsPhotoTake.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get productsPhotoTake;

  /// No description provided for @productsPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get productsPhotoGallery;

  /// No description provided for @productsPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get productsPhotoRemove;

  /// No description provided for @productsInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get productsInactive;

  /// No description provided for @productsStockOut.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get productsStockOut;

  /// No description provided for @productsStockLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productsStockLow;

  /// No description provided for @productsFilterAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get productsFilterAdvanced;

  /// No description provided for @productsFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get productsFilterClear;

  /// No description provided for @productsFilterStockType.
  ///
  /// In en, this message translates to:
  /// **'Stock type'**
  String get productsFilterStockType;

  /// No description provided for @productsFilterStockTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productsFilterStockTypeAll;

  /// No description provided for @productsFilterStockTypeWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg/g/l/ml)'**
  String get productsFilterStockTypeWeight;

  /// No description provided for @productsFilterStockTypeUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit (pcs)'**
  String get productsFilterStockTypeUnit;

  /// No description provided for @productsFilterAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get productsFilterAvailability;

  /// No description provided for @productsFilterAvailable.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get productsFilterAvailable;

  /// No description provided for @productsFilterLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productsFilterLowStock;

  /// No description provided for @productsFilterOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get productsFilterOutOfStock;

  /// No description provided for @productsFilterPriceRange.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get productsFilterPriceRange;

  /// No description provided for @productsFilterMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get productsFilterMinPrice;

  /// No description provided for @productsFilterMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get productsFilterMaxPrice;

  /// No description provided for @productsFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get productsFilterApply;

  /// No description provided for @productsFilterInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get productsFilterInactive;

  /// No description provided for @productsFilterInactiveCount.
  ///
  /// In en, this message translates to:
  /// **'Inactive · {count}'**
  String productsFilterInactiveCount(int count);

  /// No description provided for @productsHeaderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product} other{{count} products}}'**
  String productsHeaderCount(int count);

  /// No description provided for @productsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get productsClearFilters;

  /// No description provided for @productsEmptyFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get productsEmptyFilteredTitle;

  /// No description provided for @productsEmptyFilteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters.'**
  String get productsEmptyFilteredSubtitle;

  /// No description provided for @productsFilteredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product} other{{count} products}}'**
  String productsFilteredCount(int count);

  /// No description provided for @productsSummaryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get productsSummaryActive;

  /// No description provided for @productsSummaryLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get productsSummaryLowStock;

  /// No description provided for @productsSummaryInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get productsSummaryInactive;

  /// No description provided for @productsActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active product'**
  String get productsActiveLabel;

  /// No description provided for @productsActiveHint.
  ///
  /// In en, this message translates to:
  /// **'Disable to remove from POS and purchases.'**
  String get productsActiveHint;

  /// No description provided for @productsStockAdjustHint.
  ///
  /// In en, this message translates to:
  /// **'Manual adjustment: sets exact stock (FIFO).'**
  String get productsStockAdjustHint;

  /// No description provided for @productsSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get productsSectionInfo;

  /// No description provided for @productsSectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get productsSectionPricing;

  /// No description provided for @productsSectionStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get productsSectionStock;

  /// No description provided for @productsSectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get productsSectionStatus;

  /// No description provided for @productsAddNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get productsAddNewTitle;

  /// No description provided for @productsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get productsSave;

  /// No description provided for @productsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get productsSaving;

  /// No description provided for @productsSaved.
  ///
  /// In en, this message translates to:
  /// **'Product saved successfully'**
  String get productsSaved;

  /// No description provided for @productsSavedNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'Product saved! (no storage permission)'**
  String get productsSavedNoPhoto;

  /// No description provided for @productsPhotoLabelNew.
  ///
  /// In en, this message translates to:
  /// **'Product photo'**
  String get productsPhotoLabelNew;

  /// No description provided for @productsPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to add'**
  String get productsPhotoHint;

  /// No description provided for @productsSectionBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic information'**
  String get productsSectionBasic;

  /// No description provided for @productsSectionPricingNew.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get productsSectionPricingNew;

  /// No description provided for @productsSectionStockNew.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get productsSectionStockNew;

  /// No description provided for @productsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productsNameLabel;

  /// No description provided for @productsNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., Rice type 1'**
  String get productsNameHint;

  /// No description provided for @productsNameErrorMsg.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get productsNameErrorMsg;

  /// No description provided for @productsDescriptionLabelNew.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get productsDescriptionLabelNew;

  /// No description provided for @productsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get productsDescriptionHint;

  /// No description provided for @productsCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode (PLU)'**
  String get productsCodeLabel;

  /// No description provided for @productsCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Label scales (e.g. 12345)'**
  String get productsCodeHint;

  /// No description provided for @productsCodeError.
  ///
  /// In en, this message translates to:
  /// **'Invalid code: use up to 5 digits.'**
  String get productsCodeError;

  /// No description provided for @productsPurchasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get productsPurchasePriceLabel;

  /// No description provided for @productsSalePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale price'**
  String get productsSalePriceLabel;

  /// No description provided for @productsPriceValidationError.
  ///
  /// In en, this message translates to:
  /// **'Sale price must be higher than purchase price'**
  String get productsPriceValidationError;

  /// No description provided for @productsStockQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock quantity'**
  String get productsStockQuantityLabel;

  /// No description provided for @productsStockHint.
  ///
  /// In en, this message translates to:
  /// **'E.g., 50'**
  String get productsStockHint;

  /// No description provided for @productsStockWeightHint.
  ///
  /// In en, this message translates to:
  /// **'In sale units (e.g. 1.75)'**
  String get productsStockWeightHint;

  /// No description provided for @productsExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get productsExpiryLabel;

  /// No description provided for @productsExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get productsExpiryHint;

  /// No description provided for @productsExpiryAdd.
  ///
  /// In en, this message translates to:
  /// **'Set expiry'**
  String get productsExpiryAdd;

  /// No description provided for @productsExpiryClear.
  ///
  /// In en, this message translates to:
  /// **'Remove expiry'**
  String get productsExpiryClear;

  /// No description provided for @productsWeighLabel.
  ///
  /// In en, this message translates to:
  /// **'Sell by weight (fraction)'**
  String get productsWeighLabel;

  /// No description provided for @productsWeighHint.
  ///
  /// In en, this message translates to:
  /// **'Accepts decimal quantities (e.g. 1.75 kg)'**
  String get productsWeighHint;

  /// No description provided for @productsUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit of sale'**
  String get productsUnitLabel;

  /// No description provided for @customersHeaderCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer} other{{count} customers}}'**
  String customersHeaderCount(int count);

  /// No description provided for @customersColCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customersColCustomer;

  /// No description provided for @customersColContact.
  ///
  /// In en, this message translates to:
  /// **'Contact / Credit'**
  String get customersColContact;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer...'**
  String get customersSearchHint;

  /// No description provided for @customersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the customers.'**
  String get customersLoadError;

  /// No description provided for @customersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get customersEmptyTitle;

  /// No description provided for @customersEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New customer\" to get started.'**
  String get customersEmptySubtitle;

  /// No description provided for @customersAddNew.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get customersAddNew;

  /// No description provided for @customersCreditLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit {amount}'**
  String customersCreditLabel(String amount);

  /// No description provided for @customersAdded.
  ///
  /// In en, this message translates to:
  /// **'Customer {name} registered!'**
  String customersAdded(String name);

  /// No description provided for @customersAddError.
  ///
  /// In en, this message translates to:
  /// **'Could not register the customer. Try again.'**
  String get customersAddError;

  /// No description provided for @customersNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the customer name.'**
  String get customersNameError;

  /// No description provided for @customersPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get customersPhoneLabel;

  /// No description provided for @customersEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get customersEmailLabel;

  /// No description provided for @customersAddSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register customer'**
  String get customersAddSubmit;

  /// No description provided for @customersEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get customersEditTitle;

  /// No description provided for @customersEditSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer {name} updated!'**
  String customersEditSuccess(String name);

  /// No description provided for @customersEditError.
  ///
  /// In en, this message translates to:
  /// **'Could not update the customer. Try again.'**
  String get customersEditError;

  /// No description provided for @customersEditSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get customersEditSubmit;

  /// No description provided for @customersDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove customer?'**
  String get customersDeleteConfirmTitle;

  /// No description provided for @customersDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} will be permanently removed. Credit records are preserved.'**
  String customersDeleteConfirmMessage(String name);

  /// No description provided for @customersDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Customer removed.'**
  String get customersDeleteSuccess;

  /// No description provided for @customersDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the customer. Try again.'**
  String get customersDeleteError;

  /// No description provided for @purchasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchasesTitle;

  /// No description provided for @purchasesAddNew.
  ///
  /// In en, this message translates to:
  /// **'New purchase'**
  String get purchasesAddNew;

  /// No description provided for @purchasesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the purchases.'**
  String get purchasesLoadError;

  /// No description provided for @purchasesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No purchases yet'**
  String get purchasesEmptyTitle;

  /// No description provided for @purchasesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New purchase\" to record.'**
  String get purchasesEmptySubtitle;

  /// Number of today's purchases in the purchases screen summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 purchases} =1{1 purchase} other{{count} purchases}}'**
  String purchasesHeaderCount(int count);

  /// No description provided for @purchasesHeaderVsYesterday.
  ///
  /// In en, this message translates to:
  /// **'vs yesterday'**
  String get purchasesHeaderVsYesterday;

  /// Purchase card chip: units added to stock
  ///
  /// In en, this message translates to:
  /// **'Stock +{units} {unit}'**
  String purchasesStockAdded(int units, String unit);

  /// No description provided for @purchasesEmptyFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'No purchases found'**
  String get purchasesEmptyFilteredTitle;

  /// No description provided for @purchasesEmptyFilteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the search or filters.'**
  String get purchasesEmptyFilteredSubtitle;

  /// No description provided for @purchasesClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get purchasesClearFilters;

  /// No description provided for @purchasesSupplierError.
  ///
  /// In en, this message translates to:
  /// **'Enter the supplier.'**
  String get purchasesSupplierError;

  /// No description provided for @purchasesCartItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cart item no longer available. Try again.'**
  String get purchasesCartItemUnavailable;

  /// No description provided for @purchasesRegistered.
  ///
  /// In en, this message translates to:
  /// **'Purchase recorded: {amount}!'**
  String purchasesRegistered(String amount);

  /// No description provided for @purchasesProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product {id} not found in catalog.'**
  String purchasesProductNotFound(String id);

  /// No description provided for @purchasesRegisterError.
  ///
  /// In en, this message translates to:
  /// **'Could not register the purchase. Try again.'**
  String get purchasesRegisterError;

  /// No description provided for @purchasesSupplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get purchasesSupplierLabel;

  /// No description provided for @purchasesNoProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products to buy'**
  String get purchasesNoProductsTitle;

  /// No description provided for @purchasesNoProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register products to record purchases.'**
  String get purchasesNoProductsSubtitle;

  /// No description provided for @purchasesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get purchasesConfirm;

  /// No description provided for @purchasesStockLabel.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit} in stock'**
  String purchasesStockLabel(int quantity, String unit);

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reportsRevenue;

  /// No description provided for @reportsProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get reportsProfit;

  /// No description provided for @reportsMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get reportsMargin;

  /// No description provided for @reportsBestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best sellers'**
  String get reportsBestSellers;

  /// No description provided for @reportsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the report.'**
  String get reportsLoadError;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales in the period'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record sales to see the report.'**
  String get reportsEmptySubtitle;

  /// No description provided for @reportsSalesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Sales per day'**
  String get reportsSalesPerDay;

  /// No description provided for @reportsRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'{amount} sold'**
  String reportsRevenueLabel(String amount);

  /// No description provided for @reportsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get reportsExport;

  /// No description provided for @reportsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get reportsExportCsv;

  /// No description provided for @reportsExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get reportsExportPdf;

  /// No description provided for @reportsExportDone.
  ///
  /// In en, this message translates to:
  /// **'Report exported!'**
  String get reportsExportDone;

  /// No description provided for @reportsExportError.
  ///
  /// In en, this message translates to:
  /// **'Could not export the report. Try again.'**
  String get reportsExportError;

  /// No description provided for @reportsExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales report'**
  String get reportsExportTitle;

  /// No description provided for @reportsExportFileName.
  ///
  /// In en, this message translates to:
  /// **'sales_report'**
  String get reportsExportFileName;

  /// No description provided for @reportsExportStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get reportsExportStore;

  /// No description provided for @reportsExportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportsExportPeriod;

  /// No description provided for @reportsExportGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated at'**
  String get reportsExportGeneratedAt;

  /// No description provided for @reportsExportSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportsExportSummary;

  /// No description provided for @reportsExportRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get reportsExportRank;

  /// No description provided for @reportsExportProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get reportsExportProduct;

  /// No description provided for @reportsExportQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get reportsExportQuantity;

  /// No description provided for @reportsExportRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reportsExportRevenue;

  /// No description provided for @reportsExportDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get reportsExportDay;

  /// No description provided for @reportsExportTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reportsExportTotal;

  /// No description provided for @financialTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financialTitle;

  /// No description provided for @financialRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get financialRegister;

  /// No description provided for @financialIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financialIncome;

  /// No description provided for @financialExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financialExpense;

  /// No description provided for @financialBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get financialBalance;

  /// No description provided for @financialPeriodBalance.
  ///
  /// In en, this message translates to:
  /// **'Net period balance'**
  String get financialPeriodBalance;

  /// No description provided for @financialSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe for expenses →'**
  String get financialSwipeHint;

  /// No description provided for @financialTransactions.
  ///
  /// In en, this message translates to:
  /// **'Period transactions'**
  String get financialTransactions;

  /// No description provided for @financialLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the transactions.'**
  String get financialLoadError;

  /// No description provided for @financialCashFlowError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the cash flow.'**
  String get financialCashFlowError;

  /// No description provided for @financialEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get financialEmptyTitle;

  /// No description provided for @financialEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record income and expenses to track cash flow.'**
  String get financialEmptySubtitle;

  /// No description provided for @financialReceivePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive pending?'**
  String get financialReceivePendingTitle;

  /// No description provided for @financialReceivePendingBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm receipt of {amount}?'**
  String financialReceivePendingBody(String amount);

  /// No description provided for @financialReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get financialReceive;

  /// No description provided for @financialReceived.
  ///
  /// In en, this message translates to:
  /// **'Transaction received!'**
  String get financialReceived;

  /// No description provided for @financialReceiveError.
  ///
  /// In en, this message translates to:
  /// **'Could not receive. Try again.'**
  String get financialReceiveError;

  /// No description provided for @financialPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get financialPay;

  /// No description provided for @financialPayPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay pending?'**
  String get financialPayPendingTitle;

  /// No description provided for @financialPayPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm payment of {amount}?'**
  String financialPayPendingBody(String amount);

  /// No description provided for @financialPaid.
  ///
  /// In en, this message translates to:
  /// **'Expense paid!'**
  String get financialPaid;

  /// No description provided for @financialPayError.
  ///
  /// In en, this message translates to:
  /// **'Could not pay the pending item. Try again.'**
  String get financialPayError;

  /// No description provided for @financialAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Record transaction'**
  String get financialAddTitle;

  /// No description provided for @financialIncomingType.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get financialIncomingType;

  /// No description provided for @financialOutgoingType.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get financialOutgoingType;

  /// No description provided for @financialDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get financialDescriptionLabel;

  /// No description provided for @financialDescriptionError.
  ///
  /// In en, this message translates to:
  /// **'Enter the description.'**
  String get financialDescriptionError;

  /// No description provided for @financialCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get financialCategoryLabel;

  /// No description provided for @financialAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get financialAmountLabel;

  /// No description provided for @financialAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get financialAmountError;

  /// No description provided for @financialPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending (credit)'**
  String get financialPendingLabel;

  /// No description provided for @financialPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Not counted in cash until received.'**
  String get financialPendingHint;

  /// No description provided for @financialRegistered.
  ///
  /// In en, this message translates to:
  /// **'Transaction recorded!'**
  String get financialRegistered;

  /// No description provided for @financialRegisterError.
  ///
  /// In en, this message translates to:
  /// **'Could not record. Try again.'**
  String get financialRegisterError;

  /// No description provided for @financialDefaultCategoryIncome.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get financialDefaultCategoryIncome;

  /// No description provided for @financialDefaultCategoryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get financialDefaultCategoryExpense;

  /// No description provided for @financialDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get financialDetailDescription;

  /// No description provided for @financialDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get financialDetailCategory;

  /// No description provided for @financialDetailNumber.
  ///
  /// In en, this message translates to:
  /// **'Movement #'**
  String get financialDetailNumber;

  /// No description provided for @financialDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get financialDetailDate;

  /// No description provided for @financialDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get financialDetailStatus;

  /// No description provided for @cashClosingAction.
  ///
  /// In en, this message translates to:
  /// **'Cash closing'**
  String get cashClosingAction;

  /// No description provided for @cashClosingTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily cash closing'**
  String get cashClosingTitle;

  /// No description provided for @cashClosingDaySummary.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get cashClosingDaySummary;

  /// No description provided for @cashClosingTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sales'**
  String get cashClosingTotalSales;

  /// No description provided for @cashClosingExpectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected in drawer'**
  String get cashClosingExpectedCash;

  /// No description provided for @cashClosingExpectedCashHint.
  ///
  /// In en, this message translates to:
  /// **'Cash sales only.'**
  String get cashClosingExpectedCashHint;

  /// No description provided for @cashClosingByMethod.
  ///
  /// In en, this message translates to:
  /// **'By payment method'**
  String get cashClosingByMethod;

  /// No description provided for @cashClosingCountedCash.
  ///
  /// In en, this message translates to:
  /// **'Cash counted'**
  String get cashClosingCountedCash;

  /// No description provided for @cashClosingCountedCashHint.
  ///
  /// In en, this message translates to:
  /// **'Count the cash in the drawer and enter here.'**
  String get cashClosingCountedCashHint;

  /// No description provided for @cashClosingDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get cashClosingDifference;

  /// No description provided for @cashClosingConfers.
  ///
  /// In en, this message translates to:
  /// **'Cash matches'**
  String get cashClosingConfers;

  /// No description provided for @cashClosingSurplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus of {amount}'**
  String cashClosingSurplus(String amount);

  /// No description provided for @cashClosingShortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage of {amount}'**
  String cashClosingShortage(String amount);

  /// No description provided for @cashClosingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm closing'**
  String get cashClosingConfirm;

  /// No description provided for @cashClosingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update closing'**
  String get cashClosingUpdate;

  /// No description provided for @cashClosingClosedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed at'**
  String get cashClosingClosedAt;

  /// No description provided for @cashClosingSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cash closed!'**
  String get cashClosingSuccess;

  /// No description provided for @cashClosingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Closing updated!'**
  String get cashClosingUpdated;

  /// No description provided for @cashClosingError.
  ///
  /// In en, this message translates to:
  /// **'Could not close the cash. Try again.'**
  String get cashClosingError;

  /// No description provided for @cashClosingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sales recorded this day.'**
  String get cashClosingEmpty;

  /// No description provided for @cashClosingHistory.
  ///
  /// In en, this message translates to:
  /// **'Closing history'**
  String get cashClosingHistory;

  /// No description provided for @cashClosingHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No closings recorded yet.'**
  String get cashClosingHistoryEmpty;

  /// No description provided for @debtsTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get debtsTitle;

  /// No description provided for @debtsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Credit to receive and pay'**
  String get debtsHeaderSubtitle;

  /// No description provided for @debtsAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Register credit'**
  String get debtsAddDebt;

  /// No description provided for @debtsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by customer name...'**
  String get debtsSearchHint;

  /// No description provided for @debtsTabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get debtsTabPending;

  /// No description provided for @debtsTabSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get debtsTabSettled;

  /// No description provided for @debtsTotalPending.
  ///
  /// In en, this message translates to:
  /// **'Total to receive'**
  String get debtsTotalPending;

  /// No description provided for @debtsOverdueStat.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get debtsOverdueStat;

  /// No description provided for @debtsSettledStat.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get debtsSettledStat;

  /// No description provided for @debtsNoPendingCustomers.
  ///
  /// In en, this message translates to:
  /// **'No pending customers'**
  String get debtsNoPendingCustomers;

  /// No description provided for @debtsPendingCustomers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 pending customer} other{{count} pending customers}}'**
  String debtsPendingCustomers(int count);

  /// No description provided for @debtsPendingSection.
  ///
  /// In en, this message translates to:
  /// **'Pending debts'**
  String get debtsPendingSection;

  /// No description provided for @debtsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the debts.'**
  String get debtsLoadError;

  /// No description provided for @debtsEmptyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending credit'**
  String get debtsEmptyPendingTitle;

  /// No description provided for @debtsEmptyPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending credit will appear here.'**
  String get debtsEmptyPendingSubtitle;

  /// No description provided for @debtsTotalSettled.
  ///
  /// In en, this message translates to:
  /// **'Total settled'**
  String get debtsTotalSettled;

  /// No description provided for @debtsSettledCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 settlement recorded} other{{count} settlements recorded}}'**
  String debtsSettledCount(int count);

  /// No description provided for @debtsSettledSection.
  ///
  /// In en, this message translates to:
  /// **'Settlement history'**
  String get debtsSettledSection;

  /// No description provided for @debtsHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the history.'**
  String get debtsHistoryLoadError;

  /// No description provided for @debtsEmptySettledTitle.
  ///
  /// In en, this message translates to:
  /// **'No settlements yet'**
  String get debtsEmptySettledTitle;

  /// No description provided for @debtsEmptySettledSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settled credit will appear here.'**
  String get debtsEmptySettledSubtitle;

  /// No description provided for @debtsSettleTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle debt?'**
  String get debtsSettleTitle;

  /// No description provided for @debtsSettleBody.
  ///
  /// In en, this message translates to:
  /// **'Receive {amount} from {name}?'**
  String debtsSettleBody(String amount, String name);

  /// No description provided for @debtsSettle.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get debtsSettle;

  /// No description provided for @debtsSettled.
  ///
  /// In en, this message translates to:
  /// **'Credit from {name} settled — {amount} in cash.'**
  String debtsSettled(String name, String amount);

  /// No description provided for @debtsNotFound.
  ///
  /// In en, this message translates to:
  /// **'This debt is no longer pending.'**
  String get debtsNotFound;

  /// No description provided for @debtsSettleError.
  ///
  /// In en, this message translates to:
  /// **'Could not settle. Try again.'**
  String get debtsSettleError;

  /// No description provided for @debtsLate.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get debtsLate;

  /// No description provided for @debtsDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get debtsDueToday;

  /// No description provided for @debtsDueIn.
  ///
  /// In en, this message translates to:
  /// **'In {days, plural, =1{1 day} other{{days} days}}'**
  String debtsDueIn(int days);

  /// No description provided for @debtsDueAgo.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days, plural, =1{1 day} other{{days} days}}'**
  String debtsDueAgo(int days);

  /// No description provided for @debtsDueTodayDesc.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get debtsDueTodayDesc;

  /// No description provided for @debtsSettleAction.
  ///
  /// In en, this message translates to:
  /// **'Settle debt'**
  String get debtsSettleAction;

  /// No description provided for @debtsSettledLabel.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get debtsSettledLabel;

  /// No description provided for @debtsSettledOn.
  ///
  /// In en, this message translates to:
  /// **'Settled on {date}'**
  String debtsSettledOn(String date);

  /// No description provided for @debtsDueDateHelp.
  ///
  /// In en, this message translates to:
  /// **'Credit due date'**
  String get debtsDueDateHelp;

  /// No description provided for @debtsRegisteredFor.
  ///
  /// In en, this message translates to:
  /// **'Credit registered for {name}!'**
  String debtsRegisteredFor(String name);

  /// No description provided for @debtsPendingEntryError.
  ///
  /// In en, this message translates to:
  /// **'Credit registered, but pending transaction could not be created.'**
  String get debtsPendingEntryError;

  /// No description provided for @debtsRegisterError.
  ///
  /// In en, this message translates to:
  /// **'Could not register the credit. Try again.'**
  String get debtsRegisterError;

  /// No description provided for @debtsCustomerLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked customer (optional)'**
  String get debtsCustomerLinkLabel;

  /// No description provided for @debtsNoCustomer.
  ///
  /// In en, this message translates to:
  /// **'No link'**
  String get debtsNoCustomer;

  /// No description provided for @debtsCustomerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer name'**
  String get debtsCustomerNameLabel;

  /// No description provided for @debtsCustomerNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the customer name.'**
  String get debtsCustomerNameError;

  /// No description provided for @debtsDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get debtsDueDateLabel;

  /// No description provided for @salesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesTitle;

  /// No description provided for @salesNewSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get salesNewSale;

  /// Cart items section header in fullscreen POS
  ///
  /// In en, this message translates to:
  /// **'Cart · {count, plural, =1{1 item} other{{count} items}}'**
  String salesCartSection(int count);

  /// No description provided for @salesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the sales.'**
  String get salesLoadError;

  /// No description provided for @salesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get salesEmptyTitle;

  /// No description provided for @salesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New sale\" to record your first.'**
  String get salesEmptySubtitle;

  /// No description provided for @salesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search sales...'**
  String get salesSearchHint;

  /// No description provided for @periodYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get periodYesterday;

  /// No description provided for @paymentFilterCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentFilterCard;

  /// No description provided for @paymentFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get paymentFilterAll;

  /// No description provided for @salesStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get salesStatusPaid;

  /// No description provided for @salesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get salesFilterAll;

  /// No description provided for @salesFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get salesFilterActive;

  /// No description provided for @salesFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get salesFilterCancelled;

  /// Number of today's transactions in the sales screen summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 transactions} =1{1 transaction} other{{count} transactions}}'**
  String salesHeaderTransactions(int count);

  /// Number of today's sales in the fullscreen POS header
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 sales} =1{1 sale} other{{count} sales}}'**
  String salesPdvCount(int count);

  /// No description provided for @salesHeaderVsYesterday.
  ///
  /// In en, this message translates to:
  /// **'vs yesterday'**
  String get salesHeaderVsYesterday;

  /// No description provided for @salesEmptyFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'No sales found'**
  String get salesEmptyFilteredTitle;

  /// No description provided for @salesEmptyFilteredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust the search or filters.'**
  String get salesEmptyFilteredSubtitle;

  /// No description provided for @salesClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get salesClearFilters;

  /// Summary line when a filter is active in the sales list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sale} other{{count} sales}} · Total {total}'**
  String salesFilteredSummary(int count, String total);

  /// No description provided for @salesItemUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cart item no longer available. Try again.'**
  String get salesItemUnavailable;

  /// No description provided for @salesRegistered.
  ///
  /// In en, this message translates to:
  /// **'Sale recorded: {amount}!'**
  String salesRegistered(String amount);

  /// No description provided for @salesInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock{product}. Available: {available}.'**
  String salesInsufficientStock(String product, int available);

  /// No description provided for @salesStockFor.
  ///
  /// In en, this message translates to:
  /// **'for {name}'**
  String salesStockFor(String name);

  /// No description provided for @salesProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product {id} not found in stock.'**
  String salesProductNotFound(String id);

  /// No description provided for @salesRegisterError.
  ///
  /// In en, this message translates to:
  /// **'Could not register the sale. Try again.'**
  String get salesRegisterError;

  /// No description provided for @salesSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search product...'**
  String get salesSearchProducts;

  /// No description provided for @salesNoProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'No products to sell'**
  String get salesNoProductsTitle;

  /// No description provided for @salesNoProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register products to record sales.'**
  String get salesNoProductsSubtitle;

  /// No description provided for @salesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm sale'**
  String get salesConfirm;

  /// No description provided for @saleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale details'**
  String get saleDetailTitle;

  /// No description provided for @saleDetailId.
  ///
  /// In en, this message translates to:
  /// **'Sale {id}'**
  String saleDetailId(String id);

  /// No description provided for @saleDetailTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale total'**
  String get saleDetailTotalLabel;

  /// No description provided for @saleDetailItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get saleDetailItems;

  /// No description provided for @saleDetailTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get saleDetailTotal;

  /// No description provided for @saleDetailSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Prices frozen at time of sale.'**
  String get saleDetailSnapshot;

  /// No description provided for @salesStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get salesStatusCancelled;

  /// No description provided for @saleDetailCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel sale'**
  String get saleDetailCancelAction;

  /// No description provided for @saleDetailCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this sale?'**
  String get saleDetailCancelConfirmTitle;

  /// Sale cancellation confirmation — warns stock and cash will be reversed
  ///
  /// In en, this message translates to:
  /// **'Stock will be restored and cash reversed ({amount}).'**
  String saleDetailCancelConfirmBody(String amount);

  /// No description provided for @saleDetailCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get saleDetailCancelConfirm;

  /// No description provided for @saleDetailCancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled at'**
  String get saleDetailCancelledAt;

  /// No description provided for @saleCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sale cancelled.'**
  String get saleCancelledSuccess;

  /// No description provided for @saleNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'This sale no longer exists.'**
  String get saleNotFoundError;

  /// No description provided for @saleCancelError.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the sale. Try again.'**
  String get saleCancelError;

  /// No description provided for @saleDetailShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get saleDetailShareAction;

  /// No description provided for @saleDetailShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share receipt'**
  String get saleDetailShareTitle;

  /// No description provided for @saleDetailShareImage.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get saleDetailShareImage;

  /// No description provided for @saleDetailShareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get saleDetailShareWhatsApp;

  /// No description provided for @saleDetailShareError.
  ///
  /// In en, this message translates to:
  /// **'Could not share the receipt. Try again.'**
  String get saleDetailShareError;

  /// No description provided for @saleDetailShareWhatsAppError.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. Try again.'**
  String get saleDetailShareWhatsAppError;

  /// No description provided for @saleDetailReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'SALE RECEIPT'**
  String get saleDetailReceiptTitle;

  /// No description provided for @saleDetailReceiptTitleCancelled.
  ///
  /// In en, this message translates to:
  /// **'SALE RECEIPT (CANCELLED)'**
  String get saleDetailReceiptTitleCancelled;

  /// No description provided for @saleDetailReceiptPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get saleDetailReceiptPayment;

  /// No description provided for @saleDetailReceiptThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get saleDetailReceiptThanks;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Super Admin Panel'**
  String get adminTitle;

  /// No description provided for @adminNavRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get adminNavRequests;

  /// No description provided for @adminNavPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get adminNavPlans;

  /// No description provided for @adminNavUpgrades.
  ///
  /// In en, this message translates to:
  /// **'Upgrades'**
  String get adminNavUpgrades;

  /// No description provided for @adminTenantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get adminTenantsTitle;

  /// No description provided for @adminPendingOnly.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminPendingOnly;

  /// No description provided for @adminAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminAll;

  /// No description provided for @adminAwaitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} awaiting approval'**
  String adminAwaitingCount(int count);

  /// No description provided for @adminTenantsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tenants registered yet.'**
  String get adminTenantsEmpty;

  /// No description provided for @adminRequestsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the requests.'**
  String get adminRequestsLoadError;

  /// No description provided for @adminNothingPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending'**
  String get adminNothingPendingTitle;

  /// No description provided for @adminNothingPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New requests will appear here.'**
  String get adminNothingPendingSubtitle;

  /// No description provided for @adminTenantsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the tenants.'**
  String get adminTenantsLoadError;

  /// No description provided for @adminRejectError.
  ///
  /// In en, this message translates to:
  /// **'Could not reject the request.'**
  String get adminRejectError;

  /// No description provided for @adminApproveError.
  ///
  /// In en, this message translates to:
  /// **'Could not approve the request.'**
  String get adminApproveError;

  /// No description provided for @adminAccessApproved.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s access approved!'**
  String adminAccessApproved(String name);

  /// No description provided for @adminRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s request rejected.'**
  String adminRequestRejected(String name);

  /// No description provided for @adminRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject {name}'**
  String adminRejectTitle(String name);

  /// No description provided for @adminRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get adminRejectReasonLabel;

  /// No description provided for @adminRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. incomplete registration info'**
  String get adminRejectReasonHint;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan: {plan}'**
  String adminPlanLabel(String plan);

  /// No description provided for @adminPlanSolicited.
  ///
  /// In en, this message translates to:
  /// **'Plan: {plan} · Requested: {date}'**
  String adminPlanSolicited(String plan, String date);

  /// No description provided for @adminPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get adminPlansTitle;

  /// No description provided for @adminPlanNewTooltip.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get adminPlanNewTooltip;

  /// No description provided for @adminPlansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the plans.'**
  String get adminPlansLoadError;

  /// No description provided for @adminPlansEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No plans created'**
  String get adminPlansEmptyTitle;

  /// No description provided for @adminPlansEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create the first plan to enable subscriptions.'**
  String get adminPlansEmptySubtitle;

  /// No description provided for @adminPlanInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminPlanInactive;

  /// No description provided for @adminPlanDetails.
  ///
  /// In en, this message translates to:
  /// **'{price}/mo · {stores} store(s) · {employees} employee(s)'**
  String adminPlanDetails(String price, int stores, int employees);

  /// No description provided for @adminPlanNameError.
  ///
  /// In en, this message translates to:
  /// **'Enter the plan name.'**
  String get adminPlanNameError;

  /// No description provided for @adminPlanPriceError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price (≥ 0).'**
  String get adminPlanPriceError;

  /// No description provided for @adminPlanStoresError.
  ///
  /// In en, this message translates to:
  /// **'Plan must allow at least 1 store.'**
  String get adminPlanStoresError;

  /// No description provided for @adminPlanEmployeesError.
  ///
  /// In en, this message translates to:
  /// **'Plan must allow at least 1 employee.'**
  String get adminPlanEmployeesError;

  /// No description provided for @adminPlanCreated.
  ///
  /// In en, this message translates to:
  /// **'Plan {name} created!'**
  String adminPlanCreated(String name);

  /// No description provided for @adminPlanUpdated.
  ///
  /// In en, this message translates to:
  /// **'Plan {name} updated!'**
  String adminPlanUpdated(String name);

  /// No description provided for @adminPlanSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the plan. Try again.'**
  String get adminPlanSaveError;

  /// No description provided for @adminPlanNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New plan'**
  String get adminPlanNewTitle;

  /// No description provided for @adminPlanEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get adminPlanEditTitle;

  /// No description provided for @adminPlanNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get adminPlanNameLabel;

  /// No description provided for @adminPlanPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly price'**
  String get adminPlanPriceLabel;

  /// No description provided for @adminPlanMaxStores.
  ///
  /// In en, this message translates to:
  /// **'Max. stores'**
  String get adminPlanMaxStores;

  /// No description provided for @adminPlanMaxEmployees.
  ///
  /// In en, this message translates to:
  /// **'Max. employees'**
  String get adminPlanMaxEmployees;

  /// No description provided for @adminPlanActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active plan'**
  String get adminPlanActiveTitle;

  /// No description provided for @adminPlanActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disable to prevent new subscriptions.'**
  String get adminPlanActiveSubtitle;

  /// No description provided for @adminPlanCreate.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get adminPlanCreate;

  /// No description provided for @adminUpgradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan upgrades'**
  String get adminUpgradesTitle;

  /// No description provided for @adminUpgradesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the upgrade requests.'**
  String get adminUpgradesLoadError;

  /// No description provided for @adminUpgradesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No pending upgrades'**
  String get adminUpgradesEmptyTitle;

  /// No description provided for @adminUpgradesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan change requests appear here.'**
  String get adminUpgradesEmptySubtitle;

  /// No description provided for @adminUpgradeApproved.
  ///
  /// In en, this message translates to:
  /// **'Upgrade approved — plan updated!'**
  String get adminUpgradeApproved;

  /// No description provided for @adminUpgradeRejected.
  ///
  /// In en, this message translates to:
  /// **'Upgrade rejected.'**
  String get adminUpgradeRejected;

  /// No description provided for @adminUpgradeProcessError.
  ///
  /// In en, this message translates to:
  /// **'Could not process the request.'**
  String get adminUpgradeProcessError;

  /// No description provided for @adminPlanRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get adminPlanRequested;

  /// No description provided for @adminPlanCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get adminPlanCurrent;

  /// No description provided for @productsExpiryHelp.
  ///
  /// In en, this message translates to:
  /// **'Product expiry date'**
  String get productsExpiryHelp;

  /// No description provided for @salesBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get salesBarcodeLabel;

  /// No description provided for @salesBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Scale labels and PLUs — camera or USB reader'**
  String get salesBarcodeHint;

  /// No description provided for @salesBarcodeScan.
  ///
  /// In en, this message translates to:
  /// **'Scan with camera'**
  String get salesBarcodeScan;

  /// No description provided for @salesBarcodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found for this code.'**
  String get salesBarcodeNotFound;

  /// No description provided for @salesBarcodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid scale code.'**
  String get salesBarcodeInvalid;

  /// Error when adding more than available stock
  ///
  /// In en, this message translates to:
  /// **'Stock limit reached for {product}.'**
  String salesStockLimit(String product);

  /// No description provided for @salesQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get salesQuantityLabel;

  /// No description provided for @salesQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'Quantity (e.g. 1.75)'**
  String get salesQuantityHint;

  /// No description provided for @purchasesExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get purchasesExpiryLabel;

  /// No description provided for @purchasesExpiryAdd.
  ///
  /// In en, this message translates to:
  /// **'Set expiry'**
  String get purchasesExpiryAdd;

  /// No description provided for @purchasesExpiryHelp.
  ///
  /// In en, this message translates to:
  /// **'Batch expiry date'**
  String get purchasesExpiryHelp;

  /// No description provided for @dashboardExpiryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get dashboardExpiryAlerts;

  /// Expired batch — days since expiry
  ///
  /// In en, this message translates to:
  /// **'Expired {days} day(s) ago'**
  String dashboardExpiredIn(int days);

  /// Expiring batch — days remaining
  ///
  /// In en, this message translates to:
  /// **'Expires in {days} day(s)'**
  String dashboardExpiresIn(int days);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
