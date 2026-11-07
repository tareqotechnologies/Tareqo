// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
  String get onboardingCurrencyLabel => 'Devise';

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
      'Connexion, magasins, produits, ventes, crédit et rapports';

  @override
  String get supportTroubleshooting => 'Dépannage';

  @override
  String get supportTroubleshootingHint =>
      'Résolvez les problèmes de connexion, ventes, stock et réseau';

  @override
  String get supportReadingError => 'Impossible d\'ouvrir le document.';

  @override
  String get supportSearchHint => 'Rechercher dans l\'aide';

  @override
  String get supportContactSupport => 'Contactez le support';

  @override
  String get supportContactSupportHint => 'Notre équipe peut vous aider';

  @override
  String get supportHelpCenter => 'Centre d\'aide';

  @override
  String get supportContactMessage =>
      'Bonjour ! J\'ai besoin d\'aide avec TAREQO.';

  @override
  String get supportOpenError => 'Impossible d\'ouvrir le support.';

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
  String storeSwitcherA11yLabel(String store) {
    return 'Magasin : $store';
  }

  @override
  String get storeSelectorSectionTitle => 'Magasin actif';

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
  String get authErrorCheckConnection =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get authErrorLoadAccount => 'Compte non chargé';

  @override
  String get splashLoading => 'Ouverture de votre session…';

  @override
  String get appLockTitle => 'TAREQO verrouillé';

  @override
  String get appLockMessage =>
      'Touchez le capteur ou utilisez la reconnaissance faciale pour déverrouiller TAREQO.';

  @override
  String get appLockUnlock => 'Déverrouiller';

  @override
  String get appLockError =>
      'Impossible de vous authentifier. Réessayez ou déconnectez-vous.';

  @override
  String get biometricSignInTitle => 'Authentification biométrique';

  @override
  String get biometricHint => 'Touchez le capteur';

  @override
  String get biometricCancel => 'Annuler';

  @override
  String get biometricFallbackTitle => 'Utiliser le mot de passe';

  @override
  String get biometricGoToSettingsButton => 'Réglages';

  @override
  String get biometricGoToSettingsDescription =>
      'Configurez l\'authentification biométrique';

  @override
  String get biometricLockOut => 'Réessayez plus tard';

  @override
  String get biometricReason => 'Authentification biométrique';

  @override
  String get loginSubtitleSignUp => 'Créez votre compte pour commencer';

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
  String get loginConfirmError => 'Les mots de passe ne correspondent pas.';

  @override
  String get loginSignUp => 'S\'inscrire';

  @override
  String get loginSignIn => 'Se connecter';

  @override
  String get loginSignUpSuccess =>
      'Compte créé ! Confirmez votre e-mail pour vous connecter.';

  @override
  String get loginSignUpError => 'Impossible de créer le compte. Réessayez.';

  @override
  String get loginNoConnection =>
      'Pas de connexion Internet. Vérifiez le Wi-Fi/données mobiles et réessayez.';

  @override
  String get loginSignInError =>
      'Impossible de se connecter. Vérifiez l\'e-mail et le mot de passe.';

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
  String get setNewPasswordSamePassword =>
      'Le nouveau mot de passe doit être différent de l\'actuel.';

  @override
  String get setNewPasswordSessionExpired =>
      'Le lien de réinitialisation a expiré ou a déjà été utilisé. Demandez un nouveau lien.';

  @override
  String get setNewPasswordRateLimited =>
      'Trop de tentatives. Attendez un instant et réessayez.';

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
  String get passwordSameAsCurrent =>
      'Le nouveau mot de passe doit être différent de l\'actuel.';

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
  String syncErrorsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en erreur',
      one: '1 en erreur',
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
  String get dashboardOwnerFallback => 'Propriétaire';

  @override
  String get commonUnits => 'un.';

  @override
  String get dashboardQuickActions => 'Actions rapides';

  @override
  String get dashboardModuleCustomers => 'Clients';

  @override
  String get dashboardModulePurchases => 'Achats';

  @override
  String get dashboardModuleReports => 'Rapports';

  @override
  String get dashboardModuleStores => 'Magasins';

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
  String get employeesUpdateError =>
      'Impossible de mettre à jour l\'employé. Réessayez.';

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
  String get employeeDetailEmail => 'E-mail';

  @override
  String get employeeDetailStore => 'Magasin';

  @override
  String get employeeDetailRole => 'Niveau d\'accès';

  @override
  String get employeeDetailStatus => 'Statut';

  @override
  String get employeeDetailActive => 'Actif';

  @override
  String get employeeDetailInactive => 'Inactif';

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
  String get addStorePhoneLabel => 'Téléphone (facultatif)';

  @override
  String get addStoreEmailLabel => 'E-mail (facultatif)';

  @override
  String get addStoreNuitLabel => 'NUIT (facultatif)';

  @override
  String get addStoreCityLabel => 'Ville (facultatif)';

  @override
  String get storeDetailPhone => 'Téléphone';

  @override
  String get storeDetailEmail => 'E-mail';

  @override
  String get storeDetailNuit => 'NUIT';

  @override
  String get storeDetailCity => 'Ville';

  @override
  String get storeDetailAddress => 'Adresse';

  @override
  String addStoreSuccess(String name) {
    return 'Magasin $name créé !';
  }

  @override
  String get addStoreError => 'Impossible de créer le magasin. Réessayez.';

  @override
  String get addStoreSubmit => 'Créer le magasin';

  @override
  String get editStoreTitle => 'Modifier le magasin';

  @override
  String get editStoreSubmit => 'Enregistrer les modifications';

  @override
  String editStoreSuccess(String name) {
    return 'Magasin $name mis à jour !';
  }

  @override
  String get editStoreError =>
      'Impossible de mettre à jour le magasin. Réessayez.';

  @override
  String get editStoreAction => 'Modifier';

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
  String get commonUndo => 'Annuler l\'action';

  @override
  String get commonCopied => 'Copié dans le presse-papiers';

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
  String get productsFilterAll => 'Tous';

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
  String get productsSalePrice => 'Prix de vente';

  @override
  String get productsStockQuantity => 'Quantité en stock';

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
  String get productsInactive => 'Inactif';

  @override
  String get productsFilterTooltip => 'Filtrer';

  @override
  String get productsFilterAdvanced => 'Filtres avancés';

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
  String get productsTypeLabel => 'Type de produit';

  @override
  String get productsTypeRawMaterial => 'Matière première';

  @override
  String get productsTypeResale => 'Revente';

  @override
  String get productsTypeManufactured => 'Fabriqué';

  @override
  String get productsTypeComposite => 'Composé';

  @override
  String get productsTypePackaging => 'Emballage';

  @override
  String get productsFilterType => 'Type';

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
  String get productsPhotoTake => 'Prendre une photo';

  @override
  String get productsPhotoGallery => 'Choisir depuis la galerie';

  @override
  String get productsPhotoRemove => 'Retirer la photo';

  @override
  String get productsPhotoRemoveConfirm =>
      'Supprimer la photo du produit ? L\'image actuelle sera retirée à l\'enregistrement.';

  @override
  String get productsPhotoTitle => 'Photo du produit';

  @override
  String get productsPhotoAdd => 'Ajouter une photo';

  @override
  String get productsPhotoChangeHint => 'Touchez pour modifier';

  @override
  String get productsPhotoOptionalHint =>
      'Facultatif — appareil photo ou galerie';

  @override
  String get productsPurchasePriceError => 'Indiquez le prix d\'achat';

  @override
  String get productsSalePriceError => 'Indiquez le prix de vente';

  @override
  String get productsStockError => 'Quantité invalide';

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
  String get purchaseDetailTitle => 'Détails de l\'achat';

  @override
  String get purchaseDetailSupplier => 'Fournisseur';

  @override
  String get purchaseDetailDate => 'Date et heure';

  @override
  String get purchaseDetailPayment => 'Paiement';

  @override
  String get purchaseDetailExpiry => 'Péremption du lot';

  @override
  String get purchaseDetailNoExpiry => 'Sans péremption';

  @override
  String get purchaseDetailStockNote => 'Stock mis à jour via lot FIFO.';

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
  String get purchasesNoPurchasableTitle => 'Aucun produit achetable';

  @override
  String get purchasesNoPurchasableSubtitle =>
      'Les produits fabriqués et composés viennent de la production interne. Seules les matières premières, la revente et les emballages s\'achètent.';

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
  String get financialPeriodBalance => 'Solde net de la période';

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
  String get debtsTitle => 'Crédit';

  @override
  String get debtsHeaderSubtitle => 'Crédit à recevoir et à payer';

  @override
  String get debtsAddDebt => 'Enregistrer un crédit';

  @override
  String get debtsDataSection => 'Détails du crédit';

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
  String salesCartItemRemoved(String name) {
    return 'Article retiré du panier : $name.';
  }

  @override
  String get salesLoadError => 'Impossible de charger les ventes.';

  @override
  String get salesEmptyTitle => 'Aucune vente enregistrée';

  @override
  String get salesEmptySubtitle =>
      'Touchez \"Nouvelle vente\" pour enregistrer la première.';

  @override
  String get periodYesterday => 'Hier';

  @override
  String get periodWeek => 'Cette semaine';

  @override
  String get paymentFilterCard => 'Carte';

  @override
  String get paymentFilterAll => 'Toutes';

  @override
  String get salesStatusPaid => 'Payée';

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
  String get salesNoSellableTitle => 'Aucun produit vendable';

  @override
  String get salesNoSellableSubtitle =>
      'Les matières premières et les emballages ne sont pas vendus au comptoir. Changez le type du produit en revente, fabriqué ou composé pour le vendre.';

  @override
  String get salesConfirm => 'Confirmer la vente';

  @override
  String get saleDetailTitle => 'Détails de la vente';

  @override
  String saleDetailId(String id) {
    return 'Vente $id';
  }

  @override
  String get saleDetailView => 'Voir les détails';

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
  String get saleDetailCancelBiometricReason =>
      'Confirmez votre identité pour annuler la vente.';

  @override
  String get saleDetailCancelBiometricFailed =>
      'Identité non confirmée. La vente n\'a pas été annulée.';

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
  String get adminPlansLoadError => 'Impossible de charger les forfaits.';

  @override
  String get adminPlansEmptyTitle => 'Aucun forfait créé';

  @override
  String get adminPlansEmptySubtitle =>
      'Créez le premier forfait pour les abonnements.';

  @override
  String get adminPlanInactive => 'Inactif';

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
  String get productsCodeLabel => 'Code-barres (PLU)';

  @override
  String get productsCodeHint => 'Balances étiqueteuses (ex. : 12345)';

  @override
  String get productsCodeError =>
      'Code invalide : utilisez jusqu\'à 5 chiffres.';

  @override
  String get productsWeighLabel => 'Vente au poids (fraction)';

  @override
  String get productsWeighHint =>
      'Accepte les quantités décimales (ex. : 1,75 kg)';

  @override
  String get productsUnitLabel => 'Unité de vente';

  @override
  String get productsStockWeightHint => 'En unités de vente (ex. : 1,75)';

  @override
  String get productsExpiryLabel => 'Date de péremption';

  @override
  String get productsExpiryAdd => 'Définir la péremption';

  @override
  String get productsExpiryHelp => 'Date de péremption du produit';

  @override
  String get productsExpiryClear => 'Retirer la péremption';

  @override
  String get salesBarcodeLabel => 'Code-barres';

  @override
  String get salesBarcodeHint =>
      'Étiquettes de balance et PLU — caméra ou lecteur USB';

  @override
  String get salesBarcodeScan => 'Lire avec la caméra';

  @override
  String get salesBarcodeCameraHint => 'Pointez la caméra vers le code-barres';

  @override
  String salesBarcodeCameraUnavailable(String error) {
    return 'Caméra indisponible : $error';
  }

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
  String dashboardExpiredIn(int days) {
    return 'Périmé depuis $days jour(s)';
  }

  @override
  String dashboardExpiresIn(int days) {
    return 'Expire dans $days jour(s)';
  }

  @override
  String get adminNavDashboard => 'Vue d\'ensemble';

  @override
  String get adminNavAuditLog => 'Journal d\'audit';

  @override
  String get adminDashboardTitle => 'Vue d\'ensemble';

  @override
  String get adminDashboardTotalTenants => 'Total tenants';

  @override
  String get adminDashboardActiveTenants => 'Actifs';

  @override
  String get adminDashboardPendingTenants => 'En attente d\'approbation';

  @override
  String get adminDashboardPendingUpgrades => 'Évolutions en attente';

  @override
  String get adminDashboardTotalPlans => 'Forfaits';

  @override
  String get adminDashboardLoadError =>
      'Impossible de charger la vue d\'ensemble.';

  @override
  String get adminAuditLogEmpty => 'Aucune action enregistrée.';

  @override
  String get adminAuditLogEmptySubtitle =>
      'Les actions admin apparaîtront ici.';

  @override
  String get adminTenantDetailOwner => 'ID du propriétaire';

  @override
  String get adminTenantDetailPlan => 'Forfait';

  @override
  String get adminTenantDetailStores => 'Magasins';

  @override
  String get adminTenantDetailEmployees => 'Employés';

  @override
  String get adminTenantDetailStatus => 'Statut';

  @override
  String get adminTenantDetailCreated => 'Créé le';

  @override
  String get adminTenantDetailCurrency => 'Devise';

  @override
  String get adminTenantDetailLanguage => 'Langue';

  @override
  String get adminTenantDetailRejectionReason => 'Motif du rejet';

  @override
  String get adminTenantDetailApprovedAt => 'Approuvé le';

  @override
  String adminTenantDetailStoresCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count magasins',
      one: '1 magasin',
    );
    return '$_temp0';
  }

  @override
  String adminTenantDetailEmployeesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count employés',
      one: '1 employé',
    );
    return '$_temp0';
  }

  @override
  String get adminTenantSearchHint => 'Rechercher tenants...';

  @override
  String get adminTenantDetailNoStores => 'Aucun magasin créé';

  @override
  String get adminTenantDetailNoEmployees => 'Aucun employé lié';

  @override
  String get adminTenantDetailActivity => 'Activité récente';

  @override
  String get adminTenantDetailNoActivity =>
      'Aucune activité récente pour ce tenant';

  @override
  String adminTenantDetailActivityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions récentes',
      one: '1 action récente',
    );
    return '$_temp0';
  }

  @override
  String adminTenantDetailEmployeeRole(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'manager': 'Gestionnaire',
      'other': 'Employé',
    });
    return '$_temp0';
  }

  @override
  String get adminAuditLogAction => 'Action';

  @override
  String get adminAuditLogEntity => 'Entité';

  @override
  String get adminAuditLogDate => 'Date';

  @override
  String get adminAuditLogActor => 'Acteur';

  @override
  String get adminBulkSelectAll => 'Tout sélectionner';

  @override
  String get adminBulkDeselectAll => 'Tout désélectionner';

  @override
  String adminBulkApprove(Object count) {
    return 'Approuver ($count)';
  }

  @override
  String adminBulkReject(Object count) {
    return 'Rejeter ($count)';
  }

  @override
  String adminBulkRejectTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants',
      one: 'tenant',
    );
    return 'Rejeter $count $_temp0';
  }

  @override
  String adminBulkApproveSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants approuvés',
      one: 'tenant approuvé',
    );
    return '$count $_temp0';
  }

  @override
  String adminBulkRejectSuccess(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tenants rejetés',
      one: 'tenant rejeté',
    );
    return '$count $_temp0';
  }

  @override
  String get adminBulkApproveError =>
      'Erreur lors de l\'approbation. Certains tenants peuvent ne pas avoir été traités.';

  @override
  String get adminBulkRejectError =>
      'Erreur lors du rejet. Certains tenants peuvent ne pas avoir été traités.';

  @override
  String get adminActionManagePlans => 'Gérer les forfaits';

  @override
  String get adminActionViewAuditLog => 'Voir le journal d\'audit';

  @override
  String get adminTenantRequests => 'Demandes de tenant';

  @override
  String get adminPlanUpgrades => 'Évolutions de forfait';

  @override
  String adminPendingActionRequired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions requises',
      one: '1 action requise',
    );
    return '$_temp0';
  }

  @override
  String get adminAuditLogAll => 'Tous';

  @override
  String get adminAuditLogTenants => 'Tenants';

  @override
  String get adminAuditLogPlans => 'Forfaits';

  @override
  String get adminAuditLogUpgrades => 'Évolutions';

  @override
  String get adminAuditLogApproved => 'Approuvés';

  @override
  String get adminAuditLogRejected => 'Rejetés';

  @override
  String get adminAuditLogToday => 'Aujourd\'hui';

  @override
  String get adminAuditLogYesterday => 'Hier';

  @override
  String get adminAuditLogThisWeek => 'Cette semaine';

  @override
  String get adminAuditLogOlder => 'Plus ancien';

  @override
  String get adminAuditLogSearchHint => 'Rechercher dans le journal...';

  @override
  String get adminAuditLogNoResults =>
      'Aucune entrée ne correspond à votre filtre.';

  @override
  String get adminDashboardPlanDistribution => 'Distribution des forfaits';

  @override
  String get adminDashboardRecentActivity => 'Activité récente';

  @override
  String get adminGrowthTrends => 'Tendances de Croissance';

  @override
  String get adminGrowthTrendsLabel => 'Tendances (8 semaines)';

  @override
  String get adminGrowthThisWeek => 'Cette semaine';

  @override
  String get adminGrowthLastWeek => 'Semaine dernière';

  @override
  String get adminGrowthThisMonth => 'Ce mois-ci';

  @override
  String get adminGrowthLastMonth => 'Mois dernier';

  @override
  String get adminGrowthNewTenants => 'Nouveaux tenants';

  @override
  String get adminGrowthNewTenantsMonth => 'Nouveaux tenants ce mois';

  @override
  String get adminGrowthApprovals => 'Approbations';

  @override
  String adminGrowthUp(String count) {
    return '+$count';
  }

  @override
  String adminGrowthDown(String count) {
    return '-$count';
  }

  @override
  String get adminGrowthFlat => 'Aucun changement';

  @override
  String get adminGrowthRegistrationsTrend =>
      'Inscriptions (8 dernières semaines)';

  @override
  String get adminGrowthActivityTrend => 'Activité (8 dernières semaines)';

  @override
  String get adminGrowthNoData => 'Pas assez de données pour les tendances';

  @override
  String get adminNavInvoices => 'Factures';

  @override
  String get adminInvoicesTitle => 'Factures de facturation';

  @override
  String get adminInvoicesEmpty => 'Aucune facture générée.';

  @override
  String get adminInvoicesEmptyPending => 'Aucune facture en attente.';

  @override
  String get adminInvoicesLoadError => 'Impossible de charger les factures.';

  @override
  String get adminInvoiceSearchHint => 'Rechercher des factures...';

  @override
  String get adminInvoiceAmount => 'Montant :';

  @override
  String get adminInvoiceDue => 'Échéance :';

  @override
  String get adminInvoicePaidAt => 'Payée le :';

  @override
  String get adminInvoiceMarkPaid => 'Marquer comme payée';

  @override
  String get adminInvoiceMarkedPaid => 'Facture marquée comme payée !';

  @override
  String get adminInvoiceMarkPaidError =>
      'Impossible de marquer comme payée. Réessayez.';

  @override
  String get adminInvoiceCancel => 'Annuler';

  @override
  String get adminInvoiceCancelled => 'Facture annulée.';

  @override
  String get adminInvoiceCancelError =>
      'Impossible d\'annuler la facture. Réessayez.';

  @override
  String get adminInvoiceCancelTitle => 'Annuler la facture ?';

  @override
  String adminInvoiceCancelConfirm(String period) {
    return 'Annuler la facture de $period ?';
  }

  @override
  String get adminInvoiceCancelConfirmButton => 'Oui, annuler';

  @override
  String get invoiceStatusPending => 'En attente';

  @override
  String get invoiceStatusPaid => 'Payée';

  @override
  String get invoiceStatusExpired => 'Expirée';

  @override
  String get invoiceStatusCancelled => 'Annulée';

  @override
  String get notificationInvoiceGenerated => 'Nouvelle facture générée';

  @override
  String get notificationInvoiceDueSoon => 'Facture bientôt due';

  @override
  String get notificationInvoiceExpired => 'Facture expirée';

  @override
  String get notificationInvoicePaid => 'Facture payée';

  @override
  String get notificationMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notificationMarkRead => 'Marquer comme lu';

  @override
  String get notificationNoNotifications => 'Aucune notification';

  @override
  String get notificationNoNotificationsHint =>
      'Les notifications de factures apparaîtront ici.';

  @override
  String get notificationTabAll => 'Toutes';

  @override
  String get notificationTabUnread => 'Non lues';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get menuNotifications => 'Notifications';

  @override
  String notificationSinceDaysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get notificationYesterday => 'Hier';

  @override
  String get notificationJustNow => 'À l\'instant';

  @override
  String get notificationAdminLabelQuote => 'Devis';

  @override
  String get notificationAdminLabelValidity => 'Validité';

  @override
  String get notificationAdminLabelExpiring => 'Expire';

  @override
  String get notificationAdminLabelGeneral => 'Général';

  @override
  String get notificationAddonExpiringTitle => 'Add-on bientôt expiré';

  @override
  String get notificationAddonExpiredTitle => 'Add-on expiré';

  @override
  String notificationBodyInvoiceGenerated(
    String period,
    String amount,
    String currency,
    String dueDate,
  ) {
    return 'Facture $period d\'un montant de $amount $currency. Échéance : $dueDate.';
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
      other: '$days jours',
      one: '1 jour',
    );
    return 'La facture $period d\'un montant de $amount $currency arrive à échéance dans $_temp0. Merci de régulariser le paiement.';
  }

  @override
  String notificationBodyInvoiceExpired(
    String period,
    String amount,
    String currency,
  ) {
    return 'La facture $period d\'un montant de $amount $currency a expiré sans paiement. L\'accès peut être suspendu.';
  }

  @override
  String notificationBodyInvoicePaid(
    String period,
    String amount,
    String currency,
  ) {
    return 'La facture $period d\'un montant de $amount $currency a été marquée comme payée. Merci !';
  }

  @override
  String notificationBodyAddOnExpired(String addonName, String date) {
    return 'Le service « $addonName » a expiré le $date. Renouvelez l\'abonnement pour continuer à l\'utiliser.';
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
      other: '$days jours',
      one: '1 jour',
    );
    return 'Le service « $addonName » expire dans $_temp0 ($date). Renouvelez pour éviter l\'interruption.';
  }

  @override
  String get notificationIconInvoice => 'Facture';

  @override
  String get notificationIconDue => 'Échéance';

  @override
  String get notificationIconExpired => 'Expirée';

  @override
  String get notificationIconPaid => 'Payée';

  @override
  String get notificationIconExpiring => 'Expire';

  @override
  String get notificationIconExpiredShort => 'Expiré';

  @override
  String notificationDaysShort(int days) {
    return '${days}j';
  }

  @override
  String get adminMessagesTitle => 'Messages aux Tenants';

  @override
  String get adminMessagesSendSuccess => 'Message envoyé !';

  @override
  String get adminMessagesSendError =>
      'Impossible d\'envoyer le message. Réessayez.';

  @override
  String get adminMessagesTenantLabel => 'Tenant';

  @override
  String get adminMessagesTenantError => 'Sélectionnez un tenant.';

  @override
  String get adminMessagesTypeLabel => 'Type';

  @override
  String get adminMessagesTitleLabel => 'Titre';

  @override
  String get adminMessagesTitleError => 'Entrez un titre.';

  @override
  String get adminMessagesBodyLabel => 'Message';

  @override
  String get adminMessagesBodyError => 'Entrez le contenu du message.';

  @override
  String get adminMessagesSubmit => 'Envoyer';

  @override
  String get adminNavMessages => 'Messages';

  @override
  String get customInvoiceTitle => 'Facture personnalisée';

  @override
  String get customInvoiceEmpty => 'Aucune facture';

  @override
  String get customInvoiceEmptySubtitle =>
      'Créez des factures professionnelles avec une mise\nen page personnalisée pour vos clients';

  @override
  String get customInvoiceLoadError => 'Impossible de charger les factures.';

  @override
  String get customInvoiceLoadErrorHint =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String customInvoiceCreated(int number) {
    return 'Facture n° $number créée !';
  }

  @override
  String get customInvoiceSaveError =>
      'Impossible de créer la facture. Réessayez.';

  @override
  String get customInvoiceTemplateTooltip => 'Modèle de facture';

  @override
  String get customInvoiceNewFab => 'Nouvelle facture';

  @override
  String customInvoiceItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: '0 article',
    );
    return '$_temp0';
  }

  @override
  String get customInvoiceWhatsApp => 'WhatsApp';

  @override
  String get customInvoiceCreate => 'Créer la facture';

  @override
  String get customInvoiceClientSection => 'Client';

  @override
  String get customInvoiceClientName => 'Nom du client';

  @override
  String get customInvoicePhone => 'Téléphone';

  @override
  String get customInvoiceTaxIdOptional => 'NIF / NUIT (facultatif)';

  @override
  String get customInvoiceProductSection => 'Produit';

  @override
  String get customInvoiceProductPlaceholder => 'Aucun produit enregistré';

  @override
  String customInvoiceProductOption(Object price, Object stock, Object unit) {
    return 'Stock : $stock $unit  •  $price';
  }

  @override
  String get customInvoicePrice => 'Prix (MT)';

  @override
  String get customInvoiceQty => 'Qté';

  @override
  String get customInvoiceAddItem => 'Ajouter';

  @override
  String get customInvoiceDiscount => 'Remise (MT)';

  @override
  String get customInvoiceTax => 'TVA (MT)';

  @override
  String customInvoiceBillTotal(Object total) {
    return 'Total : $total';
  }

  @override
  String customInvoiceNumberPrefix(Object number) {
    return 'N° $number';
  }

  @override
  String get customInvoiceTemplateSaved => 'Modèle enregistré avec succès';

  @override
  String get customInvoiceTemplateLogoSection => 'Logo de l\'entreprise';

  @override
  String get customInvoiceTemplateLogoHint => 'Touchez pour charger un logo';

  @override
  String get customInvoiceTemplateColorSection => 'Couleur principale';

  @override
  String get customInvoiceTemplateCompanySection =>
      'Informations de l\'entreprise';

  @override
  String get customInvoiceTemplateCompanyName => 'Nom de l\'entreprise';

  @override
  String get customInvoiceTemplateAddress => 'Adresse';

  @override
  String get customInvoiceTemplateTaxId => 'NIF / NUIT';

  @override
  String get customInvoiceTemplateStyle => 'Style';

  @override
  String get customInvoiceTemplateStyleClassic => 'Classique';

  @override
  String get customInvoiceTemplateStyleModern => 'Moderne';

  @override
  String get customInvoiceTemplateStyleCompact => 'Compact';

  @override
  String get customInvoiceTemplateSave => 'Enregistrer le modèle';

  @override
  String get customInvoicePreviewCompanyFallback => 'Nom de l\'entreprise';

  @override
  String get customInvoicePreviewSampleItemA => 'Produit A';

  @override
  String get customInvoicePreviewSampleItemB => 'Produit B';

  @override
  String get customInvoicePreviewSampleClient => 'João Silva';

  @override
  String customInvoicePreviewTotal(String total) {
    return 'TOTAL : $total';
  }

  @override
  String get customInvoicePreviewFooter => 'Généré par TAREQO';

  @override
  String get quotationTitle => 'Devis';

  @override
  String get quotationEmpty => 'Aucun devis';

  @override
  String get quotationEmptySubtitle =>
      'Créez des devis et des estimations pour vos clients';

  @override
  String get quotationLoadError => 'Impossible de charger les devis.';

  @override
  String get quotationLoadErrorHint => 'Vérifiez votre connexion et réessayez.';

  @override
  String quotationCreated(int number) {
    return 'Devis n° $number créé !';
  }

  @override
  String get quotationSaveError => 'Impossible de créer le devis. Réessayez.';

  @override
  String get quotationStatusSaved => 'Statut du devis mis à jour';

  @override
  String get quotationStatusError =>
      'Impossible de mettre à jour le devis. Réessayez.';

  @override
  String get quotationTemplateTooltip => 'Modèle de devis';

  @override
  String get quotationNewFab => 'Nouveau devis';

  @override
  String quotationItemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
      zero: '0 article',
    );
    return '$_temp0';
  }

  @override
  String get quotationValidity => 'Validité';

  @override
  String quotationDays(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get quotationSend => 'Envoyer';

  @override
  String get quotationAccept => 'Accepter';

  @override
  String get quotationReject => 'Refuser';

  @override
  String get quotationStatusDraft => 'Brouillon';

  @override
  String get quotationStatusSent => 'Envoyé';

  @override
  String get quotationStatusAccepted => 'Accepté';

  @override
  String get quotationStatusRejected => 'Refusé';

  @override
  String get quotationPhoneOptional => 'Téléphone (facultatif)';

  @override
  String quotationNumberPrefix(Object number) {
    return 'N° $number';
  }

  @override
  String get quotationSave => 'Enregistrer le devis';

  @override
  String get quotationTemplatePhone => 'Téléphone';

  @override
  String get quotationTemplatePreview => 'Devis • Aperçu';

  @override
  String get quotationTemplatePreviewBadge => 'Aperçu';

  @override
  String get palettePetrol => 'Bleu pétrole';

  @override
  String get paletteSlate => 'Ardoise';

  @override
  String get paletteTerracotta => 'Terracotta';

  @override
  String get paletteBeige => 'Beige';

  @override
  String get paletteWarmGray => 'Gris chaud';

  @override
  String get palettePetrolInk => 'Encre pétrole';

  @override
  String get paletteSlateInk => 'Encre ardoise';

  @override
  String get paletteSoftBlack => 'Noir doux';

  @override
  String get customInvoicePdf => 'PDF';

  @override
  String get imageSourceGallery => 'Galerie';

  @override
  String get imageSourceCamera => 'Caméra';

  @override
  String get businessFallbackName => 'Mon entreprise';

  @override
  String get customInvoiceWhatsAppHeader => '═══ FACTURE ═══';

  @override
  String get customInvoiceNumberShort => 'N°';

  @override
  String get customInvoiceClientLabel => 'Client';

  @override
  String get customInvoicePhoneLabel => 'Tél';

  @override
  String get customInvoiceTotalLabel => 'TOTAL';

  @override
  String get customInvoiceNew => 'Nouvelle facture';

  @override
  String get customInvoiceTemplateTitle => 'Modèle de facture';

  @override
  String get commonPreview => 'Aperçu';

  @override
  String get quotationWhatsAppHeader => '═══ DEVIS ═══';

  @override
  String get quotationTemplateTitle => 'Modèle de devis';

  @override
  String get employeeMgmtTitle => 'Gestion des employés';

  @override
  String get employeeMgmtTabAttendance => 'Pointage';

  @override
  String get employeeMgmtTabCommissions => 'Commissions';

  @override
  String get employeeMgmtTabTargets => 'Objectifs';

  @override
  String get employeePresentCount => 'Présents';

  @override
  String get employeeAbsentCount => 'Absents';

  @override
  String get employeeClockInAction => 'Entrer';

  @override
  String get employeeClockOutAction => 'Sortir';

  @override
  String get employeeClockOutInProgress => 'En cours';

  @override
  String get employeeAttendanceSection => 'Registre de pointage';

  @override
  String get employeeRecordsSection => 'Registres du jour';

  @override
  String get employeeAttendanceEmpty =>
      'Aucun employé lié à ce magasin. Créez des comptes dans le module Magasins.';

  @override
  String get employeeMgmtLoadError =>
      'Impossible de charger les données des employés.';

  @override
  String get employeeMgmtNoStoreTitle => 'Aucun magasin actif';

  @override
  String get employeeMgmtNoStoreAttendance =>
      'Terminez l\'onboarding pour pointer.';

  @override
  String get employeeMgmtNoStoreCommissions =>
      'Terminez l\'onboarding pour voir les commissions.';

  @override
  String get employeeMgmtNoStoreTargets =>
      'Terminez l\'onboarding pour définir des objectifs.';

  @override
  String get employeeClockInError => 'Impossible d\'enregistrer l\'entrée.';

  @override
  String get employeeClockOutError => 'Impossible d\'enregistrer la sortie.';

  @override
  String get employeeSalesMonth => 'Ventes du mois';

  @override
  String get employeeCommissionTitle => 'Commissions';

  @override
  String get employeeCommissionPerEmployee => 'Commission par employé';

  @override
  String employeeCommissionRate(int rate, String amount) {
    return '$rate% de $amount';
  }

  @override
  String get employeeCommissionNoRate => 'Aucun taux défini';

  @override
  String get employeeCommissionSetRate => 'Définir le taux';

  @override
  String get employeeCommissionRateLabel => 'Taux de commission (%)';

  @override
  String get employeeCommissionRateSaved => 'Taux de commission mis à jour.';

  @override
  String get employeeCommissionRateError =>
      'Impossible d\'enregistrer le taux.';

  @override
  String get employeeTargetsActive => 'Objectifs actifs';

  @override
  String get employeeTargetsReached => 'Atteints';

  @override
  String get employeeTargetsPending => 'En attente';

  @override
  String get employeeTargetsMonth => 'Objectifs du mois';

  @override
  String get employeeTargetsEmptyTitle => 'Aucun objectif défini';

  @override
  String get employeeTargetsEmptySubtitle =>
      'Définissez des objectifs de vente mensuels pour chaque employé';

  @override
  String get employeeTargetAdd => 'Ajouter un objectif';

  @override
  String employeeTargetMeta(String amount) {
    return 'Objectif : $amount';
  }

  @override
  String get employeeTargetNewTitle => 'Nouvel objectif';

  @override
  String get employeeTargetEmployee => 'Employé';

  @override
  String get employeeTargetAllHave =>
      'Tous les employés ont déjà un objectif défini';

  @override
  String get employeeTargetMonthly => 'Objectif mensuel (MT)';

  @override
  String get employeeTargetSave => 'Enregistrer l\'objectif';

  @override
  String employeeTargetProgress(int progress) {
    return '$progress% de l\'objectif';
  }

  @override
  String get employeeTargetSaved => 'Objectif défini.';

  @override
  String get employeeTargetRemoved => 'Objectif supprimé.';

  @override
  String get employeeTargetError => 'Impossible d\'enregistrer l\'objectif.';

  @override
  String get employeeRoleSales => 'Vendeur';

  @override
  String get addonsTitle => 'Add-ons';

  @override
  String get addonsSubtitle =>
      'Add-ons actifs et disponibles dans votre forfait';

  @override
  String get addonsManagedByAdmin =>
      'L\'activation des add-ons est gérée par l\'administrateur du système.';

  @override
  String get addonsIncluded => 'Inclus';

  @override
  String get addonsActive => 'Actif';

  @override
  String addonsPerMonth(Object amount) {
    return '$amount MT/mois';
  }

  @override
  String get addonCategoryInvoicing => 'Facturation';

  @override
  String get addonCategoryQuotation => 'Devis';

  @override
  String get addonCategoryReports => 'Rapports';

  @override
  String get addonCategoryEmployees => 'Employés';

  @override
  String get addonCategoryMultiStore => 'Multi-magasins';

  @override
  String get addonCategoryPayments => 'Paiements';

  @override
  String get commonTotal => 'Total';

  @override
  String get addonCustomInvoiceName => 'Facture personnalisée';

  @override
  String get addonCustomInvoiceDesc =>
      'Créez des factures professionnelles avec logo, mise en page personnalisable et export PDF. Modèles prêts à l\'emploi et personnalisation des couleurs, polices et champs.';

  @override
  String get addonQuotationName => 'Devis';

  @override
  String get addonQuotationDesc =>
      'Créez et envoyez des devis à vos clients avant la vente. Conversion automatique en vente, validité configurable et envoi par SMS/WhatsApp.';

  @override
  String get addonReportsName => 'Rapports avancés';

  @override
  String get addonReportsDesc =>
      'Rapports financiers, de ventes et de stock avec filtres avancés, comparaisons de période à période et export PDF/Excel. Graphiques interactifs et tableaux de bord personnalisés.';

  @override
  String get addonEmployeesName => 'Gestion des employés';

  @override
  String get addonEmployeesDesc =>
      'Pointage (entrée/sortie), calcul automatique des commissions par vente, définition d\'objectifs mensuels et rapport de performance individuel.';

  @override
  String get addonMultiStoreName => 'Multi-magasins avancé';

  @override
  String get addonMultiStoreDesc =>
      'Transferts de stock entre magasins, rapports consolidés comparant les magasins, gestion centralisée des prix et promotions et alertes de réapprovisionnement automatiques.';

  @override
  String get addonMobileMoneyName => 'Intégration M-Pesa / E-Mola';

  @override
  String get addonMobileMoneyDesc =>
      'Paiements automatiques par mobile money avec réconciliation automatique, notifications de réception en temps réel et rapport des transactions mobile money.';

  @override
  String get transfersTitle => 'Transferts entre magasins';

  @override
  String get transfersEmpty => 'Aucun transfert';

  @override
  String get transfersEmptySubtitle =>
      'Transférez du stock entre les magasins du\nmême tenant de manière traçable';

  @override
  String get transfersNewFab => 'Nouveau transfert';

  @override
  String get transfersOriginStore => 'Magasin d\'origine';

  @override
  String get transfersDestStore => 'Magasin de destination';

  @override
  String get transfersProduct => 'Produit';

  @override
  String get transfersProductPlaceholder => 'Aucun produit enregistré';

  @override
  String get transfersQuantity => 'Quantité';

  @override
  String get transfersAddItem => 'Ajouter';

  @override
  String get transfersExecuting => 'Transfert en cours...';

  @override
  String get transfersExecute => 'Exécuter le transfert';

  @override
  String get transfersNoStoresTitle => 'Enregistrez au moins 2 magasins';

  @override
  String get transfersNoStoresSubtitle =>
      '2 magasins ou plus sont nécessaires\npour transférer du stock';

  @override
  String transfersSuccess(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits transférés',
      one: '1 produit transféré',
    );
    return '$_temp0 avec succès';
  }

  @override
  String transfersError(Object error) {
    return 'Erreur de transfert : $error';
  }

  @override
  String get transferStatusPending => 'En attente';

  @override
  String get transferStatusInTransit => 'En transit';

  @override
  String get transferStatusReceived => 'Reçu';

  @override
  String get transferStatusCancelled => 'Annulé';

  @override
  String get paymentsTitle => 'M-Pesa / E-Mola';

  @override
  String get paymentsIntegrationBlocked =>
      'L\'intégration M-Pesa/E-Mola n\'est pas encore configurée — la réconciliation réelle nécessite l\'API du fournisseur. En attendant, les données affichées ici sont locales et démonstratives.';

  @override
  String get reportsAdvancedTitle => 'Rapports avancés';

  @override
  String get reportsTabSales => 'Ventes';

  @override
  String get reportsTabFinancial => 'Finances';

  @override
  String get reportsTabStock => 'Stock';

  @override
  String get reportsKpiProducts => 'Produits';

  @override
  String get reportsKpiLowStock => 'Stock faible';

  @override
  String get reportsKpiStockValue => 'Valeur du stock';

  @override
  String get reportsKpiRevenue => 'Revenus';

  @override
  String get reportsKpiExpenses => 'Dépenses';

  @override
  String get reportsKpiNetProfit => 'Bénéfice net';

  @override
  String get reportsCashFlow => 'Flux de trésorerie';

  @override
  String get reportsCashFlowChart => 'Graphique du flux de trésorerie';

  @override
  String get reportsStockHealthy => 'Tous les produits ont un stock adéquat';

  @override
  String get reportsExportSales => 'Exporter le rapport (PDF)';

  @override
  String get reportsExportFinancial => 'Exporter les finances (PDF)';

  @override
  String get reportsExportStock => 'Exporter le stock (PDF)';

  @override
  String get reportsNoSalesData => 'Aucune donnée pour cette période';

  @override
  String get reportsPeriodYear => 'Cette année';

  @override
  String get reportsKpiStockOut => 'Rupture de stock';

  @override
  String get reportsKpiTotalProducts => 'Total produits';

  @override
  String pdfGeneratedOn(Object date) {
    return 'Généré : $date';
  }

  @override
  String get pdfIndicators => 'Indicateurs';

  @override
  String pdfFooter(Object date) {
    return 'Document généré par TAREQO — $date';
  }

  @override
  String get pdfInvoiceDocWord => 'FACTURE';

  @override
  String get pdfInvoiceSubjectWord => 'Facture';

  @override
  String get pdfInvoiceFileBase => 'facture';

  @override
  String get pdfQuotationDocWord => 'DEVIS';

  @override
  String get pdfQuotationSubjectWord => 'Devis';

  @override
  String get pdfQuotationFileBase => 'devis';

  @override
  String get pdfClientHeading => 'CLIENT';

  @override
  String pdfPhoneLine(Object value) {
    return 'Tél. : $value';
  }

  @override
  String pdfEmailLine(Object value) {
    return 'E-mail : $value';
  }

  @override
  String pdfNifLine(Object value) {
    return 'NIF : $value';
  }

  @override
  String get pdfItemHeader => 'Article';

  @override
  String get pdfUnitPriceHeader => 'Prix unit.';

  @override
  String get pdfSubtotalHeader => 'Sous-total';

  @override
  String get pdfDiscountLabel => 'Remise';

  @override
  String get pdfTaxLabel => 'TVA';

  @override
  String pdfPaymentLine(Object value) {
    return 'Paiement : $value';
  }

  @override
  String pdfReferenceLine(Object value) {
    return 'Réf. : $value';
  }

  @override
  String get pdfNotesHeading => 'Notes';

  @override
  String get pdfGeneralConditionsHeading => 'Conditions générales';

  @override
  String pdfValidityDaysLeft(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours restants',
      one: '1 jour restant',
    );
    return '$_temp0';
  }

  @override
  String pdfConditionValidBullet(Object date) {
    return 'Cette offre est valable jusqu\'au $date.';
  }

  @override
  String get pdfConditionPricesBullet =>
      'Les prix peuvent changer après la période de validité.';

  @override
  String get pdfConditionContactBullet =>
      'Pour accepter cette offre, veuillez nous contacter.';

  @override
  String get quotationStatusExpired => 'Expirée';

  @override
  String get quotationStatusConverted => 'Convertie en vente';

  @override
  String get pdfConditionsNotesHeading => 'Conditions / Notes';

  @override
  String get adminAddonsActivateBtn => 'Activer';

  @override
  String get adminAddonsActivateBulk => 'Activer l\'add-on';

  @override
  String get adminAddonsActivePill => 'Actifs';

  @override
  String get adminAddonsDeactivateBtn => 'Désactiver';

  @override
  String get adminAddonsInactivePill => 'Inactifs';

  @override
  String adminAddonsLoadError(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get adminAddonsNoTenantsSearchSub =>
      'Essayez un autre terme de recherche';

  @override
  String get adminAddonsNoTenantsTitle => 'Aucun tenant trouvé';

  @override
  String get adminAddonsNoTenantsYetSub =>
      'Aucun tenant approuvé pour l\'instant';

  @override
  String adminAddonsUpdateError(Object error) {
    return 'Erreur lors de la mise à jour de l\'add-on : $error';
  }

  @override
  String get adminBackToList => 'Retour à la liste';

  @override
  String get adminMessagesBodyHint => 'Rédigez votre message…';

  @override
  String get adminMessagesTenantHint => 'Sélectionner un tenant...';

  @override
  String get adminMessagesTitleExample => 'Ex. : Devis du forfait Pro';

  @override
  String get adminNavRevenue => 'Revenus';

  @override
  String get adminPlansActive => 'Actifs';

  @override
  String get adminPlansInactive => 'Inactifs';

  @override
  String get adminRevenueActiveTenants => 'Tenants actifs';

  @override
  String get adminRevenueActiveTenantsSub => 'Total sur la plateforme';

  @override
  String get adminRevenueAvailableAddOns => 'Add-ons disponibles';

  @override
  String get adminRevenueAvailableAddOnsSub => 'Dans le catalogue actif';

  @override
  String get adminRevenueMaxMonthly => 'Revenu mensuel maximal';

  @override
  String get adminRevenueMaxMonthlySub => 'Si tous activaient tout';

  @override
  String get adminRevenuePotential => 'Revenu potentiel';

  @override
  String get adminRevenuePotentialSub => 'Par tenant/mois (tous les add-ons)';

  @override
  String get adminTenantsMonthlyValue => 'Valeur mensuelle';

  @override
  String get adminTenantsNextInvoice => 'Prochaine facture';

  @override
  String get adminTenantsPlanExpiresOn => 'Le forfait expire le';

  @override
  String get adminTenantsTrialEndsOn => 'L\'essai se termine le';

  @override
  String get commonId => 'ID';

  @override
  String dashboardSaleEntry(Object number) {
    return 'Vente $number';
  }

  @override
  String get loginConfirmPasswordHint => 'Répétez votre mot de passe';

  @override
  String get loginConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get loginEmailHint => 'Saisissez votre e-mail';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginNameHint => 'Saisissez votre nom';

  @override
  String get loginPasswordHint => 'Saisissez votre mot de passe';

  @override
  String get loginPromptHaveAccount => 'Déjà un compte ?';

  @override
  String get loginPromptNoAccount => 'Pas encore de compte ?';

  @override
  String get loginTagline => 'Une gestion simple pour votre entreprise';

  @override
  String get loginSecurityFooter =>
      'Vos données sont protégées par chiffrement.';

  @override
  String get mfaCodeFieldLabel => 'Code MFA';

  @override
  String get mfaCodeHint =>
      'Saisissez le code à 6 chiffres de votre application d\'authentification :';

  @override
  String get mfaCodeLengthError => 'Saisissez le code à 6 chiffres';

  @override
  String get mfaConfirmPrompt =>
      'Saisissez le code de l\'application pour confirmer :';

  @override
  String get mfaDigitsFieldLabel => 'Code à 6 chiffres';

  @override
  String mfaExpiresIn(num seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds secondes',
      one: '1 seconde',
    );
    return 'Le code expire dans $_temp0';
  }

  @override
  String mfaInitError(Object error) {
    return 'Erreur lors de l\'initialisation du MFA : $error';
  }

  @override
  String get mfaInvalidCode => 'Code invalide. Réessayez.';

  @override
  String get mfaManualEntryTitle => 'Ou saisissez ce code manuellement :';

  @override
  String get mfaQrScanHelp =>
      'Utilisez votre application d\'authentification (Google Authenticator, Authy, etc.) pour scanner ce code QR :';

  @override
  String get mfaQrScanTitle => 'Scannez le code QR';

  @override
  String get mfaSetupSuccess => 'MFA configuré avec succès !';

  @override
  String get mfaSetupTitle => 'Configurer l\'authentification à deux facteurs';

  @override
  String get mfaVerify => 'Vérifier';

  @override
  String get mfaVerifyAndEnable => 'Vérifier et activer';

  @override
  String mfaVerifyError(Object error) {
    return 'Erreur lors de la vérification du code : $error';
  }

  @override
  String get securityBiometricDisabledSub =>
      'Utilisez l\'empreinte digitale ou la reconnaissance faciale';

  @override
  String get securityBiometricEnabledSub =>
      'Activée — Empreinte digitale ou visage';

  @override
  String get securityBiometricTitle => 'Authentification biométrique';

  @override
  String get securityBiometricUnavailable => 'Indisponible sur cet appareil';

  @override
  String get securityTwoFactorDisabledSub =>
      'Ajoutez une couche de sécurité supplémentaire';

  @override
  String get securityTwoFactorEnabledSub =>
      'Activée — Utilisez une appli d\'authentification';

  @override
  String get securityTwoFactorTitle => 'Authentification à deux facteurs';

  @override
  String get settingsHapticsTitle => 'Retour haptique';

  @override
  String get settingsHapticsSubtitle =>
      'Vibration à la fin des ventes, paiements et confirmations';

  @override
  String get a11yIncreaseQuantity => 'Augmenter la quantité';

  @override
  String get a11yDecreaseQuantity => 'Diminuer la quantité';

  @override
  String get a11yAddFraction => 'Ajouter 0,1 (poids)';

  @override
  String get settingsMfaEnforceError =>
      'Impossible de modifier l\'exigence MFA. Vérifiez la connexion et réessayez.';

  @override
  String get settingsMfaEnforceSubOff =>
      'Désactivé — ventes et caisse fonctionnent avec mot de passe seul';

  @override
  String get settingsMfaEnforceSubOn =>
      'Exigé — les écritures d\'argent demandent le code de l\'application d\'authentification';

  @override
  String get settingsMfaEnforceTitle =>
      'Exiger le MFA pour les opérations d\'argent';

  @override
  String get transfersRowDate => 'Date';

  @override
  String get transfersRowDest => 'Destination';

  @override
  String get transfersRowOrigin => 'Origine';

  @override
  String get transfersRowStatus => 'Statut';

  @override
  String adminAddonsBulkActivated(Object addonName, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$addonName activé pour $_temp0';
  }

  @override
  String adminAddonsBulkDeactivated(Object addonName, num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants',
      one: '1 tenant',
    );
    return '$addonName désactivé pour $_temp0';
  }

  @override
  String adminAddonsBulkSheetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tenants sélectionnés',
      one: '1 tenant sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get adminAddonsBulkSheetTitle => 'Activer des add-ons en masse';

  @override
  String get adminAddonsEditPriceTitle => 'Modifier le prix mensuel';

  @override
  String get adminAddonsEditPriceTooltip => 'Modifier le prix';

  @override
  String adminAddonsPriceUpdated(Object addonName, Object price) {
    return 'Prix de $addonName mis à jour : $price/mois';
  }

  @override
  String get adminAddonsPriceSaveError =>
      'Impossible d’enregistrer le prix. Réessayez.';

  @override
  String get adminAddonsListHint =>
      'Touchez un tenant pour gérer ses add-ons. Touchez l’icône ✓ pour la sélection multiple.';

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
  String get adminRevenueByAddOn => 'Revenus par add-on';

  @override
  String get adminRevenueByCategory => 'Répartition par catégorie';

  @override
  String get adminRevenuePerMonth => 'potentiel/mois';

  @override
  String get adminPlanPerMonthSuffix => '/mois';

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
      other: '$days jours restants',
      one: '1 jour restant',
    );
    return 'Actif : $_temp0';
  }

  @override
  String get adminTenantCycleExpired => 'Expiré';

  @override
  String adminTenantCycleExpiresIn(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return 'Expire dans $_temp0';
  }

  @override
  String adminTenantCycleTrialLeft(num days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours restants',
      one: '1 jour restant',
    );
    return 'Essai : $_temp0';
  }

  @override
  String get validationCustomerNameRequired => 'Renseignez le nom du client.';

  @override
  String get validationDebtAmountPositive =>
      'Le montant du crédit doit être supérieur à zéro.';

  @override
  String get validationAmountPositive =>
      'Le montant de la transaction doit être supérieur à zéro.';

  @override
  String get validationCashCountNonNegative =>
      'Le comptage physique ne peut pas être négatif.';

  @override
  String get validationSalePriceBelowPurchase =>
      'Le prix de vente ne peut pas être inférieur au prix d\'achat.';

  @override
  String get validationStoreNameRequired => 'Renseignez le nom du magasin.';

  @override
  String get validationTenantNotApproved =>
      'Votre accès à l\'ERP n\'a pas encore été approuvé.';

  @override
  String get validationEmployeeNameEmailRequired =>
      'Renseignez le nom et l\'e-mail de l\'employé.';

  @override
  String get validationEmployeeStoreRequired =>
      'Choisissez un magasin de votre tenant.';

  @override
  String get validationPlanNameRequired => 'Renseignez le nom du plan.';

  @override
  String get validationPlanMinStores =>
      'Le plan doit autoriser au moins 1 magasin.';

  @override
  String get validationPlanMinEmployees =>
      'Le plan doit autoriser au moins 1 employé.';

  @override
  String get validationPlanPriceNonNegative =>
      'Le prix ne peut pas être négatif.';

  @override
  String get validationBusinessNameRequired =>
      'Renseignez le nom de votre entreprise.';

  @override
  String get validationAccessPlanRequired => 'Choisissez un plan.';

  @override
  String get validationAccessAlreadyRequested =>
      'Vous avez déjà une demande d\'accès en cours. Attendez l\'approbation.';

  @override
  String get validationUpgradePlanDifferent =>
      'Choisissez un plan différent de l\'actuel.';

  @override
  String get validationUpgradePendingExists =>
      'Une demande de mise à niveau est déjà en attente d\'approbation.';

  @override
  String get validationAccountGeneric =>
      'Impossible de créer le compte de l\'employé. Réessayez.';

  @override
  String get validationAccountEmailInUse =>
      'Un compte avec cet e-mail existe déjà. Utilisez un autre e-mail ou demandez à l\'employé de se connecter avec son compte.';

  @override
  String get validationAccountOwnerOnly =>
      'Seul le propriétaire du tenant peut enregistrer des employés.';

  @override
  String get validationAccountWeakPassword =>
      'Le mot de passe doit comporter au moins 8 caractères.';

  @override
  String planLimitStores(String planName, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit magasins',
      one: '1 magasin',
    );
    return 'Le plan $planName autorise jusqu\'à $_temp0. Demandez une mise à niveau du plan pour en créer plus.';
  }

  @override
  String planLimitEmployees(String planName, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit employés',
      one: '1 employé',
    );
    return 'Le plan $planName autorise jusqu\'à $_temp0. Demandez une mise à niveau du plan pour embaucher plus.';
  }

  @override
  String get productionTitle => 'Production';

  @override
  String get productionEmptyTitle => 'Aucune fiche technique';

  @override
  String get productionEmptySubtitle =>
      'La fiche technique définit les composants (matière première, emballage…) qui produisent un produit fini.';

  @override
  String get productionNewRecipe => 'Nouvelle fiche technique';

  @override
  String get productionRecipesSection => 'Fiches techniques';

  @override
  String get productionHistorySection => 'Historique de production';

  @override
  String get productionHistoryEmpty => 'Aucune production enregistrée';

  @override
  String get productionHistoryEmptySubtitle =>
      'Les ordres de production apparaissent ici après la production.';

  @override
  String get productionRecipeTitle => 'Fiche technique';

  @override
  String get productionFinishedProduct => 'Produit fini';

  @override
  String get productionYieldLabel => 'Rendement de la base (unités)';

  @override
  String get productionComponents => 'Composants';

  @override
  String get productionAddComponent => 'Ajouter un composant';

  @override
  String get productionComponentLabel => 'Composant';

  @override
  String get productionQuantityLabel => 'Quantité';

  @override
  String get productionProduce => 'Produire';

  @override
  String get productionBasesLabel => 'Bases à produire';

  @override
  String productionProduced(String quantity) {
    return 'À produire : $quantity';
  }

  @override
  String productionCostTotal(String amount) {
    return 'Coût de l\'ordre : $amount';
  }

  @override
  String get productionConfirm => 'Enregistrer la production';

  @override
  String get productionSaved => 'Production enregistrée';

  @override
  String get productionRecipeSaved => 'Fiche technique enregistrée';

  @override
  String get productionDeleteTitle => 'Supprimer la fiche technique';

  @override
  String get productionDeleteMessage =>
      'La fiche technique sera supprimée. L\'historique de production est conservé.';

  @override
  String productionItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count composants',
      one: '1 composant',
    );
    return '$_temp0';
  }

  @override
  String get productionNoProducibleTitle => 'Aucun produit productible';

  @override
  String get productionNoProducibleSubtitle =>
      'Définissez le type d\'un produit sur \"Produit\" ou \"Composé\" pour créer une fiche technique.';

  @override
  String productionInsufficientProduct(String product) {
    return 'Stock insuffisant pour $product';
  }
}
