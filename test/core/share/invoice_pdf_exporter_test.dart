import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

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
  createdAt: DateTime(2026, 8, 3, 14, 30),
);

/// Fake do [PathProviderPlatform] — diretório temporário REAL: o
/// `sharePdf` grava o PDF em `$temp/<arquivo>.pdf` antes de partilhar
/// (Android/iOS exigem um `File` no share sheet).
class _FakePathProvider extends PathProviderPlatform {
  late Directory tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

void main() {
  // O buildPdf embute a fonte Outfit via rootBundle (asset do pubspec).
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;

  setUp(() async {
    fakePP.tempDir = await Directory.systemTemp.createTemp('tareqo_invoice');
    PathProviderPlatform.instance = fakePP;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(shareChannel, null);
    PathProviderPlatform.instance = originalPP;
    await fakePP.tempDir.delete(recursive: true);
  });

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

    test('logotipo fornecido é embutido no documento sem quebrar', () async {
      // PNG 1×1 REAL (pixel vermelho) — o decoder do pacote pdf valida
      // a imagem de verdade, não apenas a assinatura.
      final logo = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
        'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      );

      final bytes = await exporter.buildPdf(
        _invoice(),
        labels: _labels(),
        businessName: 'Com Logo',
        logoBytes: logo,
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      // Documento com imagem embutida é estruturalmente maior que sem.
      final without = await exporter.buildPdf(
        _invoice(),
        labels: _labels(),
        businessName: 'Com Logo',
      );
      expect(bytes.length, greaterThan(without.length));
    });

    test(
      'itens por peso (fração) e totais com desconto/imposto renderizam',
      () async {
        final invoice = CustomInvoice(
          id: 'ci2',
          storeId: 'st1',
          clientName: 'Maria Peso',
          clientEmail: 'maria@test.local',
          clientAddress: 'Rua 5, 12',
          items: const [
            CustomInvoiceItem(
              productName: 'Arroz a granel',
              quantity: 1500,
              unit: 'kg',
              unitPriceCents: 850,
              subtotalCents: 12750,
            ),
          ],
          totalAmountCents: 14000,
          discountCents: 250,
          taxCents: 1500,
          notes: 'Entrega ao sábado antes das 10h',
          paymentMethod: 'M-Pesa',
          paymentReference: 'MP2408.123.A45678',
          createdAt: DateTime(2026, 8, 3),
        );

        final bytes = await exporter.buildPdf(
          invoice,
          labels: _labels(),
          businessName: 'Loja',
        );

        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        expect(bytes.length, greaterThan(1500));
      },
    );

    test(
      'número da factura fica com padding de 5 dígitos no nome do arquivo',
      () async {
        // Contrato validado via sharePdf (abaixo) — aqui só garantimos que
        // o PDF aceita number=42 sem quebrar.
        final bytes = await exporter.buildPdf(
          CustomInvoice(
            id: 'ci3',
            storeId: 'st1',
            clientName: 'Cliente',
            number: 42,
            items: const [
              CustomInvoiceItem(
                productName: 'Item',
                quantity: 1000,
                unitPriceCents: 100,
                subtotalCents: 100,
              ),
            ],
            totalAmountCents: 100,
            createdAt: DateTime(2026, 8, 3),
          ),
          labels: _labels(),
          businessName: 'Loja',
        );

        expect(bytes, isNotEmpty);
      },
    );
  });

  group('InvoicePdfExporter.sharePdf', () {
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
          CustomInvoice(
            id: 'ci4',
            storeId: 'st1',
            clientName: 'Cliente Share',
            number: 42,
            items: const [
              CustomInvoiceItem(
                productName: 'Item',
                quantity: 1000,
                unitPriceCents: 100,
                subtotalCents: 100,
              ),
            ],
            totalAmountCents: 100,
            createdAt: DateTime(2026, 8, 3),
          ),
          labels: _labels(),
          businessName: 'Loja',
        );

        expect(calls, hasLength(1));
        final paths = (calls.single['paths'] as List).cast<String>();
        expect(paths.single, endsWith('factura_00042.pdf'));
        expect((calls.single['mimeTypes'] as List).single, 'application/pdf');
        expect(calls.single['subject'], 'Factura Nº 00042');

        // O arquivo partilhado é um PDF REAL com os bytes gerados.
        final written = File(paths.single).readAsBytesSync();
        expect(String.fromCharCodes(written.take(4)), '%PDF');
        expect(written.length, greaterThan(500));
      },
    );
  });
}
