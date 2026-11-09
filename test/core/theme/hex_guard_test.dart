import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail do design system (Fase 8, plano §5.2): cores por HEX literal
/// em `lib/presentation` só podem existir na lista documentada abaixo —
/// cada entrada carrega a justificativa funcional (identidade de provedor,
/// papel do recibo impresso, paleta de template etc.).
///
/// A Fase 0 media 46 hex; a Fase 1 migrou os duplicados de papéis do tema
/// para `AppColors.*` (commit 08ebc0f) e as fases seguintes migraram os
/// restantes — o teto atual é a soma da lista abaixo. Novas cores DEVEM ir
/// para `lib/core/theme/app_colors.dart` (ou outro token) e NÃO para esta
/// lista: o inventário registra o que já está justificado, não é alvo a
/// crescer. Se um arquivo da lista deixar de ter hex, remova a entrada —
/// este teste também falha com entrada obsoleta (contagem a mais).
///
/// Grepping simples, não AST: o analyzer não tem regra para isso e a CI já
/// roda `flutter test` — um teste é o guard mais barato e fala a linguagem
/// do projeto (mesma abordagem do plano §5.3 para guidelines).
void main() {
  test(
    'hex em lib/presentation = inventário documentado (nem mais, nem menos)',
    () {
      final root = Directory('lib/presentation');
      expect(
        root.existsSync(),
        isTrue,
        reason: 'Rode o teste a partir da raiz do projeto.',
      );

      // Arquivo → ocorrências `Color(0x…)` documentadas (caminho com `/`).
      // U-23: paleta oficial — nenhum hex literal em apresentação; o
      // recibo impresso usa tokens (AppColors.brandBlack/surfaceGray).
      const documented = <String, int>{};

      final problems = <String>[];

      // 1. Nenhum arquivo pode exceder a sua contagem documentada.
      const prefix = 'lib/presentation/';
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final rel = entity.path.replaceAll('\\\\', '/').replaceFirst(prefix, '');
        final actual = RegExp(r'Color\(0x').allMatches(entity.readAsStringSync()).length;
        if (actual == 0) continue;
        final allowed = documented[rel] ?? 0;
        if (actual > allowed) {
          problems.add(
            '$rel: $actual ocorrência(s) (documentadas: $allowed) — mova a cor '
            'para AppColors/tokens ou documente a justificativa aqui.',
          );
        }
      }

      // 2. Nenhuma entrada da lista pode ter ficado obsoleta (hex removido e
      // contagem não atualizada) — o inventário não envelhece silenciosamente.
      for (final entry in documented.entries) {
        final f = File('lib/presentation/${entry.key}');
        if (!f.existsSync()) {
          problems.add('${entry.key}: arquivo documentado não existe mais.');
          continue;
        }
        final actual = RegExp(r'Color\(0x').allMatches(f.readAsStringSync()).length;
        if (actual < entry.value) {
          problems.add(
            '${entry.key}: documentadas ${entry.value}, mas o arquivo tem '
            '$actual — atualize o inventário (e aproveite para migrar o resto '
            'para tokens, se a cor já não é usada).',
          );
        }
      }

      expect(problems, isEmpty, reason: 'Guard de hex do design system');
    },
  );
}