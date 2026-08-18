import '../../domain/entities/plan.dart';
import '../../domain/repositories/i_plan_repository.dart';
import '../datasources/local/plan_local_data_source.dart';

/// Implementação de [IPlanRepository] sobre um [PlanLocalDataSource].
final class PlanRepositoryImpl implements IPlanRepository {
 const PlanRepositoryImpl(this._localDataSource);

 final PlanLocalDataSource _localDataSource;

 @override
 Future<List<Plan>> getActivePlans() => _localDataSource.getActivePlans();

 @override
 Future<List<Plan>> getAllPlans() => _localDataSource.getAllPlans();

 @override
 Future<Plan?> getById(String id) => _localDataSource.getById(id);

 @override
 Future<void> add(Plan plan) => _localDataSource.add(plan);

 @override
 Future<void> update(Plan plan) => _localDataSource.update(plan);
}
