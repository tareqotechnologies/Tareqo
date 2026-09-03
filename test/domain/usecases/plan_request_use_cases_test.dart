import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/plan_request.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_plan_request_repository.dart';
import 'package:tareqo/domain/repositories/i_tenant_repository.dart';
import 'package:tareqo/domain/usecases/decide_plan_request_use_case.dart';
import 'package:tareqo/domain/usecases/get_pending_plan_requests_use_case.dart';
import 'package:tareqo/domain/usecases/request_plan_upgrade_use_case.dart';

class _FakePlanRequestRepository implements IPlanRequestRepository {
 final List<PlanRequest> _requests = [];

 @override
 Future<List<PlanRequest>> getByTenant(String tenantId) async =>
 List.unmodifiable(
 _requests.where((r) => r.tenantId == tenantId).toList()
 ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
 );

 @override
 Future<PlanRequest?> getById(String id) async {
 for (final request in _requests) {
 if (request.id == id) return request;
 }
 return null;
 }

 @override
 Future<List<PlanRequest>> getPending() async => List.unmodifiable(
 _requests.where((r) => r.status == PlanRequestStatus.pending),
 );

 @override
 Future<PlanRequest> create({
 required String tenantId,
 required String currentPlanId,
 required String requestedPlanId,
 }) async {
 final request = PlanRequest(
 id: 'pr_${_requests.length + 1}',
 tenantId: tenantId,
 currentPlanId: currentPlanId,
 requestedPlanId: requestedPlanId,
 status: PlanRequestStatus.pending,
 createdAt: DateTime.now(),
 );
 _requests.add(request);
 return request;
 }

 @override
 Future<void> decide(String id, {required bool approve}) async {
 final index = _requests.indexWhere((r) => r.id == id);
 _requests[index] = _requests[index].copyWith(
 status: approve
 ? PlanRequestStatus.approved
 : PlanRequestStatus.rejected,
 decidedAt: DateTime.now(),
 );
 }
}

class _FakeTenantRepository implements ITenantRepository {
 Tenant tenant;
 String? updatedPlanId;

 _FakeTenantRepository(this.tenant);

 @override
 Future<Tenant?> getMyTenant(String userId) async => tenant;

 @override
 Future<Tenant?> getById(String id) async =>
 tenant.id == id ? tenant : null;

 @override
 Future<Tenant> requestAccess({
 required String ownerUserId,
 required String businessName,
 required String planId,
 required String currencyCode,
 required String language,
 }) =>
 throw UnimplementedError();

 @override
 Future<void> updateSettings(
 String id, {
 required String currencyCode,
 required String language,
 }) async {}

 @override
 Future<void> approve(String id) async {}

 @override
 Future<void> reject(String id, String reason) async {}

 @override
 Future<void> updatePlan(String id, String planId) async {
 updatedPlanId = planId;
 tenant = tenant.copyWith(planId: planId);
 }

 @override
 Future<List<Tenant>> getPending() async => const [];  @override
  Future<List<Tenant>> getAll() async => [tenant];

  @override
  Future<void> updateBilling(
    String id, {
    required DateTime planExpiresAt,
    required DateTime nextInvoiceAt,
  }) async {}
}

void main() {
 Tenant approvedTenant({String planId = 'pl1'}) => Tenant(
 id: 'tn1',
 ownerUserId: 'u1',
 businessName: 'Comercial X',
 planId: planId,
 status: TenantStatus.approved,
 approvedAt: DateTime.now(),
 createdAt: DateTime.now(),
 );

 group('RequestPlanUpgradeUseCase', () {
 test('cria o pedido quando válido', () async {
 final requestRepository = _FakePlanRequestRepository();
 final useCase = RequestPlanUpgradeUseCase(
 requestRepository,
 _FakeTenantRepository(approvedTenant()),
 );

 await useCase(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 );

 expect(await requestRepository.getPending(), hasLength(1));
 });

 test('lança InvalidPlanRequestException com plano igual ao atual',
 () async {
 final useCase = RequestPlanUpgradeUseCase(
 _FakePlanRequestRepository(),
 _FakeTenantRepository(approvedTenant()),
 );

 await expectLater(
 useCase(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl1',
 ),
 throwsA(isA<InvalidPlanRequestException>()),
 );
 });

 test('lança InvalidPlanRequestException com pedido pendente existente',
 () async {
 final requestRepository = _FakePlanRequestRepository();
 await requestRepository.create(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 );
 final useCase = RequestPlanUpgradeUseCase(
 requestRepository,
 _FakeTenantRepository(approvedTenant()),
 );

 await expectLater(
 useCase(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl3',
 ),
 throwsA(isA<InvalidPlanRequestException>()),
 );
 });

 test('lança InvalidPlanRequestException com tenant não aprovado',
 () async {
 final tenant = Tenant(
 id: 'tn1',
 ownerUserId: 'u1',
 businessName: 'X',
 planId: 'pl1',
 status: TenantStatus.pending,
 createdAt: DateTime.now(),
 );
 final useCase = RequestPlanUpgradeUseCase(
 _FakePlanRequestRepository(),
 _FakeTenantRepository(tenant),
 );

 await expectLater(
 useCase(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 ),
 throwsA(isA<InvalidPlanRequestException>()),
 );
 });
 });

 group('DecidePlanRequestUseCase', () {
 test('aprovar o pedido troca o plano do tenant', () async {
 final requestRepository = _FakePlanRequestRepository();
 final request = await requestRepository.create(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 );
 final tenantRepository = _FakeTenantRepository(approvedTenant());
 final useCase = DecidePlanRequestUseCase(
 requestRepository,
 tenantRepository,
 );

 await useCase(request.id, approve: true);

 expect(
 (await requestRepository.getById(request.id))!.status,
 PlanRequestStatus.approved,
 );
 expect(tenantRepository.updatedPlanId, 'pl2');
 });

 test('decidir um pedido já decidido lança StateError', () async {
 final requestRepository = _FakePlanRequestRepository();
 final request = await requestRepository.create(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 );
 final useCase = DecidePlanRequestUseCase(
 requestRepository,
 _FakeTenantRepository(approvedTenant()),
 );

 await useCase(request.id, approve: true);

 await expectLater(
 useCase(request.id, approve: false),
 throwsStateError,
 );
 });

 test('rejeitar não altera o plano do tenant', () async {
 final requestRepository = _FakePlanRequestRepository();
 final request = await requestRepository.create(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 );
 final tenantRepository = _FakeTenantRepository(approvedTenant());
 final useCase = DecidePlanRequestUseCase(
 requestRepository,
 tenantRepository,
 );

 await useCase(request.id, approve: false);

 expect(
 (await requestRepository.getById(request.id))!.status,
 PlanRequestStatus.rejected,
 );
 expect(tenantRepository.updatedPlanId, isNull);
 });

 test('getPending retorna apenas os pendentes', () async {
 final requestRepository = _FakePlanRequestRepository();
 final request = await requestRepository.create(
 tenantId: 'tn1',
 currentPlanId: 'pl1',
 requestedPlanId: 'pl2',
 );
 await requestRepository.decide(request.id, approve: true);

 expect(await GetPendingPlanRequestsUseCase(requestRepository)(), isEmpty);
 });
 });
}
