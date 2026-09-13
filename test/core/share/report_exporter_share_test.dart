import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:tareqo/core/share/report_exporter.dart';
import 'package:tareqo/data/services/product_image_store_supabase.dart';
import 'package:tareqo/domain/usecases/get_sales_report_use_case.dart';
import '../../helpers/supabase_test_harness.dart';

/// Fixtures — mesmas do report_exporter_test.dart.
ReportExportLabels _labels() => const ReportExportLabels(
  title: 'Relatório de vendas',
  store: 'Loja',
  period: 'Período',
  generatedAt: 'Gerado em',
  summary: 'Resumo',
  revenueKpi: 'Faturamento',
  profitKpi: 'Lucro bruto',
  marginKpi: 'Margem',
  bestSellers: 'Mais vendidos',
  rank: 'Posição',
  product: 'Produto',
  quantity: 'Quantidade',
  revenue: 'Receita',
  perDay: 'Vendas por dia',
  day: 'Dia',
  total: 'Total',
  units: 'un.',
  fileNameBase: 'relatorio_vendas',
);

SalesReport _report() => SalesReport(
  totalRevenueCents: 5400,
  totalProfitCents: 1800,
  bestSellers: [
    BestSeller(
      productId: 'p1',
      productName: 'Caneta azul',
      quantity: 12000,
      revenueCents: 2400,
    ),
  ],
  perDay: [DailySales(day: DateTime(2026, 8, 10), totalCents: 5400)],
);

/// Fake do [PathProviderPlatform] — grava em temp real para o File.
class _FakePathProvider extends PathProviderPlatform {
  late Directory tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;
  late StubSupabaseHttp stub;

  setUpAll(() async {
    stub = await initStubbedSupabase();
    await signInStubUser();
  });

  setUp(() async {
    fakePP.tempDir = await Directory.systemTemp.createTemp('tareqo_rpt_share');
    PathProviderPlatform.instance = fakePP;
    // Upload do Storage: o storage_client espera {'Key': '<path>'}.
    stub.handler = (path, request) => path.contains('/object/')
        ? FakeResponse({'Key': 'product-images/st-9/p-1.jpg'})
        : FakeResponse(<dynamic>[]);
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(shareChannel, null);
    PathProviderPlatform.instance = originalPP;
    await fakePP.tempDir.delete(recursive: true);
  });

  List<Map<String, dynamic>> captureShare() {
    final calls = <Map<String, dynamic>>[];
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      calls.add(Map<String, dynamic>.from(call.arguments as Map));
      return 'dev.fluttercommunity.plus/share/dismissed';
    });
    return calls;
  }

  group('ReportExporter — caminho real de compartilhamento (arquivo)', () {
    test('shareCsv grava CSV com BOM e partilha com o nome datado', () async {
      final calls = captureShare();
      final exporter = const ReportExporter();
      final generatedAt = DateTime(2026, 9, 5);

      await exporter.shareCsv(
        report: _report(),
        labels: _labels(),
        storeName: 'Matriz',
        periodLabel: 'Este mês',
        generatedAt: generatedAt,
      );

      expect(calls, hasLength(1));
      expect(calls.single['subject'], 'Relatório de vendas');
      final paths = (calls.single['paths'] ?? calls.single['files']) as List;
      expect(paths.single, contains('relatorio_vendas_2026-09-05.csv'));

      // O arquivo gravado é o MESMO compartilhado e começa com o BOM UTF-8
      // (Excel pt-BR lê os acentos corretamente).
      final file = File(paths.single as String);
      final bytes = await file.readAsBytes();
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
      expect(utf8.decode(bytes.sublist(3)), contains('Faturamento'));
    });

    test(
      'sharePdf grava PDF válido (%PDF) e partilha com mime correto',
      () async {
        final calls = captureShare();
        final exporter = const ReportExporter();
        final generatedAt = DateTime(2026, 9, 5);

        await exporter.sharePdf(
          report: _report(),
          labels: _labels(),
          storeName: 'Matriz',
          periodLabel: 'Este mês',
          generatedAt: generatedAt,
        );

        expect(calls, hasLength(1));
        final paths = (calls.single['paths'] ?? calls.single['files']) as List;
        expect(paths.single, contains('relatorio_vendas_2026-09-05.pdf'));
        final bytes = await File(paths.single as String).readAsBytes();
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      },
    );
  });

  group('ProductImageStoreSupabase — contrato do Storage (SaaS)', () {
    test('saveImage faz uploadBinary no caminho <storeId>/<productId>.jpg e '
        'devolve a URL pública', () async {
      final store = const ProductImageStoreSupabase();

      // O stub responde [] por padrão (uploadBinary aceita corpo vazio).
      final url = await store.saveImage(
        productId: 'p-1',
        storeId: 'st-9',
        bytes: Uint8List.fromList([1, 2, 3]),
      );

      // A URL pública aponta para o bucket e o caminho com store_id no
      // primeiro segmento (a política RLS do bucket valida isso).
      expect(url, contains('product-images/st-9/p-1.jpg'));
      expect(url, startsWith('https://fake.supabase.co/storage/v1/object/'));
    });

    test(
      'deleteImage com URL pública extrai o object path do bucket',
      () async {
        final store = const ProductImageStoreSupabase();
        // Não deve lançar: o stub responde [] (remove aceita lista vazia).
        await store.deleteImage(
          'https://fake.supabase.co/storage/v1/object/public/'
          'product-images/st-9/p-1.jpg',
        );
      },
    );

    test('deleteImage com path vazio é no-op (nada a remover)', () async {
      const store = ProductImageStoreSupabase();
      await store.deleteImage('');
      await store.deleteImage('not-a-bucket-url');
    });
  });
}
