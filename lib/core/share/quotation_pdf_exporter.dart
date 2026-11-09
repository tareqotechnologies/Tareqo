import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_accent.dart';

import '../../domain/entities/quotation.dart';
import '../utils/formatters.dart';
import 'document_pdf_scaffold.dart';

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
/// itens. Compartilhado pelo share sheet do sistema. As PEÇAS comuns
/// vivem em [document_pdf_scaffold] — este arquivo só extrai os campos da
/// [Quotation] e compõe o layout da cotação.
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
    PdfColor primaryColor = PdfAccents.terracotta,
    String templateStyle = 'Classic',
  }) async {
    final doc = await newPdfDocument();

    final daysRemaining = quotation.validUntil
        .difference(DateTime.now())
        .inDays;
    final statusLabel = labels.statusText(quotation.status);
    final validityDaysLabel = labels.daysLeftText(daysRemaining);

    final logoImage = pdfLogo(logoBytes);

    // Cor escura para texto sobre fundo claro.
    final primaryDark = pdfDarken(primaryColor);

    final quotationNumber = quotation.number.toString().padLeft(5, '0');
    final dateLine = pdfFormatDate(quotation.createdAt);
    final validUntilLine = pdfFormatDate(quotation.validUntil);

    // Mesmos 3 estilos do template da Factura (Classic/Modern/Compact).
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
          // Modern: faixa lateral colorida + fundo suave (mesma identidade
          // da Factura) — o PDF da cotação segue o ESTILO do template.
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
                  quotationNumber,
                ),
                dateLine: dateLine,
                statusLabel: statusLabel,
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
                quotationNumber,
              ),
              dateLine: dateLine,
              statusLabel: statusLabel,
              primaryColor: primaryColor,
              primaryDark: primaryDark,
            ),

          pw.SizedBox(height: gapSection),
          pw.Divider(color: PdfAccents.gray),
          pw.SizedBox(height: style.isCompact ? 8 : 16),

          // ─── Dados do Cliente + Validade ─────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      labels.clientHeading,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfAccents.gray,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      quotation.customerName,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (quotation.customerPhone.isNotEmpty)
                      pw.Text(
                        pdfFill(
                          labels.phoneLabelTemplate,
                          quotation.customerPhone,
                        ),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfAccents.black,
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
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfAccents.gray,
                    ),
                  ),
                  pw.Text(
                    validUntilLine,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: daysRemaining <= 3
                          ? PdfAccents.alertError
                          : PdfAccents.black,
                    ),
                  ),
                  pw.Text(
                    validityDaysLabel,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: daysRemaining <= 3
                          ? PdfAccents.alertError
                          : PdfAccents.gray,
                    ),
                  ),
                ],
              ),
            ],
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
              for (final item in quotation.items)
                [
                  item.productName,
                  pdfFormatQty(item.quantity),
                  Formatters.currency(item.unitPriceCents),
                  Formatters.currency(
                    item.quantity * item.unitPriceCents ~/ 1000,
                  ),
                ],
            ],
            primaryColor: primaryColor,
            tablePadding: style.tablePadding,
          ),

          pw.SizedBox(height: gapTable),

          // ─── Totais ──────────────────────────────────────────
          pdfTotalsBlock(
            extraRows: [
              if (quotation.discountCents > 0)
                pdfTotalRow(
                  labels.discountLabel,
                  '-${Formatters.currency(quotation.discountCents)}',
                  PdfAccents.alertError,
                ),
            ],
            totalLabel: labels.totalLabel,
            totalValue: Formatters.currency(quotation.totalAmountCents),
            totalColor: primaryDark,
          ),

          // ─── Notas ───────────────────────────────────────────
          if (quotation.notes.isNotEmpty)
            ...pdfNotesBlock(
              spacer: pw.SizedBox(height: gapTable),
              heading: labels.notesHeading,
              notes: quotation.notes,
            ),

          // ─── Condições Gerais ────────────────────────────────
          pw.SizedBox(height: gapSection),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfAccents.ice,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  labels.generalConditionsHeading,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfAccents.black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '• ${labels.validConditionTemplate.replaceFirst('{date}', validUntilLine)}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfAccents.gray,
                  ),
                ),
                pw.Text(
                  '• ${labels.pricesConditionText}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfAccents.gray,
                  ),
                ),
                pw.Text(
                  '• ${labels.contactConditionText}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfAccents.gray,
                  ),
                ),
              ],
            ),
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

  /// Gera e partilha o PDF da cotação.
  Future<void> sharePdf(
    Quotation quotation, {
    required QuotationPdfLabels labels,
    required String businessName,
    String? businessAddress,
    String? businessPhone,
    String? businessTaxId,
    Uint8List? logoBytes,
    PdfColor primaryColor = PdfAccents.terracotta,
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
    await sharePdfFile(bytes, fileName, subject);
  }
}
