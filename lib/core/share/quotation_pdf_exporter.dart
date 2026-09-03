import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/quotation.dart';
import '../utils/formatters.dart';

/// Exportação de cotações/orçamentos para PDF.
///
/// Gera um documento A4 profissional com validade, condições e tabela de
/// itens. Compartilhado pelo share sheet do sistema.
class QuotationPdfExporter {
  const QuotationPdfExporter();

  /// Gera os bytes do PDF da cotação.
  Future<Uint8List> buildPdf(
    Quotation quotation, {
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    Uint8List? logoBytes,
    PdfColor primaryColor = PdfColors.amber700,
  }) async {
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: pw.Font.ttf(data)),
    );

    final daysRemaining =
        quotation.validUntil.difference(DateTime.now()).inDays;
    final statusLabel = switch (quotation.status) {
      QuotationStatus.draft => 'Rascunho',
      QuotationStatus.sent => 'Enviada',
      QuotationStatus.accepted => 'Aceite',
      QuotationStatus.rejected => 'Rejeitada',
      QuotationStatus.expired => 'Expirada',
      QuotationStatus.converted => 'Convertida em Venda',
    };

    // Pré-carregar o logotipo se fornecido.
    pw.ImageProvider? logoImage;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      logoImage = pw.MemoryImage(logoBytes);
    }

    // Cor escura para texto sobre fundo claro.
    final primaryDark = _darken(primaryColor);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ─── Cabeçalho ───────────────────────────────────────
          pw.Row(
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
                        child:
                            pw.Image(logoImage, fit: pw.BoxFit.contain),
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
                          if (businessAddress != null &&
                              businessAddress.isNotEmpty)
                            pw.Text(
                              businessAddress,
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          if (businessPhone != null &&
                              businessPhone.isNotEmpty)
                            pw.Text(
                              businessPhone,
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          if (businessTaxId != null &&
                              businessTaxId.isNotEmpty)
                            pw.Text(
                              'NIF: $businessTaxId',
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
              // Lado direito: badge COTAÇÃO + nº + data + estado
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'COTAÇÃO',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Nº ${quotation.number.toString().padLeft(5, '0')}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatDate(quotation.createdAt),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 16),

          // ─── Dados do Cliente ────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLIENTE',
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
                        'Tel: ${quotation.customerPhone}',
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
                    'Validade',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    _formatDate(quotation.validUntil),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: daysRemaining <= 3
                          ? PdfColors.red700
                          : PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    daysRemaining > 0
                        ? '$daysRemaining dias restantes'
                        : 'Expirada',
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

          pw.SizedBox(height: 20),

          // ─── Tabela de Itens ─────────────────────────────────
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Qtd', 'Preço Unit.', 'Subtotal'],
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
            headerDecoration: pw.BoxDecoration(
              color: primaryColor,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding: const pw.EdgeInsets.all(6),
            cellAlignments: {
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
          ),

          pw.SizedBox(height: 16),

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
                        'Desconto',
                        '-${Formatters.currency(quotation.discountCents)}',
                        PdfColors.red700,
                      ),
                    pw.Divider(color: PdfColors.grey300),
                    _totalRow(
                      'TOTAL',
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
            pw.SizedBox(height: 16),
            pw.Text(
              'Condições / Notas',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              quotation.notes,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],

          // ─── Condições Gerais ────────────────────────────────
          pw.SizedBox(height: 20),
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
                  'Condições Gerais',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '• Esta cotação é válida até ${_formatDate(quotation.validUntil)}.',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '• Preços sujeitos a alteração após o prazo de validade.',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  '• Para aceitar esta cotação, entre em contacto connosco.',
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
              'Documento gerado pelo TAREQO — ${_formatDate(quotation.createdAt)}',
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

  /// Gera e partilha o PDF da cotação.
  Future<void> sharePdf(
    Quotation quotation, {
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    Uint8List? logoBytes,
    PdfColor primaryColor = PdfColors.amber700,
  }) async {
    final bytes = await buildPdf(
      quotation,
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      businessTaxId: businessTaxId,
      logoBytes: logoBytes,
      primaryColor: primaryColor,
    );
    final fileName =
        'cotacao_${quotation.number.toString().padLeft(5, '0')}.pdf';
    await _share(bytes, fileName);
  }

  Future<void> _share(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: fileName,
            ),
          ],
          subject: 'Cotação $fileName',
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
        subject: 'Cotação $fileName',
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatQty(int millesimos) {
    if (millesimos % 1000 == 0) return '${millesimos ~/ 1000}';
    return (millesimos / 1000).toStringAsFixed(1);
  }

  pw.Widget _totalRow(String label, String value, PdfColor color,
      {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 12 : 9,
              fontWeight:
                  isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 14 : 10,
              fontWeight:
                  isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
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
