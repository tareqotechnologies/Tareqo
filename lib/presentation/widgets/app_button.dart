import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Botão padrão V4 — variantes primary, secondary e danger.
///
/// Física de press (estilo Apple): TODOS os botões respondem ao toque com
/// escala 0.98 (80ms) e regressam suavemente; `pressScale: false` desliga-a
/// onde o botão vive dentro de gestos próprios. O gradiente sutil (`gradient: true`) só existe quando o botão está
/// HABILITADO — o estado desabilitado recua para o fill flat padrão (a
/// desmotivação visual do gesto é parte do feedback).
class AppButton extends StatefulWidget {
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.expanded = false,
    this.gradient = false,
    this.pressScale = true,
  }) : _variant = _AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.expanded = false,
  }) : _variant = _AppButtonVariant.secondary,
       gradient = false,
       pressScale = true;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style,
    this.expanded = false,
  }) : _variant = _AppButtonVariant.danger,
       gradient = false,
       pressScale = true;

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonStyle? style;
  final bool expanded;

  /// Gradiente sutil (primary → véu neutro de onPrimary, brilho metálico)
  /// no fundo — só no primary HABILITADO (F4.1: o botão de pagamento "acende" quando o carrinho
  /// permite confirmar).
  final bool gradient;

  /// Escala 0.98 no press com retorno em 80ms (F4.1) — respeita
  /// `MediaQuery.disableAnimationsOf` (movimento reduzido = botão estático).
  final bool pressScale;

  final _AppButtonVariant _variant;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  /// 1.0 = repouso; 0.98 = pressionado.reverse() no down, forward() no up.
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: AppDurations.fast, // 150ms; opress usa 80ms — ver build
      value: 1,
    );
    _scale = Tween<double>(
      begin: 0.98,
      end: 1,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  void _onPointerDown(_) {
    if (!_enabled || !widget.pressScale) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _press.animateTo(0, duration: const Duration(milliseconds: 80));
  }

  void _onPointerUp(_) {
    if (!_enabled || !widget.pressScale) return;
    _press.forward();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Widget content;
    if (widget.icon != null) {
      // Flexible no rótulo: numa Row, filho sem flex recebe largura
      // ilimitada no eixo principal e estoura com texto longo (fr a 360dp
      // ou escala de texto 2.0). Com Flexible o rótulo quebra em 2 linhas
      // em vez de vazar do botão.
      content = Row(
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.icon!,
          const SizedBox(width: AppSpacing.xs),
          Flexible(child: Text(widget.label, textAlign: TextAlign.center)),
        ],
      );
    } else {
      content = Text(widget.label);
    }

    final Widget button;
    switch (widget._variant) {
      case _AppButtonVariant.primary:
        if (widget.gradient && _enabled) {
          // Gradiente sutil: o fill fica TRANSPARENTE e o Ink pinta o
          // gradiente DENTRO da forma do botão (mesma borda/ripple).
          button = FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
            ).merge(widget.style),
            child: Ink(
              decoration: BoxDecoration(
                // Minimalista: cor sólida azul (paleta oficial). Sem
                // gradiente com tons fora da paleta.
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: content,
            ),
          );
        } else {
          button = FilledButton(
            onPressed: widget.onPressed,
            style: widget.style,
            child: content,
          );
        }
      case _AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: widget.onPressed,
          style: widget.style,
          child: content,
        );
      case _AppButtonVariant.danger:
        button = FilledButton(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ).merge(widget.style),
          child: content,
        );
    }

    Widget result = button;
    if (widget.pressScale && _enabled) {
      result = Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerUp,
        child: ScaleTransition(scale: _scale, child: result),
      );
    }

    if (!widget.expanded) return result;
    return SizedBox(width: double.infinity, child: result);
  }
}

enum _AppButtonVariant { primary, secondary, danger }
