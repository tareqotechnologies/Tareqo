import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:tareqo/core/di/service_locator.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/core/observability/crash_reporting.dart';
import 'package:tareqo/data/datasources/local/addon_local_data_source.dart';
import 'package:tareqo/data/datasources/local/admin_message_local_data_source.dart';
import 'package:tareqo/data/datasources/local/cash_closing_local_data_source.dart';
import 'package:tareqo/data/datasources/local/customer_local_data_source.dart';
import 'package:tareqo/data/datasources/local/custom_invoice_local_data_source.dart';
import 'package:tareqo/data/datasources/local/debt_local_data_source.dart';
import 'package:tareqo/data/datasources/local/employee_local_data_source.dart';
import 'package:tareqo/data/datasources/local/employee_management_local_data_source.dart';
import 'package:tareqo/data/datasources/local/financial_transaction_local_data_source.dart';
import 'package:tareqo/data/datasources/local/invoice_local_data_source.dart';
import 'package:tareqo/data/datasources/local/invoice_notification_local_data_source.dart';
import 'package:tareqo/data/datasources/local/plan_local_data_source.dart';
import 'package:tareqo/data/datasources/local/plan_request_local_data_source.dart';
import 'package:tareqo/data/datasources/local/product_local_data_source.dart';
import 'package:tareqo/data/datasources/local/purchase_local_data_source.dart';
import 'package:tareqo/data/datasources/local/quotation_local_data_source.dart';
import 'package:tareqo/data/datasources/local/sale_local_data_source.dart';
import 'package:tareqo/data/datasources/local/stock_lot_local_data_source.dart';
import 'package:tareqo/data/datasources/local/store_local_data_source.dart';
import 'package:tareqo/data/datasources/local/tenant_local_data_source.dart';
import 'package:tareqo/data/repositories/admin_repository_impl.dart';
import 'package:tareqo/data/services/offline_sync_service.dart';
import 'package:tareqo/data/repositories/supabase_cash_flow_repository.dart';
import 'package:tareqo/data/repositories/supabase_dashboard_kpis_repository.dart';
import 'package:tareqo/data/repositories/supabase_employee_commission_summary_repository.dart';
import 'package:tareqo/data/repositories/supabase_sales_report_repository.dart';
import 'package:tareqo/data/repositories/supabase_cash_closing_summary_repository.dart';
import 'package:tareqo/data/services/supabase_employee_realtime_signal_source.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue.dart';
import 'package:tareqo/domain/repositories/i_admin_repository.dart';
import 'package:tareqo/domain/repositories/i_audit_log_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_processor.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_summary_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/repositories/i_customer_repository.dart';
import 'package:tareqo/domain/repositories/i_dashboard_kpis_repository.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/repositories/i_debt_repository.dart';
import 'package:tareqo/domain/repositories/i_employee_commission_summary_repository.dart';
import 'package:tareqo/domain/repositories/i_employee_management_repository.dart';
import 'package:tareqo/domain/repositories/i_employee_realtime_signal_source.dart';
import 'package:tareqo/domain/repositories/i_employee_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_invoice_notification_repository.dart';
import 'package:tareqo/domain/repositories/i_sales_report_repository.dart';
import 'package:tareqo/domain/repositories/i_invoice_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_request_repository.dart';
import 'package:tareqo/domain/repositories/i_product_image_store.dart';

void main() {
  // Inicializa o binding: o path_provider sem canal cai no fallback de
  // memória do ServiceLocator (fila offline em memória — comportamento
  // de teste, não de produção).
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => GetIt.instance.reset());

  test(
    'resolve TODAS as dependências registradas (grafo Supabase íntegro)',
    () async {
      await ServiceLocator.initialize();

      final getIt = ServiceLocator.instance;

      // ── Infra de base ────────────────────────────────────────────────
      expect(getIt<SecureStorageService>(), isA<SecureStorageService>());
      expect(
        getIt<IEmployeeRealtimeSignalSource>(),
        isA<SupabaseEmployeeRealtimeSignalSource>(),
      );
      expect(getIt<OfflineSyncService>(), isA<OfflineSyncService>());
      expect(getIt<IPendingOpQueue>(), isA<IPendingOpQueue>());

      // ── Datasources (remotos no modo SaaS — default dos testes) ─────
      expect(getIt<ProductLocalDataSource>(), isA<ProductLocalDataSource>());
      expect(getIt<SaleLocalDataSource>(), isA<SaleLocalDataSource>());
      expect(
        getIt<FinancialTransactionLocalDataSource>(),
        isA<FinancialTransactionLocalDataSource>(),
      );
      expect(
        getIt<CashClosingLocalDataSource>(),
        isA<CashClosingLocalDataSource>(),
      );
      expect(getIt<DebtLocalDataSource>(), isA<DebtLocalDataSource>());
      expect(getIt<CustomerLocalDataSource>(), isA<CustomerLocalDataSource>());
      expect(getIt<PurchaseLocalDataSource>(), isA<PurchaseLocalDataSource>());
      expect(getIt<StockLotLocalDataSource>(), isA<StockLotLocalDataSource>());
      expect(getIt<PlanLocalDataSource>(), isA<PlanLocalDataSource>());
      expect(getIt<TenantLocalDataSource>(), isA<TenantLocalDataSource>());
      expect(getIt<StoreLocalDataSource>(), isA<StoreLocalDataSource>());
      expect(getIt<EmployeeLocalDataSource>(), isA<EmployeeLocalDataSource>());
      expect(
        getIt<PlanRequestLocalDataSource>(),
        isA<PlanRequestLocalDataSource>(),
      );
      expect(getIt<InvoiceLocalDataSource>(), isA<InvoiceLocalDataSource>());
      expect(
        getIt<InvoiceNotificationLocalDataSource>(),
        isA<InvoiceNotificationLocalDataSource>(),
      );
      expect(
        getIt<AdminMessageLocalDataSource>(),
        isA<AdminMessageLocalDataSource>(),
      );
      expect(getIt<AddOnLocalDataSource>(), isA<AddOnLocalDataSource>());
      expect(
        getIt<CustomInvoiceLocalDataSource>(),
        isA<CustomInvoiceLocalDataSource>(),
      );
      expect(
        getIt<QuotationLocalDataSource>(),
        isA<QuotationLocalDataSource>(),
      );
      expect(
        getIt<EmployeeManagementLocalDataSource>(),
        isA<EmployeeManagementLocalDataSource>(),
      );

      // ── Processadores atômicos (RPC) + unit of work ─────────────────
      expect(getIt<ICashClosingProcessor>(), isNotNull);
      expect(getIt<IDebtAtomicProcessor>(), isNotNull);

      // ── Repositórios ────────────────────────────────────────────────
      expect(getIt<ICustomerRepository>(), isNotNull);
      expect(getIt<IDebtRepository>(), isNotNull);
      expect(getIt<IFinancialTransactionRepository>(), isNotNull);
      expect(getIt<ICashClosingRepository>(), isNotNull);
      expect(getIt<IPlanRepository>(), isNotNull);
      expect(getIt<IPlanRequestRepository>(), isNotNull);
      expect(getIt<IInvoiceRepository>(), isNotNull);
      expect(getIt<IInvoiceNotificationRepository>(), isNotNull);
      expect(getIt<IEmployeeRepository>(), isNotNull);
      expect(getIt<IEmployeeManagementRepository>(), isNotNull);
      expect(getIt<IAuditLogRepository>(), isNotNull);

      // ── Agregações server-side (H2) — apenas no modo remoto ────────
      expect(getIt<ICashFlowRepository>(), isA<SupabaseCashFlowRepository>());
      expect(
        getIt<ISalesReportRepository>(),
        isA<SupabaseSalesReportRepository>(),
      );
      expect(
        getIt<IDashboardKpisRepository>(),
        isA<SupabaseDashboardKpisRepository>(),
      );
      expect(
        getIt<ICashClosingSummaryRepository>(),
        isA<SupabaseCashClosingSummaryRepository>(),
      );
      expect(
        getIt<IEmployeeCommissionSummaryRepository>(),
        isA<SupabaseEmployeeCommissionSummaryRepository>(),
      );
      expect(
        getIt<IAdminRepository>(),
        isA<AdminRepositoryImpl>(),
        reason: 'no modo SaaS o papel de super admin vem do BANCO',
      );

      // ── Foto de produto: Supabase Storage no modo SaaS ──────────────
      expect(
        getIt<IProductImageStore>().runtimeType.toString(),
        'ProductImageStoreSupabase',
      );
    },
  );

  test(
    'dreno do boot NÃO lança com fila vazia e auto-drain pode ser parado',
    () async {
      await ServiceLocator.initialize();

      final sync = ServiceLocator.instance<OfflineSyncService>();
      // O initialize já dispara `unawaited(sync.drain())` + startAutoDrain;
      // com fila vazia ambos são no-op seguros. Paramos o timer para o
      // teste não deixar pendências assíncronas.
      sync.stopAutoDrain();

      expect(await sync.count(), 0);
      // O dreno manual após o stop também é seguro (idempotente).
      await sync.drain();
      expect(await sync.count(), 0);
    },
  );

  test('CrashReporting.capture nunca lança fora do canal ativo', () {
    // Usado nos catch de telas/providers: deve ser seguro chamar de
    // qualquer lugar (no-op sem DSN — ver core/observability).
    expect(
      () => CrashReporting.capture(
        StateError('erro de teste'),
        StackTrace.current,
        hint: 'service-locator-test',
      ),
      returnsNormally,
    );
  });
}
