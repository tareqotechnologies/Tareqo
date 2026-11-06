import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail da Fase 2.3 do plano UI/UX (docs/pt/21): **espaçamento pela
/// grelha de 4px** — paddings, gaps e recuos em `lib/presentation` usam os
/// tokens `AppSpacing`/`AppRadius` (`core/theme/app_tokens.dart`), nunca
/// números soltos fora da grelha (…4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48…).
///
/// O que a varredura tranca:
///
/// 1. Valores OFF-grid em `EdgeInsets` (`horizontal|vertical|top|bottom|
///    left|right|all:`) e em gaps de `Wrap`/`Divider` (`spacing|runSpacing|
///    indent|endIndent:`) — o deslize histórico (5/6/10/14px) que fazia
///    cada tela respirar de um jeito diferente.
/// 2. `SizedBox(height:|width:)` fora da grelha — o espaçador é spacing.
///
/// O que fica FORA do escopo (com a razão):
/// * Valores ON-grid escritos como número (2/3/4px de micro-ajuste,
///   hairlines, baseline de texto) — não são casos a migrar à força;
///   o alvo da fase eram os OFF-grid.
/// * Indentações estruturais de timeline (56/60/72 = largura do avatar +
///   gap) e o `left: 44` de alinhamento sob checkbox — dependentes de
///   tamanho de componente, documentadas no inventário abaixo. Se um
///   número novo aparecer, DOCUMENTE-O com justificativa ou migre para o
///   token da grelha; o objetivo é o inventário encolher, não crescer.
///
/// Grepping simples, não AST (o analyzer não tem regra para isso; mesma
/// abordagem do `hex_guard_test.dart` e do `destructive_dialog_guard_test.dart`).
void main() {
  test('valores off-grid da grelha de 4px = só o inventário documentado', () {
    final root = Directory('lib/presentation');
    expect(
      root.existsSync(),
      isTrue,
      reason: 'Rode o teste a partir da raiz do projeto.',
    );

    // Grelha V4: 4/8/12/16/20/24/32/40/48 (+0 e 1/2/3px micro).
    const grid = {0, 1, 2, 3, 4, 8, 12, 16, 20, 24, 32, 40, 48};

    // Recuos estruturais legítimos (caminho com `/` → ocorrências): não são
    // "respiro de layout", derivam do tamanho de um componente (avatar,
    // checkbox). Documentar aqui ≠ convidar a crescer.
    const documented = <String, int>{
      'screens/admin/admin_audit_log_screen.dart': 1, // indent: 72 (timeline)
      'screens/admin/admin_tenants_widgets.dart': 1, // left: 44 (checkbox)
      'screens/dashboard/dashboard_screen.dart': 1, // indent: 60 (timeline)
      'screens/dashboard/notifications_screen.dart': 2, // indent: 56 + h 120
      'screens/financial/financial_screen.dart': 1, // indent: 60 (timeline)
      'screens/sales/sales_widgets.dart': 1, // indent: 60 (timeline)
      'widgets/feed_card.dart': 1, // indent: 60 (timeline)
    };

    final edgeInsetsPattern = RegExp(
      r'(?:horizontal|vertical|top|bottom|left|right|all|spacing|runSpacing|'
      r'indent|endIndent):\s*(\d+)',
    );
    final sizedBoxPattern = RegExp(r'SizedBox\((?:height|width):\s*(\d+)');

    final problems = <String>[];
    const prefix = 'lib/presentation/';
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll('\\', '/').replaceFirst(prefix, '');
      final source = entity.readAsStringSync();

      final offGrid = [
        ...edgeInsetsPattern.allMatches(source),
        ...sizedBoxPattern.allMatches(source),
      ].where((m) => !grid.contains(int.parse(m.group(1)!))).toList();
      if (offGrid.isEmpty) continue;

      final allowed = documented[rel] ?? 0;
      if (offGrid.length > allowed) {
        final values = offGrid.map((m) => m.group(0)).join(', ');
        problems.add(
          '$rel: ${offGrid.length} valor(es) fora da grelha [$values] — use '
          'AppSpacing/AppRadius (core/theme/app_tokens.dart); se for '
          'estrutural (dependente de componente), documente a justificativa '
          'no inventário.',
        );
      }
    }

    // Entradas obsoletas também falham — o inventário encolhe.
    for (final entry in documented.entries) {
      final file = File('lib/presentation/${entry.key}');
      if (!file.existsSync()) {
        problems.add(
          '${entry.key}: arquivo não existe mais — remova a entrada do '
          'inventário.',
        );
        continue;
      }
      final actual = [
        ...edgeInsetsPattern.allMatches(file.readAsStringSync()),
        ...sizedBoxPattern.allMatches(file.readAsStringSync()),
      ].where((m) => !grid.contains(int.parse(m.group(1)!))).length;
      if (actual < entry.value) {
        problems.add(
          '${entry.key}: $actual ocorrência(s) (documentadas: '
          '${entry.value}) — entrada obsoleta, remova-a do inventário.',
        );
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
