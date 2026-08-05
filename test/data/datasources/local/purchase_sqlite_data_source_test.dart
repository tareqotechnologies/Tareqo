import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/purchase_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/purchase.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.dispose());

  test('add persiste compra + itens e getAll reconstrói', () async {
    final dataSource = PurchaseSqliteDataSourceImpl(db);

    await dataSource.add(
      Purchase(
        id: 'pc1',
        supplierName: 'Distribuidora',
        items: const [
          PurchaseItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 5,
            unitPrice: 1.0,
          ),
          PurchaseItem(
            productId: 'p2',
            productName: 'Caderno',
            quantity: 2,
            unitPrice: 5.0,
          ),
        ],
        totalAmount: 15.0,
        dateTime: DateTime(2026, 8, 4, 10, 30),
      ),
    );

    final purchases = await dataSource.getAll(storeId: 'st1');

    expect(purchases, hasLength(1));
    final purchase = purchases.first;
    expect(purchase.supplierName, 'Distribuidora');
    expect(purchase.totalAmount, 15.0);
    expect(purchase.dateTime, DateTime(2026, 8, 4, 10, 30));
    expect(purchase.items, hasLength(2));
    expect(purchase.items.first.productName, 'Caneta');
    expect(purchase.items.first.quantity, 5);
    expect(purchase.items.last.unitPrice, 5.0);
  });

  test('add persiste múltiplas compras e ordena por data desc', () async {
    final dataSource = PurchaseSqliteDataSourceImpl(db);

    await dataSource.add(
      Purchase(
        id: 'pc1',
        supplierName: 'Fornecedor A',
        items: const [
          PurchaseItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 1,
            unitPrice: 1.0,
          ),
        ],
        totalAmount: 1.0,
        dateTime: DateTime(2026, 8, 4),
      ),
    );
    await dataSource.add(
      Purchase(
        id: 'pc2',
        supplierName: 'Fornecedor B',
        items: const [
          PurchaseItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 1,
            unitPrice: 1.0,
          ),
        ],
        totalAmount: 1.0,
        dateTime: DateTime(2026, 8, 1),
      ),
    );

    final purchases = await dataSource.getAll(storeId: 'st1');

    expect(purchases, hasLength(2));
    expect(purchases.first.supplierName, 'Fornecedor A');
    expect(purchases.last.supplierName, 'Fornecedor B');
  });
}
