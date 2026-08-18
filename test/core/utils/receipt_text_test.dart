import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/utils/formatters.dart';
import 'package:dumbhanengue/core/utils/receipt_text.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';

void main() {
 final sale = Sale(
 id: 's1',
 number: 1,
 items: const [
 SaleItem(
 productId: 'p1',
 productName: 'Caneta',
 quantity: 2000, // 2 unidades em MILÉSIMOS (W11)
 unitPriceCents: 200,
 ),
 SaleItem(
 productId: 'p2',
 productName: 'Caderno',
 quantity: 1000,
 unitPriceCents: 990,
 ),
 ],
 totalAmountCents: 1390,
 paymentMethod: PaymentMethod.mPesa,
 dateTime: DateTime(2026, 8, 3, 14, 30),
 );

 setUp(() {
 // Moeda/idioma padrão dos testes (pt-BR, R$).
 Formatters.applySettings(currencyCode: 'BRL', language: 'pt');
 });

 group('ReceiptText.build (pt)', () {
 test('inclui cabeçalho, título, itens, total, pagamento e rodapé', () {
 final text = ReceiptText.build(
 sale: sale,
 storeName: 'Loja Centro',
 storeAddress: 'Av. Central, 123',
 language: 'pt',
 );

 expect(text, contains('LOJA CENTRO'));
 expect(text, contains('Av. Central, 123'));
 expect(text, contains('RECIBO DE VENDA'));
 expect(text, contains('Venda S-00001'));
 expect(text, contains('03/08/2026 14:30'));
 expect(text, contains('Caneta'));
 expect(text, contains(' 2 × R\$ 2,00 = R\$ 4,00'));
 expect(text, contains('Caderno'));
 expect(text, contains(' 1 × R\$ 9,90 = R\$ 9,90'));
 expect(text, contains('Total: R\$ 13,90'));
 expect(text, contains('Pagamento: M-Pesa'));
 expect(text, contains('Obrigado pela preferência!'));
 });

 test('sem loja o recibo começa direto no título', () {
 final text = ReceiptText.build(
 sale: sale,
 language: 'pt',
 );

 expect(text, startsWith('RECIBO DE VENDA'));
 expect(text, isNot(contains('LOJA CENTRO')));
 });

 test('venda anulada ganha a marca (ANULADA)', () {
 final cancelled = sale.copyWith(status: SaleStatus.cancelled);
 final text = ReceiptText.build(sale: cancelled, language: 'pt');

 expect(text, contains('(ANULADA)'));
 });

 test('pagamento em dinheiro é localizado no idioma ativo', () {
 final cash = sale.copyWith(paymentMethod: PaymentMethod.cash);
 final text = ReceiptText.build(sale: cash, language: 'pt');

 expect(text, contains('Pagamento: Dinheiro'));
 });
 });

 group('ReceiptText.build (en)', () {
 test('usa os rótulos em inglês', () {
 final text = ReceiptText.build(
 sale: sale,
 storeName: 'Loja Centro',
 language: 'en',
 );

 expect(text, contains('LOJA CENTRO'));
 expect(text, contains('SALE RECEIPT'));
 expect(text, contains('Sale S-00001'));
 expect(text, contains('Total: R\$ 13,90'));
 expect(text, contains('Payment: M-Pesa'));
 expect(text, contains('Thank you for your purchase!'));
 });

 test('venda anulada ganha a marca (CANCELLED)', () {
 final cancelled = sale.copyWith(status: SaleStatus.cancelled);
 final text = ReceiptText.build(sale: cancelled, language: 'en');

 expect(text, contains('(CANCELLED)'));
 });
 });
}
