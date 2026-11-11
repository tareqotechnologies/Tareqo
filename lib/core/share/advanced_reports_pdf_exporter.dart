import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'pdf_accent.dart';

/// Exportação de relatórios avançados para PDF.
///
/// Gera documentos A4 para os 3 tipos de relatório:
/// - Vendas: KPIs + gráfico + top produtos
/// - Financeiro: receitas/despesas/lucro + fluxo de caixa
/// - Estoque: KPIs + produtos com estoque baixo
class AdvancedReportsPdfExporter {
  const AdvancedReportsPdfExporter();

  /// Gera e partilha o relatório de vendas.
  ///
  /// [title] é o título localizado exibido no documento e usado como base
  /// do nome do arquivo; o exporter nunca hardcoda textos.
  Future<void> shareSalesReport({
    required String title,
    required String period,
    required Map<String, String> kpis,
    required String businessName,
    required String generatedOnLabel,
    required String indicatorsLabel,
    required String noDataLabel,
    required String footerLabel,
  }) async {
    final bytes = await _buildReport(
      title: title,
      period: period,
      kpis: kpis,
      sections: [],
      businessName: businessName,
      generatedOnLabel: generatedOnLabel,
      indicatorsLabel: indicatorsLabel,
      noDataLabel: noDataLabel,
      footerLabel: footerLabel,
    );
    await _share(bytes, '${_slug(title)}.pdf', title);
  }

  /// Gera e partilha o relatório financeiro.
  Future<void> shareFinancialReport({
    required String title,
    required String period,
    required Map<String, String> kpis,
    required String businessName,
    required String generatedOnLabel,
    required String indicatorsLabel,
    required String noDataLabel,
    required String footerLabel,
  }) async {
    final bytes = await _buildReport(
      title: title,
      period: period,
      kpis: kpis,
      sections: [],
      businessName: businessName,
      generatedOnLabel: generatedOnLabel,
      indicatorsLabel: indicatorsLabel,
      noDataLabel: noDataLabel,
      footerLabel: footerLabel,
    );
    await _share(bytes, '${_slug(title)}.pdf', title);
  }

  /// Gera e partilha o relatório de estoque.
  Future<void> shareStockReport({
    required String title,
    required String period,
    required Map<String, String> kpis,
    required String businessName,
    required String generatedOnLabel,
    required String indicatorsLabel,
    required String noDataLabel,
    required String footerLabel,
  }) async {
    final bytes = await _buildReport(
      title: title,
      period: period,
      kpis: kpis,
      sections: [],
      businessName: businessName,
      generatedOnLabel: generatedOnLabel,
      indicatorsLabel: indicatorsLabel,
      noDataLabel: noDataLabel,
      footerLabel: footerLabel,
    );
    await _share(bytes, '${_slug(title)}.pdf', title);
  }

  /// Converte o título localizado em base de nome de arquivo segura.
  String _slug(String title) {
    const accents = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const plain = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final sb = StringBuffer();
    for (final ch in title.toLowerCase().split('')) {
      final idx = accents.indexOf(ch);
      sb.write(idx >= 0 ? plain[idx] : ch);
    }
    return sb
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<Uint8List> _buildReport({
    required String title,
    required String period,
    required Map<String, String> kpis,
    required List<_ReportSection> sections,
    required String businessName,
    required String generatedOnLabel,
    required String indicatorsLabel,
    required String noDataLabel,
    required String footerLabel,
  }) async {
    final data = await rootBundle.load('assets/fonts/Outfit-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Outfit-Bold.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(data),
        bold: pw.Font.ttf(bold),
      ),
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
                    businessName,
                    style: const pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfAccents.slateDeep,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    title,
                    style: const pw.TextStyle(
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
                      color: PdfAccents.petrol,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      period,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfAccents.ice,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    generatedOnLabel.replaceFirst('{date}', dateStr),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfAccents.gray,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfAccents.gray),
          pw.SizedBox(height: 16),

          // ─── KPI Cards ──────────────────────────────────
          pw.Text(
            indicatorsLabel,
            style: const pw.TextStyle(
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
              style: const pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (section.rows.isEmpty)
              pw.Text(
                noDataLabel,
                style: const pw.TextStyle(fontSize: 9, color: PdfAccents.gray),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: section.headers,
                data: section.rows,
                headerStyle: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfAccents.ice,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfAccents.petrol,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.all(6),
              ),
          ],

          // ─── Footer ─────────────────────────────────────
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfAccents.gray),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              footerLabel.replaceFirst('{date}', dateStr),
              style: const pw.TextStyle(fontSize: 8, color: PdfAccents.gray),
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
        color: PdfAccents.warmBeige,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfAccents.gray),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfAccents.slateDeep,
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
