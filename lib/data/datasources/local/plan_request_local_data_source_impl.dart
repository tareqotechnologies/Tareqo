import '../../../core/utils/ids.dart';
import '../../../domain/entities/plan_request.dart';
import 'plan_request_local_data_source.dart';

/// Implementação em memória do [PlanRequestLocalDataSource].
final class PlanRequestLocalDataSourceImpl implements PlanRequestLocalDataSource {
  PlanRequestLocalDataSourceImpl({List<PlanRequest> seed = const []})
      : _requests = [...seed];

  final List<PlanRequest> _requests;

  @override
  Future<List<PlanRequest>> getByTenant(String tenantId) async {
    final sorted = _requests.where((r) => r.tenantId == tenantId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(sorted);
  }

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
      id: AppIds.newId('pr'),
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
    if (index < 0) {
      throw StateError('Pedido de upgrade $id não encontrado.');
    }
    _requests[index] = _requests[index].copyWith(
      status: approve ? PlanRequestStatus.approved : PlanRequestStatus.rejected,
      decidedAt: DateTime.now(),
    );
  }
}
