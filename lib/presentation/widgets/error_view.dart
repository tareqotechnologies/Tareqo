import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Estado de erro V4 — mensagem + detalhe técnico + retry.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.details,
  });

  final String message;
  final String? details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.gigantic,
              height: AppSpacing.gigantic,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: AppRadius.xlAll,
                border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: AppSizes.iconXl,
                color: scheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: scheme.onSurface,
              ),
            ),
            if (details != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                details!,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              label: context.l10n.commonRetry,
              icon: const Icon(Icons.refresh, size: AppSizes.iconSm),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
