// Testes do gerador de PDFs de apoio ao utilizador final — NÃO fazem parte
// da suíte normal (`flutter test` só corre test/). Uso manual:
//
//   flutter test tool/generate_docs_pdf_test.dart
//
// Cobre: parser markdown (cabeçalhos/intro/listas/citações/tabelas/regras),
// remoção de emoji e de glifos sem suporte (preservando quebras de linha),
// o índice em DOIS PASSOS (sondagem de página) e a geração completa dos 4
// documentos reais.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' show TtfParser;
import 'package:pdf/widgets.dart' as pw;

import 'user_docs_pdf/markdown_pdf.dart';

const _fontPath = 'assets/fonts/Inter-Variable.ttf';

const _sample = '''
# Manual de Teste

Um parágrafo de apresentação para a capa.

## 1. Primeira secção

Primeiro parágrafo com **negrito** e `código`.

- Item **um**
- Item dois
  - Sub-item

## 2. Segunda secção

1. Passo um
2. Passo dois

> Uma citação importante.

---

### Sub-secção

| A | B |
|---|---|
| 1 | **dois** |
| 3 | quatro |
''';

late Uint8List _fontData;
late TtfParser _ttf;

void main() {
  setUpAll(() async {
    _fontData = await File(_fontPath).readAsBytes();
    _ttf = TtfParser(ByteData.sublistView(_fontData));
  });

  group('parseMarkdown', () {
    test('título, intro e blocos', () {
      final doc = parseMarkdown(_sample);
      expect(doc.title, 'Manual de Teste');
      expect(doc.intro, contains('parágrafo de apresentação'));
      // heading + paragraph + heading + list + heading + list +
      // quote + hr + heading + table
      expect(doc.blocks.length, 9);
      expect(doc.toc.map((h) => h.text).toList(), [
        '1. Primeira secção',
        '2. Segunda secção',
        'Sub-secção',
      ]);
    });

    test('listas com sub-itens e numeradas', () {
      final doc = parseMarkdown(_sample);
      final bullet = doc.blocks.where((b) => b.kind == MdBlockKind.list).first;
      expect(bullet.ordered, isFalse);
      expect(bullet.items.length, 3);
      expect(bullet.items[0].indent, 0);
      expect(bullet.items[1].text, 'Item dois');
      expect(bullet.items[2].indent, 1);
      final ordered = doc.blocks.where((b) => b.kind == MdBlockKind.list).last;
      expect(ordered.ordered, isTrue);
      expect(ordered.items[1].text, 'Passo dois');
    });

    test('citação e regra horizontal', () {
      final doc = parseMarkdown(_sample);
      expect(
        doc.blocks.any((b) => b.kind == MdBlockKind.quote),
        isTrue,
        reason: 'deve haver uma citação',
      );
      expect(
        doc.blocks.any((b) => b.kind == MdBlockKind.hr),
        isTrue,
        reason: 'deve haver uma regra horizontal',
      );
    });

    test('bloco de código fenced preserva o conteúdo e as quebras de linha',
        () {
      final doc = parseMarkdown('''
# Título

Código:

```bash
export SUPABASE_DB_URL='...'
psql "\$URL" -1 -f supabase/upgrade.sql
```

Fim.
''');
      final code = doc.blocks
          .where((b) => b.kind == MdBlockKind.code)
          .toList();
      expect(code, hasLength(1));
      expect(code.single.code, contains('export SUPABASE_DB_URL'));
      expect(code.single.code, contains('\n'));
      // Sem fence sobrando no texto.
      expect(code.single.code, isNot(contains('```')));
      expect(doc.blocks.last.text, 'Fim.');
    });

    test('tabela com cabeçalho e linhas', () {
      final doc = parseMarkdown(_sample);
      final table = doc.blocks.firstWhere((b) => b.kind == MdBlockKind.table);
      expect(table.headers, ['A', 'B']);
      expect(table.rows.length, 2);
      expect(table.rows[1], ['3', 'quatro']);
    });

    test('stripEmoji remove emojis mas preserva o texto', () {
      expect(stripEmoji('🟡 Amarelo 🔴 Vermelho ⚠️'), ' Amarelo  Vermelho ');
    });
  });

  group('parseInline', () {
    const base = pw.TextStyle(fontSize: 10.5);

    test('negrito, código e links viram spans', () {
      // span 0 = 'Negrito' (negrito), span 1 = ' e ', span 2 = 'código',
      // span 3 = ' e ', span 4 = 'link' (sublinhado).
      final spans = parseInline(
        '**Negrito** e `código` e [link](x.md)',
        base: base,
      );
      expect(spans.length, 5);
      expect(spans[0].text, 'Negrito');
      expect(spans[0].style!.fontWeight, pw.FontWeight.bold);
      expect(spans[2].text, 'código');
      expect(spans[4].text, 'link');
      expect(spans[4].style!.decoration, pw.TextDecoration.underline);
    });

    test('texto sem formatação vira um único span', () {
      final spans = parseInline('apenas texto', base: base);
      expect(spans.length, 1);
      expect(spans.single.text, 'apenas texto');
    });
  });

  group('filterGlyphs', () {
    test('remove glifos sem suporte e mantém quebras de linha', () {
      expect(filterGlyphs('ok\nlinha 2', _ttf), 'ok\nlinha 2');
      // U+1F512 🔒 não existe na Inter; \n é preservado.
      expect(filterGlyphs('x 🔒\ny', _ttf), 'x \ny');
    });
  });

  group('índice em dois passos', () {
    test('a sondagem regista a página de cada heading', () async {
      final doc = parseMarkdown(_sample);
      final pages = <String, int>{};
      final pass1 = buildDoc(
        font: pw.Font.ttf(ByteData.sublistView(_fontData)),
        doc: doc,
        docName: 'Teste',
        appName: 'Dumbhanengue ERP',
        subtitle: 'subtítulo',
        metaLine: 'meta',
        tocTitle: 'Índice',
        tocPages: null,
        onProbe: (id, page) => pages[id] = page,
      );
      await pass1.save();
      // Capa = 1, índice = 2 → o conteúdo começa na página 3.
      expect(pages.length, doc.toc.length);
      pages.forEach((id, page) {
        expect(
          page,
          greaterThanOrEqualTo(3),
          reason: '$id caiu na página $page',
        );
      });
      // Vários headings podem cair na MESMA página — a ordem deve ser
      // não-decrescente (o conteúdo flui para frente).
      final sorted = pages.values.toList()..sort();
      for (var i = 1; i < sorted.length; i++) {
        expect(sorted[i], greaterThanOrEqualTo(sorted[i - 1]));
      }
    });
  });

  group('geração completa', () {
    test('amostra gera um PDF válido com >= 3 páginas', () async {
      final doc = parseMarkdown(_sample);
      final (bytes, pages) = await generatePdf(
        fontData: _fontData,
        doc: doc,
        docName: 'Teste',
        appName: 'Dumbhanengue ERP',
        subtitle: 'subtítulo',
        metaLine: 'meta',
        tocTitle: 'Índice',
      );
      expect(
        utf8.decode(bytes.take(5).toList(), allowMalformed: true),
        '%PDF-',
      );
      expect(pages, greaterThanOrEqualTo(3));
    });

    test('os 19 capítulos técnicos em francês geram PDFs válidos', () async {
      // Cobre também os blocos de código fenced (SQL/bash/dart) dos
      // runbooks e guias técnicos.
      final jobs = [
        'docs/fr/01-overview.md',
        'docs/fr/02-architecture.md',
        'docs/fr/03-domain.md',
        'docs/fr/04-data.md',
        'docs/fr/05-presentation.md',
        'docs/fr/06-authentication.md',
        'docs/fr/07-security.md',
        'docs/fr/08-business-flows.md',
        'docs/fr/09-testing.md',
        'docs/fr/10-developer-guide.md',
        'docs/fr/11-multitenancy.md',
        'docs/fr/12-architecture-decisions.md',
        'docs/fr/13-build-and-release.md',
        'docs/fr/14-go-live-ops.md',
        'docs/fr/15-audit-status.md',
        'docs/fr/16-migracao-w4-h2.md',
        'docs/fr/17-production-checklist.md',
        'docs/fr/18-migracao-w11.md',
        'docs/fr/19-migracao-cash-closing.md',
      ];
      for (final path in jobs) {
        final doc = parseMarkdown(await File(path).readAsString());
        expect(doc.blocks, isNotEmpty, reason: path);
        expect(doc.toc, isNotEmpty, reason: path);
        final sanitized = sanitizeDoc(doc, (s) => filterGlyphs(s, _ttf));
        final (bytes, pages) = await generatePdf(
          fontData: _fontData,
          doc: sanitized,
          docName: path,
          appName: 'Dumbhanengue ERP',
          subtitle: sanitized.intro ?? '',
          metaLine: 'meta',
          tocTitle: 'Table des matières',
        );
        expect(
          utf8.decode(bytes.take(5).toList(), allowMalformed: true),
          '%PDF-',
          reason: path,
        );
        expect(pages, greaterThanOrEqualTo(3), reason: path);
      }
    });

    test('os 4 documentos reais geram PDFs válidos', () async {
      const jobs = [
        ('docs/pt/GUIA_DO_USUARIO.md', 'Guia do Usuário', 'Índice'),
        ('docs/pt/TROUBLESHOOTING.md', 'Troubleshooting', 'Índice'),
        ('docs/en/USER_GUIDE.md', 'User Guide', 'Table of contents'),
        ('docs/en/TROUBLESHOOTING.md', 'Troubleshooting', 'Table of contents'),
      ];
      for (final (path, name, toc) in jobs) {
        final doc = parseMarkdown(await File(path).readAsString());
        expect(doc.blocks, isNotEmpty, reason: path);
        expect(doc.toc, isNotEmpty, reason: path);
        final sanitized = sanitizeDoc(doc, (s) => filterGlyphs(s, _ttf));
        final (bytes, pages) = await generatePdf(
          fontData: _fontData,
          doc: sanitized,
          docName: name,
          appName: 'Dumbhanengue ERP',
          subtitle: sanitized.intro ?? '',
          metaLine: 'meta',
          tocTitle: toc,
        );
        expect(
          utf8.decode(bytes.take(5).toList(), allowMalformed: true),
          '%PDF-',
          reason: path,
        );
        expect(pages, greaterThanOrEqualTo(6), reason: path);
      }
    });
  });
}
