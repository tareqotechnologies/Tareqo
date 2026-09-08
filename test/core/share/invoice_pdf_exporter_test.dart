import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/share/invoice_pdf_exporter.dart';
import 'package:tareqo/domain/entities/custom_invoice.dart';

InvoicePdfLabels _labels() => const InvoicePdfLabels(
  docWord: 'FACTURA',
  numberLabelTemplate: 'Nº {number}',
  clientHeading: 'CLIENTE',
  phoneLabelTemplate: 'Tel: {value}',
  emailLabelTemplate: 'Email: {value}',
  taxIdLabelTemplate: 'NIF: {value}',
  itemHeader: 'Item',
  qtyHeader: 'Qtd',
  unitPriceHeader: 'Preço',
  subtotalHeader: 'Subtotal',
  discountLabel: 'Desconto',
  taxLabel: 'Imposto',
  totalLabel: 'TOTAL',
  paymentLabelTemplate: 'Pagamento: {value}',
  referenceLabelTemplate: 'Ref: {value}',
  notesHeading: 'Notas',
  footerTemplate: 'Gerado em {date} pelo TAREQO',
  fileNameBase: 'factura',
  subjectWord: 'Factura',
);

CustomInvoice _invoice() => CustomInvoice(
  id: 'ci1',
  storeId: 'st1',
  clientName: 'João da Silva',
  clientPhone: '84 123 4567',
  clientTaxId: '123456789',
  items: const [
    CustomInvoiceItem(
      productName: 'Caneta',
      quantity: 2,
      unitPriceCents: 200,
      subtotalCents: 400,
    ),
    CustomInvoiceItem(
      productName: 'Caderno',
      quantity: 1,
      unitPriceCents: 990,
      subtotalCents: 990,
    ),
  ],
  totalAmountCents: 1390,
  discountCents: 0,
  taxCents: 0,
  createdAt: DateTime(2026, 8, 3, 14, 30),
);

void main() {
  // O buildPdf embute a fonte Inter via rootBundle (asset do pubspec).
  TestWidgetsFlutterBinding.ensureInitialized();

  const exporter = InvoicePdfExporter();

  group('InvoicePdfExporter.buildPdf', () {
    test(
      'gera bytes de PDF válidos (%PDF + %%EOF) com os dados da factura',
      () async {
        final bytes = await exporter.buildPdf(
          _invoice(),
          labels: _labels(),
          businessName: 'Mercado Central',
          businessAddress: 'Av. 24 de Julho, 100',
          businessPhone: '84 000 0000',
          businessTaxId: '400123456',
        );

        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        final text = String.fromCharCodes(bytes);
        expect(text.trimRight().endsWith('%%EOF'), isTrue);
        expect(text.length, greaterThan(1000));
      },
    );

    test('gera PDF mesmo sem dados opcionais do negócio', () async {
      final bytes = await exporter.buildPdf(
        _invoice(),
        labels: _labels(),
        businessName: 'Loja',
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(500));
    });
  });
}
