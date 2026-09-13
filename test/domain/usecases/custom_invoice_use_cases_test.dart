import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/custom_invoice.dart';
import 'package:tareqo/domain/usecases/custom_invoice_use_cases.dart';

/// Regras de negócio das facturas personalizadas: validações de entrada,
/// cálculo de subtotais/desconto/imposto em centavos (inteiro — sem
/// truncamento de double) e formatação do preview textual (incluindo
/// quantidade em milésimos para granel).
void main() {
  final create = const CreateCustomInvoiceUseCase();
  final preview = const GenerateInvoicePreviewUseCase();

  CustomInvoiceItemInput item(
    String name,
    int quantity,
    int unitPriceCents, {
    String unit = 'un',
  }) => CustomInvoiceItemInput(
    productName: name,
    quantity: quantity,
    unitPriceCents: unitPriceCents,
    unit: unit,
  );

  group('CreateCustomInvoiceUseCase — validações', () {
    test('deve rejeitar factura sem itens', () {
      expect(
        () => create(storeId: 'st1', clientName: 'Ana', items: const []),
        throwsArgumentError,
      );
    });

    test('deve rejeitar nome do cliente vazio e só com espaços', () {
      expect(
        () => create(
          storeId: 'st1',
          clientName: '   ',
          items: [item('Arroz', 1, 500)],
        ),
        throwsArgumentError,
      );
      expect(
        () => create(
          storeId: 'st1',
          clientName: '',
          items: [item('Arroz', 1, 500)],
        ),
        throwsArgumentError,
      );
    });

    test('deve rejeitar desconto e imposto negativos', () {
      final items = [item('Arroz', 1, 500)];
      expect(
        () => create(
          storeId: 'st1',
          clientName: 'Ana',
          items: items,
          discountCents: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => create(
          storeId: 'st1',
          clientName: 'Ana',
          items: items,
          taxCents: -1,
        ),
        throwsArgumentError,
      );
    });

    test(
      'deve rejeitar item sem nome, com quantidade <= 0 ou preço negativo',
      () {
        // Nome vazio.
        expect(
          () => create(
            storeId: 'st1',
            clientName: 'Ana',
            items: [item('  ', 1, 500)],
          ),
          throwsArgumentError,
        );
        // Quantidade zero e negativa.
        expect(
          () => create(
            storeId: 'st1',
            clientName: 'Ana',
            items: [item('Arroz', 0, 500)],
          ),
          throwsArgumentError,
        );
        expect(
          () => create(
            storeId: 'st1',
            clientName: 'Ana',
            items: [item('Arroz', -2, 500)],
          ),
          throwsArgumentError,
        );
        // Preço unitário negativo.
        expect(
          () => create(
            storeId: 'st1',
            clientName: 'Ana',
            items: [item('Arroz', 1, -1)],
          ),
          throwsArgumentError,
        );
      },
    );

    test('deve aceitar preço unitário zero (brinde/amostra)', () {
      final invoice = create(
        storeId: 'st1',
        clientName: 'Ana',
        items: [item('Amostra', 1000, 0)],
      );
      expect(invoice.totalAmountCents, 0);
    });
  });

  group('CreateCustomInvoiceUseCase — cálculo', () {
    test('deve calcular subtotais e total com múltiplos itens', () {
      // Quantidade em MILÉSIMOS: subtotal = quantidade × preço unitário.
      final invoice = create(
        storeId: 'st1',
        clientName: 'Ana',
        items: [
          item('Arroz', 2000, 500), // 2.000 × 5,00 = 10.000,00
          item('Sal', 1000, 150), // 1.000 × 1,50 = 1.500,00
        ],
      );

      expect(invoice.items.first.subtotalCents, 1000000);
      expect(invoice.items.last.subtotalCents, 150000);
      expect(invoice.totalAmountCents, 1150000);
      // id vazio: atribuído pelo banco.
      expect(invoice.id, '');
    });

    test('deve aplicar desconto e imposto e nunca ficar negativo', () {
      final withAdjustments = create(
        storeId: 'st1',
        clientName: 'Ana',
        items: [item('A', 1000, 1000)], // 1.000 × 10,00 = 10.000,00
        discountCents: 30000, // -300,00
        taxCents: 10000, // +100,00
      );
      expect(withAdjustments.totalAmountCents, 980000);

      // Desconto maior que o total → satura em 0 (sem total negativo).
      final saturated = create(
        storeId: 'st1',
        clientName: 'Ana',
        items: [item('A', 1000, 100)],
        discountCents: 500000,
      );
      expect(saturated.totalAmountCents, 0);
    });

    test('deve preservar unidade e dados opcionais do cliente', () {
      final invoice = create(
        storeId: 'st1',
        clientName: '  Ana Maria  ',
        clientPhone: '+258841111111',
        clientEmail: 'ana@test.local',
        clientAddress: 'Av. 24 de Julho, 100',
        clientTaxId: '4001234567',
        items: [item('Milho', 3500, 3000, unit: 'kg')],
        notes: 'Entrega sexta-feira',
        paymentMethod: 'M-Pesa',
      );

      expect(invoice.items.first.unit, 'kg');
      expect(invoice.clientPhone, '+258841111111');
      expect(invoice.clientTaxId, '4001234567');
      expect(invoice.notes, 'Entrega sexta-feira');
      expect(invoice.paymentMethod, 'M-Pesa');
    });

    test('deve aceitar valores muito grandes sem estourar para double', () {
      // 999.999 milésimos × 999.999,99 — em centavos inteiros.
      final invoice = create(
        storeId: 'st1',
        clientName: 'Ana',
        items: [item('Container', 999999, 99999999)],
      );
      expect(invoice.items.first.subtotalCents, 999999 * 99999999);
    });
  });

  group('GenerateInvoicePreviewUseCase — formatação', () {
    CustomInvoice invoice({
      List<CustomInvoiceItem> items = const [],
      int discountCents = 0,
      int taxCents = 0,
      String notes = '',
      String clientPhone = '',
      String clientTaxId = '',
    }) => CustomInvoice(
      id: 'inv1',
      number: 42,
      storeId: 'st1',
      clientName: 'Ana',
      items: items,
      totalAmountCents: 0,
      discountCents: discountCents,
      taxCents: taxCents,
      notes: notes,
      createdAt: DateTime(2026, 9, 11),
      clientPhone: clientPhone,
      clientTaxId: clientTaxId,
    );

    test('deve incluir cabeçalho, número, data e total formatados', () {
      final text = preview(
        invoice(
          items: [
            const CustomInvoiceItem(
              productName: 'Arroz',
              quantity: 2000,
              unitPriceCents: 500,
              subtotalCents: 1000,
            ),
          ],
        ),
      );

      expect(text, contains('FACTURA'));
      expect(text, contains('Nº: 42'));
      expect(text, contains('Data: 11/09/2026'));
      expect(text, contains('CLIENTE:'));
      expect(text, contains('Ana'));
      expect(text, contains('Arroz'));
      expect(text, contains('5.00 MT'));
      expect(text, contains('Subtotal: 10.00 MT'));
      expect(text, contains('TOTAL:'));
    });

    test('quantidade em milésimos: inteiro e fracionária (granel)', () {
      final text = preview(
        invoice(
          items: [
            const CustomInvoiceItem(
              productName: 'Sal',
              quantity: 3000,
              unitPriceCents: 150,
              subtotalCents: 450,
            ),
            const CustomInvoiceItem(
              productName: 'Milho',
              quantity: 1500,
              unitPriceCents: 3000,
              subtotalCents: 4500,
            ),
          ],
        ),
      );
      // 3000 milésimos → "3"; 1500 → "1.5".
      expect(text, contains('Sal  3 x 1.50 MT'));
      expect(text, contains('Milho  1.5 x 30.00 MT'));
      // Subtotais em centavos: 450 → 4,50; 4500 → 45,00.
      expect(text, contains('Subtotal: 4.50 MT'));
      expect(text, contains('Subtotal: 45.00 MT'));
    });

    test('só imprime desconto/IVA/telefone/NIF/notas quando não vazios', () {
      final text = preview(invoice(items: const []));
      expect(text, isNot(contains('Desconto')));
      expect(text, isNot(contains('IVA')));
      expect(text, isNot(contains('Tel:')));
      expect(text, isNot(contains('NIF:')));

      final complete = preview(
        invoice(
          items: const [],
          discountCents: 100,
          taxCents: 50,
          notes: 'Obrigado pela preferência',
          clientPhone: '+258841111111',
          clientTaxId: '4001234567',
        ),
      );
      expect(complete, contains('Desconto:  -1.00 MT'));
      expect(complete, contains('IVA:       +0.50 MT'));
      expect(complete, contains('Tel: +258841111111'));
      expect(complete, contains('NIF: 4001234567'));
      expect(complete, contains('Obrigado pela preferência'));
    });
  });
}
