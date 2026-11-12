import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/app_button.dart';
import 'premium_decor.dart';

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
          child: _SheetScaleIn(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: fullscreen
                    ? BorderRadius.zero
                    : const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                border: fullscreen
                    ? null
                    : Border(
                        top: BorderSide(color: PremiumDecor.hairline(scheme)),
                      ),
                // Sombra que "sobe" do rodapé — a sheet flutua sobre o
                // ecrã em vez de colar-se a ele.
                boxShadow: fullscreen
                    ? null
                    : PremiumDecor.upwardShadow(scheme),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fullscreen)
                    const Padding(
                      padding: EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xxs,
                      ),
                      child: SheetHandle(),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                      ),
                      child: SheetHandle(),
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
        ),
      );
    },
  );
}

/// Entrada da sheet (plano UI/UX — F4.3): **scale 0.92 + fade** — o padrão
/// iOS "card stack" de abertura. Encapsulado AQUI (não no chamador): toda
/// sheet do app herda a mesma física de entrada sem propagação de flags.
/// O slide nativo do `showModalBottomSheet` continua existindo — o scale
/// é o acabamento por cima. Respeita `MediaQuery.disableAnimationsOf`
/// (movimento reduzido = entrada estática, o slide de rota cuida do resto).
class _SheetScaleIn extends StatelessWidget {
  const _SheetScaleIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.normal,
      curve: AppCurves.standard,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      ),
      child: child,
    );
  }
}

/// Scaffold ÚNICO de formulário em sheet.
///
/// Padroniza o ritmo visual de TODOS os formulários de criação/edição:
/// cabeçalho → conteúdo (seções `SheetSection`) → erro → ação primária de
/// largura total. Quem chama só declara os campos; scroll, padding, teclado,
/// limite de altura e estado de envio ficam aqui — nenhum formulário
/// reimplementa (ou esquece) uma parte do padrão.
///
/// * [formKey] liga o [Form] interno (validação com os `AppTextField`).
/// * [error] aparece imediatamente acima da ação, em bloco compacto.
/// * [actionLabel]/[onSubmit]/[isSubmitting] desenham o botão primário no
///   rodapé, com spinner no lugar do ícone durante o envio.
/// * [leading] permite uma peça fixa no topo do conteúdo (ex.: foto).
class SheetForm extends StatelessWidget {
  const SheetForm({
    super.key,
    this.formKey,
    required this.title,
    required this.children,
    this.error,
    this.actionLabel,
    this.onSubmit,
    this.isSubmitting = false,
    this.actionIcon,
    this.headerSubtitle,
    this.maxHeightFactor = 0.9,
    this.scrollKey,
  });

  final GlobalKey<FormState>? formKey;
  final String title;
  final String? headerSubtitle;
  final List<Widget> children;

  /// Mensagem de erro do formulário (exceção de domínio/servidor).
  final String? error;

  /// Rótulo da ação principal. `null` = formulário sem ação no rodapé.
  final String? actionLabel;
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  /// Ícone opcional da ação (o spinner o substitui durante o envio).
  final Widget? actionIcon;

  /// Fração máxima da altura do ecrã ocupada pela sheet.
  final double maxHeightFactor;

  /// Chave opcional do scroll (testes que precisam de `dragUntilVisible`).
  final Key? scrollKey;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
      ),
      child: SingleChildScrollView(
        key: scrollKey,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: AppSpacing.sheetPadding,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: title, subtitle: headerSubtitle),
              const SizedBox(height: AppSpacing.md),
              ...children,
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                SheetFormError(message: error!),
              ],
              if (hasAction) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton.primary(
                  label: actionLabel!,
                  onPressed: isSubmitting ? null : onSubmit,
                  icon: isSubmitting
                      ? const SizedBox(
                          height: AppSizes.iconMd,
                          width: AppSizes.iconMd,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : actionIcon,
                ),
              ] else
                const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Erro de formulário — bloco compacto com ícone, acima da ação.
///
/// Usa `theme.expense` (tinta de despesa com AA garantido nos dois temas)
/// em vez do vermelho puro, que falha contraste como texto no papel escuro.
class SheetFormError extends StatelessWidget {
  const SheetFormError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.expense.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: AppSizes.iconMd,
            color: theme.expense,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: theme.expense),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seção agrupada dentro de uma sheet — o grupo de campos do formulário.
///
/// Uma única superfície neutra (o tint quente do tema a 45%), cantos 18 e
/// **sem borda**: a hierarquia vem do agrupamento, do espaçamento e do
/// rótulo — não de uma caixa dentro da caixa. O ícone do rótulo é discreto
/// (`onSurfaceVariant`); o acento fica reservado para a ação principal da
/// sheet.
///
/// Use [icon] + [title] para o rótulo da seção (opcional) e coloque os
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: AppRadius.lgAll,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppSizes.iconSm,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Expanded(
                  child: Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
    final scheme = Theme.of(context).colorScheme;
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
          bottom: BorderSide(color: PremiumDecor.hairline(scheme)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, size: AppSizes.iconMd),
            color: scheme.onSurfaceVariant,
            onPressed: onClose ?? () => Navigator.of(context).pop(),
            tooltip: l10n.appSheetClose,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Textos longos ("Registrar movimentação") NÃO truncam:
                // título SEM maxLines/ellipsis e auto-size — em telas
                // estreitas ou com escala de texto alta o rótulo encolhe
                // (fator mínimo 0.8, ~12.8pt de um titleMedium 16pt) para
                // continuar 100% legível em uma linha.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    // Título de sheet no papel "Título 2": a sheet é um
                    // ecrã, e o título dela lê-se como tal.
                    style: AppTypography.titleMedium.copyWith(
                      color: scheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: false,
                    maxLines: 1,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
                      height: AppSizes.iconSm,
                      width: AppSizes.iconSm,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            )
          else
            const SizedBox(width: AppSizes.touchTarget),
        ],
      ),
    );
  }
}

/// Alça de arraste das sheets — 36×5, discreta. Pública para sheets que
/// montam o próprio contentor (ex.: detalhe de notificação) herdarem o
/// mesmo desenho em vez de duplicarem a barra.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}
