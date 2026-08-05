import '../../../domain/entities/customer.dart';
import '../local/customer_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [CustomerLocalDataSource] sobre o Supabase.
///
/// O RLS (`auth.uid() = user_id`) isola os dados por tenant; o `user_id` é
/// gravado explicitamente nos INSERTs (o trigger do schema reforça com
/// `auth.uid()`).
final class CustomerSupabaseDataSourceImpl implements CustomerLocalDataSource {
  const CustomerSupabaseDataSourceImpl();

  static const _table = 'customers';

  @override
  Future<List<Customer>> getAll({required String storeId}) async {
    final rows = await supabaseClient
        .from(_table)
        .select('id, store_id, name, phone, email')
        .eq('store_id', storeId)
        .order('name', ascending: true);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> add(Customer customer) async {
    await supabaseClient.from(_table).insert({
      'id': customer.id,
      'user_id': requireCurrentUserId(),
      'store_id': customer.storeId,
      'name': customer.name,
      'phone': customer.phone,
      'email': customer.email,
    });
  }

  Customer _map(Map<String, dynamic> row) => Customer(
        id: row['id'] as String,
        storeId: row['store_id'] as String,
        name: row['name'] as String,
        phone: (row['phone'] as String?) ?? '',
        email: (row['email'] as String?) ?? '',
      );
}
