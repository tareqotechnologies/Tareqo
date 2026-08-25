import '../../../domain/entities/store.dart';
import '../local/store_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [StoreLocalDataSource] sobre o Supabase.
///
/// O RLS restringe as lojas ao dono do tenant (via `tenant_id` → tenant →
/// `owner_user_id = auth.uid()`) e ao super admin. O `tenant_id` é gravado
/// explicitamente; o trigger `set_tenant_id_from_owner` do schema reforça
/// no servidor.
final class StoreSupabaseDataSourceImpl implements StoreLocalDataSource {
 const StoreSupabaseDataSourceImpl();  static const _table = 'stores';
  static const _columns = 'id, tenant_id, name, address, phone, email, nuit, city';

 @override
 Future<List<Store>> getByTenant(String tenantId) async {
 final rows = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('tenant_id', tenantId)
 .order('created_at', ascending: true)
 .limit(SupabaseQueryLimits.pageSize);
 return List.unmodifiable([for (final row in rows) _map(row)]);
 }  @override
  Future<void> add(Store store) async {
    await supabaseClient.from(_table).insert({
      'id': store.id,
      'tenant_id': store.tenantId,
      'name': store.name,
      'address': store.address,
      'phone': store.phone,
      'email': store.email,
      'nuit': store.nuit,
      'city': store.city,
    });
  }

  @override
  Future<void> update(Store store) async {
    await supabaseClient.from(_table).update({
      'name': store.name,
      'address': store.address,
      'phone': store.phone,
      'email': store.email,
      'nuit': store.nuit,
      'city': store.city,
    }).eq('id', store.id);
  }  Store _map(Map<String, dynamic> row) => Store(
    id: row['id'] as String,
    tenantId: row['tenant_id'] as String,
    name: row['name'] as String,
    address: (row['address'] as String?) ?? '',
    phone: (row['phone'] as String?) ?? '',
    email: (row['email'] as String?) ?? '',
    nuit: (row['nuit'] as String?) ?? '',
    city: (row['city'] as String?) ?? '',
  );
}
