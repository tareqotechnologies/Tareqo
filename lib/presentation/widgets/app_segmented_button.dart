import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// SegmentedButton no padrão do design system V4: pílulas estilo Apple
/// (StadiumBorder), segmento ativo em primaryContainer, rótulo w500 e
/// alvo de toque ≥ 48dp (sem densidade compacta — o segmento é botão de
/// baixa frequência).
///
/// Unifica o estilo que estava copiado em 4 telas (financeiro, relatórios,
/// fiado e sheet de transação). O [FittedBox] fica no call site: nos
/// seletores de período/abas ele encolhe o widget em telas estreitas; no
/// sheet de transação o botão é full-width e NÃO usa FittedBox.
class AppSegmentedButton<T> extends StatelessWidget {
  const AppSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SegmentedButton<T>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        // Alvo de toque ≥ 48dp (guideline a11y).
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: Colors.transparent,
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        foregroundColor: scheme.onSurfaceVariant,
        // Filtros são controlos discretos: 14/w500, nunca semibold.
        textStyle: theme.textTheme.labelLarge,
      ),
      segments: segments,
      selected: selected,
      onSelectionChanged: onSelectionChanged,
    );
  }
}
