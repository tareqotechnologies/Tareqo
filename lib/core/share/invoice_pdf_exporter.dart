import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/custom_invoice.dart';
import '../utils/formatters.dart';
import 'document_pdf_scaffold.dart';
import 'pdf_accent.dart';

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
/// pelo share sheet do sistema. As PEÇAS comuns vivem em
/// [document_pdf_scaffold] — este arquivo só extrai os campos da
/// [CustomInvoice] e compõe o layout da factura.
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
    PdfColor primaryColor = PdfAccents.slate,
    String templateStyle = 'Classic',
  }) async {
    final doc = await newPdfDocument();

    final logoImage = pdfLogo(logoBytes);

    // Cor escura para texto sobre fundo claro.
    final primaryDark = pdfDarken(primaryColor);

    final invoiceNumber = invoice.number.toString().padLeft(5, '0');
    final dateLine = pdfFormatDate(invoice.createdAt);

    final style = pdfStyleGaps(templateStyle);
    final gapSection = style.gapSection;
    final gapTable = style.gapTable;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.fromLTRB(
          style.isModern ? 0 : 32,
          32,
          style.isModern ? 0 : 32,
          32,
        ),
        build: (context) => [
          // ─── Cabeçalho ───────────────────────────────────────
          // Modern: faixa lateral colorida + fundo suave da cor do
          // template — o PDF segue o ESTILO escolhido no template.
          if (style.isModern)
            pdfModernHeaderBand(
              primaryColor: primaryColor,
              child: pdfDocumentHeader(
                logoImage: logoImage,
                businessName: businessName,
                businessAddress: businessAddress,
                businessPhone: businessPhone,
                businessTaxId: businessTaxId,
                taxIdLabelTemplate: labels.taxIdLabelTemplate,
                docWord: labels.docWord,
                numberText: labels.numberLabelTemplate.replaceFirst(
                  '{number}',
                  invoiceNumber,
                ),
                dateLine: dateLine,
                primaryColor: primaryColor,
                primaryDark: primaryDark,
              ),
            )
          else
            pdfDocumentHeader(
              logoImage: logoImage,
              businessName: businessName,
              businessAddress: businessAddress,
              businessPhone: businessPhone,
              businessTaxId: businessTaxId,
              taxIdLabelTemplate: labels.taxIdLabelTemplate,
              docWord: labels.docWord,
              numberText: labels.numberLabelTemplate.replaceFirst(
                '{number}',
                invoiceNumber,
              ),
              dateLine: dateLine,
              primaryColor: primaryColor,
              primaryDark: primaryDark,
            ),

          pw.SizedBox(height: gapSection),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: style.isCompact ? 8 : 16),

          // ─── Dados do Cliente ────────────────────────────────
          pw.Text(
            labels.clientHeading,
            style: const pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            invoice.clientName,
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (invoice.clientPhone.isNotEmpty)
            pw.Text(
              pdfFill(labels.phoneLabelTemplate, invoice.clientPhone),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientEmail.isNotEmpty)
            pw.Text(
              pdfFill(labels.emailLabelTemplate, invoice.clientEmail),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientAddress.isNotEmpty)
            pw.Text(
              invoice.clientAddress,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          if (invoice.clientTaxId.isNotEmpty)
            pw.Text(
              pdfFill(labels.taxIdLabelTemplate, invoice.clientTaxId),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),

          pw.SizedBox(height: gapSection),

          // ─── Tabela de Itens ─────────────────────────────────
          pdfItemsTable(
            headers: [
              labels.itemHeader,
              labels.qtyHeader,
              labels.unitPriceHeader,
              labels.subtotalHeader,
            ],
            rows: [
              for (final item in invoice.items)
                [
                  item.productName,
                  pdfFormatQty(item.quantity, item.unit),
                  Formatters.currency(item.unitPriceCents),
                  Formatters.currency(item.subtotalCents),
                ],
            ],
            primaryColor: primaryColor,
            tablePadding: style.tablePadding,
          ),

          pw.SizedBox(height: gapTable),

          // ─── Totais ──────────────────────────────────────────
          pdfTotalsBlock(
            extraRows: [
              if (invoice.discountCents > 0)
                pdfTotalRow(
                  labels.discountLabel,
                  '-${Formatters.currency(invoice.discountCents)}',
                  PdfColors.red700,
                ),
              if (invoice.taxCents > 0)
                pdfTotalRow(
                  labels.taxLabel,
                  '+${Formatters.currency(invoice.taxCents)}',
                  PdfColors.grey700,
                ),
            ],
            totalLabel: labels.totalLabel,
            totalValue: Formatters.currency(invoice.totalAmountCents),
            totalColor: primaryDark,
          ),

          // ─── Pagamento ───────────────────────────────────────
          if (invoice.paymentMethod.isNotEmpty) ...[
            pw.SizedBox(height: gapTable),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfAccents.paymentSurface,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    pdfFill(labels.paymentLabelTemplate, invoice.paymentMethod),
                    style: const pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfAccents.paymentText,
                    ),
                  ),
                  if (invoice.paymentReference.isNotEmpty) ...[
                    pw.SizedBox(width: 12),
                    pw.Text(
                      pdfFill(
                        labels.referenceLabelTemplate,
                        invoice.paymentReference,
                      ),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfAccents.paymentTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ─── Notas ───────────────────────────────────────────
          if (invoice.notes.isNotEmpty)
            ...pdfNotesBlock(
              spacer: pw.SizedBox(height: gapTable),
              heading: labels.notesHeading,
              notes: invoice.notes,
            ),

          // ─── Rodapé ──────────────────────────────────────────
          ...pdfFooterBlock(
            footerText: labels.footerTemplate.replaceFirst('{date}', dateLine),
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
    PdfColor primaryColor = PdfAccents.slate,
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
    await sharePdfFile(bytes, fileName, subject);
  }
}
