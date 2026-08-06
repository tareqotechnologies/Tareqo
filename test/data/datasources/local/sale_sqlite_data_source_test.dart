import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/sale_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';

import '../../../helpers/test_sqlite.dart';

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Sale buildSale(String id) => Sale(
        id: id,
        items: const [
          SaleItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 2,
            unitPriceCents: 200,
          ),
          SaleItem(
            productId: 'p2',
            productName: 'Caderno',
            quantity: 1,
            unitPriceCents: 990,
          ),
        ],
        totalAmountCents: 1390,
        paymentMethod: PaymentMethod.pix,
        dateTime: DateTime(2026, 8, 3, 14, 30),
      );

  test('add grava venda + itens e getAll reconstrói a venda completa',
      () async {
    final dataSource = SaleSqliteDataSourceImpl(db);

    await dataSource.add(buildSale('s1'));

    final sales = await dataSource.getAll(storeId: 'st1');

    expect(sales, hasLength(1));
    final sale = sales.first;
    expect(sale.id, 's1');
    expect(sale.paymentMethod, PaymentMethod.pix);
    expect(sale.totalAmountCents, 1390);
    expect(sale.dateTime, DateTime(2026, 8, 3, 14, 30));
    expect(sale.items, hasLength(2));
    expect(sale.items.first.productName, 'Caneta');
    expect(sale.items.last.quantity, 1);
  });

  test('getAll retorna da venda mais recente para a mais antiga', () async {
    final dataSource = SaleSqliteDataSourceImpl(db);

    await dataSource.add(buildSale('s1'));
    await dataSource.add(
      buildSale('s2').copyWith(dateTime: DateTime(2026, 8, 1)),
    );

    final sales = await dataSource.getAll(storeId: 'st1');

    expect(sales.map((s) => s.id).toList(), ['s1', 's2']);
  });
}

