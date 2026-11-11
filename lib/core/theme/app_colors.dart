import 'package:flutter/material.dart';

/// Paleta OFICIAL do sistema (identidade Outfit, guia em anexo):
///
/// **Paleta principal (interface geral — só estas 5 cores sólidas):**
/// 1. **Azul** `#0067FF` — ações primárias, links ativos, indicadores,
///    destaques, estados ativos, navegação.
/// 2. **Cinza médio** `#6E7174` — texto secundário (claro), bordas e
///    divisores no escuro, estados desativados.
/// 3. **Cinza de superfície** `#E7E5E5` — superfícies secundárias, campos,
///    divisores suaves, fundos alternativos (claro), texto secundário (escuro).
/// 4. **Branco suave** `#F9F9F9` — fundo principal claro, superfícies,
///    texto claro em fundos escuros, rótulo sobre o azul.
/// 5. **Tinta escura** `#232323` — texto principal (claro), fundo principal
///    escuro, ícones principais, bordas estruturais.
///
/// Estados semânticos reutilizam exclusivamente os cinco tons oficiais;
/// ícone e rótulo acompanham a cor para não depender apenas de matiz.
///
/// Acessibilidade (WCAG, medido sobre os pares da paleta nativa):
/// - Tinta sobre suave: `#232323` vs `#F9F9F9` ≈ **14.9:1** (AAA).
/// - Suave sobre tinta: ≈ **14.9:1** (AAA).
/// - Cinza de superfície sobre tinta: `#E7E5E5` vs `#232323` ≈ **12.5:1**
///   — texto secundário no escuro.
/// - Cinza médio sobre suave: `#6E7174` vs `#F9F9F9` ≈ **4.7:1** (AA texto).
/// - Azul sobre suave: `#0067FF` vs `#F9F9F9` ≈ **4.55:1** (AA texto — pode
///   ser usado em links e texto de ação).
/// - Suave sobre azul: ≈ **4.55:1** (AA texto — rótulo do botão primário).
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────
  // 0. Base oficial (únicas cores sólidas permitidas)
  // ─────────────────────────────────────────────────────────────────────

  /// Azul principal #0067FF.
  static const Color brandBlue = Color(0xFF0067FF);

  /// Cinza médio #6E7174.
  static const Color grayMid = Color(0xFF6E7174);

  /// Cinza de superfície #E7E5E5.
  static const Color surfaceGray = Color(0xFFE7E5E5);

  /// Branco suave #F9F9F9.
  static const Color softWhite = Color(0xFFF9F9F9);

  /// Tinta escura #232323.
  static const Color brandInk = Color(0xFF232323);

  /// Sucesso: azul oficial (estado indicado também por ícone e rótulo).
  static const Color alertSuccess = brandBlue;

  /// Erro: tinta escura oficial (estado indicado também por ícone e rótulo).
  static const Color alertError = brandInk;

  /// Aviso: cinza médio oficial (estado indicado também por ícone e rótulo).
  static const Color alertWarning = grayMid;'} (commentary) 。。{} пож`functions.Edit` tool running with the following input: {

  // ─────────────────────────────────────────────────────────────────────
  // 0.1 Tints semânticos de TEXTO no escuro (WCAG AA)
  // ─────────────────────────────────────────────────────────────────────

  /// Texto de estado no escuro usa branco suave da paleta oficial.
  static const Color successTextDark = softWhite;
  static const Color errorTextDark = softWhite;

  // ─────────────────────────────────────────────────────────────────────
  // 1. Tema claro (paleta oficial)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas — fundo da aplicação (#F9F9F9).
  static const Color lightBackground = softWhite;

  /// surface — cartões, listas, sheets, campos.
  static const Color lightSurface = softWhite;

  /// surfaceSunken — zonas agrupadas e fundo de inputs (#E7E5E5).
  static const Color lightSurfaceSecondary = surfaceGray;

  /// surfaceRaised — superfície com elevação.
  static const Color lightSurfaceElevated = softWhite;

  /// textPrimary — 14.9:1 sobre suave.
  static const Color lightTextPrimary = brandInk;

  /// textSecondary — cinza médio #6E7174 (4.7:1, AA).
  static const Color lightTextSecondary = grayMid;

  /// textTertiary — cinza médio #6E7174.
  static const Color lightTextTertiary = grayMid;

  /// border — divisores e contornos decorativos (#E7E5E5).
  static const Color lightBorder = surfaceGray;

  /// borderStrong — contorno de controlos (tinta).
  static const Color lightBorderStrong = brandInk;

  /// Control border (outline buttons, fields).
  static const Color controlBorder = brandInk;

  /// separator — linhas de lista e tabela.
  static const Color lightDivider = surfaceGray;

  /// textDisabled — cinza médio sobre suave.
  static const Color lightTextDisabled = grayMid;

  /// actionFill — fundo de botão primário (azul).
  /// Rótulo sobre ele = branco suave (4.55:1, AA texto).
  static const Color lightPrimary = brandBlue;

  /// textOnAction — branco suave sobre azul.
  static const Color lightOnPrimary = softWhite;

  /// Botão secundário: superfície com contorno.
  static const Color lightSecondaryAction = softWhite;

  /// Texto do botão secundário.
  static const Color lightOnSecondary = brandInk;

  /// action — ícones, foco, seleção (azul).
  static const Color lightAction = brandBlue;

  /// actionText — links e texto de ação (azul, 4.55:1 AA).
  static const Color lightActionText = brandBlue;

  /// actionPressed — estado premido (azul).
  static const Color lightActionPressed = brandBlue;

  /// actionSoft — fundo de chip selecionado (azul a 10%).
  static const Color lightActionSoft = brandBlue;

  /// actionBorder — contorno de seleção.
  static const Color lightActionBorder = brandBlue;

  /// Acento da marca — azul do guia (#0067FF).
  /// Avisos usam cinza médio, mantendo a paleta oficial.
  static const Color accentBlue = brandBlue;

  /// Fonte do véu de acento (quem pinta aplica o alfa).
  static const Color accentBlueSoft = brandBlue;

  /// warning — texto de alerta (tinta sobre véu de aviso).
  static const Color warningText = brandInk;

  /// Alias para `of(...)` e testes de contraste.
  static const Color warning = warningText;

  /// warningLight — fundo suave de aviso.
  static const Color warningLight = accentBlueSoft;

  /// success — ícone/badge usando azul oficial.
  static const Color successNeutral = alertSuccess;

  /// successText — texto de sucesso usando azul oficial.
  static const Color successText = alertSuccess;

  /// successSoft — fundo de badge de sucesso (a 10%).
  static const Color successSoft = alertSuccess;

  /// error — erro e ações destrutivas usando tinta oficial.
  static const Color errorNeutral = alertError;

  /// errorSoft — fundo de badge de erro (a 10%).
  static const Color lightErrorSoft = alertError;

  /// info — informação (azul).
  static const Color info = brandBlue;

  /// infoSoft — fundo suave de informação.
  static const Color infoSoft = brandBlue;

  // ─────────────────────────────────────────────────────────────────────
  // 2. Tema escuro (paleta oficial — não é inversão)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas escuro — tinta escura oficial.
  static const Color darkBackground = brandInk;

  /// surface escuro — tinta escura oficial.
  static const Color darkSurface = brandInk;

  /// surfaceSunken escuro.
  static const Color darkSurfaceSecondary = brandInk;

  /// surfaceRaised escuro — tinta escura oficial.
  static const Color darkSurfaceElevated = brandInk;

  /// textPrimary escuro — suave sobre tinta 14.9:1.
  static const Color darkTextPrimary = softWhite;

  /// textSecondary escuro — cinza de superfície sobre tinta 12.5:1.
  static const Color darkTextSecondary = surfaceGray;

  /// textTertiary escuro.
  static const Color darkTextTertiary = surfaceGray;

  /// border escuro — decorativo (cinza médio sobre tinta).
  static const Color darkBorder = grayMid;

  /// borderStrong escuro.
  static const Color darkBorderStrong = softWhite;

  /// separator escuro.
  static const Color darkDivider = grayMid;

  /// textDisabled escuro.
  static const Color darkTextDisabled = grayMid;

  /// Botão primário escuro: azul com rótulo BRANCO SUAVE (4.55:1).
  static const Color darkPrimary = brandBlue;

  /// Rótulo branco suave sobre azul no escuro.
  static const Color darkOnPrimary = softWhite;

  /// Botão secundário escuro.
  static const Color darkSecondaryAction = brandInk;

  /// Texto do botão secundário escuro.
  static const Color darkOnSecondary = softWhite;

  /// action escuro — azul sobre tinta.
  static const Color darkAction = brandBlue;

  /// actionPressed escuro.
  static const Color darkActionPressed = brandBlue;

  /// actionSoft escuro — fundo de seleção (azul a 12%).
  static const Color darkActionSoft = brandBlue;

  /// Acento no escuro — o mesmo azul #0067FF (rótulo sobre ele = suave).
  static const Color darkAccentBlue = brandBlue;
  static const Color accentBlueDark = brandBlue;

  /// Fonte do véu de acento no escuro.
  static const Color darkAccentBlueSoft = brandBlue;

  /// Texto de alerta escuro (suave sobre tinta — aviso é ícone/borda).
  static const Color darkWarningText = softWhite;

  /// error escuro — tinta oficial.
  static const Color darkErrorNeutral = alertError;

  /// Fundo suave de erro escuro.
  static const Color darkErrorSoft = alertError;

  /// success escuro — azul oficial.
  static const Color successNeutralDark = alertSuccess;

  /// info escuro (azul).
  static const Color darkInfo = brandBlue;

  /// Rótulo sobre preenchimentos semânticos no escuro.
  static const Color onSemanticDark = softWhite;

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

  /// Cores das etiquetas de categoria de produto (paleta oficial).
  static const Color categoryResale = brandInk; // revenda: tinta
  static const Color categoryProduzido = brandBlue; // produzido: azul
  static const Color categoryComposto = surfaceGray; // composto: cinza
  static Color getIncomeLight(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.light
        ? lightSurfaceSecondary
        : darkSurfaceSecondary;
  }

  // ── Aliases de migração ──
  static const Color statusError = errorNeutral;
  static const Color statusWarning = accentBlue;
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
