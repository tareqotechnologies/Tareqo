import 'package:get_it/get_it.dart';

import '../../core/config/supabase_config.dart';
import '../../core/database/app_database.dart';
import '../../core/security/secure_storage_service.dart';
import '../../data/datasources/auth/supabase_auth_remote_data_source.dart';
import '../../data/datasources/local/customer_local_data_source.dart';
import '../../data/datasources/local/customer_local_data_source_impl.dart';
import '../../data/datasources/local/debt_local_data_source.dart';
import '../../data/datasources/local/debt_local_data_source_impl.dart';
import '../../data/datasources/local/plan_catalog.dart';
import '../../data/datasources/local/employee_local_data_source.dart';
import '../../data/datasources/local/employee_local_data_source_impl.dart';
import '../../data/datasources/local/financial_transaction_local_data_source.dart';
import '../../data/datasources/local/financial_transaction_local_data_source_impl.dart';
import '../../data/datasources/local/plan_local_data_source.dart';
import '../../data/datasources/local/plan_local_data_source_impl.dart';
import '../../data/datasources/local/plan_request_local_data_source.dart';
import '../../data/datasources/local/plan_request_local_data_source_impl.dart';
import '../../data/datasources/local/product_local_data_source.dart';
import '../../data/datasources/local/product_local_data_source_impl.dart';
import '../../data/datasources/local/purchase_local_data_source.dart';
import '../../data/datasources/local/purchase_local_data_source_impl.dart';
import '../../data/datasources/local/sale_local_data_source.dart';
import '../../data/datasources/local/sale_local_data_source_impl.dart';
import '../../data/datasources/local/stock_lot_local_data_source.dart';
import '../../data/datasources/local/stock_lot_local_data_source_impl.dart';
import '../../data/datasources/local/store_local_data_source.dart';
import '../../data/datasources/local/store_local_data_source_impl.dart';
import '../../data/datasources/local/tenant_local_data_source.dart';
import '../../data/datasources/local/tenant_local_data_source_impl.dart';
import '../../data/datasources/remote/supabase_customer_data_source.dart';
import '../../data/datasources/remote/supabase_debt_data_source.dart';
import '../../data/datasources/remote/supabase_employee_data_source.dart';
import '../../data/datasources/remote/supabase_financial_transaction_data_source.dart';
import '../../data/datasources/remote/supabase_plan_data_source.dart';
import '../../data/datasources/remote/supabase_plan_request_data_source.dart';
import '../../data/datasources/remote/supabase_product_data_source.dart';
import '../../data/datasources/remote/supabase_purchase_data_source.dart';
import '../../data/datasources/remote/supabase_sale_data_source.dart';
import '../../data/datasources/remote/supabase_stock_lot_data_source.dart';
import '../../data/datasources/remote/supabase_store_data_source.dart';
import '../../data/datasources/remote/supabase_tenant_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/debt_repository_impl.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../data/repositories/financial_transaction_repository_impl.dart';
import '../../data/repositories/plan_repository_impl.dart';
import '../../data/repositories/plan_request_repository_impl.dart';
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
import '../../data/services/supabase_sale_processor.dart';
import '../../domain/repositories/i_admin_repository.dart';
import '../../domain/repositories/i_employee_account_processor.dart';
import '../../domain/repositories/i_employee_realtime_signal_source.dart';
import '../../domain/repositories/i_employee_account_service.dart';
import '../../domain/repositories/i_auth_repository.dart';
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
import '../../domain/repositories/i_product_repository.dart';
import '../../domain/repositories/i_purchase_processor.dart';
import '../../domain/repositories/i_purchase_repository.dart';
import '../../domain/repositories/i_sale_processor.dart';
import '../../domain/repositories/i_sale_repository.dart';
import '../../domain/repositories/i_stock_lot_repository.dart';
import '../../domain/repositories/i_store_repository.dart';
import '../../domain/repositories/i_tenant_repository.dart';
import '../../domain/repositories/i_unit_of_work.dart';
import '../../domain/usecases/add_customer_use_case.dart';
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
import '../../domain/usecases/get_all_tenants_use_case.dart';
import '../../domain/usecases/get_cash_flow_use_case.dart';
import '../../domain/usecases/get_dashboard_kpis_use_case.dart';
import '../../domain/usecases/get_customers_use_case.dart';
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
import '../../domain/usecases/process_sale_use_case.dart';
import '../../domain/usecases/reject_tenant_use_case.dart';
import '../../domain/usecases/request_plan_upgrade_use_case.dart';
import '../../domain/usecases/request_tenant_access_use_case.dart';
import '../../domain/usecases/settle_debt_use_case.dart';
import '../../domain/usecases/update_tenant_settings_use_case.dart';
import '../../domain/usecases/update_plan_use_case.dart';
import '../../domain/usecases/update_product_stock_use_case.dart';

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
      // Supabase via RPC `is_super_admin`; nunca e-mail hardcoded). Sem
      // Supabase não há sessão nem papel — ninguém é super admin.
      ..registerLazySingleton<IAdminRepository>(
        () => SupabaseConfig.isConfigured
            ? const AdminRepositoryImpl()
            : const LocalAdminRepository(),
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

    // Persistência (em ordem de precedência):
    // 1. Supabase configurado → datasources REMOTOS (dados por tenant via
    //    RLS) — o modelo SaaS do produto;
    // 2. senão SQLite em plataformas nativas;
    // 3. senão memória (web — dart:ffi indisponível — ou falha da lib).
    if (SupabaseConfig.isConfigured) {
      _registerSupabaseDatasources();
    } else if (await AppDatabase.openAppDatabase()) {
      AppDatabase.registerDatasources(instance);
      _registerLocalAccountDatasources();
    } else {
      _registerInMemoryDatasources();
    }

    _registerRepositoriesAndUseCases();
  }

  /// Datasources REMOTOS (Supabase): leituras/escritas vão direto ao
  /// Postgres com o JWT do usuário logado; o RLS isola por tenant. Usado
  /// quando [SupabaseConfig.isConfigured]. O unit of work é um no-op — as
  /// operações multi-tabela críticas (venda/compra) delegam às RPCs
  /// atômicas `process_sale`/`process_purchase` do schema.
  static void _registerSupabaseDatasources() {
    instance
      ..registerLazySingleton<IUnitOfWork>(() => const _DirectUnitOfWork())
      // Processadores ATÔMICOS (RPC): venda/compra + itens + estoque +
      // caixa em UMA transação no banco (funções `process_sale`/
      // `process_purchase` em supabase/schema.sql).
      ..registerLazySingleton<ISaleAtomicProcessor>(
        () => const SupabaseSaleProcessor(SaleSupabaseDataSourceImpl()),
      )
      ..registerLazySingleton<IPurchaseAtomicProcessor>(
        () => const SupabasePurchaseProcessor(PurchaseSupabaseDataSourceImpl()),
      )
      ..registerLazySingleton<IDebtAtomicProcessor>(
        () => const SupabaseDebtProcessor(DebtSupabaseDataSourceImpl()),
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
      ..registerLazySingleton<IDebtRepository>(
        () => DebtRepositoryImpl(instance<DebtLocalDataSource>()),
      )
      ..registerLazySingleton<ICustomerRepository>(
        () => CustomerRepositoryImpl(instance<CustomerLocalDataSource>()),
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
        () => PlanRequestRepositoryImpl(
          instance<PlanRequestLocalDataSource>(),
        ),
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
        () => GetPendingPlanRequestsUseCase(
          instance<IPlanRequestRepository>(),
        ),
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
