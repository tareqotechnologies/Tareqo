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
    });

    test('categorias', () {
      expect(TransactionDescriptions.saleCategory('pt'), 'Vendas');
      expect(TransactionDescriptions.saleCategory('en'), 'Sales');
      expect(TransactionDescriptions.debtCategory('pt'), 'Fiado');
      expect(TransactionDescriptions.debtCategory('en'), 'Credit');
      expect(TransactionDescriptions.purchaseCategory('pt'), 'Compras');
      expect(TransactionDescriptions.purchaseCategory('en'), 'Purchases');
    });
  });
}
