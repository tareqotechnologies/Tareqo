import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';

void main() {
  final sale = Sale(
    id: 'VENDA-001',
    items: const [
      SaleItem(
        productId: '1',
        productName: 'Caneta',
        quantity: 2,
        unitPrice: 2.0,
      ),
      SaleItem(
        productId: '2',
        productName: 'Caderno',
        quantity: 1,
        unitPrice: 9.9,
      ),
    ],
    totalAmount: 13.9,
    paymentMethod: PaymentMethod.pix,
    dateTime: DateTime.utc(2026, 8, 3, 14, 30),
  );

  test('toJson/fromJson preserva todos os campos (round-trip)', () {
    final restored = Sale.fromJson(sale.toJson());

    expect(restored, sale);
    expect(restored.paymentMethod, PaymentMethod.pix);
    expect(restored.dateTime, DateTime.utc(2026, 8, 3, 14, 30));
    expect(restored.items, hasLength(2));
    expect(restored.items.first.productName, 'Caneta');
    expect(restored.items.first.unitPrice, 2.0);
  });

  test('PaymentMethod é serializado pelo nome do enum', () {
    expect(sale.toJson()['paymentMethod'], 'pix');

    // Mapa completo (com base no JSON da venda) trocando apenas o método.
    final json = sale.toJson();
    final restored = Sale.fromJson({...json, 'paymentMethod': 'creditCard'});
    expect(restored.paymentMethod, PaymentMethod.creditCard);
  });

  test('SaleItem guarda o preço unitário do momento da venda', () {
    final item = sale.items.first;

    // O item preserva o valor cobrado na data da venda — mesmo que o
    // preço atual do catálogo mude depois, o histórico não é afetado.
    expect(item.unitPrice, 2.0);
    expect(item.productId, '1');
  });
}
