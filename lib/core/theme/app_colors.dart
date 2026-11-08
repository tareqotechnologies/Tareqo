import 'package:flutter/material.dart';

/// Paleta OFICIAL do sistema (nova identidade):
///
/// **Paleta principal (interface geral):**
/// 1. **Preto** `#212121` — textos principais, títulos, ícones principais,
///    botões de maior destaque, navegação.
/// 2. **Cinza** `#757575` — textos secundários, descrições, placeholders,
///    bordas, estados desabilitados, menor hierarquia.
/// 3. **Terracota** `#B7472A` — destaque, ações primárias, links relevantes,
///    indicadores ativos, estados selecionados, chamadas importantes.
/// 4. **Branco gelo** `#E0E0E0` — fundos claros, superfícies, cartões,
///    modais, contraste suave.
///
/// **Exceção controlada (alertas semânticos — e SÓ eles):**
/// - Sucesso `#2E7D32` — confirmações, êxito.
/// - Erro `#C62828` — falhas, invalidação, destrutivo.
/// - Aviso `#F9A825` — atenção, risco, pendências.
/// Nunca em fundo geral, menu, botões comuns, cards, gráficos, logo ou
/// decoração.
///
/// Acessibilidade (WCAG):
/// - Preto sobre gelo: `#212121` vs `#E0E0E0` ≈ **11.7:1** (AAA).
/// - Cinza sobre gelo: `#757575` vs `#E0E0E0` ≈ **3.5:1** (AA para texto
///   grande/ícones; para texto pequeno usar preto).
/// - Terracota sobre gelo: `#B7472A` vs `#E0E0E0` ≈ **4.0:1** (AA para
///   texto grande e não-texto; botões primários com texto gelo).
/// - Sucesso sobre gelo: `#2E7D32` vs `#E0E0E0` ≈ **3.6:1** (não-texto ok).
/// - Erro sobre gelo: `#C62828` vs `#E0E0E0` ≈ **4.0:1**.
/// - Aviso sobre gelo: `#F9A825` vs `#E0E0E0` ≈ **1.5:1** — usar texto
///   preto (#212121) sobre aviso, nunca aviso sobre gelo.
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────
  // 0. Base oficial (únicas cores sólidas permitidas)
  // ─────────────────────────────────────────────────────────────────────

  /// Preto principal #212121.
  static const Color black = Color(0xFF212121);

  /// Cinza secundário #757575.
  static const Color gray = Color(0xFF757575);

  /// Terracota / vermelho queimado #B7472A.
  static const Color terracotta = Color(0xFFB7472A);

  /// Branco gelo #E0E0E0.
  static const Color ice = Color(0xFFE0E0E0);

  /// Sucesso #2E7D32 — SÓ em alertas de sucesso/feedback.
  static const Color alertSuccess = Color(0xFF2E7D32);

  /// Erro #C62828 — SÓ em alertas de erro/falha.
  static const Color alertError = Color(0xFFC62828);

  /// Aviso #F9A825 — SÓ em alertas de atenção/aviso.
  static const Color alertWarning = Color(0xFFF9A825);

  // ─────────────────────────────────────────────────────────────────────
  // 1. Tema claro (paleta oficial)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas — fundo da aplicação.
  static const Color lightBackground = ice;

  /// surface — cartões, listas, sheets, campos.
  static const Color lightSurface = ice;

  /// surfaceSunken — zonas agrupadas e fundo de inputs.
  static const Color lightSurfaceSecondary = ice;

  /// surfaceRaised — superfície com elevação (menus, diálogos).
  static const Color lightSurfaceElevated = ice;

  /// textPrimary — 11.7:1 sobre gelo.
  static const Color lightTextPrimary = black;

  /// textSecondary — 3.5:1 sobre gelo (texto pequeno: usar black).
  static const Color lightTextSecondary = gray;

  /// textTertiary — mesmo cinza (paleta limitada, sem cor nova).
  static const Color lightTextTertiary = gray;

  /// border — divisores e contornos decorativos.
  static const Color lightBorder = gray;

  /// borderStrong — contorno de controlos.
  static const Color lightBorderStrong = black;

  /// Control border (outline buttons, fields): cinza sobre gelo.
  static const Color controlBorder = gray;

  /// separator — linhas de lista e tabela.
  static const Color lightDivider = gray;

  /// textDisabled — cinza (isento de AA por design).
  static const Color lightTextDisabled = gray;

  /// actionFill — fundo de botão primário (terracota).
  /// Rótulo sobre ele = gelo (4.0:1, AA texto grande).
  static const Color lightPrimary = terracotta;

  /// textOnAction — gelo sobre terracota.
  static const Color lightOnPrimary = ice;

  /// Botão secundário: superfície com contorno.
  static const Color lightSecondaryAction = ice;

  /// Texto do botão secundário.
  static const Color lightOnSecondary = black;

  /// action — ícones, foco, seleção (terracota).
  static const Color lightAction = terracotta;

  /// actionText — links e texto de ação.
  static const Color lightActionText = black;

  /// actionPressed — estado premido (terracota com transparência).
  static const Color lightActionPressed = terracotta;

  /// actionSoft — fundo de chip selecionado (terracota a 10%).
  static const Color lightActionSoft = terracotta;

  /// actionBorder — contorno de seleção.
  static const Color lightActionBorder = terracotta;

  /// warningBright — ícone de alerta (alerta semântico #F9A825).
  static const Color accentOrange = alertWarning;

  /// warningSoft — fundo de badge de alerta (aviso a 10%).
  static const Color accentOrangeSoft = alertWarning;

  /// warning — texto de alerta (preto sobre aviso, 11.7:1 sobre gelo
  /// seria 1.5:1 com aviso — por isso o TEXTO é preto, o aviso é borda/ícone).
  static const Color warningText = black;

  /// Alias para `of(...)` e testes de contraste.
  static const Color warning = warningText;

  /// warningLight — fundo suave de aviso.
  static const Color warningLight = accentOrangeSoft;

  /// success — ícone/badge de sucesso (alerta semântico #2E7D32).
  static const Color successNeutral = alertSuccess;

  /// successText — texto de sucesso (alerta semântico #2E7D32).
  static const Color successText = alertSuccess;

  /// successSoft — fundo de badge de sucesso (verde a 10%).
  static const Color successSoft = alertSuccess;

  /// error — erro e ações destrutivas (alerta semântico #C62828).
  static const Color errorNeutral = alertError;

  /// errorSoft — fundo de badge de erro (vermelho a 10%).
  static const Color lightErrorSoft = alertError;

  /// info — informação (terracota).
  static const Color info = terracotta;

  /// infoSoft — fundo suave de informação.
  static const Color infoSoft = terracotta;

  // ─────────────────────────────────────────────────────────────────────
  // 2. Tema escuro (paleta oficial — não é inversão)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas escuro — preto oficial.
  static const Color darkBackground = black;

  /// surface escuro — preto oficial.
  static const Color darkSurface = black;

  /// surfaceSunken escuro.
  static const Color darkSurfaceSecondary = black;

  /// surfaceRaised escuro — preto oficial.
  static const Color darkSurfaceElevated = black;

  /// textPrimary escuro — gelo sobre preto 11.7:1.
  static const Color darkTextPrimary = ice;

  /// textSecondary escuro — cinza sobre preto 3.5:1.
  static const Color darkTextSecondary = gray;

  /// textTertiary escuro.
  static const Color darkTextTertiary = gray;

  /// border escuro — decorativo (cinza sobre preto).
  static const Color darkBorder = gray;

  /// borderStrong escuro.
  static const Color darkBorderStrong = ice;

  /// separator escuro.
  static const Color darkDivider = gray;

  /// textDisabled escuro.
  static const Color darkTextDisabled = gray;

  /// Botão primário escuro: fundo terracota com rótulo Gelo (4.0:1).
  static const Color darkPrimary = terracotta;

  /// Rótulo gelo sobre terracota no escuro.
  static const Color darkOnPrimary = ice;

  /// Botão secundário escuro.
  static const Color darkSecondaryAction = black;

  /// Texto do botão secundário escuro.
  static const Color darkOnSecondary = ice;

  /// action escuro — terracota sobre preto 3.3:1 (ícones/ação).
  static const Color darkAction = terracotta;

  /// actionPressed escuro.
  static const Color darkActionPressed = terracotta;

  /// actionSoft escuro — fundo de seleção (terracota a 12%).
  static const Color darkActionSoft = terracotta;

  /// Alerta escuro (aviso semântico #F9A825).
  static const Color darkAccentOrange = alertWarning;
  static const Color accentOrangeDark = alertWarning;

  /// Fundo suave de alerta escuro (aviso a 10%).
  static const Color darkAccentOrangeSoft = alertWarning;

  /// Texto de alerta escuro ( gelo sobre fundo escuro — aviso é ícone).
  static const Color darkWarningText = ice;

  /// error escuro (alerta semântico #C62828).
  static const Color darkErrorNeutral = alertError;

  /// Fundo suave de erro escuro (vermelho a 10%).
  static const Color darkErrorSoft = alertError;

  /// success escuro (alerta semântico #2E7D32).
  static const Color successNeutralDark = alertSuccess;

  /// info escuro (terracota).
  static const Color darkInfo = terracotta;

  /// Rótulo sobre preenchimentos semânticos no escuro.
  static const Color onSemanticDark = ice;

  // ─────────────────────────────────────────────────────────────────────
  // 3. Alertas (terracota) — mantidos por compatibilidade
  // ─────────────────────────────────────────────────────────────────────

  static const Color accentOrangeAlert = accentOrange;
  static const Color accentOrangeSoftAlert = accentOrangeSoft;
  static const Color warningTextDark = darkWarningText;
  static const Color errorNeutralDark = darkErrorNeutral;
  static const Color successNeutralDarkAlias = successNeutralDark;

  // ─────────────────────────────────────────────────────────────────────
  // 4. API de compatibilidade
  // ─────────────────────────────────────────────────────────────────────

  static Color get income => successNeutral;
  static Color get expense => errorNeutral;
  static Color get incomeDark => successNeutralDark;
  static Color get expenseDark => darkErrorNeutral;
  static Color get accent => accentOrange;
  static Color get accentDark => darkAccentOrange;
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
    if (status == 'pending' || status == 'pendente') return accentOrange;

    return lightTextSecondary;
  }

  /// Cores das etiquetas de categoria de produto (paleta oficial).
  static const Color categoryResale = gray; // revenda: cinza
  static const Color categoryProduzido = terracotta; // produzido: terracota
  static const Color categoryComposto = black; // composto: preto
  static Color getIncomeLight(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.light
        ? lightSurfaceSecondary
        : darkSurfaceSecondary;
  }

  // ── Aliases de migração ──
  static const Color statusError = errorNeutral;
  static const Color statusWarning = accentOrange;
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

  /// LEGADO: = ice (não é a ação). Não usar para botões.
  static const Color primaryLight = ice;

  /// LEGADO: = black (não é a ação). Não usar para botões.
  static const Color primaryDark = black;
  static const Color brandMuted = accentOrange;
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
    primary: AppColors.accentOrange,
    onPrimary: AppColors.lightOnPrimary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    error: AppColors.errorNeutral,
    warning: AppColors.warningText,
    success: AppColors.successNeutral,
    income: AppColors.successText,
    expense: AppColors.errorNeutral,
    accent: AppColors.accentOrange,
    incomeLight: AppColors.lightSurfaceSecondary,
    expenseLight: AppColors.lightErrorSoft,
    warningLight: AppColors.accentOrangeSoft,
    accentLight: AppColors.accentOrangeSoft,
  );

  /// Instância do modo escuro.
  static const AppStatusColors dark = AppStatusColors._(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    error: AppColors.darkErrorNeutral,
    warning: AppColors.darkWarningText,
    success: AppColors.successNeutralDark,
    income: AppColors.successNeutralDark,
    expense: AppColors.darkErrorNeutral,
    accent: AppColors.darkAccentOrange,
    incomeLight: AppColors.darkSurfaceSecondary,
    expenseLight: AppColors.darkErrorSoft,
    warningLight: AppColors.darkAccentOrangeSoft,
    accentLight: AppColors.darkAccentOrangeSoft,
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
