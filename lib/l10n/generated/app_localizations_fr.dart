// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Dumbhanengue ERP';

  @override
  String get onboardingTitle => 'Bienvenue !';

  @override
  String get onboardingHeading => 'Configurez votre entreprise';

  @override
  String get onboardingSubtitle =>
      'Choisissez le forfait, le nom et la devise. Approbation en 24h.';

  @override
  String get onboardingBusinessLabel => 'Nom de l\'entreprise';

  @override
  String get onboardingBusinessError => 'Indiquez le nom de votre entreprise.';

  @override
  String get onboardingPlanLabel => 'Choisissez le forfait';

  @override
  String get onboardingPlansError => 'Impossible de charger les forfaits.';

  @override
  String onboardingPlanDetails(int stores, int employees) {
    return '$stores magasin(s) · $employees employé(s)';
  }

  @override
  String get onboardingSubmit => 'Demander l\'accès';

  @override
  String onboardingSuccess(String business) {
    return 'Demande pour $business envoyée ! Agardez l\'approbation (24h).';
  }

  @override
  String get onboardingChoosePlanError =>
      'Choisissez un forfait pour continuer.';

  @override
  String get onboardingGenericError =>
      'Impossible d\'envoyer la demande. Réessayez.';

  @override
  String get onboardingLanguageLabel => 'Langue';

  @override
  String get onboardingLanguageHint => 'Langue de l\'application';

  @override
  String get onboardingCurrencyLabel => 'Devise';

  @override
  String get onboardingCurrencyHint => 'Devise utilisée pour les montants';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get currencyBrl => 'Réal (BRL)';

  @override
  String get currencyUsd => 'Dollar américain (USD)';

  @override
  String get currencyEur => 'Euro (EUR)';

  @override
  String get currencyMzn => 'Metical (MZN)';

  @override
  String get settingsSave => 'Enregistrer';

  @override
  String get settingsSaved => 'Réglages enregistrés !';

  @override
  String get settingsGenericError => 'Impossible d\'enregistrer. Réessayez.';

  @override
  String get settingsSupportSection => 'Assistance';

  @override
  String get settingsSupportEntry => 'Aide et documentation';

  @override
  String get settingsSupportEntryHint => 'Guide et dépannage — hors ligne';

  @override
  String get supportTitle => 'Aide';

  @override
  String get supportSubtitle => 'Guide utilisateur et dépannage.';

  @override
  String get supportUserGuide => 'Guide de l\'utilisateur';

  @override
  String get supportUserGuideHint =>
      'Connexion, magasins, produits, ventes, crédit, finances et rapports';

  @override
  String get supportTroubleshooting => 'Dépannage';

  @override
  String get supportTroubleshootingHint =>
      'Problèmes courants : connexion, ventes, stock et réseau';

  @override
  String get supportReadingError => 'Impossible d\'ouvrir le document.';

  @override
  String get commonSearch => 'Rechercher...';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonSignOut => 'Se déconnecter';

  @override
  String get appSheetClose => 'Fermer';

  @override
  String get storeSwitcherTooltip => 'Changer de magasin';

  @override
  String get storeSelectorSectionTitle => 'Magasin actif';

  @override
  String get storeSelectorSectionHint => 'Choisissez le magasin actif.';

  @override
  String get tenantPendingTitle => 'En attente d\'approbation';

  @override
  String tenantPendingSubtitle(String business) {
    return 'Demande pour \"$business\" envoyée. Attendez 24h.';
  }

  @override
  String get tenantPendingHint =>
      'Une fois approuvé, créez des magasins et commencez.';

  @override
  String get tenantRejectedTitle => 'Demande rejetée';

  @override
  String tenantRejectedSubtitle(String business) {
    return 'La demande pour \"$business\" n\'a pas été approuvée.';
  }

  @override
  String get authBlockedTitle => 'Accès suspendu';

  @override
  String get authBlockedMessage =>
      'Votre compte a été désactivé par le propriétaire.';

  @override
  String get authBlockedSignOut => 'Se déconnecter';

  @override
  String get authErrorRestoreSession => 'Session non restaurée';

  @override
  String get authErrorCheckConnection =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get authErrorLoadAccount => 'Compte non chargé';

  @override
  String get splashLoading => 'Ouverture de votre session…';

  @override
  String get loginSubtitleSignUp => 'Créez votre compte pour commencer';

  @override
  String get loginSubtitleSignIn => 'Une gestion simple pour votre entreprise';

  @override
  String get loginNameLabel => 'Nom';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginEmailError => 'Indiquez un e-mail valide.';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginPasswordError =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get loginPasswordHint =>
      'Min. 8 caractères avec minuscule, majuscule, chiffre et symbole.';

  @override
  String get loginWeakPasswordError =>
      'Le mot de passe doit contenir lettres, chiffres et symboles.';

  @override
  String get loginRateLimitError =>
      'Trop de tentatives. Attendez 1h et réessayez.';

  @override
  String get loginShowPassword => 'Afficher le mot de passe';

  @override
  String get loginHidePassword => 'Masquer le mot de passe';

  @override
  String get loginConfirmLabel => 'Confirmer le mot de passe';

  @override
  String get loginConfirmError => 'Les mots de passe ne correspondent pas.';

  @override
  String get loginSignUp => 'S\'inscrire';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String get loginSwitchToSignIn => 'J\'ai déjà un compte — se connecter';

  @override
  String get loginSwitchToSignUp => 'Pas encore de compte — s\'inscrire';

  @override
  String get loginSignUpSuccess =>
      'Compte créé ! Confirmez votre e-mail pour vous connecter.';

  @override
  String get loginSignUpError => 'Impossible de créer le compte. Réessayez.';

  @override
  String get loginSignInError =>
      'Impossible de se connecter. Vérifiez l\'e-mail et le mot de passe.';

  @override
  String get loginSecurityNote => 'Données protégées par chiffrement.';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get forgotPasswordHint =>
      'Indiquez votre e-mail. Nous enverrons un lien.';

  @override
  String get forgotPasswordSubmit => 'Envoyer le lien';

  @override
  String get forgotPasswordSent =>
      'Si un compte existe, nous avons envoyé un lien.';

  @override
  String get forgotPasswordError => 'Impossible d\'envoyer le lien. Réessayez.';

  @override
  String get setNewPasswordTitle => 'Définir un nouveau mot de passe';

  @override
  String get setNewPasswordHint =>
      'Min. 8 caractères avec minuscule, majuscule, chiffre et symbole.';

  @override
  String get setNewPasswordSubmit => 'Enregistrer le nouveau mot de passe';

  @override
  String get setNewPasswordSuccess => 'Mot de passe mis à jour !';

  @override
  String get setNewPasswordError => 'Impossible de mettre à jour. Réessayez.';

  @override
  String get setNewPasswordSignOut => 'Se déconnecter';

  @override
  String get changePasswordTitle => 'Changer le mot de passe';

  @override
  String get changePasswordCurrentLabel => 'Mot de passe actuel';

  @override
  String get changePasswordNewLabel => 'Nouveau mot de passe';

  @override
  String get changePasswordConfirmLabel => 'Confirmer le nouveau mot de passe';

  @override
  String get changePasswordSuccess => 'Mot de passe modifié avec succès !';

  @override
  String get changePasswordWrongCurrent =>
      'Mot de passe actuel incorrect. Réessayez.';

  @override
  String get changePasswordSubmit => 'Changer le mot de passe';

  @override
  String get changePasswordError =>
      'Impossible de changer le mot de passe. Réessayez.';

  @override
  String get securitySectionTitle => 'Sécurité';

  @override
  String get securityChangePassword => 'Changer le mot de passe';

  @override
  String get securityChangePasswordHint =>
      'Mettez à jour le mot de passe de votre compte';

  @override
  String get appNavHome => 'Accueil';

  @override
  String get appNavSales => 'Ventes';

  @override
  String get appNavWallet => 'Portefeuille';

  @override
  String get appNavMenu => 'Menu';

  @override
  String get appNavProducts => 'Produits';

  @override
  String get appNavFinancial => 'Finances';

  @override
  String get appNavCredit => 'Crédit';

  @override
  String get appNavCustomers => 'Clients';

  @override
  String get fabMenuTitle => 'Nouvelle action';

  @override
  String get fabMenuSubtitle => 'Que souhaitez-vous faire ?';

  @override
  String get menuSubtitle => 'Choisissez une zone pour continuer';

  @override
  String get commonSignOutConfirmTitle => 'Se déconnecter ?';

  @override
  String get commonSignOutConfirmMessage =>
      'Vous allez vous déconnecter de votre compte sur cet appareil.';

  @override
  String get fabMenuNewSale => 'Nouvelle vente';

  @override
  String get fabMenuNewSaleHint => 'Panier · déduction de stock · caisse';

  @override
  String get fabMenuExpense => 'Enregistrer une dépense';

  @override
  String get fabMenuExpenseHint => 'Sortie de caisse avec catégorie';

  @override
  String get fabMenuAddProduct => 'Ajouter un produit';

  @override
  String get fabMenuAddProductHint => 'Catalogue · prix · stock initial';

  @override
  String get fabMenuAddDebt => 'Enregistrer un crédit';

  @override
  String get fabMenuAddDebtHint => 'À recevoir ou à payer';

  @override
  String get fabMenuAddCustomer => 'Ajouter un client';

  @override
  String get fabMenuAddCustomerHint => 'Contacts · crédit lié';

  @override
  String get fabMenuCancel => 'Annuler';

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations en attente',
      one: '1 opération en attente',
    );
    return '$_temp0';
  }

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get syncOfflineSaved =>
      'Pas de connexion. Enregistré — synchronisé automatiquement.';

  @override
  String syncDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count opérations synchronisées',
      one: '1 opération synchronisée',
    );
    return '$_temp0';
  }

  @override
  String get syncStillOffline => 'Pas de connexion — opérations en attente.';

  @override
  String dashboardGreeting(String name) {
    return 'Bonjour, $name';
  }

  @override
  String get dashboardSignOutTooltip => 'Se déconnecter';

  @override
  String get dashboardOwnerFallback => 'Propriétaire';

  @override
  String get dashboardTotalSales => 'Total des ventes';

  @override
  String get dashboardAllTime => 'Tout l\'historique';

  @override
  String get dashboardCashBalance => 'Solde en caisse';

  @override
  String get dashboardReceivables => 'À recevoir (crédit)';

  @override
  String get dashboardStockLabel => 'Stock en produits';

  @override
  String get commonUnits => 'un.';

  @override
  String get dashboardQuickActions => 'Actions rapides';

  @override
  String get dashboardQuickNewSale => 'Nouvelle vente';

  @override
  String get dashboardQuickAddProduct => 'Ajouter un produit';

  @override
  String get dashboardQuickAddTransaction => 'Enregistrer une transaction';

  @override
  String get dashboardQuickAddDebt => 'Enregistrer un crédit';

  @override
  String get dashboardModules => 'Modules';

  @override
  String get dashboardModuleCustomers => 'Clients';

  @override
  String get dashboardModulePurchases => 'Achats';

  @override
  String get dashboardModuleReports => 'Rapports';

  @override
  String get dashboardModuleStores => 'Magasins';

  @override
  String get dashboardRecentSales => 'Ventes récentes';

  @override
  String get dashboardViewAll => 'Tout voir';

  @override
  String get dashboardNoSales => 'Aucune vente — enregistrez la première !';

  @override
  String get dashboardRecentPurchases => 'Achats récents';

  @override
  String get dashboardNoPurchases => 'Aucun achat — enregistrez le premier !';

  @override
  String get dashboardLowStock => 'Stock faible';

  @override
  String get dashboardKpisError => 'Impossible de charger les indicateurs.';

  @override
  String get dashboardActivityTitle => 'Activité du jour';

  @override
  String dashboardActivityEvents(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count événements',
      one: '1 événement',
    );
    return '$_temp0';
  }

  @override
  String dashboardActivityMinutesAgo(Object count) {
    return 'il y a $count min';
  }

  @override
  String dashboardActivityHoursAgo(Object count) {
    return 'il y a $count h';
  }

  @override
  String get dashboardDateToday => 'Aujourd\'hui';

  @override
  String get dashboardMetricSales => 'Ventes';

  @override
  String get dashboardMetricCash => 'Caisse';

  @override
  String get dashboardMetricReceivables => 'À recevoir';

  @override
  String dashboardFiadoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count crédits',
      one: '1 crédit',
    );
    return '$_temp0';
  }

  @override
  String get dashboardActivityEmpty => 'Aucune activité enregistrée.';

  @override
  String get dashboardActivitySeeAll => 'Tout voir';

  @override
  String dashboardStockEntry(String product) {
    return 'Stock · $product';
  }

  @override
  String dashboardStockEntryDetail(String quantity, String time) {
    return 'Entrée de $quantity · $time';
  }

  @override
  String get dashboardFiadoPayment => 'Paiement à crédit';

  @override
  String dashboardExpenseRow(String description) {
    return 'Dépense · $description';
  }

  @override
  String dashboardLowStockDetail(String name, String quantity) {
    return '$name · $quantity restantes';
  }

  @override
  String get dashboardAlertBadge => 'Alerte';

  @override
  String dashboardSaleItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMonday => 'Lundi';

  @override
  String get weekdayTuesday => 'Mardi';

  @override
  String get weekdayWednesday => 'Mercredi';

  @override
  String get weekdayThursday => 'Jeudi';

  @override
  String get weekdayFriday => 'Vendredi';

  @override
  String get weekdaySaturday => 'Samedi';

  @override
  String get weekdaySunday => 'Dimanche';

  @override
  String get storesTitle => 'Magasins';

  @override
  String get storesTabStores => 'Magasins';

  @override
  String get storesTabEmployees => 'Employés';

  @override
  String get storesTabUpgrades => 'Upgrades';

  @override
  String get storesTabSettings => 'Réglages';

  @override
  String get storesAddStore => 'Nouveau magasin';

  @override
  String get storesAddEmployee => 'Nouvel employé';

  @override
  String get storesLoadError => 'Impossible de charger les magasins.';

  @override
  String get storesEmptyTitle => 'Aucun magasin créé';

  @override
  String get storesEmptySubtitle =>
      'Créez le premier magasin de votre entreprise.';

  @override
  String get employeesLoadError => 'Impossible de charger les employés.';

  @override
  String get employeesEmptyTitle => 'Aucun employé lié';

  @override
  String get employeesEmptySubtitle =>
      'Créez le compte de l\'employé et choisissez le magasin.';

  @override
  String get roleManager => 'Gérant';

  @override
  String get roleEmployee => 'Employé';

  @override
  String get employeeActive => 'Actif';

  @override
  String get employeeInactive => 'Inactif';

  @override
  String employeeDeactivateConfirm(Object name) {
    return 'Désactiver $name ? Perd l\'accès immédiatement.';
  }

  @override
  String employeeReactivateConfirm(Object name) {
    return 'Réactiver $name ? Retrouve l\'accès au magasin.';
  }

  @override
  String get employeeDeactivated => 'Employé désactivé.';

  @override
  String get employeeReactivated => 'Employé réactivé.';

  @override
  String get employeeDeactivateAction => 'Désactiver';

  @override
  String get employeeReactivateAction => 'Réactiver';

  @override
  String get upgradesLoadError =>
      'Impossible de charger les demandes d\'évolution.';

  @override
  String get upgradesEmptyTitle => 'Aucune demande d\'évolution';

  @override
  String get upgradesEmptySubtitle =>
      'Demandez un forfait supérieur ci-dessus.';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusApproved => 'Approuvé';

  @override
  String get statusRejected => 'Rejeté';

  @override
  String upgradesRequestedOn(String date) {
    return 'Demandé le $date';
  }

  @override
  String get planCardTitle => 'Forfait';

  @override
  String get planCardUpgrade => 'Évoluer';

  @override
  String get planCardStores => 'Magasins';

  @override
  String get planCardEmployees => 'Employés';

  @override
  String planDetails(int stores, int employees) {
    return '$stores magasin(s) · $employees employé(s)';
  }

  @override
  String get addStoreTitle => 'Nouveau magasin';

  @override
  String get addStoreNameLabel => 'Nom du magasin';

  @override
  String get addStoreNameError => 'Indiquez le nom du magasin.';

  @override
  String get addStoreAddressLabel => 'Adresse (facultatif)';

  @override
  String addStoreSuccess(String name) {
    return 'Magasin $name créé !';
  }

  @override
  String get addStoreError => 'Impossible de créer le magasin. Réessayez.';

  @override
  String get addStoreSubmit => 'Créer le magasin';

  @override
  String get addEmployeeTitle => 'Nouvel employé';

  @override
  String get addEmployeeNameLabel => 'Nom complet';

  @override
  String get addEmployeeNameError => 'Indiquez le nom de l\'employé.';

  @override
  String get addEmployeeEmailLabel => 'E-mail';

  @override
  String get addEmployeeEmailError => 'Indiquez un e-mail valide.';

  @override
  String get addEmployeePasswordLabel => 'Mot de passe d\'accès';

  @override
  String get addEmployeePasswordError =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get addEmployeeStoreLabel => 'Magasin';

  @override
  String get addEmployeeNoStores =>
      'Créez un magasin avant d\'ajouter des employés.';

  @override
  String get addEmployeeRoleLabel => 'Poste';

  @override
  String get addEmployeeSuccess => 'Employé enregistré ! Compte d\'accès créé.';

  @override
  String get addEmployeeError =>
      'Impossible d\'enregistrer. Vérifiez l\'e-mail.';

  @override
  String get addEmployeeSubmit => 'Enregistrer l\'employé';

  @override
  String get upgradeTitle => 'Évolution de forfait';

  @override
  String get upgradeSubtitle =>
      'Choisissez le nouveau forfait. Approuvé par le super admin.';

  @override
  String get upgradeMaxReached => 'Vous êtes déjà au forfait maximum.';

  @override
  String get upgradeChooseError => 'Choisissez le forfait de destination.';

  @override
  String get upgradeSuccess => 'Demande d\'évolution envoyée !';

  @override
  String get upgradeError => 'Impossible d\'envoyer la demande. Réessayez.';

  @override
  String get upgradeSubmit => 'Demander l\'évolution';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonNoResults => 'Aucun résultat';

  @override
  String get commonNoResultsHint => 'Essayez un autre terme.';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSoldOut => 'Épuisé';

  @override
  String get periodToday => 'Aujourd\'hui';

  @override
  String get periodWeek => 'Cette semaine';

  @override
  String get periodMonth => 'Ce mois-ci';

  @override
  String get periodAll => 'Tout';

  @override
  String get paymentCash => 'Espèces';

  @override
  String get paymentDebitCard => 'Carte de débit';

  @override
  String get paymentCreditCard => 'Carte de crédit';

  @override
  String get paymentEMola => 'E-Mola';

  @override
  String get paymentMPesa => 'M-Pesa';

  @override
  String get paymentTransfer => 'Virement';

  @override
  String get purchasesSearchHint => 'Rechercher un achat...';

  @override
  String get productsFilterTooltip => 'Filtrer';

  @override
  String get productsFilterAll => 'Tous';

  @override
  String productsFilterAllCount(int count) {
    return 'Tous · $count';
  }

  @override
  String productsFilterLowCount(int count) {
    return 'Stock faible · $count';
  }

  @override
  String get productsColProduct => 'Produit / SKU';

  @override
  String get productsColPrice => 'Prix · Stock';

  @override
  String get productsSearchHint => 'Rechercher un produit...';

  @override
  String get productsLoadError => 'Impossible de charger les produits.';

  @override
  String get productsEmptyTitle => 'Aucun produit enregistré';

  @override
  String get productsEmptySubtitle =>
      'Touchez \"Nouveau produit\" pour commencer.';

  @override
  String get productsAddNew => 'Nouveau produit';

  @override
  String productsBuySell(String buy, String sell) {
    return 'Achat : $buy · Vente : $sell';
  }

  @override
  String get productsAdded => 'Produit ajouté !';

  @override
  String get productsAddedNoPhoto =>
      'Produit ajouté ! (pas de permission de stockage)';

  @override
  String get productsAddError => 'Impossible d\'ajouter le produit. Réessayez.';

  @override
  String get productsNameError => 'Indiquez le nom du produit.';

  @override
  String get productsDescriptionLabel => 'Description (facultatif)';

  @override
  String get productsPurchasePrice => 'Prix d\'achat';

  @override
  String get productsPurchasePriceError => 'Indiquez le prix d\'achat';

  @override
  String get productsSalePrice => 'Prix de vente';

  @override
  String get productsSalePriceError => 'Indiquez le prix de vente';

  @override
  String get productsStockQuantity => 'Quantité en stock';

  @override
  String get productsStockError => 'Quantité invalide';

  @override
  String get productsAddSubmit => 'Ajouter le produit';

  @override
  String get productsEditTitle => 'Modifier le produit';

  @override
  String get productsEditSubmit => 'Enregistrer les modifications';

  @override
  String get productsEditSaved => 'Produit mis à jour !';

  @override
  String get productsEditSavedNoPhoto =>
      'Produit mis à jour ! (pas de permission de stockage)';

  @override
  String get productsEditError => 'Impossible de mettre à jour. Réessayez.';

  @override
  String get productsPhotoLabel => 'Photo du produit';

  @override
  String get productsPhotoTake => 'Prendre une photo';

  @override
  String get productsPhotoGallery => 'Choisir depuis la galerie';

  @override
  String get productsPhotoRemove => 'Retirer la photo';

  @override
  String get productsInactive => 'Inactif';

  @override
  String get productsStockOut => 'Rupture';

  @override
  String get productsStockLow => 'Faible';

  @override
  String get productsFilterAdvanced => 'Filtres avancés';

  @override
  String get productsFilterClear => 'Tout effacer';

  @override
  String get productsFilterStockType => 'Type de stock';

  @override
  String get productsFilterStockTypeAll => 'Tous';

  @override
  String get productsFilterStockTypeWeight => 'Poids (kg/g/l/ml)';

  @override
  String get productsFilterStockTypeUnit => 'Unité (pcs)';

  @override
  String get productsFilterAvailability => 'Disponibilité';

  @override
  String get productsFilterAvailable => 'En stock';

  @override
  String get productsFilterLowStock => 'Stock faible';

  @override
  String get productsFilterOutOfStock => 'Rupture';

  @override
  String get productsFilterPriceRange => 'Fourchette de prix';

  @override
  String get productsFilterMinPrice => 'Prix min';

  @override
  String get productsFilterMaxPrice => 'Prix max';

  @override
  String get productsFilterApply => 'Appliquer';

  @override
  String get productsFilterInactive => 'Inactifs';

  @override
  String productsFilterInactiveCount(int count) {
    return 'Inactifs · $count';
  }

  @override
  String productsHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits',
      one: '1 produit',
    );
    return '$_temp0';
  }

  @override
  String get productsClearFilters => 'Effacer les filtres';

  @override
  String get productsEmptyFilteredTitle => 'Aucun produit trouvé';

  @override
  String get productsEmptyFilteredSubtitle =>
      'Ajustez la recherche ou les filtres.';

  @override
  String productsFilteredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits',
      one: '1 produit',
    );
    return '$_temp0';
  }

  @override
  String get productsSummaryActive => 'Actifs';

  @override
  String get productsSummaryLowStock => 'Stock faible';

  @override
  String get productsSummaryInactive => 'Inactifs';

  @override
  String get productsActiveLabel => 'Produit actif';

  @override
  String get productsActiveHint =>
      'Désactivez pour retirer du PDV et des achats.';

  @override
  String get productsStockAdjustHint =>
      'Ajustement manuel : définit le stock exact (FIFO).';

  @override
  String get productsSectionInfo => 'Informations';

  @override
  String get productsSectionPricing => 'Prix';

  @override
  String get productsSectionStock => 'Stock';

  @override
  String get productsSectionStatus => 'Statut';

  @override
  String get productsAddNewTitle => 'Nouveau produit';

  @override
  String get productsSave => 'Enregistrer';

  @override
  String get productsSaving => 'Enregistrement...';

  @override
  String get productsSaved => 'Produit enregistré avec succès';

  @override
  String get productsSavedNoPhoto =>
      'Produit enregistré ! (pas de permission de stockage)';

  @override
  String get productsPhotoLabelNew => 'Photo du produit';

  @override
  String get productsPhotoHint => 'Touchez pour ajouter';

  @override
  String get productsSectionBasic => 'Informations de base';

  @override
  String get productsSectionPricingNew => 'Prix';

  @override
  String get productsSectionStockNew => 'Stock';

  @override
  String get productsNameLabel => 'Nom du produit';

  @override
  String get productsNameHint => 'Ex. : Riz type 1';

  @override
  String get productsNameErrorMsg => 'Obligatoire';

  @override
  String get productsDescriptionLabelNew => 'Description';

  @override
  String get productsDescriptionHint => 'Facultatif';

  @override
  String get productsCodeLabel => 'Code-barres (PLU)';

  @override
  String get productsCodeHint => 'Balances étiqueteuses (ex. : 12345)';

  @override
  String get productsCodeError =>
      'Code invalide : utilisez jusqu\'à 5 chiffres.';

  @override
  String get productsPurchasePriceLabel => 'Prix d\'achat';

  @override
  String get productsSalePriceLabel => 'Prix de vente';

  @override
  String get productsPriceValidationError =>
      'Le prix de vente doit être supérieur au prix d\'achat';

  @override
  String get productsStockQuantityLabel => 'Quantité en stock';

  @override
  String get productsStockHint => 'Ex. : 50';

  @override
  String get productsStockWeightHint => 'En unités de vente (ex. : 1,75)';

  @override
  String get productsExpiryLabel => 'Date de péremption';

  @override
  String get productsExpiryHint => 'Facultatif';

  @override
  String get productsExpiryAdd => 'Définir la péremption';

  @override
  String get productsExpiryClear => 'Retirer la péremption';

  @override
  String get productsWeighLabel => 'Vente au poids (fraction)';

  @override
  String get productsWeighHint =>
      'Accepte les quantités décimales (ex. : 1,75 kg)';

  @override
  String get productsUnitLabel => 'Unité de vente';

  @override
  String customersHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients',
      one: '1 client',
    );
    return '$_temp0';
  }

  @override
  String get customersColCustomer => 'Client';

  @override
  String get customersColContact => 'Contact / Crédit';

  @override
  String get customersSearchHint => 'Rechercher un client...';

  @override
  String get customersLoadError => 'Impossible de charger les clients.';

  @override
  String get customersEmptyTitle => 'Aucun client enregistré';

  @override
  String get customersEmptySubtitle =>
      'Touchez \"Nouveau client\" pour commencer.';

  @override
  String get customersAddNew => 'Nouveau client';

  @override
  String customersCreditLabel(String amount) {
    return 'Crédit $amount';
  }

  @override
  String customersAdded(String name) {
    return 'Client $name enregistré !';
  }

  @override
  String get customersAddError =>
      'Impossible d\'enregistrer le client. Réessayez.';

  @override
  String get customersNameError => 'Indiquez le nom du client.';

  @override
  String get customersPhoneLabel => 'Téléphone (facultatif)';

  @override
  String get customersEmailLabel => 'E-mail (facultatif)';

  @override
  String get customersAddSubmit => 'Enregistrer le client';

  @override
  String get customersEditTitle => 'Modifier le client';

  @override
  String customersEditSuccess(Object name) {
    return 'Client $name mis à jour !';
  }

  @override
  String get customersEditError =>
      'Impossible de modifier le client. Réessayez.';

  @override
  String get customersEditSubmit => 'Enregistrer';

  @override
  String get customersDeleteConfirmTitle => 'Supprimer le client ?';

  @override
  String customersDeleteConfirmMessage(Object name) {
    return '$name sera supprimé définitivement. Les enregistrements de crédit sont conservés.';
  }

  @override
  String get customersDeleteSuccess => 'Client supprimé.';

  @override
  String get customersDeleteError =>
      'Impossible de supprimer le client. Réessayez.';

  @override
  String get purchasesTitle => 'Achats';

  @override
  String get purchasesAddNew => 'Nouvel achat';

  @override
  String get purchasesLoadError => 'Impossible de charger les achats.';

  @override
  String get purchasesEmptyTitle => 'Aucun achat enregistré';

  @override
  String get purchasesEmptySubtitle =>
      'Touchez \"Nouvel achat\" pour enregistrer.';

  @override
  String purchasesHeaderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count achats',
      one: '1 achat',
      zero: '0 achats',
    );
    return '$_temp0';
  }

  @override
  String get purchasesHeaderVsYesterday => 'vs hier';

  @override
  String purchasesStockAdded(int units, String unit) {
    return 'Stock +$units $unit';
  }

  @override
  String get purchasesEmptyFilteredTitle => 'Aucun achat trouvé';

  @override
  String get purchasesEmptyFilteredSubtitle =>
      'Ajustez la recherche ou les filtres.';

  @override
  String get purchasesClearFilters => 'Effacer les filtres';

  @override
  String get purchasesSupplierError => 'Indiquez le fournisseur.';

  @override
  String get purchasesCartItemUnavailable =>
      'Article du panier indisponible. Réessayez.';

  @override
  String purchasesRegistered(String amount) {
    return 'Achat enregistré : $amount !';
  }

  @override
  String purchasesProductNotFound(String id) {
    return 'Produit $id introuvable dans le catalogue.';
  }

  @override
  String get purchasesRegisterError =>
      'Impossible d\'enregistrer l\'achat. Réessayez.';

  @override
  String get purchasesSupplierLabel => 'Fournisseur';

  @override
  String get purchasesNoProductsTitle => 'Aucun produit à acheter';

  @override
  String get purchasesNoProductsSubtitle =>
      'Enregistrez des produits pour faire des achats.';

  @override
  String get purchasesConfirm => 'Confirmer l\'achat';

  @override
  String purchasesStockLabel(int quantity, String unit) {
    return '$quantity $unit en stock';
  }

  @override
  String get reportsTitle => 'Rapports';

  @override
  String get reportsRevenue => 'Chiffre d\'affaires';

  @override
  String get reportsProfit => 'Bénéfice brut';

  @override
  String get reportsMargin => 'Marge';

  @override
  String get reportsBestSellers => 'Meilleures ventes';

  @override
  String get reportsLoadError => 'Impossible de charger le rapport.';

  @override
  String get reportsEmptyTitle => 'Aucune vente sur la période';

  @override
  String get reportsEmptySubtitle =>
      'Enregistrez des ventes pour voir le rapport.';

  @override
  String get reportsSalesPerDay => 'Ventes par jour';

  @override
  String reportsRevenueLabel(String amount) {
    return '$amount vendus';
  }

  @override
  String get reportsExport => 'Exporter';

  @override
  String get reportsExportCsv => 'Exporter en CSV';

  @override
  String get reportsExportPdf => 'Exporter en PDF';

  @override
  String get reportsExportDone => 'Rapport exporté !';

  @override
  String get reportsExportError => 'Impossible d\'exporter. Réessayez.';

  @override
  String get reportsExportTitle => 'Rapport de ventes';

  @override
  String get reportsExportFileName => 'rapport_ventes';

  @override
  String get reportsExportStore => 'Magasin';

  @override
  String get reportsExportPeriod => 'Période';

  @override
  String get reportsExportGeneratedAt => 'Généré le';

  @override
  String get reportsExportSummary => 'Résumé';

  @override
  String get reportsExportRank => 'Position';

  @override
  String get reportsExportProduct => 'Produit';

  @override
  String get reportsExportQuantity => 'Quantité';

  @override
  String get reportsExportRevenue => 'Chiffre d\'affaires';

  @override
  String get reportsExportDay => 'Jour';

  @override
  String get reportsExportTotal => 'Total';

  @override
  String get financialTitle => 'Finances';

  @override
  String get financialRegister => 'Enregistrer';

  @override
  String get financialIncome => 'Entrées';

  @override
  String get financialExpense => 'Sorties';

  @override
  String get financialBalance => 'Solde';

  @override
  String get financialPeriodBalance => 'Solde net de la période';

  @override
  String get financialSwipeHint => 'Glissez pour les dépenses →';

  @override
  String get financialTransactions => 'Transactions de la période';

  @override
  String get financialLoadError => 'Impossible de charger les transactions.';

  @override
  String get financialCashFlowError =>
      'Impossible de charger le flux de trésorerie.';

  @override
  String get financialEmptyTitle => 'Aucune transaction';

  @override
  String get financialEmptySubtitle =>
      'Enregistrez des entrées et sorties pour suivre le caisse.';

  @override
  String get financialReceivePendingTitle => 'Recevoir le montant en attente ?';

  @override
  String financialReceivePendingBody(String amount) {
    return 'Confirmer la réception de $amount ?';
  }

  @override
  String get financialReceive => 'Recevoir';

  @override
  String get financialReceived => 'Transaction reçue !';

  @override
  String get financialReceiveError => 'Impossible de recevoir. Réessayez.';

  @override
  String get financialPay => 'Payer';

  @override
  String get financialPayPendingTitle => 'Payer le montant en attente ?';

  @override
  String financialPayPendingBody(String amount) {
    return 'Confirmer le paiement de $amount ?';
  }

  @override
  String get financialPaid => 'Sortie payée !';

  @override
  String get financialPayError =>
      'Impossible de payer la transaction en attente. Réessayez.';

  @override
  String get financialAddTitle => 'Enregistrer une transaction';

  @override
  String get financialIncomingType => 'Entrée';

  @override
  String get financialOutgoingType => 'Sortie';

  @override
  String get financialDescriptionLabel => 'Description';

  @override
  String get financialDescriptionError => 'Indiquez la description.';

  @override
  String get financialCategoryLabel => 'Catégorie (facultatif)';

  @override
  String get financialAmountLabel => 'Montant';

  @override
  String get financialAmountError => 'Indiquez un montant supérieur à zéro.';

  @override
  String get financialPendingLabel => 'En attente (crédit)';

  @override
  String get financialPendingHint =>
      'Ne compte pas dans la caisse tant que non reçu.';

  @override
  String get financialRegistered => 'Transaction enregistrée !';

  @override
  String get financialRegisterError => 'Impossible d\'enregistrer. Réessayez.';

  @override
  String get financialDefaultCategoryIncome => 'Ventes';

  @override
  String get financialDefaultCategoryExpense => 'Dépenses';

  @override
  String get financialDetailDescription => 'Description';

  @override
  String get financialDetailCategory => 'Catégorie';

  @override
  String get financialDetailNumber => 'Nº mouvement';

  @override
  String get financialDetailDate => 'Date et heure';

  @override
  String get financialDetailStatus => 'Statut';

  @override
  String get cashClosingAction => 'Clôture de caisse';

  @override
  String get cashClosingTitle => 'Clôture de caisse du jour';

  @override
  String get cashClosingDaySummary => 'Résumé du jour';

  @override
  String get cashClosingTotalSales => 'Ventes du jour';

  @override
  String get cashClosingExpectedCash => 'Attendu dans le tiroir';

  @override
  String get cashClosingExpectedCashHint => 'Ventes en espèces uniquement.';

  @override
  String get cashClosingByMethod => 'Par moyen de paiement';

  @override
  String get cashClosingCountedCash => 'Espèces comptées';

  @override
  String get cashClosingCountedCashHint =>
      'Comptez l\'argent du tiroir et indiquez-le ici.';

  @override
  String get cashClosingDifference => 'Différence';

  @override
  String get cashClosingConfers => 'Caisse juste';

  @override
  String cashClosingSurplus(String amount) {
    return 'Excédent de $amount';
  }

  @override
  String cashClosingShortage(String amount) {
    return 'Manque de $amount';
  }

  @override
  String get cashClosingConfirm => 'Confirmer la clôture';

  @override
  String get cashClosingUpdate => 'Mettre à jour la clôture';

  @override
  String get cashClosingClosedAt => 'Fermé à';

  @override
  String get cashClosingSuccess => 'Caisse fermée !';

  @override
  String get cashClosingUpdated => 'Clôture mise à jour !';

  @override
  String get cashClosingError => 'Impossible de fermer la caisse. Réessayez.';

  @override
  String get cashClosingEmpty => 'Aucune vente enregistrée ce jour.';

  @override
  String get cashClosingHistory => 'Historique des clôtures';

  @override
  String get cashClosingHistoryEmpty => 'Aucune clôture enregistrée.';

  @override
  String get debtsTitle => 'Crédit';

  @override
  String get debtsHeaderSubtitle => 'Crédit à recevoir et à payer';

  @override
  String get debtsAddDebt => 'Enregistrer un crédit';

  @override
  String get debtsSearchHint => 'Rechercher par nom du client...';

  @override
  String get debtsTabPending => 'En attente';

  @override
  String get debtsTabSettled => 'Soldées';

  @override
  String get debtsTotalPending => 'Total à recevoir';

  @override
  String get debtsOverdueStat => 'En retard';

  @override
  String get debtsSettledStat => 'Soldées';

  @override
  String get debtsNoPendingCustomers => 'Aucun client en attente';

  @override
  String debtsPendingCustomers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients en attente',
      one: '1 client en attente',
    );
    return '$_temp0';
  }

  @override
  String get debtsPendingSection => 'Dettes en attente';

  @override
  String get debtsLoadError => 'Impossible de charger les dettes.';

  @override
  String get debtsEmptyPendingTitle => 'Aucun crédit en attente';

  @override
  String get debtsEmptyPendingSubtitle =>
      'Les crédits en attente apparaîtront ici.';

  @override
  String get debtsTotalSettled => 'Total soldé';

  @override
  String debtsSettledCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count règlements enregistrés',
      one: '1 règlement enregistré',
    );
    return '$_temp0';
  }

  @override
  String get debtsSettledSection => 'Historique des règlements';

  @override
  String get debtsHistoryLoadError => 'Impossible de charger l\'historique.';

  @override
  String get debtsEmptySettledTitle => 'Aucun règlement';

  @override
  String get debtsEmptySettledSubtitle =>
      'Les crédits soldés apparaîtront ici.';

  @override
  String get debtsSettleTitle => 'Soldé la dette ?';

  @override
  String debtsSettleBody(String amount, String name) {
    return 'Recevoir $amount de $name ?';
  }

  @override
  String get debtsSettle => 'Soldé';

  @override
  String debtsSettled(String name, String amount) {
    return 'Crédit de $name soldé — $amount en caisse.';
  }

  @override
  String get debtsNotFound => 'Cette dette n\'est plus en attente.';

  @override
  String get debtsSettleError => 'Impossible de solder. Réessayez.';

  @override
  String get debtsLate => 'En retard';

  @override
  String get debtsDueToday => 'Échoit aujourd\'hui';

  @override
  String debtsDueIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return 'Dans $_temp0';
  }

  @override
  String debtsDueAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return 'Échu il y a $_temp0';
  }

  @override
  String get debtsDueTodayDesc => 'Échoit aujourd\'hui';

  @override
  String get debtsSettleAction => 'Soldé la dette';

  @override
  String get debtsSettledLabel => 'Soldée';

  @override
  String debtsSettledOn(String date) {
    return 'Soldée le $date';
  }

  @override
  String get debtsDueDateHelp => 'Échéance du crédit';

  @override
  String debtsRegisteredFor(String name) {
    return 'Crédit enregistré pour $name !';
  }

  @override
  String get debtsPendingEntryError =>
      'Crédit enregistré, mais la pendance n\'a pas pu être créée.';

  @override
  String get debtsRegisterError =>
      'Impossible d\'enregistrer le crédit. Réessayez.';

  @override
  String get debtsCustomerLinkLabel => 'Client lié (facultatif)';

  @override
  String get debtsNoCustomer => 'Sans lien';

  @override
  String get debtsCustomerNameLabel => 'Nom du client';

  @override
  String get debtsCustomerNameError => 'Indiquez le nom du client.';

  @override
  String get debtsDueDateLabel => 'Échéance';

  @override
  String get salesTitle => 'Ventes';

  @override
  String get salesNewSale => 'Nouvelle vente';

  @override
  String salesCartSection(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return 'Panier · $_temp0';
  }

  @override
  String get salesLoadError => 'Impossible de charger les ventes.';

  @override
  String get salesEmptyTitle => 'Aucune vente enregistrée';

  @override
  String get salesEmptySubtitle =>
      'Touchez \"Nouvelle vente\" pour enregistrer la première.';

  @override
  String get salesSearchHint => 'Rechercher une vente...';

  @override
  String get periodYesterday => 'Hier';

  @override
  String get paymentFilterCard => 'Carte';

  @override
  String get paymentFilterAll => 'Toutes';

  @override
  String get salesStatusPaid => 'Payée';

  @override
  String get salesFilterAll => 'Toutes';

  @override
  String get salesFilterActive => 'Actives';

  @override
  String get salesFilterCancelled => 'Annulées';

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
      other: '$count ventes',
      one: '1 vente',
      zero: '0 ventes',
    );
    return '$_temp0';
  }

  @override
  String get salesHeaderVsYesterday => 'vs hier';

  @override
  String get salesEmptyFilteredTitle => 'Aucune vente trouvée';

  @override
  String get salesEmptyFilteredSubtitle =>
      'Ajustez la recherche ou les filtres.';

  @override
  String get salesClearFilters => 'Effacer les filtres';

  @override
  String salesFilteredSummary(int count, String total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ventes',
      one: '1 vente',
    );
    return '$_temp0 · Total $total';
  }

  @override
  String get salesItemUnavailable =>
      'Article du panier indisponible. Réessayez.';

  @override
  String salesRegistered(String amount) {
    return 'Vente enregistrée : $amount !';
  }

  @override
  String salesInsufficientStock(String product, int available) {
    return 'Stock insuffisant$product. Disponible : $available.';
  }

  @override
  String salesStockFor(String name) {
    return 'pour $name';
  }

  @override
  String salesProductNotFound(String id) {
    return 'Produit $id introuvable dans le stock.';
  }

  @override
  String get salesRegisterError =>
      'Impossible d\'enregistrer la vente. Réessayez.';

  @override
  String get salesSearchProducts => 'Rechercher un produit...';

  @override
  String get salesNoProductsTitle => 'Aucun produit à vendre';

  @override
  String get salesNoProductsSubtitle =>
      'Enregistrez des produits pour pouvoir vendre.';

  @override
  String get salesConfirm => 'Confirmer la vente';

  @override
  String get saleDetailTitle => 'Détails de la vente';

  @override
  String saleDetailId(String id) {
    return 'Vente $id';
  }

  @override
  String get saleDetailTotalLabel => 'Total de la vente';

  @override
  String get saleDetailItems => 'Articles';

  @override
  String get saleDetailTotal => 'Total';

  @override
  String get saleDetailSnapshot => 'Prix figés au moment de la vente.';

  @override
  String get salesStatusCancelled => 'Annulée';

  @override
  String get saleDetailCancelAction => 'Annuler la vente';

  @override
  String get saleDetailCancelConfirmTitle => 'Annuler cette vente ?';

  @override
  String saleDetailCancelConfirmBody(String amount) {
    return 'Stock restitué et caisse annulée ($amount).';
  }

  @override
  String get saleDetailCancelConfirm => 'Oui, annuler';

  @override
  String get saleDetailCancelledAt => 'Annulée le';

  @override
  String get saleCancelledSuccess => 'Vente annulée.';

  @override
  String get saleNotFoundError => 'Cette vente n\'existe plus.';

  @override
  String get saleCancelError => 'Impossible d\'annuler la vente. Réessayez.';

  @override
  String get saleDetailShareAction => 'Partager le reçu';

  @override
  String get saleDetailShareTitle => 'Partager le reçu';

  @override
  String get saleDetailShareImage => 'Partager en image';

  @override
  String get saleDetailShareWhatsApp => 'WhatsApp';

  @override
  String get saleDetailShareError =>
      'Impossible de partager le reçu. Réessayez.';

  @override
  String get saleDetailShareWhatsAppError =>
      'Impossible d\'ouvrir WhatsApp. Réessayez.';

  @override
  String get saleDetailReceiptTitle => 'REÇU DE VENTE';

  @override
  String get saleDetailReceiptTitleCancelled => 'REÇU DE VENTE (ANNULÉE)';

  @override
  String get saleDetailReceiptPayment => 'Paiement';

  @override
  String get saleDetailReceiptThanks => 'Merci de votre achat !';

  @override
  String get adminTitle => 'Panneau du super administrateur';

  @override
  String get adminNavRequests => 'Demandes';

  @override
  String get adminNavPlans => 'Forfaits';

  @override
  String get adminNavUpgrades => 'Évolutions';

  @override
  String get adminTenantsTitle => 'Tenants';

  @override
  String get adminPendingOnly => 'En attente';

  @override
  String get adminAll => 'Tous';

  @override
  String adminAwaitingCount(int count) {
    return '$count en attente d\'approbation';
  }

  @override
  String get adminTenantsEmpty => 'Aucun tenant enregistré.';

  @override
  String get adminRequestsLoadError => 'Impossible de charger les demandes.';

  @override
  String get adminNothingPendingTitle => 'Rien en attente';

  @override
  String get adminNothingPendingSubtitle =>
      'Les nouvelles demandes apparaîtront ici.';

  @override
  String get adminTenantsLoadError => 'Impossible de charger les tenants.';

  @override
  String get adminRejectError => 'Impossible de rejeter la demande.';

  @override
  String get adminApproveError => 'Impossible d\'approuver la demande.';

  @override
  String adminAccessApproved(String name) {
    return 'Accès de $name approuvé !';
  }

  @override
  String adminRequestRejected(String name) {
    return 'Demande de $name rejetée.';
  }

  @override
  String adminRejectTitle(String name) {
    return 'Rejeter $name';
  }

  @override
  String get adminRejectReasonLabel => 'Motif du rejet';

  @override
  String get adminRejectReasonHint => 'Ex. : informations incomplètes';

  @override
  String get adminApprove => 'Approuver';

  @override
  String get adminReject => 'Rejeter';

  @override
  String adminPlanLabel(String plan) {
    return 'Forfait : $plan';
  }

  @override
  String adminPlanSolicited(String plan, String date) {
    return 'Forfait : $plan · Demandé : $date';
  }

  @override
  String get adminPlansTitle => 'Forfaits';

  @override
  String get adminPlanNewTooltip => 'Nouveau forfait';

  @override
  String get adminPlansLoadError => 'Impossible de charger les forfaits.';

  @override
  String get adminPlansEmptyTitle => 'Aucun forfait créé';

  @override
  String get adminPlansEmptySubtitle =>
      'Créez le premier forfait pour les abonnements.';

  @override
  String get adminPlanInactive => 'Inactif';

  @override
  String adminPlanDetails(String price, int stores, int employees) {
    return '$price/mois · $stores magasin(s) · $employees employé(s)';
  }

  @override
  String get adminPlanNameError => 'Indiquez le nom du forfait.';

  @override
  String get adminPlanPriceError => 'Indiquez un prix valide (≥ 0).';

  @override
  String get adminPlanStoresError =>
      'Le forfait doit autoriser au moins 1 magasin.';

  @override
  String get adminPlanEmployeesError =>
      'Le forfait doit autoriser au moins 1 employé.';

  @override
  String adminPlanCreated(String name) {
    return 'Forfait $name créé !';
  }

  @override
  String adminPlanUpdated(String name) {
    return 'Forfait $name mis à jour !';
  }

  @override
  String get adminPlanSaveError =>
      'Impossible d\'enregistrer le forfait. Réessayez.';

  @override
  String get adminPlanNewTitle => 'Nouveau forfait';

  @override
  String get adminPlanEditTitle => 'Modifier le forfait';

  @override
  String get adminPlanNameLabel => 'Nom du forfait';

  @override
  String get adminPlanPriceLabel => 'Prix mensuel';

  @override
  String get adminPlanMaxStores => 'Max. magasins';

  @override
  String get adminPlanMaxEmployees => 'Max. employés';

  @override
  String get adminPlanActiveTitle => 'Forfait actif';

  @override
  String get adminPlanActiveSubtitle =>
      'Désactivez pour empêcher les nouveaux abonnements.';

  @override
  String get adminPlanCreate => 'Créer le forfait';

  @override
  String get adminUpgradesTitle => 'Évolutions de forfait';

  @override
  String get adminUpgradesLoadError =>
      'Impossible de charger les demandes d\'évolution.';

  @override
  String get adminUpgradesEmptyTitle => 'Aucune évolution en attente';

  @override
  String get adminUpgradesEmptySubtitle =>
      'Les demandes de changement apparaissent ici.';

  @override
  String get adminUpgradeApproved =>
      'Évolution approuvée — forfait mis à jour !';

  @override
  String get adminUpgradeRejected => 'Évolution rejetée.';

  @override
  String get adminUpgradeProcessError => 'Impossible de traiter la demande.';

  @override
  String get adminPlanRequested => 'Demandé';

  @override
  String get adminPlanCurrent => 'Actuel';

  @override
  String get productsExpiryHelp => 'Date de péremption du produit';

  @override
  String get salesBarcodeLabel => 'Code-barres';

  @override
  String get salesBarcodeHint =>
      'Étiquettes de balance et PLU — caméra ou lecteur USB';

  @override
  String get salesBarcodeScan => 'Lire avec la caméra';

  @override
  String get salesBarcodeNotFound => 'Produit introuvable pour ce code.';

  @override
  String get salesBarcodeInvalid => 'Code de balance invalide.';

  @override
  String salesStockLimit(String product) {
    return 'Limite de stock atteinte pour $product.';
  }

  @override
  String get salesQuantityLabel => 'Quantité';

  @override
  String get salesQuantityHint => 'Quantité (ex. : 1,75)';

  @override
  String get purchasesExpiryLabel => 'Date de péremption';

  @override
  String get purchasesExpiryAdd => 'Définir la péremption';

  @override
  String get purchasesExpiryHelp => 'Date de péremption du lot';

  @override
  String get dashboardExpiryAlerts => 'Péremption';

  @override
  String dashboardExpiredIn(int days) {
    return 'Périmé depuis $days jour(s)';
  }

  @override
  String dashboardExpiresIn(int days) {
    return 'Expire dans $days jour(s)';
  }
}
