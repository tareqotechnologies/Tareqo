import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'app_card.dart';

/// Aviso compacto de falha de carregamento V4.
class InlineErrorCard extends StatelessWidget {
  const InlineErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = scheme.error;
    // Com texto ampliado o rótulo do retry consome a linha inteira e a
    // mensagem quebra letra a letra — o botão passa para baixo.
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.4;

    final iconBadge = Container(
      width: AppSizes.avatarSm,
      height: AppSizes.avatarSm,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.14),
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(Icons.error_outline, size: AppSizes.iconMd, color: error),
    );

    final messageText = Text(
      message,
      style: AppTypography.bodyMedium.copyWith(color: scheme.onSurface),
    );

    final retry = TextButton(
      onPressed: onRetry,
      child: Text(context.l10n.commonRetry),
    );

    final content = largeText
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  iconBadge,
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: messageText),
                ],
              ),
              Align(alignment: Alignment.centerRight, child: retry),
            ],
          )
        : Row(
            children: [
              iconBadge,
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: messageText),
              retry,
            ],
          );

    return AppCard(
      borderColor: error.withValues(alpha: 0.35),
      color: error.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: content,
    );
  }
}
