import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'pdf_accent.dart';

/// Peças COMUNS dos exporters de Factura/Cotação (`invoice_pdf_exporter` /
/// `quotation_pdf_exporter` — antes ~158 blocos idênticos de 12 linhas).
///
/// Todas as peças recebem PRIMITIVOS (texto/cor/widgets) — nenhuma entidade
/// entra aqui; cada exporter extrai os seus campos e compõe as peças. Cada
/// função é uma cópia VERBATIM de código que já renderizava os PDFs em
/// produção: migrar aqui elimina a duplicação SEM alterar o desenho.

/// Carrega as fontes Outfit e cria o documento PDF base (tema embutido).
///
/// Base = instância ESTÁTICA Regular (w400): o package `pdf` não resolve o
/// eixo `wght` da variável, cuja instância padrão é Thin (w100) — o corpo
/// do PDF sairia fino demais.
Future<pw.Document> newPdfDocument() async {
  final data = await rootBundle.load('assets/fonts/Outfit-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/Outfit-Bold.ttf');
  return pw.Document(
    theme: pw.ThemeData.withFont(
      base: pw.Font.ttf(data),
      bold: pw.Font.ttf(bold),
    ),
  );
}

/// Logotipo pré-carregado, ou `null` quando não há foto fornecida.
pw.ImageProvider? pdfLogo(Uint8List? logoBytes) {
  if (logoBytes != null && logoBytes.isNotEmpty) {
    return pw.MemoryImage(logoBytes);
  }
  return null;
}

/// Escurece uma cor PDF para usar como texto sobre fundo claro.
PdfColor pdfDarken(PdfColor color) {
  return PdfColor(
    (color.red * 0.7).clamp(0, 1),
    (color.green * 0.7).clamp(0, 1),
    (color.blue * 0.7).clamp(0, 1),
  );
}

/// Densidade vertical por ESTILO do template (Compact aperta, Modern
/// respira) — mesmos 3 estilos (Classic/Modern/Compact) nos dois
/// documentos.
({
  double gapSection,
  double gapTable,
  double tablePadding,
  bool isModern,
  bool isCompact,
})
pdfStyleGaps(String templateStyle) {
  final isModern = templateStyle == 'Modern';
  final isCompact = templateStyle == 'Compact';
  return (
    gapSection: isCompact ? 12.0 : (isModern ? 28.0 : 20.0),
    gapTable: isCompact ? 8.0 : 16.0,
    tablePadding: isCompact ? 4.0 : 6.0,
    isModern: isModern,
    isCompact: isCompact,
  );
}

/// Faixa lateral colorida do estilo MODERN (identidade do cabeçalho).
/// Container puro: Row+stretch teria altura infinita no MultiPage.
pw.Widget pdfModernHeaderBand({
  required PdfColor primaryColor,
  required pw.Widget child,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(24, 32, 32, 24),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromInt(0x0D000000 | (primaryColor.toInt() & 0x00FFFFFF)),
      border: pw.Border(left: pw.BorderSide(color: primaryColor, width: 10)),
    ),
    child: child,
  );
}

/// Cabeçalho do documento (logotipo + dados da empresa + selo do
/// documento + nº + data +, opcionalmente, chip de estado).
///
/// `statusLabel != null` obtém o chip de estado da cotação; facturas
/// passam `null` (só [dateLine] antes do rodapé do cabeçalho).
pw.Widget pdfDocumentHeader({
  required pw.ImageProvider? logoImage,
  required String businessName,
  String? businessAddress,
  String? businessPhone,
  String? businessTaxId,
  required String taxIdLabelTemplate,
  required String docWord,
  required String numberText,
  required String dateLine,
  String? statusLabel,
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
                        color: PdfAccents.black,
                      ),
                    ),
                  if (businessPhone != null && businessPhone.isNotEmpty)
                    pw.Text(
                      businessPhone,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfAccents.black,
                      ),
                    ),
                  if (businessTaxId != null && businessTaxId.isNotEmpty)
                    pw.Text(
                      pdfFill(taxIdLabelTemplate, businessTaxId),
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfAccents.black,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Lado direito: selo do documento + nº + data (+ estado)
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
              docWord,
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfAccents.ice,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            numberText,
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            dateLine,
            style: const pw.TextStyle(fontSize: 9, color: PdfAccents.black),
          ),
          if (statusLabel != null) ...[
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
        ],
      ),
    ],
  );
}

/// Tabela de itens — opções IDÊNTICAS nos dois documentos; o que muda são
/// os rótulos e as linhas (cada exporter extrai da sua entidade).
pw.Widget pdfItemsTable({
  required List<String> headers,
  required List<List<String>> rows,
  required PdfColor primaryColor,
  required double tablePadding,
}) {
  return pw.TableHelper.fromTextArray(
    headers: headers,
    data: [for (final row in rows) row],
    columnWidths: const {
      0: pw.FlexColumnWidth(),
      1: pw.FixedColumnWidth(60),
      2: pw.FixedColumnWidth(80),
      3: pw.FixedColumnWidth(80),
    },
    headerStyle: const pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfAccents.ice,
    ),
    headerDecoration: pw.BoxDecoration(color: primaryColor),
    cellStyle: const pw.TextStyle(fontSize: 9),
    cellPadding: pw.EdgeInsets.all(tablePadding),
    cellAlignments: {
      1: pw.Alignment.center,
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
    },
  );
}

/// Linha individual de total (ex.: desconto, imposto, total geral).
pw.Widget pdfTotalRow(
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

/// Bloco de TOTAIS — coluna de 220px à direita com linhas opcionais
/// ([extraRows]: desconto/imposto), divisor e o total geral em bold.
pw.Widget pdfTotalsBlock({
  required List<pw.Widget> extraRows,
  required String totalLabel,
  required String totalValue,
  required PdfColor totalColor,
}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.SizedBox(
        width: 220,
        child: pw.Column(
          children: [
            ...extraRows,
            pw.Divider(color: PdfAccents.gray),
            pdfTotalRow(totalLabel, totalValue, totalColor, isBold: true),
          ],
        ),
      ),
    ],
  );
}

/// Bloco de NOTAS — mesmo cabeçalho/tipografia nos dois documentos
/// (factura imprime `notes`; cotação imprime as condições/notas).
List<pw.Widget> pdfNotesBlock({
  required pw.Widget spacer,
  required String heading,
  required String notes,
}) {
  return [
    spacer,
    pw.Text(
      heading,
      style: const pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfAccents.gray,
      ),
    ),
    pw.SizedBox(height: 4),
    pw.Text(
      notes,
      style: const pw.TextStyle(fontSize: 9, color: PdfAccents.black),
    ),
  ];
}

/// Rodapé do documento — idêntico nos dois PDFs (data marcada no
/// [footerText] pelo chamador).
List<pw.Widget> pdfFooterBlock({required String footerText}) {
  return [
    pw.SizedBox(height: 40),
    pw.Divider(color: PdfAccents.gray),
    pw.SizedBox(height: 8),
    pw.Center(
      child: pw.Text(
        footerText,
        style: const pw.TextStyle(fontSize: 8, color: PdfAccents.gray),
      ),
    ),
  ];
}

/// Grava/grava os bytes e partilha o PDF — igual nos dois documentos
/// (web: em memória; nativo: arquivo temporário).
Future<void> sharePdfFile(
  Uint8List bytes,
  String fileName,
  String subject,
) async {
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

/// Substitui o marcador `{value}` pelo valor fornecido.
String pdfFill(String template, String value) =>
    template.replaceFirst('{value}', value);

/// Data no formato dd/mm/aaaa (com zero-padding, produção original).
String pdfFormatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Quantidade em MILÉSIMOS → texto (decimais possíveis). Sem [unit] e
/// inteiro: só o número (cotação); com [unit]: `12 kg` (factura).
String pdfFormatQty(int millesimos, [String? unit]) {
  final suffix = unit == null ? '' : ' $unit';
  if (millesimos % 1000 == 0) return '${millesimos ~/ 1000}$suffix';
  return '${(millesimos / 1000).toStringAsFixed(1)}$suffix';
}
