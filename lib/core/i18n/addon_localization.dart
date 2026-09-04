import '../../domain/entities/addon.dart';
import '../../l10n/generated/app_localizations.dart';

/// Resolve o nome localizado de um add-on do catálogo.
///
/// O catálogo ([AddOnCatalog]) armazena os nomes/descrições como dados
/// (pt) para persistência e backoffice; a camada de UI usa estas funções
/// para exibir o texto no idioma activo. Fallback para o valor do catálogo
/// quando o add-on não é um dos conhecidos.
String addonDisplayName(AppLocalizations l10n, AddOn addon) {
  switch (addon.id) {
    case 'ao_custom_invoice':
      return l10n.addonCustomInvoiceName;
    case 'ao_quotation':
      return l10n.addonQuotationName;
    case 'ao_advanced_reports':
      return l10n.addonReportsName;
    case 'ao_employee_mgmt':
      return l10n.addonEmployeesName;
    case 'ao_multi_store':
      return l10n.addonMultiStoreName;
    case 'ao_mobile_money':
      return l10n.addonMobileMoneyName;
    default:
      return addon.name;
  }
}

/// Descrição localizada de um add-on do catálogo (fallback para o valor de dados).
String addonDescription(AppLocalizations l10n, AddOn addon) {
  switch (addon.id) {
    case 'ao_custom_invoice':
      return l10n.addonCustomInvoiceDesc;
    case 'ao_quotation':
      return l10n.addonQuotationDesc;
    case 'ao_advanced_reports':
      return l10n.addonReportsDesc;
    case 'ao_employee_mgmt':
      return l10n.addonEmployeesDesc;
    case 'ao_multi_store':
      return l10n.addonMultiStoreDesc;
    case 'ao_mobile_money':
      return l10n.addonMobileMoneyDesc;
    default:
      return addon.description;
  }
}

/// Rótulo localizado da categoria de um add-on.
String addonCategoryLabel(AppLocalizations l10n, AddOnCategory category) {
  switch (category) {
    case AddOnCategory.invoice:
      return l10n.addonCategoryInvoicing;
    case AddOnCategory.quotation:
      return l10n.addonCategoryQuotation;
    case AddOnCategory.reports:
      return l10n.addonCategoryReports;
    case AddOnCategory.employees:
      return l10n.addonCategoryEmployees;
    case AddOnCategory.multiStore:
      return l10n.addonCategoryMultiStore;
    case AddOnCategory.payments:
      return l10n.addonCategoryPayments;
  }
}
