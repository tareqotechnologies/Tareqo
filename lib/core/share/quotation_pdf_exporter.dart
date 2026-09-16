import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/quotation.dart';
import '../utils/formatters.dart';

/// Rótulos LOCALIZADOS do PDF da cotação/orçamento.
///
/// Montados pela tela a partir do `AppLocalizations` — o exporter é 100%
/// livre de UI; só recebe textos prontos (pt/en/fr), templates com
/// marcadores (`{value}`/`{number}`/`{date}`) e resolvers localizados.
class QuotationPdfLabels {
  const QuotationPdfLabels({
    required this.docWord,
    required this.numberLabelTemplate,
    required this.clientHeading,
    required this.phoneLabelTemplate,
    required this.taxIdLabelTemplate,
    required this.itemHeader,
    required this.qtyHeader,
    required this.unitPriceHeader,
    required this.subtotalHeader,
    required this.discountLabel,
    required this.totalLabel,
    required this.validityHeading,
    required this.notesHeading,
    required this.generalConditionsHeading,
    required this.validConditionTemplate,
    required this.pricesConditionText,
    required this.contactConditionText,
    required this.footerTemplate,
    required this.fileNameBase,
    required this.subjectWord,
    required this.statusText,
    required this.daysLeftText,
  });

  /// Tipo de documento exibido no selo (ex.: 'COTAÇÃO'/'QUOTATION').
  final String docWord;

  /// Template do número com marcador `{number}` (ex.: 'Nº {number}').
  final String numberLabelTemplate;

  /// Cabeçalho da secção do cliente (ex.: 'CLIENTE'/'CLIENT').
  final String clientHeading;

  /// Template 'Tel: {value}' com marcador `{value}`.
  final String phoneLabelTemplate;

  /// Template 'NIF: {value}' com marcador `{value}`.
  final String taxIdLabelTemplate;

  final String itemHeader;
  final String qtyHeader;
  final String unitPriceHeader;
  final String subtotalHeader;
  final String discountLabel;
  final String totalLabel;

  /// Cabeçalho da validade (ex.: 'Validade'/'Validity').
  final String validityHeading;

  /// Cabeçalho das notas quando presentes (ex.: 'Condições / Notas').
  final String notesHeading;

  /// Cabeçalho da caixa de condições gerais.
  final String generalConditionsHeading;

  /// Template da 1ª condição com marcador `{date}` (validade até ...).
  final String validConditionTemplate;

  final String pricesConditionText;
  final String contactConditionText;

  /// Template do rodapé com marcador `{date}`.
  final String footerTemplate;

  /// Base do nome do arquivo (ex.: 'cotacao'/'quotation').
  final String fileNameBase;

  /// Palavra do assunto da partilha (ex.: 'Cotação'/'Quotation').
  final String subjectWord;

  /// Resolve o rótulo do estado da cotação a partir do enum.
  final String Function(QuotationStatus status) statusText;

  /// Resolve o texto de dias restantes/vencida a partir dos dias restantes
  /// (pluralização e 'Expirada' decididas no chamador via l10n).
  final String Function(int daysRemaining) daysLeftText;
}

/// Exportação de cotações/orçamentos para PDF.
///
/// Gera um documento A4 profissional com validade, condições e tabela de
/// itens. Compartilhado pelo share sheet do sistema.
class QuotationPdfExporter {
  const QuotationPdfExporter();

  /// Gera os bytes do PDF da cotação.
  Future<Uint8List> buildPdf(
    Quotation quotation, {
    required QuotationPdfLabels labels,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    Uint8List? logoBytes,
    PdfColor primaryColor = PdfColors.amber700,
    String templateStyle = 'Classic',
  }) async {
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: pw.Font.ttf(data)),
    );

    final daysRemaining = quotation.validUntil
        .difference(DateTime.now())
        .inDays;
    final statusLabel = labels.statusText(quotation.status);
    final validityDaysLabel = labels.daysLeftText(daysRemaining);

    // Pré-carregar o logotipo se fornecido.
    pw.ImageProvider? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(logoBytes);
    }

    // Cor escura para texto sobre fundo claro.
    final primaryDark = _darken(primaryColor);

    final quotationNumber = quotation.number.toString().padLeft(5, '0');
    final dateLine = _formatDate(quotation.createdAt);
    final validUntilLine = _formatDate(quotation.validUntil);

    // Mesmos 3 estilos do template da Factura (Classic/Modern/Compact).
    final isModern = templateStyle == 'Modern';
    final isCompact = templateStyle == 'Compact';
    final gapSection = isCompact ? 12.0 : (isModern ? 28.0 : 20.0);
    final gapTable = isCompact ? 8.0 : 16.0;
    final tablePadding = isCompact ? 4.0 : 6.0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.fromLTRB(
          isModern ? 0 : 32,
          32,
          isModern ? 0 : 32,
          32,
        ),
        build: (context) => [
          // ─── Cabeçalho ───────────────────────────────────────
          // Modern: faixa lateral colorida + fundo suave (mesma identidade
          // da Factura) — o PDF da cotação segue o ESTILO do template.
          if (isModern)
            // Borda lateral + fundo suave (identidade Modern). Container
            // puro: Row+stretch teria altura infinita no MultiPage.
            pw.Container(
              padding: const pw.EdgeInsets.fromLTRB(24, 32, 32, 24),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(
                  0x0D000000 | (primaryColor.toInt() & 0x00FFFFFF),
                ),
                border: pw.Border(
                  left: pw.BorderSide(color: primaryColor, width: 10),
                ),
              ),
              child: _header(
                logoImage: logoImage,
                businessName: businessName,
                businessAddress: businessAddress,
                businessPhone: businessPhone,
                businessTaxId: businessTaxId,
                labels: labels,
                quotationNumber: quotationNumber,
                dateLine: dateLine,
                statusLabel: statusLabel,
                primaryColor: primaryColor,
                primaryDark: primaryDark,
              ),
            )
          else
            _header(
              logoImage: logoImage,
              businessName: businessName,
              businessAddress: businessAddress,
              businessPhone: businessPhone,
              businessTaxId: businessTaxId,
              labels: labels,
              quotationNumber: quotationNumber,
              dateLine: dateLine,
              statusLabel: statusLabel,
              primaryColor: primaryColor,
              primaryDark: primaryDark,
            ),

          pw.SizedBox(height: gapSection),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: isCompact ? 8 : 16),

          // ─── Dados do Cliente ────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      labels.clientHeading,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      quotation.customerName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (quotation.customerPhone.isNotEmpty)
                      pw.Text(
                        _fill(
                          labels.phoneLabelTemplate,
                          quotation.customerPhone,
                        ),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    labels.validityHeading,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    validUntilLine,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: daysRemaining <= 3
                          ? PdfColors.red700
                          : PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    validityDaysLabel,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: daysRemaining <= 3
                          ? PdfColors.red600
                          : PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: gapSection),

          // ─── Tabela de Itens ─────────────────────────────────
          pw.TableHelper.fromTextArray(
            headers: [
              labels.itemHeader,
              labels.qtyHeader,
              labels.unitPriceHeader,
              labels.subtotalHeader,
            ],
            data: [
              for (final item in quotation.items)
                [
                  item.productName,
                  _formatQty(item.quantity),
                  Formatters.currency(item.unitPriceCents),
                  Formatters.currency(
                    item.quantity * item.unitPriceCents ~/ 1000,
                  ),
                ],
            ],
            columnWidths: const {
              0: pw.FlexColumnWidth(),
              1: pw.FixedColumnWidth(60),
              2: pw.FixedColumnWidth(80),
              3: pw.FixedColumnWidth(80),
            },
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: pw.EdgeInsets.all(tablePadding),
            cellAlignments: {
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),

          pw.SizedBox(height: gapTable),

          // ─── Totais ──────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    if (quotation.discountCents > 0)
                      _totalRow(
                        labels.discountLabel,
                        '-${Formatters.currency(quotation.discountCents)}',
                        PdfColors.red700,
                      ),
                    pw.Divider(color: PdfColors.grey300),
                    _totalRow(
                      labels.totalLabel,
                      Formatters.currency(quotation.totalAmountCents),
                      primaryDark,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ─── Notas ───────────────────────────────────────────
          if (quotation.notes.isNotEmpty) ...[
            pw.SizedBox(height: gapTable),
            pw.Text(
              labels.notesHeading,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              quotation.notes,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],

          // ─── Condições Gerais ────────────────────────────────
          pw.SizedBox(height: gapSection),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  labels.generalConditionsHeading,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '• ${labels.validConditionTemplate.replaceFirst('{date}', validUntilLine)}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '• ${labels.pricesConditionText}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '• ${labels.contactConditionText}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          // ─── Rodapé ──────────────────────────────────────────
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              labels.footerTemplate.replaceFirst('{date}', dateLine),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Gera e partilha o PDF da cotação.
  Future<void> sharePdf(
    Quotation quotation, {
    required QuotationPdfLabels labels,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    Uint8List? logoBytes,
    PdfColor primaryColor = PdfColors.amber700,
    String templateStyle = 'Classic',
  }) async {
    final bytes = await buildPdf(
      quotation,
      labels: labels,
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      businessTaxId: businessTaxId,
      logoBytes: logoBytes,
      primaryColor: primaryColor,
      templateStyle: templateStyle,
    );
    final number = quotation.number.toString().padLeft(5, '0');
    final fileName = '${labels.fileNameBase}_$number.pdf';
    final subject =
        '${labels.subjectWord} '
        '${labels.numberLabelTemplate.replaceFirst('{number}', number)}';
    await _share(bytes, fileName, subject);
  }

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

  /// Cabeçalho do PDF da cotação (logotipo + empresa + selo/estado).
  /// Extraído para as variantes por ESTILO (Modern embrulha na faixa).
  pw.Widget _header({
    required pw.ImageProvider? logoImage,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    required QuotationPdfLabels labels,
    required String quotationNumber,
    required String dateLine,
    required String statusLabel,
    required PdfColor primaryColor,
    required PdfColor primaryDark,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Lado esquerdo: logotipo + dados da empresa
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null) ...[
                pw.Container(
                  width: 48,
                  height: 48,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
              ],
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      businessName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryDark,
                      ),
                    ),
                    if (businessAddress != null && businessAddress.isNotEmpty)
                      pw.Text(
                        businessAddress,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if (businessPhone != null && businessPhone.isNotEmpty)
                      pw.Text(
                        businessPhone,
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    if (businessTaxId != null && businessTaxId.isNotEmpty)
                      pw.Text(
                        _fill(labels.taxIdLabelTemplate, businessTaxId),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Lado direito: selo COTAÇÃO + nº + data + estado
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                labels.docWord,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              labels.numberLabelTemplate.replaceFirst('{number}', quotationNumber),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              dateLine,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColor(
                  primaryColor.red,
                  primaryColor.green,
                  primaryColor.blue,
                ),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                statusLabel,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Substitui o marcador `{value}` pelo valor fornecido.
  String _fill(String template, String value) =>
      template.replaceFirst('{value}', value);

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatQty(int millesimos) {
    if (millesimos % 1000 == 0) return '${millesimos ~/ 1000}';
    return (millesimos / 1000).toStringAsFixed(1);
  }

  pw.Widget _totalRow(
    String label,
    String value,
    PdfColor color, {
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 12 : 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 14 : 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Escurece uma cor PDF para usar como texto sobre fundo claro.
  PdfColor _darken(PdfColor color) {
    return PdfColor(
      (color.red * 0.7).clamp(0, 1),
      (color.green * 0.7).clamp(0, 1),
      (color.blue * 0.7).clamp(0, 1),
    );
  }
}
