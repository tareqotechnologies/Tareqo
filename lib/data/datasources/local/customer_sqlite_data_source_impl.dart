import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/customer.dart';
import 'customer_local_data_source.dart';

/// Implementação SQLite do [CustomerLocalDataSource].
///
/// Mantém **as mesmas assinaturas** do contrato, então a troca de
/// persistência acontece apenas no ServiceLocator. Usa SQL parametrizado
/// (prepared statements).
final class CustomerSqliteDataSourceImpl implements CustomerLocalDataSource {
 const CustomerSqliteDataSourceImpl(this._db);

 final Database _db;

 static const _columns = 'id, store_id, name, phone, email';

 @override
 Future<List<Customer>> getAll({required String storeId}) async {
 final rows = _db.select(
 'SELECT $_columns FROM customers WHERE store_id = ? '
 'ORDER BY name COLLATE NOCASE',
 [storeId],
 );
 return [for (final row in rows) _map(row)];
 }

 @override
 Future<void> add(Customer customer) async {
 _db.execute(
 'INSERT INTO customers ($_columns) VALUES (?, ?, ?, ?, ?)',
 [
 customer.id,
 customer.storeId,
 customer.name,
 customer.phone,
 customer.email,
 ],
 );
 }

 Customer _map(Row row) => Customer(
 id: row['id'] as String,
 storeId: row['store_id'] as String,
 name: row['name'] as String,
 phone: (row['phone'] as String?) ?? '',
 email: (row['email'] as String?) ?? '',
 );
}
