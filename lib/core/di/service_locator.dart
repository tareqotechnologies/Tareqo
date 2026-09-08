import 'dart:async';

import 'package:get_it/get_it.dart';

import '../../core/config/supabase_config.dart';
import '../../core/database/app_database.dart';
import '../../core/security/secure_storage_service.dart';
import '../../data/datasources/auth/supabase_auth_remote_data_source.dart';
import '../../data/datasources/local/cash_closing_local_data_source.dart';
import '../../data/datasources/local/cash_closing_local_data_source_impl.dart';
import '../../data/datasources/local/customer_local_data_source.dart';
import '../../data/datasources/local/customer_local_data_source_impl.dart';
import '../../data/datasources/local/debt_local_data_source.dart';
import '../../data/datasources/local/debt_local_data_source_impl.dart';
import '../../data/datasources/local/addon_local_data_source.dart';
import '../../data/datasources/local/addon_local_data_source_impl.dart';
import '../../data/datasources/local/plan_catalog.dart';
import '../../data/datasources/local/employee_local_data_source.dart';
import '../../data/datasources/local/employee_local_data_source_impl.dart';
import '../../data/datasources/local/financial_transaction_local_data_source.dart';
import '../../data/datasources/local/financial_transaction_local_data_source_impl.dart';
import '../../data/datasources/local/plan_local_data_source.dart';
import '../../data/datasources/local/plan_local_data_source_impl.dart';
import '../../data/datasources/local/plan_request_local_data_source.dart';
import '../../data/datasources/local/plan_request_local_data_source_impl.dart';
import '../../data/datasources/local/invoice_local_data_source.dart';
import '../../data/datasources/local/invoice_local_data_source_impl.dart';
import '../../data/datasources/local/invoice_notification_local_data_source.dart';
import '../../data/datasources/local/invoice_notification_local_data_source_impl.dart';
import '../../data/datasources/remote/supabase_invoice_notification_data_source.dart';
import '../../data/datasources/local/product_local_data_source.dart';
import '../../data/datasources/local/product_local_data_source_impl.dart';
import '../../data/datasources/local/pending_op_queue.dart';
import '../../data/datasources/local/pending_op_queue_memory_impl.dart';
import '../../data/datasources/local/purchase_local_data_source.dart';
import '../../data/datasources/local/purchase_local_data_source_impl.dart';
import '../../data/datasources/local/sale_local_data_source.dart';
import '../../data/datasources/local/sale_local_data_source_impl.dart';
import '../../data/datasources/local/stock_lot_local_data_source.dart';
import '../../data/datasources/local/stock_lot_local_data_source_impl.dart';
import '../../data/datasources/local/store_local_data_source.dart';
import '../../data/services/offline_aware_processors.dart';
import '../../data/services/offline_sync_service.dart';
import '../../data/services/product_image_store_local.dart';
import '../../data/services/product_image_store_noop.dart';
import '../../data/services/product_image_store_supabase.dart';
import '../../data/datasources/local/store_local_data_source_impl.dart';
import '../../data/datasources/local/tenant_local_data_source.dart';
import '../../data/datasources/local/tenant_local_data_source_impl.dart';
import '../../data/datasources/remote/supabase_cash_closing_data_source.dart';
import '../../data/datasources/remote/supabase_customer_data_source.dart';
import '../../data/datasources/remote/supabase_debt_data_source.dart';
import '../../data/datasources/remote/supabase_employee_data_source.dart';
import '../../data/datasources/remote/supabase_financial_transaction_data_source.dart';
import '../../data/datasources/remote/supabase_plan_data_source.dart';
import '../../data/datasources/remote/supabase_plan_request_data_source.dart';
import '../../data/datasources/remote/supabase_invoice_data_source.dart';
import '../../data/datasources/remote/supabase_product_data_source.dart';
import '../../data/datasources/remote/supabase_purchase_data_source.dart';
import '../../data/datasources/remote/supabase_sale_data_source.dart';
import '../../data/datasources/remote/supabase_stock_lot_data_source.dart';
import '../../data/datasources/remote/supabase_store_data_source.dart';
import '../../data/datasources/remote/supabase_tenant_data_source.dart';
import '../../data/datasources/local/audit_log_local_data_source.dart';
import '../../data/datasources/local/audit_log_local_data_source_impl.dart';
import '../../data/datasources/remote/supabase_audit_log_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/repositories/audit_log_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/cash_closing_repository_impl.dart';
import '../../data/repositories/supabase_cash_closing_summary_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../data/repositories/financial_transaction_repository_impl.dart';
import '../../data/repositories/plan_repository_impl.dart';
import '../../data/repositories/plan_request_repository_impl.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../data/repositories/invoice_notification_repository_impl.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../data/repositories/stock_lot_repository_impl.dart';
import '../../data/repositories/store_repository_impl.dart';
import '../../data/repositories/supabase_cash_flow_repository.dart';
import '../../data/repositories/supabase_dashboard_kpis_repository.dart';
import '../../data/repositories/supabase_sales_report_repository.dart';
import '../../data/repositories/tenant_repository_impl.dart';
import '../../data/repositories/local_admin_repository.dart';
import '../../data/services/empty_employee_realtime_signal_source.dart';
import '../../data/services/local_employee_account_service.dart';
import '../../data/services/supabase_debt_processor.dart';
import '../../data/services/supabase_employee_processor.dart';
import '../../data/services/supabase_employee_realtime_signal_source.dart';
import '../../data/services/supabase_purchase_processor.dart';
import '../../data/services/supabase_sale_cancellation_processor.dart';
import '../../data/services/supabase_sale_processor.dart';
import '../../data/services/supabase_cash_closing_processor.dart';
import '../../data/services/supabase_stock_adjustment_processor.dart';
import '../../domain/entities/debt.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/i_admin_repository.dart';
import '../../domain/repositories/i_audit_log_repository.dart';
import '../../domain/repositories/i_employee_account_processor.dart';
import '../../domain/repositories/i_product_image_store.dart';
import '../../domain/repositories/i_employee_realtime_signal_source.dart';
import '../../domain/repositories/i_employee_account_service.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_cash_closing_processor.dart';
import '../../domain/repositories/i_cash_closing_repository.dart';
import '../../domain/repositories/i_cash_closing_summary_repository.dart';
import '../../domain/repositories/i_customer_repository.dart';
import '../../domain/repositories/i_debt_processor.dart';
import '../../domain/repositories/i_debt_repository.dart';
import '../../domain/repositories/i_employee_repository.dart';
import '../../domain/repositories/i_cash_flow_repository.dart';
import '../../domain/repositories/i_dashboard_kpis_repository.dart';
import '../../domain/repositories/i_financial_transaction_repository.dart';
import '../../domain/repositories/i_sales_report_repository.dart';
import '../../domain/repositories/i_plan_repository.dart';
import '../../domain/repositories/i_plan_request_repository.dart';
import '../../domain/repositories/i_invoice_repository.dart';
import '../../domain/repositories/i_invoice_notification_repository.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/repositories/i_purchase_processor.dart';
import '../../domain/repositories/i_purchase_repository.dart';
import '../../domain/repositories/i_sale_processor.dart';
import '../../domain/repositories/i_sale_repository.dart';
import '../../domain/repositories/i_stock_adjustment_processor.dart';
import '../../domain/repositories/i_stock_lot_repository.dart';
import '../../domain/repositories/i_store_repository.dart';
import '../../domain/repositories/i_tenant_repository.dart';
import '../../domain/repositories/i_unit_of_work.dart';
import '../../domain/usecases/add_customer_use_case.dart';
import '../../domain/usecases/close_cash_register_use_case.dart';
import '../../domain/usecases/get_cash_closing_summary_use_case.dart';
import '../../domain/usecases/add_debt_use_case.dart';
import '../../domain/usecases/add_employee_use_case.dart';
import '../../domain/usecases/set_employee_active_use_case.dart';
import '../../domain/usecases/add_financial_transaction_use_case.dart';
import '../../domain/usecases/add_plan_use_case.dart';
import '../../domain/usecases/add_product_use_case.dart';
import '../../domain/usecases/add_purchase_use_case.dart';
import '../../domain/usecases/add_store_use_case.dart';
import '../../domain/usecases/approve_tenant_use_case.dart';
import '../../domain/usecases/decide_plan_request_use_case.dart';
import '../../domain/usecases/generate_invoice_use_case.dart';
import '../../domain/usecases/get_tenant_invoices_use_case.dart';
import '../../domain/usecases/get_pending_invoices_use_case.dart';
import '../../domain/usecases/get_all_invoices_use_case.dart';
import '../../domain/usecases/mark_invoice_as_paid_use_case.dart';
import '../../domain/usecases/cancel_invoice_use_case.dart';
import '../../domain/usecases/notify_invoice_generated_use_case.dart';
import '../../domain/usecases/get_tenant_notifications_use_case.dart';
import '../../domain/usecases/mark_notification_as_read_use_case.dart';
import '../../domain/usecases/mark_all_notifications_as_read_use_case.dart';
import '../../domain/usecases/check_tenants_for_invoices_use_case.dart';
import '../../domain/usecases/get_audit_log_use_case.dart';
import '../../domain/usecases/get_all_tenants_use_case.dart';
import '../../domain/usecases/get_cash_flow_use_case.dart';
import '../../domain/usecases/get_dashboard_kpis_use_case.dart';
import '../../domain/usecases/delete_customer_use_case.dart';
import '../../domain/usecases/get_customers_use_case.dart';
import '../../domain/usecases/update_customer_use_case.dart';
import '../../domain/usecases/get_employees_use_case.dart';
import '../../domain/usecases/get_my_plan_requests_use_case.dart';
import '../../domain/usecases/get_all_plans_use_case.dart';
import '../../domain/usecases/get_my_tenant_use_case.dart';
import '../../domain/usecases/get_pending_debts_use_case.dart';
import '../../domain/usecases/get_pending_plan_requests_use_case.dart';
import '../../domain/usecases/get_pending_tenants_use_case.dart';
import '../../domain/usecases/get_plans_use_case.dart';
import '../../domain/usecases/get_purchases_use_case.dart';
import '../../domain/usecases/get_sales_report_use_case.dart';
import '../../domain/usecases/get_settled_debts_use_case.dart';
import '../../domain/usecases/get_stores_use_case.dart';
import '../../domain/usecases/get_stock_lots_use_case.dart';
import '../../domain/usecases/get_products_use_case.dart';
import '../../domain/usecases/fifo_stock_use_case.dart';
import '../../domain/usecases/mark_transaction_as_paid_use_case.dart';
import '../../domain/usecases/cancel_sale_use_case.dart';
import '../../domain/usecases/process_sale_use_case.dart';
import '../../domain/usecases/reject_tenant_use_case.dart';
import '../../domain/usecases/request_plan_upgrade_use_case.dart';
import '../../domain/usecases/request_tenant_access_use_case.dart';
import '../../domain/usecases/settle_debt_use_case.dart';
import '../../domain/usecases/update_tenant_settings_use_case.dart';
import '../../domain/usecases/update_plan_use_case.dart';
import '../../domain/usecases/update_product_stock_use_case.dart';
import '../../domain/usecases/update_product_use_case.dart';
import '../../data/datasources/local/admin_message_local_data_source.dart';
import '../../data/datasources/local/admin_message_local_data_source_impl.dart';
import '../../data/datasources/local/custom_invoice_local_data_source.dart';
import '../../data/datasources/local/custom_invoice_local_data_source_impl.dart';
import '../../data/datasources/local/employee_management_local_data_source.dart';
import '../../data/datasources/local/employee_management_local_data_source_impl.dart';
import '../../data/datasources/local/quotation_local_data_source.dart';
import '../../data/datasources/local/quotation_local_data_source_impl.dart';
import '../../data/datasources/remote/supabase_addon_data_source.dart';
import '../../data/datasources/remote/supabase_admin_message_data_source.dart';
import '../../data/datasources/remote/supabase_custom_invoice_data_source.dart';
import '../../data/datasources/remote/supabase_employee_management_data_source.dart';
import '../../data/datasources/remote/supabase_quotation_data_source.dart';
import '../../data/repositories/admin_message_repository_impl.dart';
import '../../data/repositories/custom_invoice_repository_impl.dart';
import '../../data/repositories/employee_management_repository_impl.dart';
import '../../data/repositories/quotation_repository_impl.dart';
import '../../data/repositories/supabase_employee_commission_summary_repository.dart';
import '../../domain/repositories/i_custom_invoice_repository.dart';
import '../../domain/repositories/i_employee_commission_summary_repository.dart';
import '../../domain/repositories/i_employee_management_repository.dart';
import '../../domain/repositories/i_quotation_repository.dart';
import '../../domain/repositories/i_admin_message_repository.dart';
import '../../domain/usecases/send_admin_message_use_case.dart';
import '../../domain/usecases/get_tenant_admin_messages_use_case.dart';
import '../../domain/usecases/mark_admin_message_as_read_use_case.dart';
import '../../domain/usecases/mark_all_admin_messages_as_read_use_case.dart';

/// Registro central de dependências do aplicativo (Service Locator).
///
/// No bootstrap (`main.dart`) chamamos [initialize]. A persistência é
/// **SQLite em plataformas nativas** (Windows/mobile/desktop) e cai para
/// os datasources **em memória** na web (o sqlite3 nativo não roda no
/// navegador) ou se a biblioteca nativa falhar — sempre com os mesmos
/// contratos do domínio, então a UI não muda.
final class ServiceLocator {
  ServiceLocator._();

  /// Instância global do GetIt.
  static final GetIt instance = GetIt.instance;

  /// Registra todas as dependências do aplicativo.
  static Future<void> initialize() async {
    instance
      // Armazenamento seguro (Keychain/Keystore) para tokens e chaves.
      ..registerLazySingleton<SecureStorageService>(SecureStorageService.new)
      // Autenticação (Supabase). Requer `Supabase.initialize` no main.
      ..registerLazySingleton<IAuthRepository>(
        () => AuthRepositoryImpl(SupabaseAuthRemoteDataSourceImpl()),
      )
      // Papel de super admin (baseado em BANCO — `public.super_admins` no
      // Supabase via RPC `is_super_admin`; nunca e-mail hardcoded). Sem    // Supabase não há sessão nem papel — ninguém é super admin.
      ..registerLazySingleton<IAdminRepository>(
        () => SupabaseConfig.isConfigured
            ? const AdminRepositoryImpl()
            : const LocalAdminRepository(),
      )
      ..registerLazySingleton<AuditLogLocalDataSource>(
        () => SupabaseConfig.isConfigured
            ? const SupabaseAuditLogDataSourceImpl()
            : const AuditLogLocalDataSourceImpl(),
      );

    // Criação de contas de funcionários — apenas no modo LOCAL (sem
    // Supabase): o vínculo é criado pelo caso de uso com um id sintético.
    // No modo Supabase quem cria a conta + vínculo é o processador atômico
    // IEmployeeAccountProcessor (RPC create_employee_account — UMA
    // transação, sem contas órfãs).
    if (!SupabaseConfig.isConfigured) {
      instance.registerLazySingleton<EmployeeAccountService>(
        () => const LocalEmployeeAccountService(),
      );
    }

    // SQLite é aberto em TODOS os modos nativos: banco principal no modo
    // LOCAL; no modo SaaS serve a FILA OFFLINE (outbox) — operações do
    // caminho de dinheiro enfileiradas sem conexão e reenviadas pelo
    // OfflineSyncService. Na web (dart:ffi indisponível) a fila cai para
    // memória (não persiste entre sessões — limitação documentada).
    final sqliteAvailable = await AppDatabase.openAppDatabase();
    if (sqliteAvailable) {
      AppDatabase.registerOfflineQueue(instance);
    } else {
      instance.registerLazySingleton<IPendingOpQueue>(
        PendingOpQueueMemoryImpl.new,
      );
    }
    // Serviço de sincronização — registrado em todos os modos (a fila
    // existe sempre; no local fica vazia, no SaaS é o outbox).
    instance.registerLazySingleton<OfflineSyncService>(
      () => OfflineSyncService(instance<IPendingOpQueue>()),
    );

    // Persistência (em ordem de precedência):
    // 1. Supabase configurado → datasources REMOTOS (dados por tenant via
    // RLS) — o modelo SaaS do produto;
    // 2. senão SQLite em plataformas nativas;
    // 3. senão memória (web — dart:ffi indisponível — ou falha da lib).
    //
    // O armazenamento de FOTOS segue o mesmo modo: Supabase Storage (URL
    // pública) no SaaS, arquivo local no SQLite e no-op na memória (web /
    // testes — sem foto).
    if (SupabaseConfig.isConfigured) {
      _registerSupabaseDatasources();
      instance.registerLazySingleton<IProductImageStore>(
        () => const ProductImageStoreSupabase(),
      );
      // Dreno do boot: reenvia pendências de sessões offline anteriores.
      // + dreno automático periódico enquanto o app estiver aberto.
      final sync = instance<OfflineSyncService>();
      unawaited(sync.drain());
      sync.startAutoDrain();
    } else if (sqliteAvailable) {
      AppDatabase.registerDatasources(instance);
      _registerLocalAccountDatasources();
      instance.registerLazySingleton<IProductImageStore>(
        () => const ProductImageStoreLocal(),
      );
    } else {
      _registerInMemoryDatasources();
      instance.registerLazySingleton<IProductImageStore>(
        () => const ProductImageStoreNoop(),
      );
    }

    _registerRepositoriesAndUseCases();
  }

  /// Datasources REMOTOS (Supabase): leituras/escritas vão direto ao
  /// Postgres com o JWT do usuário logado; o RLS isola por tenant. Usado
  /// quando [SupabaseConfig.isConfigured]. O unit of work é um no-op — as
  /// operações multi-tabela críticas (venda/compra) delegam às RPCs
  /// atômicas `process_sale`/`process_purchase` do schema.
  static void _registerSupabaseDatasources() {
    // Processadores REMOTOS (RPC atômicas) — compartilhados entre o
    // caminho normal e o replay da fila offline. Os registrados NO GetIt
    // são os wrappers offline-aware: sem rede, o comando é enfileirado
    // (outbox) e o OfflineSyncService reenviará; os replayers abaixo
    // reconstroem a entidade do payload e reexecutam a MESMA RPC
    // (idempotente por design — o id do registro é a chave).
    final sync = instance<OfflineSyncService>();
    final saleProcessor = const SupabaseSaleProcessor(
      SaleSupabaseDataSourceImpl(),
    );
    final purchaseProcessor = const SupabasePurchaseProcessor(
      PurchaseSupabaseDataSourceImpl(),
    );
    final debtProcessor = const SupabaseDebtProcessor(
      DebtSupabaseDataSourceImpl(),
    );
    final cancellationProcessor = const SupabaseSaleCancellationProcessor(
      SaleSupabaseDataSourceImpl(),
    );

    sync
      ..registerReplayer(
        'process_sale',
        (payload) => saleProcessor.process(
          Sale.fromJson(payload['sale'] as Map<String, dynamic>),
        ),
      )
      ..registerReplayer(
        'process_purchase',
        (payload) => purchaseProcessor.process(
          Purchase.fromJson(payload['purchase'] as Map<String, dynamic>),
        ),
      )
      ..registerReplayer(
        'register_debt',
        (payload) => debtProcessor.register(
          Debt.fromJson(payload['debt'] as Map<String, dynamic>),
        ),
      )
      ..registerReplayer(
        'settle_debt',
        (payload) => debtProcessor.settle(
          payload['debtId'] as String,
          storeId: payload['storeId'] as String,
        ),
      )
      ..registerReplayer(
        'cancel_sale',
        (payload) => cancellationProcessor.cancel(
          payload['saleId'] as String,
          storeId: payload['storeId'] as String,
        ),
      );

    instance
      ..registerLazySingleton<IUnitOfWork>(() => const _DirectUnitOfWork())
      // Processadores ATÔMICOS (RPC): venda/compra + itens + estoque +
      // caixa em UMA transação no banco (funções `process_sale`/
      // `process_purchase` em supabase/schema.sql). Wrappers offline-aware:
      // sem conexão o comando é enfileirado e reenviado automaticamente.
      ..registerLazySingleton<ISaleAtomicProcessor>(
        () => OfflineAwareSaleProcessor(saleProcessor, sync),
      )
      // Anulação de venda (RPC `cancel_sale` — estorno de estoque nos
      // lotes exatos + estorno de caixa + status, UMA transação, guarda
      // gerencial is_manager_of_store). Mesmo padrão dos demais.
      ..registerLazySingleton<ISaleCancellationProcessor>(
        () =>
            OfflineAwareSaleCancellationProcessor(cancellationProcessor, sync),
      )
      // Ajuste manual de estoque (RPC `adjust_product_stock` — define a
      // quantidade absoluta criando/consumindo LOTES FIFO em UMA transação
      // no servidor, guarda gerencial is_manager_of_store). Registrado
      // apenas no modo remoto.
      ..registerLazySingleton<IStockAdjustmentProcessor>(
        () => const SupabaseStockAdjustmentProcessor(
          ProductSupabaseDataSourceImpl(),
        ),
      )
      ..registerLazySingleton<IPurchaseAtomicProcessor>(
        () => OfflineAwarePurchaseProcessor(purchaseProcessor, sync),
      )
      ..registerLazySingleton<IDebtAtomicProcessor>(
        () => OfflineAwareDebtProcessor(debtProcessor, sync),
      )
      ..registerLazySingleton<ProductLocalDataSource>(
        () => ProductSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<SaleLocalDataSource>(
        () => SaleSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<FinancialTransactionLocalDataSource>(
        () => FinancialTransactionSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<CashClosingLocalDataSource>(
        () => const CashClosingSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<ICashClosingProcessor>(
        () => const SupabaseCashClosingProcessor(
          CashClosingSupabaseDataSourceImpl(),
        ),
      )
      ..registerLazySingleton<DebtLocalDataSource>(
        () => DebtSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<CustomerLocalDataSource>(
        () => CustomerSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<PurchaseLocalDataSource>(
        () => PurchaseSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<StockLotLocalDataSource>(
        () => const StockLotSupabaseDataSourceImpl(),
      )
      // Camada de Contas (planos, tenants, lojas, funcionários, upgrades).
      ..registerLazySingleton<PlanLocalDataSource>(
        () => const PlanSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<TenantLocalDataSource>(
        () => const TenantSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<StoreLocalDataSource>(
        () => const StoreSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<EmployeeLocalDataSource>(
        () => const EmployeeSupabaseDataSourceImpl(),
      )
      // Realtime de funcionários (bloqueio INSTANTÂNEO de desativados):
      // postgres_changes em store_employees filtrado pelo usuário logado.
      ..registerLazySingleton<IEmployeeRealtimeSignalSource>(
        () => SupabaseEmployeeRealtimeSignalSource(),
      )
      ..registerLazySingleton<PlanRequestLocalDataSource>(
        () => const PlanRequestSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<InvoiceLocalDataSource>(
        () => const InvoiceSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<InvoiceNotificationLocalDataSource>(
        () => const InvoiceNotificationSupabaseDataSourceImpl(),
      )
      ..registerLazySingleton<AdminMessageLocalDataSource>(
        () => const AdminMessageSupabaseDataSourceImpl(),
      )
      // Add-ons: persistência por tenant (RLS filtra automaticamente).
      ..registerLazySingleton<AddOnLocalDataSource>(
        () => const SupabaseAddOnDataSourceImpl(),
      )
      // Facturas personalizadas (add-on) — documento por loja, RLS por
      // is_my_store; número sequencial atribuído por trigger no servidor.
      ..registerLazySingleton<CustomInvoiceLocalDataSource>(
        () => const CustomInvoiceSupabaseDataSourceImpl(),
      )
      // Cotações (add-on) — documento por loja, RLS por is_my_store;
      // número sequencial atribuído por trigger; UPDATE para transições
      // de estado (enviada/aceite/rejeitada).
      ..registerLazySingleton<QuotationLocalDataSource>(
        () => const QuotationSupabaseDataSourceImpl(),
      )
      // Gestão de funcionários (add-on) — ponto, taxas de comissão e
      // metas por loja, RLS por is_my_store + is_store_employee_active.
      ..registerLazySingleton<EmployeeManagementLocalDataSource>(
        () => const EmployeeManagementSupabaseDataSourceImpl(),
      )
      // Resumo de comissões CALCULADO no servidor (RPC com guarda
      // is_my_store) — registrado APENAS no modo remoto; no local o
      // provider calcula das vendas reais (mesma semântica).
      ..registerLazySingleton<IEmployeeCommissionSummaryRepository>(
        () => const SupabaseEmployeeCommissionSummaryRepository(),
      )
      // Cadastro de funcionário ATÔMICO (RPC `create_employee_account`):
      // conta de acesso + vínculo em `store_employees` em UMA transação no
      // banco (sem contas órfãs se o limite do plano for atingido).
      ..registerLazySingleton<IEmployeeAccountProcessor>(
        () => const SupabaseEmployeeProcessor(),
      )
      // KPIs do dashboard (escala W5): agregação SERVER-SIDE via RPC
      // `get_dashboard_kpis` — uma chamada em vez de 4 listagens de até
      // 1000 linhas somadas no cliente. Registado apenas no modo remoto;
      // no modo local o provider usa o fallback client-side.
      ..registerLazySingleton<IDashboardKpisRepository>(
        () => const SupabaseDashboardKpisRepository(),
      )
      ..registerLazySingleton<GetDashboardKpisUseCase>(
        () => GetDashboardKpisUseCase(instance<IDashboardKpisRepository>()),
      )
      // Agregações H2 no SERVIDOR (cash flow + relatório de vendas): as
      // RPCs `get_cash_flow`/`get_sales_report` devolvem os agregados em
      // UMA chamada (em vez de listar e somar no cliente). Registradas
      // apenas no modo remoto; os use cases recebem via
      // `instance.isRegistered` (null → cálculo client-side).
      ..registerLazySingleton<ICashFlowRepository>(
        () => const SupabaseCashFlowRepository(),
      )
      ..registerLazySingleton<ISalesReportRepository>(
        () => const SupabaseSalesReportRepository(),
      )
      // Prévia do fecho de caixa (Z-report) agregada NO SERVIDOR (H2): RPC
      // get_cash_closing_summary (mesmo padrão get_cash_flow/get_sales_report).
      // Registrada apenas no modo remoto; no local/testes o use case recebe
      // `instance.isRegistered` → null → cálculo client-side.
      ..registerLazySingleton<ICashClosingSummaryRepository>(
        () => const SupabaseCashClosingSummaryRepository(),
      );
  }

  /// Datasources da camada de Contas **em memória** (dev local sem
  /// Supabase): apenas o catálogo REAL de planos; tenant, lojas,
  /// funcionários e upgrades nascem vazios — o dono passa pelo fluxo real
  /// de onboarding + aprovação (nenhum dado de demonstração).
  static void _registerLocalAccountDatasources() {
    instance
      ..registerLazySingleton<PlanLocalDataSource>(
        () => PlanLocalDataSourceImpl(seed: PlanCatalog.plans()),
      )
      ..registerLazySingleton<TenantLocalDataSource>(
        () => TenantLocalDataSourceImpl(),
      )
      ..registerLazySingleton<StoreLocalDataSource>(
        () => StoreLocalDataSourceImpl(),
      )
      ..registerLazySingleton<EmployeeLocalDataSource>(
        () => EmployeeLocalDataSourceImpl(),
      )
      // Sem servidor no modo local: fonte de sinais vazia (o polling do
      // AuthGate continua cobrindo o bloqueio reativo).
      ..registerLazySingleton<IEmployeeRealtimeSignalSource>(
        () => const EmptyEmployeeRealtimeSignalSource(),
      )
      ..registerLazySingleton<PlanRequestLocalDataSource>(
        () => PlanRequestLocalDataSourceImpl(),
      )
      ..registerLazySingleton<InvoiceLocalDataSource>(
        () => InvoiceLocalDataSourceImpl(),
      )
      ..registerLazySingleton<InvoiceNotificationLocalDataSource>(
        () => InvoiceNotificationLocalDataSourceImpl(),
      )
      ..registerLazySingleton<AdminMessageLocalDataSource>(
        () => AdminMessageLocalDataSourceImpl(),
      )
      ..registerLazySingleton<AddOnLocalDataSource>(
        AddOnLocalDataSourceImpl.new,
      );
  }

  /// Fallback em memória (web / falha da biblioteca nativa) — mesma
  /// estrutura dos testes: dados nascem VAZIOS, apenas com o catálogo de
  /// planos. Nenhum dado de demonstração.
  static void _registerInMemoryDatasources() {
    instance
      ..registerLazySingleton<IUnitOfWork>(() => const _DirectUnitOfWork())
      ..registerLazySingleton<ProductLocalDataSource>(
        () => ProductLocalDataSourceImpl(),
      )
      ..registerLazySingleton<SaleLocalDataSource>(
        () => SaleLocalDataSourceImpl(),
      )
      ..registerLazySingleton<FinancialTransactionLocalDataSource>(
        () => FinancialTransactionLocalDataSourceImpl(),
      )
      ..registerLazySingleton<CashClosingLocalDataSource>(
        () => CashClosingLocalDataSourceImpl(),
      )
      ..registerLazySingleton<DebtLocalDataSource>(
        () => DebtLocalDataSourceImpl(),
      )
      ..registerLazySingleton<CustomerLocalDataSource>(
        () => CustomerLocalDataSourceImpl(),
      )
      ..registerLazySingleton<PurchaseLocalDataSource>(
        () => PurchaseLocalDataSourceImpl(),
      )
      ..registerLazySingleton<StockLotLocalDataSource>(
        () => StockLotLocalDataSourceImpl(),
      )
      // Camada de Contas em memória — catálogo real de planos; tenant,
      // lojas, funcionários e upgrades nascem vazios (fluxo real).
      ..registerLazySingleton<PlanLocalDataSource>(
        () => PlanLocalDataSourceImpl(seed: PlanCatalog.plans()),
      )
      ..registerLazySingleton<TenantLocalDataSource>(
        () => TenantLocalDataSourceImpl(),
      )
      ..registerLazySingleton<StoreLocalDataSource>(
        () => StoreLocalDataSourceImpl(),
      )
      ..registerLazySingleton<EmployeeLocalDataSource>(
        () => EmployeeLocalDataSourceImpl(),
      )
      ..registerLazySingleton<IEmployeeRealtimeSignalSource>(
        () => const EmptyEmployeeRealtimeSignalSource(),
      )
      ..registerLazySingleton<PlanRequestLocalDataSource>(
        () => PlanRequestLocalDataSourceImpl(),
      )
      ..registerLazySingleton<InvoiceLocalDataSource>(
        () => InvoiceLocalDataSourceImpl(),
      )
      ..registerLazySingleton<InvoiceNotificationLocalDataSource>(
        () => InvoiceNotificationLocalDataSourceImpl(),
      )
      ..registerLazySingleton<AdminMessageLocalDataSource>(
        () => AdminMessageLocalDataSourceImpl(),
      )
      ..registerLazySingleton<AddOnLocalDataSource>(
        AddOnLocalDataSourceImpl.new,
      )
      ..registerLazySingleton<CustomInvoiceLocalDataSource>(
        CustomInvoiceLocalDataSourceImpl.new,
      )
      ..registerLazySingleton<QuotationLocalDataSource>(
        QuotationLocalDataSourceImpl.new,
      )
      ..registerLazySingleton<EmployeeManagementLocalDataSource>(
        EmployeeManagementLocalDataSourceImpl.new,
      );
  }

  /// Repositórios + casos de uso — idênticos para SQLite e memória, pois
  /// dependem apenas dos contratos dos datasources.
  static void _registerRepositoriesAndUseCases() {
    instance
      ..registerLazySingleton<IProductRepository>(
        () => ProductRepositoryImpl(instance<ProductLocalDataSource>()),
      )
      ..registerLazySingleton<ISaleRepository>(
        () => SaleRepositoryImpl(instance<SaleLocalDataSource>()),
      )
      ..registerLazySingleton<IFinancialTransactionRepository>(
        () => FinancialTransactionRepositoryImpl(
          instance<FinancialTransactionLocalDataSource>(),
        ),
      )
      ..registerLazySingleton<ICashClosingRepository>(
        () => CashClosingRepositoryImpl(instance<CashClosingLocalDataSource>()),
      )
      ..registerLazySingleton<IDebtRepository>(
        () => DebtRepositoryImpl(instance<DebtLocalDataSource>()),
      )
      ..registerLazySingleton<ICustomerRepository>(
        () => CustomerRepositoryImpl(instance<CustomerLocalDataSource>()),
      )
      ..registerLazySingleton<ICustomInvoiceRepository>(
        () => CustomInvoiceRepositoryImpl(
          instance<CustomInvoiceLocalDataSource>(),
        ),
      )
      ..registerLazySingleton<IQuotationRepository>(
        () => QuotationRepositoryImpl(instance<QuotationLocalDataSource>()),
      )
      ..registerLazySingleton<IEmployeeManagementRepository>(
        () => EmployeeManagementRepositoryImpl(
          instance<EmployeeManagementLocalDataSource>(),
        ),
      )
      ..registerLazySingleton<IPurchaseRepository>(
        () => PurchaseRepositoryImpl(instance<PurchaseLocalDataSource>()),
      )
      ..registerLazySingleton<IStockLotRepository>(
        () => StockLotRepositoryImpl(instance<StockLotLocalDataSource>()),
      )
      // Camada de Contas — repositórios.
      ..registerLazySingleton<IPlanRepository>(
        () => PlanRepositoryImpl(instance<PlanLocalDataSource>()),
      )
      ..registerLazySingleton<ITenantRepository>(
        () => TenantRepositoryImpl(instance<TenantLocalDataSource>()),
      )
      ..registerLazySingleton<IStoreRepository>(
        () => StoreRepositoryImpl(instance<StoreLocalDataSource>()),
      )
      ..registerLazySingleton<IEmployeeRepository>(
        () => EmployeeRepositoryImpl(instance<EmployeeLocalDataSource>()),
      )
      ..registerLazySingleton<IPlanRequestRepository>(
        () => PlanRequestRepositoryImpl(instance<PlanRequestLocalDataSource>()),
      )
      ..registerLazySingleton<IAuditLogRepository>(
        () => AuditLogRepositoryImpl(instance<AuditLogLocalDataSource>()),
      )
      ..registerLazySingleton<IInvoiceRepository>(
        () => InvoiceRepositoryImpl(instance<InvoiceLocalDataSource>()),
      )
      ..registerLazySingleton<IInvoiceNotificationRepository>(
        () => InvoiceNotificationRepositoryImpl(
          instance<InvoiceNotificationLocalDataSource>(),
        ),
      )
      ..registerLazySingleton<IAdminMessageRepository>(
        () =>
            AdminMessageRepositoryImpl(instance<AdminMessageLocalDataSource>()),
      )
      // Camada de Contas — casos de uso (planos/tenant/lojas/funcionários).
      ..registerLazySingleton<GetPlansUseCase>(
        () => GetPlansUseCase(instance<IPlanRepository>()),
      )
      ..registerLazySingleton<GetAllPlansUseCase>(
        () => GetAllPlansUseCase(instance<IPlanRepository>()),
      )
      ..registerLazySingleton<AddPlanUseCase>(
        () => AddPlanUseCase(instance<IPlanRepository>()),
      )
      ..registerLazySingleton<UpdatePlanUseCase>(
        () => UpdatePlanUseCase(instance<IPlanRepository>()),
      )
      ..registerLazySingleton<GetMyTenantUseCase>(
        () => GetMyTenantUseCase(instance<ITenantRepository>()),
      )
      ..registerLazySingleton<RequestTenantAccessUseCase>(
        () => RequestTenantAccessUseCase(instance<ITenantRepository>()),
      )
      ..registerLazySingleton<UpdateTenantSettingsUseCase>(
        () => UpdateTenantSettingsUseCase(instance<ITenantRepository>()),
      )
      ..registerLazySingleton<ApproveTenantUseCase>(
        () => ApproveTenantUseCase(instance<ITenantRepository>()),
      )
      ..registerLazySingleton<RejectTenantUseCase>(
        () => RejectTenantUseCase(instance<ITenantRepository>()),
      )
      ..registerLazySingleton<GetAuditLogUseCase>(
        () => GetAuditLogUseCase(instance<IAuditLogRepository>()),
      )
      ..registerLazySingleton<GetPendingTenantsUseCase>(
        () => GetPendingTenantsUseCase(instance<ITenantRepository>()),
      )
      ..registerLazySingleton<GetAllTenantsUseCase>(
        () => GetAllTenantsUseCase(instance<ITenantRepository>()),
      )
      ..registerLazySingleton<GetStoresUseCase>(
        () => GetStoresUseCase(instance<IStoreRepository>()),
      )
      ..registerLazySingleton<AddStoreUseCase>(
        () => AddStoreUseCase(
          instance<IStoreRepository>(),
          instance<ITenantRepository>(),
          instance<IPlanRepository>(),
        ),
      )
      ..registerLazySingleton<GetEmployeesUseCase>(
        () => GetEmployeesUseCase(instance<IEmployeeRepository>()),
      )
      ..registerLazySingleton<SetEmployeeActiveUseCase>(
        () => SetEmployeeActiveUseCase(instance<IEmployeeRepository>()),
      )
      ..registerLazySingleton<AddEmployeeUseCase>(
        () => AddEmployeeUseCase(
          instance<IEmployeeRepository>(),
          instance<ITenantRepository>(),
          instance<IPlanRepository>(),
          instance<IStoreRepository>(),
          // Supabase: processador atômico registrado (conta + vínculo).
          // Local: serviço de conta sintética registrado. Exatamente um
          // dos dois existe em cada modo.
          accountService: instance.isRegistered<EmployeeAccountService>()
              ? instance<EmployeeAccountService>()
              : null,
          processor: instance.isRegistered<IEmployeeAccountProcessor>()
              ? instance<IEmployeeAccountProcessor>()
              : null,
        ),
      )
      ..registerLazySingleton<GetMyPlanRequestsUseCase>(
        () => GetMyPlanRequestsUseCase(instance<IPlanRequestRepository>()),
      )
      ..registerLazySingleton<RequestPlanUpgradeUseCase>(
        () => RequestPlanUpgradeUseCase(
          instance<IPlanRequestRepository>(),
          instance<ITenantRepository>(),
        ),
      )
      ..registerLazySingleton<GetPendingPlanRequestsUseCase>(
        () => GetPendingPlanRequestsUseCase(instance<IPlanRequestRepository>()),
      )
      ..registerLazySingleton<DecidePlanRequestUseCase>(
        () => DecidePlanRequestUseCase(
          instance<IPlanRequestRepository>(),
          instance<ITenantRepository>(),
        ),
      )
      ..registerLazySingleton<GetProductsUseCase>(
        () => GetProductsUseCase(instance<IProductRepository>()),
      )
      ..registerLazySingleton<AddProductUseCase>(
        () => AddProductUseCase(
          instance<IProductRepository>(),
          instance<IStockLotRepository>(),
          instance<IUnitOfWork>(),
        ),
      )
      ..registerLazySingleton<UpdateProductStockUseCase>(
        () => UpdateProductStockUseCase(instance<IProductRepository>()),
      )
      // Edição de produto (W12): detalhes do catálogo (nome/preços/status
      // ativo) + AJUSTE MANUAL de estoque. Supabase: ajuste delega à RPC
      // `adjust_product_stock` (transação única no servidor); local:
      // caminho composto (FifoStockUseCase + IUnitOfWork).
      ..registerLazySingleton<UpdateProductUseCase>(
        () => UpdateProductUseCase(
          instance<IProductRepository>(),
          instance<FifoStockUseCase>(),
          instance<IUnitOfWork>(),
          stockAdjustmentProcessor:
              instance.isRegistered<IStockAdjustmentProcessor>()
              ? instance<IStockAdjustmentProcessor>()
              : null,
        ),
      )
      // W11 (FIFO): porta única para mutar estoque + lotes — usado por
      // vendas (baixa FIFO) e compras (cria lotes).
      ..registerLazySingleton<FifoStockUseCase>(
        () => FifoStockUseCase(
          instance<IStockLotRepository>(),
          instance<UpdateProductStockUseCase>(),
        ),
      )
      ..registerLazySingleton<GetStockLotsUseCase>(
        () => GetStockLotsUseCase(instance<IStockLotRepository>()),
      )
      ..registerLazySingleton<ProcessSaleUseCase>(
        () => ProcessSaleUseCase(
          instance<ISaleRepository>(),
          instance<FifoStockUseCase>(),
          instance<IFinancialTransactionRepository>(),
          instance<IUnitOfWork>(),
          // Supabase: delega à RPC `process_sale` (transação única no
          // servidor — baixa FIFO incluída). Registrado apenas no modo
          // remoto.
          processor: instance.isRegistered<ISaleAtomicProcessor>()
              ? instance<ISaleAtomicProcessor>()
              : null,
        ),
      )
      ..registerLazySingleton<CancelSaleUseCase>(
        () => CancelSaleUseCase(
          instance<ISaleRepository>(),
          instance<FifoStockUseCase>(),
          instance<IFinancialTransactionRepository>(),
          instance<IUnitOfWork>(),
          // Supabase: delega à RPC `cancel_sale` (estorno de estoque +
          // caixa + status em UMA transação no servidor, guarda gerencial
          // is_manager_of_store). Registrado apenas no modo remoto.
          processor: instance.isRegistered<ISaleCancellationProcessor>()
              ? instance<ISaleCancellationProcessor>()
              : null,
        ),
      )
      ..registerLazySingleton<MarkTransactionAsPaidUseCase>(
        () => MarkTransactionAsPaidUseCase(
          instance<IFinancialTransactionRepository>(),
        ),
      )
      ..registerLazySingleton<GetCashFlowUseCase>(
        () => GetCashFlowUseCase(
          instance<IFinancialTransactionRepository>(),
          // Supabase: agregação server-side (H2). Local/testes: null.
          serverRepository: instance.isRegistered<ICashFlowRepository>()
              ? instance<ICashFlowRepository>()
              : null,
        ),
      )
      ..registerLazySingleton<AddFinancialTransactionUseCase>(
        () => AddFinancialTransactionUseCase(
          instance<IFinancialTransactionRepository>(),
        ),
      )
      // Fecho de caixa diário (Z-report): resumo do dia + registro do
      // fecho. Supabase: delega à RPC `close_cash_register` (cálculo +
      // guarda gerencial + UPSERT em UMA transação no servidor).
      // Registrado apenas no modo remoto.
      ..registerLazySingleton<GetCashClosingSummaryUseCase>(
        () => GetCashClosingSummaryUseCase(
          instance<ISaleRepository>(),
          instance<ICashClosingRepository>(),
          serverRepository:
              instance.isRegistered<ICashClosingSummaryRepository>()
              ? instance<ICashClosingSummaryRepository>()
              : null,
        ),
      )
      ..registerLazySingleton<CloseCashRegisterUseCase>(
        () => CloseCashRegisterUseCase(
          instance<ISaleRepository>(),
          instance<ICashClosingRepository>(),
          processor: instance.isRegistered<ICashClosingProcessor>()
              ? instance<ICashClosingProcessor>()
              : null,
        ),
      )
      ..registerLazySingleton<GetPendingDebtsUseCase>(
        () => GetPendingDebtsUseCase(instance<IDebtRepository>()),
      )
      ..registerLazySingleton<GetSettledDebtsUseCase>(
        () => GetSettledDebtsUseCase(instance<IDebtRepository>()),
      )
      ..registerLazySingleton<AddDebtUseCase>(
        () => AddDebtUseCase(
          instance<IDebtRepository>(),
          instance<IFinancialTransactionRepository>(),
          // Supabase: delega à RPC `register_debt` (dívida + pendência em
          // uma única transação no servidor). Registrado só no modo remoto.
          processor: instance.isRegistered<IDebtAtomicProcessor>()
              ? instance<IDebtAtomicProcessor>()
              : null,
        ),
      )
      ..registerLazySingleton<SettleDebtUseCase>(
        () => SettleDebtUseCase(
          instance<IDebtRepository>(),
          instance<IFinancialTransactionRepository>(),
          instance<IUnitOfWork>(),
          // Supabase: delega à RPC `settle_debt` (baixa + resolução da
          // pendência/entrada em uma única transação no servidor).
          // Registrado apenas no modo remoto.
          processor: instance.isRegistered<IDebtAtomicProcessor>()
              ? instance<IDebtAtomicProcessor>()
              : null,
        ),
      )
      ..registerLazySingleton<GetCustomersUseCase>(
        () => GetCustomersUseCase(instance<ICustomerRepository>()),
      )
      ..registerLazySingleton<AddCustomerUseCase>(
        () => AddCustomerUseCase(instance<ICustomerRepository>()),
      )
      ..registerLazySingleton<UpdateCustomerUseCase>(
        () => UpdateCustomerUseCase(instance<ICustomerRepository>()),
      )
      ..registerLazySingleton<DeleteCustomerUseCase>(
        () => DeleteCustomerUseCase(instance<ICustomerRepository>()),
      )
      ..registerLazySingleton<GetPurchasesUseCase>(
        () => GetPurchasesUseCase(instance<IPurchaseRepository>()),
      )
      ..registerLazySingleton<ProcessPurchaseUseCase>(
        () => ProcessPurchaseUseCase(
          instance<IPurchaseRepository>(),
          instance<FifoStockUseCase>(),
          instance<IFinancialTransactionRepository>(),
          instance<IUnitOfWork>(),
          // Supabase: delega à RPC `process_purchase` (transação única no
          // servidor — criação dos lotes FIFO incluída). Registrado apenas
          // no modo remoto.
          processor: instance.isRegistered<IPurchaseAtomicProcessor>()
              ? instance<IPurchaseAtomicProcessor>()
              : null,
        ),
      )
      ..registerLazySingleton<GetSalesReportUseCase>(
        () => GetSalesReportUseCase(
          instance<ISaleRepository>(),
          instance<IProductRepository>(),
          // Supabase: agregação server-side (H2). Local/testes: null.
          serverRepository: instance.isRegistered<ISalesReportRepository>()
              ? instance<ISalesReportRepository>()
              : null,
        ),
      )
      // Camada de Facturas — casos de uso.
      ..registerLazySingleton<GenerateInvoiceUseCase>(
        () => GenerateInvoiceUseCase(
          instance<IInvoiceRepository>(),
          instance<ITenantRepository>(),
          instance<IPlanRepository>(),
        ),
      )
      ..registerLazySingleton<GetTenantInvoicesUseCase>(
        () => GetTenantInvoicesUseCase(instance<IInvoiceRepository>()),
      )
      ..registerLazySingleton<GetPendingInvoicesUseCase>(
        () => GetPendingInvoicesUseCase(instance<IInvoiceRepository>()),
      )
      ..registerLazySingleton<GetAllInvoicesUseCase>(
        () => GetAllInvoicesUseCase(instance<IInvoiceRepository>()),
      )
      ..registerLazySingleton<MarkInvoiceAsPaidUseCase>(
        () => MarkInvoiceAsPaidUseCase(instance<IInvoiceRepository>()),
      )
      ..registerLazySingleton<CancelInvoiceUseCase>(
        () => CancelInvoiceUseCase(instance<IInvoiceRepository>()),
      )
      ..registerLazySingleton<NotifyInvoiceGeneratedUseCase>(
        () => NotifyInvoiceGeneratedUseCase(
          instance<IInvoiceNotificationRepository>(),
          instance<IPlanRepository>(),
        ),
      )
      ..registerLazySingleton<GetTenantNotificationsUseCase>(
        () => GetTenantNotificationsUseCase(
          instance<IInvoiceNotificationRepository>(),
        ),
      )
      ..registerLazySingleton<MarkNotificationAsReadUseCase>(
        () => MarkNotificationAsReadUseCase(
          instance<IInvoiceNotificationRepository>(),
        ),
      )
      ..registerLazySingleton<MarkAllNotificationsAsReadUseCase>(
        () => MarkAllNotificationsAsReadUseCase(
          instance<IInvoiceNotificationRepository>(),
        ),
      )
      ..registerLazySingleton<CheckTenantsForInvoicesUseCase>(
        () => CheckTenantsForInvoicesUseCase(
          instance<GenerateInvoiceUseCase>(),
          instance<ITenantRepository>(),
          notifyInvoiceGenerated: instance<NotifyInvoiceGeneratedUseCase>(),
        ),
      )
      // Camada de Mensagens Admin→Tenant.
      ..registerLazySingleton<SendAdminMessageUseCase>(
        () => SendAdminMessageUseCase(
          instance<IAdminMessageRepository>(),
          instance<ITenantRepository>(),
        ),
      )
      ..registerLazySingleton<GetTenantAdminMessagesUseCase>(
        () =>
            GetTenantAdminMessagesUseCase(instance<IAdminMessageRepository>()),
      )
      ..registerLazySingleton<MarkAdminMessageAsReadUseCase>(
        () =>
            MarkAdminMessageAsReadUseCase(instance<IAdminMessageRepository>()),
      )
      ..registerLazySingleton<MarkAllAdminMessagesAsReadUseCase>(
        () => MarkAllAdminMessagesAsReadUseCase(
          instance<IAdminMessageRepository>(),
        ),
      );
  }
}

/// Unit of work no-op para persistência em memória (web/fallback): a
/// execução já é sequencial — a ação roda diretamente, sem transação.
final class _DirectUnitOfWork implements IUnitOfWork {
  const _DirectUnitOfWork();

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}
