// Gerador dos PDFs de apoio ao utilizador final (Guia do Usuário +
// Troubleshooting, pt/en) — PARTE 2: CLI.
//
// Uso:
//   dart run tool/generate_user_docs_pdf.dart
//
// Lê os markdown de docs/{pt,en}/, embeleza com capa + índice (two-pass com
// números de página reais) e grava em docs/pdf/{pt,en}/. Também remove os
// glifos que a Inter embutida não cobre (emoji etc.), avisando no stderr.
//
// Bibliotecas usadas: package:pdf (já no pubspec, via report_exporter) e o
// parser desta pasta (markdown_pdf.dart). Puro Dart — sem Flutter.
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart' show TtfParser;

import 'user_docs_pdf/markdown_pdf.dart';

const _appName = 'Dumbhanengue ERP';
const _fontPath = 'assets/fonts/Inter-Variable.ttf';

Future<void> main() async {
  final fontData = await File(_fontPath).readAsBytes();
  // Parser da fonte: usamos o cmap para saber quais runes existem.
  final ttf = TtfParser(ByteData.sublistView(fontData));
  final version = await _readVersion();

  final jobs = <_Job>[
    _Job(
      src: 'docs/pt/GUIA_DO_USUARIO.md',
      out: 'docs/pdf/pt/GUIA_DO_USUARIO.pdf',
      lang: 'pt',
      docName: 'Guia do Usuário',
      tocTitle: 'Índice',
    ),
    _Job(
      src: 'docs/pt/TROUBLESHOOTING.md',
      out: 'docs/pdf/pt/TROUBLESHOOTING.pdf',
      lang: 'pt',
      docName: 'Troubleshooting',
      tocTitle: 'Índice',
    ),
    _Job(
      src: 'docs/en/USER_GUIDE.md',
      out: 'docs/pdf/en/USER_GUIDE.pdf',
      lang: 'en',
      docName: 'User Guide',
      tocTitle: 'Table of contents',
    ),
    _Job(
      src: 'docs/en/TROUBLESHOOTING.md',
      out: 'docs/pdf/en/TROUBLESHOOTING.pdf',
      lang: 'en',
      docName: 'Troubleshooting',
      tocTitle: 'Table of contents',
    ),
  ];

  for (final job in jobs) {
    final doc = parseMarkdown(await File(job.src).readAsString());
    final sanitized = sanitizeDoc(doc, (s) => _filter(s, ttf));
    // Título da capa: remove o sufixo "— Dumbhanengue ERP" (qualquer travessão).
    final coverTitle = sanitized.title
        .replaceFirst(RegExp(r'\s+[—–]\s+.*$'), '')
        .trim();
    // Subtitle: primeira linha da intro, sem a sintaxe de link do markdown
    // (no PDF impresso o texto do link vale sozinho — sem URL visível).
    final subtitle = sanitized.intro == null
        ? ''
        : sanitized.intro!
              .split('\n')
              .first
              .replaceAllMapped(
                RegExp(r'\[([^\]]+)\]\([^)]+\)'),
                (m) => m.group(1)!,
              );
    // O gerador usa `doc.title` na capa — entrega o título limpo.
    final coverDoc = DocModel(
      title: coverTitle,
      intro: sanitized.intro,
      blocks: sanitized.blocks,
      toc: sanitized.toc,
    );
    final metaLine =
        '${_label(job.lang, 'version')} $version  ·  ${_dateLabel(job.lang, DateTime.now())}';

    final (bytes, pages) = await generatePdf(
      fontData: fontData,
      doc: coverDoc,
      docName: job.docName,
      appName: _appName,
      subtitle: subtitle,
      metaLine: metaLine,
      tocTitle: job.tocTitle,
    );

    final out = File(job.out)..createSync(recursive: true);
    out.writeAsBytesSync(bytes);
    // ignore: avoid_print — CLI.
    print('OK  ${job.out}  ($pages páginas, ${bytes.length ~/ 1024} KB)');
  }
}

String _filter(String s, TtfParser ttf) {
  final clean = filterGlyphs(s, ttf);
  if (clean.length != s.length) {
    // ignore: avoid_print — CLI.
    stderr.writeln(
      'aviso: glifos sem suporte removidos (${s.length - clean.length} rune(s))',
    );
  }
  return clean;
}

String _label(String lang, String key) {
  if (lang == 'pt') return key == 'version' ? 'Versão' : '';
  return key == 'version' ? 'Version' : '';
}

String _dateLabel(String lang, DateTime d) {
  if (lang == 'pt') {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

Future<String> _readVersion() async {
  final pubspec = await File('pubspec.yaml').readAsString();
  final m = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:\+[0-9]+)?)',
    multiLine: true,
  ).firstMatch(pubspec);
  return m?.group(1) ?? '1.1.0';
}

class _Job {
  const _Job({
    required this.src,
    required this.out,
    required this.lang,
    required this.docName,
    required this.tocTitle,
  });
  final String src;
  final String out;
  final String lang;
  final String docName;
  final String tocTitle;
}
