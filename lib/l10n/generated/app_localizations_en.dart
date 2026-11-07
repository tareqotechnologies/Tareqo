// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get onboardingCurrencyLabel => 'Currency';

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
      'Sign-in, stores, products, sales, credit and reports';

  @override
  String get supportTroubleshooting => 'Troubleshooting';

  @override
  String get supportTroubleshootingHint =>
      'Resolve sign-in, sales, stock and connection issues';

  @override
  String get supportReadingError => 'Could not open the document.';

  @override
  String get supportSearchHint => 'Search help';

  @override
  String get supportContactSupport => 'Contact support';

  @override
  String get supportContactSupportHint => 'Our team can help you';

  @override
  String get supportHelpCenter => 'Help center';

  @override
  String get supportContactMessage => 'Hi! I need help with TAREQO.';

  @override
  String get supportOpenError => 'Could not open support.';

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
  String storeSwitcherA11yLabel(String store) {
    return 'Store: $store';
  }

  @override
  String get storeSelectorSectionTitle => 'Active store';

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
  String get authErrorCheckConnection => 'Check your connection and try again.';

  @override
  String get authErrorLoadAccount => 'Account not loaded';

  @override
  String get splashLoading => 'Opening your session…';

  @override
  String get appLockTitle => 'TAREQO is locked';

  @override
  String get appLockMessage =>
      'Touch the sensor or use facial recognition to unlock TAREQO.';

  @override
  String get appLockUnlock => 'Unlock';

  @override
  String get appLockError => 'Couldn\'t authenticate. Try again or sign out.';

  @override
  String get biometricSignInTitle => 'Biometric Authentication';

  @override
  String get biometricHint => 'Touch the sensor';

  @override
  String get biometricCancel => 'Cancel';

  @override
  String get biometricFallbackTitle => 'Use password';

  @override
  String get biometricGoToSettingsButton => 'Settings';

  @override
  String get biometricGoToSettingsDescription =>
      'Set up biometric authentication';

  @override
  String get biometricLockOut => 'Try again later';

  @override
  String get biometricReason => 'Biometric authentication';

  @override
  String get loginSubtitleSignUp => 'Create your account to get started';

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
  String get loginConfirmError => 'Passwords do not match.';

  @override
  String get loginSignUp => 'Sign up';

  @override
  String get loginSignIn => 'Sign in';

  @override
  String get loginSignUpSuccess =>
      'Account created! Confirm your email to sign in.';

  @override
  String get loginSignUpError => 'Could not create the account. Try again.';

  @override
  String get loginNoConnection =>
      'No internet connection. Check your Wi-Fi/mobile data and try again.';

  @override
  String get loginSignInError =>
      'Could not sign in. Check your email and password.';

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
  String get setNewPasswordSamePassword =>
      'The new password must be different from the current one.';

  @override
  String get setNewPasswordSessionExpired =>
      'The recovery link expired or was already used. Request a new link.';

  @override
  String get setNewPasswordRateLimited =>
      'Too many attempts. Wait a moment and try again.';

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
  String get passwordSameAsCurrent =>
      'The new password must be different from the current one.';

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
  String syncErrorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count with errors',
      one: '1 with error',
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
  String get dashboardOwnerFallback => 'Owner';

  @override
  String get commonUnits => 'u.';

  @override
  String get dashboardQuickActions => 'Quick actions';

  @override
  String get dashboardModuleCustomers => 'Customers';

  @override
  String get dashboardModulePurchases => 'Purchases';

  @override
  String get dashboardModuleReports => 'Reports';

  @override
  String get dashboardModuleStores => 'Stores';

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
  String get employeesUpdateError =>
      'Could not update the employee. Try again.';

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
  String get addStorePhoneLabel => 'Phone (optional)';

  @override
  String get addStoreEmailLabel => 'Email (optional)';

  @override
  String get addStoreNuitLabel => 'Tax ID (optional)';

  @override
  String get addStoreCityLabel => 'City (optional)';

  @override
  String get storeDetailPhone => 'Phone';

  @override
  String get storeDetailEmail => 'Email';

  @override
  String get storeDetailNuit => 'Tax ID';

  @override
  String get storeDetailCity => 'City';

  @override
  String get storeDetailAddress => 'Address';

  @override
  String addStoreSuccess(String name) {
    return 'Store $name created!';
  }

  @override
  String get addStoreError => 'Could not create the store. Try again.';

  @override
  String get addStoreSubmit => 'Create store';

  @override
  String get editStoreTitle => 'Edit store';

  @override
  String get editStoreSubmit => 'Save changes';

  @override
  String editStoreSuccess(String name) {
    return 'Store $name updated!';
  }

  @override
  String get editStoreError => 'Could not update the store. Try again.';

  @override
  String get editStoreAction => 'Edit';

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
  String get commonUndo => 'Undo';

  @override
  String get commonCopied => 'Copied to clipboard';

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
  String get productsFilterAll => 'All';

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
  String get productsSalePrice => 'Sale price';

  @override
  String get productsStockQuantity => 'Stock quantity';

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
  String get productsInactive => 'Inactive';

  @override
  String get productsFilterTooltip => 'Filter';

  @override
  String get productsFilterAdvanced => 'Advanced filters';

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
  String get productsTypeLabel => 'Product type';

  @override
  String get productsTypeRawMaterial => 'Raw material';

  @override
  String get productsTypeResale => 'Resale';

  @override
  String get productsTypeManufactured => 'Manufactured';

  @override
  String get productsTypeComposite => 'Composite';

  @override
  String get productsTypePackaging => 'Packaging';

  @override
  String get productsFilterType => 'Type';

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
  String get productsPhotoTake => 'Take photo';

  @override
  String get productsPhotoGallery => 'Choose from gallery';

  @override
  String get productsPhotoRemove => 'Remove photo';

  @override
  String get productsPhotoRemoveConfirm =>
      'Delete the product photo? The current image will be removed on save.';

  @override
  String get productsPhotoTitle => 'Product photo';

  @override
  String get productsPhotoAdd => 'Add photo';

  @override
  String get productsPhotoChangeHint => 'Tap to change';

  @override
  String get productsPhotoOptionalHint => 'Optional — camera or gallery';

  @override
  String get productsPurchasePriceError => 'Enter purchase price';

  @override
  String get productsSalePriceError => 'Enter sale price';

  @override
  String get productsStockError => 'Invalid quantity';

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
  String get purchaseDetailTitle => 'Purchase details';

  @override
  String get purchaseDetailSupplier => 'Supplier';

  @override
  String get purchaseDetailDate => 'Date and time';

  @override
  String get purchaseDetailPayment => 'Payment';

  @override
  String get purchaseDetailExpiry => 'Batch expiry';

  @override
  String get purchaseDetailNoExpiry => 'No expiry';

  @override
  String get purchaseDetailStockNote => 'Stock updated via FIFO batch.';

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
  String get purchasesNoPurchasableTitle => 'No purchasable products';

  @override
  String get purchasesNoPurchasableSubtitle =>
      'Manufactured and composite products come from internal production. Only raw materials, resale and packaging items are bought.';

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
  String get financialPeriodBalance => 'Net period balance';

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
  String get debtsTitle => 'Credit';

  @override
  String get debtsHeaderSubtitle => 'Credit to receive and pay';

  @override
  String get debtsAddDebt => 'Register credit';

  @override
  String get debtsDataSection => 'Credit details';

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
  String salesCartItemRemoved(String name) {
    return 'Item removed from the cart: $name.';
  }

  @override
  String get salesLoadError => 'Could not load the sales.';

  @override
  String get salesEmptyTitle => 'No sales yet';

  @override
  String get salesEmptySubtitle => 'Tap \"New sale\" to record your first.';

  @override
  String get periodYesterday => 'Yesterday';

  @override
  String get periodWeek => 'This week';

  @override
  String get paymentFilterCard => 'Card';

  @override
  String get paymentFilterAll => 'All';

  @override
  String get salesStatusPaid => 'Paid';

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
  String get salesNoSellableTitle => 'No sellable products';

  @override
  String get salesNoSellableSubtitle =>
      'Raw materials and packaging are not sold at the counter. Change the product type to resale, manufactured or composite to sell it.';

  @override
  String get salesConfirm => 'Confirm sale';

  @override
  String get saleDetailTitle => 'Sale details';

  @override
  String saleDetailId(String id) {
    return 'Sale $id';
  }

  @override
  String get saleDetailView => 'View details';

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
  String get saleDetailCancelBiometricReason =>
      'Confirm your identity to cancel the sale.';

  @override
  String get saleDetailCancelBiometricFailed =>
      'Identity not confirmed. The sale was not cancelled.';

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
  String get adminPlansLoadError => 'Could not load the plans.';

  @override
  String get adminPlansEmptyTitle => 'No plans created';

  @override
  String get adminPlansEmptySubtitle =>
      'Create the first plan to enable subscriptions.';

  @override
  String get adminPlanInactive => 'Inactive';

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
  String get productsCodeLabel => 'Barcode (PLU)';

  @override
  String get productsCodeHint => 'Label scales (e.g. 12345)';

  @override
  String get productsCodeError => 'Invalid code: use up to 5 digits.';

  @override
  String get productsWeighLabel => 'Sell by weight (fraction)';

  @override
  String get productsWeighHint => 'Accepts decimal quantities (e.g. 1.75 kg)';

  @override
  String get productsUnitLabel => 'Unit of sale';

  @override
  String get productsStockWeightHint => 'In sale units (e.g. 1.75)';

  @override
  String get productsExpiryLabel => 'Expiry';

  @override
  String get productsExpiryAdd => 'Set expiry';

  @override
  String get productsExpiryHelp => 'Product expiry date';

  @override
  String get productsExpiryClear => 'Remove expiry';

  @override
  String get salesBarcodeLabel => 'Barcode';

  @override
  String get salesBarcodeHint => 'Scale labels and PLUs — camera or USB reader';

  @override
  String get salesBarcodeScan => 'Scan with camera';

  @override
  String get salesBarcodeCameraHint => 'Point the camera at the barcode';

  @override
  String salesBarcodeCameraUnavailable(String error) {
    return 'Camera unavailable: $error';
  }

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
  String dashboardExpiredIn(int days) {
    return 'Expired $days day(s) ago';
  }

  @override
  String dashboardExpiresIn(int days) {
    return 'Expires in $days day(s)';
  }

  @override
  String get adminNavDashboard => 'Overview';

  @override
  String get adminNavAuditLog => 'Audit Log';

  @override
  String get adminDashboardTitle => 'Overview';

  @override
  String get adminDashboardTotalTenants => 'Total tenants';

  @override
  String get adminDashboardActiveTenants => 'Active';

  @override
  String get adminDashboardPendingTenants => 'Pending approval';

  @override
  String get adminDashboardPendingUpgrades => 'Pending upgrades';

  @override
  String get adminDashboardTotalPlans => 'Plans';

  @override
  String get adminDashboardLoadError => 'Could not load overview.';

  @override
  String get adminAuditLogEmpty => 'No actions recorded yet.';

  @override
  String get adminAuditLogEmptySubtitle => 'Admin actions will appear here.';

  @override
  String get adminTenantDetailOwner => 'Owner ID';

  @override
  String get adminTenantDetailPlan => 'Plan';

  @override
  String get adminTenantDetailStores => 'Stores';

  @override
  String get adminTenantDetailEmployees => 'Employees';

  @override
  String get adminTenantDetailStatus => 'Status';

  @override
  String get adminTenantDetailCreated => 'Created';

  @override
  String get adminTenantDetailCurrency => 'Currency';

  @override
  String get adminTenantDetailLanguage => 'Language';

  @override
  String get adminTenantDetailRejectionReason => 'Rejection reason';

  @override
  String get adminTenantDetailApprovedAt => 'Approved at';

  @override
  String adminTenantDetailStoresCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stores',
      one: '1 store',
    );
    return '$_temp0';
  }

  @override
  String adminTenantDetailEmployeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count employees',
      one: '1 employee',
    );
    return '$_temp0';
  }

  @override
  String get adminTenantSearchHint => 'Search tenants...';

  @override
  String get adminTenantDetailNoStores => 'No stores created';

  @override
  String get adminTenantDetailNoEmployees => 'No employees linked';

  @override
  String get adminTenantDetailActivity => 'Recent activity';

  @override
  String get adminTenantDetailNoActivity =>
      'No recent activity for this tenant';

  @override
  String adminTenantDetailActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recent actions',
      one: '1 recent action',
    );
    return '$_temp0';
  }

  @override
  String adminTenantDetailEmployeeRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'manager': 'Manager',
      'other': 'Employee',
    });
    return '$_temp0';
  }

  @override
  String get adminAuditLogAction => 'Action';

  @override
  String get adminAuditLogEntity => 'Entity';

  @override
  String get adminAuditLogDate => 'Date';

  @override
  String get adminAuditLogActor => 'Actor';

  @override
  String get adminBulkSelectAll => 'Select all';

  @override
  String get adminBulkDeselectAll => 'Deselect all';

  @override
  String adminBulkApprove(Object count) {
    return 'Approve ($count)';
  }

  @override
  String adminBulkReject(Object count) {
    return 'Reject ($count)';
  }

  @override
  String adminBulkRejectTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants',
      one: 'tenant',
    );
    return 'Reject $count $_temp0';
  }

  @override
  String adminBulkApproveSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants approved',
      one: 'tenant approved',
    );
    return '$count $_temp0';
  }

  @override
  String adminBulkRejectSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants rejected',
      one: 'tenant rejected',
    );
    return '$count $_temp0';
  }

  @override
  String get adminBulkApproveError =>
      'Error approving tenants. Some may not have been processed.';

  @override
  String get adminBulkRejectError =>
      'Error rejecting tenants. Some may not have been processed.';

  @override
  String get adminActionManagePlans => 'Manage Plans';

  @override
  String get adminActionViewAuditLog => 'View Audit Log';

  @override
  String get adminTenantRequests => 'Tenant Requests';

  @override
  String get adminPlanUpgrades => 'Plan Upgrades';

  @override
  String adminPendingActionRequired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions required',
      one: '1 action required',
    );
    return '$_temp0';
  }

  @override
  String get adminAuditLogAll => 'All';

  @override
  String get adminAuditLogTenants => 'Tenants';

  @override
  String get adminAuditLogPlans => 'Plans';

  @override
  String get adminAuditLogUpgrades => 'Upgrades';

  @override
  String get adminAuditLogApproved => 'Approved';

  @override
  String get adminAuditLogRejected => 'Rejected';

  @override
  String get adminAuditLogToday => 'Today';

  @override
  String get adminAuditLogYesterday => 'Yesterday';

  @override
  String get adminAuditLogThisWeek => 'This week';

  @override
  String get adminAuditLogOlder => 'Older';

  @override
  String get adminAuditLogSearchHint => 'Search audit log...';

  @override
  String get adminAuditLogNoResults => 'No entries match your filter.';

  @override
  String get adminDashboardPlanDistribution => 'Plan distribution';

  @override
  String get adminDashboardRecentActivity => 'Recent activity';

  @override
  String get adminGrowthTrends => 'Growth Trends';

  @override
  String get adminGrowthTrendsLabel => 'Trends (8 weeks)';

  @override
  String get adminGrowthThisWeek => 'This week';

  @override
  String get adminGrowthLastWeek => 'Last week';

  @override
  String get adminGrowthThisMonth => 'This month';

  @override
  String get adminGrowthLastMonth => 'Last month';

  @override
  String get adminGrowthNewTenants => 'New tenants';

  @override
  String get adminGrowthNewTenantsMonth => 'New tenants this month';

  @override
  String get adminGrowthApprovals => 'Approvals';

  @override
  String adminGrowthUp(String count) {
    return '+$count';
  }

  @override
  String adminGrowthDown(String count) {
    return '-$count';
  }

  @override
  String get adminGrowthFlat => 'No change';

  @override
  String get adminGrowthRegistrationsTrend => 'Registrations (last 8 weeks)';

  @override
  String get adminGrowthActivityTrend => 'Activity (last 8 weeks)';

  @override
  String get adminGrowthNoData => 'Not enough data to show trends';

  @override
  String get adminNavInvoices => 'Invoices';

  @override
  String get adminInvoicesTitle => 'Billing Invoices';

  @override
  String get adminInvoicesEmpty => 'No invoices generated yet.';

  @override
  String get adminInvoicesEmptyPending => 'No pending invoices.';

  @override
  String get adminInvoicesLoadError => 'Could not load the invoices.';

  @override
  String get adminInvoiceSearchHint => 'Search invoices...';

  @override
  String get adminInvoiceAmount => 'Amount:';

  @override
  String get adminInvoiceDue => 'Due:';

  @override
  String get adminInvoicePaidAt => 'Paid on:';

  @override
  String get adminInvoiceMarkPaid => 'Mark as paid';

  @override
  String get adminInvoiceMarkedPaid => 'Invoice marked as paid!';

  @override
  String get adminInvoiceMarkPaidError => 'Could not mark as paid. Try again.';

  @override
  String get adminInvoiceCancel => 'Cancel';

  @override
  String get adminInvoiceCancelled => 'Invoice cancelled.';

  @override
  String get adminInvoiceCancelError =>
      'Could not cancel the invoice. Try again.';

  @override
  String get adminInvoiceCancelTitle => 'Cancel invoice?';

  @override
  String adminInvoiceCancelConfirm(String period) {
    return 'Cancel the invoice for $period?';
  }

  @override
  String get adminInvoiceCancelConfirmButton => 'Yes, cancel';

  @override
  String get invoiceStatusPending => 'Pending';

  @override
  String get invoiceStatusPaid => 'Paid';

  @override
  String get invoiceStatusExpired => 'Expired';

  @override
  String get invoiceStatusCancelled => 'Cancelled';

  @override
  String get notificationInvoiceGenerated => 'New invoice generated';

  @override
  String get notificationInvoiceDueSoon => 'Invoice due soon';

  @override
  String get notificationInvoiceExpired => 'Invoice expired';

  @override
  String get notificationInvoicePaid => 'Invoice paid';

  @override
  String get notificationMarkAllRead => 'Mark all as read';

  @override
  String get notificationMarkRead => 'Mark as read';

  @override
  String get notificationNoNotifications => 'No notifications';

  @override
  String get notificationNoNotificationsHint =>
      'You\'ll see invoice notifications here.';

  @override
  String get notificationTabAll => 'All';

  @override
  String get notificationTabUnread => 'Unread';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get menuNotifications => 'Notifications';

  @override
  String notificationSinceDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get notificationYesterday => 'Yesterday';

  @override
  String get notificationJustNow => 'Just now';

  @override
  String get notificationAdminLabelQuote => 'Quote';

  @override
  String get notificationAdminLabelValidity => 'Validity';

  @override
  String get notificationAdminLabelExpiring => 'Expiring';

  @override
  String get notificationAdminLabelGeneral => 'General';

  @override
  String get notificationAddonExpiringTitle => 'Add-on expiring soon';

  @override
  String get notificationAddonExpiredTitle => 'Add-on expired';

  @override
  String notificationBodyInvoiceGenerated(
    String period,
    String amount,
    String currency,
    String dueDate,
  ) {
    return 'Invoice $period for $amount $currency. Due on $dueDate.';
  }

  @override
  String notificationBodyInvoiceDueSoon(
    String period,
    String amount,
    String currency,
    int days,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Invoice $period for $amount $currency is due in $_temp0. Please settle the payment.';
  }

  @override
  String notificationBodyInvoiceExpired(
    String period,
    String amount,
    String currency,
  ) {
    return 'Invoice $period for $amount $currency expired without payment. Access may be suspended.';
  }

  @override
  String notificationBodyInvoicePaid(
    String period,
    String amount,
    String currency,
  ) {
    return 'Invoice $period for $amount $currency was marked as paid. Thank you!';
  }

  @override
  String notificationBodyAddOnExpired(String addonName, String date) {
    return 'The \"$addonName\" add-on expired on $date. Renew the subscription to keep using it.';
  }

  @override
  String notificationBodyAddOnExpiringSoon(
    String addonName,
    int days,
    String date,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'The \"$addonName\" add-on expires in $_temp0 ($date). Renew to avoid interruption.';
  }

  @override
  String get notificationIconInvoice => 'Invoice';

  @override
  String get notificationIconDue => 'Due';

  @override
  String get notificationIconExpired => 'Expired';

  @override
  String get notificationIconPaid => 'Paid';

  @override
  String get notificationIconExpiring => 'Expiring';

  @override
  String get notificationIconExpiredShort => 'Expired';

  @override
  String notificationDaysShort(int days) {
    return '${days}d';
  }

  @override
  String get adminMessagesTitle => 'Messages to Tenants';

  @override
  String get adminMessagesSendSuccess => 'Message sent!';

  @override
  String get adminMessagesSendError => 'Could not send the message. Try again.';

  @override
  String get adminMessagesTenantLabel => 'Tenant';

  @override
  String get adminMessagesTenantError => 'Select a tenant.';

  @override
  String get adminMessagesTypeLabel => 'Type';

  @override
  String get adminMessagesTitleLabel => 'Title';

  @override
  String get adminMessagesTitleError => 'Enter a title.';

  @override
  String get adminMessagesBodyLabel => 'Message';

  @override
  String get adminMessagesBodyError => 'Enter the message body.';

  @override
  String get adminMessagesSubmit => 'Send';

  @override
  String get adminNavMessages => 'Messages';

  @override
  String get customInvoiceTitle => 'Custom Invoice';

  @override
  String get customInvoiceEmpty => 'No invoices';

  @override
  String get customInvoiceEmptySubtitle =>
      'Create professional invoices with a custom\nlayout for your clients';

  @override
  String get customInvoiceLoadError => 'Couldn\'t load the invoices.';

  @override
  String get customInvoiceLoadErrorHint =>
      'Check your connection and try again.';

  @override
  String customInvoiceCreated(int number) {
    return 'Invoice #$number created!';
  }

  @override
  String get customInvoiceSaveError =>
      'Couldn\'t create the invoice. Try again.';

  @override
  String get customInvoiceTemplateTooltip => 'Invoice template';

  @override
  String get customInvoiceNewFab => 'New Invoice';

  @override
  String customInvoiceItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get customInvoiceWhatsApp => 'WhatsApp';

  @override
  String get customInvoiceCreate => 'Create Invoice';

  @override
  String get customInvoiceClientSection => 'Client';

  @override
  String get customInvoiceClientName => 'Client name';

  @override
  String get customInvoicePhone => 'Phone';

  @override
  String get customInvoiceTaxIdOptional => 'Tax ID / NUIT (optional)';

  @override
  String get customInvoiceProductSection => 'Product';

  @override
  String get customInvoiceProductPlaceholder => 'No products registered';

  @override
  String customInvoiceProductOption(Object price, Object stock, Object unit) {
    return 'Stock: $stock $unit  •  $price';
  }

  @override
  String get customInvoicePrice => 'Price (MT)';

  @override
  String get customInvoiceQty => 'Qty';

  @override
  String get customInvoiceAddItem => 'Add';

  @override
  String get customInvoiceDiscount => 'Discount (MT)';

  @override
  String get customInvoiceTax => 'VAT (MT)';

  @override
  String customInvoiceBillTotal(Object total) {
    return 'Total: $total';
  }

  @override
  String customInvoiceNumberPrefix(Object number) {
    return 'No. $number';
  }

  @override
  String get customInvoiceTemplateSaved => 'Template saved successfully';

  @override
  String get customInvoiceTemplateLogoSection => 'Company logo';

  @override
  String get customInvoiceTemplateLogoHint => 'Tap to upload a logo';

  @override
  String get customInvoiceTemplateColorSection => 'Primary colour';

  @override
  String get customInvoiceTemplateCompanySection => 'Company details';

  @override
  String get customInvoiceTemplateCompanyName => 'Company name';

  @override
  String get customInvoiceTemplateAddress => 'Address';

  @override
  String get customInvoiceTemplateTaxId => 'Tax ID / NUIT';

  @override
  String get customInvoiceTemplateStyle => 'Style';

  @override
  String get customInvoiceTemplateStyleClassic => 'Classic';

  @override
  String get customInvoiceTemplateStyleModern => 'Modern';

  @override
  String get customInvoiceTemplateStyleCompact => 'Compact';

  @override
  String get customInvoiceTemplateSave => 'Save Template';

  @override
  String get customInvoicePreviewCompanyFallback => 'Company name';

  @override
  String get customInvoicePreviewSampleItemA => 'Product A';

  @override
  String get customInvoicePreviewSampleItemB => 'Product B';

  @override
  String get customInvoicePreviewSampleClient => 'João Silva';

  @override
  String customInvoicePreviewTotal(String total) {
    return 'TOTAL: $total';
  }

  @override
  String get customInvoicePreviewFooter => 'Generated by TAREQO';

  @override
  String get quotationTitle => 'Quotations';

  @override
  String get quotationEmpty => 'No quotations';

  @override
  String get quotationEmptySubtitle =>
      'Create quotations and estimates for your clients';

  @override
  String get quotationLoadError => 'Couldn\'t load the quotations.';

  @override
  String get quotationLoadErrorHint => 'Check your connection and try again.';

  @override
  String quotationCreated(int number) {
    return 'Quotation #$number created!';
  }

  @override
  String get quotationSaveError => 'Couldn\'t create the quotation. Try again.';

  @override
  String get quotationStatusSaved => 'Quotation status updated';

  @override
  String get quotationStatusError =>
      'Couldn\'t update the quotation. Try again.';

  @override
  String get quotationTemplateTooltip => 'Quotation template';

  @override
  String get quotationNewFab => 'New Quotation';

  @override
  String quotationItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get quotationValidity => 'Validity';

  @override
  String quotationDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get quotationSend => 'Send';

  @override
  String get quotationAccept => 'Accept';

  @override
  String get quotationReject => 'Reject';

  @override
  String get quotationStatusDraft => 'Draft';

  @override
  String get quotationStatusSent => 'Sent';

  @override
  String get quotationStatusAccepted => 'Accepted';

  @override
  String get quotationStatusRejected => 'Rejected';

  @override
  String get quotationPhoneOptional => 'Phone (optional)';

  @override
  String quotationNumberPrefix(Object number) {
    return 'No. $number';
  }

  @override
  String get quotationSave => 'Save Quotation';

  @override
  String get quotationTemplatePhone => 'Phone';

  @override
  String get quotationTemplatePreview => 'Quotation • Preview';

  @override
  String get quotationTemplatePreviewBadge => 'Preview';

  @override
  String get palettePetrol => 'Petrol blue';

  @override
  String get paletteSlate => 'Slate';

  @override
  String get paletteTerracotta => 'Terracotta';

  @override
  String get paletteBeige => 'Beige';

  @override
  String get paletteWarmGray => 'Warm gray';

  @override
  String get palettePetrolInk => 'Petrol ink';

  @override
  String get paletteSlateInk => 'Slate ink';

  @override
  String get paletteSoftBlack => 'Soft black';

  @override
  String get customInvoicePdf => 'PDF';

  @override
  String get imageSourceGallery => 'Gallery';

  @override
  String get imageSourceCamera => 'Camera';

  @override
  String get businessFallbackName => 'My Business';

  @override
  String get customInvoiceWhatsAppHeader => '═══ INVOICE ═══';

  @override
  String get customInvoiceNumberShort => 'No.';

  @override
  String get customInvoiceClientLabel => 'Client';

  @override
  String get customInvoicePhoneLabel => 'Tel';

  @override
  String get customInvoiceTotalLabel => 'TOTAL';

  @override
  String get customInvoiceNew => 'New Invoice';

  @override
  String get customInvoiceTemplateTitle => 'Invoice template';

  @override
  String get commonPreview => 'Preview';

  @override
  String get quotationWhatsAppHeader => '═══ QUOTATION ═══';

  @override
  String get quotationTemplateTitle => 'Quotation template';

  @override
  String get employeeMgmtTitle => 'Employee Management';

  @override
  String get employeeMgmtTabAttendance => 'Attendance';

  @override
  String get employeeMgmtTabCommissions => 'Commissions';

  @override
  String get employeeMgmtTabTargets => 'Targets';

  @override
  String get employeePresentCount => 'Present';

  @override
  String get employeeAbsentCount => 'Absent';

  @override
  String get employeeClockInAction => 'Clock in';

  @override
  String get employeeClockOutAction => 'Clock out';

  @override
  String get employeeClockOutInProgress => 'In progress';

  @override
  String get employeeAttendanceSection => 'Time Records';

  @override
  String get employeeRecordsSection => 'Today\'s Records';

  @override
  String get employeeAttendanceEmpty =>
      'No employees linked to this store. Create accounts in the Stores module.';

  @override
  String get employeeMgmtLoadError => 'Unable to load employee data.';

  @override
  String get employeeMgmtNoStoreTitle => 'No active store';

  @override
  String get employeeMgmtNoStoreAttendance =>
      'Complete onboarding to clock in.';

  @override
  String get employeeMgmtNoStoreCommissions =>
      'Complete onboarding to view commissions.';

  @override
  String get employeeMgmtNoStoreTargets =>
      'Complete onboarding to set targets.';

  @override
  String get employeeClockInError => 'Unable to record clock in.';

  @override
  String get employeeClockOutError => 'Unable to record clock out.';

  @override
  String get employeeSalesMonth => 'Monthly Sales';

  @override
  String get employeeCommissionTitle => 'Commissions';

  @override
  String get employeeCommissionPerEmployee => 'Commission per Employee';

  @override
  String employeeCommissionRate(int rate, String amount) {
    return '$rate% of $amount';
  }

  @override
  String get employeeCommissionNoRate => 'No rate set';

  @override
  String get employeeCommissionSetRate => 'Set Rate';

  @override
  String get employeeCommissionRateLabel => 'Commission rate (%)';

  @override
  String get employeeCommissionRateSaved => 'Commission rate updated.';

  @override
  String get employeeCommissionRateError => 'Unable to save the rate.';

  @override
  String get employeeTargetsActive => 'Active Targets';

  @override
  String get employeeTargetsReached => 'Reached';

  @override
  String get employeeTargetsPending => 'Pending';

  @override
  String get employeeTargetsMonth => 'Month\'s Targets';

  @override
  String get employeeTargetsEmptyTitle => 'No targets set';

  @override
  String get employeeTargetsEmptySubtitle =>
      'Set monthly sales targets for each employee';

  @override
  String get employeeTargetAdd => 'Add Target';

  @override
  String employeeTargetMeta(String amount) {
    return 'Target: $amount';
  }

  @override
  String get employeeTargetNewTitle => 'New Target';

  @override
  String get employeeTargetEmployee => 'Employee';

  @override
  String get employeeTargetAllHave => 'All employees already have a target set';

  @override
  String get employeeTargetMonthly => 'Monthly Target (MT)';

  @override
  String get employeeTargetSave => 'Save Target';

  @override
  String employeeTargetProgress(int progress) {
    return '$progress% of target';
  }

  @override
  String get employeeTargetSaved => 'Target set.';

  @override
  String get employeeTargetRemoved => 'Target removed.';

  @override
  String get employeeTargetError => 'Unable to save the target.';

  @override
  String get employeeRoleSales => 'Salesperson';

  @override
  String get addonsTitle => 'Add-ons';

  @override
  String get addonsSubtitle => 'Active add-ons and add-ons in your plan';

  @override
  String get addonsManagedByAdmin =>
      'Add-on activation is managed by the system administrator.';

  @override
  String get addonsIncluded => 'Included';

  @override
  String get addonsActive => 'Active';

  @override
  String addonsPerMonth(Object amount) {
    return '$amount MT/month';
  }

  @override
  String get addonCategoryInvoicing => 'Invoicing';

  @override
  String get addonCategoryQuotation => 'Quotations';

  @override
  String get addonCategoryReports => 'Reports';

  @override
  String get addonCategoryEmployees => 'Employees';

  @override
  String get addonCategoryMultiStore => 'Multi-store';

  @override
  String get addonCategoryPayments => 'Payments';

  @override
  String get commonTotal => 'Total';

  @override
  String get addonCustomInvoiceName => 'Custom Invoice';

  @override
  String get addonCustomInvoiceDesc =>
      'Create professional invoices with a logo, custom layout and PDF export. Includes ready-made templates and customization of colours, fonts and fields.';

  @override
  String get addonQuotationName => 'Quotation / Estimate';

  @override
  String get addonQuotationDesc =>
      'Create and send quotations and estimates to clients before the sale. Includes automatic conversion to a sale, configurable validity and SMS/WhatsApp delivery.';

  @override
  String get addonReportsName => 'Advanced Reports';

  @override
  String get addonReportsDesc =>
      'Financial, sales and stock reports with advanced filters, period-over-period comparisons and PDF/Excel export. Includes interactive charts and custom dashboards.';

  @override
  String get addonEmployeesName => 'Employee Management';

  @override
  String get addonEmployeesDesc =>
      'Time tracking (clock in/out), automatic sales-commission calculation, monthly target setting and individual performance reports.';

  @override
  String get addonMultiStoreName => 'Advanced Multi-store';

  @override
  String get addonMultiStoreDesc =>
      'Stock transfers between stores, consolidated store-comparison reports, centralised price and promotion management and automatic restock alerts.';

  @override
  String get addonMobileMoneyName => 'M-Pesa / E-Mola Integration';

  @override
  String get addonMobileMoneyDesc =>
      'Automatic mobile-money payments with automatic reconciliation, real-time receipt notifications and a mobile-money transaction report.';

  @override
  String get transfersTitle => 'Store Transfers';

  @override
  String get transfersEmpty => 'No transfers';

  @override
  String get transfersEmptySubtitle =>
      'Transfer stock between stores of the\nsame tenant with full traceability';

  @override
  String get transfersNewFab => 'New Transfer';

  @override
  String get transfersOriginStore => 'Origin store';

  @override
  String get transfersDestStore => 'Destination store';

  @override
  String get transfersProduct => 'Product';

  @override
  String get transfersProductPlaceholder => 'No products registered';

  @override
  String get transfersQuantity => 'Quantity';

  @override
  String get transfersAddItem => 'Add';

  @override
  String get transfersExecuting => 'Transferring...';

  @override
  String get transfersExecute => 'Execute Transfer';

  @override
  String get transfersNoStoresTitle => 'Register at least 2 stores';

  @override
  String get transfersNoStoresSubtitle =>
      'You need 2+ stores to\ntransfer stock between them';

  @override
  String transfersSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products transferred',
      one: '1 product transferred',
    );
    return '$_temp0 successfully';
  }

  @override
  String transfersError(Object error) {
    return 'Transfer error: $error';
  }

  @override
  String get transferStatusPending => 'Pending';

  @override
  String get transferStatusInTransit => 'In transit';

  @override
  String get transferStatusReceived => 'Received';

  @override
  String get transferStatusCancelled => 'Cancelled';

  @override
  String get paymentsTitle => 'M-Pesa / E-Mola';

  @override
  String get paymentsIntegrationBlocked =>
      'M-Pesa/E-Mola integration is not configured yet — real reconciliation requires the provider API. Until then, the data shown here is local and demonstrative.';

  @override
  String get reportsAdvancedTitle => 'Advanced Reports';

  @override
  String get reportsTabSales => 'Sales';

  @override
  String get reportsTabFinancial => 'Financial';

  @override
  String get reportsTabStock => 'Stock';

  @override
  String get reportsKpiProducts => 'Products';

  @override
  String get reportsKpiLowStock => 'Low Stock';

  @override
  String get reportsKpiStockValue => 'Stock Value';

  @override
  String get reportsKpiRevenue => 'Revenue';

  @override
  String get reportsKpiExpenses => 'Expenses';

  @override
  String get reportsKpiNetProfit => 'Net Profit';

  @override
  String get reportsCashFlow => 'Cash Flow';

  @override
  String get reportsCashFlowChart => 'Cash flow chart';

  @override
  String get reportsStockHealthy => 'All products have adequate stock';

  @override
  String get reportsExportSales => 'Export Report (PDF)';

  @override
  String get reportsExportFinancial => 'Export Financial (PDF)';

  @override
  String get reportsExportStock => 'Export Stock (PDF)';

  @override
  String get reportsNoSalesData => 'No data for this period';

  @override
  String get reportsPeriodYear => 'This Year';

  @override
  String get reportsKpiStockOut => 'Out of Stock';

  @override
  String get reportsKpiTotalProducts => 'Total Products';

  @override
  String pdfGeneratedOn(Object date) {
    return 'Generated: $date';
  }

  @override
  String get pdfIndicators => 'Indicators';

  @override
  String pdfFooter(Object date) {
    return 'Document generated by TAREQO — $date';
  }

  @override
  String get pdfInvoiceDocWord => 'INVOICE';

  @override
  String get pdfInvoiceSubjectWord => 'Invoice';

  @override
  String get pdfInvoiceFileBase => 'invoice';

  @override
  String get pdfQuotationDocWord => 'QUOTATION';

  @override
  String get pdfQuotationSubjectWord => 'Quotation';

  @override
  String get pdfQuotationFileBase => 'quotation';

  @override
  String get pdfClientHeading => 'CLIENT';

  @override
  String pdfPhoneLine(Object value) {
    return 'Phone: $value';
  }

  @override
  String pdfEmailLine(Object value) {
    return 'Email: $value';
  }

  @override
  String pdfNifLine(Object value) {
    return 'Tax ID: $value';
  }

  @override
  String get pdfItemHeader => 'Item';

  @override
  String get pdfUnitPriceHeader => 'Unit Price';

  @override
  String get pdfSubtotalHeader => 'Subtotal';

  @override
  String get pdfDiscountLabel => 'Discount';

  @override
  String get pdfTaxLabel => 'VAT';

  @override
  String pdfPaymentLine(Object value) {
    return 'Payment: $value';
  }

  @override
  String pdfReferenceLine(Object value) {
    return 'Ref: $value';
  }

  @override
  String get pdfNotesHeading => 'Notes';

  @override
  String get pdfGeneralConditionsHeading => 'General Conditions';

  @override
  String pdfValidityDaysLeft(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String pdfConditionValidBullet(Object date) {
    return 'This quotation is valid until $date.';
  }

  @override
  String get pdfConditionPricesBullet =>
      'Prices are subject to change after the validity period.';

  @override
  String get pdfConditionContactBullet =>
      'To accept this quotation, please contact us.';

  @override
  String get quotationStatusExpired => 'Expired';

  @override
  String get quotationStatusConverted => 'Converted to Sale';

  @override
  String get pdfConditionsNotesHeading => 'Conditions / Notes';

  @override
  String get adminAddonsActivateBtn => 'Activate';

  @override
  String get adminAddonsActivateBulk => 'Activate add-on';

  @override
  String get adminAddonsActivePill => 'Active';

  @override
  String get adminAddonsDeactivateBtn => 'Deactivate';

  @override
  String get adminAddonsInactivePill => 'Inactive';

  @override
  String adminAddonsLoadError(Object error) {
    return 'Error: $error';
  }

  @override
  String get adminAddonsNoTenantsSearchSub => 'Try another search term';

  @override
  String get adminAddonsNoTenantsTitle => 'No tenant found';

  @override
  String get adminAddonsNoTenantsYetSub => 'No approved tenants yet';

  @override
  String adminAddonsUpdateError(Object error) {
    return 'Error updating add-on: $error';
  }

  @override
  String get adminBackToList => 'Back to list';

  @override
  String get adminMessagesBodyHint => 'Write your message…';

  @override
  String get adminMessagesTenantHint => 'Select tenant...';

  @override
  String get adminMessagesTitleExample => 'E.g.: Pro Plan Quote';

  @override
  String get adminNavRevenue => 'Revenue';

  @override
  String get adminPlansActive => 'Active';

  @override
  String get adminPlansInactive => 'Inactive';

  @override
  String get adminRevenueActiveTenants => 'Active Tenants';

  @override
  String get adminRevenueActiveTenantsSub => 'Total on the platform';

  @override
  String get adminRevenueAvailableAddOns => 'Available Add-ons';

  @override
  String get adminRevenueAvailableAddOnsSub => 'In the active catalog';

  @override
  String get adminRevenueMaxMonthly => 'Max monthly revenue';

  @override
  String get adminRevenueMaxMonthlySub => 'If all activated everything';

  @override
  String get adminRevenuePotential => 'Potential Revenue';

  @override
  String get adminRevenuePotentialSub => 'Per tenant/month (all add-ons)';

  @override
  String get adminTenantsMonthlyValue => 'Monthly value';

  @override
  String get adminTenantsNextInvoice => 'Next invoice';

  @override
  String get adminTenantsPlanExpiresOn => 'Plan expires on';

  @override
  String get adminTenantsTrialEndsOn => 'Trial ends on';

  @override
  String get commonId => 'ID';

  @override
  String dashboardSaleEntry(Object number) {
    return 'Sale $number';
  }

  @override
  String get loginConfirmPasswordHint => 'Repeat your password';

  @override
  String get loginConfirmPasswordLabel => 'Confirm password';

  @override
  String get loginEmailHint => 'Enter your email';

  @override
  String get loginForgotPassword => 'Forgot your password?';

  @override
  String get loginNameHint => 'Enter your name';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginPromptHaveAccount => 'Already have an account?';

  @override
  String get loginPromptNoAccount => 'Don\'t have an account?';

  @override
  String get loginTagline => 'Simple management for your business';

  @override
  String get loginSecurityFooter => 'Your data is protected with encryption.';

  @override
  String get mfaCodeFieldLabel => 'MFA Code';

  @override
  String get mfaCodeHint =>
      'Enter the 6-digit code from your authenticator app:';

  @override
  String get mfaCodeLengthError => 'Enter the 6-digit code';

  @override
  String get mfaConfirmPrompt => 'Enter the app code to confirm:';

  @override
  String get mfaDigitsFieldLabel => '6-digit code';

  @override
  String mfaExpiresIn(num seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return 'Code expires in $_temp0';
  }

  @override
  String mfaInitError(Object error) {
    return 'Error initializing MFA: $error';
  }

  @override
  String get mfaInvalidCode => 'Invalid code. Try again.';

  @override
  String get mfaManualEntryTitle => 'Or enter this code manually:';

  @override
  String get mfaQrScanHelp =>
      'Use your authenticator app (Google Authenticator, Authy, etc.) to scan this QR code:';

  @override
  String get mfaQrScanTitle => 'Scan the QR Code';

  @override
  String get mfaSetupSuccess => 'MFA set up successfully!';

  @override
  String get mfaSetupTitle => 'Set Up Two-Factor Authentication';

  @override
  String get mfaVerify => 'Verify';

  @override
  String get mfaVerifyAndEnable => 'Verify and Enable';

  @override
  String mfaVerifyError(Object error) {
    return 'Error verifying code: $error';
  }

  @override
  String get securityBiometricDisabledSub =>
      'Use fingerprint or facial recognition';

  @override
  String get securityBiometricEnabledSub => 'Enabled — Fingerprint or face';

  @override
  String get securityBiometricTitle => 'Biometric Authentication';

  @override
  String get securityBiometricUnavailable => 'Not available on this device';

  @override
  String get securityTwoFactorDisabledSub => 'Add an extra security layer';

  @override
  String get securityTwoFactorEnabledSub =>
      'Enabled — Use an authenticator app';

  @override
  String get securityTwoFactorTitle => 'Two-Factor Authentication';

  @override
  String get settingsHapticsTitle => 'Haptic feedback';

  @override
  String get settingsHapticsSubtitle =>
      'Vibration when completing sales, payments and confirmations';

  @override
  String get a11yIncreaseQuantity => 'Increase quantity';

  @override
  String get a11yDecreaseQuantity => 'Decrease quantity';

  @override
  String get a11yAddFraction => 'Add 0.1 (weight)';

  @override
  String get settingsMfaEnforceError =>
      'Could not change the MFA requirement. Check your connection and try again.';

  @override
  String get settingsMfaEnforceSubOff =>
      'Off — sales and cash work with password only';

  @override
  String get settingsMfaEnforceSubOn =>
      'Enforced — money writes require your authenticator code';

  @override
  String get settingsMfaEnforceTitle => 'Require MFA for money operations';

  @override
  String get transfersRowDate => 'Date';

  @override
  String get transfersRowDest => 'Destination';

  @override
  String get transfersRowOrigin => 'Origin';

  @override
  String get transfersRowStatus => 'Status';

  @override
  String adminAddonsBulkActivated(Object addonName, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$addonName activated for $_temp0';
  }

  @override
  String adminAddonsBulkDeactivated(Object addonName, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$addonName deactivated for $_temp0';
  }

  @override
  String adminAddonsBulkSheetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants selected',
      one: '1 tenant selected',
    );
    return '$_temp0';
  }

  @override
  String get adminAddonsBulkSheetTitle => 'Activate add-on in bulk';

  @override
  String get adminAddonsEditPriceTitle => 'Edit monthly price';

  @override
  String get adminAddonsEditPriceTooltip => 'Edit price';

  @override
  String adminAddonsPriceUpdated(Object addonName, Object price) {
    return '$addonName price updated to $price/month';
  }

  @override
  String get adminAddonsPriceSaveError =>
      'Could not save the price. Try again.';

  @override
  String get adminAddonsListHint =>
      'Tap a tenant to manage its add-ons. Tap the ✓ icon for multi-select.';

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
  String get adminRevenueByAddOn => 'Revenue by Add-on';

  @override
  String get adminRevenueByCategory => 'Distribution by Category';

  @override
  String get adminRevenuePerMonth => 'potential/month';

  @override
  String get adminPlanPerMonthSuffix => '/mo';

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
      other: '$days days left',
      one: '1 day left',
    );
    return 'Active: $_temp0';
  }

  @override
  String get adminTenantCycleExpired => 'Expired';

  @override
  String adminTenantCycleExpiresIn(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Expires in $_temp0';
  }

  @override
  String adminTenantCycleTrialLeft(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
    );
    return 'Trial: $_temp0';
  }

  @override
  String get validationCustomerNameRequired => 'Enter the customer name.';

  @override
  String get validationDebtAmountPositive =>
      'The credit amount must be greater than zero.';

  @override
  String get validationAmountPositive =>
      'The transaction amount must be greater than zero.';

  @override
  String get validationCashCountNonNegative =>
      'The physical cash count cannot be negative.';

  @override
  String get validationSalePriceBelowPurchase =>
      'The sale price cannot be lower than the purchase price.';

  @override
  String get validationStoreNameRequired => 'Enter the store name.';

  @override
  String get validationTenantNotApproved =>
      'Your ERP access has not been approved yet.';

  @override
  String get validationEmployeeNameEmailRequired =>
      'Enter the employee\'s name and e-mail.';

  @override
  String get validationEmployeeStoreRequired =>
      'Choose a store from your tenant.';

  @override
  String get validationPlanNameRequired => 'Enter the plan name.';

  @override
  String get validationPlanMinStores => 'The plan must allow at least 1 store.';

  @override
  String get validationPlanMinEmployees =>
      'The plan must allow at least 1 employee.';

  @override
  String get validationPlanPriceNonNegative => 'The price cannot be negative.';

  @override
  String get validationBusinessNameRequired => 'Enter your business name.';

  @override
  String get validationAccessPlanRequired => 'Choose a plan.';

  @override
  String get validationAccessAlreadyRequested =>
      'You already have an access request. Please wait for approval.';

  @override
  String get validationUpgradePlanDifferent =>
      'Choose a plan different from the current one.';

  @override
  String get validationUpgradePendingExists =>
      'There is already an upgrade request awaiting approval.';

  @override
  String get validationAccountGeneric =>
      'Could not create the employee account. Please try again.';

  @override
  String get validationAccountEmailInUse =>
      'An account with this e-mail already exists. Use another e-mail or ask the employee to sign in with their own account.';

  @override
  String get validationAccountOwnerOnly =>
      'Only the tenant owner can register employees.';

  @override
  String get validationAccountWeakPassword =>
      'The password must have at least 8 characters.';

  @override
  String planLimitStores(String planName, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit stores',
      one: '1 store',
    );
    return 'The $planName plan allows up to $_temp0. Request a plan upgrade to add more.';
  }

  @override
  String planLimitEmployees(String planName, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit employees',
      one: '1 employee',
    );
    return 'The $planName plan allows up to $_temp0. Request a plan upgrade to hire more.';
  }

  @override
  String get productionTitle => 'Production';

  @override
  String get productionEmptyTitle => 'No recipe yet';

  @override
  String get productionEmptySubtitle =>
      'A recipe defines the components (raw material, packaging…) that produce a finished product.';

  @override
  String get productionNewRecipe => 'New recipe';

  @override
  String get productionRecipesSection => 'Recipes';

  @override
  String get productionHistorySection => 'Production history';

  @override
  String get productionHistoryEmpty => 'No production recorded';

  @override
  String get productionHistoryEmptySubtitle =>
      'Production orders appear here after you produce.';

  @override
  String get productionRecipeTitle => 'Recipe';

  @override
  String get productionFinishedProduct => 'Finished product';

  @override
  String get productionYieldLabel => 'Base yield (units)';

  @override
  String get productionComponents => 'Components';

  @override
  String get productionAddComponent => 'Add component';

  @override
  String get productionComponentLabel => 'Component';

  @override
  String get productionQuantityLabel => 'Quantity';

  @override
  String get productionProduce => 'Produce';

  @override
  String get productionBasesLabel => 'Bases to produce';

  @override
  String productionProduced(String quantity) {
    return 'To produce: $quantity';
  }

  @override
  String productionCostTotal(String amount) {
    return 'Order cost: $amount';
  }

  @override
  String get productionConfirm => 'Record production';

  @override
  String get productionSaved => 'Production recorded';

  @override
  String get productionRecipeSaved => 'Recipe saved';

  @override
  String get productionDeleteTitle => 'Remove recipe';

  @override
  String get productionDeleteMessage =>
      'The recipe will be removed. Production history is kept.';

  @override
  String productionItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count components',
      one: '1 component',
    );
    return '$_temp0';
  }

  @override
  String get productionNoProducibleTitle => 'No producible products';

  @override
  String get productionNoProducibleSubtitle =>
      'Set a product type to \"Manufactured\" or \"Composite\" to create a recipe.';

  @override
  String productionInsufficientProduct(String product) {
    return 'Insufficient stock for $product';
  }
}
