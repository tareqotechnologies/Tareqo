import 'package:flutter/material.dart';

import '../../domain/entities/sale.dart';
import '../../domain/entities/tenant.dart';
import '../screens/shell/app_shell.dart' show AppSection;
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/financial/financial_screen.dart';
import '../screens/shell/menu_screen.dart';
import '../screens/addons/addon_marketplace_screen.dart';
import '../screens/addons/advanced_reports_screen.dart';
import '../screens/addons/custom_invoice_screen.dart';
import '../screens/addons/employee_management_screen.dart';
import '../screens/addons/payment_reconciliation_screen.dart';
import '../screens/addons/quotation_screen.dart';
import '../screens/addons/store_transfers_screen.dart';
import '../screens/account/security_settings_screen.dart';
import '../screens/auth/mfa_setup_screen.dart';
import '../screens/credit/debts_screen.dart';
import '../screens/customers/customers_screen.dart';

import '../screens/dashboard/notifications_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/production/production_screen.dart';
import '../screens/purchases/purchases_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/sales/sale_detail_screen.dart';
import '../screens/stores/stores_screen.dart';
import '../screens/support/doc_reader_screen.dart';
import '../screens/support/support_screen.dart';

/// Rotas nomeadas do TAREQO (U-09).
///
/// Antes: `Navigator.push(MaterialPageRoute(...))` ad-hoc em 8 ficheiros
/// (Menu, Dashboard, Marketplace, Suporte, Stores, Shell, Security) —
/// sem nomes, sem deep links internos, transições por omissão.
///
/// Agora: uma **tabela única** de nomes (`/purchases`, `/reports`, …) e
/// helpers [AppNavigator] que os usam. As transições continuam a vir do
/// `PageTransitionsTheme` global (Zoom/Android, Cupertino/iOS).
///
/// **Deep links internos** (`tareqo://go/<rota>`): [AppRoutes.parseGoDeepLink]
/// mapeia `tareqo://go/purchases` → [AppRoutes.purchases]. Os links de
/// **autenticação** (`tareqo://callback`) continuam no [DeepLinkHandler]
/// (gotrue/PKCE) — este módulo nunca os toca.
abstract final class AppRoutes {
  static const String purchases = '/purchases';
  static const String reports = '/reports';
  static const String production = '/production';
  static const String stores = '/stores';
  static const String notifications = '/notifications';
  static const String addons = '/addons';
  static const String security = '/security';
  static const String support = '/support';
  static const String docReader = '/doc-reader';
  static const String saleDetail = '/sale-detail';
  static const String mfaSetup = '/mfa-setup';

  // Add-ons (marketplace) — rotas internas por id de catálogo.
  static const String addonCustomInvoice = '/addons/custom-invoice';
  static const String addonQuotation = '/addons/quotation';
  static const String addonAdvancedReports = '/addons/advanced-reports';
  static const String addonEmployeeMgmt = '/addons/employee-mgmt';
  static const String addonStoreTransfers = '/addons/store-transfers';
  static const String addonMobileMoney = '/addons/mobile-money';

  /// Casca do ERP (secções) — `goTo(AppSection)` continua a ser o mecanismo
  /// interno das 7 secções; os nomes abaixo cobrem as telas **empurradas**
  /// (fora do IndexedStack).
  static const String products = '/products';
  static const String credit = '/credit';
  static const String customers = '/customers';

  /// Scheme/host dos deep links internos `tareqo://go/<rota>`.
  static const String goScheme = 'tareqo';
  static const String goHost = 'go';

  /// Conjunto de rotas empurráveis resolvidas por [onGenerateRoute].
  static const Set<String> _pushable = {
    purchases,
    reports,
    production,
    stores,
    notifications,
    addons,
    security,
    support,
    docReader,
    saleDetail,
    mfaSetup,
    addonCustomInvoice,
    addonQuotation,
    addonAdvancedReports,
    addonEmployeeMgmt,
    addonStoreTransfers,
    addonMobileMoney,
  };

  /// Resolves a deep-link interna `tareqo://go/<rota>` para o nome da rota,
  /// ou `null` se não for um link interno reconhecido.
  ///
  /// - `tareqo://go/purchases` → `/purchases`
  /// - `tareqo://go/addons/custom-invoice` → `/addons/custom-invoice`
  /// - `tareqo://callback…` (auth) → `null` (não é daqui)
  static String? parseGoDeepLink(Uri uri) {
    if (uri.scheme != goScheme || uri.host != goHost) return null;
    final route = '/${uri.pathSegments.join('/')}';
    return _pushable.contains(route) ? route : null;
  }

  /// Nome de rota de uma secção do shell (para `pushSection`).
  static String sectionName(AppSection section) {
    return switch (section) {
      AppSection.dashboard => '/dashboard',
      AppSection.sales => '/sales',
      AppSection.financial => '/financial',
      AppSection.menu => '/menu',
      AppSection.products => products,
      AppSection.credit => credit,
      AppSection.customers => customers,
    };
  }

  // ── onGenerateRoute ────────────────────────────────────────────────

  /// Gera a rota para um nome. Os casos com argumentos (stores, docReader,
  /// saleDetail) validam o tipo e caem no sink quando inválidos — nunca
  /// lançam dentro do Navigator.
  ///
  /// Telas que **não** estão na tabela (secções do shell, admin, sheets)
  /// continuam a ser abertas por `goTo(...)` / `showAppSheet` — ver
  /// [AppNavigator] para a fronteira.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null) return null;

    WidgetBuilder builder;
    switch (name) {
      case purchases:
        builder = (_) => const PurchasesScreen();
      case reports:
        builder = (_) => const ReportsScreen();
      case production:
        builder = (_) => const ProductionScreen();
      case notifications:
        builder = (_) => const NotificationsScreen();
      case addons:
        builder = (_) => const AddOnMarketplaceScreen();
      case security:
        builder = (_) => const SecuritySettingsScreen();
      case support:
        builder = (_) => const SupportScreen();
      case mfaSetup:
        builder = (_) => const MFASetupScreen();
      case addonCustomInvoice:
        builder = (_) => const CustomInvoiceScreen();
      case addonQuotation:
        builder = (_) => const QuotationScreen();
      case addonAdvancedReports:
        builder = (_) => const AdvancedReportsScreen();
      case addonEmployeeMgmt:
        builder = (_) => const EmployeeManagementScreen();
      case addonStoreTransfers:
        builder = (_) => const StoreTransfersScreen();
      case addonMobileMoney:
        builder = (_) => const PaymentReconciliationScreen();
      case stores:
        final tenant = _arg<Tenant>(settings, 'tenant');
        if (tenant == null) return _unknown(settings);
        builder = (_) => StoresScreen(tenant: tenant);
      case docReader:
        final document = _arg<SupportDocument>(settings, 'document');
        if (document == null) return _unknown(settings);
        builder = (_) => DocReaderScreen(document: document);
      case saleDetail:
        final sale = _arg<Sale>(settings, 'sale');
        if (sale == null) return _unknown(settings);
        builder = (_) => SaleDetailScreen(sale: sale);
      default:
        return _unknown(settings);
    }

    // Secções do shell: a tela da secção empurrada (não troca a aba).
    final isSection = name == '/dashboard' ||
        name == '/sales' ||
        name == '/financial' ||
        name == '/menu' ||
        name == products ||
        name == credit ||
        name == customers;
    if (isSection) {
      final sectionBuilder = switch (name) {
        '/dashboard' => const DashboardScreen(),
        '/sales' => const SalesScreen(),
        '/financial' => const FinancialScreen(),
        '/menu' => const MenuScreen(),
        _ when name == products => const ProductListScreen(),
        _ when name == credit => const DebtsScreen(),
        _ => const CustomersScreen(),
      };
      return MaterialPageRoute<dynamic>(
        settings: settings,
        builder: (_) => sectionBuilder,
      );
    }

    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: builder,
    );
  }

  static T? _arg<T>(RouteSettings settings, String key) {
    final args = settings.arguments;
    if (args is Map && args[key] is T) return args[key] as T;
    return null;
  }

  /// Rota de “não encontrado” — nunca esconde o erro: mostra a rota pedida.
  static Route<dynamic> _unknown(RouteSettings settings) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Rota não encontrada: ${settings.name ?? ''}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Exposto para o `MaterialApp.onUnknownRoute`.
  static Route<dynamic> unknownRoute(RouteSettings settings) =>
      _unknown(settings);

  /// Deep link interno → navega (sem sair do app). Retorna `true` quando
  /// navegou, `false` quando a URI não é um link `go` reconhecido.
  static bool handleGoDeepLink(BuildContext context, Uri uri) {
    final route = parseGoDeepLink(uri);
    if (route == null) return false;
    Navigator.of(context).pushNamed(route);
    return true;
  }
}

/// Navegação por nomes (U-09) — a fronteira pública.
///
/// Todo o código de apresentação deve abrir telas empurradas **por aqui**
/// (`AppNavigator.push(context, AppRoutes.purchases)`) em vez de
/// `Navigator.of(context).push(MaterialPageRoute(...))` inline.
abstract final class AppNavigator {
  /// Abre a rota [name] (ver [AppRoutes]). Retorna o resultado da rota.
  static Future<T?> push<T>(BuildContext context, String name) {
    return Navigator.of(context).pushNamed<T>(name);
  }

  /// Abre com argumentos nomeados (stores/docReader/saleDetail).
  static Future<T?> pushWith<T>(
    BuildContext context,
    String name,
    Map<String, Object?> args,
  ) {
    return Navigator.of(context).pushNamed<T>(
      name,
      arguments: args,
    );
  }

  /// Abre uma **secção do shell** empurrando a tela correspondente
  /// (Dashboard/Financeiro/Crédito/…): o shell não tem rota própria
  /// (IndexedStack + `goTo(AppSection)`), por isso o empurrão usa
  /// `pushNamed` com o nome da secção — ver [AppRoutes.sectionName].
  static Future<T?> pushSection<T>(BuildContext context, AppSection section) {
    return Navigator.of(context).pushNamed<T>(AppRoutes.sectionName(section));
  }
}
