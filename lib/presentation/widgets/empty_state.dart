import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_button.dart';
import 'app_card.dart';

/// Estado vazio V4 — ícone, título, subtítulo e ação opcional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.outlinedAction = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Quando `true`, renderiza a ação como botão OUTLINED em vez de
  /// `AppButton.primary` — útil para ações secundárias (ex.: "Limpar
  /// filtros") em estados vazios derivados de filtro ativo. Mantém o
  /// `AppButton.primary` (CTA forte) como padrão para o primeiro
  /// estado vazio (zero cadastros).
  final bool outlinedAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Center + SingleChildScrollView: em alturas apertadas (ex.: o PDV em
    // ecrãs baixos) o conteúdo rola em vez de estourar ("bottom overflowed");
    // quando há espaço, fica centralizado como sempre.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: AppRadius.xlAll,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              if (outlinedAction)
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.outline),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(actionLabel!),
                )
              else
                AppButton.primary(
                  label: actionLabel!,
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: onAction,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mensagem inline de seção vazia (menor peso visual que [EmptyState]).
class InlineEmpty extends StatelessWidget {
  const InlineEmpty({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      color: Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              message,
              textAlign: icon == null ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
