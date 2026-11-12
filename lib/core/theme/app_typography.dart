import 'package:flutter/material.dart';

/// Tipografia do TAREQO — dois cortes do anexo (Text & Styles):
/// **Regular (400)** e **Medium (500)**. Semibold não faz parte do tema.
///
/// A família do guia de identidade (Inter, Google Fonts) — variável OFL 1.1,
/// eixos wght 100–900 e opsz — resolve Regular no corpo, Medium nos títulos
/// e controlos. O tema usa apenas 400/500.
///
/// Escala modular centralizada — todos os textos, títulos, valores financeiros,
/// botões, campos, cards, filtros, modais, notificações e elementos de navegação
/// devem usar estes tokens reutilizáveis em vez de definições inline.
///
/// Referências: Material Design 3, acessibilidade, aplicações financeiras.
/// Plataforma: Android (sp), iOS (Dynamic Type), Web (rem).
///
/// **Escala modular (tamanho / entrelinha / peso):**
///
/// | Token | px | LH | Peso | Uso |
/// |-------|----|----|------|-----|
/// | display | 28 | 36 | 500 | Saldo principal, grandes destaques. O maior elemento da tela. |
/// | headline | 24 | 32 | 500 | Títulos de página principais. |
/// | titleLarge | 20 | 28 | 500 | Títulos de blocos e referências. |
/// | sectionTitle | 18 | 24 | 500 | Títulos de secção. |
/// | titleMedium | 16 | 24 | 500 | Títulos de card e grupos de informações. |
/// | bodyLarge | 16 | 24 | 400 | Textos principais e descrições importantes. |
/// | bodyMedium | 14 | 20 | 400 | Textos secundários, listas e informações gerais. |
/// | bodySmall | 12 | 16 | 400 | Metadados e informações complementares. |
/// | labelLarge | 14 | 20 | 500 | Botões, controles e ações principais. |
/// | labelMedium | 12 | 16 | 500 | Filtros, status e ações secundárias. |
/// | labelSmall | 11 | 16 | 500 | Apenas informação não essencial. |
///
/// Pesos permitidos no tema: **400 (Regular) e 500 (Medium)**. O Medium
/// cobre títulos, botões e o valor dominante. Listas de transações usam
/// valores em 15/w500 ([amountInRow]): o número alinha, mas não domina a linha.
abstract final class AppTypography {
  /// Família tipográfica principal.
  ///
  /// Flutter resolve `fontFamily` pelo **nome exato** registrado no pubspec
  /// (`fonts: - family: Inter`). Uma lista no estilo CSS
  /// (`'Inter, -apple-system, …'`) não é resolvida pelo motor e cai
  /// silenciosamente na fonte padrão da plataforma — por isso a família é o
  /// nome puro e o fallback de plataforma vive em [familyFallback].
  static const String family = 'Inter';

  /// Fallback por plataforma, consultado apenas quando um glifo não existe na
  /// Inter (a Inter cobre Latin/Latin-Ext — o fallback é rede de segurança).
  static const List<String> familyFallback = <String>[
    'Roboto', // Android
    'Segoe UI', // Windows
    'Helvetica Neue', // iOS / macOS
    'sans-serif', // Web
  ];

  /// --- Tamanhos (px, escalados pelo `textScaler` da plataforma) ---

  static const double displaySize = 28;
  static const double headlineSize = 24;
  static const double titleLargeSize = 20;
  static const double sectionTitleSize = 18;
  static const double sectionTitleLineHeight = 24;
  static const double titleMediumSize = 16;
  static const double bodyLargeSize = 16;
  static const double bodyMediumSize = 14;
  static const double bodySmallSize = 12;
  static const double labelLargeSize = 14;
  static const double labelMediumSize = 12;
  static const double labelSmallSize = 11;

  /// Valor de resumo de ecrã (total do dia) — abaixo do saldo-herói.
  static const double summaryAmountSize = 22;
  static const double summaryAmountLineHeight = 28;

  /// Saldo principal — 26/Medium é o teto de destaque monetário.
  static const double heroAmountSize = 26;
  static const double heroAmountLineHeight = 32;

  /// Valor de linha de transação — alinhado à direita, sem dominar.
  static const double amountInRowSize = 15;
  static const double amountInRowLineHeight = 20;

  /// --- Altura de linha ---

  static const double displayLineHeight = 36;
  static const double headlineLineHeight = 32;
  static const double titleLargeLineHeight = 28;
  static const double titleMediumLineHeight = 24;
  static const double bodyLargeLineHeight = 24;
  static const double bodyMediumLineHeight = 20;
  static const double bodySmallLineHeight = 16;
  static const double labelLargeLineHeight = 20;
  static const double labelMediumLineHeight = 16;
  static const double labelSmallLineHeight = 16;

  /// --- Peso ---

  static const FontWeight displayWeight = FontWeight.w500;
  static const FontWeight headlineWeight = FontWeight.w500;
  static const FontWeight titleLargeWeight = FontWeight.w500;
  static const FontWeight titleMediumWeight = FontWeight.w500;
  static const FontWeight bodyLargeWeight = FontWeight.w400;
  static const FontWeight bodyMediumWeight = FontWeight.w400;
  static const FontWeight bodySmallWeight = FontWeight.w400;
  static const FontWeight labelLargeWeight = FontWeight.w500;
  static const FontWeight labelMediumWeight = FontWeight.w500;
  static const FontWeight labelSmallWeight = FontWeight.w500;

  /// --- Tracking (letter-spacing) ---

  static const double displayLetterSpacing = -0.6;
  static const double headlineLetterSpacing = -0.5;
  static const double titleLargeLetterSpacing = -0.35;
  static const double titleMediumLetterSpacing = -0.3;
  static const double bodyLargeLetterSpacing = -0.1;
  static const double bodyMediumLetterSpacing = -0.1;
  static const double bodySmallLetterSpacing = 0;
  static const double labelLargeLetterSpacing = 0;
  static const double labelMediumLetterSpacing = 0;
  static const double labelSmallLetterSpacing = 0;

  /// --- Font Features ---

  /// tabularFigures em TODOS os papéis: preços, quantidades, percentagens e
  /// contagens aparecem alinhados coluna a coluna. Em texto corrido o recurso
  /// é inócuo (apenas dígitos mudam de largura), então carrega-se globalmente.
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// Único ponto de construção: família, fallback, tracking, tabular e a
  /// razão de entrelinha (LH / tamanho) derivam SEMPRE daqui — evita que os
  /// papéis do [TextTheme] e os getters divirjam entre si.
  static TextStyle _base({
    required double fontSize,
    required double lineHeight,
    required FontWeight fontWeight,
    required double letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: familyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight / fontSize,
      letterSpacing: letterSpacing,
      fontFeatures: tabularFigures,
      color: color,
    );
  }

  /// --- TextStyles centralizadas ---

  /// As cores vêm do [ColorScheme] do tema — o mesmo estilo serve aos modos
  /// claro e escuro. Nunca defina tamanho, peso, altura de linha ou tracking
  /// inline em telas/components: use estes getters, [forScheme] ou
  /// `copyWith(color:)` sobre eles.

  /// display — Saldo principal e destaques importantes. O maior elemento da
  /// hierarquia visual — deve ser dominante pero legível.
  static TextStyle get display => _base(
    fontSize: displaySize,
    lineHeight: displayLineHeight,
    fontWeight: displayWeight,
    letterSpacing: displayLetterSpacing,
  );

  /// headline — Títulos principais de páginas.
  static TextStyle get headline => _base(
    fontSize: headlineSize,
    lineHeight: headlineLineHeight,
    fontWeight: headlineWeight,
    letterSpacing: headlineLetterSpacing,
  );

  /// titleLarge — Títulos de seções e blocos importantes.
  static TextStyle get titleLarge => _base(
    fontSize: titleLargeSize,
    lineHeight: titleLargeLineHeight,
    fontWeight: titleLargeWeight,
    letterSpacing: titleLargeLetterSpacing,
  );

  /// sectionTitle — Títulos de secção (18/Medium), abaixo do título de
  /// página e acima do corpo.
  static TextStyle get sectionTitle => _base(
    fontSize: sectionTitleSize,
    lineHeight: sectionTitleLineHeight,
    fontWeight: FontWeight.w500,
    letterSpacing: titleLargeLetterSpacing,
  );

  /// titleMedium — Títulos de cards, grupos e componentes.
  static TextStyle get titleMedium => _base(
    fontSize: titleMediumSize,
    lineHeight: titleMediumLineHeight,
    fontWeight: titleMediumWeight,
    letterSpacing: titleMediumLetterSpacing,
  );

  /// bodyLarge — Textos principais e descrições importantes.
  static TextStyle get bodyLarge => _base(
    fontSize: bodyLargeSize,
    lineHeight: bodyLargeLineHeight,
    fontWeight: bodyLargeWeight,
    letterSpacing: bodyLargeLetterSpacing,
  );

  /// bodyMedium — Textos secundários, listas e informações gerais.
  static TextStyle get bodyMedium => _base(
    fontSize: bodyMediumSize,
    lineHeight: bodyMediumLineHeight,
    fontWeight: bodyMediumWeight,
    letterSpacing: bodyMediumLetterSpacing,
  );

  /// bodySmall — Metadados e informações complementares.
  static TextStyle get bodySmall => _base(
    fontSize: bodySmallSize,
    lineHeight: bodySmallLineHeight,
    fontWeight: bodySmallWeight,
    letterSpacing: bodySmallLetterSpacing,
  );

  /// labelLarge — Botões, controles e ações principais. Peso 500, tamanho 14px.
  static TextStyle get labelLarge => _base(
    fontSize: labelLargeSize,
    lineHeight: labelLargeLineHeight,
    fontWeight: labelLargeWeight,
    letterSpacing: labelLargeLetterSpacing,
  );

  /// labelMedium — Filtros, status e ações secundárias. Peso 500, tamanho 12px.
  static TextStyle get labelMedium => _base(
    fontSize: labelMediumSize,
    lineHeight: labelMediumLineHeight,
    fontWeight: labelMediumWeight,
    letterSpacing: labelMediumLetterSpacing,
  );

  /// labelSmall — Informação auxiliares não essenciais. Tamanho 11px.
  ///
  /// 11 px só é legítimo em texto acessório (selo de contagem, caption de
  /// apoio). NUNCA em erro/sucesso, valores, labels de campo, botões ou
  /// navegação.
  static TextStyle get labelSmall => _base(
    fontSize: labelSmallSize,
    lineHeight: labelSmallLineHeight,
    fontWeight: labelSmallWeight,
    letterSpacing: labelSmallLetterSpacing,
  );

  /// --- Constrói o [TextTheme] do app com cores do scheme. ---

  /// Os 15 papéis do Material são cobertos — um papel sem mapeamento herdaria
  /// a escala padrão do Material (outra família/tamanho) e quebraria a
  /// consistência. Papéis "extras" do M3 apontam para o degrau mais próximo:
  ///
  /// * `display*` → display (28)   * `headline*` → headline (24)
  /// * `titleSmall` → degrau 14/w500 (labelLarge): destaque de linha em
  ///   listas, onde a hierarquia vem da cor e da posição, não do peso.
  static TextTheme forScheme(ColorScheme scheme) {
    final onSurface = scheme.onSurface;
    return TextTheme(
      displayLarge: display.copyWith(color: onSurface),
      displayMedium: display.copyWith(color: onSurface),
      displaySmall: display.copyWith(color: onSurface),
      headlineLarge: headline.copyWith(color: onSurface),
      headlineMedium: headline.copyWith(color: onSurface),
      headlineSmall: headline.copyWith(color: onSurface),
      titleLarge: titleLarge.copyWith(color: onSurface),
      titleMedium: titleMedium.copyWith(color: onSurface),
      titleSmall: labelLarge.copyWith(color: onSurface),
      bodyLarge: bodyLarge.copyWith(color: onSurface),
      bodyMedium: bodyMedium.copyWith(color: onSurface),
      bodySmall: bodySmall.copyWith(color: onSurface),
      labelLarge: labelLarge.copyWith(color: onSurface),
      labelMedium: labelMedium.copyWith(color: onSurface),
      labelSmall: labelSmall.copyWith(color: onSurface),
    );
  }

  /// --- TextStyles específicas para contexto financeiro ---

  /// [TextStyle] do valor-herói de um ecrã (26/Medium, tabular) — o saldo
  /// principal ou o total mais importante do resumo. 26 é o teto: mesmo o
  /// número de destaque não deve parecer um título.
  static TextStyle heroAmount(Color color) => _base(
    fontSize: heroAmountSize,
    lineHeight: heroAmountLineHeight,
    fontWeight: FontWeight.w500,
    letterSpacing: displayLetterSpacing,
    color: color,
  );

  /// [TextStyle] do total de um resumo compacto (22/Medium, tabular) — o
  /// valor do dia em Vendas. Hierarquia clara sem competir com o
  /// [heroAmount] nem com o título do ecrã.
  static TextStyle summaryAmount(Color color) => _base(
    fontSize: summaryAmountSize,
    lineHeight: summaryAmountLineHeight,
    fontWeight: FontWeight.w500,
    letterSpacing: titleLargeLetterSpacing,
    color: color,
  );

  /// [TextStyle] de um valor em linha de transação (15/w500, tabular) — o
  /// montante alinha coluna a coluna entre linhas consecutivas, mas não é o
  /// elemento dominante da lista. Descrições e datas ficam em 400.
  static TextStyle amountInRow(Color color) => _base(
    fontSize: amountInRowSize,
    lineHeight: amountInRowLineHeight,
    fontWeight: FontWeight.w500,
    letterSpacing: bodyMediumLetterSpacing,
    color: color,
  );

  /// Rótulo de contexto em caixa alta (11/w500, tracking 0.8) — o "HOJE"
  /// acima de um valor-herói ou o título de uma secção de lista.
  ///
  /// Caixa alta é aceite aqui porque é uma etiqueta curta de hierarquia; o
  /// texto vem do ARB já em maiúsculas (não é transformação em runtime).
  static TextStyle eyebrow(Color color) => _base(
    fontSize: labelSmallSize,
    lineHeight: labelSmallLineHeight,
    fontWeight: labelSmallWeight,
    letterSpacing: 0.8,
    color: color,
  );

  /// Rótulo da navegação inferior/rail — 12 px, nunca 11.
  /// Repouso = Regular (400); destino ativo = Medium (500).
  static TextStyle navigationLabel(Color color, {bool selected = false}) =>
      _base(
        fontSize: labelMediumSize,
        lineHeight: labelMediumLineHeight,
        fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
        letterSpacing: 0,
        color: color,
      );
}
