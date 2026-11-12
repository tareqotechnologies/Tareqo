import 'dart:io';

import 'package:flutter/material.dart' show Color, HSVColor;
import 'package:flutter_test/flutter_test.dart';

/// Guard rail da paleta OFICIAL (identidade Tareqo — "Shades of gray").
///
/// Nenhum ficheiro de `lib/` ou `tool/` pode declarar um HEX fora de:
/// * escala neutra do anexo: Preto 100 `#0A0E15`, 90 `#212631`, 80
///   `#373F4E`, 70 `#4E576A`, 60 `#667085`; Branco 100 `#FFFFFF`, 90
///   `#F0F1F5`, 80 `#E0E4EB`, 70 `#D1D6E0`, 60 `#BFC5D4`;
/// * alertas semânticos `#2E7D32` (sucesso), `#C62828` (erro),
///   `#66BB6A` (sucesso texto AA no escuro) e `#FF8A80` (erro texto
///   AA no escuro);
/// * tinta Preto 100 com qualquer alfa (sombras/véus da paleta).
///
/// **Sem laranja:** nenhum HEX pode ter matiz entre 10° e 45° com
/// saturação relevante — a identidade é monocromática.
///
/// Cores novas entram em `AppColors`/`PdfAccents`, nunca à mão num ecrã.
void main() {
  test('nenhum HEX fora da paleta oficial em lib/ e tool/', () {
    const official = <int>{
      // Escala neutra (anexo)
      0xFF0A0E15, // preto 100 (tinta e canvas escuro)
      0xFF212631, // preto 90 (superfície escura)
      0xFF373F4E, // preto 80 (elevada escura)
      0xFF4E576A, // preto 70 (texto secundário no claro)
      0xFF667085, // preto 60 (bordas de controlo)
      0xFFFFFFFF, // branco 100 (canvas/cartões claros)
      0xFFF0F1F5, // branco 90 (canvas claro / campos)
      0xFFE0E4EB, // branco 80 (divisores)
      0xFFD1D6E0, // branco 70 (contorno suave)
      0xFFBFC5D4, // branco 60 (desactivado / texto escuro)
      // Alertas semânticos
      0xFF2E7D32, // alerta: sucesso
      0xFFC62828, // alerta: erro
      0xFF66BB6A, // alerta: sucesso (texto AA no escuro)
      0xFFFF8A80, // alerta: erro (texto AA no escuro)
    };

    final hexPatterns = [
      RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)'),
      RegExp(r'PdfColor\.fromInt\(0x([0-9A-Fa-f]{8})\)'),
    ];

    bool isOfficial(int value) =>
        official.contains(value) ||
        // Sombras e véus: tinta Preto 100 com alfa variável.
        (value & 0x00FFFFFF) == 0x0A0E15;

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

  test('nenhum HEX de laranja em lib/ e tool/ (matiz 10°–45°)', () {
    final hexPatterns = [
      RegExp(r'Color\(0x([0-9A-Fa-f]{8})\)'),
      RegExp(r'PdfColor\.fromInt\(0x([0-9A-Fa-f]{8})\)'),
    ];

    final problems = <String>[];

    for (final dir in ['lib', 'tool']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final rel = entity.path.replaceAll(Platform.pathSeparator, '/');
        final lines = entity.readAsLinesSync();

        for (var i = 0; i < lines.length; i++) {
          for (final pattern in hexPatterns) {
            for (final match in pattern.allMatches(lines[i])) {
              final value = int.parse(match.group(1)!, radix: 16);
              final hsv = HSVColor.fromColor(Color(value));
              final isOrange =
                  hsv.saturation >= 0.25 &&
                  hsv.value >= 0.15 &&
                  hsv.hue >= 10 &&
                  hsv.hue <= 45;
              if (isOrange) {
                problems.add(
                  '$rel:${i + 1}: #${match.group(1)!.toUpperCase()} '
                  'é laranja (matiz ${hsv.hue.toStringAsFixed(0)}°).',
                );
              }
            }
          }
        }
      }
    }

    expect(problems, isEmpty, reason: 'A identidade não tem laranja');
  });
}
