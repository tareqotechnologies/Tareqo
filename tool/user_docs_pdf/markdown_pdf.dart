// Gerador de PDF para os documentos de suporte ao utilizador final
// (Guia do Usuário + Troubleshooting, pt/en) — PARTE 1: biblioteca.
//
// Puro Dart (só depende de package:pdf), usado pelo CLI
// `tool/generate_user_docs_pdf.dart` e pelos testes em
// `tool/generate_docs_pdf_test.dart` (corrida manual, como
// generate_icons_test.dart — não entra na suíte `flutter test`).
//
// Design (espelho do design system "ultra-clean" do app):
//   - Capa escura (fundo #161D22) com o acento verde da marca e título leve;
//   - Índice com números de página — calculado em DOIS PASSOS (o pacote pdf
//     não sabe a página de um heading antes de renderizar; um widget sonda
//     `context.pageNumber` durante o layout do 1.º passe e o 2.º passe
//     desenha os números reais);
//   - Conteúdo em páginas CLARAS (impressão/leitura): cabeçalhos com régua
//     verde, listas, citações, regras, tabelas com cabeçalho tingido;
//   - Marcadores de navegação (bookmarks) via `pw.Outline`;
//   - Glifos sem suporte na fonte (emoji, símbolos raros) são removidos
//     usando o cmap da Inter (TtfParser.charToGlyphIndexMap) — nunca fica
//     um quadrado vazio no PDF.
import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ---------------------------------------------------------------------------
// Cores da marca (idênticas ao AppTheme — lib/core/theme/app_theme.dart)
// ---------------------------------------------------------------------------

/// Fundo escuro da capa (surface escura do tema do app).
const PdfColor coverBg = PdfColor.fromInt(0xFF161D22);

/// Acento verde da marca.
const PdfColor accent = PdfColor.fromInt(0xFF22C55E);

/// Verde escuro (texto/link sobre fundo claro — primary do tema).
const PdfColor accentDark = PdfColor.fromInt(0xFF15803D);

/// Texto principal sobre fundo claro.
const PdfColor textColor = PdfColor.fromInt(0xFF1A1C1B);

/// Texto secundário (legendas, meta).
const PdfColor textMuted = PdfColor.fromInt(0xFF5F6B64);

/// Cinza claro de fundos de citação.
const PdfColor quoteBg = PdfColor.fromInt(0xFFF1F3F2);

/// Verde-água claro do cabeçalho das tabelas (secondaryContainer).
const PdfColor tableHeadBg = PdfColor.fromInt(0xFFD6F5E0);

/// Borda suave (outlineVariant claro).
const PdfColor borderColor = PdfColor.fromInt(0xFFD9DEDB);

/// Cinza claro (texto da capa, notas).
const PdfColor onCoverMuted = PdfColor.fromInt(0xFFA1A1AA);

/// Branco (texto da capa).
const PdfColor onCover = PdfColor.fromInt(0xFFF4F4F5);

// ---------------------------------------------------------------------------
// Modelo do documento
// ---------------------------------------------------------------------------

enum MdBlockKind { heading, paragraph, list, quote, table, hr }

class MdHeading {
  const MdHeading(this.level, this.text);
  final int level; // 2 ou 3 (o H1 é o título do documento)
  final String text;
}

class MdListItem {
  const MdListItem({required this.indent, required this.text});
  final int indent; // 0 = nível superior; 1 = sub-item
  final String text;
}

class MdBlock {
  const MdBlock.heading(MdHeading this.heading)
    : kind = MdBlockKind.heading,
      text = null,
      items = const [],
      quote = null,
      headers = const [],
      rows = const [],
      ordered = false;
  const MdBlock.paragraph(String this.text)
    : kind = MdBlockKind.paragraph,
      heading = null,
      items = const [],
      quote = null,
      headers = const [],
      rows = const [],
      ordered = false;
  const MdBlock.list({required this.ordered, required this.items})
    : kind = MdBlockKind.list,
      heading = null,
      text = null,
      quote = null,
      headers = const [],
      rows = const [];
  const MdBlock.quote(String this.quote)
    : kind = MdBlockKind.quote,
      heading = null,
      text = null,
      items = const [],
      headers = const [],
      rows = const [],
      ordered = false;
  const MdBlock.table(this.headers, this.rows)
    : kind = MdBlockKind.table,
      heading = null,
      text = null,
      items = const [],
      quote = null,
      ordered = false;
  const MdBlock.hr()
    : kind = MdBlockKind.hr,
      heading = null,
      text = null,
      items = const [],
      quote = null,
      headers = const [],
      rows = const [],
      ordered = false;

  final MdBlockKind kind;
  final MdHeading? heading;
  final String? text;
  final bool ordered;
  final List<MdListItem> items;
  final String? quote;
  final List<String> headers;
  final List<List<String>> rows;
}

class DocModel {
  DocModel({
    required this.title,
    required this.intro,
    required this.blocks,
    required this.toc,
  });

  /// Título do documento (H1, sem o sufixo "— Dumbhanengue ERP").
  final String title;

  /// Parágrafo de apresentação logo após o H1 (vira subtítulo da capa).
  final String? intro;

  /// Todos os blocos após o H1/intro.
  final List<MdBlock> blocks;

  /// Entradas do índice (H2 + H3, na ordem do documento).
  final List<MdHeading> toc;
}

// ---------------------------------------------------------------------------
// Emoji / glifos sem suporte na fonte
// ---------------------------------------------------------------------------

/// Emoji e símbolos decorativos removidos do texto impresso (a Inter não tem
/// esses glifos; o texto que os acompanha preserva o significado).
final RegExp _emojiRe = RegExp(
  r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{200D}]',
  unicode: true,
);

String stripEmoji(String s) => s.replaceAll(_emojiRe, '');

/// Remove runes que a fonte embutida não cobre (cmap da Inter). Retorna o
/// texto pronto para o PDF — sem quadrados vazios. Quebras de linha e tabs
/// são mantidas (são comandos de layout, não glifos).
String filterGlyphs(String s, TtfParser font) {
  final out = StringBuffer();
  for (final rune in s.runes) {
    if (rune == 0x0A || rune == 0x0D || rune == 0x09) {
      out.writeCharCode(rune);
    } else if (font.charToGlyphIndexMap.containsKey(rune)) {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}

/// Aplica `f` a todos os textos do modelo (título, intro, índice, blocos).
/// Usado para remover glifos sem suporte na fonte embutida antes do PDF.
DocModel sanitizeDoc(DocModel doc, String Function(String) f) {
  return DocModel(
    title: f(doc.title),
    intro: doc.intro == null ? null : f(doc.intro!),
    toc: [for (final h in doc.toc) MdHeading(h.level, f(h.text))],
    blocks: [
      for (final b in doc.blocks)
        switch (b.kind) {
          MdBlockKind.heading => MdBlock.heading(
            MdHeading(b.heading!.level, f(b.heading!.text)),
          ),
          MdBlockKind.paragraph => MdBlock.paragraph(f(b.text!)),
          MdBlockKind.list => MdBlock.list(
            ordered: b.ordered,
            items: [
              for (final it in b.items)
                MdListItem(indent: it.indent, text: f(it.text)),
            ],
          ),
          MdBlockKind.quote => MdBlock.quote(f(b.quote!)),
          MdBlockKind.table => MdBlock.table(
            [for (final h in b.headers) f(h)],
            [
              for (final r in b.rows) [for (final c in r) f(c)],
            ],
          ),
          MdBlockKind.hr => const MdBlock.hr(),
        },
    ],
  );
}

// ---------------------------------------------------------------------------
// Parser markdown (subconjunto usado pelos documentos)
// ---------------------------------------------------------------------------

final RegExp _headingRe = RegExp(r'^(#{1,3})\s+(.*)$');
final RegExp _hrRe = RegExp(r'^(-{3,}|\*{3,}|_{3,})$');
final RegExp _listBulletRe = RegExp(r'^( *)[-*]\s+(.*)$');
final RegExp _listOrderedRe = RegExp(r'^( *)\d+\.\s+(.*)$');

/// Divide uma linha de tabela `| a | b |` em células (removendo espaços).
List<String> _splitRow(String line) {
  final t = line.trim();
  final inner = t.startsWith('|') ? t.substring(1) : t;
  final end = inner.endsWith('|')
      ? inner.substring(0, inner.length - 1)
      : inner;
  return end.split('|').map((c) => c.trim()).toList();
}

DocModel parseMarkdown(String source) {
  final lines = const LineSplitter().convert(source);
  final blocks = <MdBlock>[];
  final toc = <MdHeading>[];
  String? title;
  String? intro;
  var i = 0;

  while (i < lines.length) {
    final t = lines[i].trim();

    if (t.isEmpty) {
      i++;
      continue;
    }

    // -- Cabeçalho ---------------------------------------------------------
    final h = _headingRe.firstMatch(t);
    if (h != null) {
      final level = h.group(1)!.length;
      final text = stripEmoji(h.group(2)!.trim());
      if (level == 1) {
        title = text;
      } else {
        final hd = MdHeading(level, text);
        blocks.add(MdBlock.heading(hd));
        if (level == 2 || level == 3) {
          toc.add(hd);
        }
      }
      i++;
      continue;
    }

    // -- Regra horizontal --------------------------------------------------
    if (_hrRe.hasMatch(t)) {
      blocks.add(const MdBlock.hr());
      i++;
      continue;
    }

    // -- Citação (bloco `>`) ----------------------------------------------
    if (t.startsWith('>')) {
      final q = <String>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
        q.add(lines[i].trimLeft().substring(1).trim());
        i++;
      }
      blocks.add(MdBlock.quote(stripEmoji(q.join('\n'))));
      continue;
    }

    // -- Tabela ------------------------------------------------------------
    if (t.startsWith('|')) {
      final header = _splitRow(lines[i]).map(stripEmoji).toList();
      i++;
      // Linha separadora `|---|---|`
      if (i < lines.length &&
          lines[i].trim().contains('-') &&
          RegExp(r'^\|?[\s:\-|]+\|?$').hasMatch(lines[i].trim())) {
        i++;
      }
      final rows = <List<String>>[];
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        rows.add(_splitRow(lines[i]).map(stripEmoji).toList());
        i++;
      }
      blocks.add(MdBlock.table(header, rows));
      continue;
    }

    // -- Lista -------------------------------------------------------------
    final firstBullet = _listBulletRe.firstMatch(lines[i]);
    final firstOrdered = _listOrderedRe.firstMatch(lines[i]);
    if (firstBullet != null || firstOrdered != null) {
      final ordered = firstOrdered != null;
      final items = <MdListItem>[];
      while (i < lines.length) {
        final b = _listBulletRe.firstMatch(lines[i]);
        final o = _listOrderedRe.firstMatch(lines[i]);
        if (b == null && o == null) break;
        final m = (b ?? o)!;
        final indent = m.group(1)!.length ~/ 2;
        items.add(MdListItem(indent: indent, text: stripEmoji(m.group(2)!)));
        i++;
      }
      blocks.add(MdBlock.list(ordered: ordered, items: items));
      continue;
    }

    // -- Parágrafo ---------------------------------------------------------
    final p = <String>[];
    while (i < lines.length) {
      final l = lines[i];
      if (l.trim().isEmpty) break;
      if (_headingRe.hasMatch(l.trim())) break;
      if (l.trimLeft().startsWith('>')) break;
      if (l.trim().startsWith('|')) break;
      if (_listBulletRe.hasMatch(l) || _listOrderedRe.hasMatch(l)) break;
      if (_hrRe.hasMatch(l.trim())) break;
      p.add(l.trim());
      i++;
    }
    final ptext = stripEmoji(p.join('\n'));
    if (title != null && blocks.isEmpty && intro == null) {
      intro = ptext; // parágrafo de apresentação após o H1
    } else {
      blocks.add(MdBlock.paragraph(ptext));
    }
  }

  return DocModel(
    title: title ?? 'Dumbhanengue ERP',
    intro: intro,
    blocks: blocks,
    toc: toc,
  );
}

// ---------------------------------------------------------------------------
// Formatação inline (negrito, código, links)
// ---------------------------------------------------------------------------

final RegExp _inlineRe = RegExp(
  r'\*\*(.+?)\*\*|`([^`]+)`|\[([^\]]+)\]\(([^)]+)\)',
);

/// Converte `**negrito**`, `` `código` `` e `[texto](url)` em spans.
List<pw.TextSpan> parseInline(String raw, {required pw.TextStyle base}) {
  final spans = <pw.TextSpan>[];
  var last = 0;
  for (final m in _inlineRe.allMatches(raw)) {
    if (m.start > last) {
      spans.add(pw.TextSpan(text: raw.substring(last, m.start), style: base));
    }
    if (m.group(1) != null) {
      spans.add(
        pw.TextSpan(
          text: m.group(1),
          style: base.copyWith(fontWeight: pw.FontWeight.bold),
        ),
      );
    } else if (m.group(2) != null) {
      spans.add(
        pw.TextSpan(
          text: m.group(2),
          style: base.copyWith(color: accentDark),
        ),
      );
    } else {
      spans.add(
        pw.TextSpan(
          text: m.group(3),
          style: base.copyWith(
            color: accentDark,
            decoration: pw.TextDecoration.underline,
          ),
        ),
      );
    }
    last = m.end;
  }
  if (last < raw.length) {
    spans.add(pw.TextSpan(text: raw.substring(last), style: base));
  }
  return spans;
}

// ---------------------------------------------------------------------------
// Sonda de página (1.º passe do índice)
// ---------------------------------------------------------------------------

/// Widget invisível que regista a página em que o heading ficou durante o
/// layout (`context.pageNumber` é a página real do `MultiPage`).
class PageProbe extends pw.StatelessWidget {
  PageProbe({required this.id, required this.onPage, required this.child});

  final String id;
  final void Function(String id, int page) onPage;
  final pw.Widget child;

  @override
  pw.Widget build(pw.Context context) {
    onPage(id, context.pageNumber);
    return child;
  }
}

// ---------------------------------------------------------------------------
// Construtor do documento
// ---------------------------------------------------------------------------

pw.Document buildDoc({
  required pw.Font font,
  required DocModel doc,
  required String docName,
  required String appName,
  required String subtitle,
  required String metaLine,
  required String tocTitle,
  required Map<String, int>? tocPages,
  void Function(String id, int page)? onProbe,
  void Function(int page)? onFooterPage,
}) {
  final doc2 = pw.Document(
    // `bold: font`: a Inter é variável (eixo wght) e o dart_pdf não seleciona
    // o eixo — sem `fontBold` explícito, textos BOLD perdiam a fonte (o
    // resolvedor caía no fallback e glifos como o bullet `•` sumiam). Com
    // `bold: font`, o bold usa a MESMA fonte (peso visual da base, como o
    // report_exporter já documenta) e nenhum glifo se perde.
    theme: pw.ThemeData.withFont(base: font, bold: font),
    title: docName,
    author: appName,
  );

  // -- CAPA -----------------------------------------------------------------
  doc2.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        buildBackground: (ctx) => pw.Container(color: coverBg),
      ),
      build: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
        child: pw.Column(
          children: [
            pw.Spacer(flex: 2),
            // Marca: quadrado verde arredondado com a inicial.
            pw.Container(
              width: 64,
              height: 64,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Text(
                'D',
                style: pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: onCover,
                ),
              ),
            ),
            pw.SizedBox(height: 28),
            pw.Text(
              appName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 13,
                letterSpacing: 4,
                color: onCoverMuted,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              doc.title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 32, color: onCover, lineSpacing: 6),
            ),
            pw.SizedBox(height: 12),
            if (subtitle.isNotEmpty)
              pw.Text(
                subtitle,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 12.5, color: onCoverMuted),
              ),
            pw.Spacer(flex: 3),
            pw.Text(
              metaLine,
              style: const pw.TextStyle(fontSize: 10, color: onCoverMuted),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Dumbhanengue ERP',
              style: const pw.TextStyle(fontSize: 9, color: onCoverMuted),
            ),
          ],
        ),
      ),
    ),
  );

  // -- ÍNDICE (dois passes: placeholder sem números → números reais) --------
  final tocEntries = doc.toc;

  doc2.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 34),
      footer: (ctx) {
        onFooterPage?.call(ctx.pageNumber);
        return _footer(docName);
      },
      build: (ctx) => [
        pw.Text(
          tocTitle,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: accent),
        pw.SizedBox(height: 18),
        for (var i = 0; i < tocEntries.length; i++)
          _tocRow(
            index: i,
            heading: tocEntries[i],
            page: tocPages?[tocEntryId(i)],
          ),
        if (tocEntries.isEmpty)
          pw.Text('—', style: const pw.TextStyle(color: textMuted)),
      ],
    ),
  );

  // -- CONTEÚDO --------------------------------------------------------------
  doc2.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 34),
      footer: (ctx) {
        onFooterPage?.call(ctx.pageNumber);
        return _footer(docName);
      },
      build: (ctx) {
        final widgets = <pw.Widget>[];
        // Ids unificados com o índice: `t<indice>` — a sonda do 1.º passe
        // regista exatamente a chave que o índice procura no 2.º passe.
        var tocIndex = 0;
        for (final block in doc.blocks) {
          switch (block.kind) {
            case MdBlockKind.heading:
              final h = block.heading!;
              if (h.level == 2) {
                widgets.add(
                  _heading2(
                    id: tocEntryId(tocIndex),
                    heading: h,
                    onProbe: onProbe,
                  ),
                );
                tocIndex++;
              } else {
                widgets.add(
                  _heading3(
                    id: tocEntryId(tocIndex),
                    heading: h,
                    onProbe: onProbe,
                  ),
                );
                tocIndex++;
              }
            case MdBlockKind.paragraph:
              widgets.add(_paragraph(block.text!));
            case MdBlockKind.list:
              widgets.add(_list(block));
            case MdBlockKind.quote:
              widgets.add(_quote(block.quote!));
            case MdBlockKind.table:
              widgets.add(_table(block));
            case MdBlockKind.hr:
              widgets.add(
                pw.Container(
                  height: 0.6,
                  color: borderColor,
                  margin: const pw.EdgeInsets.symmetric(vertical: 12),
                ),
              );
          }
        }
        return widgets;
      },
    ),
  );

  return doc2;
}

/// Dois passes: 1.º recolhe heading→página via `PageProbe`; 2.º desenha o
/// índice com os números reais. Devolve os bytes e a contagem de páginas.
Future<(Uint8List, int)> generatePdf({
  required Uint8List fontData,
  required DocModel doc,
  required String docName,
  required String appName,
  required String subtitle,
  required String metaLine,
  required String tocTitle,
}) async {
  final font = pw.Font.ttf(ByteData.sublistView(fontData));
  final pages = <String, int>{};

  // 1.º passe — índice placeholder + sonda de página.
  final pass1 = buildDoc(
    font: font,
    doc: doc,
    docName: docName,
    appName: appName,
    subtitle: subtitle,
    metaLine: metaLine,
    tocTitle: tocTitle,
    tocPages: null,
    onProbe: (id, page) => pages[id] = page,
  );
  await pass1.save();

  // 2.º passe — índice com números reais (contagem fiável via footer).
  var pageCount = 0;
  final pass2 = buildDoc(
    font: font,
    doc: doc,
    docName: docName,
    appName: appName,
    subtitle: subtitle,
    metaLine: metaLine,
    tocTitle: tocTitle,
    tocPages: pages,
    onProbe: null,
    onFooterPage: (page) => pageCount = page,
  );
  final bytes = await pass2.save();
  return (bytes, pageCount);
}

String tocEntryId(int index) => 't$index';

// ---------------------------------------------------------------------------
// Widgets de conteúdo
// ---------------------------------------------------------------------------

pw.Widget _footer(String docName) => pw.Container(
  alignment: pw.Alignment.center,
  padding: const pw.EdgeInsets.only(top: 6),
  child: pw.Text(
    '$docName  ·  Dumbhanengue ERP',
    style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
  ),
);

pw.Widget _tocRow({
  required int index,
  required MdHeading heading,
  required int? page,
}) {
  final isH2 = heading.level == 2;
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 7),
    padding: isH2 ? pw.EdgeInsets.zero : const pw.EdgeInsets.only(left: 16),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Text(
            heading.text,
            style: pw.TextStyle(
              fontSize: isH2 ? 11.5 : 10,
              fontWeight: isH2 ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isH2 ? textColor : textMuted,
              lineSpacing: 2,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          page != null ? '$page' : '·',
          style: const pw.TextStyle(fontSize: 10.5, color: accentDark),
        ),
      ],
    ),
  );
}

pw.Widget _heading2({
  required String id,
  required MdHeading heading,
  required void Function(String id, int page)? onProbe,
}) {
  final content = pw.Container(
    margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
    padding: const pw.EdgeInsets.only(left: 10),
    decoration: const pw.BoxDecoration(
      border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(
          fontSize: 15.5,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
          lineSpacing: 3,
        ),
        children: parseInline(
          heading.text,
          base: pw.TextStyle(
            fontSize: 15.5,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    ),
  );
  // `Outline` SEMPRE (bookmarks no PDF final — os bytes do 1.º passe são
  // descartados); a sonda é que só existe no 1.º passe.
  final child = onProbe == null
      ? content
      : PageProbe(id: id, onPage: onProbe, child: content);
  return pw.Outline(name: id, title: heading.text, level: 0, child: child);
}

pw.Widget _heading3({
  required String id,
  required MdHeading heading,
  required void Function(String id, int page)? onProbe,
}) {
  final content = pw.Container(
    margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(
          fontSize: 12.5,
          fontWeight: pw.FontWeight.bold,
          color: accentDark,
          lineSpacing: 2,
        ),
        children: parseInline(
          heading.text,
          base: pw.TextStyle(
            fontSize: 12.5,
            fontWeight: pw.FontWeight.bold,
            color: accentDark,
          ),
        ),
      ),
    ),
  );
  final child = onProbe == null
      ? content
      : PageProbe(id: id, onPage: onProbe, child: content);
  return pw.Outline(name: id, title: heading.text, level: 1, child: child);
}

pw.Widget _paragraph(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(
          fontSize: 10.5,
          color: textColor,
          lineSpacing: 4,
        ),
        children: parseInline(
          text,
          base: const pw.TextStyle(
            fontSize: 10.5,
            color: textColor,
            lineSpacing: 4,
          ),
        ),
      ),
    ),
  );
}

pw.Widget _list(MdBlock block) {
  final body = <pw.Widget>[];
  for (var i = 0; i < block.items.length; i++) {
    final item = block.items[i];
    final marker = block.ordered ? '${i + 1}.' : '•';
    body.add(
      pw.Padding(
        padding: pw.EdgeInsets.only(left: 6 + item.indent * 16, bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 16,
              child: pw.Text(
                marker,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  color: item.indent > 0 ? textMuted : accentDark,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.RichText(
                text: pw.TextSpan(
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    color: textColor,
                    lineSpacing: 4,
                  ),
                  children: parseInline(
                    item.text,
                    base: const pw.TextStyle(
                      fontSize: 10.5,
                      color: textColor,
                      lineSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: body,
    ),
  );
}

pw.Widget _quote(String text) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.fromLTRB(12, 9, 12, 9),
    // Sem `borderRadius`: o pacote pdf não aceita raio com borda não
    // uniforme (só a esquerda) — a régua verde + fundo claro bastam.
    decoration: pw.BoxDecoration(
      color: quoteBg,
      border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        style: const pw.TextStyle(
          fontSize: 10.5,
          color: textColor,
          lineSpacing: 4,
        ),
        children: parseInline(
          text,
          base: const pw.TextStyle(
            fontSize: 10.5,
            color: textColor,
            lineSpacing: 4,
          ),
        ),
      ),
    ),
  );
}

pw.Widget _table(MdBlock block) {
  pw.Widget cell(String text, {required bool header}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.RichText(
        text: pw.TextSpan(
          style: pw.TextStyle(
            fontSize: 9.5,
            color: textColor,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            lineSpacing: 2,
          ),
          children: parseInline(
            text,
            base: pw.TextStyle(
              fontSize: 9.5,
              color: textColor,
              fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        for (var c = 0; c < block.headers.length; c++) c: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: tableHeadBg),
          children: [for (final h in block.headers) cell(h, header: true)],
        ),
        for (final row in block.rows)
          pw.TableRow(
            children: [
              for (var c = 0; c < block.headers.length; c++)
                cell(c < row.length ? row[c] : '', header: false),
            ],
          ),
      ],
    ),
  );
}
