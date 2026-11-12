import 'package:flutter/material.dart';

/// Acabamento "premium" partilhado — profundidade, gradientes de marca e
/// brilhos suaves num ÚNICO lugar, para todos os componentes falarem a
/// mesma linguagem visual.
///
/// Regras:
/// * Só papéis do `ColorScheme` (ou cores já do tema passadas pelo
///   chamador) — nenhum hex fora do tema.
/// * Sombras NEUTRAS em camadas (contacto + ambiente), nunca coloridas
///   por estado; o brilho colorido ([glow]) fica reservado a CTAs e marca.
/// * Tudo é decoração: nenhum helper altera layout, semântica ou lógica.
class PremiumDecor {
  const PremiumDecor._();

  static bool _isDark(ColorScheme scheme) =>
      scheme.brightness == Brightness.dark;

  /// Borda de cabelo — define a forma sem pesar.
  static Color hairline(ColorScheme scheme) =>
      scheme.outlineVariant.withValues(alpha: _isDark(scheme) ? 0.45 : 0.65);

  /// Sombra em repouso: contacto curto + ambiente difuso.
  static List<BoxShadow> softShadow(ColorScheme scheme, {double strength = 1}) {
    final dark = _isDark(scheme);
    final base = scheme.shadow;
    return [
      BoxShadow(
        color: base.withValues(alpha: (dark ? 0.28 : 0.04) * strength),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: base.withValues(alpha: (dark ? 0.32 : 0.06) * strength),
        blurRadius: 24,
        spreadRadius: -6,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// Sombra elevada (hover/realce): o cartão "sobe" ligeiramente.
  static List<BoxShadow> liftShadow(ColorScheme scheme) {
    final dark = _isDark(scheme);
    final base = scheme.shadow;
    return [
      BoxShadow(
        color: base.withValues(alpha: dark ? 0.32 : 0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: base.withValues(alpha: dark ? 0.42 : 0.10),
        blurRadius: 32,
        spreadRadius: -8,
        offset: const Offset(0, 16),
      ),
    ];
  }

  /// Sombra para superfícies que sobem do fundo do ecrã (sheets, barra).
  static List<BoxShadow> upwardShadow(ColorScheme scheme) {
    final dark = _isDark(scheme);
    return [
      BoxShadow(
        color: scheme.shadow.withValues(alpha: dark ? 0.40 : 0.10),
        blurRadius: 30,
        spreadRadius: -4,
        offset: const Offset(0, -6),
      ),
    ];
  }

  /// Brilho colorido difuso — só para CTAs e marca.
  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
    BoxShadow(
      color: color.withValues(alpha: 0.30 * strength),
      blurRadius: 22,
      spreadRadius: -6,
      offset: const Offset(0, 10),
    ),
  ];

  /// Gradiente de marca (primary → brilho neutro), o mesmo do CTA de pagamento.
  static LinearGradient brandGradient(ColorScheme scheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      scheme.primary,
      Color.lerp(scheme.primary, scheme.onPrimary, 0.18)!,
    ],
  );

  /// Superfície de hero: o cartão do tema com um véu neutro quase
  /// imperceptível nos cantos — profundidade sem tingir o conteúdo.
  /// A marca (tinta) fica no traço do rótulo e nos CTAs, não no fundo.
  static LinearGradient heroSurface(ColorScheme scheme, {Color? tint}) {
    final dark = _isDark(scheme);
    final t = tint ?? scheme.onSurface;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0, 0.55, 1],
      colors: [
        Color.alphaBlend(
          t.withValues(alpha: dark ? 0.07 : 0.035),
          scheme.surface,
        ),
        scheme.surface,
        Color.alphaBlend(
          t.withValues(alpha: dark ? 0.03 : 0.015),
          scheme.surface,
        ),
      ],
    );
  }

  /// Fundo tingido para badges de ícone (gradiente subtil da própria cor).
  static LinearGradient iconTint(Color color, {bool dark = false}) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: dark ? 0.26 : 0.18),
          color.withValues(alpha: dark ? 0.10 : 0.06),
        ],
      );
}

/// Halo radial decorativo (luz suave num canto do hero/ecrã). Não recebe
/// toques e não participa da semântica.
class PremiumGlow extends StatelessWidget {
  const PremiumGlow({
    super.key,
    required this.color,
    this.size = 220,
    this.opacity = 0.14,
  });

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
