import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/usecases/get_sales_report_use_case.dart';
import '../utils/formatters.dart';
import '../utils/quantity.dart';

/// Rótulos LOCALIZADOS do relatório exportado (CSV/PDF).
///
/// Montados pela tela a partir do `AppLocalizations` — o exporter é 100%
/// livre de UI; só recebe textos prontos (pt/en) e formata valores.
class ReportExportLabels {
  const ReportExportLabels({
    required this.title,
    required this.store,
    required this.period,
    required this.generatedAt,
    required this.summary,
    required this.revenueKpi,
    required this.profitKpi,
    required this.marginKpi,
    required this.bestSellers,
    required this.rank,
    required this.product,
    required this.quantity,
    required this.revenue,
    required this.perDay,
    required this.day,
    required this.total,
    required this.units,
    // Base do NOME do arquivo (localizada: 'relatorio_vendas' pt /
    // 'sales_report' en) — o exporter recebe textos prontos, nunca hardcoda.
    required this.fileNameBase,
  });

  final String title;
  final String store;
  final String period;
  final String generatedAt;
  final String summary;
  final String revenueKpi;
  final String profitKpi;
  final String marginKpi;
  final String bestSellers;
  final String rank;
  final String product;
  final String quantity;
  final String revenue;
  final String perDay;
  final String day;
  final String total;

  /// Sufixo de unidade (ex.: 'un.') para quantidades exibidas.
  final String units;

  /// Base localizada do nome do arquivo exportado (ex.: 'relatorio_vendas').
  final String fileNameBase;
}

/// Exportação do relatório de vendas — única porta de saída para os dois
/// formatos, espelhando o `ReceiptSharer`:
///
/// 1. **CSV** — texto RFC 4180 com `;` (Excel pt-BR/MZN abre direto),
/// UTF-8 com BOM; gerado localmente, sem dependência;
/// 2. **PDF** — documento A4 via pacote oficial `pdf` (dart-lang): resumo
/// (faturamento/lucro/margem), mais vendidos e vendas por dia em tabelas.
///
/// Ambos são partilhados pelo share sheet do sistema (arquivo temporário no
/// mobile; `XFile.fromData` na web). Criado via provider
/// ([reportExporterProvider]) para ser substituído por um fake nos testes.
class ReportExporter {
  const ReportExporter();

  /// Gera e partilha o relatório em CSV.
  Future<void> shareCsv({
    required SalesReport report,
    required ReportExportLabels labels,
    required String storeName,
    required String periodLabel,
    required DateTime generatedAt,
  }) async {
    final csv = buildCsv(
      report: report,
      labels: labels,
      storeName: storeName,
      periodLabel: periodLabel,
      generatedAt: generatedAt,
    );
    // BOM UTF-8: o Excel identifica a codificação corretamente (acentos).
    final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csv'));
    await _share(
      bytes,
      _fileName(labels.fileNameBase, generatedAt, 'csv'),
      'text/csv',
      subject: labels.title,
    );
  }

  /// Gera e partilha o relatório em PDF.
  Future<void> sharePdf({
    required SalesReport report,
    required ReportExportLabels labels,
    required String storeName,
    required String periodLabel,
    required DateTime generatedAt,
  }) async {
    final bytes = await buildPdf(
      report: report,
      labels: labels,
      storeName: storeName,
      periodLabel: periodLabel,
      generatedAt: generatedAt,
    );
    await _share(
      bytes,
      _fileName(labels.fileNameBase, generatedAt, 'pdf'),
      'application/pdf',
      subject: labels.title,
    );
  }

  /// Conteúdo CSV do relatório (RFC 4180, delimitador `;`).
  ///
  /// Estrutura: cabeçalho (loja/período/gerado em) → resumo → mais vendidos
  /// → vendas por dia. Campos com o DELIMITADOR `;`, aspas ou quebra de
  /// linha são entre-aspados (escape `""`) — nunca quebra a linha do CSV.
  /// A vírgula decimal da moeda (`R$ 54,00`) NÃO é escapada: com separador
  /// `;`, o Excel pt-BR/MZN lê o campo inteiro sem aspas desnecessárias.
  @visibleForTesting
  String buildCsv({
    required SalesReport report,
    required ReportExportLabels labels,
    required String storeName,
    required String periodLabel,
    required DateTime generatedAt,
  }) {
    final buffer = StringBuffer();
    void line(List<String> cells) =>
        buffer.writeln(cells.map(_csvField).join(';'));

    line([labels.title]);
    line([labels.store, storeName]);
    line([labels.period, periodLabel]);
    line([labels.generatedAt, Formatters.dateTime(generatedAt)]);
    buffer.writeln();

    line([labels.summary]);
    line([labels.revenueKpi, labels.profitKpi, labels.marginKpi]);
    line([
      Formatters.currency(report.totalRevenueCents),
      Formatters.currency(report.totalProfitCents),
      '${report.margin.toStringAsFixed(1)}%',
    ]);
    buffer.writeln();

    line([labels.bestSellers]);
    line([labels.rank, labels.product, labels.quantity, labels.revenue]);
    for (var i = 0; i < report.bestSellers.length; i++) {
      final seller = report.bestSellers[i];
      line([
        '${i + 1}',
        seller.productName,
        _formatQuantity(seller.quantity, labels.units),
        Formatters.currency(seller.revenueCents),
      ]);
    }
    buffer.writeln();

    line([labels.perDay]);
    line([labels.day, labels.total]);
    for (final daily in report.perDay) {
      line([Formatters.date(daily.day), Formatters.currency(daily.totalCents)]);
    }

    return buffer.toString();
  }

  /// Bytes do PDF do relatório (A4, resumo + tabelas).
  ///
  /// A fonte Inter do app é EMBUTIDA no documento (a Helvetica padrão não
  /// tem suporte a Unicode — acentos pt como ó/ã/ç falhariam ao codificar).
  @visibleForTesting
  Future<Uint8List> buildPdf({
    required SalesReport report,
    required ReportExportLabels labels,
    required String storeName,
    required String periodLabel,
    required DateTime generatedAt,
  }) async {
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    // Bold REAL: TTF estático Inter-Bold (mesma versão upstream 4.001 da
    // Inter variável do app) embutido como fonte `bold` do dart_pdf — o
    // pacote não seleciona o eixo wght da variável, então sem isto os pesos
    // bold caem na base (hierarquia do relatório perdia o peso).
    final bold = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(data),
        bold: pw.Font.ttf(bold),
      ),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            labels.title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${labels.store}: $storeName · ${labels.period}: $periodLabel',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.Text(
            '${labels.generatedAt}: ${Formatters.dateTime(generatedAt)}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              _summaryCell(
                labels.revenueKpi,
                Formatters.currency(report.totalRevenueCents),
              ),
              _summaryCell(
                labels.profitKpi,
                Formatters.currency(report.totalProfitCents),
              ),
              _summaryCell(
                labels.marginKpi,
                '${report.margin.toStringAsFixed(1)}%',
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          pw.Text(
            labels.bestSellers,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (report.bestSellers.isEmpty)
            pw.Text('—', style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: [
                labels.rank,
                labels.product,
                labels.quantity,
                labels.revenue,
              ],
              data: [
                for (var i = 0; i < report.bestSellers.length; i++)
                  [
                    '${i + 1}',
                    report.bestSellers[i].productName,
                    _formatQuantity(
                      report.bestSellers[i].quantity,
                      labels.units,
                    ),
                    Formatters.currency(report.bestSellers[i].revenueCents),
                  ],
              ],
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(70),
                3: pw.FixedColumnWidth(90),
              },
              headerStyle: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          pw.SizedBox(height: 24),
          pw.Text(
            labels.perDay,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (report.perDay.isEmpty)
            pw.Text('—', style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.TableHelper.fromTextArray(
              headers: [labels.day, labels.total],
              data: [
                for (final daily in report.perDay)
                  [
                    Formatters.date(daily.day),
                    Formatters.currency(daily.totalCents),
                  ],
              ],
              columnWidths: const {
                0: pw.FlexColumnWidth(),
                1: pw.FixedColumnWidth(110),
              },
              headerStyle: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo700,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> _share(
    Uint8List bytes,
    String fileName,
    String mimeType, {
    required String subject,
  }) async {
    if (kIsWeb) {
      // Web Share API com fallback de download (share_plus).
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
          subject: subject,
        ),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: subject,
      ),
    );
  }

  String _fileName(String base, DateTime generatedAt, String extension) {
    final date =
        '${generatedAt.year}-'
        '${generatedAt.month.toString().padLeft(2, '0')}-'
        '${generatedAt.day.toString().padLeft(2, '0')}';
    return '${base}_$date.$extension';
  }

  /// Quantidade (MILÉSIMOS, W11) exibida em unidades + sufixo localizado.
  String _formatQuantity(int milli, String unitsLabel) =>
      '${Quantity.format(milli, language: Formatters.currentLanguage)}'
      '${unitsLabel.isEmpty ? '' : ' $unitsLabel'}';

  pw.Widget _summaryCell(String label, String value) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
        ],
      ),
    ),
  );

  static String _csvField(String value) {
    if (!value.contains(';') &&
        !value.contains('"') &&
        !value.contains('\n') &&
        !value.contains('\r')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
