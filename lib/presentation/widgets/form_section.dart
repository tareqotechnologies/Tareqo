import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_tokens.dart';
import 'premium_decor.dart';

/// Seção agrupada de formulário — **plana**: rótulo curto + régua fina
/// (`hairline`) e os campos directos sobre a superfície da tela/sheet, sem
/// cartão de fundo.
///
/// O formulário lê-se como uma lista contínua, em vez de caixas dentro de
/// caixas. O ícone do rótulo é discreto (`onSurfaceVariant`); o acento fica
/// reservado para a ação principal.
///
/// É o mesmo componente dentro e fora das sheets: `SheetSection` é apenas
/// o alias usado pelos formulários em bottom sheet.
class FormSection extends StatelessWidget {
  const FormSection({super.key, this.icon, this.title, required this.children});

  final IconData? icon;
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              // O rótulo leva a largura NATURAL (até 60% da linha); a régua
              // preenche o RESTANTE. Sem o ConstrainedBox, `Flexible` +
              // `Expanded` dividiam o espaço a meio e a régua parava no
              // centro da seção.
              final maxLabelWidth = constraints.maxWidth * 0.6;
              return Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: AppSizes.iconSm,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                  ],
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabelWidth),
                    child: Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: PremiumDecor.hairline(scheme),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ...children,
      ],
    );
  }
}
