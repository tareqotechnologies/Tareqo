import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail da Fase 2.2 do plano UI/UX (docs/pt/21): **um único
/// "destrutivo"** — toda confirmação destrutiva passa pelo
/// [showConfirmDialog] (`confirm_dialog.dart`), que centraliza a variante
/// `.danger` do [AppButton] E o `Haptics.warning` no toque de confirmação.
///
/// O que a varredura tranca:
///
/// 1. `AlertDialog(` inline em telas — o padrão antigo que gerava
///    confirmações inconsistentes (sem haptic, sem cancelamento leve,
///    cores ad-hoc). Só os componentes do design system podem construí-lo.
/// 2. `CupertinoAlertDialog(` — a voz iOS não existe no design system
///    (dark-first M3); o `showConfirmDialog` é a ÚNICA confirmação.
/// 3. `HapticFeedback.` direto fora da fachada `Haptics`
///    (`core/ui/haptics.dart`) — o gate da preferência do utilizador
///    (`hapticsEnabled`) é aplicado só lá; uma chamada direta o contorna.
///
/// Grepping simples, não AST (o analyzer não tem regra para isso e a CI já
/// roda `flutter test` — mesma abordagem do `hex_guard_test.dart`). Novas
/// entradas na lista DEVEM carregar justificativa; o objetivo é o teto
/// encolher, não crescer.
void main() {
  test('AlertDialog inline = só os componentes do design system', () {
    final root = Directory('lib');
    expect(
      root.existsSync(),
      isTrue,
      reason: 'Rode o teste a partir da raiz do projeto.',
    );

    // Arquivo → ocorrências `AlertDialog(` documentadas (caminho com `/`).
    // `CupertinoAlertDialog(` NÃO está na lista: zero usos permitidos.
    const documented = <String, int>{
      // O próprio componente unificado (showConfirmDialog).
      'presentation/widgets/confirm_dialog.dart': 1,
      // Dialog de ENTRADA (showInputDialog) — nunca destrutivo: o campo de
      // texto precisa do AlertDialog para o layout das ações.
      'presentation/widgets/input_dialog.dart': 1,
    };

    final problems = <String>[];
    final prefix = 'lib/';
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll('\\', '/').replaceFirst(prefix, '');
      final source = entity.readAsStringSync();

      final actual = RegExp(r'AlertDialog\(').allMatches(source).length;
      final cupertino = RegExp(
        r'CupertinoAlertDialog\(',
      ).allMatches(source).length;
      if (cupertino > 0) {
        problems.add(
          '$rel: CupertinoAlertDialog encontrado — use showConfirmDialog '
          '(a voz iOS não existe no design system).',
        );
      }
      if (actual == 0) continue;
      final allowed = documented[rel] ?? 0;
      if (actual > allowed) {
        problems.add(
          '$rel: $actual AlertDialog(s) (documentados: $allowed) — '
          'use showConfirmDialog ou documente a justificativa aqui.',
        );
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test(
    'HapticFeedback direto = só na fachada Haptics (gate da preferência)',
    () {
      final root = Directory('lib');
      const facade = 'core/ui/haptics.dart';

      final problems = <String>[];
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final rel = entity.path.replaceAll('\\', '/').replaceFirst('lib/', '');
        if (rel == facade) continue;
        final matches = RegExp(
          r'HapticFeedback\.',
        ).allMatches(entity.readAsStringSync());
        if (matches.isNotEmpty) {
          problems.add(
            '$rel: HapticFeedback direto (${matches.length}x) — passe pela '
            'fachada Haptics (core/ui/haptics.dart) para respeitar a '
            'preferência do utilizador.',
          );
        }
      }

      expect(problems, isEmpty, reason: problems.join('\n'));
    },
  );
}
