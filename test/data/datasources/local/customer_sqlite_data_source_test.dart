import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/customer_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/customer.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
 late Database db;

 setUp(() => db = openTestDatabase());
 tearDown(() => db.close());

 test('add persiste e getAll reconstrói o cliente com contatos', () async {
 final dataSource = CustomerSqliteDataSourceImpl(db);

 await dataSource.add(
 const Customer(
 id: 'c1',
 name: 'João',
 phone: '(11) 99999-0000',
 email: 'joao@email.com',
 ),
 );
 await dataSource.add(
 const Customer(id: 'c2', name: 'Ana'),
 );

 final customers = await dataSource.getAll(storeId: 'st1');

 expect(customers, hasLength(2));
 // Ordenação por nome (case-insensitive).
 expect(customers.first.name, 'Ana');
 expect(customers.last.name, 'João');
 expect(customers.last.phone, '(11) 99999-0000');
 expect(customers.last.email, 'joao@email.com');
 expect(customers.first.phone, isEmpty);
 });
}
