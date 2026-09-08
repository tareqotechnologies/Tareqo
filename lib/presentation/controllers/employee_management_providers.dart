import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/employee_management.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/i_employee_commission_summary_repository.dart';
import '../../domain/repositories/i_employee_management_repository.dart';
import '../../domain/usecases/employee_commission_calculator.dart';
import 'account_providers.dart';
import 'auth_providers.dart';
import 'sales_providers.dart';

/// Ponte com o ServiceLocator (GetIt): expõe o repositório de gestão de
/// funcionários como provider.
final employeeManagementRepositoryProvider =
    Provider<IEmployeeManagementRepository>(
      (ref) => ServiceLocator.instance<IEmployeeManagementRepository>(),
    );

/// Resumo de comissões calculado NO SERVIDOR (Supabase) — registrado
/// apenas no modo remoto; `null` no modo local/offline (o provider usa a
/// computação local).
final employeeCommissionSummaryRepositoryProvider =
    Provider<IEmployeeCommissionSummaryRepository?>(
      (ref) =>
          ServiceLocator.instance
              .isRegistered<IEmployeeCommissionSummaryRepository>()
          ? ServiceLocator.instance<IEmployeeCommissionSummaryRepository>()
          : null,
    );

/// Registos de ponto do dia [workDate] na loja ativa.
final attendanceProvider = FutureProvider.autoDispose
    .family<List<EmployeeAttendance>, String>((ref, workDate) async {
      final user = ref.watch(authStateProvider).value;
      final storeId = user == null
          ? null
          : ref.watch(activeStoreIdProvider(user.id));
      if (storeId == null) return const [];
      final repo = ref.watch(employeeManagementRepositoryProvider);
      return repo.getAttendance(storeId: storeId, workDate: workDate);
    });

/// Taxas de comissão da loja ativa.
final commissionRatesProvider = FutureProvider<List<EmployeeCommissionRate>>((
  ref,
) async {
  final user = ref.watch(authStateProvider).value;
  final storeId = user == null
      ? null
      : ref.watch(activeStoreIdProvider(user.id));
  if (storeId == null) return const [];
  final repo = ref.watch(employeeManagementRepositoryProvider);
  return repo.getCommissionRates(storeId: storeId);
});

/// Metas da loja ativa (todas — o filtro por mês é feito na aba).
final targetsProvider = FutureProvider<List<EmployeeTarget>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  final storeId = user == null
      ? null
      : ref.watch(activeStoreIdProvider(user.id));
  if (storeId == null) return const [];
  final repo = ref.watch(employeeManagementRepositoryProvider);
  return repo.getTargets(storeId: storeId);
});

/// Resumo de comissões do mês [month] (`YYYY-MM`) na loja ativa.
///
/// Supabase: RPC `get_employee_commission_summary` (agregação server-side
/// das vendas reais). Local/offline: calcula das vendas reais via
/// [calculateEmployeeCommissions] — a MESMA semântica, sobre os mesmos
/// dados; venda sem `userId` (legada) nunca gera comissão.
final commissionSummaryProvider = FutureProvider.autoDispose
    .family<List<EmployeeCommissionSummaryEntry>, String>((ref, month) async {
      final user = ref.watch(authStateProvider).value;
      final tenant = user == null
          ? null
          : ref.watch(myTenantProvider(user.id)).value;
      final storeId = user == null
          ? null
          : ref.watch(activeStoreIdProvider(user.id));
      if (user == null || tenant == null || storeId == null) return const [];

      final server = ref.watch(employeeCommissionSummaryRepositoryProvider);
      if (server != null) {
        return server.getSummary(storeId: storeId, month: month);
      }

      // Caminho local: roster real + vendas reais + taxas cadastradas.
      final employees =
          ref.watch(employeesProvider(tenant.id)).value ?? const [];
      final sales = ref.watch(salesListProvider).value ?? const <Sale>[];
      final rates = ref.watch(commissionRatesProvider).value ?? const [];
      return calculateEmployeeCommissions(
        roster: employees,
        sales: sales,
        rateBpsByUserId: {for (final rate in rates) rate.userId: rate.rateBps},
        storeId: storeId,
        month: month,
      );
    });
