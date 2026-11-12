import 'package:flutter/material.dart';

/// Paleta OFICIAL do sistema (identidade Tareqo 2026 — "Shades of gray"):
///
/// **Escala neutra oficial (10 passos, do anexo):**
/// * Preto: [black100] `#0A0E15`, [black90] `#212631`, [black80]
///   `#373F4E`, [black70] `#4E576A`, [black60] `#667085`.
/// * Branco: [white100] `#FFFFFF`, [white90] `#F0F1F5`, [white80]
///   `#E0E4EB`, [white70] `#D1D6E0`, [white60] `#BFC5D4`.
///
/// **Acento único — tinta monocromática:** não existe laranja na
/// identidade. O acento é o próprio Preto 100 (claro) / Branco 100
/// (escuro): CTA primário, foco, selecção e marca. Tudo o resto é
/// neutro (superfícies, ícones, segmentos, selos informativos).
///
/// **Sem tints derivados de marca:** os únicos valores fora da escala
/// são os alertas semânticos (verde/vermelho), sempre acompanhados de
/// ícone e rótulo.
///
/// **Alertas semânticos** (exceção controlada à paleta, sempre acompanhados
/// de ícone e rótulo): sucesso `#2E7D32`, erro `#C62828`; aviso usa a
/// escala neutra (Preto 70/Branco 60) — sem laranja. No escuro os valores
/// de TEXTO usam tints AA (`#66BB6A`/`#FF8A80`).
///
/// Acessibilidade (WCAG, medido sobre os pares nativos):
/// - Preto 100 sobre branco 100 ≈ **19:1** (AAA) e branco sobre preto 100
///   ≈ **19:1**.
/// - Branco 80 sobre preto 90 ≈ **15:1**; branco 60 sobre preto 90 ≈
///   **8.8:1** (AA texto).
/// - Preto 70 sobre branco 90 ≈ **6.4:1** (AA) — texto secundário claro.
/// - Branco 100 sobre Preto 100 ≈ **19:1** — rótulo do botão primário.
/// - Preto 60 sobre branco 90 ≈ **4.4:1** (bordas de controlo ≥ 3:1).
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────
  // 0. Escala neutra oficial (únicas cores sólidas permitidas)
  // ─────────────────────────────────────────────────────────────────────

  /// Preto 100 `#0A0E15` — tinta máxima (claro) e canvas profundo (escuro).
  static const Color black100 = Color(0xFF0A0E15);

  /// Preto 90 `#212631` — superfície (cartões, listas, barras) no escuro.
  static const Color black90 = Color(0xFF212631);

  /// Preto 80 `#373F4E` — superfície elevada/agrupada no escuro.
  static const Color black80 = Color(0xFF373F4E);

  /// Preto 70 `#4E576A` — bordas fortes e texto secundário no claro.
  static const Color black70 = Color(0xFF4E576A);

  /// Preto 60 `#667085` — bordas de controlo, ícones e texto terciário.
  static const Color black60 = Color(0xFF667085);

  /// Branco 100 `#FFFFFF` — canvas/cartões claros e texto no escuro.
  static const Color white100 = Color(0xFFFFFFFF);

  /// Branco 90 `#F0F1F5` — canvas claro e zonas agrupadas/campos.
  static const Color white90 = Color(0xFFF0F1F5);

  /// Branco 80 `#E0E4EB` — divisores e contornos decorativos no claro.
  static const Color white80 = Color(0xFFE0E4EB);

  /// Branco 70 `#D1D6E0` — contorno estrutural suave no claro.
  static const Color white70 = Color(0xFFD1D6E0);

  /// Branco 60 `#BFC5D4` — estado desactivado no claro.
  static const Color white60 = Color(0xFFBFC5D4);

  // ── Aliases da escala (nomes curtos usados nos papéis) ────────────────

  /// Alias de [black100] — tinta e canvas escuro.
  static const Color darkVoid = black100;

  /// Alias de [black90] — superfície no escuro.
  static const Color gluonGrey = black90;

  /// Alias de [black80] — superfície elevada no escuro.
  static const Color slateGrey = black80;

  /// Alias de [black60] — bordas e texto não essencial.
  static const Color dustyGrey = black60;

  /// Alias de [white100] — canvas claro e texto sobre o escuro.
  static const Color snow = white100;

  /// Alias de [black70] — texto secundário no tema claro.
  static const Color ashText = black70;

  /// Alias de [white60] — texto secundário no escuro.
  static const Color ashDark = white60;

  /// Zona agrupada / fundo de campo no claro (Branco 90).
  static const Color snowMist = white90;

  /// Contorno decorativo no claro (Branco 80).
  static const Color smokeBorder = white80;

  /// Selos informativos neutros — tinta (nunca acento).
  static const Color neutralInfo = black100;

  // ── Alertas semânticos (excepção controlada) ─────────────────────────

  /// Sucesso `#2E7D32` (texto AA no claro, 4.96:1 sobre Snow).
  static const Color alertSuccess = Color(0xFF2E7D32);

  /// Erro `#C62828` (texto AA no claro, 5.4:1 sobre Snow).
  static const Color alertError = Color(0xFFC62828);

  /// Aviso: Preto 70 (estado indicado também por ícone e rótulo).
  static const Color alertWarning = black70;

  // ── Aliases legados dos nomes da paleta anterior ─────────────────────
  // Mantidos para não tocar em centenas de call sites; todos apontam para
  // a paleta nova. Não usar em código novo.

  /// LEGADO: acção/marca (agora tinta).
  static const Color brandBlue = black100;

  /// LEGADO: Dusty (borda de controlo no claro).
  static const Color grayMid = dustyGrey;

  /// LEGADO: SnowMist (zona agrupada no claro).
  static const Color surfaceGray = snowMist;

  /// LEGADO: Snow (canvas claro / texto sobre escuro).
  static const Color softWhite = snow;

  /// LEGADO: Void (tinta e canvas escuro).
  static const Color brandInk = darkVoid;

  // ─────────────────────────────────────────────────────────────────────
  // 0.1 Tints semânticos de TEXTO no escuro (WCAG AA)
  // ─────────────────────────────────────────────────────────────────────

  /// Sucesso como texto no escuro (≈7.3:1 sobre Gluon).
  static const Color successTextDark = Color(0xFF66BB6A);

  /// Erro como texto no escuro (≈7.5:1 sobre Gluon; ≥3:1 no selo a 22%).
  static const Color errorTextDark = Color(0xFFFF8A80);

  // ─────────────────────────────────────────────────────────────────────
  // 1. Tema claro (paleta oficial)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas — fundo da aplicação (Branco 90, deixa os cartões brancos
  /// "flutuar" sem sombra pesada).
  static const Color lightBackground = white90;

  /// surface — cartões, listas, sheets (Branco 100).
  static const Color lightSurface = white100;

  /// surfaceSunken — zonas agrupadas e fundo de inputs (Branco 90).
  static const Color lightSurfaceSecondary = white90;

  /// surfaceRaised — superfície com elevação (Branco 100).
  static const Color lightSurfaceElevated = white100;

  /// textPrimary — Preto 100 sobre Branco 100 (19:1).
  static const Color lightTextPrimary = black100;

  /// textSecondary — Preto 70 ≈6.4:1 sobre o canvas (AA).
  static const Color lightTextSecondary = black70;

  /// textTertiary — o mesmo cinza legível (AA).
  static const Color lightTextTertiary = black70;

  /// border — hairlines e contornos decorativos (Branco 80).
  static const Color lightBorder = white80;

  /// borderStrong — contorno estrutural (Preto 100).
  static const Color lightBorderStrong = black100;

  /// Control border (outline buttons, fields) — Preto 60 (4.4:1 sobre o
  /// canvas e o fill do campo; WCAG 1.4.11 exige ≥3:1).
  static const Color controlBorder = black60;

  /// separator — linhas de lista e tabela.
  static const Color lightDivider = white80;

  /// textDisabled — Branco 60 sobre o canvas (estado desactivado).
  static const Color lightTextDisabled = white60;

  /// actionFill — fundo de botão primário (Preto 100).
  /// Rótulo sobre ele = Branco 100 (19:1, AAA texto).
  static const Color lightPrimary = black100;

  /// textOnAction — Branco 100 sobre Preto 100.
  static const Color lightOnPrimary = white100;

  /// Botão secundário: superfície com contorno.
  static const Color lightSecondaryAction = snow;

  /// Texto do botão secundário.
  static const Color lightOnSecondary = darkVoid;

  /// action — ícones, foco e selecção no claro (Preto 100, 19:1).
  static const Color lightAction = black100;

  /// actionText — links e texto de acção (Preto 100, AA).
  static const Color lightActionText = black100;

  /// actionPressed — estado premido.
  static const Color lightActionPressed = black80;

  /// actionSoft — fonte do véu de selecção (Preto 100, alfa no chamador).
  static const Color lightActionSoft = black100;

  /// actionBorder — contorno de selecção (Preto 100 ≥3:1).
  static const Color lightActionBorder = black100;

  /// Acento da marca — tinta Preto 100.
  static const Color accentBlue = black100;

  /// Acento de TRAÇO no claro — Preto 100; no escuro, Branco 100.
  static Color accentOn(Brightness brightness) =>
      brightness == Brightness.light ? black100 : darkAction;

  /// Fonte do véu de acento (quem pinta aplica o alfa).
  static const Color accentBlueSoft = black100;

  /// warning — texto de alerta no claro (Preto 70, ≈6.4:1 AA).
  static const Color warningText = black70;

  /// Alias para `of(...)` e testes de contraste.
  static const Color warning = warningText;

  /// warningLight — fundo suave de aviso (véu neutro).
  static const Color warningLight = warningText;

  /// success — verde semântico (ícone/fundo AA).
  static const Color successNeutral = alertSuccess;

  /// successText — verde semântico (texto AA).
  static const Color successText = alertSuccess;

  /// successSoft — fundo de badge de sucesso (alfa no chamador).
  static const Color successSoft = alertSuccess;

  /// error — vermelho semântico (texto/ícone AA).
  static const Color errorNeutral = alertError;

  /// errorSoft — fundo de badge de erro (alfa no chamador).
  static const Color lightErrorSoft = alertError;

  /// info — informação (Preto 70, AA no claro).
  static const Color info = black70;

  /// infoSoft — fundo suave de informação (véu neutro).
  static const Color infoSoft = info;

  // ─────────────────────────────────────────────────────────────────────
  // 2. Tema escuro (paleta oficial — não é inversão)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas escuro — Preto 100 (camada mais profunda).
  static const Color darkBackground = darkVoid;

  /// surface escuro — Preto 90 (cartões e listas).
  static const Color darkSurface = gluonGrey;

  /// surfaceSunken escuro — Preto 80 (campos e zonas agrupadas).
  static const Color darkSurfaceSecondary = slateGrey;

  /// surfaceRaised escuro — Preto 80.
  static const Color darkSurfaceElevated = slateGrey;

  /// textPrimary escuro — Branco 100 sobre Preto 90 (15.6:1).
  static const Color darkTextPrimary = snow;

  /// textSecondary escuro — Branco 60 ≈8.8:1 sobre Preto 90 (AA).
  static const Color darkTextSecondary = ashDark;

  /// textTertiary escuro — Branco 60 ≈8.8:1 sobre Preto 90 (AA).
  static const Color darkTextTertiary = ashDark;

  /// border escuro — Dusty (não-texto ≥3:1).
  static const Color darkBorder = dustyGrey;

  /// borderStrong escuro.
  static const Color darkBorderStrong = snow;

  /// separator escuro — Slate (divisor subtil).
  static const Color darkDivider = slateGrey;

  /// textDisabled escuro.
  static const Color darkTextDisabled = dustyGrey;

  /// Botão primário escuro: Branco 100 com rótulo Preto 100 (19:1).
  static const Color darkPrimary = white100;

  /// Rótulo Preto 100 sobre Branco 100 no escuro.
  static const Color darkOnPrimary = black100;

  /// Botão secundário escuro.
  static const Color darkSecondaryAction = gluonGrey;

  /// Texto do botão secundário escuro.
  static const Color darkOnSecondary = snow;

  /// action escuro — Branco 100 sobre Preto 90 (15.6:1, AAA texto).
  static const Color darkAction = white100;

  /// actionPressed escuro.
  static const Color darkActionPressed = white80;

  /// actionSoft escuro — fonte do véu de selecção (Branco 100).
  static const Color darkActionSoft = white100;

  /// Acento no escuro — Branco 100.
  static const Color darkAccentBlue = white100;
  static const Color accentBlueDark = white100;

  /// Fonte do véu de acento no escuro.
  static const Color darkAccentBlueSoft = white100;

  /// Texto de alerta escuro — Branco 60 (≈8.8:1 sobre Preto 90).
  static const Color darkWarningText = ashDark;

  /// error escuro — vermelho claro (≈7.5:1 sobre Gluon).
  static const Color darkErrorNeutral = errorTextDark;

  /// Fundo suave de erro escuro.
  static const Color darkErrorSoft = alertError;

  /// success escuro — tint de texto AA.
  static const Color successNeutralDark = successTextDark;

  /// info escuro (Branco 60).
  static const Color darkInfo = ashDark;

  /// Rótulo sobre preenchimentos semânticos no escuro.
  static const Color onSemanticDark = snow;

  // ─────────────────────────────────────────────────────────────────────
  // 3. Alertas (semânticos) — mantidos por compatibilidade
  // ─────────────────────────────────────────────────────────────────────

  static const Color accentBlueAlert = accentBlue;
  static const Color accentBlueSoftAlert = accentBlueSoft;
  static const Color warningTextDark = darkWarningText;
  static const Color errorNeutralDark = darkErrorNeutral;
  static const Color successNeutralDarkAlias = successNeutralDark;

  // ─────────────────────────────────────────────────────────────────────
  // 4. API de compatibilidade
  // ─────────────────────────────────────────────────────────────────────

  static Color get income => successNeutral;
  static Color get expense => errorNeutral;

  /// Variante de TEXTO do sucesso no escuro (tint AA).
  static Color get incomeDark => successTextDark;

  /// Variante de TEXTO do erro no escuro (tint AA).
  static Color get expenseDark => errorTextDark;
  static Color get accent => accentBlue;
  static Color get accentDark => darkAccentBlue;
  static Color get incomeLight => successText;
  static Color get expenseLight => errorNeutral;

  /// Escolhe a variante do brilho corrente: `dark` no escuro, `light` no claro.
  static Color of(Brightness brightness, Color dark, Color light) {
    return brightness == Brightness.light ? light : dark;
  }

  /// Cor do status de decisão (aprovação/rejeição).
  static Color decisionStatusColor(Object? status) {
    if (status == null || status == '') return lightBorder;
    if (status == 'approved' || status == 'aprovado') return successNeutral;
    if (status == 'rejected' || status == 'rejeitado') return errorNeutral;
    if (status == 'pending' || status == 'pendente') return accentBlue;

    return lightTextSecondary;
  }

  /// Cores das etiquetas de categoria de produto (escala neutra — o
  /// acento fica reservado a CTA/foco/selecção).
  static const Color categoryResale = black100; // revenda: Preto 100
  static const Color categoryProduzido = black70; // produzido: Preto 70
  static const Color categoryComposto = white90; // composto: Branco 90
  static Color getIncomeLight(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.light
        ? lightSurfaceSecondary
        : darkSurfaceSecondary;
  }

  // ── Aliases de migração ──
  static const Color statusError = errorNeutral;
  static const Color statusWarning = warning;
  static const Color statusSuccess = successNeutral;
  static const Color petrol = darkBackground;
  static const Color backgroundDark = darkBackground;
  static const Color surfaceDark = darkSurface;
  static const Color scaffoldLight = lightBackground;
  static const Color scaffoldDark = darkBackground;
  static const Color cardLight = lightSurface;
  static const Color cardDark = darkSurface;
  static const Color onSurfaceLight = lightTextPrimary;
  static const Color onSurfaceDark = darkTextPrimary;
  static const Color onSurfaceVariantLight = lightTextSecondary;
  static const Color onSurfaceVariantDark = darkTextSecondary;
  static const Color surfaceLight = lightSurface;

  /// LEGADO: = softWhite (não é a ação). Não usar para botões.
  static const Color primaryLight = softWhite;

  /// LEGADO: = brandInk (não é a ação). Não usar para botões.
  static const Color primaryDark = brandInk;
  static const Color brandMuted = accentBlue;
  static const Color outlineLight = lightBorder;
  static const Color outlineDark = darkBorder;
  static const Color outlineVariantLight = lightDivider;
  static const Color outlineVariantDark = darkDivider;
}

/// Cores semânticas que não cabem no [ColorScheme] (entrada, saída, alerta).
///
/// [ThemeExtension] para que a troca claro ⇄ escuro seja interpolada.
@immutable
class AppStatusColors implements ThemeExtension<AppStatusColors> {
  const AppStatusColors._({
    this.primary = Colors.transparent,
    this.onPrimary = Colors.transparent,
    this.surface = Colors.transparent,
    this.onSurface = Colors.transparent,
    this.error = Colors.transparent,
    this.warning = Colors.transparent,
    this.success = Colors.transparent,
    this.income = Colors.transparent,
    this.expense = Colors.transparent,
    this.accent = Colors.transparent,
    this.incomeLight = Colors.transparent,
    this.expenseLight = Colors.transparent,
    this.warningLight = Colors.transparent,
    this.accentLight = Colors.transparent,
  });

  /// Tipo da extensão (compatibilidade com a assinatura anterior).
  @override
  Type get type => runtimeType;

  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color warning;
  final Color success;
  final Color income;
  final Color expense;
  final Color accent;
  final Color incomeLight;
  final Color expenseLight;
  final Color warningLight;
  final Color accentLight;

  /// Instância do modo claro (valores vindos de [AppColors]).
  static const AppStatusColors light = AppStatusColors._(
    primary: AppColors.accentBlue,
    onPrimary: AppColors.lightOnPrimary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    error: AppColors.errorNeutral,
    warning: AppColors.warningText,
    success: AppColors.successNeutral,
    income: AppColors.successText,
    expense: AppColors.errorNeutral,
    accent: AppColors.accentBlue,
    incomeLight: AppColors.lightSurfaceSecondary,
    expenseLight: AppColors.lightErrorSoft,
    warningLight: AppColors.accentBlueSoft,
    accentLight: AppColors.accentBlueSoft,
  );

  /// Instância do modo escuro.
  ///
  /// `income`/`expense` usam branco suave para manter contraste no tema escuro.
  /// As cores de estado utilizam apenas os tokens da paleta oficial.
  static const AppStatusColors dark = AppStatusColors._(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    error: AppColors.darkErrorNeutral,
    warning: AppColors.darkWarningText,
    success: AppColors.successNeutralDark,
    income: AppColors.successTextDark,
    expense: AppColors.errorTextDark,
    accent: AppColors.darkAccentBlue,
    incomeLight: AppColors.darkSurfaceSecondary,
    expenseLight: AppColors.darkErrorSoft,
    warningLight: AppColors.darkAccentBlueSoft,
    accentLight: AppColors.darkAccentBlueSoft,
  );

  @override
  AppStatusColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? surface,
    Color? onSurface,
    Color? error,
    Color? warning,
    Color? success,
    Color? income,
    Color? expense,
    Color? accent,
    Color? incomeLight,
    Color? expenseLight,
    Color? warningLight,
    Color? accentLight,
  }) {
    return AppStatusColors._(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      accent: accent ?? this.accent,
      incomeLight: incomeLight ?? this.incomeLight,
      expenseLight: expenseLight ?? this.expenseLight,
      warningLight: warningLight ?? this.warningLight,
      accentLight: accentLight ?? this.accentLight,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors._(
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      incomeLight: Color.lerp(incomeLight, other.incomeLight, t)!,
      expenseLight: Color.lerp(expenseLight, other.expenseLight, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
    );
  }
}

/// Acesso às cores semânticas: `Theme.of(context).status`, etc.
extension AppColorsTheme on ThemeData {
  AppStatusColors get status =>
      extension<AppStatusColors>() ??
      (brightness == Brightness.light
          ? AppStatusColors.light
          : AppStatusColors.dark);

  Color get income => status.income;
  Color get expense => status.expense;
  Color get warning => status.warning;
  Color get accent => status.accent;

  Color get incomeLight => status.incomeLight;
  Color get expenseLight => status.expenseLight;
  Color get warningLight => status.warningLight;
  Color get accentLight => status.accentLight;

  Color get incomeDark => status.income;
  Color get expenseDark => status.expense;
  Color get warningDark => status.warning;
  Color get accentDark => status.accent;
}
