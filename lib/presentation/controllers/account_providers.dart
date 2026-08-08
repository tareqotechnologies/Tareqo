import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../../core/config/app_settings.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/empty_employee_realtime_signal_source.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/i_employee_realtime_signal_source.dart';
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
import '../../domain/usecases/set_employee_active_use_case.dart';
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

final setEmployeeActiveUseCaseProvider = Provider<SetEmployeeActiveUseCase>(
  (ref) => ServiceLocator.instance<SetEmployeeActiveUseCase>(),
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

/// Fonte de sinais de REALTIME do vínculo do funcionário logado
/// (bloqueio INSTANTÂNEO de desativados).
///
/// O `AuthGate` assina `.signals` e re-busca os vínculos a cada sinal —
/// emitido quando a linha do usuário em `store_employees` muda no servidor
/// (ex.: o dono desativou/reativou em outro dispositivo), sem esperar o
/// polling.
///
/// Modo Supabase: fonte real (postgres_changes, registrada pelo
/// ServiceLocator). Modo local/testes: fonte VAZIA (nunca emite — nenhum
/// canal de websocket é aberto; o polling do `AuthGate` segue como
/// fallback).
final employeeRealtimeSignalsProvider = Provider<IEmployeeRealtimeSignalSource>(
  (ref) {
    if (!ServiceLocator.instance.isRegistered<IEmployeeRealtimeSignalSource>()) {
      return const EmptyEmployeeRealtimeSignalSource();
    }
    return ServiceLocator.instance<IEmployeeRealtimeSignalSource>();
  },
);

/// Intervalo do polling de fallback do bloqueio reativo.
///
/// Padrão de produção: 30s. Override nos testes (ex.: 2s) para disparar
/// o timer com `tester.pump` sem esperar de verdade.
final employeePollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// Polling CENTRAL do bloqueio reativo de funcionários desativados.
///
/// Enquanto ALGUÉM observar este provider (ex.: o [AuthGate], quando há um
/// usuário logado), ele mantém ativas as duas fontes de re-verificação dos
/// vínculos do usuário:
///
/// 1. **Realtime** (Supabase): o vínculo do usuário mudou no servidor
///    (o dono desativou/reativou em outro dispositivo) — bloqueio
///    INSTANTÂNEO;
/// 2. **Timer de fallback** ([employeePollIntervalProvider]): cobre o
///    modo local (sem servidor) e websockets fora do ar.
///
/// A CADA sinal, [refreshEmployeeLinksIfNeeded] re-busca os vínculos — o
/// refresh re-emite `employeesProvider` e o bloqueio é reavaliado no build
/// do gate. **`autoDispose`**: quando o último consumidor sai (ex.:
/// sign-out), o timer de fallback e o canal Realtime são cancelados — nada
/// roda em segundo plano durante toda a sessão. Sem self-refresh: o
/// provider NÃO observa `employeesProvider`, então re-buscar não o recria
/// — sem loop.
final employeesPollingProvider = Provider.autoDispose<void>((ref) {
  final interval = ref.watch(employeePollIntervalProvider);
  final realtime = ref.watch(employeeRealtimeSignalsProvider);

  // Cada sinal (timer + Realtime) dispara a re-verificação automaticamente
  // — o consumidor só precisa MANTER o provider vivo (ref.watch); a
  // assinatura vive aqui e é cancelada no dispose.
  void onSignal() => refreshEmployeeLinksIfNeeded(ref);

  final periodicSub = Stream<void>.periodic(interval, (_) {}).listen(
    (_) => onSignal(),
  );
  final realtimeSub = realtime.signals.listen((_) => onSignal());
  ref.onDispose(() {
    periodicSub.cancel();
    realtimeSub.cancel();
  });
});

/// Re-busca os vínculos quando o usuário logado NÃO é o dono do tenant
/// aprovado (dono não pode ser desativado — evita consulta inútil). O
/// refresh dispara o rebuild de quem observa [employeesProvider],
/// reavaliando o bloqueio com dados frescos.
///
/// Chamado a cada sinal de [employeesPollingProvider].
void refreshEmployeeLinksIfNeeded(Ref ref) {
  final user = ref.read(authStateProvider).value;
  if (user == null) return;
  final tenant = ref.read(myTenantProvider(user.id)).value;
  // Só faz sentido para tenant APROVADO de não-dono (é o único caso em
  // que o bloqueio é avaliado — evita refresh inútil em pendente/rejeitado).
  if (tenant == null ||
      tenant.ownerUserId == user.id ||
      tenant.status != TenantStatus.approved) {
    return;
  }
  // O retorno é intencionalmente descartado (fire-and-forget).
  // ignore: unused_result
  ref.refresh(employeesProvider(tenant.id));
}

/// Nível de acesso do usuário logado dentro do tenant.
///
/// Ordem de privilégio: **owner** > **manager** > **employee**.
///
/// - **owner** — dono do tenant: acesso total (operação + gestão de
///   lojas/funcionários/plano/ajustes);
/// - **manager** — gerente de loja: operação completa (inclui compras e
///   relatórios), mas SEM gestão (só do dono);
/// - **employee** — funcionário comum: apenas operação diária (vendas,
///   produtos, financeiro, fiado, clientes).
enum UserAccessLevel {
  owner,
  manager,
  employee,
}

/// Nível de acesso do usuário logado: [UserAccessLevel.owner] para o dono
/// do tenant; caso contrário, o **maior cargo** entre os vínculos do
/// usuário em `store_employees` (manager > employee). `null` enquanto o
/// tenant/vínculos não estiverem resolvidos (ou usuário sem tenant).
///
/// ⚠️ Isto é apenas orientação de **navegação/UX**. A autoridade real é o
/// **servidor**: o RLS e as guardas das RPCs (ex.: `is_manager_of_store`
/// no `process_purchase`) negam a operação mesmo se um cliente modificado
/// chamar o PostgREST diretamente.
final currentAccessLevelProvider = Provider<UserAccessLevel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final tenant = ref.watch(myTenantProvider(user.id)).value;
  if (tenant == null) return null;
  // Dono do tenant → acesso total (sem precisar ler os vínculos).
  if (tenant.ownerUserId == user.id) return UserAccessLevel.owner;
  // Funcionário: resolve o cargo pelo vínculo em store_employees. Se o
  // usuário tiver vários vínculos, vale o MAIOR cargo (manager > employee).
  final employees =
      ref.watch(employeesProvider(tenant.id)).value ?? const <StoreEmployee>[];
  final links = employees.where((employee) => employee.userId == user.id);
  final isManager = links.any((employee) => employee.role == EmployeeRole.manager);
  return isManager ? UserAccessLevel.manager : UserAccessLevel.employee;
});

/// Estado: pedidos de upgrade do tenant.
final myPlanRequestsProvider =
    FutureProvider.autoDispose.family<List<PlanRequest>, String>(
  (ref, tenantId) => ref.watch(getMyPlanRequestsUseCaseProvider).call(tenantId),
);
