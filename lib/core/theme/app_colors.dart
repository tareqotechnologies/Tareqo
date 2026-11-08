import 'package:flutter/material.dart';

/// Paleta TAREQO Signature (DESIGN_SYSTEM.md §2–3).
///
/// Orçamento de cor: ~90% neutros, ~8% azul de ação, ~2% semântica.
/// Nomes mantidos por compatibilidade com os ecrãs existentes: só os valores
/// mudam. Não usar as cores semânticas como decoração.
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────
  // 1. Tema claro
  // ─────────────────────────────────────────────────────────────────────

  /// canvas — fundo da aplicação.
  static const Color lightBackground = Color(0xFFF5F5F7);

  /// surface — cartões, listas, sheets, campos.
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// surfaceSunken — zonas agrupadas e fundo de inputs.
  static const Color lightSurfaceSecondary = Color(0xFFEDEDF0);

  /// surfaceRaised — superfície com elevação (menus, diálogos).
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  /// textPrimary — 16.83:1 sobre surface.
  static const Color lightTextPrimary = Color(0xFF1D1D1F);

  /// textSecondary — 5.07:1 sobre surface.
  static const Color lightTextSecondary = Color(0xFF5E5E63);

  /// textTertiary — 5.99:1 sobre surface.
  static const Color lightTextTertiary = Color(0xFF636366);

  /// border — divisores e contornos decorativos.
  static const Color lightBorder = Color(0xFFD2D2D7);

  /// borderStrong — contorno de controlos (≥3:1).
  static const Color lightBorderStrong = Color(0xFFC7C7CC);

  /// Control border (outline buttons, fields): 3.3:1 on white, 5.4:1 on dark (WCAG 1.4.11). borderStrong does NOT reach 3:1.
  static const Color controlBorder = Color(0xFF8A8A8F);

  /// separator — linhas de lista e tabela.
  static const Color lightDivider = Color(0xFFE5E5EA);

  /// textDisabled — isento de AA.
  static const Color lightTextDisabled = Color(0xFFAEAEB2);

  /// actionFill — fundo de botão primário (âmbar #D97706).
  /// Rótulo sobre ele = [lightOnPrimary] (tinta #1D1D1F): contraste
  /// real ≈ 5,0:1 (AA). Branco sobre #D97706 daria ≈ 3,3:1 (falha AA
  /// para texto) — por isso o rótulo é escuro, não branco (U-21).
  static const Color lightPrimary = Color(0xFFD97706);

  /// textOnAction — tinta escura sobre o preenchimento de ação.
  static const Color lightOnPrimary = Color(0xFF1D1D1F);

  /// Botão secundário: superfície com contorno (sem preenchimento colorido).
  static const Color lightSecondaryAction = Color(0xFFFFFFFF);

  /// Texto do botão secundário.
  static const Color lightOnSecondary = Color(0xFF1D1D1F);

  /// action — ícones, foco, indicador de seleção em laranja.
  static const Color lightAction = Color(0xFFD97706);

  /// actionText — links e texto de ação sobre superfície laranja.
  static const Color lightActionText = Color(0xFF1D1D1F);

  /// actionPressed — estado premido em laranja mais suave.
  static const Color lightActionPressed = Color(0xFFFFD1A3);

  /// actionSoft — fundo de chip selecionado em laranja muito claro.
  static const Color lightActionSoft = Color(0xFFFFF3E0);

  /// actionBorder — contorno de seleção em laranja muito claro.
  static const Color lightActionBorder = Color(0xFFFFF3E0);

  /// warningBright — ícone de alerta (não-texto, ≥3:1). Mantém o nome
  /// `accentOrange` usado pelos ecrãs existentes.
  static const Color accentOrange = Color(0xFFD97706);

  /// warningSoft — fundo de badge de alerta.
  static const Color accentOrangeSoft = Color(0xFFFFF3E0);

  /// warning — texto de alerta (5.20:1 sobre branco).
  static const Color warningText = Color(0xFF9A4500);

  /// Alias para `of(...)` e testes de contraste.
  // blue removido — warning mantém-se como referência antiga.
  static const Color warning = warningText;

  /// warningLight — fundo suave de aviso.
  static const Color warningLight = accentOrangeSoft;

  /// success — ícone/badge de sucesso (não-texto, 4.40:1).
  static const Color successNeutral = Color(0xFF248A3D);

  /// successText — texto de sucesso (5.40:1).
  static const Color successText = Color(0xFF176A2C);

  /// successSoft — fundo de badge de sucesso.
  static const Color successSoft = Color(0xFFE7F4EA);

  /// error — erro e ações destrutivas (5.38:1).
  static const Color errorNeutral = Color(0xFFB0000F);

  /// errorSoft — fundo de badge de erro.
  static const Color lightErrorSoft = Color(0xFFFDECEF);

  /// info — informação (6.87:1, substituído por laranja).
  static const Color info = Color(0xFFD97706);

  /// infoSoft — fundo suave de informação em laranja claro.
  static const Color infoSoft = Color(0xFFFFF3E0);

  // ─────────────────────────────────────────────────────────────────────
  // 2. Tema escuro (paleta própria, não é inversão)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas escuro.
  static const Color darkBackground = Color(0xFF0B0B0D);

  /// surface escuro — cartões e listas.
  static const Color darkSurface = Color(0xFF161618);

  /// surfaceSunken escuro — inputs e zonas agrupadas.
  static const Color darkSurfaceSecondary = Color(0xFF0F0F11);

  /// surfaceRaised escuro — sheets, diálogos, menus.
  static const Color darkSurfaceElevated = Color(0xFF1C1C1E);

  /// textPrimary escuro — 16.60:1 sobre surface.
  static const Color darkTextPrimary = Color(0xFFF5F5F7);

  /// textSecondary escuro — 7.03:1 sobre surface.
  static const Color darkTextSecondary = Color(0xFFA1A1A6);

  /// textTertiary escuro — 5.54:1 sobre surface.
  static const Color darkTextTertiary = Color(0xFF8E8E93);

  /// border escuro — decorativo.
  static const Color darkBorder = Color(0xFF2C2C2E);

  /// borderStrong escuro — contorno de controlos.
  static const Color darkBorderStrong = Color(0xFF3A3A3C);

  /// separator escuro.
  static const Color darkDivider = Color(0xFF242426);

  /// textDisabled escuro.
  static const Color darkTextDisabled = Color(0xFF636366);

  /// Botão primário escuro: fundo âmbar claro #FF9F0A com rótulo
  /// ESCURO [darkOnPrimary] (AA). Branco sobre #FF9F0A daria ≈ 2,2:1
  /// (falha grave) — o rótulo escuro é a escolha auditada (U-21).
  static const Color darkPrimary = Color(0xFFFF9F0A);

  /// Rótulo escuro sobre o primário escuro.
  static const Color darkOnPrimary = Color(0xFF0B0B0D);

  /// Botão secundário escuro.
  static const Color darkSecondaryAction = Color(0xFF1C1C1E);

  /// Texto do botão secundário escuro.
  static const Color darkOnSecondary = Color(0xFFF5F5F7);

  /// action escuro — ícones, foco, seleção em laranja (4.95:1 sobre surface).
  static const Color darkAction = Color(0xFFFF9F0A);

  /// actionPressed escuro — estado premido em laranja mais claro.
  static const Color darkActionPressed = Color(0xFFFFCD80);

  /// actionSoft escuro — fundo de seleção.
  static const Color darkActionSoft = Color(0xFF0F2A44);

  /// Alerta escuro (warning 8.28:1). Mantém o nome `darkAccentOrange`.
  static const Color darkAccentOrange = Color(0xFFFF9F0A);
  static const Color accentOrangeDark = Color(0xFFB45309);

  /// Fundo suave de alerta escuro.
  static const Color darkAccentOrangeSoft = Color(0xFF3A260D);

  /// Texto de alerta escuro.
  static const Color darkWarningText = Color(0xFFFF9F0A);

  /// error escuro (4.99:1).
  static const Color darkErrorNeutral = Color(0xFFFF453A);
  // azul removido da seção de alertas

  /// Fundo suave de erro escuro.
  static const Color darkErrorSoft = Color(0xFF3B1714);

  /// success escuro (8.42:1).
  static const Color successNeutralDark = Color(0xFF30D158);

  /// info escuro — laranja escuro (9.90:1 sobre surface).
  static const Color darkInfo = Color(0xFF3A260D);

  /// Rótulo sobre preenchimentos semânticos no escuro.
  static const Color onSemanticDark = Color(0xFF0B0B0D);

  // ─────────────────────────────────────────────────────────────────────
  // 3. Alertas (laranja) — mantidos por compatibilidade
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
  /// Cores das etiquetas de categoria de produto.
  /// Revenda: cinza; Produzido: laranja; Composto: azul/roxo.
  /// Utilizadas nos selos/badges ao lado dos produtos.
  static const Color categoryResale = Color(0xFF6B7280);       // gray 300
  static const Color categoryProduzido = Color(0xFFFF9F0A);      // orange accent
  static const Color categoryComposto = Color(0xFF8B5CF6);       // violet 400
  static Color getIncomeLight(ColorScheme scheme, Brightness brightness) {
    return brightness == Brightness.light ? lightSurfaceSecondary : darkSurfaceSecondary;
  }

  // ── Aliases de migração (U-21): mantidos por compatibilidade, mas
  // documentados com o valor REAL — `primaryLight`/`primaryDark` NUNCA
  // foram a cor de ação (são surfaces, legado de uma paleta anterior);
  // usar `lightPrimary`/`darkPrimary` (ou scheme.primary) para ação.
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
  /// LEGADO: = lightSurface (não é a ação). Não usar para botões.
  static const Color primaryLight = lightSurface;
  /// LEGADO: = darkSurface (não é a ação). Não usar para botões.
  static const Color primaryDark = darkSurface;
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
  AppStatusColors get status => extension<AppStatusColors>() ?? (
    brightness == Brightness.light ? AppStatusColors.light : AppStatusColors.dark
  );

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