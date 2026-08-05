import '../../../domain/entities/plan.dart';
import 'plan_local_data_source.dart';

/// Implementação em memória do [PlanLocalDataSource].
///
/// Inicia vazia por padrão (testes dependem disso); o seed de demonstração
/// é injetado pelo ServiceLocator.
final class PlanLocalDataSourceImpl implements PlanLocalDataSource {
  PlanLocalDataSourceImpl({List<Plan> seed = const []}) : _plans = [...seed];

  final List<Plan> _plans;

  @override
  Future<List<Plan>> getActivePlans() async => List.unmodifiable(
        [..._plans.where((plan) => plan.isActive)]
          ..sort((a, b) => a.priceMonthly.compareTo(b.priceMonthly)),
      );

  @override
  Future<List<Plan>> getAllPlans() async => List.unmodifiable(
        [..._plans]
          ..sort((a, b) => a.priceMonthly.compareTo(b.priceMonthly)),
      );

  @override
  Future<Plan?> getById(String id) async {
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  @override
  Future<void> add(Plan plan) async {
    _plans.add(plan);
  }

  @override
  Future<void> update(Plan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index < 0) {
      throw StateError('Plano ${plan.id} não encontrado para atualização.');
    }
    _plans[index] = plan;
  }
}
