import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail da **padronização tipográfica global**.
///
/// A regra do design system: todo texto da app usa os tokens de
/// `core/theme/app_typography.dart` (via `AppTypography.*` ou pelo
/// `textTheme`). Estilos com tamanho/peso/família escritos na tela são
/// dívida — cada um cria um degrau a mais na escala e impede a hierarquia
/// de ser previsível entre telas.
///
/// O que a varredura tranca em `lib/presentation`:
///
/// 1. `fontSize:` inline — só nas superfícies de exceção abaixo;
/// 2. `fontFamily:` — apenas a Inter (herdada do tema) ou `'monospace'`
///    (códigos/IDs, família declarada no pubspec);
/// 3. pesos fora da escala 400/500/600 — só nas mesmas exceções.
///
/// Superfícies de exceção (documentadas, não convite a crescer):
///
/// * `screens/admin/` + `widgets/admin_thin_bridge.dart` — painel do super
///   admin com a escala thin DERIVADA (w300), um sistema visual separado e
///   testado em `typography_scale_test.dart`;
/// * `widgets/sale_receipt_view.dart` — recibo impresso (papel térmico/PDF):
///   tamanhos em pontos, não em sp de UI;
/// * `screens/addons/custom_invoice_preview.dart` — pré-visualização da
///   factura/orçamento (folha A4), mesma razão do recibo.
void main() {
  final root = Directory('lib/presentation');
  const prefix = 'lib/presentation/';

  /// Caminho relativo (com `/`) → justificativa da exceção.
  bool isException(String rel) {
    if (rel.startsWith('screens/admin/')) return true;
    const files = {
      'widgets/admin_thin_bridge.dart',
      'widgets/sale_receipt_view.dart',
      'screens/addons/custom_invoice_preview.dart',
    };
    return files.contains(rel);
  }

  Iterable<(String, String)> sources() sync* {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll('\\', '/').replaceFirst(prefix, '');
      yield (rel, entity.readAsStringSync());
    }
  }

  setUpAll(() {
    expect(
      root.existsSync(),
      isTrue,
      reason: 'Rode o teste a partir da raiz do projeto.',
    );
  });

  test('fontSize inline = só nas superfícies de exceção', () {
    final inline = RegExp(r'(?<![\w.])fontSize:\s*[\d.]');
    final problems = <String>[];
    for (final (rel, source) in sources()) {
      final hits = inline.allMatches(source).length;
      if (hits == 0 || isException(rel)) continue;
      problems.add(
        '$rel: $hits fontSize inline — use AppTypography.* ou o textTheme '
        '(titleMedium, bodyMedium, labelMedium…); se for papel impresso/'
        'pré-visualização, documente a exceção neste inventário.',
      );
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('fontFamily só a Inter do tema ou a mono declarada', () {
    final family = RegExp(r'''fontFamily:\s*'([^']*)'|fontFamily:\s*"([^"]*)"''');
    final allowed = {'Inter', 'monospace'};
    final problems = <String>[];
    for (final (rel, source) in sources()) {
      for (final m in family.allMatches(source)) {
        final value = m.group(1) ?? m.group(2)!;
        if (allowed.contains(value)) continue;
        problems.add(
          '$rel: fontFamily "$value" — a app usa apenas Inter '
          '(herdada do tema) e monospace para códigos/IDs.',
        );
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('pesos fora de 400/500/600 = só nas superfícies de exceção', () {
    final weight = RegExp(r'FontWeight\.w(300|700|800|900)\b');
    final problems = <String>[];
    for (final (rel, source) in sources()) {
      final hits = weight.allMatches(source).length;
      if (hits == 0 || isException(rel)) continue;
      problems.add(
        '$rel: $hits uso(s) de peso leve/extra-pesado — a escala usa apenas '
        '400 (corpo), 500 (labels) e 600 (títulos e valor dominante).',
      );
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
