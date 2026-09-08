import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/i18n/addon_localization.dart';
import 'package:tareqo/data/datasources/local/addon_catalog.dart';
import 'package:tareqo/domain/entities/addon.dart';
import 'package:tareqo/l10n/generated/app_localizations_en.dart';
import 'package:tareqo/l10n/generated/app_localizations_pt.dart';

/// Trava a resolução localizada dos add-ons do catálogo
/// (`addonDisplayName`/`addonDescription`/`addonCategoryLabel`): os ids
/// conhecidos devem resolver para as chaves l10n (e trocar de idioma com o
/// locale activo), enquanto um add-on desconhecido cai no valor de dados.
void main() {
  final pt = AppLocalizationsPt();
  final en = AppLocalizationsEn();

  AddOn addonOf(String id) =>
      AddOnCatalog.addOns().firstWhere((a) => a.id == id);

  group('addonDisplayName', () {
    test('add-ons conhecidos resolvem para o nome localizado (pt)', () {
      expect(
        addonDisplayName(pt, addonOf('ao_custom_invoice')),
        pt.addonCustomInvoiceName,
      );
      expect(
        addonDisplayName(pt, addonOf('ao_quotation')),
        pt.addonQuotationName,
      );
      expect(
        addonDisplayName(pt, addonOf('ao_advanced_reports')),
        pt.addonReportsName,
      );
      expect(
        addonDisplayName(pt, addonOf('ao_employee_mgmt')),
        pt.addonEmployeesName,
      );
      expect(
        addonDisplayName(pt, addonOf('ao_multi_store')),
        pt.addonMultiStoreName,
      );
      expect(
        addonDisplayName(pt, addonOf('ao_mobile_money')),
        pt.addonMobileMoneyName,
      );
    });

    test('troca de idioma conforme o locale (en)', () {
      expect(
        addonDisplayName(en, addonOf('ao_custom_invoice')),
        en.addonCustomInvoiceName,
      );
      expect(
        addonDisplayName(en, addonOf('ao_multi_store')),
        en.addonMultiStoreName,
      );
      // O nome em en não é o mesmo texto do catálogo (pt).
      expect(
        addonDisplayName(en, addonOf('ao_quotation')),
        isNot(addonOf('ao_quotation').name),
      );
    });

    test('add-on desconhecido cai no nome do catálogo', () {
      const unknown = AddOn(
        id: 'ao_futuro',
        name: 'Add-on Futuro',
        description: 'Ainda não localizado',
        category: AddOnCategory.reports,
        priceMonthlyCents: 0,
      );
      expect(addonDisplayName(pt, unknown), unknown.name);
      expect(addonDisplayName(en, unknown), unknown.name);
    });
  });

  group('addonDescription', () {
    test('add-ons conhecidos resolvem para a descrição localizada', () {
      expect(
        addonDescription(pt, addonOf('ao_custom_invoice')),
        pt.addonCustomInvoiceDesc,
      );
      expect(
        addonDescription(pt, addonOf('ao_quotation')),
        pt.addonQuotationDesc,
      );
      expect(
        addonDescription(pt, addonOf('ao_employee_mgmt')),
        pt.addonEmployeesDesc,
      );
      expect(
        addonDescription(pt, addonOf('ao_multi_store')),
        pt.addonMultiStoreDesc,
      );
      expect(
        addonDescription(en, addonOf('ao_advanced_reports')),
        en.addonReportsDesc,
      );
      expect(
        addonDescription(en, addonOf('ao_mobile_money')),
        en.addonMobileMoneyDesc,
      );
    });

    test('add-on desconhecido cai na descrição do catálogo', () {
      const unknown = AddOn(
        id: 'ao_futuro',
        name: 'Add-on Futuro',
        description: 'Descrição padrão do catálogo',
        category: AddOnCategory.payments,
        priceMonthlyCents: 0,
      );
      expect(addonDescription(pt, unknown), unknown.description);
    });
  });

  group('addonCategoryLabel', () {
    test('cada categoria mapeia para o rótulo localizado (pt)', () {
      expect(
        addonCategoryLabel(pt, AddOnCategory.invoice),
        pt.addonCategoryInvoicing,
      );
      expect(
        addonCategoryLabel(pt, AddOnCategory.quotation),
        pt.addonCategoryQuotation,
      );
      expect(
        addonCategoryLabel(pt, AddOnCategory.reports),
        pt.addonCategoryReports,
      );
      expect(
        addonCategoryLabel(pt, AddOnCategory.employees),
        pt.addonCategoryEmployees,
      );
      expect(
        addonCategoryLabel(pt, AddOnCategory.multiStore),
        pt.addonCategoryMultiStore,
      );
      expect(
        addonCategoryLabel(pt, AddOnCategory.payments),
        pt.addonCategoryPayments,
      );
    });

    test('rótulo troca de idioma conforme o locale (en)', () {
      expect(
        addonCategoryLabel(en, AddOnCategory.invoice),
        en.addonCategoryInvoicing,
      );
      expect(
        addonCategoryLabel(en, AddOnCategory.payments),
        en.addonCategoryPayments,
      );
    });
  });
}
