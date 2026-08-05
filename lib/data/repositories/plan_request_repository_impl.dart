import '../../domain/entities/plan_request.dart';
import '../../domain/repositories/i_plan_request_repository.dart';
import '../datasources/local/plan_request_local_data_source.dart';

/// Implementação de [IPlanRequestRepository] sobre um
/// [PlanRequestLocalDataSource].
final class PlanRequestRepositoryImpl implements IPlanRequestRepository {
  const PlanRequestRepositoryImpl(this._localDataSource);

  final PlanRequestLocalDataSource _localDataSource;

  @override
  Future<List<PlanRequest>> getByTenant(String tenantId) =>
      _localDataSource.getByTenant(tenantId);

  @override
  Future<PlanRequest?> getById(String id) => _localDataSource.getById(id);

  @override
  Future<List<PlanRequest>> getPending() => _localDataSource.getPending();

  @override
  Future<PlanRequest> create({
    required String tenantId,
    required String currentPlanId,
    required String requestedPlanId,
  }) =>
      _localDataSource.create(
        tenantId: tenantId,
        currentPlanId: currentPlanId,
        requestedPlanId: requestedPlanId,
      );

  @override
  Future<void> decide(String id, {required bool approve}) =>
      _localDataSource.decide(id, approve: approve);
}
