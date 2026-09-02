import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/custom_invoice.dart';
import '../utils/formatters.dart';

/// Exportação de facturas personalizadas para PDF.
///
/// Gera um documento A4 profissional com cabeçalho (logotipo/nome da loja),
/// dados do cliente, tabela de itens, totais e rodapé. Compartilhado
/// pelo share sheet do sistema.
class InvoicePdfExporter {
  const InvoicePdfExporter();

  /// Gera os bytes do PDF da factura.
  Future<Uint8List> buildPdf(
    CustomInvoice invoice, {
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
  }) async {
    final data = await rootBundle.load('assets/fonts/Inter-Variable.ttf');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: pw.Font.ttf(data)),
    );

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
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo900,
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
                      'NIF: $businessTaxId',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo700,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      'FACTURA',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Nº ${invoice.number.toString().padLeft(5, '0')}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _formatDate(invoice.createdAt),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
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
            invoice.clientName,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (invoice.clientPhone.isNotEmpty)
            pw.Text(
              'Tel: ${invoice.clientPhone}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientEmail.isNotEmpty)
            pw.Text(
              'Email: ${invoice.clientEmail}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientAddress.isNotEmpty)
            pw.Text(
              invoice.clientAddress,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientTaxId.isNotEmpty)
            pw.Text(
              'NIF: ${invoice.clientTaxId}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),

          pw.SizedBox(height: 20),

          // ─── Tabela de Itens ─────────────────────────────────
          pw.TableHelper.fromTextArray(
            headers: ['Item', 'Qtd', 'Preço Unit.', 'Subtotal'],
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
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.indigo700,
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
                    if (invoice.discountCents > 0)
                      _totalRow(
                        'Desconto',
                        '-${Formatters.currency(invoice.discountCents)}',
                        PdfColors.red700,
                      ),
                    if (invoice.taxCents > 0)
                      _totalRow(
                        'IVA',
                        '+${Formatters.currency(invoice.taxCents)}',
                        PdfColors.grey700,
                      ),
                    pw.Divider(color: PdfColors.grey300),
                    _totalRow(
                      'TOTAL',
                      Formatters.currency(invoice.totalAmountCents),
                      PdfColors.indigo900,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ─── Pagamento ───────────────────────────────────────
          if (invoice.paymentMethod.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Pagamento: ${invoice.paymentMethod}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  if (invoice.paymentReference.isNotEmpty) ...[
                    pw.SizedBox(width: 12),
                    pw.Text(
                      'Ref: ${invoice.paymentReference}',
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
            pw.SizedBox(height: 16),
            pw.Text(
              'Notas',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.notes,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],

          // ─── Rodapé ──────────────────────────────────────────
          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Documento gerado pelo TAREQO — ${_formatDate(invoice.createdAt)}',
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

  /// Gera e partilha o PDF da factura.
  Future<void> sharePdf(
    CustomInvoice invoice, {
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
  }) async {
    final bytes = await buildPdf(
      invoice,
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
      businessTaxId: businessTaxId,
    );
    final fileName = 'factura_${invoice.number.toString().padLeft(5, '0')}.pdf';
    await _share(bytes, fileName);
  }

  Future<void> _share(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName),
          ],
          subject: 'Factura $fileName',
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
        subject: 'Factura $fileName',
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatQty(int millesimos, String unit) {
    if (millesimos % 1000 == 0) return '${millesimos ~/ 1000} $unit';
    return '${(millesimos / 1000).toStringAsFixed(1)} $unit';
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
}
