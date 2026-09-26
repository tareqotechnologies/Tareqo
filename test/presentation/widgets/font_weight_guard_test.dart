import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard rail da Fase 2.4 do plano UI/UX (docs/pt/21): **pesos tipográficos
/// unificados** — estilos vêm do `textTheme` (a escala já define w600 como
/// ÊNFASE única e w400 como corpo); `copyWith(fontWeight:)` inline é
/// EXCEÇÃO documentada, não padrão.
///
/// Histórico: a v2.4.0 (auditoria P1–P2) migrou 158 usos → 10; a Fase 2.4
/// corrigiu os 2× w300 remanescentes em `stores_screen.dart` (13px w300 =
/// legibilidade degradada) — teto: 8. **Fase 2.4 (fecho)**: os 5 usos de
/// "ênfase sancionada" eram no-ops — `copyWith(fontWeight: w600)` sobre
/// papéis que a escala JÁ define como w600 (titleSmall, titleMedium,
/// labelMedium), defesa contra uma escala anterior aos pesos — removidos;
/// restam só os estruturais (ponte thin do admin + recibo impresso).
/// Teto atual: **3**. O inventário registra o que já está justificado;
/// NÃO é alvo a crescer. Novos usos DEVEM ir para a escala
/// (`app_typography.dart`) ou para um componente; se uma entrada da
/// lista zerar, REMOVA-A — o teste também falha com teto obsoleto
/// (contagem a menos).
///
/// Escopo do varrimento (alinhado ao plano): `copyWith(fontWeight:` em
/// `lib/presentation`. `TextStyle(fontWeight:` cru tem ~258 usos legítimos
/// (temas admin/bridge, estilos de recibo impresso, estilos const de
/// formulário) fora do alcance desta fase.
///
/// Grepping simples, não AST (o analyzer não tem regra para isso; mesma
/// abordagem do `hex_guard_test.dart`).
void main() {
  test('copyWith(fontWeight:) inline = inventário documentado (teto 3)', () {
    final root = Directory('lib/presentation');
    expect(root.existsSync(), isTrue,
        reason: 'Rode o teste a partir da raiz do projeto.');

    // Arquivo → ocorrências `copyWith(fontWeight` documentadas (caminho
    // com `/`).
    const documented = <String, int>{
      // A própria ponte do tema Thin do admin (derivação w300/w400
      // documentada do painel) — corrigida na v2.4.0 para preservar pesos.
      'widgets/admin_thin_bridge.dart': 1,
      // Recibo IMPRESSO (papel de tinta, não de UI): total em w700 e
      // subtítulo em w600 — hierarquia do papel térmico/PDF, mesmo
      // princípio do PdfAccents.
      'widgets/sale_receipt_view.dart': 2,
    };

    final problems = <String>[];
    const prefix = 'lib/presentation/';
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel =
          entity.path.replaceAll('\\', '/').replaceFirst(prefix, '');
      final actual = RegExp(
        r'copyWith\(fontWeight',
      ).allMatches(entity.readAsStringSync()).length;
      if (actual == 0) continue;
      final allowed = documented[rel] ?? 0;
      if (actual > allowed) {
        problems.add(
          '$rel: $actual ocorrência(s) (documentadas: $allowed) — mova o '
          'peso para a escala (app_typography.dart) ou um componente; se '
          'for legítimo, documente a justificativa aqui.',
        );
      }
    }

    // Entradas obsoletas (arquivo zerou) também falham — o teto encolhe.
    for (final entry in documented.entries) {
      final file = File('lib/presentation/${entry.key}');
      if (!file.existsSync()) {
        problems.add('${entry.key}: arquivo não existe mais — remova a '
            'entrada do inventário.');
        continue;
      }
      final actual = RegExp(
        r'copyWith\(fontWeight',
      ).allMatches(file.readAsStringSync()).length;
      if (actual < entry.value) {
        problems.add('${entry.key}: $actual ocorrência(s) (documentadas: '
            '${entry.value}) — entrada obsoleta, remova-a do inventário.');
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
