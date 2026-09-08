import 'package:postgrest/postgrest.dart';

import '../../../domain/entities/store_employee.dart';
import '../local/employee_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [EmployeeLocalDataSource] sobre o Supabase.
///
/// O dono vincula funcionários às lojas do tenant; o RLS limita a gestão
/// ao dono (e leitura ao próprio funcionário). O `tenant_id` é reforçado
/// pelo trigger anti-forja `trg_store_employees_tenant` (função
/// `set_employee_tenant`) do schema.
final class EmployeeSupabaseDataSourceImpl implements EmployeeLocalDataSource {
  /// [rpc] injetável para testes — mesmo contrato do `SupabaseEmployeeProcessor`
  /// (`Future<dynamic> Function(String fn, Map<String, dynamic> params)`),
  /// que permite o teste de CONTRATO da tradução de `PostgrestException` da
  /// RPC `set_employee_active` sem inicializar o cliente real. `null` (padrão)
  /// → cliente global ([supabaseClient]), como nos demais datasources.
  const EmployeeSupabaseDataSourceImpl({
    Future<dynamic> Function(String fn, Map<String, dynamic> params)? rpc,
  }) : _rpcOverride = rpc;

  final Future<dynamic> Function(String fn, Map<String, dynamic> params)?
  _rpcOverride;

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) =>
      _rpcOverride != null
      ? _rpcOverride(fn, params)
      : supabaseClient.rpc(fn, params: params);

  static const _table = 'store_employees';
  static const _columns =
      'id, tenant_id, store_id, user_id, full_name, '
      'email, role, is_active';

  @override
  Future<List<StoreEmployee>> getByTenant(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .order('full_name', ascending: true)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<List<StoreEmployee>> getByStore(String storeId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('store_id', storeId)
        .order('full_name', ascending: true)
        .limit(SupabaseQueryLimits.pageSize);
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
      'is_active': employee.isActive,
    });
  }

  @override
  Future<void> setActive({
    required String employeeId,
    required bool isActive,
  }) async {
    // RPC `set_employee_active` (SECURITY DEFINER): revalida que o chamador
    // é o DONO do tenant do vínculo e atualiza apenas is_active.
    try {
      await _rpc('set_employee_active', {
        'p_employee_id': employeeId,
        'p_is_active': isActive,
      });
    } on PostgrestException catch (error) {
      // As exceções do RPC (não-dono, vínculo inexistente, rede) chegam
      // como PostgrestException — traduz para texto amigável (mesmo
      // padrão do SupabaseEmployeeProcessor).
      throw StateError(_friendlyMessage(error.message));
    }
  }

  /// Traduz as mensagens do RPC `set_employee_active` para texto amigável.
  static String _friendlyMessage(String serverMessage) {
    if (serverMessage.contains('Apenas o dono')) {
      return 'Apenas o dono do tenant pode ativar/desativar funcionários.';
    }
    if (serverMessage.contains('Funcionário não encontrado')) {
      return 'Funcionário não encontrado. Atualize a lista e tente novamente.';
    }
    return 'Não foi possível atualizar o funcionário. Tente novamente.';
  }

  StoreEmployee _map(Map<String, dynamic> row) => StoreEmployee(
    id: row['id'] as String,
    tenantId: row['tenant_id'] as String,
    storeId: row['store_id'] as String,
    userId: row['user_id'] as String,
    fullName: row['full_name'] as String,
    email: row['email'] as String,
    role: EmployeeRole.values.byName(row['role'] as String),
    // Legado: servidor antigo sem a coluna → vínculo considerado ativo.
    isActive: row['is_active'] as bool? ?? true,
  );
}
