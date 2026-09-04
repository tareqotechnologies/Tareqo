import 'package:flutter/material.dart';

/// Tipografia do TAREQO — Inter (variável, eixos wght + opsz).
///
/// Escala modular Apple HIG / SF Pro (ver `docs/pt/05-apresentacao.md` e
/// capítulo 12 — Decisões de Arquitetura):
///
/// | Papel | Tamanho | Uso |
/// |---|---|---|
/// | `displaySmall` | 34 | Large Title — login/boas-vindas, totais consolidados |
/// | `headlineMedium` | 28 | Título 1 — cabeçalhos de página/seções |
/// | `headlineSmall` | 24 | Título 1.5 — KPIs/totais |
/// | `titleLarge` | 22 | Título 2 — cartões de resumo, modais, AppBar |
/// | `titleMedium` | 20 | Título 3 — subtítulos/seções |
/// | `titleSmall` | 14 | destaque de linha (peso) |
/// | `bodyLarge` | 17 | corpo destacado |
/// | `bodyMedium` | 15 | corpo |
/// | `bodySmall` | 13 | nota |
/// | `labelLarge` | 14 | ações |
/// | `labelMedium` | 12 | labels |
/// | `labelSmall` | 11 | caption/badge |
///
/// Três eixos de precisão (SF Pro):
/// - **tracking** negativo nos títulos (−0.15 a −0.6), neutro no corpo,
///   positivo leve nos captions;
/// - **entrelinha** na razão do SF Pro (~1.2 títulos, ~1.4 corpo);
/// - **eixo óptico** `opsz`: títulos ≥20px usam o corte *Display*
///   (24–32); corpo/captions ficam no corte *Texto* (sem variação).
///
/// `tabularFigures` apenas nos estilos **numéricos** (preços MZN e
/// quantidades alinham dígito a dígito); rótulos (titleSmall,
/// labelLarge/Medium/Small) não carregam números e não o usam.
abstract final class AppTypography {
  /// Constrói o [TextTheme] do app. As cores vêm do [scheme] — o mesmo
  /// tema serve aos modos claro e escuro.
  static TextTheme forScheme(ColorScheme scheme) {
    return TextTheme(
      displaySmall: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.6,
        height: 1.2,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontVariations: const [FontVariation('opsz', 32)],
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        height: 1.2,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontVariations: const [FontVariation('opsz', 32)],
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.25,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontVariations: const [FontVariation('opsz', 32)],
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        height: 1.27,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontVariations: const [FontVariation('opsz', 24)],
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontVariations: const [FontVariation('opsz', 24)],
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.35,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.4,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.35,
        color: scheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.25,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}