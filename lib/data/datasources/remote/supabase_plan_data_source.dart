import '../../../domain/entities/plan.dart';
import '../local/plan_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [PlanLocalDataSource] sobre o Supabase.
///
/// Planos são públicos para usuários logados (lista e leitura); a criação
/// e edição ficam restritas ao super admin pelo RLS
/// (`auth.jwt()->>'email' = e-mail do super admin`).
final class PlanSupabaseDataSourceImpl implements PlanLocalDataSource {
  const PlanSupabaseDataSourceImpl();

  static const _table = 'plans';
  static const _columns =
      'id, name, description, price_monthly, max_stores, max_employees, is_active';

  @override
  Future<List<Plan>> getActivePlans() async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('is_active', true)
        .order('price_monthly', ascending: true)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<List<Plan>> getAllPlans() async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .order('price_monthly', ascending: true)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<Plan?> getById(String id) async {
    final row = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _map(row);
  }

  @override
  Future<void> add(Plan plan) async {
    await supabaseClient.from(_table).insert({
      'id': plan.id,
      'name': plan.name,
      'description': plan.description,
      'price_monthly': plan.priceMonthlyCents,
      'max_stores': plan.maxStores,
      'max_employees': plan.maxEmployees,
      'is_active': plan.isActive,
    });
  }

  @override
  Future<void> update(Plan plan) async {
    final rows = await supabaseClient
        .from(_table)
        .update({
          'name': plan.name,
          'description': plan.description,
          'price_monthly': plan.priceMonthlyCents,
          'max_stores': plan.maxStores,
          'max_employees': plan.maxEmployees,
          'is_active': plan.isActive,
        })
        .eq('id', plan.id)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Plano ${plan.id} não encontrado para atualização.');
    }
  }

  Plan _map(Map<String, dynamic> row) => Plan(
    id: row['id'] as String,
    name: row['name'] as String,
    description: (row['description'] as String?) ?? '',
    priceMonthlyCents: (row['price_monthly'] as num).toInt(),
    maxStores: (row['max_stores'] as num).toInt(),
    maxEmployees: (row['max_employees'] as num).toInt(),
    isActive: (row['is_active'] as bool?) ?? true,
  );
}
