import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
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
    final error = theme.colorScheme.error;

    return AppCard(
      borderColor: error.withValues(alpha: 0.35),
      color: error.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.avatarSm,
            height: AppSizes.avatarSm,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: error.withValues(alpha: 0.14),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(Icons.error_outline, size: 18, color: error),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.commonRetry)),
        ],
      ),
    );
  }
}
