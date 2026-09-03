import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;

void main() {
 final purchase = Purchase(
 id: 'COMPRA-001',
 number: 42,
 storeId: 'st2',
 supplierName: 'Distribuidora Central',
 items: const [
 PurchaseItem(
 productId: '1',
 productName: 'Caneta',
 quantity: 5,
 unitPriceCents: 100,
 ),
 PurchaseItem(
 productId: '2',
 productName: 'Caderno',
 quantity: 2,
 unitPriceCents: 500,
 ),
 ],
 totalAmountCents: 1500,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime.utc(2026, 8, 4, 10, 30),
 );

 test('toJson/fromJson preserva todos os campos (round-trip)', () {
 final restored = Purchase.fromJson(purchase.toJson());

 expect(restored, purchase);
 expect(restored.supplierName, 'Distribuidora Central');
 expect(restored.storeId, 'st2');
 expect(restored.dateTime, DateTime.utc(2026, 8, 4, 10, 30));
 expect(restored.items, hasLength(2));
 expect(restored.items.first.productName, 'Caneta');
 expect(restored.items.first.unitPriceCents, 100);
 // Número SEQUENCIAL da compra na loja sobrevive ao round-trip.
 expect(restored.number, 42);
 expect(purchase.toJson()['number'], 42);
 // Forma de pagamento sobrevive ao round-trip (serializada pelo NOME).
 expect(restored.paymentMethod, PaymentMethod.mPesa);
 expect(purchase.toJson()['paymentMethod'], 'mPesa');
 });

 test('default do number é 0 (nunca persistido — o banco atribui)', () {
 final semNumero = Purchase(
 id: 'COMPRA-002',
 supplierName: 'Fornecedor B',
 items: const [
 PurchaseItem(
 productId: '1',
 productName: 'Caneta',
 quantity: 1,
 unitPriceCents: 100,
 ),
 ],
 totalAmountCents: 100,
 dateTime: DateTime.utc(2026, 8, 1),
 );

 expect(semNumero.number, 0);
 });

 test('default da forma de pagamento é cash (compras antigas à vista)', () {
 expect(purchase.paymentMethod, PaymentMethod.mPesa);

 // Sem o campo (JSON antigo / compra legada), cai em cash.
 final legada = Purchase.fromJson({
 'id': 'COMPRA-003',
 'supplierName': 'Fornecedor C',
 'items': const [],
 'totalAmountCents': 100,
 'dateTime': '2026-08-01T00:00:00.000Z',
 });
 expect(legada.paymentMethod, PaymentMethod.cash);
 });

 test('PurchaseItem guarda o preço unitário do momento da compra', () {
 final item = purchase.items.first;

 // O item preserva o custo na data da compra — mesmo que o preço atual
 // do catálogo mude depois, o histórico não é afetado.
 expect(item.unitPriceCents, 100);
 expect(item.productId, '1');
 });
}
