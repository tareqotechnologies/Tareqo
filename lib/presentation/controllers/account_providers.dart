import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_settings.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/employee_account_service.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/plan_request.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/store_employee.dart';
import '../../domain/entities/tenant.dart';
import '../../domain/usecases/add_employee_use_case.dart';
import '../../domain/usecases/add_plan_use_case.dart';
import '../../domain/usecases/add_store_use_case.dart';
import '../../domain/usecases/approve_tenant_use_case.dart';
import '../../domain/usecases/get_employees_use_case.dart';
import '../../domain/usecases/get_my_plan_requests_use_case.dart';
import '../../domain/usecases/get_my_tenant_use_case.dart';
import '../../domain/usecases/get_plans_use_case.dart';
import '../../domain/usecases/get_stores_use_case.dart';
import '../../domain/usecases/reject_tenant_use_case.dart';
import '../../domain/usecases/request_plan_upgrade_use_case.dart';
import '../../domain/usecases/request_tenant_access_use_case.dart';
import '../../domain/usecases/update_plan_use_case.dart';
import '../../domain/usecases/update_tenant_settings_use_case.dart';
import 'auth_providers.dart';

/// Ponte com o ServiceLocator (GetIt): expõe os casos de uso da camada de
/// Contas como providers, permitindo substituí-los facilmente em testes.
final getPlansUseCaseProvider = Provider<GetPlansUseCase>(
  (ref) => ServiceLocator.instance<GetPlansUseCase>(),
);

final addPlanUseCaseProvider = Provider<AddPlanUseCase>(
  (ref) => ServiceLocator.instance<AddPlanUseCase>(),
);

final updatePlanUseCaseProvider = Provider<UpdatePlanUseCase>(
  (ref) => ServiceLocator.instance<UpdatePlanUseCase>(),
);

final getMyTenantUseCaseProvider = Provider<GetMyTenantUseCase>(
  (ref) => ServiceLocator.instance<GetMyTenantUseCase>(),
);

final requestTenantAccessUseCaseProvider = Provider<RequestTenantAccessUseCase>(
  (ref) => ServiceLocator.instance<RequestTenantAccessUseCase>(),
);

final updateTenantSettingsUseCaseProvider = Provider<UpdateTenantSettingsUseCase>(
  (ref) => ServiceLocator.instance<UpdateTenantSettingsUseCase>(),
);

/// Preferências do tenant (**moeda** e **idioma**) escolhidas pelo dono —
/// o [DumbhanengueApp] as aplica no locale do MaterialApp e na
/// formatação de moeda ([Formatters]). Funcionários herdam a escolha.
final tenantSettingsProvider = Provider<AppSettings?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final tenant = ref.watch(myTenantProvider(user.id)).value;
  if (tenant == null) return null;
  return AppSettings(
    currencyCode: tenant.currencyCode,
    language: tenant.language,
  );
});

final approveTenantUseCaseProvider = Provider<ApproveTenantUseCase>(
  (ref) => ServiceLocator.instance<ApproveTenantUseCase>(),
);

final rejectTenantUseCaseProvider = Provider<RejectTenantUseCase>(
  (ref) => ServiceLocator.instance<RejectTenantUseCase>(),
);

final getStoresUseCaseProvider = Provider<GetStoresUseCase>(
  (ref) => ServiceLocator.instance<GetStoresUseCase>(),
);

final addStoreUseCaseProvider = Provider<AddStoreUseCase>(
  (ref) => ServiceLocator.instance<AddStoreUseCase>(),
);

final getEmployeesUseCaseProvider = Provider<GetEmployeesUseCase>(
  (ref) => ServiceLocator.instance<GetEmployeesUseCase>(),
);

final addEmployeeUseCaseProvider = Provider<AddEmployeeUseCase>(
  (ref) => ServiceLocator.instance<AddEmployeeUseCase>(),
);

final employeeAccountServiceProvider = Provider<EmployeeAccountService>(
  (ref) => ServiceLocator.instance<EmployeeAccountService>(),
);

final getMyPlanRequestsUseCaseProvider = Provider<GetMyPlanRequestsUseCase>(
  (ref) => ServiceLocator.instance<GetMyPlanRequestsUseCase>(),
);

final requestPlanUpgradeUseCaseProvider = Provider<RequestPlanUpgradeUseCase>(
  (ref) => ServiceLocator.instance<RequestPlanUpgradeUseCase>(),
);

/// Estado: planos ativos (seletor do onboarding e do upgrade).
final plansProvider = FutureProvider<List<Plan>>(
  (ref) => ref.watch(getPlansUseCaseProvider).call(),
);

/// Estado: tenant do usuário logado (dono ou funcionário).
final myTenantProvider = FutureProvider.autoDispose.family<Tenant?, String>(
  (ref, userId) => ref.watch(getMyTenantUseCaseProvider).call(userId),
);

/// Estado: lojas do tenant.
final storesProvider =
    FutureProvider.autoDispose.family<List<Store>, String>(
  (ref, tenantId) => ref.watch(getStoresUseCaseProvider).call(tenantId),
);

/// Loja ativa do usuário (seletor no topo das telas — Fase 2).
///
/// Por padrão, a primeira loja do tenant; o usuário pode trocar via
/// [ActiveStoreNotifier.select]. Quando o tenant ou a lista de lojas
/// muda (ex.: nova loja criada), a seleção volta a ser válida (primeira
/// loja) — nunca fica apontando para uma loja inexistente.
final activeStoreIdProvider =
    NotifierProvider.autoDispose.family<ActiveStoreNotifier, String?, String>(
  ActiveStoreNotifier.new,
);

class ActiveStoreNotifier extends Notifier<String?> {
  ActiveStoreNotifier(this.userId);

  /// Usuário logado — argumento do family provider (Riverpod 3.x injeta
  /// o argumento via construtor, não via `arg`).
  final String userId;

  /// Seleção feita pelo usuário, persistida entre rebuilds do notifier.
  ///
  /// ⚠️ NÃO lemos `state` dentro de `build()`: em um `Notifier` síncrono,
  /// ler o próprio `state` antes da primeira atribuição (`state =`) lança
  /// "Tried to read the state of an uninitialized provider" (ver docs do
  /// Riverpod). O campo guarda a seleção de forma segura.
  String? _selected;

  @override
  String? build() {
    final tenant = ref.watch(myTenantProvider(userId)).value;
    if (tenant == null) return null;
    final stores = ref.watch(storesProvider(tenant.id)).value ?? const [];
    if (stores.isEmpty) return null;
    // Se a seleção atual sumiu da lista (loja removida), volta à primeira.
    final current = _selected;
    if (current != null && stores.any((store) => store.id == current)) {
      return current;
    }
    return stores.first.id;
  }

  /// Define a loja ativa manualmente (seletor de lojas).
  void select(String storeId) {
    _selected = storeId;
    state = storeId;
  }
}

/// Estado: funcionários do tenant.
final employeesProvider =
    FutureProvider.autoDispose.family<List<StoreEmployee>, String>(
  (ref, tenantId) => ref.watch(getEmployeesUseCaseProvider).call(tenantId),
);

/// Estado: pedidos de upgrade do tenant.
final myPlanRequestsProvider =
    FutureProvider.autoDispose.family<List<PlanRequest>, String>(
  (ref, tenantId) => ref.watch(getMyPlanRequestsUseCaseProvider).call(tenantId),
);
