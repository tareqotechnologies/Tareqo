// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dumbhanengue ERP';

  @override
  String get onboardingTitle => 'Welcome!';

  @override
  String get onboardingHeading => 'Set up your business';

  @override
  String get onboardingSubtitle =>
      'Choose a plan, name and currency. Approval within 24h.';

  @override
  String get onboardingBusinessLabel => 'Business name';

  @override
  String get onboardingBusinessError => 'Enter your business name.';

  @override
  String get onboardingPlanLabel => 'Choose a plan';

  @override
  String get onboardingPlansError => 'Could not load the plans.';

  @override
  String onboardingPlanDetails(int stores, int employees) {
    return '$stores store(s) · $employees employee(s)';
  }

  @override
  String get onboardingSubmit => 'Request access';

  @override
  String onboardingSuccess(String business) {
    return 'Request for $business sent! Wait for approval (within 24h).';
  }

  @override
  String get onboardingChoosePlanError => 'Choose a plan to continue.';

  @override
  String get onboardingGenericError => 'Could not send the request. Try again.';

  @override
  String get onboardingLanguageLabel => 'Language';

  @override
  String get onboardingLanguageHint => 'App language';

  @override
  String get onboardingCurrencyLabel => 'Currency';

  @override
  String get onboardingCurrencyHint => 'Currency used for amounts';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get currencyBrl => 'Brazilian Real (BRL)';

  @override
  String get currencyUsd => 'US Dollar (USD)';

  @override
  String get currencyEur => 'Euro (EUR)';

  @override
  String get currencyMzn => 'Mozambican Metical (MZN)';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsSaved => 'Settings saved!';

  @override
  String get settingsGenericError => 'Could not save settings. Try again.';

  @override
  String get settingsSupportSection => 'Support';

  @override
  String get settingsSupportEntry => 'Help and documentation';

  @override
  String get settingsSupportEntryHint =>
      'User Guide and Troubleshooting — offline';

  @override
  String get supportTitle => 'Help';

  @override
  String get supportSubtitle => 'User guide and troubleshooting.';

  @override
  String get supportUserGuide => 'User Guide';

  @override
  String get supportUserGuideHint =>
      'Sign-in, stores, products, sales, credit, finance and reports';

  @override
  String get supportTroubleshooting => 'Troubleshooting';

  @override
  String get supportTroubleshootingHint =>
      'Common issues: sign-in, sales, stock and connection';

  @override
  String get supportReadingError => 'Could not open the document.';

  @override
  String get commonSearch => 'Search...';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSignOut => 'Sign out';

  @override
  String get appSheetClose => 'Close';

  @override
  String get storeSwitcherTooltip => 'Switch store';

  @override
  String get storeSelectorSectionTitle => 'Active store';

  @override
  String get storeSelectorSectionHint => 'Choose the active store.';

  @override
  String get tenantPendingTitle => 'Waiting for approval';

  @override
  String tenantPendingSubtitle(String business) {
    return 'Request for \"$business\" sent. Wait up to 24h.';
  }

  @override
  String get tenantPendingHint =>
      'Once approved, create stores and start operating.';

  @override
  String get tenantRejectedTitle => 'Request rejected';

  @override
  String tenantRejectedSubtitle(String business) {
    return 'The request for \"$business\" was not approved.';
  }

  @override
  String get authBlockedTitle => 'Access suspended';

  @override
  String get authBlockedMessage => 'Your account was deactivated by the owner.';

  @override
  String get authBlockedSignOut => 'Sign out';

  @override
  String get authErrorRestoreSession => 'Session not restored';

  @override
  String get authErrorCheckConnection => 'Check your connection and try again.';

  @override
  String get authErrorLoadAccount => 'Account not loaded';

  @override
  String get splashLoading => 'Opening your session…';

  @override
  String get loginSubtitleSignUp => 'Create your account to get started';

  @override
  String get loginSubtitleSignIn => 'Simple management for your business';

  @override
  String get loginNameLabel => 'Name';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailError => 'Enter a valid email.';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordError => 'Password must be at least 8 characters.';

  @override
  String get loginPasswordHint =>
      'Min. 8 characters with lowercase, uppercase, number and symbol.';

  @override
  String get loginWeakPasswordError =>
      'Password must include letters, numbers and symbols.';

  @override
  String get loginRateLimitError =>
      'Too many attempts. Wait 1 hour and try again.';

  @override
  String get loginShowPassword => 'Show password';

  @override
  String get loginHidePassword => 'Hide password';

  @override
  String get loginConfirmLabel => 'Confirm password';

  @override
  String get loginConfirmError => 'Passwords do not match.';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginSwitchToSignIn => 'Already have an account — sign in';

  @override
  String get loginSwitchToSignUp => 'No account yet — sign up';

  @override
  String get loginSignUpSuccess =>
      'Account created! Confirm your email to sign in.';

  @override
  String get loginSignUpError => 'Could not create the account. Try again.';

  @override
  String get loginSignInError =>
      'Could not sign in. Check your email and password.';

  @override
  String get loginSecurityNote => 'Data protected with encryption.';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordHint =>
      'Enter your email. We\'ll send a reset link.';

  @override
  String get forgotPasswordSubmit => 'Send link';

  @override
  String get forgotPasswordSent => 'If an account exists, we\'ve sent a link.';

  @override
  String get forgotPasswordError => 'Could not send the link. Try again.';

  @override
  String get setNewPasswordTitle => 'Set a new password';

  @override
  String get setNewPasswordHint =>
      'Min. 8 characters with lowercase, uppercase, number and symbol.';

  @override
  String get setNewPasswordSubmit => 'Save new password';

  @override
  String get setNewPasswordSuccess => 'Password updated!';

  @override
  String get setNewPasswordError => 'Could not update the password. Try again.';

  @override
  String get setNewPasswordSignOut => 'Sign out';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordSuccess => 'Password changed successfully!';

  @override
  String get changePasswordWrongCurrent =>
      'Current password is incorrect. Try again.';

  @override
  String get changePasswordSubmit => 'Change password';

  @override
  String get changePasswordError => 'Could not change the password. Try again.';

  @override
  String get securitySectionTitle => 'Security';

  @override
  String get securityChangePassword => 'Change password';

  @override
  String get securityChangePasswordHint => 'Update your account password';

  @override
  String get appNavHome => 'Home';

  @override
  String get appNavSales => 'Sales';

  @override
  String get appNavWallet => 'Wallet';

  @override
  String get appNavMenu => 'Menu';

  @override
  String get appNavProducts => 'Products';

  @override
  String get appNavFinancial => 'Finance';

  @override
  String get appNavCredit => 'Credit';

  @override
  String get appNavCustomers => 'Customers';

  @override
  String get fabMenuTitle => 'New action';

  @override
  String get fabMenuSubtitle => 'What would you like to do?';

  @override
  String get menuSubtitle => 'Choose an area to continue';

  @override
  String get commonSignOutConfirmTitle => 'Sign out?';

  @override
  String get commonSignOutConfirmMessage =>
      'You will sign out of your account on this device.';

  @override
  String get fabMenuNewSale => 'New sale';

  @override
  String get fabMenuNewSaleHint => 'Cart · stock deduction · cash';

  @override
  String get fabMenuExpense => 'Register expense';

  @override
  String get fabMenuExpenseHint => 'Cash outflow with category';

  @override
  String get fabMenuAddProduct => 'Add product';

  @override
  String get fabMenuAddProductHint => 'Catalog · price · initial stock';

  @override
  String get fabMenuAddDebt => 'Register credit';

  @override
  String get fabMenuAddDebtHint => 'Receivable or payable';

  @override
  String get fabMenuAddCustomer => 'Add customer';

  @override
  String get fabMenuAddCustomerHint => 'Contacts · linked credit';

  @override
  String get fabMenuCancel => 'Cancel';

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operations awaiting sync',
      one: '1 operation awaiting sync',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncOfflineSaved =>
      'No connection. Saved — will sync automatically.';

  @override
  String syncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operations synced',
      one: '1 operation synced',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline => 'No connection — operations pending.';

  @override
  String dashboardGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get dashboardSignOutTooltip => 'Sign out';

  @override
  String get dashboardOwnerFallback => 'Owner';

  @override
  String get dashboardTotalSales => 'Total sales';

  @override
  String get dashboardAllTime => 'All time';

  @override
  String get dashboardCashBalance => 'Cash balance';

  @override
  String get dashboardReceivables => 'Receivables (credit)';

  @override
  String get dashboardStockLabel => 'Stock in products';

  @override
  String get commonUnits => 'u.';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardQuickNewSale => 'New sale';

  @override
  String get dashboardQuickAddProduct => 'Add product';

  @override
  String get dashboardQuickAddTransaction => 'Add transaction';

  @override
  String get dashboardQuickAddDebt => 'Add credit';

  @override
  String get dashboardModules => 'Modules';

  @override
  String get dashboardModuleCustomers => 'Customers';

  @override
  String get dashboardModulePurchases => 'Purchases';

  @override
  String get dashboardModuleReports => 'Reports';

  @override
  String get dashboardModuleStores => 'Stores';

  @override
  String get dashboardRecentSales => 'Recent sales';

  @override
  String get dashboardViewAll => 'View all';

  @override
  String get dashboardNoSales => 'No sales yet — record your first one!';

  @override
  String get dashboardRecentPurchases => 'Recent purchases';

  @override
  String get dashboardNoPurchases =>
      'No purchases yet — record your first one!';

  @override
  String get dashboardLowStock => 'Low stock';

  @override
  String get dashboardKpisError => 'Could not load indicators.';

  @override
  String get dashboardActivityTitle => 'Today\'s activity';

  @override
  String dashboardActivityEvents(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String dashboardActivityMinutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String dashboardActivityHoursAgo(Object count) {
    return '$count h ago';
  }

  @override
  String get dashboardDateToday => 'Today';

  @override
  String get dashboardMetricSales => 'Sales';

  @override
  String get dashboardMetricCash => 'Cash';

  @override
  String get dashboardMetricReceivables => 'Receivables';

  @override
  String dashboardFiadoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tabs',
      one: '1 tab',
    );
    return '$_temp0';
  }

  @override
  String get dashboardActivityEmpty => 'No activity recorded yet.';

  @override
  String get dashboardActivitySeeAll => 'View all';

  @override
  String dashboardStockEntry(String product) {
    return 'Stock · $product';
  }

  @override
  String dashboardStockEntryDetail(String quantity, String time) {
    return 'Inflow of $quantity · $time';
  }

  @override
  String get dashboardFiadoPayment => 'Credit payment';

  @override
  String dashboardExpenseRow(String description) {
    return 'Expense · $description';
  }

  @override
  String dashboardLowStockDetail(String name, String quantity) {
    return '$name · $quantity left';
  }

  @override
  String get dashboardAlertBadge => 'Alert';

  @override
  String dashboardSaleItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get storesTitle => 'Stores';

  @override
  String get storesTabStores => 'Stores';

  @override
  String get storesTabEmployees => 'Employees';

  @override
  String get storesTabUpgrades => 'Upgrades';

  @override
  String get storesTabSettings => 'Settings';

  @override
  String get storesAddStore => 'New store';

  @override
  String get storesAddEmployee => 'New employee';

  @override
  String get storesLoadError => 'Could not load the stores.';

  @override
  String get storesEmptyTitle => 'No stores created';

  @override
  String get storesEmptySubtitle => 'Create the first store of your business.';

  @override
  String get employeesLoadError => 'Could not load the employees.';

  @override
  String get employeesEmptyTitle => 'No employees linked';

  @override
  String get employeesEmptySubtitle =>
      'Create the employee account and pick a store.';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get employeeActive => 'Active';

  @override
  String get employeeInactive => 'Inactive';

  @override
  String employeeDeactivateConfirm(Object name) {
    return 'Deactivate $name? Loses access immediately.';
  }

  @override
  String employeeReactivateConfirm(Object name) {
    return 'Reactivate $name? Gets store access again.';
  }

  @override
  String get employeeDeactivated => 'Employee deactivated.';

  @override
  String get employeeReactivated => 'Employee reactivated.';

  @override
  String get employeeDeactivateAction => 'Deactivate';

  @override
  String get employeeReactivateAction => 'Reactivate';

  @override
  String get employeeDetailTitle => 'Employee details';

  @override
  String get employeeDetailEmail => 'Email';

  @override
  String get employeeDetailStore => 'Store';

  @override
  String get employeeDetailRole => 'Access level';

  @override
  String get employeeDetailStatus => 'Status';

  @override
  String get employeeDetailActive => 'Active';

  @override
  String get employeeDetailInactive => 'Inactive';

  @override
  String get employeeDetailActions => 'Actions';

  @override
  String get upgradesLoadError => 'Could not load the plan upgrade requests.';

  @override
  String get upgradesEmptyTitle => 'No upgrade requests';

  @override
  String get upgradesEmptySubtitle =>
      'Request a bigger plan in the card above.';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusRejected => 'Rejected';

  @override
  String upgradesRequestedOn(String date) {
    return 'Requested on $date';
  }

  @override
  String get planCardTitle => 'Plan';

  @override
  String get planCardUpgrade => 'Upgrade';

  @override
  String get planCardStores => 'Stores';

  @override
  String get planCardEmployees => 'Employees';

  @override
  String planDetails(int stores, int employees) {
    return '$stores store(s) · $employees employee(s)';
  }

  @override
  String get addStoreTitle => 'New store';

  @override
  String get addStoreNameLabel => 'Store name';

  @override
  String get addStoreNameError => 'Enter the store name.';

  @override
  String get addStoreAddressLabel => 'Address (optional)';

  @override
  String addStoreSuccess(String name) {
    return 'Store $name created!';
  }

  @override
  String get addStoreError => 'Could not create the store. Try again.';

  @override
  String get addStoreSubmit => 'Create store';

  @override
  String get addEmployeeTitle => 'New employee';

  @override
  String get addEmployeeNameLabel => 'Full name';

  @override
  String get addEmployeeNameError => 'Enter the employee name.';

  @override
  String get addEmployeeEmailLabel => 'Email';

  @override
  String get addEmployeeEmailError => 'Enter a valid email.';

  @override
  String get addEmployeePasswordLabel => 'Access password';

  @override
  String get addEmployeePasswordError =>
      'Password must be at least 8 characters.';

  @override
  String get addEmployeeStoreLabel => 'Store';

  @override
  String get addEmployeeNoStores => 'Create a store before adding employees.';

  @override
  String get addEmployeeRoleLabel => 'Role';

  @override
  String get addEmployeeSuccess =>
      'Employee registered! Access account created.';

  @override
  String get addEmployeeError =>
      'Could not register. Check if the email is in use.';

  @override
  String get addEmployeeSubmit => 'Register employee';

  @override
  String get upgradeTitle => 'Plan upgrade';

  @override
  String get upgradeSubtitle =>
      'Choose the new plan. Awaits super admin approval.';

  @override
  String get upgradeMaxReached => 'You are already on the highest plan.';

  @override
  String get upgradeChooseError => 'Choose the target plan.';

  @override
  String get upgradeSuccess => 'Upgrade request sent!';

  @override
  String get upgradeError => 'Could not send the request. Try again.';

  @override
  String get upgradeSubmit => 'Request upgrade';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonNoResults => 'No results';

  @override
  String get commonNoResultsHint => 'Try searching another term.';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSoldOut => 'Sold out';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'This week';

  @override
  String get periodMonth => 'This month';

  @override
  String get periodAll => 'All';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentDebitCard => 'Debit card';

  @override
  String get paymentCreditCard => 'Credit card';

  @override
  String get paymentEMola => 'E-Mola';

  @override
  String get paymentMPesa => 'M-Pesa';

  @override
  String get paymentTransfer => 'Transfer';

  @override
  String get purchasesSearchHint => 'Search purchases...';

  @override
  String get productsFilterTooltip => 'Filter';

  @override
  String get productsFilterAll => 'All';

  @override
  String productsFilterAllCount(int count) {
    return 'All · $count';
  }

  @override
  String productsFilterLowCount(int count) {
    return 'Low stock · $count';
  }

  @override
  String get productsColProduct => 'Product / SKU';

  @override
  String get productsColPrice => 'Price · Stock';

  @override
  String get productsSearchHint => 'Search product...';

  @override
  String get productsLoadError => 'Could not load the products.';

  @override
  String get productsEmptyTitle => 'No products yet';

  @override
  String get productsEmptySubtitle => 'Tap \"New product\" to get started.';

  @override
  String get productsAddNew => 'New product';

  @override
  String productsBuySell(String buy, String sell) {
    return 'Buy: $buy · Sell: $sell';
  }

  @override
  String get productsAdded => 'Product added!';

  @override
  String get productsAddedNoPhoto => 'Product added! (no storage permission)';

  @override
  String get productsAddError => 'Could not add the product. Try again.';

  @override
  String get productsNameError => 'Enter the product name.';

  @override
  String get productsDescriptionLabel => 'Description (optional)';

  @override
  String get productsPurchasePrice => 'Purchase price';

  @override
  String get productsPurchasePriceError => 'Enter purchase price';

  @override
  String get productsSalePrice => 'Sale price';

  @override
  String get productsSalePriceError => 'Enter sale price';

  @override
  String get productsStockQuantity => 'Stock quantity';

  @override
  String get productsStockError => 'Invalid quantity';

  @override
  String get productsAddSubmit => 'Add product';

  @override
  String get productsEditTitle => 'Edit product';

  @override
  String get productsEditSubmit => 'Save changes';

  @override
  String get productsEditSaved => 'Product updated!';

  @override
  String get productsEditSavedNoPhoto =>
      'Product updated! (no storage permission)';

  @override
  String get productsEditError => 'Could not update the product. Try again.';

  @override
  String get productsPhotoLabel => 'Product photo';

  @override
  String get productsPhotoTake => 'Take photo';

  @override
  String get productsPhotoGallery => 'Choose from gallery';

  @override
  String get productsPhotoRemove => 'Remove photo';

  @override
  String get productsInactive => 'Inactive';

  @override
  String get productsStockOut => 'Out of stock';

  @override
  String get productsStockLow => 'Low stock';

  @override
  String get productsFilterAdvanced => 'Advanced filters';

  @override
  String get productsFilterClear => 'Clear all';

  @override
  String get productsFilterStockType => 'Stock type';

  @override
  String get productsFilterStockTypeAll => 'All';

  @override
  String get productsFilterStockTypeWeight => 'Weight (kg/g/l/ml)';

  @override
  String get productsFilterStockTypeUnit => 'Unit (pcs)';

  @override
  String get productsFilterAvailability => 'Availability';

  @override
  String get productsFilterAvailable => 'In stock';

  @override
  String get productsFilterLowStock => 'Low stock';

  @override
  String get productsFilterOutOfStock => 'Out of stock';

  @override
  String get productsFilterPriceRange => 'Price range';

  @override
  String get productsFilterMinPrice => 'Min price';

  @override
  String get productsFilterMaxPrice => 'Max price';

  @override
  String get productsFilterApply => 'Apply';

  @override
  String get productsFilterInactive => 'Inactive';

  @override
  String productsFilterInactiveCount(int count) {
    return 'Inactive · $count';
  }

  @override
  String productsHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String get productsClearFilters => 'Clear filters';

  @override
  String get productsEmptyFilteredTitle => 'No products found';

  @override
  String get productsEmptyFilteredSubtitle =>
      'Try adjusting your search or filters.';

  @override
  String productsFilteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    return '$_temp0';
  }

  @override
  String get productsSummaryActive => 'Active';

  @override
  String get productsSummaryLowStock => 'Low stock';

  @override
  String get productsSummaryInactive => 'Inactive';

  @override
  String get productsActiveLabel => 'Active product';

  @override
  String get productsActiveHint => 'Disable to remove from POS and purchases.';

  @override
  String get productsStockAdjustHint =>
      'Manual adjustment: sets exact stock (FIFO).';

  @override
  String get productsSectionInfo => 'Info';

  @override
  String get productsSectionPricing => 'Pricing';

  @override
  String get productsSectionStock => 'Stock';

  @override
  String get productsSectionStatus => 'Status';

  @override
  String get productsAddNewTitle => 'New product';

  @override
  String get productsSave => 'Save';

  @override
  String get productsSaving => 'Saving...';

  @override
  String get productsSaved => 'Product saved successfully';

  @override
  String get productsSavedNoPhoto => 'Product saved! (no storage permission)';

  @override
  String get productsPhotoLabelNew => 'Product photo';

  @override
  String get productsPhotoHint => 'Tap to add';

  @override
  String get productsSectionBasic => 'Basic information';

  @override
  String get productsSectionPricingNew => 'Pricing';

  @override
  String get productsSectionStockNew => 'Stock';

  @override
  String get productsNameLabel => 'Product name';

  @override
  String get productsNameHint => 'E.g., Rice type 1';

  @override
  String get productsNameErrorMsg => 'Required';

  @override
  String get productsDescriptionLabelNew => 'Description';

  @override
  String get productsDescriptionHint => 'Optional';

  @override
  String get productsCodeLabel => 'Barcode (PLU)';

  @override
  String get productsCodeHint => 'Label scales (e.g. 12345)';

  @override
  String get productsCodeError => 'Invalid code: use up to 5 digits.';

  @override
  String get productsPurchasePriceLabel => 'Purchase price';

  @override
  String get productsSalePriceLabel => 'Sale price';

  @override
  String get productsPriceValidationError =>
      'Sale price must be higher than purchase price';

  @override
  String get productsStockQuantityLabel => 'Stock quantity';

  @override
  String get productsStockHint => 'E.g., 50';

  @override
  String get productsStockWeightHint => 'In sale units (e.g. 1.75)';

  @override
  String get productsExpiryLabel => 'Expiry';

  @override
  String get productsExpiryHint => 'Optional';

  @override
  String get productsExpiryAdd => 'Set expiry';

  @override
  String get productsExpiryClear => 'Remove expiry';

  @override
  String get productsWeighLabel => 'Sell by weight (fraction)';

  @override
  String get productsWeighHint => 'Accepts decimal quantities (e.g. 1.75 kg)';

  @override
  String get productsUnitLabel => 'Unit of sale';

  @override
  String customersHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers',
      one: '1 customer',
    );
    return '$_temp0';
  }

  @override
  String get customersColCustomer => 'Customer';

  @override
  String get customersColContact => 'Contact / Credit';

  @override
  String get customersSearchHint => 'Search customer...';

  @override
  String get customersLoadError => 'Could not load the customers.';

  @override
  String get customersEmptyTitle => 'No customers yet';

  @override
  String get customersEmptySubtitle => 'Tap \"New customer\" to get started.';

  @override
  String get customersAddNew => 'New customer';

  @override
  String customersCreditLabel(String amount) {
    return 'Credit $amount';
  }

  @override
  String customersAdded(String name) {
    return 'Customer $name registered!';
  }

  @override
  String get customersAddError => 'Could not register the customer. Try again.';

  @override
  String get customersNameError => 'Enter the customer name.';

  @override
  String get customersPhoneLabel => 'Phone (optional)';

  @override
  String get customersEmailLabel => 'Email (optional)';

  @override
  String get customersAddSubmit => 'Register customer';

  @override
  String get customersEditTitle => 'Edit customer';

  @override
  String customersEditSuccess(Object name) {
    return 'Customer $name updated!';
  }

  @override
  String get customersEditError => 'Could not update the customer. Try again.';

  @override
  String get customersEditSubmit => 'Save changes';

  @override
  String get customersDeleteConfirmTitle => 'Remove customer?';

  @override
  String customersDeleteConfirmMessage(Object name) {
    return '$name will be permanently removed. Credit records are preserved.';
  }

  @override
  String get customersDeleteSuccess => 'Customer removed.';

  @override
  String get customersDeleteError =>
      'Could not remove the customer. Try again.';

  @override
  String get purchasesTitle => 'Purchases';

  @override
  String get purchasesAddNew => 'New purchase';

  @override
  String get purchasesLoadError => 'Could not load the purchases.';

  @override
  String get purchasesEmptyTitle => 'No purchases yet';

  @override
  String get purchasesEmptySubtitle => 'Tap \"New purchase\" to record.';

  @override
  String purchasesHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count purchases',
      one: '1 purchase',
      zero: '0 purchases',
    );
    return '$_temp0';
  }

  @override
  String get purchasesHeaderVsYesterday => 'vs yesterday';

  @override
  String purchasesStockAdded(int units, String unit) {
    return 'Stock +$units $unit';
  }

  @override
  String get purchasesEmptyFilteredTitle => 'No purchases found';

  @override
  String get purchasesEmptyFilteredSubtitle => 'Adjust the search or filters.';

  @override
  String get purchasesClearFilters => 'Clear filters';

  @override
  String get purchasesSupplierError => 'Enter the supplier.';

  @override
  String get purchasesCartItemUnavailable =>
      'Cart item no longer available. Try again.';

  @override
  String purchasesRegistered(String amount) {
    return 'Purchase recorded: $amount!';
  }

  @override
  String purchasesProductNotFound(String id) {
    return 'Product $id not found in catalog.';
  }

  @override
  String get purchasesRegisterError =>
      'Could not register the purchase. Try again.';

  @override
  String get purchasesSupplierLabel => 'Supplier';

  @override
  String get purchasesNoProductsTitle => 'No products to buy';

  @override
  String get purchasesNoProductsSubtitle =>
      'Register products to record purchases.';

  @override
  String get purchasesConfirm => 'Confirm purchase';

  @override
  String purchasesStockLabel(int quantity, String unit) {
    return '$quantity $unit in stock';
  }

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsRevenue => 'Revenue';

  @override
  String get reportsProfit => 'Gross profit';

  @override
  String get reportsMargin => 'Margin';

  @override
  String get reportsBestSellers => 'Best sellers';

  @override
  String get reportsLoadError => 'Could not load the report.';

  @override
  String get reportsEmptyTitle => 'No sales in the period';

  @override
  String get reportsEmptySubtitle => 'Record sales to see the report.';

  @override
  String get reportsSalesPerDay => 'Sales per day';

  @override
  String reportsRevenueLabel(String amount) {
    return '$amount sold';
  }

  @override
  String get reportsExport => 'Export';

  @override
  String get reportsExportCsv => 'Export CSV';

  @override
  String get reportsExportPdf => 'Export PDF';

  @override
  String get reportsExportDone => 'Report exported!';

  @override
  String get reportsExportError => 'Could not export the report. Try again.';

  @override
  String get reportsExportTitle => 'Sales report';

  @override
  String get reportsExportFileName => 'sales_report';

  @override
  String get reportsExportStore => 'Store';

  @override
  String get reportsExportPeriod => 'Period';

  @override
  String get reportsExportGeneratedAt => 'Generated at';

  @override
  String get reportsExportSummary => 'Summary';

  @override
  String get reportsExportRank => 'Rank';

  @override
  String get reportsExportProduct => 'Product';

  @override
  String get reportsExportQuantity => 'Quantity';

  @override
  String get reportsExportRevenue => 'Revenue';

  @override
  String get reportsExportDay => 'Day';

  @override
  String get reportsExportTotal => 'Total';

  @override
  String get financialTitle => 'Finance';

  @override
  String get financialRegister => 'Register';

  @override
  String get financialIncome => 'Income';

  @override
  String get financialExpense => 'Expenses';

  @override
  String get financialBalance => 'Balance';

  @override
  String get financialPeriodBalance => 'Net period balance';

  @override
  String get financialSwipeHint => 'Swipe for expenses →';

  @override
  String get financialTransactions => 'Period transactions';

  @override
  String get financialLoadError => 'Could not load the transactions.';

  @override
  String get financialCashFlowError => 'Could not load the cash flow.';

  @override
  String get financialEmptyTitle => 'No transactions';

  @override
  String get financialEmptySubtitle =>
      'Record income and expenses to track cash flow.';

  @override
  String get financialReceivePendingTitle => 'Receive pending?';

  @override
  String financialReceivePendingBody(String amount) {
    return 'Confirm receipt of $amount?';
  }

  @override
  String get financialReceive => 'Receive';

  @override
  String get financialReceived => 'Transaction received!';

  @override
  String get financialReceiveError => 'Could not receive. Try again.';

  @override
  String get financialPay => 'Pay';

  @override
  String get financialPayPendingTitle => 'Pay pending?';

  @override
  String financialPayPendingBody(String amount) {
    return 'Confirm payment of $amount?';
  }

  @override
  String get financialPaid => 'Expense paid!';

  @override
  String get financialPayError => 'Could not pay the pending item. Try again.';

  @override
  String get financialAddTitle => 'Record transaction';

  @override
  String get financialIncomingType => 'Income';

  @override
  String get financialOutgoingType => 'Expense';

  @override
  String get financialDescriptionLabel => 'Description';

  @override
  String get financialDescriptionError => 'Enter the description.';

  @override
  String get financialCategoryLabel => 'Category (optional)';

  @override
  String get financialAmountLabel => 'Amount';

  @override
  String get financialAmountError => 'Enter an amount greater than zero.';

  @override
  String get financialPendingLabel => 'Pending (credit)';

  @override
  String get financialPendingHint => 'Not counted in cash until received.';

  @override
  String get financialRegistered => 'Transaction recorded!';

  @override
  String get financialRegisterError => 'Could not record. Try again.';

  @override
  String get financialDefaultCategoryIncome => 'Sales';

  @override
  String get financialDefaultCategoryExpense => 'Expenses';

  @override
  String get financialDetailDescription => 'Description';

  @override
  String get financialDetailCategory => 'Category';

  @override
  String get financialDetailNumber => 'Movement #';

  @override
  String get financialDetailDate => 'Date and time';

  @override
  String get financialDetailStatus => 'Status';

  @override
  String get cashClosingAction => 'Cash closing';

  @override
  String get cashClosingTitle => 'Daily cash closing';

  @override
  String get cashClosingDaySummary => 'Day summary';

  @override
  String get cashClosingTotalSales => 'Today\'s sales';

  @override
  String get cashClosingExpectedCash => 'Expected in drawer';

  @override
  String get cashClosingExpectedCashHint => 'Cash sales only.';

  @override
  String get cashClosingByMethod => 'By payment method';

  @override
  String get cashClosingCountedCash => 'Cash counted';

  @override
  String get cashClosingCountedCashHint =>
      'Count the cash in the drawer and enter here.';

  @override
  String get cashClosingDifference => 'Difference';

  @override
  String get cashClosingConfers => 'Cash matches';

  @override
  String cashClosingSurplus(String amount) {
    return 'Surplus of $amount';
  }

  @override
  String cashClosingShortage(String amount) {
    return 'Shortage of $amount';
  }

  @override
  String get cashClosingConfirm => 'Confirm closing';

  @override
  String get cashClosingUpdate => 'Update closing';

  @override
  String get cashClosingClosedAt => 'Closed at';

  @override
  String get cashClosingSuccess => 'Cash closed!';

  @override
  String get cashClosingUpdated => 'Closing updated!';

  @override
  String get cashClosingError => 'Could not close the cash. Try again.';

  @override
  String get cashClosingEmpty => 'No sales recorded this day.';

  @override
  String get cashClosingHistory => 'Closing history';

  @override
  String get cashClosingHistoryEmpty => 'No closings recorded yet.';

  @override
  String get debtsTitle => 'Credit';

  @override
  String get debtsHeaderSubtitle => 'Credit to receive and pay';

  @override
  String get debtsAddDebt => 'Register credit';

  @override
  String get debtsSearchHint => 'Search by customer name...';

  @override
  String get debtsTabPending => 'Pending';

  @override
  String get debtsTabSettled => 'Settled';

  @override
  String get debtsTotalPending => 'Total to receive';

  @override
  String get debtsOverdueStat => 'Overdue';

  @override
  String get debtsSettledStat => 'Settled';

  @override
  String get debtsNoPendingCustomers => 'No pending customers';

  @override
  String debtsPendingCustomers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending customers',
      one: '1 pending customer',
    );
    return '$_temp0';
  }

  @override
  String get debtsPendingSection => 'Pending debts';

  @override
  String get debtsLoadError => 'Could not load the debts.';

  @override
  String get debtsEmptyPendingTitle => 'No pending credit';

  @override
  String get debtsEmptyPendingSubtitle => 'Pending credit will appear here.';

  @override
  String get debtsTotalSettled => 'Total settled';

  @override
  String debtsSettledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settlements recorded',
      one: '1 settlement recorded',
    );
    return '$_temp0';
  }

  @override
  String get debtsSettledSection => 'Settlement history';

  @override
  String get debtsHistoryLoadError => 'Could not load the history.';

  @override
  String get debtsEmptySettledTitle => 'No settlements yet';

  @override
  String get debtsEmptySettledSubtitle => 'Settled credit will appear here.';

  @override
  String get debtsSettleTitle => 'Settle debt?';

  @override
  String debtsSettleBody(String amount, String name) {
    return 'Receive $amount from $name?';
  }

  @override
  String get debtsSettle => 'Settle';

  @override
  String debtsSettled(String name, String amount) {
    return 'Credit from $name settled — $amount in cash.';
  }

  @override
  String get debtsNotFound => 'This debt is no longer pending.';

  @override
  String get debtsSettleError => 'Could not settle. Try again.';

  @override
  String get debtsLate => 'Overdue';

  @override
  String get debtsDueToday => 'Due today';

  @override
  String debtsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'In $_temp0';
  }

  @override
  String debtsDueAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Overdue by $_temp0';
  }

  @override
  String get debtsDueTodayDesc => 'Due today';

  @override
  String get debtsSettleAction => 'Settle debt';

  @override
  String get debtsSettledLabel => 'Settled';

  @override
  String debtsSettledOn(String date) {
    return 'Settled on $date';
  }

  @override
  String get debtsDueDateHelp => 'Credit due date';

  @override
  String debtsRegisteredFor(String name) {
    return 'Credit registered for $name!';
  }

  @override
  String get debtsPendingEntryError =>
      'Credit registered, but pending transaction could not be created.';

  @override
  String get debtsRegisterError => 'Could not register the credit. Try again.';

  @override
  String get debtsCustomerLinkLabel => 'Linked customer (optional)';

  @override
  String get debtsNoCustomer => 'No link';

  @override
  String get debtsCustomerNameLabel => 'Customer name';

  @override
  String get debtsCustomerNameError => 'Enter the customer name.';

  @override
  String get debtsDueDateLabel => 'Due date';

  @override
  String get salesTitle => 'Sales';

  @override
  String get salesNewSale => 'New sale';

  @override
  String salesCartSection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Cart · $_temp0';
  }

  @override
  String get salesLoadError => 'Could not load the sales.';

  @override
  String get salesEmptyTitle => 'No sales yet';

  @override
  String get salesEmptySubtitle => 'Tap \"New sale\" to record your first.';

  @override
  String get salesSearchHint => 'Search sales...';

  @override
  String get periodYesterday => 'Yesterday';

  @override
  String get paymentFilterCard => 'Card';

  @override
  String get paymentFilterAll => 'All';

  @override
  String get salesStatusPaid => 'Paid';

  @override
  String get salesFilterAll => 'All';

  @override
  String get salesFilterActive => 'Active';

  @override
  String get salesFilterCancelled => 'Cancelled';

  @override
  String salesHeaderTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: '0 transactions',
    );
    return '$_temp0';
  }

  @override
  String salesPdvCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
      zero: '0 sales',
    );
    return '$_temp0';
  }

  @override
  String get salesHeaderVsYesterday => 'vs yesterday';

  @override
  String get salesEmptyFilteredTitle => 'No sales found';

  @override
  String get salesEmptyFilteredSubtitle => 'Adjust the search or filters.';

  @override
  String get salesClearFilters => 'Clear filters';

  @override
  String salesFilteredSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return '$_temp0 · Total $total';
  }

  @override
  String get salesItemUnavailable =>
      'Cart item no longer available. Try again.';

  @override
  String salesRegistered(String amount) {
    return 'Sale recorded: $amount!';
  }

  @override
  String salesInsufficientStock(String product, int available) {
    return 'Insufficient stock$product. Available: $available.';
  }

  @override
  String salesStockFor(String name) {
    return 'for $name';
  }

  @override
  String salesProductNotFound(String id) {
    return 'Product $id not found in stock.';
  }

  @override
  String get salesRegisterError => 'Could not register the sale. Try again.';

  @override
  String get salesSearchProducts => 'Search product...';

  @override
  String get salesNoProductsTitle => 'No products to sell';

  @override
  String get salesNoProductsSubtitle => 'Register products to record sales.';

  @override
  String get salesConfirm => 'Confirm sale';

  @override
  String get saleDetailTitle => 'Sale details';

  @override
  String saleDetailId(String id) {
    return 'Sale $id';
  }

  @override
  String get saleDetailTotalLabel => 'Sale total';

  @override
  String get saleDetailItems => 'Items';

  @override
  String get saleDetailTotal => 'Total';

  @override
  String get saleDetailSnapshot => 'Prices frozen at time of sale.';

  @override
  String get salesStatusCancelled => 'Cancelled';

  @override
  String get saleDetailCancelAction => 'Cancel sale';

  @override
  String get saleDetailCancelConfirmTitle => 'Cancel this sale?';

  @override
  String saleDetailCancelConfirmBody(String amount) {
    return 'Stock will be restored and cash reversed ($amount).';
  }

  @override
  String get saleDetailCancelConfirm => 'Yes, cancel';

  @override
  String get saleDetailCancelledAt => 'Cancelled at';

  @override
  String get saleCancelledSuccess => 'Sale cancelled.';

  @override
  String get saleNotFoundError => 'This sale no longer exists.';

  @override
  String get saleCancelError => 'Could not cancel the sale. Try again.';

  @override
  String get saleDetailShareAction => 'Share receipt';

  @override
  String get saleDetailShareTitle => 'Share receipt';

  @override
  String get saleDetailShareImage => 'Share as image';

  @override
  String get saleDetailShareWhatsApp => 'WhatsApp';

  @override
  String get saleDetailShareError => 'Could not share the receipt. Try again.';

  @override
  String get saleDetailShareWhatsAppError =>
      'Could not open WhatsApp. Try again.';

  @override
  String get saleDetailReceiptTitle => 'SALE RECEIPT';

  @override
  String get saleDetailReceiptTitleCancelled => 'SALE RECEIPT (CANCELLED)';

  @override
  String get saleDetailReceiptPayment => 'Payment';

  @override
  String get saleDetailReceiptThanks => 'Thank you for your purchase!';

  @override
  String get adminTitle => 'Super Admin Panel';

  @override
  String get adminNavRequests => 'Requests';

  @override
  String get adminNavPlans => 'Plans';

  @override
  String get adminNavUpgrades => 'Upgrades';

  @override
  String get adminTenantsTitle => 'Tenants';

  @override
  String get adminPendingOnly => 'Pending';

  @override
  String get adminAll => 'All';

  @override
  String adminAwaitingCount(int count) {
    return '$count awaiting approval';
  }

  @override
  String get adminTenantsEmpty => 'No tenants registered yet.';

  @override
  String get adminRequestsLoadError => 'Could not load the requests.';

  @override
  String get adminNothingPendingTitle => 'Nothing pending';

  @override
  String get adminNothingPendingSubtitle => 'New requests will appear here.';

  @override
  String get adminTenantsLoadError => 'Could not load the tenants.';

  @override
  String get adminRejectError => 'Could not reject the request.';

  @override
  String get adminApproveError => 'Could not approve the request.';

  @override
  String adminAccessApproved(String name) {
    return '$name\'s access approved!';
  }

  @override
  String adminRequestRejected(String name) {
    return '$name\'s request rejected.';
  }

  @override
  String adminRejectTitle(String name) {
    return 'Reject $name';
  }

  @override
  String get adminRejectReasonLabel => 'Rejection reason';

  @override
  String get adminRejectReasonHint => 'e.g. incomplete registration info';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminReject => 'Reject';

  @override
  String adminPlanLabel(String plan) {
    return 'Plan: $plan';
  }

  @override
  String adminPlanSolicited(String plan, String date) {
    return 'Plan: $plan · Requested: $date';
  }

  @override
  String get adminPlansTitle => 'Plans';

  @override
  String get adminPlanNewTooltip => 'New plan';

  @override
  String get adminPlansLoadError => 'Could not load the plans.';

  @override
  String get adminPlansEmptyTitle => 'No plans created';

  @override
  String get adminPlansEmptySubtitle =>
      'Create the first plan to enable subscriptions.';

  @override
  String get adminPlanInactive => 'Inactive';

  @override
  String adminPlanDetails(String price, int stores, int employees) {
    return '$price/mo · $stores store(s) · $employees employee(s)';
  }

  @override
  String get adminPlanNameError => 'Enter the plan name.';

  @override
  String get adminPlanPriceError => 'Enter a valid price (≥ 0).';

  @override
  String get adminPlanStoresError => 'Plan must allow at least 1 store.';

  @override
  String get adminPlanEmployeesError => 'Plan must allow at least 1 employee.';

  @override
  String adminPlanCreated(String name) {
    return 'Plan $name created!';
  }

  @override
  String adminPlanUpdated(String name) {
    return 'Plan $name updated!';
  }

  @override
  String get adminPlanSaveError => 'Could not save the plan. Try again.';

  @override
  String get adminPlanNewTitle => 'New plan';

  @override
  String get adminPlanEditTitle => 'Edit plan';

  @override
  String get adminPlanNameLabel => 'Plan name';

  @override
  String get adminPlanPriceLabel => 'Monthly price';

  @override
  String get adminPlanMaxStores => 'Max. stores';

  @override
  String get adminPlanMaxEmployees => 'Max. employees';

  @override
  String get adminPlanActiveTitle => 'Active plan';

  @override
  String get adminPlanActiveSubtitle => 'Disable to prevent new subscriptions.';

  @override
  String get adminPlanCreate => 'Create plan';

  @override
  String get adminUpgradesTitle => 'Plan upgrades';

  @override
  String get adminUpgradesLoadError => 'Could not load the upgrade requests.';

  @override
  String get adminUpgradesEmptyTitle => 'No pending upgrades';

  @override
  String get adminUpgradesEmptySubtitle => 'Plan change requests appear here.';

  @override
  String get adminUpgradeApproved => 'Upgrade approved — plan updated!';

  @override
  String get adminUpgradeRejected => 'Upgrade rejected.';

  @override
  String get adminUpgradeProcessError => 'Could not process the request.';

  @override
  String get adminPlanRequested => 'Requested';

  @override
  String get adminPlanCurrent => 'Current';

  @override
  String get productsExpiryHelp => 'Product expiry date';

  @override
  String get salesBarcodeLabel => 'Barcode';

  @override
  String get salesBarcodeHint => 'Scale labels and PLUs — camera or USB reader';

  @override
  String get salesBarcodeScan => 'Scan with camera';

  @override
  String get salesBarcodeNotFound => 'Product not found for this code.';

  @override
  String get salesBarcodeInvalid => 'Invalid scale code.';

  @override
  String salesStockLimit(String product) {
    return 'Stock limit reached for $product.';
  }

  @override
  String get salesQuantityLabel => 'Quantity';

  @override
  String get salesQuantityHint => 'Quantity (e.g. 1.75)';

  @override
  String get purchasesExpiryLabel => 'Expiry';

  @override
  String get purchasesExpiryAdd => 'Set expiry';

  @override
  String get purchasesExpiryHelp => 'Batch expiry date';

  @override
  String get dashboardExpiryAlerts => 'Expiry';

  @override
  String dashboardExpiredIn(int days) {
    return 'Expired $days day(s) ago';
  }

  @override
  String dashboardExpiresIn(int days) {
    return 'Expires in $days day(s)';
  }
}
