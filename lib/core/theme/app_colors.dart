import 'package:flutter/material.dart';

/// Paleta OFICIAL do sistema (identidade 2026-11-09):
///
/// **Paleta principal (interface geral — só estas 4 cores sólidas):**
/// 1. **Laranja** `#FF6A2A` — ações primárias, links ativos, indicadores,
///    destaques, estados ativos, navegação.
/// 2. **Cinza de superfície** `#F0F0F0` — superfícies secundárias, campos,
///    divisores suaves, fundos alternativos (claro), texto secundário (escuro).
/// 3. **Branco suave** `#F9F9F9` — fundo principal claro, superfícies,
///    texto claro em fundos escuros.
/// 4. **Preto** `#0C0B0A` — texto principal claro, fundo principal escuro,
///    ícones principais, bordas estruturais.
///
/// **Exceção controlada (alertas semânticos — e SÓ eles):**
/// - Sucesso `#2E7D32`, Erro `#C62828`, Aviso `#F9A825` — nunca em fundo
///   geral, menu, botões comuns, cards, gráficos, logo ou decoração.
///
/// Acessibilidade (WCAG, medido sobre os pares da paleta nativa):
/// - Preto sobre suave: `#0C0B0A` vs `#F9F9F9` ≈ **17.6:1** (AAA).
/// - Suave sobre preto: ≈ **17.6:1** (AAA).
/// - Cinza sobre suave: `#F0F0F0` vs `#F9F9F9` ≈ **1.2:1** — texto
///   secundário no escuro usa `#F0F0F0` sobre `#0C0B0A` (≈ **14.8:1**).
/// - Laranja sobre suave: `#FF6A2A` vs `#F9F9F9` ≈ **2.9:1** — só
///   não-texto/elementos grandes; texto pequeno em laranja usa preto.
/// - Preto sobre laranja: `#0C0B0A` vs `#FF6A2A` ≈ **6.1:1** (AA texto).
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────
  // 0. Base oficial (únicas cores sólidas permitidas)
  // ─────────────────────────────────────────────────────────────────────

  /// Laranja principal #FF6A2A.
  static const Color brandOrange = Color(0xFFFF6A2A);

  /// Cinza de superfície #F0F0F0.
  static const Color surfaceGray = Color(0xFFF0F0F0);

  /// Branco suave #F9F9F9.
  static const Color softWhite = Color(0xFFF9F9F9);

  /// Preto principal #0C0B0A.
  static const Color brandBlack = Color(0xFF0C0B0A);

  /// Sucesso #2E7D32 — SÓ em alertas de sucesso/feedback.
  static const Color alertSuccess = Color(0xFF2E7D32);

  /// Erro #C62828 — SÓ em alertas de erro/falha.
  static const Color alertError = Color(0xFFC62828);

  /// Aviso #F9A825 — SÓ em alertas de atenção/aviso.
  static const Color alertWarning = Color(0xFFF9A825);

  // ─────────────────────────────────────────────────────────────────────
  // 0.1 Tints semânticos de TEXTO no escuro (WCAG AA)
  // ─────────────────────────────────────────────────────────────────────

  /// Verde de texto no escuro — 8.32:1 sobre #0C0B0A (AA/AAA para texto).
  ///
  /// Os tons base (#2E7D32/#C62828) ficam para preenchimentos, chips e
  /// ícones: como texto pequeno sobre preto medem 3.84:1/3.50:1 e falham
  /// AA 4.5:1. Só estes dois tints são usados em TEXTO monetário no dark.
  static const Color successTextDark = Color(0xFF66BB6A);
  static const Color errorTextDark = Color(0xFFEF5350);

  // ─────────────────────────────────────────────────────────────────────
  // 1. Tema claro (paleta oficial)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas — fundo da aplicação (#F9F9F9).
  static const Color lightBackground = softWhite;

  /// surface — cartões, listas, sheets, campos.
  static const Color lightSurface = softWhite;

  /// surfaceSunken — zonas agrupadas e fundo de inputs (#F0F0F0).
  static const Color lightSurfaceSecondary = surfaceGray;

  /// surfaceRaised — superfície com elevação.
  static const Color lightSurfaceElevated = softWhite;

  /// textPrimary — 17.6:1 sobre suave.
  static const Color lightTextPrimary = brandBlack;

  /// textSecondary — preto (AA); cinza sobre suave dá 1.2:1 (ilegível).
  static const Color lightTextSecondary = brandBlack;

  /// textTertiary — preto oficial (paleta sem cinza de texto legível).
  static const Color lightTextTertiary = brandBlack;

  /// border — divisores e contornos decorativos (#F0F0F0).
  static const Color lightBorder = surfaceGray;

  /// borderStrong — contorno de controlos (preto).
  static const Color lightBorderStrong = brandBlack;

  /// Control border (outline buttons, fields).
  static const Color controlBorder = brandBlack;

  /// separator — linhas de lista e tabela.
  static const Color lightDivider = surfaceGray;

  /// textDisabled — cinza de superfície sobre suave (isento de AA).
  static const Color lightTextDisabled = surfaceGray;

  /// actionFill — fundo de botão primário (laranja).
  /// Rótulo sobre ele = preto (6.1:1, AA texto).
  static const Color lightPrimary = brandOrange;

  /// textOnAction — preto sobre laranja.
  static const Color lightOnPrimary = brandBlack;

  /// Botão secundário: superfície com contorno.
  static const Color lightSecondaryAction = softWhite;

  /// Texto do botão secundário.
  static const Color lightOnSecondary = brandBlack;

  /// action — ícones, foco, seleção (laranja).
  static const Color lightAction = brandOrange;

  /// actionText — links e texto de ação.
  static const Color lightActionText = brandBlack;

  /// actionPressed — estado premido (laranja).
  static const Color lightActionPressed = brandOrange;

  /// actionSoft — fundo de chip selecionado (laranja a 10%).
  static const Color lightActionSoft = brandOrange;

  /// actionBorder — contorno de seleção.
  static const Color lightActionBorder = brandOrange;

  /// Acento da marca — laranja do anexo (#FF6A2A).
  /// Não é o amarelo de aviso (#F9A825): esse fica só em [alertWarning].
  static const Color accentOrange = brandOrange;

  /// Fonte do véu de acento (quem pinta aplica o alfa).
  static const Color accentOrangeSoft = brandOrange;

  /// warning — texto de alerta (preto sobre aviso).
  static const Color warningText = brandBlack;

  /// Alias para `of(...)` e testes de contraste.
  static const Color warning = warningText;

  /// warningLight — fundo suave de aviso.
  static const Color warningLight = accentOrangeSoft;

  /// success — ícone/badge de sucesso (alerta semântico #2E7D32).
  static const Color successNeutral = alertSuccess;

  /// successText — texto de sucesso (#2E7D32).
  static const Color successText = alertSuccess;

  /// successSoft — fundo de badge de sucesso (a 10%).
  static const Color successSoft = alertSuccess;

  /// error — erro e ações destrutivas (#C62828).
  static const Color errorNeutral = alertError;

  /// errorSoft — fundo de badge de erro (a 10%).
  static const Color lightErrorSoft = alertError;

  /// info — informação (laranja; cinza sobre suave é 1.2:1).
  static const Color info = brandOrange;

  /// infoSoft — fundo suave de informação.
  static const Color infoSoft = brandOrange;

  // ─────────────────────────────────────────────────────────────────────
  // 2. Tema escuro (paleta oficial — não é inversão)
  // ─────────────────────────────────────────────────────────────────────

  /// canvas escuro — preto oficial.
  static const Color darkBackground = brandBlack;

  /// surface escuro — preto oficial.
  static const Color darkSurface = brandBlack;

  /// surfaceSunken escuro.
  static const Color darkSurfaceSecondary = brandBlack;

  /// surfaceRaised escuro — preto oficial.
  static const Color darkSurfaceElevated = brandBlack;

  /// textPrimary escuro — suave sobre preto 17.6:1.
  static const Color darkTextPrimary = softWhite;

  /// textSecondary escuro — cinza de superfície sobre preto 14.8:1.
  static const Color darkTextSecondary = surfaceGray;

  /// textTertiary escuro.
  static const Color darkTextTertiary = surfaceGray;

  /// border escuro — decorativo (cinza sobre preto).
  static const Color darkBorder = surfaceGray;

  /// borderStrong escuro.
  static const Color darkBorderStrong = softWhite;

  /// separator escuro.
  static const Color darkDivider = surfaceGray;

  /// textDisabled escuro.
  static const Color darkTextDisabled = surfaceGray;

  /// Botão primário escuro: laranja com rótulo PRETO (6.1:1).
  static const Color darkPrimary = brandOrange;

  /// Rótulo preto sobre laranja no escuro.
  static const Color darkOnPrimary = brandBlack;

  /// Botão secundário escuro.
  static const Color darkSecondaryAction = brandBlack;

  /// Texto do botão secundário escuro.
  static const Color darkOnSecondary = softWhite;

  /// action escuro — laranja sobre preto.
  static const Color darkAction = brandOrange;

  /// actionPressed escuro.
  static const Color darkActionPressed = brandOrange;

  /// actionSoft escuro — fundo de seleção (laranja a 12%).
  static const Color darkActionSoft = brandOrange;

  /// Acento no escuro — o mesmo laranja #FF6A2A (rótulo sobre ele = preto).
  static const Color darkAccentOrange = brandOrange;
  static const Color accentOrangeDark = brandOrange;

  /// Fonte do véu de acento no escuro.
  static const Color darkAccentOrangeSoft = brandOrange;

  /// Texto de alerta escuro (suave sobre preto — aviso é ícone/borda).
  static const Color darkWarningText = softWhite;

  /// error escuro (alerta semântico #C62828).
  static const Color darkErrorNeutral = alertError;

  /// Fundo suave de erro escuro.
  static const Color darkErrorSoft = alertError;

  /// success escuro (alerta semântico #2E7D32).
  static const Color successNeutralDark = alertSuccess;

  /// info escuro (laranja).
  static const Color darkInfo = brandOrange;

  /// Rótulo sobre preenchimentos semânticos no escuro.
  static const Color onSemanticDark = softWhite;

  // ─────────────────────────────────────────────────────────────────────
  // 3. Alertas (semânticos) — mantidos por compatibilidade
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

  /// Variante de TEXTO do sucesso no escuro (tint AA).
  static Color get incomeDark => successTextDark;

  /// Variante de TEXTO do erro no escuro (tint AA).
  static Color get expenseDark => errorTextDark;
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
  static const Color categoryResale = brandBlack; // revenda: preto
  static const Color categoryProduzido = brandOrange; // produzido: laranja
  static const Color categoryComposto = surfaceGray; // composto: cinza
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

  /// LEGADO: = softWhite (não é a ação). Não usar para botões.
  static const Color primaryLight = softWhite;

  /// LEGADO: = brandBlack (não é a ação). Não usar para botões.
  static const Color primaryDark = brandBlack;
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
  ///
  /// `income`/`expense` são a variante de TEXTO (tints AA 8.32:1/5.64:1).
  /// Os tons base (#2E7D32/#C62828) continuam em `success`/`error` para
  /// preenchimentos e chips.
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
