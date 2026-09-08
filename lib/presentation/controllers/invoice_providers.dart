import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/generate_invoice_use_case.dart';
import '../../domain/usecases/get_tenant_invoices_use_case.dart';
import '../../domain/usecases/get_pending_invoices_use_case.dart';
import '../../domain/usecases/get_all_invoices_use_case.dart';
import '../../domain/usecases/mark_invoice_as_paid_use_case.dart';
import '../../domain/usecases/cancel_invoice_use_case.dart';
import '../../domain/usecases/check_tenants_for_invoices_use_case.dart';

/// Ponte com o ServiceLocator: casos de uso de facturas como providers.
final generateInvoiceUseCaseProvider = Provider<GenerateInvoiceUseCase>(
  (ref) => ServiceLocator.instance<GenerateInvoiceUseCase>(),
);

final getTenantInvoicesUseCaseProvider = Provider<GetTenantInvoicesUseCase>(
  (ref) => ServiceLocator.instance<GetTenantInvoicesUseCase>(),
);

final getPendingInvoicesUseCaseProvider = Provider<GetPendingInvoicesUseCase>(
  (ref) => ServiceLocator.instance<GetPendingInvoicesUseCase>(),
);

final getAllInvoicesUseCaseProvider = Provider<GetAllInvoicesUseCase>(
  (ref) => ServiceLocator.instance<GetAllInvoicesUseCase>(),
);

final markInvoiceAsPaidUseCaseProvider = Provider<MarkInvoiceAsPaidUseCase>(
  (ref) => ServiceLocator.instance<MarkInvoiceAsPaidUseCase>(),
);

final cancelInvoiceUseCaseProvider = Provider<CancelInvoiceUseCase>(
  (ref) => ServiceLocator.instance<CancelInvoiceUseCase>(),
);

final checkTenantsForInvoicesUseCaseProvider =
    Provider<CheckTenantsForInvoicesUseCase>(
      (ref) => ServiceLocator.instance<CheckTenantsForInvoicesUseCase>(),
    );

/// Estado: facturas pendentes no sistema.
final pendingInvoicesProvider =
    AsyncNotifierProvider<PendingInvoicesNotifier, List<Invoice>>(
      PendingInvoicesNotifier.new,
    );

class PendingInvoicesNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() =>
      ref.watch(getPendingInvoicesUseCaseProvider).call();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado: todas as facturas no sistema.
final allInvoicesProvider =
    AsyncNotifierProvider<AllInvoicesNotifier, List<Invoice>>(
      AllInvoicesNotifier.new,
    );

class AllInvoicesNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() =>
      ref.watch(getAllInvoicesUseCaseProvider).call();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado: facturas de um tenant específico.
final tenantInvoicesProvider = FutureProvider.family<List<Invoice>, String>((
  ref,
  tenantId,
) async {
  return ref.watch(getTenantInvoicesUseCaseProvider).call(tenantId);
});
