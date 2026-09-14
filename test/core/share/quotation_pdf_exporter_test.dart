import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

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

/// Fake do [PathProviderPlatform] — diretório temporário REAL para o
/// caminho de partilha (o PDF é gravado em disco antes do share sheet).
class _FakePathProvider extends PathProviderPlatform {
  late Directory tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

void main() {
  // O buildPdf embute a fonte Inter via rootBundle (asset do pubspec).
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;

  setUp(() async {
    fakePP.tempDir = await Directory.systemTemp.createTemp('tareqo_quote');
    PathProviderPlatform.instance = fakePP;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(shareChannel, null);
    PathProviderPlatform.instance = originalPP;
    await fakePP.tempDir.delete(recursive: true);
  });

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

    test('logotipo embutido não quebra o documento', () async {
      final logo = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
        'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      );

      final bytes = await exporter.buildPdf(
        _quotation(),
        labels: _labels(),
        businessName: 'Com Logo',
        logoBytes: logo,
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      final without = await exporter.buildPdf(
        _quotation(),
        labels: _labels(),
        businessName: 'Com Logo',
      );
      expect(bytes.length, greaterThan(without.length));
    });

    test('item fracionário, desconto, notas e validade renderizam', () async {
      final bytes = await exporter.buildPdf(
        _quotation().copyWith(
          items: const [
            QuotationItem(
              productId: 'p3',
              productName: 'Arroz a granel',
              quantity: 1500,
              unitPriceCents: 850,
            ),
          ],
          totalAmountCents: 12750,
          discountCents: 500,
          notes: 'Válido para retirada na loja.',
        ),
        labels: _labels(),
        businessName: 'Loja',
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      expect(bytes.length, greaterThan(1500));
    });
  });

  group('QuotationPdfExporter.sharePdf', () {
    test(
      'grava o PDF temporário e partilha com nome por número + assunto',
      () async {
        final calls = <Map<String, dynamic>>[];
        messenger.setMockMethodCallHandler(shareChannel, (call) async {
          expect(call.method, 'share');
          calls.add(Map<String, dynamic>.from(call.arguments as Map));
          return 'dev.fluttercommunity.plus/share/dismissed';
        });

        await exporter.sharePdf(
          _quotation().copyWith(number: 7),
          labels: _labels(),
          businessName: 'Loja',
        );

        expect(calls, hasLength(1));
        final paths = (calls.single['paths'] as List).cast<String>();
        expect(paths.single, endsWith('cotacao_00007.pdf'));
        expect((calls.single['mimeTypes'] as List).single, 'application/pdf');
        expect(calls.single['subject'], 'Cotação Nº 00007');

        final written = File(paths.single).readAsBytesSync();
        expect(String.fromCharCodes(written.take(4)), '%PDF');
      },
    );
  });
}
