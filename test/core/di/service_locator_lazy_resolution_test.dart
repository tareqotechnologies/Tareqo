import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:tareqo/core/di/service_locator.dart';
import 'package:tareqo/domain/repositories/i_admin_message_repository.dart';
import 'package:tareqo/domain/repositories/i_audit_log_repository.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_processor.dart';
import 'package:tareqo/domain/repositories/i_cash_closing_repository.dart';
import 'package:tareqo/domain/repositories/i_custom_invoice_repository.dart';
import 'package:tareqo/domain/repositories/i_customer_repository.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/repositories/i_debt_repository.dart';
import 'package:tareqo/domain/repositories/i_employee_account_processor.dart';
import 'package:tareqo/domain/repositories/i_employee_account_service.dart';
import 'package:tareqo/domain/repositories/i_employee_management_repository.dart';
import 'package:tareqo/domain/repositories/i_employee_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_invoice_notification_repository.dart';
import 'package:tareqo/domain/repositories/i_invoice_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_request_repository.dart';
import 'package:tareqo/domain/repositories/i_purchase_processor.dart';
import 'package:tareqo/domain/repositories/i_purchase_repository.dart';
import 'package:tareqo/domain/repositories/i_quotation_repository.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/repositories/i_stock_adjustment_processor.dart';
import 'package:tareqo/domain/repositories/i_stock_lot_repository.dart';
import 'package:tareqo/domain/repositories/i_store_repository.dart';
import 'package:tareqo/domain/repositories/i_tenant_repository.dart';
import 'package:tareqo/domain/usecases/add_debt_use_case.dart';
import 'package:tareqo/domain/usecases/add_employee_use_case.dart';
import 'package:tareqo/domain/usecases/add_financial_transaction_use_case.dart';
import 'package:tareqo/domain/usecases/add_plan_use_case.dart';
import 'package:tareqo/domain/usecases/add_product_use_case.dart';
import 'package:tareqo/domain/usecases/add_purchase_use_case.dart';
import 'package:tareqo/domain/usecases/add_store_use_case.dart';
import 'package:tareqo/domain/usecases/approve_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/cancel_invoice_use_case.dart';
import 'package:tareqo/domain/usecases/cancel_sale_use_case.dart';
import 'package:tareqo/domain/usecases/check_tenants_for_invoices_use_case.dart';
import 'package:tareqo/domain/usecases/close_cash_register_use_case.dart';
import 'package:tareqo/domain/usecases/decide_plan_request_use_case.dart';
import 'package:tareqo/domain/usecases/delete_customer_use_case.dart';
import 'package:tareqo/domain/usecases/fifo_stock_use_case.dart';
import 'package:tareqo/domain/usecases/generate_invoice_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_invoices_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_audit_log_use_case.dart';
import 'package:tareqo/domain/usecases/get_cash_closing_summary_use_case.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_dashboard_kpis_use_case.dart';
import 'package:tareqo/domain/usecases/get_employees_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_my_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_invoices_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_tenants_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/domain/usecases/get_sales_report_use_case.dart';
import 'package:tareqo/domain/usecases/get_settled_debts_use_case.dart';
import 'package:tareqo/domain/usecases/get_stock_lots_use_case.dart';
import 'package:tareqo/domain/usecases/get_stores_use_case.dart';
import 'package:tareqo/domain/usecases/get_tenant_admin_messages_use_case.dart';
import 'package:tareqo/domain/usecases/get_tenant_invoices_use_case.dart';
import 'package:tareqo/domain/usecases/get_tenant_notifications_use_case.dart';
import 'package:tareqo/domain/usecases/mark_admin_message_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_all_admin_messages_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_all_notifications_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_invoice_as_paid_use_case.dart';
import 'package:tareqo/domain/usecases/mark_notification_as_read_use_case.dart';
import 'package:tareqo/domain/usecases/mark_transaction_as_paid_use_case.dart';
import 'package:tareqo/domain/usecases/notify_invoice_generated_use_case.dart';
import 'package:tareqo/domain/usecases/reject_tenant_use_case.dart';
import 'package:tareqo/domain/usecases/request_plan_upgrade_use_case.dart';
import 'package:tareqo/domain/usecases/request_tenant_access_use_case.dart';
import 'package:tareqo/domain/usecases/send_admin_message_use_case.dart';
import 'package:tareqo/domain/usecases/set_employee_active_use_case.dart';
import 'package:tareqo/domain/usecases/settle_debt_use_case.dart';
import 'package:tareqo/domain/usecases/update_customer_use_case.dart';
import 'package:tareqo/domain/usecases/update_plan_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_use_case.dart';
import 'package:tareqo/domain/usecases/update_tenant_settings_use_case.dart';

/// Varredura de resolução preguiçosa: o [ServiceLocator.initialize] registra
/// ~80 use cases/repos com `registerLazySingleton` — as fábricas só rodam
/// na PRIMEIRA resolução, então um erro de grafo (dependência faltando,
/// ordem errada) só explodiria EM PRODUÇÃO. Este teste resolve TODOS os
/// tipos registrados uma vez, provando o grafo inteiro em teste.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => GetIt.instance.reset());

  test('todas as fábricas lazy resolvem sem erro (grafo íntegro)', () async {
    await ServiceLocator.initialize();
    final getIt = ServiceLocator.instance;

    expect(getIt<IAdminMessageRepository>(), isNotNull);
    expect(getIt<IAuditLogRepository>(), isNotNull);
    expect(getIt<ICashClosingProcessor>(), isNotNull);
    expect(getIt<ICashClosingRepository>(), isNotNull);
    expect(getIt<ICustomInvoiceRepository>(), isNotNull);
    expect(getIt<ICustomerRepository>(), isNotNull);
    expect(getIt<IDebtAtomicProcessor>(), isNotNull);
    expect(getIt<IDebtRepository>(), isNotNull);
    expect(getIt<IEmployeeAccountProcessor>(), isNotNull);
    // EmployeeAccountService é registrado APENAS no modo local (sem
    // Supabase) — no SaaS quem cria contas é o IEmployeeAccountProcessor
    // via RPC atômico. Com os defaults de teste (Supabase configurado),
    // o contrato correto é NÃO estar registrado.
    expect(
      getIt.isRegistered<EmployeeAccountService>(),
      isFalse,
      reason: 'modo SaaS usa o processador atômico, não o serviço local',
    );
    expect(getIt<IEmployeeManagementRepository>(), isNotNull);
    expect(getIt<IEmployeeRepository>(), isNotNull);
    expect(getIt<IFinancialTransactionRepository>(), isNotNull);
    expect(getIt<IInvoiceNotificationRepository>(), isNotNull);
    expect(getIt<IInvoiceRepository>(), isNotNull);
    expect(getIt<IPlanRepository>(), isNotNull);
    expect(getIt<IPlanRequestRepository>(), isNotNull);
    expect(getIt<IPurchaseAtomicProcessor>(), isNotNull);
    expect(getIt<IPurchaseRepository>(), isNotNull);
    expect(getIt<IQuotationRepository>(), isNotNull);
    expect(getIt<ISaleAtomicProcessor>(), isNotNull);
    expect(getIt<ISaleCancellationProcessor>(), isNotNull);
    expect(getIt<ISaleRepository>(), isNotNull);
    expect(getIt<IStockAdjustmentProcessor>(), isNotNull);
    expect(getIt<IStockLotRepository>(), isNotNull);
    expect(getIt<IStoreRepository>(), isNotNull);
    expect(getIt<ITenantRepository>(), isNotNull);
    expect(getIt<AddDebtUseCase>(), isNotNull);
    expect(getIt<AddEmployeeUseCase>(), isNotNull);
    expect(getIt<AddFinancialTransactionUseCase>(), isNotNull);
    expect(getIt<AddPlanUseCase>(), isNotNull);
    expect(getIt<AddProductUseCase>(), isNotNull);
    expect(getIt<ProcessPurchaseUseCase>(), isNotNull);
    expect(getIt<AddStoreUseCase>(), isNotNull);
    expect(getIt<ApproveTenantUseCase>(), isNotNull);
    expect(getIt<CancelInvoiceUseCase>(), isNotNull);
    expect(getIt<CancelSaleUseCase>(), isNotNull);
    expect(getIt<CheckTenantsForInvoicesUseCase>(), isNotNull);
    expect(getIt<CloseCashRegisterUseCase>(), isNotNull);
    expect(getIt<DecidePlanRequestUseCase>(), isNotNull);
    expect(getIt<DeleteCustomerUseCase>(), isNotNull);
    expect(getIt<FifoStockUseCase>(), isNotNull);
    expect(getIt<GenerateInvoiceUseCase>(), isNotNull);
    expect(getIt<GetAllInvoicesUseCase>(), isNotNull);
    expect(getIt<GetAllPlansUseCase>(), isNotNull);
    expect(getIt<GetAllTenantsUseCase>(), isNotNull);
    expect(getIt<GetAuditLogUseCase>(), isNotNull);
    expect(getIt<GetCashClosingSummaryUseCase>(), isNotNull);
    expect(getIt<GetCashFlowUseCase>(), isNotNull);
    expect(getIt<GetCustomersUseCase>(), isNotNull);
    expect(getIt<GetDashboardKpisUseCase>(), isNotNull);
    expect(getIt<GetEmployeesUseCase>(), isNotNull);
    expect(getIt<GetMyPlanRequestsUseCase>(), isNotNull);
    expect(getIt<GetMyTenantUseCase>(), isNotNull);
    expect(getIt<GetPendingDebtsUseCase>(), isNotNull);
    expect(getIt<GetPendingInvoicesUseCase>(), isNotNull);
    expect(getIt<GetPendingPlanRequestsUseCase>(), isNotNull);
    expect(getIt<GetPendingTenantsUseCase>(), isNotNull);
    expect(getIt<GetPlansUseCase>(), isNotNull);
    expect(getIt<GetPurchasesUseCase>(), isNotNull);
    expect(getIt<GetSalesReportUseCase>(), isNotNull);
    expect(getIt<GetSettledDebtsUseCase>(), isNotNull);
    expect(getIt<GetStockLotsUseCase>(), isNotNull);
    expect(getIt<GetStoresUseCase>(), isNotNull);
    expect(getIt<GetTenantAdminMessagesUseCase>(), isNotNull);
    expect(getIt<GetTenantInvoicesUseCase>(), isNotNull);
    expect(getIt<GetTenantNotificationsUseCase>(), isNotNull);
    expect(getIt<MarkAdminMessageAsReadUseCase>(), isNotNull);
    expect(getIt<MarkAllAdminMessagesAsReadUseCase>(), isNotNull);
    expect(getIt<MarkAllNotificationsAsReadUseCase>(), isNotNull);
    expect(getIt<MarkInvoiceAsPaidUseCase>(), isNotNull);
    expect(getIt<MarkNotificationAsReadUseCase>(), isNotNull);
    expect(getIt<MarkTransactionAsPaidUseCase>(), isNotNull);
    expect(getIt<NotifyInvoiceGeneratedUseCase>(), isNotNull);
    expect(getIt<RejectTenantUseCase>(), isNotNull);
    expect(getIt<RequestPlanUpgradeUseCase>(), isNotNull);
    expect(getIt<RequestTenantAccessUseCase>(), isNotNull);
    expect(getIt<SendAdminMessageUseCase>(), isNotNull);
    expect(getIt<SetEmployeeActiveUseCase>(), isNotNull);
    expect(getIt<SettleDebtUseCase>(), isNotNull);
    expect(getIt<UpdateCustomerUseCase>(), isNotNull);
    expect(getIt<UpdatePlanUseCase>(), isNotNull);
    expect(getIt<UpdateProductStockUseCase>(), isNotNull);
    expect(getIt<UpdateProductUseCase>(), isNotNull);
    expect(getIt<UpdateTenantSettingsUseCase>(), isNotNull);
  });
}
