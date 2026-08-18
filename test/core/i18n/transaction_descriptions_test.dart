import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/i18n/transaction_descriptions.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';

void main() {
 group('TransactionDescriptions (pt/en na gravação)', () {
 test('venda', () {
 expect(
 TransactionDescriptions.sale(
 language: 'pt',
 paymentMethod: PaymentMethod.cash,
 ),
 'Venda Dinheiro',
 );
 expect(
 TransactionDescriptions.sale(
 language: 'en',
 paymentMethod: PaymentMethod.debitCard,
 ),
 'Sale — Debit card',
 );
 expect(
 TransactionDescriptions.sale(
 language: 'fr',
 paymentMethod: PaymentMethod.cash,
 ),
 'Vente — Espèces',
 );
 expect(
 TransactionDescriptions.saleReversal(
 language: 'fr',
 paymentMethod: PaymentMethod.transfer,
 ),
 'Annulation de vente — Virement',
 );
 });

 test('nome da forma de pagamento', () {
 expect(
 TransactionDescriptions.paymentMethodName(
 'pt', PaymentMethod.mPesa),
 'M-Pesa');
 expect(
 TransactionDescriptions.paymentMethodName(
 'en', PaymentMethod.creditCard),
 'Credit card');
 expect(
 TransactionDescriptions.paymentMethodName(
 'pt', PaymentMethod.transfer),
 'Transferência');
 expect(
 TransactionDescriptions.paymentMethodName(
 'en', PaymentMethod.transfer),
 'Bank transfer');
 expect(
 TransactionDescriptions.paymentMethodName(
 'fr', PaymentMethod.cash),
 'Espèces');
 expect(
 TransactionDescriptions.paymentMethodName(
 'fr', PaymentMethod.debitCard),
 'Carte de débit');
 expect(
 TransactionDescriptions.paymentMethodName(
 'fr', PaymentMethod.transfer),
 'Virement');
 });

 test('fiado (a receber / a pagar)', () {
 expect(
 TransactionDescriptions.debt(
 language: 'pt',
 isCustomerDebt: true,
 personName: 'João',
 ),
 'Fiado a receber — João',
 );
 expect(
 TransactionDescriptions.debt(
 language: 'pt',
 isCustomerDebt: false,
 personName: 'Fornecedor X',
 ),
 'Fiado a pagar — Fornecedor X',
 );
 expect(
 TransactionDescriptions.debt(
 language: 'en',
 isCustomerDebt: true,
 personName: 'João',
 ),
 'Credit to receive — João',
 );
 expect(
 TransactionDescriptions.debt(
 language: 'en',
 isCustomerDebt: false,
 personName: 'Supplier X',
 ),
 'Credit to pay — Supplier X',
 );
 expect(
 TransactionDescriptions.debt(
 language: 'fr',
 isCustomerDebt: true,
 personName: 'João',
 ),
 'Crédit à recevoir — João',
 );
 expect(
 TransactionDescriptions.debt(
 language: 'fr',
 isCustomerDebt: false,
 personName: 'Fournisseur X',
 ),
 'Crédit à payer — Fournisseur X',
 );
 });

 test('quitação de fiado', () {
 expect(
 TransactionDescriptions.settleDebt(language: 'pt', personName: 'João'),
 'Recebimento de fiado — João',
 );
 expect(
 TransactionDescriptions.settleDebt(language: 'en', personName: 'João'),
 'Credit received — João',
 );
 expect(
 TransactionDescriptions.settleDebt(language: 'fr', personName: 'João'),
 'Crédit reçu — João',
 );
 });

 test('compra', () {
 expect(
 TransactionDescriptions.purchase(
 language: 'pt', supplierName: 'ACME'),
 'Compra — ACME',
 );
 expect(
 TransactionDescriptions.purchase(
 language: 'en', supplierName: 'ACME'),
 'Purchase — ACME',
 );
 expect(
 TransactionDescriptions.purchase(
 language: 'fr', supplierName: 'ACME'),
 'Achat — ACME',
 );
 });

 test('categorias', () {
 expect(TransactionDescriptions.saleCategory('pt'), 'Vendas');
 expect(TransactionDescriptions.saleCategory('en'), 'Sales');
 expect(TransactionDescriptions.saleCategory('fr'), 'Ventes');
 expect(TransactionDescriptions.debtCategory('pt'), 'Fiado');
 expect(TransactionDescriptions.debtCategory('en'), 'Credit');
 expect(TransactionDescriptions.debtCategory('fr'), 'Crédit');
 expect(TransactionDescriptions.purchaseCategory('pt'), 'Compras');
 expect(TransactionDescriptions.purchaseCategory('en'), 'Purchases');
 expect(TransactionDescriptions.purchaseCategory('fr'), 'Achats');
 });
 });
}
