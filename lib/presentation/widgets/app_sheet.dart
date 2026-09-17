import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_tokens.dart';
import '../widgets/app_button.dart';

/// Abre uma bottom sheet V4 com animação suave e suporte fullscreen.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool fullscreen = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: AppDurations.fast,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: fullscreen
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(top: Radius.circular(28)),
              border: fullscreen
                  ? null
                  : Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fullscreen)
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 4),
                    child: _SheetHandle(),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 6),
                    child: _SheetHandle(),
                  ),
                Flexible(
                  child: fullscreen
                      ? SizedBox(
                          height: MediaQuery.sizeOf(context).height,
                          child: builder(context),
                        )
                      : builder(context),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Seção agrupada dentro de uma sheet — container com fundo sutil,
/// cantos arredondados e padding interno. Inspira-se no card de atividade
/// do dashboard (surfaceContainerHighest, AppRadius.xl, borda sutil)
/// para dar hierarquia visual aos formulários.
///
/// Use [icon] + [title] para rótulo de seção (opcional), e coloque os
/// campos do formulário como [children].
class SheetSection extends StatelessWidget {
  const SheetSection({
    super.key,
    this.icon,
    this.title,
    required this.children,
  });

  final IconData? icon;
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 10),
                ],
                Text(
                  title!,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }
}

/// Cabeçalho UNIFICADO das sheets — fechar à esquerda, título (e subtítulo
/// opcional) centrado, acção principal à direita.
///
/// * Sheets com acção (formulários/filtros): passe [onSave] + [actionLabel]
///   (ex.: "Guardar", "Aplicar") — o rótulo vem de quem usa, sem default
///   genérico de produto.
/// * Sheets de leitura/detalhe (sem acção): omita [onSave]/[actionLabel] —
///   o espaço à direita é preenchido para manter o título centrado.
///
/// Este é o ÚNICO cabeçalho de sheet do design system (o antigo
/// `AppSheetHeader`, com título à esquerda, foi absorvido aqui).
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSave,
    this.actionLabel,
    this.isSaving = false,
    this.onClose,
  });

  final String title;

  /// Linha de apoio sob o título (ex.: contagem, contexto).
  final String? subtitle;

  /// Acção principal. `null` = sheet sem acção (só fechar).
  final VoidCallback? onSave;
  final String? actionLabel;
  final bool isSaving;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final hasAction = onSave != null && actionLabel != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            tooltip: l10n.appSheetClose,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Ação real ou espaçador da largura do IconButton: o título fica
          // centrado nos dois casos (balanceamento do Row).
          if (hasAction)
            AppButton.primary(
              label: actionLabel!,
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}

