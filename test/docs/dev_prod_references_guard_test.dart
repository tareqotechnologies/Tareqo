import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail da identidade de projeto (Set/2026): dev e produção são projetos
/// Supabase **SEPARADOS** — `dotklbpqmlnhcdifiukd` (DEV, `env/dev.env`) e
/// `bcyolmheltzlddfwgqcq` (PRODUÇÃO, `env/prod.env`).
///
/// Vários documentos descreviam o deployment como um projeto **ÚNICO**
/// compartilhado por dev/prod (verdade até Ago/2026) e afirmavam que a infra de
/// produção estava pendente. A limpeza de Set/2026 corrigiu docs, CI e
/// comentários; este teste impede a regressão — se alguém reintroduzir a
/// premissa antiga num doc, a CI falha.
///
/// Grepping simples, sem AST: um Markdown não tem AST e a CI já roda
/// `flutter test` (mesma abordagem dos outros guard rails do projeto). Para
/// texto HISTÓRICO deliberado, marque a linha com `dev-prod-guard: allow`.
void main() {
  test('docs não afirmam um projeto Supabase único compartilhado dev/prod', () {
    final root = Directory('docs');
    expect(
      root.existsSync(),
      isTrue,
      reason: 'Rode o teste a partir da raiz do projeto (docs/ ausente).',
    );

    final files =
        root
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.md'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty, reason: 'Nenhum .md encontrado em docs/.');

    // Padrões que caracterizam a premissa ERRADA (projeto único/compartilhado,
    // ou infra de produção pendente). Multilíngue — os docs são pt/en/fr.
    const allowMarker = 'dev-prod-guard: allow';
    final forbidden = <RegExp>[
      // pt: "projeto único", "projeto Supabase único", "único projeto".
      RegExp(r'projeto\s+(supabase\s+)?[úu]nico', caseSensitive: false),
      RegExp(r'[úu]nico\s+projeto', caseSensitive: false),
      // en/fr.
      RegExp(r'single\s+supabase\s+project', caseSensitive: false),
      RegExp(r'seul\s+projet\s+supabase', caseSensitive: false),
      // "compartilhado/partilhado/partagé dev/prod|entre dev|por dev" — exige
      // o contexto DEV/PROD para não pegar "partilhado por WhatsApp".
      RegExp(
        r'(compartilhad|partilhad)\w*\s+(dev\s*/\s*prod|entre\s+dev|por\s+dev)',
        caseSensitive: false,
      ),
      RegExp(
        r'partag[ée]s?\s+(dev\s*/\s*prod|entre\s+dev)',
        caseSensitive: false,
      ),
      RegExp(r'shared\s+(by|between)\s+dev', caseSensitive: false),
      // infra de produção pendente (os dois projetos já existem).
      RegExp(r'pending\s+infra\s+step', caseSensitive: false),
      RegExp(r'passo\s+de\s+infra\s+pendente', caseSensitive: false),
      RegExp(r"étape\s+d['’]infra", caseSensitive: false),
    ];

    final problems = <String>[];
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(allowMarker)) continue;
        if (forbidden.any((p) => p.hasMatch(line))) {
          problems.add(
            '${file.path.replaceAll('\\', '/')}:${i + 1} — "${line.trim()}"',
          );
        }
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          'Desde Set/2026 dev e produção são projetos Supabase SEPARADOS '
          '(`dotklbpqmlnhcdifiukd` DEV / `bcyolmheltzlddfwgqcq` PRODUÇÃO). '
          'Reescreva a frase — ou marque a linha com "$allowMarker" se for '
          'texto histórico deliberado:\n${problems.join('\n')}',
    );
  });
}
