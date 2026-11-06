import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'premium_decor.dart';

/// Estado vazio V4 — ícone, título, subtítulo e ação opcional.
///
/// Adições de microinteração (F4.2):
/// - Ícone com pulse suave (loop 2.4s) para dar vida ao estado estático,
///   respeitando MediaQuery.disableAnimationsOf.
/// - Título e subtítulo podem usar AnimatedSwitcher para fade-in.
/// - Ação com escala 0.98 no press (já existente em AppButton.pressScale).
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
            // Ícone num halo em camadas com entrada única (scale + fade,
            // 420ms) — dá vida ao estado sem animação infinita (testes com
            // pumpAndSettle continuam a assentar). Respeita reduce-motion.
            _EmptyHalo(icon: icon),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
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

/// Halo do estado vazio — anel exterior difuso, disco interior em
/// gradiente subtil e o ícone ao centro.
class _EmptyHalo extends StatelessWidget {
  const _EmptyHalo({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    final halo = SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  scheme.primary.withValues(alpha: dark ? 0.16 : 0.10),
                  scheme.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surface,
              gradient: PremiumDecor.iconTint(scheme.primary, dark: dark),
              border: Border.all(color: PremiumDecor.hairline(scheme)),
              boxShadow: PremiumDecor.softShadow(scheme),
            ),
            child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    if (MediaQuery.disableAnimationsOf(context)) return halo;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.86 + 0.14 * t, child: child),
      ),
      child: halo,
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
      key: ValueKey('inline_empty_$message'),
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
