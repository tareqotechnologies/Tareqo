import '../../../domain/entities/plan.dart';
import 'plan_local_data_source.dart';

/// Implementação em memória do [PlanLocalDataSource].
///
/// Inicia vazia por padrão (testes dependem disso); o catálogo real de
/// planos é injetado pelo ServiceLocator (ver PlanCatalog).
final class PlanLocalDataSourceImpl implements PlanLocalDataSource {
  PlanLocalDataSourceImpl({List<Plan> seed = const []}) : _plans = [...seed];

  final List<Plan> _plans;

  @override
  Future<List<Plan>> getActivePlans() async => List.unmodifiable(
        [..._plans.where((plan) => plan.isActive)]
          ..sort((a, b) => a.priceMonthlyCents.compareTo(b.priceMonthlyCents)),
      );

  @override
  Future<List<Plan>> getAllPlans() async => List.unmodifiable(
        [..._plans]
          ..sort((a, b) => a.priceMonthlyCents.compareTo(b.priceMonthlyCents)),
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
    // Espelha a PRIMARY KEY do banco (Supabase/SQLite): inserir um plano
    // com id já existente é um erro, não um no-op silencioso (protege
    // contra duplicação acidental na lista).
    if (_plans.any((p) => p.id == plan.id)) {
      throw StateError('Plano ${plan.id} já existe.');
    }
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
