import 'package:flutter/material.dart';

import 'num_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

/// Pílula de status — rótulo com fundo colorido translúcido.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A11y (plano UI/UX — Fase 3.1): o chip é UM nó semântico — o leitor
    // de ecrã anuncia o estado inteiro ("Pago", "5 un.") em vez de
    // percorrer ícone e texto como nós separados. O ícone é decoração
    // (o rótulo já diz tudo) e o FittedBox fica fora do nó para o label
    // não ser anunciado como nó próprio (mesmo padrão do SalesCard).
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
          // Aro fino da própria cor: contorno nítido sem pesar o chip.
          border: Border.all(color: color.withValues(alpha: 0.22), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                // NumText: chips carregam quantidades/valores/datas — dígitos
                // alinhados em colunas de chips (tabular embutido).
                child: NumText(
                  label,
                  maxLines: 1,
                  // Status = labelMedium (12/w500) do design system; a cor
                  // reforça o estado, mas o texto já o comunica sozinho.
                  style: AppTypography.labelMedium.copyWith(
                    color: scheme.brightness == Brightness.dark
                        ? color.withValues(alpha: 0.9)
                        : color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
