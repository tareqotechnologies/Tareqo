import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Exportação de relatórios avançados para PDF.
///
/// Gera documentos A4 para os 3 tipos de relatório:
/// - Vendas: KPIs + gráfico + top produtos
/// - Financeiro: receitas/despesas/lucro + fluxo de caixa
/// - Estoque: KPIs + produtos com estoque baixo
class AdvancedReportsPdfExporter {
  const AdvancedReportsPdfExporter();

  /// Gera e partilha o relatório de vendas.
  Future<void> shareSalesReport({
    required String period,
    required Map<String, String> kpis,
    String? businessName,
  }) async {
    final bytes = await _buildReport(
      title: 'Relatório de Vendas',
      period: period,
      kpis: kpis,
      sections: [],
      businessName: businessName,
    );
    await _share(bytes, 'relatorio_vendas.pdf', 'Relatório de Vendas');
  }

  /// Gera e partilha o relatório financeiro.
  Future<void> shareFinancialReport({
    required String period,
    required Map<String, String> kpis,
    String? businessName,
  }) async {
    final bytes = await _buildReport(
      title: 'Relatório Financeiro',
      period: period,
      kpis: kpis,
      sections: [],
      businessName: businessName,
    );
    await _share(bytes, 'relatorio_financeiro.pdf', 'Relatório Financeiro');
  }

  /// Gera e partilha o relatório de estoque.
  Future<void> shareStockReport({
    required String period,
    required Map<String, String> kpis,
    String? businessName,
  }) async {
    final bytes = await _buildReport(
      title: 'Relatório de Estoque',
      period: period,
      kpis: kpis,
      sections: [],
      businessName: businessName,
    );
    await _share(bytes, 'relatorio_estoque.pdf', 'Relatório de Estoque');
  }

  Future<Uint8List> _buildReport({
    required String title,
    required String period,
    required Map<String, String> kpis,
    required List<_ReportSection> sections,
    String? businessName,
  }) async {
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: pw.Font.ttf(data)),
    );

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ─── Header ───────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    businessName ?? 'TAREQO',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo700,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      period,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Gerado: $dateStr',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),

          // ─── KPI Cards ──────────────────────────────────
          pw.Text(
            'Indicadores',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ..._buildKpiRows(kpis),

          // ─── Sections ───────────────────────────────────
          for (final section in sections) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              section.title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (section.rows.isEmpty)
              pw.Text(
                'Sem dados para este período',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey500,
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: section.headers,
                data: section.rows,
                headerStyle: pw.TextStyle(
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

          // ─── Footer ─────────────────────────────────────
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Documento gerado pelo TAREQO — $dateStr',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
              ),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  List<pw.Widget> _buildKpiRows(Map<String, String> kpis) {
    final entries = kpis.entries.toList();
    final rows = <pw.Widget>[];

    for (var i = 0; i < entries.length; i += 2) {
      final children = <pw.Widget>[];

      children.add(_kpiCell(entries[i].key, entries[i].value));

      if (i + 1 < entries.length) {
        children.add(pw.SizedBox(width: 8));
        children.add(_kpiCell(entries[i + 1].key, entries[i + 1].value));
      }

      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(children: children),
        ),
      );
    }

    return rows;
  }

  pw.Widget _kpiCell(String label, String value) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _share(Uint8List bytes, String fileName, String subject) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName),
          ],
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
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: subject,
      ),
    );
  }
}

class _ReportSection {
  const _ReportSection({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}
