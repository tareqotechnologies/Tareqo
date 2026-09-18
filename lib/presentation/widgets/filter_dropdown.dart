import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';

/// Seletor de filtro minimalista (canvas V3) — UM único chip compacto com
/// o valor ativo + chevron; tocar abre o menu de opções. Mesma linguagem
/// da pílula de período da Home ("Hoje ▾"): substitui as linhas de chips
/// (período + pagamento empilhadas) por dois seletores discretos numa
/// única linha.
///
/// O chip destaca (primaryContainer) quando um filtro NÃO-default está
/// ativo — o estado de filtragem aparece num relance sem gritar.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.icon,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  /// Ícone fixo do chip (calendário para período, pagamentos para forma).
  final IconData icon;

  final List<T> options;

  /// Opção ativa (a primeira da lista é o default — chip neutro).
  final T selected;

  final String Function(T option) labelOf;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = selected != options.first;

    // Largura mínima baseada no rótulo mais longo para itens uniformes.
    final longestLabel = options
        .map((o) => labelOf(o))
        .fold<int>(0, (max, l) => l.length > max ? l.length : max);
    final itemWidth = (longestLabel * 7.0) + 44; // ícone + padding

    return PopupMenuButton<T>(
      onSelected: onChanged,
      tooltip: labelOf(selected),
      position: PopupMenuPosition.under,
      constraints: BoxConstraints(minWidth: itemWidth),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem(
            value: option,
            height: 44,
            child: Row(
              children: [
                Icon(
                  option == selected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 16,
                  color: option == selected
                      ? theme.accent
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    labelOf(option),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        // Alvo de toque ≥ 48dp (WCAG/androidTapTargetGuideline): o chip é
        // compacto por design, mas a área tocável não pode ser menor que
        // o mínimo de acessibilidade.
        constraints: const BoxConstraints(minHeight: AppSizes.touchTarget),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active ? Colors.transparent : scheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              labelOf(selected),
              style: theme.textTheme.labelLarge?.copyWith(
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: active
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
