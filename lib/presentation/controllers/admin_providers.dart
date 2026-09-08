import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/i_admin_repository.dart';
import '../../domain/entities/plan_request.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/usecases/decide_plan_request_use_case.dart';
import '../../domain/usecases/get_audit_log_use_case.dart';
import '../../domain/usecases/get_all_tenants_use_case.dart';
import '../../domain/usecases/get_pending_plan_requests_use_case.dart';
import '../../domain/usecases/get_all_plans_use_case.dart';
import '../../domain/usecases/get_pending_tenants_use_case.dart';

/// Ponte com o ServiceLocator (GetIt): repositório do papel de super admin
/// (substituível em testes).
final adminRepositoryProvider = Provider<IAdminRepository>(
  (ref) => ServiceLocator.instance<IAdminRepository>(),
);

/// O usuário logado é super admin? Papel **baseado em banco** — a tabela
/// `public.super_admins` no Supabase (RPC `is_super_admin`), nunca e-mail
/// hardcoded. A chave [userId] é apenas o cache do provider (o papel é
/// resolvido no servidor com a sessão do próprio usuário). Mudanças de
/// papel refletem no próximo login/invalidação — o RLS do servidor é a
/// autoridade, o cliente decide apenas a navegação.
final isSuperAdminProvider = FutureProvider.family<bool, String>((
  ref,
  userId,
) async {
  return ref.watch(adminRepositoryProvider).isSuperAdmin();
});

/// Ponte com o ServiceLocator (GetIt): casos de uso do painel do super
/// admin como providers (substituíveis em testes).
final getPendingTenantsUseCaseProvider = Provider<GetPendingTenantsUseCase>(
  (ref) => ServiceLocator.instance<GetPendingTenantsUseCase>(),
);

final getAllTenantsUseCaseProvider = Provider<GetAllTenantsUseCase>(
  (ref) => ServiceLocator.instance<GetAllTenantsUseCase>(),
);

final getAllPlansUseCaseProvider = Provider<GetAllPlansUseCase>(
  (ref) => ServiceLocator.instance<GetAllPlansUseCase>(),
);

final getPendingPlanRequestsUseCaseProvider =
    Provider<GetPendingPlanRequestsUseCase>(
      (ref) => ServiceLocator.instance<GetPendingPlanRequestsUseCase>(),
    );
final decidePlanRequestUseCaseProvider = Provider<DecidePlanRequestUseCase>(
  (ref) => ServiceLocator.instance<DecidePlanRequestUseCase>(),
);

final getAuditLogUseCaseProvider = Provider<GetAuditLogUseCase>(
  (ref) => ServiceLocator.instance<GetAuditLogUseCase>(),
);

/// Estado: solicitações de tenant aguardando aprovação.
final pendingTenantsProvider =
    AsyncNotifierProvider<PendingTenantsNotifier, List<Tenant>>(
      PendingTenantsNotifier.new,
    );

class PendingTenantsNotifier extends AsyncNotifier<List<Tenant>> {
  @override
  Future<List<Tenant>> build() =>
      ref.watch(getPendingTenantsUseCaseProvider).call();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado: todos os tenants (painel do super admin).
final allTenantsProvider =
    AsyncNotifierProvider<AllTenantsNotifier, List<Tenant>>(
      AllTenantsNotifier.new,
    );

class AllTenantsNotifier extends AsyncNotifier<List<Tenant>> {
  @override
  Future<List<Tenant>> build() =>
      ref.watch(getAllTenantsUseCaseProvider).call();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado: todos os planos, incluindo inativos (gestão de planos).
final allPlansProvider = AsyncNotifierProvider<AllPlansNotifier, List<Plan>>(
  AllPlansNotifier.new,
);

class AllPlansNotifier extends AsyncNotifier<List<Plan>> {
  @override
  Future<List<Plan>> build() => ref.watch(getAllPlansUseCaseProvider).call();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado: pedidos de upgrade aguardando decisão.
final pendingPlanRequestsProvider =
    AsyncNotifierProvider<PendingPlanRequestsNotifier, List<PlanRequest>>(
      PendingPlanRequestsNotifier.new,
    );

class PendingPlanRequestsNotifier extends AsyncNotifier<List<PlanRequest>> {
  @override
  Future<List<PlanRequest>> build() =>
      ref.watch(getPendingPlanRequestsUseCaseProvider).call();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Estado: registo de auditoria (ações admin).
final auditLogProvider =
    AsyncNotifierProvider<AuditLogNotifier, List<AuditEntry>>(
      AuditLogNotifier.new,
    );

class AuditLogNotifier extends AsyncNotifier<List<AuditEntry>> {
  @override
  Future<List<AuditEntry>> build() =>
      ref.watch(getAuditLogUseCaseProvider).call();

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
