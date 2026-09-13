import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:tareqo/core/share/advanced_reports_pdf_exporter.dart';

/// Fake do [PathProviderPlatform] — o `_share` (ramo não-web) grava o PDF
/// num diretório temporário antes de partilhar. Aponta para um diretório
/// REAL criado no setUp (o `File.writeAsBytes` não cria diretórios pais).
class _FakePathProvider extends PathProviderPlatform {
  late Directory tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;

  setUp(() async {
    fakePP.tempDir = await Directory.systemTemp.createTemp('tareqo_adv_rpt');
    PathProviderPlatform.instance = fakePP;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    PathProviderPlatform.instance = originalPP;
    await fakePP.tempDir.delete(recursive: true);
  });

  /// Registra o mock do channel ANTES da chamada e devolve a lista de
  /// argumentos capturados (`paths`, `mimeTypes`, `subject`).
  List<Map<String, dynamic>> captureShare() {
    final calls = <Map<String, dynamic>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(Map<String, dynamic>.from(call.arguments as Map));
      return 'dev.fluttercommunity.plus/share/dismissed';
    });
    return calls;
  }

  Map<String, String> kpis() => const {
    'Faturamento': 'R\$ 54,00',
    'Lucro bruto': 'R\$ 18,00',
    'Margem': '33,3%',
  };

  const businessName = 'Farmácia Vida';
  const generatedOnLabel = 'Gerado em {date}';
  const indicatorsLabel = 'Indicadores';
  const noDataLabel = 'Sem dados';
  const footerLabel = 'Tareqo — {date}';

  group('AdvancedReportsPdfExporter — share (caminho real de arquivo)', () {
    test(
      'shareSalesReport grava o PDF temporário e partilha com slug',
      () async {
        final calls = captureShare();
        const title = 'Relatório de Vendas';
        await const AdvancedReportsPdfExporter().shareSalesReport(
          title: title,
          period: 'Este mês',
          kpis: kpis(),
          businessName: businessName,
          generatedOnLabel: generatedOnLabel,
          indicatorsLabel: indicatorsLabel,
          noDataLabel: noDataLabel,
          footerLabel: footerLabel,
        );

        expect(calls, hasLength(1));
        expect(calls.single['subject'], title);
        final paths = (calls.single['paths'] as List).cast<String>();
        // O título vira nome de arquivo seguro (sem espaços/maiúsculas).
        expect(paths.single, endsWith('relatorio_de_vendas.pdf'));
        expect((calls.single['mimeTypes'] as List).single, 'application/pdf');

        // O arquivo partilhado é um PDF válido — lido do disco a partir do
        // caminho que o exporter gravou via getTemporaryDirectory.
        final bytes = File(paths.single).readAsBytesSync();
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      },
    );

    test(
      'shareFinancialReport e shareStockReport partilham PDFs válidos com slug sem acentos',
      () async {
        final exporter = const AdvancedReportsPdfExporter();

        final finCalls = captureShare();
        await exporter.shareFinancialReport(
          title: 'Relatório Financeiro ÁéÍ',
          period: 'Hoje',
          kpis: kpis(),
          businessName: businessName,
          generatedOnLabel: generatedOnLabel,
          indicatorsLabel: indicatorsLabel,
          noDataLabel: noDataLabel,
          footerLabel: footerLabel,
        );
        final finPaths = (finCalls.single['paths'] as List).cast<String>();
        // Slug remove acentos e espaços.
        expect(finPaths.single, endsWith('relatorio_financeiro_aei.pdf'));
        final finBytes = File(finPaths.single).readAsBytesSync();
        expect(String.fromCharCodes(finBytes.take(4)), '%PDF');

        final stockCalls = captureShare();
        await exporter.shareStockReport(
          title: 'Relatório de Estoque',
          period: 'Semana',
          kpis: kpis(),
          businessName: businessName,
          generatedOnLabel: generatedOnLabel,
          indicatorsLabel: indicatorsLabel,
          noDataLabel: noDataLabel,
          footerLabel: footerLabel,
        );
        final stockPaths = (stockCalls.single['paths'] as List).cast<String>();
        expect(stockPaths.single, endsWith('relatorio_de_estoque.pdf'));
        final stockBytes = File(stockPaths.single).readAsBytesSync();
        expect(String.fromCharCodes(stockBytes.take(4)), '%PDF');
      },
    );
  });
}
