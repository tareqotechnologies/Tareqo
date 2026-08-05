import '../../../domain/entities/store_employee.dart';
import '../local/employee_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [EmployeeLocalDataSource] sobre o Supabase.
///
/// O dono vincula funcionários às lojas do tenant; o RLS limita a gestão
/// ao dono (e leitura ao próprio funcionário). O `tenant_id` é reforçado
/// pelo trigger `set_employee_tenant_from_store` do schema.
final class EmployeeSupabaseDataSourceImpl implements EmployeeLocalDataSource {
  const EmployeeSupabaseDataSourceImpl();

  static const _table = 'store_employees';
  static const _columns = 'id, tenant_id, store_id, user_id, full_name, '
      'email, role';

  @override
  Future<List<StoreEmployee>> getByTenant(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .order('full_name', ascending: true);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<List<StoreEmployee>> getByStore(String storeId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('store_id', storeId)
        .order('full_name', ascending: true);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> add(StoreEmployee employee) async {
    await supabaseClient.from(_table).insert({
      'id': employee.id,
      'tenant_id': employee.tenantId,
      'store_id': employee.storeId,
      'user_id': employee.userId,
      'full_name': employee.fullName,
      'email': employee.email,
      'role': employee.role.name,
    });
  }

  StoreEmployee _map(Map<String, dynamic> row) => StoreEmployee(
        id: row['id'] as String,
        tenantId: row['tenant_id'] as String,
        storeId: row['store_id'] as String,
        userId: row['user_id'] as String,
        fullName: row['full_name'] as String,
        email: row['email'] as String,
        role: EmployeeRole.values.byName(row['role'] as String),
      );
}
