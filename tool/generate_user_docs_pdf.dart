// Gerador dos PDFs de apoio ao utilizador final (Guia do Usuário +
// Troubleshooting, pt/en/fr) — PARTE 2: CLI.
//
// Uso:
// dart run tool/generate_user_docs_pdf.dart
//
// Lê os markdown de docs/{pt,en,fr}/, embeleza com capa + índice (two-pass
// com números de página reais) e grava em docs/pdf/{pt,en,fr}/. Também
// remove os glifos que a Inter embutida não cobre (emoji etc.), avisando no
// stderr.
//
// Bibliotecas usadas: package:pdf (já no pubspec, via report_exporter) e o
// parser desta pasta (markdown_pdf.dart). Puro Dart — sem Flutter.
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart' show TtfParser;

import 'user_docs_pdf/markdown_pdf.dart';

const _appName = 'TAREQO';
const _fontPath = 'assets/fonts/Inter-Variable.ttf';

Future<void> main() async {
  final fontData = await File(_fontPath).readAsBytes();
  // Parser da fonte: usamos o cmap para saber quais runes existem.
  final ttf = TtfParser(ByteData.sublistView(fontData));
  final version = await _readVersion();

  final jobs = <_Job>[
    const _Job(
      src: 'docs/pt/GUIA_DO_USUARIO.md',
      out: 'docs/pdf/pt/GUIA_DO_USUARIO.pdf',
      lang: 'pt',
      docName: 'Guia do Usuário',
      tocTitle: 'Índice',
    ),
    const _Job(
      src: 'docs/pt/TROUBLESHOOTING.md',
      out: 'docs/pdf/pt/TROUBLESHOOTING.pdf',
      lang: 'pt',
      docName: 'Troubleshooting',
      tocTitle: 'Índice',
    ),
    const _Job(
      src: 'docs/en/USER_GUIDE.md',
      out: 'docs/pdf/en/USER_GUIDE.pdf',
      lang: 'en',
      docName: 'User Guide',
      tocTitle: 'Table of contents',
    ),
    const _Job(
      src: 'docs/en/TROUBLESHOOTING.md',
      out: 'docs/pdf/en/TROUBLESHOOTING.pdf',
      lang: 'en',
      docName: 'Troubleshooting',
      tocTitle: 'Table of contents',
    ),
    const _Job(
      src: 'docs/fr/GUIDE_DE_L_UTILISATEUR.md',
      out: 'docs/pdf/fr/GUIDE_DE_L_UTILISATEUR.pdf',
      lang: 'fr',
      docName: "Guide de l'utilisateur",
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/DEPANNAGE.md',
      out: 'docs/pdf/fr/DEPANNAGE.pdf',
      lang: 'fr',
      docName: 'Dépannage',
      tocTitle: 'Table des matières',
    ),
    // Capítulos técnicos em francês (01–19) — mesma apresentação dos guias:
    // capa + índice + conteúdo. O docName da capa/footer usa o nome do
    // capítulo; o tocTitle é o índice em francês.
    const _Job(
      src: 'docs/fr/01-overview.md',
      out: 'docs/pdf/fr/01-overview.pdf',
      lang: 'fr',
      docName: 'Chapitre 01 — Vue d’ensemble',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/02-architecture.md',
      out: 'docs/pdf/fr/02-architecture.pdf',
      lang: 'fr',
      docName: 'Chapitre 02 — Architecture',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/03-domain.md',
      out: 'docs/pdf/fr/03-domain.pdf',
      lang: 'fr',
      docName: 'Chapitre 03 — Domaine',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/04-data.md',
      out: 'docs/pdf/fr/04-data.pdf',
      lang: 'fr',
      docName: 'Chapitre 04 — Couche de données',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/05-presentation.md',
      out: 'docs/pdf/fr/05-presentation.pdf',
      lang: 'fr',
      docName: 'Chapitre 05 — Présentation',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/06-authentication.md',
      out: 'docs/pdf/fr/06-authentication.pdf',
      lang: 'fr',
      docName: 'Chapitre 06 — Authentification',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/07-security.md',
      out: 'docs/pdf/fr/07-security.pdf',
      lang: 'fr',
      docName: 'Chapitre 07 — Sécurité',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/08-business-flows.md',
      out: 'docs/pdf/fr/08-business-flows.pdf',
      lang: 'fr',
      docName: 'Chapitre 08 — Flux métier',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/09-testing.md',
      out: 'docs/pdf/fr/09-testing.pdf',
      lang: 'fr',
      docName: 'Chapitre 09 — Tests',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/10-developer-guide.md',
      out: 'docs/pdf/fr/10-developer-guide.pdf',
      lang: 'fr',
      docName: 'Chapitre 10 — Guide du développeur',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/11-multitenancy.md',
      out: 'docs/pdf/fr/11-multitenancy.pdf',
      lang: 'fr',
      docName: 'Chapitre 11 — Multi-tenancy et Super Admin',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/12-architecture-decisions.md',
      out: 'docs/pdf/fr/12-architecture-decisions.pdf',
      lang: 'fr',
      docName: 'Chapitre 12 — Décisions d’architecture',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/13-build-and-release.md',
      out: 'docs/pdf/fr/13-build-and-release.pdf',
      lang: 'fr',
      docName: 'Chapitre 13 — Build et publication',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/14-go-live-ops.md',
      out: 'docs/pdf/fr/14-go-live-ops.pdf',
      lang: 'fr',
      docName: 'Chapitre 14 — Opérations de go-live',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/15-audit-status.md',
      out: 'docs/pdf/fr/15-audit-status.pdf',
      lang: 'fr',
      docName: 'Chapitre 15 — Statut d’audit',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/16-migracao-w4-h2.md',
      out: 'docs/pdf/fr/16-migracao-w4-h2.pdf',
      lang: 'fr',
      docName: 'Chapitre 16 — Migration W4 + H2',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/17-production-checklist.md',
      out: 'docs/pdf/fr/17-production-checklist.pdf',
      lang: 'fr',
      docName: 'Chapitre 17 — Checklist de production',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/18-migracao-w11.md',
      out: 'docs/pdf/fr/18-migracao-w11.pdf',
      lang: 'fr',
      docName: 'Chapitre 18 — Migration W11',
      tocTitle: 'Table des matières',
    ),
    const _Job(
      src: 'docs/fr/19-migracao-cash-closing.md',
      out: 'docs/pdf/fr/19-migracao-cash-closing.pdf',
      lang: 'fr',
      docName: 'Chapitre 19 — Clôture de caisse',
      tocTitle: 'Table des matières',
    ),
  ];

  for (final job in jobs) {
    final doc = parseMarkdown(await File(job.src).readAsString());
    final sanitized = sanitizeDoc(doc, (s) => _filter(s, ttf));
    // Título da capa: remove APENAS o sufixo "— TAREQO" (os
    // capítulos técnicos têm travessões significativos no título, ex.
    // "01 — Vue d'ensemble" — não podem ser cortados).
    final coverTitle = sanitized.title
        .replaceFirst(RegExp(r'\s+[—–]\s*TAREQO\s*$'), '')
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
        '${_label(job.lang, 'version')} $version · ${_dateLabel(job.lang, DateTime.now())}';

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
    print('OK ${job.out} ($pages páginas, ${bytes.length ~/ 1024} KB)');
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
  // fr usa o mesmo 'Version' do en.
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
  if (lang == 'fr') {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
