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
/// | `bodySmall` | 13 | nota · CÉLULA DE TABELA (admin/dados) |
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
/// `tabularFigures` em TODOS os papéis (decisão P1 da auditoria
/// tipográfica): preços, quantidades, percentagens e contagens aparecem
/// também em titleSmall/label* (destaques de linha, chips de filtro,
/// células de tabela) — em texto corrido o recurso é inócuo (só dígitos
/// mudam de largura), então não há custo em carregá-lo globalmente.
/// O ponto único de DINHEIRO continua sendo o SmartAmount; números fora
/// dele usam NumText (ambos reforçam o tabular por segurança).
///
/// Célula de tabela (P1 da auditoria): dados em listas/tabelas densas —
/// ex. painel admin — usam `bodySmall` PURO (13/w400/tabular, cor via
/// copyWith). Não reduza para 12 inline: 12 é papel de LABEL (labelMedium)
/// ou caption (labelSmall), não de dado.
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
        fontFeatures: const [FontFeature.tabularFigures()],
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
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: scheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.25,
        color: scheme.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
