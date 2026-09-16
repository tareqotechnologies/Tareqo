import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/custom_invoice.dart';
import '../utils/formatters.dart';

/// Rótulos LOCALIZADOS do PDF da factura personalizada.
///
/// Montados pela tela a partir do `AppLocalizations` — o exporter é 100%
/// livre de UI; só recebe textos prontos (pt/en/fr) e valores.
///
/// Templates (`{value}`/`{number}`/`{date}`) são preenchidos pelo exporter
/// com os dados do documento (telefone, NIF, número, data).
class InvoicePdfLabels {
  const InvoicePdfLabels({
    required this.docWord,
    required this.numberLabelTemplate,
    required this.clientHeading,
    required this.phoneLabelTemplate,
    required this.emailLabelTemplate,
    required this.taxIdLabelTemplate,
    required this.itemHeader,
    required this.qtyHeader,
    required this.unitPriceHeader,
    required this.subtotalHeader,
    required this.discountLabel,
    required this.taxLabel,
    required this.totalLabel,
    required this.paymentLabelTemplate,
    required this.referenceLabelTemplate,
    required this.notesHeading,
    required this.footerTemplate,
    required this.fileNameBase,
    required this.subjectWord,
  });

  /// Tipo de documento exibido no selo (ex.: 'FACTURA'/'INVOICE').
  final String docWord;

  /// Template do número com marcador `{number}` (ex.: 'Nº {number}').
  final String numberLabelTemplate;

  /// Cabeçalho da secção do cliente (ex.: 'CLIENTE'/'CLIENT').
  final String clientHeading;

  /// Template 'Tel: {value}' com marcador `{value}`.
  final String phoneLabelTemplate;

  /// Template 'Email: {value}' com marcador `{value}`.
  final String emailLabelTemplate;

  /// Template 'NIF: {value}' com marcador `{value}`.
  final String taxIdLabelTemplate;

  final String itemHeader;
  final String qtyHeader;
  final String unitPriceHeader;
  final String subtotalHeader;
  final String discountLabel;
  final String taxLabel;
  final String totalLabel;

  /// Template 'Pagamento: {value}' com marcador `{value}`.
  final String paymentLabelTemplate;

  /// Template 'Ref: {value}' com marcador `{value}`.
  final String referenceLabelTemplate;
  final String notesHeading;

  /// Template do rodapé com marcador `{date}`.
  final String footerTemplate;

  /// Base do nome do arquivo (ex.: 'factura'/'invoice').
  final String fileNameBase;

  /// Palavra do assunto da partilha (ex.: 'Factura'/'Invoice').
  final String subjectWord;
}

/// Exportação de facturas personalizadas para PDF.
///
/// Gera um documento A4 profissional com cabeçalho (logotipo/nome da loja),
/// dados do cliente, tabela de itens, totais e rodapé. Compartilhado
/// pelo share sheet do sistema.
class InvoicePdfExporter {
  const InvoicePdfExporter();

  /// Gera os bytes do PDF da factura.
  ///
  /// [logoBytes] — bytes da imagem do logotipo (PNG/JPEG).
  /// [primaryColor] — cor principal do template (usada no cabeçalho,
  /// tabela e totais).
  /// [templateStyle] — estilo escolhido no template: 'Classic' (padrão),
  /// 'Modern' (faixa lateral + totais em caixa) ou 'Compact' (denso).
  Future<Uint8List> buildPdf(
    CustomInvoice invoice, {
    required InvoicePdfLabels labels,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    Uint8List? logoBytes,
    PdfColor primaryColor = PdfColors.indigo700,
    String templateStyle = 'Classic',
  }) async {
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: pw.Font.ttf(data)),
    );

    // Pré-carregar o logotipo se fornecido.
    pw.ImageProvider? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(logoBytes);
    }

    // Cor escura para texto sobre fundo claro.
    final primaryDark = _darken(primaryColor);

    final invoiceNumber = invoice.number.toString().padLeft(5, '0');
    final dateLine = _formatDate(invoice.createdAt);

    final isModern = templateStyle == 'Modern';
    final isCompact = templateStyle == 'Compact';
    // Densidade vertical por estilo (Compact aperta, Modern respira).
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
          // Modern: faixa lateral colorida + fundo suave da cor do
          // template — o PDF segue o ESTILO escolhido no template.
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
                invoiceNumber: invoiceNumber,
                dateLine: dateLine,
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
              invoiceNumber: invoiceNumber,
              dateLine: dateLine,
              primaryColor: primaryColor,
              primaryDark: primaryDark,
            ),

          pw.SizedBox(height: gapSection),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: isCompact ? 8 : 16),

          // ─── Dados do Cliente ────────────────────────────────
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
            invoice.clientName,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (invoice.clientPhone.isNotEmpty)
            pw.Text(
              _fill(labels.phoneLabelTemplate, invoice.clientPhone),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientEmail.isNotEmpty)
            pw.Text(
              _fill(labels.emailLabelTemplate, invoice.clientEmail),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientAddress.isNotEmpty)
            pw.Text(
              invoice.clientAddress,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientTaxId.isNotEmpty)
            pw.Text(
              _fill(labels.taxIdLabelTemplate, invoice.clientTaxId),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
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
              for (final item in invoice.items)
                [
                  item.productName,
                  _formatQty(item.quantity, item.unit),
                  Formatters.currency(item.unitPriceCents),
                  Formatters.currency(item.subtotalCents),
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
                    if (invoice.discountCents > 0)
                      _totalRow(
                        labels.discountLabel,
                        '-${Formatters.currency(invoice.discountCents)}',
                        PdfColors.red700,
                      ),
                    if (invoice.taxCents > 0)
                      _totalRow(
                        labels.taxLabel,
                        '+${Formatters.currency(invoice.taxCents)}',
                        PdfColors.grey700,
                      ),
                    pw.Divider(color: PdfColors.grey300),
                    _totalRow(
                      labels.totalLabel,
                      Formatters.currency(invoice.totalAmountCents),
                      primaryDark,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ─── Pagamento ───────────────────────────────────────
          if (invoice.paymentMethod.isNotEmpty) ...[
            pw.SizedBox(height: gapTable),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    _fill(labels.paymentLabelTemplate, invoice.paymentMethod),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  if (invoice.paymentReference.isNotEmpty) ...[
                    pw.SizedBox(width: 12),
                    pw.Text(
                      _fill(
                        labels.referenceLabelTemplate,
                        invoice.paymentReference,
                      ),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.green800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ─── Notas ───────────────────────────────────────────
          if (invoice.notes.isNotEmpty) ...[
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
              invoice.notes,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],

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

  /// Gera e partilha o PDF da factura.
  Future<void> sharePdf(
    CustomInvoice invoice, {
    required InvoicePdfLabels labels,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    Uint8List? logoBytes,
    PdfColor primaryColor = PdfColors.indigo700,
    String templateStyle = 'Classic',
  }) async {
    final bytes = await buildPdf(
      invoice,
      labels: labels,
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      businessTaxId: businessTaxId,
      logoBytes: logoBytes,
      primaryColor: primaryColor,
      templateStyle: templateStyle,
    );
    final number = invoice.number.toString().padLeft(5, '0');
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

  /// Cabeçalho do PDF (logotipo + dados da empresa + selo do documento).
  /// Extraído para permitir variantes por ESTILO do template (Modern
  /// embrulha o cabeçalho numa faixa colorida; Classic/Compact usam
  /// o layout padrão).
  pw.Widget _header({
    required pw.ImageProvider? logoImage,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    required InvoicePdfLabels labels,
    required String invoiceNumber,
    required String dateLine,
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
              // Logotipo (se fornecido)
              if (logoImage != null) ...[
                pw.Container(
                  width: 48,
                  height: 48,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
              ],
              // Dados da empresa
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
        // Lado direito: selo do documento + nº + data
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
              labels.numberLabelTemplate.replaceFirst('{number}', invoiceNumber),
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

  String _formatQty(int millesimos, String unit) {
    if (millesimos % 1000 == 0) return '${millesimos ~/ 1000} $unit';
    return '${(millesimos / 1000).toStringAsFixed(1)} $unit';
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
