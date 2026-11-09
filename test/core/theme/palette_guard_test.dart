import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail da paleta OFICIAL (identidade 2026-11-09).
///
/// Nenhum ficheiro de `lib/` ou `tool/` pode declarar um HEX fora de:
/// * laranja `#FF6A2A`, cinza `#F0F0F0`, suave `#F9F9F9`, preto `#0C0B0A`;
/// * alertas semânticos `#2E7D32` (sucesso), `#C62828` (erro),
///   `#F9A825` (aviso);
/// * preto com qualquer alfa (sombras/véus da paleta).
///
/// Cores novas entram em `AppColors`/`PdfAccents`, nunca à mão num ecrã.
void main() {
  test('nenhum HEX fora da paleta oficial em lib/ e tool/', () {
    const official = <int>{
      0xFFFF6A2A, // laranja
      0xFFF0F0F0, // cinza de superfície
      0xFFF9F9F9, // branco suave
      0xFF0C0B0A, // preto
      0xFF2E7D32, // alerta: sucesso
      0xFFC62828, // alerta: erro
      0xFFF9A825, // alerta: aviso
    };

    final hexPatterns = [
      RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)'),
      RegExp(r'PdfColor\.fromInt\(0x([0-9A-Fa-f]{8})\)'),
    ];

    bool isOfficial(int value) =>
        official.contains(value) ||
        // Sombras e véus: preto oficial com alfa variável.
        (value & 0x00FFFFFF) == 0x0C0B0A;

    final problems = <String>[];

    for (final dir in ['lib', 'tool']) {
      final root = Directory(dir);
      expect(root.existsSync(), isTrue, reason: 'Rode a partir da raiz.');

      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final rel = entity.path.replaceAll(Platform.pathSeparator, '/');
        final lines = entity.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          for (final pattern in hexPatterns) {
            for (final match in pattern.allMatches(lines[i])) {
              final value = int.parse(match.group(1)!, radix: 16);
              if (!isOfficial(value)) {
                problems.add(
                  '$rel:${i + 1}: #${match.group(1)!.toUpperCase()} '
                  'fora da paleta oficial.',
                );
              }
            }
          }
        }
      }
    }

    expect(problems, isEmpty, reason: 'Guard da paleta oficial');
  });
}
