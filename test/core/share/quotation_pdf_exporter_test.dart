import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/share/quotation_pdf_exporter.dart';
import 'package:tareqo/domain/entities/quotation.dart';

QuotationPdfLabels _labels() => QuotationPdfLabels(
  docWord: 'COTAÇÃO',
  numberLabelTemplate: 'Nº {number}',
  clientHeading: 'CLIENTE',
  phoneLabelTemplate: 'Tel: {value}',
  taxIdLabelTemplate: 'NIF: {value}',
  itemHeader: 'Item',
  qtyHeader: 'Qtd',
  unitPriceHeader: 'Preço',
  subtotalHeader: 'Subtotal',
  discountLabel: 'Desconto',
  totalLabel: 'TOTAL',
  validityHeading: 'Validade',
  notesHeading: 'Notas',
  generalConditionsHeading: 'Condições Gerais',
  validConditionTemplate: 'Esta cotação é válida até {date}.',
  pricesConditionText: 'Preços em meticais.',
  contactConditionText: 'Contacte-nos para esclarecimentos.',
  footerTemplate: 'Gerado em {date} pelo TAREQO',
  fileNameBase: 'cotacao',
  subjectWord: 'Cotação',
  statusText: (_) => 'Rascunho',
  daysLeftText: (days) => days >= 0 ? '$days dias' : 'Expirada',
);

Quotation _quotation() => Quotation(
  id: 'qt1',
  storeId: 'st1',
  customerId: 'c1',
  customerName: 'João da Silva',
  customerPhone: '84 123 4567',
  items: const [
    QuotationItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 2000,
      unitPriceCents: 200,
    ),
    QuotationItem(
      productId: 'p2',
      productName: 'Caderno',
      quantity: 1000,
      unitPriceCents: 990,
    ),
  ],
  totalAmountCents: 1390,
  status: QuotationStatus.draft,
  validUntil: DateTime(2026, 8, 10),
  createdAt: DateTime(2026, 8, 3, 14, 30),
);

void main() {
  // O buildPdf embute a fonte Inter via rootBundle (asset do pubspec).
  TestWidgetsFlutterBinding.ensureInitialized();

  const exporter = QuotationPdfExporter();

  group('QuotationPdfExporter.buildPdf', () {
    test(
      'gera bytes de PDF válidos (%PDF + %%EOF) com os dados da cotação',
      () async {
        final bytes = await exporter.buildPdf(
          _quotation(),
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

    test('gera PDF para estado aceite (statusText é resolvido)', () async {
      final bytes = await exporter.buildPdf(
        _quotation().copyWith(status: QuotationStatus.accepted),
        labels: _labels(),
        businessName: 'Loja',
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(500));
    });
  });
}
