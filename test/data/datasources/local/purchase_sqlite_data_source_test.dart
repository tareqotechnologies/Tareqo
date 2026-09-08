import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/purchase_sqlite_data_source_impl.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;

import '../../../helpers/test_sqlite.dart';

Purchase _buildPurchase(String id, String supplierName) => Purchase(
  id: id,
  supplierName: supplierName,
  items: const [
    PurchaseItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 1,
      unitPriceCents: 100,
    ),
  ],
  totalAmountCents: 100,
  dateTime: DateTime(2026, 8, 4),
);

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

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
            unitPriceCents: 100,
          ),
          PurchaseItem(
            productId: 'p2',
            productName: 'Caderno',
            quantity: 2,
            unitPriceCents: 500,
          ),
        ],
        totalAmountCents: 1500,
        paymentMethod: PaymentMethod.mPesa,
        dateTime: DateTime(2026, 8, 4, 10, 30),
      ),
    );

    final purchases = await dataSource.getAll(storeId: 'st1');

    expect(purchases, hasLength(1));
    final purchase = purchases.first;
    expect(purchase.supplierName, 'Distribuidora');
    expect(purchase.totalAmountCents, 1500);
    expect(purchase.dateTime, DateTime(2026, 8, 4, 10, 30));
    expect(purchase.items, hasLength(2));
    expect(purchase.items.first.productName, 'Caneta');
    expect(purchase.items.first.quantity, 5);
    expect(purchase.items.last.unitPriceCents, 500);
    // Número SEQUENCIAL atribuído pelo banco (primeira compra da loja = 1).
    expect(purchase.number, 1);
    // Forma de pagamento persistida pelo NOME do enum e reconstruída.
    expect(purchase.paymentMethod, PaymentMethod.mPesa);
  });

  test('add sem paymentMethod persiste cash (default da entidade)', () async {
    final dataSource = PurchaseSqliteDataSourceImpl(db);

    await dataSource.add(_buildPurchase('pc-default', 'Fornecedor D'));

    final purchases = await dataSource.getAll(storeId: 'st1');
    expect(purchases.first.paymentMethod, PaymentMethod.cash);
  });

  test(
    'add atribui número SEQUENCIAL por loja (MAX+1) e ignora o do objeto',
    () async {
      final dataSource = PurchaseSqliteDataSourceImpl(db);

      await dataSource.add(_buildPurchase('pc1', 'Fornecedor A'));
      // Mesmo que o objeto traga number: 999, o banco atribui o próximo.
      await dataSource.add(
        _buildPurchase('pc2', 'Fornecedor B').copyWith(number: 999),
      );
      await dataSource.add(_buildPurchase('pc3', 'Fornecedor C'));

      final purchases = await dataSource.getAll(storeId: 'st1');
      expect(purchases, hasLength(3));
      expect(purchases.map((p) => p.number).toSet(), {1, 2, 3});
    },
  );

  test('numeração é independente por loja (cada loja começa em 1)', () async {
    final dataSource = PurchaseSqliteDataSourceImpl(db);

    await dataSource.add(_buildPurchase('pc1', 'Fornecedor A'));
    await dataSource.add(
      _buildPurchase('pc2', 'Fornecedor B').copyWith(storeId: 'st2'),
    );

    expect((await dataSource.getAll(storeId: 'st1')).first.number, 1);
    expect((await dataSource.getAll(storeId: 'st2')).first.number, 1);
  });

  test('add persiste múltiplas compras e ordena por data desc', () async {
    final dataSource = PurchaseSqliteDataSourceImpl(db);

    await dataSource.add(_buildPurchase('pc1', 'Fornecedor A'));
    await dataSource.add(
      _buildPurchase(
        'pc2',
        'Fornecedor B',
      ).copyWith(dateTime: DateTime(2026, 8, 1)),
    );

    final purchases = await dataSource.getAll(storeId: 'st1');

    expect(purchases, hasLength(2));
    expect(purchases.first.supplierName, 'Fornecedor A');
    expect(purchases.last.supplierName, 'Fornecedor B');
  });
}
