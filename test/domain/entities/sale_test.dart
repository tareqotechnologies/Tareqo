import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';

void main() {
 final sale = Sale(
 id: 'VENDA-001',
 number: 42,
 items: const [
 SaleItem(
 productId: '1',
 productName: 'Caneta',
 quantity: 2,
 unitPriceCents: 200,
 ),
 SaleItem(
 productId: '2',
 productName: 'Caderno',
 quantity: 1,
 unitPriceCents: 990,
 ),
 ],
 totalAmountCents: 1390,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime.utc(2026, 8, 3, 14, 30),
 );

 test('toJson/fromJson preserva todos os campos (round-trip)', () {
 final restored = Sale.fromJson(sale.toJson());

 expect(restored, sale);
 expect(restored.paymentMethod, PaymentMethod.mPesa);
 expect(restored.dateTime, DateTime.utc(2026, 8, 3, 14, 30));
 expect(restored.items, hasLength(2));
 expect(restored.items.first.productName, 'Caneta');
 expect(restored.items.first.unitPriceCents, 200);
 // Número SEQUENCIAL da venda na loja sobrevive ao round-trip.
 expect(restored.number, 42);
 expect(sale.toJson()['number'], 42);
 });

 test('PaymentMethod é serializado pelo nome do enum', () {
 expect(sale.toJson()['paymentMethod'], 'mPesa');

 // Mapa completo (com base no JSON da venda) trocando apenas o método.
 final json = sale.toJson();
 final restored = Sale.fromJson({...json, 'paymentMethod': 'creditCard'});
 expect(restored.paymentMethod, PaymentMethod.creditCard);
 });

 test('SaleItem guarda o preço unitário do momento da venda', () {
 final item = sale.items.first;

 // O item preserva o valor cobrado na data da venda — mesmo que o
 // preço atual do catálogo mude depois, o histórico não é afetado.
 expect(item.unitPriceCents, 200);
 expect(item.productId, '1');
 });
}
