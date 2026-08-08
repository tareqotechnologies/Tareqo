import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/data/datasources/local/sale_local_data_source_impl.dart';
import 'package:dumbhanengue/data/repositories/sale_repository_impl.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';

void main() {
  test('registerSale persiste e getAll retorna a venda', () async {
    final repository = SaleRepositoryImpl(SaleLocalDataSourceImpl());

    await repository.registerSale(
      Sale(
        id: 's1',
        items: const [
          SaleItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 2,
            unitPriceCents: 200,
          ),
        ],
        totalAmountCents: 400,
        paymentMethod: PaymentMethod.mPesa,
        dateTime: DateTime(2026, 8, 3),
      ),
    );

    final sales = await repository.getAll(storeId: 'st1');

    expect(sales, hasLength(1));
    expect(sales.first.id, 's1');
    expect(sales.first.totalAmountCents, 400);
  });
}
