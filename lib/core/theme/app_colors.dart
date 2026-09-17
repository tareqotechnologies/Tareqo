import 'package:flutter/material.dart';

/// Paleta e cores semânticas que NÃO vivem no [ColorScheme].
///
/// Regra do design system: cor representa **função**, nunca aparência.
/// Os nomes seguem o papel que a cor cumpre no UI (`income`, `expense`,
/// `warning`, `accent`…). Onde existe um par para os dois temas, o sufixo
/// `*Light` refere-se ao modo claro — não é uma cor "mais clara".
///
/// As variantes usadas como TEXTO sobre superfícies claras foram calibradas
/// para WCAG AA (≥ 4.5:1) e, como ícone/chip (≥ 3:1) — ver
/// `test/core/theme/theme_contrast_test.dart`.
abstract final class AppColors {
  // ── Marca — escala única de verdes (fonte única dos hexadecimais) ──
  /// Verde vivo — ícones, destaques e FAB no modo escuro.
  static const Color brand = Color(0xFF16A34A);

  /// Verde médio — superfícies primárias com texto branco (branco = 5.0:1).
  static const Color brandMuted = Color(0xFF15803D);

  /// Containers do verde de marca (chips selecionados, indicador de navegação).
  static const Color brandContainerLight = Color(0xFFD1FAE5);
  static const Color brandContainerDark = Color(0xFF14532D);

  /// Texto sobre os containers da marca.
  static const Color onBrandContainerLight = Color(0xFF064E3B);
  static const Color onBrandContainerDark = Color(0xFFBBF7D0);

  // ── API legada (mantida para compatibilidade) ──
  // `accent`/`success` são o mesmo verde vivo da marca; `accentLight`/
  // `successLight` o verde médio. Valores idênticos aos anteriores — o
  // `success` verde-claro AA (≥4.5:1 sobre branco e chip@14%) é o `brandMuted`.
  static const Color accent = brand;
  static const Color accentLight = brandMuted;
  static const Color success = brand;
  static const Color successLight = brandMuted;

  // ── Fluxo de caixa (entradas/saídas) — calibrado AA no teste de contraste ──
  static const Color income = Color(0xFF34D399);
  static const Color incomeLight = Color(0xFF03754F);
  static const Color expense = Color(0xFFF87171);
  static const Color expenseLight = Color(0xFFC81E1E);

  // ── Alertas genéricos (texto curto em negrito sobre superfície clara) ──
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFF9A5308);

  // ── Neutros do modo escuro (superfícies por papel) ──
  static const Color surfaceDark = Color(0xFF131316);
  static const Color surfaceElevatedDark = Color(0xFF1A1A1F);
  static const Color backgroundDark = Color(0xFF09090B);
  static const Color borderDark = Color(0xFF27272A);

  // ── Papéis do modo CLARO (fonte única dos hex do AppTheme.light) ──
  // Espelham os mesmos hex usados inline no `_base(Brightness.light)` —
  // quem precisa de um papel do tema FORA do ThemeData (splash, paletas
  // const de telas) importa daqui em vez de repetir o hex.

  /// Fundo de scaffold claro (mesmo papel do `scaffoldBackgroundColor`).
  static const Color scaffoldLight = Color(0xFFFAFAFA);

  /// Texto principal sobre superfícies claras (mesmo papel do `onSurface`).
  static const Color onSurfaceLight = Color(0xFF18181B);

  /// Texto secundário no escuro (mesmo papel do `onSurfaceVariant` dark).
  static const Color onSurfaceVariantDark = Color(0xFFA1A1AA);

  /// Texto secundário no claro (mesmo papel do `onSurfaceVariant` light).
  static const Color onSurfaceVariantLight = Color(0xFF6E6E77);

  /// Bordas/linhas no claro (mesmo papel do `outlineVariant` light).
  static const Color borderLight = Color(0xFFE4E4E7);

  // ── Status semânticos (centralizados; cores de ícone/decorativas) ──
  static const Color statusError = Color(0xFFDC2626);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusInfo = Color(0xFF3B82F6);
  static const Color statusPurple = Color(0xFF7C3AED);
  static const Color statusIndigo = Color(0xFF6366F1);
  static const Color statusTeal = Color(0xFF10B981);

  /// Cor semântica para um status de decisão (`approved`/`rejected`/
  /// `pending`) usado nas telas admin — aprovação de tenants/planos e
  /// entradas de auditoria. Valor desconhecido → cinza neutro (sem papel
  /// de cor no design system). Fonte única do mapeamento (antes duplicado
  /// em tenants/audit/dashboard).
  static Color decisionStatusColor(String? status) => switch (status) {
    'approved' => success,
    'rejected' => statusError,
    'pending' => statusWarning,
    _ => Colors.grey,
  };

  /// Resolve um par (escuro, claro) conforme o brilho do tema.
  static Color of(Brightness brightness, Color dark, Color light) =>
      brightness == Brightness.light ? light : dark;

  // ── Variantes por brilho (mantidas para compatibilidade) ──
  static Color errorOf(Brightness brightness) =>
      brightness == Brightness.light ? statusError : const Color(0xFFF87171);

  static Color successOf(Brightness brightness) =>
      brightness == Brightness.light ? successLight : success;

  static Color warningOf(Brightness brightness) =>
      brightness == Brightness.light ? warningLight : const Color(0xFFFBBF24);
}

/// Cores semânticas do app que dependem do brilho do tema e não existem no
/// [ColorScheme] do Material 3 (sucesso/entrada/saída/alerta/acento).
///
/// Implementado como [ThemeExtension] para que a troca claro ⇄ escuro seja
/// interpolada suavemente (lerp) junto com o resto do tema — em vez de
/// "saltar" entre as duas variantes.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.accent,
  });

  /// Variantes do modo claro (tons mais escuros para AA sobre superfícies claras).
  static const AppStatusColors light = AppStatusColors(
    income: AppColors.incomeLight,
    expense: AppColors.expenseLight,
    warning: AppColors.warningLight,
    accent: AppColors.accentLight,
  );

  /// Variantes do modo escuro (tons luminosos sobre superfícies escuras).
  static const AppStatusColors dark = AppStatusColors(
    income: AppColors.income,
    expense: AppColors.expense,
    warning: AppColors.warning,
    accent: AppColors.accent,
  );

  final Color income;
  final Color expense;
  final Color warning;
  final Color accent;

  @override
  AppStatusColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? accent,
  }) {
    return AppStatusColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      accent: accent ?? this.accent,
    );
  }

  @override
  AppStatusColors lerp(AppStatusColors? other, double t) {
    if (other == null) return this;
    return AppStatusColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

/// Acesso ergonômico às cores semânticas a partir de qualquer `ThemeData`:
/// `Theme.of(context).income`, `.expense`, `.warning` e `.accent`.
///
/// Lê o [AppStatusColors] registado no tema; se ausente (temas construídos
/// fora do design system), cai para a resolução estática por brilho — o
/// mesmo comportamento da API anterior.
extension AppColorsTheme on ThemeData {
  Color get income =>
      extension<AppStatusColors>()?.income ??
      AppColors.of(brightness, AppColors.income, AppColors.incomeLight);

  Color get expense =>
      extension<AppStatusColors>()?.expense ??
      AppColors.of(brightness, AppColors.expense, AppColors.expenseLight);

  Color get warning =>
      extension<AppStatusColors>()?.warning ??
      AppColors.of(brightness, AppColors.warning, AppColors.warningLight);

  Color get accent =>
      extension<AppStatusColors>()?.accent ??
      AppColors.of(brightness, AppColors.accent, AppColors.accentLight);
}
