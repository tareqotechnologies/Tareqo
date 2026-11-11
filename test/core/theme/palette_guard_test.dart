import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail da paleta OFICIAL (identidade Outfit).
///
/// Nenhum ficheiro de `lib/` ou `tool/` pode declarar um HEX fora de:
/// * azul `#0067FF`, cinza médio `#6E7174`, cinza `#E7E5E5`,
///   suave `#F9F9F9`, tinta `#232323`;
/// * alertas semânticos `#2E7D32` (sucesso), `#C62828` (erro),
///   `#F9A825` (aviso);
/// * tints de texto dos MESMOS alertas no escuro (`#66BB6A` sucesso,
///   `#FF6B66` erro) — a variante de texto AA sobre `#232323`; os tons
///   base acima continuam para preenchimentos/chips;
/// * tinta com qualquer alfa (sombras/véus da paleta).
///
/// Cores novas entram em `AppColors`/`PdfAccents`, nunca à mão num ecrã.
void main() {
  test('nenhum HEX fora da paleta oficial em lib/ e tool/', () {
    const official = <int>{
      0xFF0067FF, // azul
      0xFF6E7174, // cinza médio
      0xFFE7E5E5, // cinza de superfície
      0xFFF9F9F9, // branco suave
      0xFF232323, // tinta escura
      0xFF2E7D32, // alerta: sucesso
      0xFFC62828, // alerta: erro
      0xFFF9A825, // alerta: aviso
      0xFF66BB6A, // alerta: sucesso (texto AA no escuro)
      0xFFFF6B66, // alerta: erro (texto AA no escuro)
    };

    final hexPatterns = [
      RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)'),
      RegExp(r'PdfColor\.fromInt\(0x([0-9A-Fa-f]{8})\)'),
    ];

    bool isOfficial(int value) =>
        official.contains(value) ||
        // Sombras e véus: preto oficial com alfa variável.
        (value & 0x00FFFFFF) == 0x232323;

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
