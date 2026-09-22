import 'package:flutter/material.dart';

/// Paleta oficial e cores semânticas que NÃO vivem no [ColorScheme].
///
/// RE2 — Paleta base do produto (fonte única dos hexadecimais):
/// * `petrol`     #10282A — azul-petróleo escuro (identidade, superfícies)
/// * `slate`      #3D4D55 — cinza azulado (primário claro, estrutura)
/// * `warmGray`   #A79E9C — cinza quente (texto secundário, neutros)
/// * `warmBeige`  #D3C3B9 — bege claro (acento no escuro, texto sobre petrol)
/// * `terracotta` #B58863 — terracota (destaque único, usada com parcimônia)
/// * `softBlack`  #161616 — preto suave (texto, snackbar)
///
/// Regra do design system: cor representa **função**, nunca aparência.
/// A hierarquia vem dos NEUTROS (petróleo/slate/cinza quente); a terracota
/// e o bege são destaques reservados — nunca preenchimentos de massa.
/// Onde existe um par para os dois temas, o sufixo `*Light` refere-se ao
/// modo claro — não é uma cor "mais clara".
///
/// As variantes usadas como TEXTO sobre superfícies claras foram calibradas
/// para WCAG AA (≥ 4.5:1) e, como ícone/chip (≥ 3:1) — ver
/// `test/core/theme/theme_contrast_test.dart`.
abstract final class AppColors {
  // ── Paleta base (não alterar sem justificativa técnica) ──
  static const Color petrol = Color(0xFF10282A);
  static const Color slate = Color(0xFF3D4D55);
  static const Color warmGray = Color(0xFFA79E9C);
  static const Color warmBeige = Color(0xFFD3C3B9);
  static const Color terracotta = Color(0xFFB58863);
  static const Color softBlack = Color(0xFF161616);

  // ── Marca — derivadas da paleta base ──
  /// Acento da marca no MODO ESCURO: terracota — destaque sóbrio sobre
  /// superfícies petróleo (ícones, FAB, cursor; não é cor de preenchimento
  /// de massa). Ícone/chip ≥ 3:1 sobre as superfícies escuras.
  static const Color brand = terracotta;

  /// Acento da marca no MODO CLARO: slate-escuro (#2C3E45) derivado do
  /// `slate` — botão primário com texto branco a 8.6:1 (AA/AAA). O antigo
  /// verde-médio foi substituído: a marca deixa de ter verde como padrão.
  static const Color brandMuted = Color(0xFF2C3E45);

  /// Container do acento (chips selecionados, indicador de navegação):
  /// bege no claro (sobreposição suave do `warmBeige`); petróleo no escuro.
  static const Color brandContainerLight = warmBeige;
  static const Color brandContainerDark = petrol;

  /// Conteúdo sobre os containers do acento: preto suave no bege claro
  /// (12.2:1) e bege no petróleo escuro (8.8:1) — ambos ≥ AA.
  static const Color onBrandContainerLight = softBlack;
  static const Color onBrandContainerDark = warmBeige;

  // ── API legada (mantida para compatibilidade) ──
  // `accent`/`success` apontam para o acento da marca (terracota no escuro,
  // slate-escuro no claro). Nenhum uso de "verde de sucesso" permanece:
  // aprovação/conclusão usa o neutro quente da marca (regra: sem verde).
  static const Color accent = brand;
  static const Color accentLight = brandMuted;
  static const Color success = brand;
  static const Color successLight = brandMuted;

  // ── Fluxo de caixa (entradas/saídas) — calibrado AA no teste de contraste.
  // Entrada (income): tom quente terroso (verde removido da semântica);
  // mantém ≥ 4.5:1 sobre branco e sobre chip@14% nos DOIS temas.
  static const Color income = Color(0xFFD8B08C);
  static const Color incomeLight = Color(0xFF5A4632);
  // Saída (expense) e alertas: vermelho/âmbar já auditados — preservados.
  static const Color expense = Color(0xFFF87171);
  static const Color expenseLight = Color(0xFFC81E1E);

  // ── Alertas genéricos (texto curto em negrito sobre superfície clara) ──
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningLight = Color(0xFF9A5308);

  // ── Neutros do modo escuro (família petróleo — superfícies por papel) ──
  // Escala derivada do petrol com gradação de luminosidade (antes cinza
  // puro #131316/#09090B): as superfícies ganham a temperatura da marca.
  static const Color surfaceDark = Color(0xFF10232A);
  static const Color surfaceElevatedDark = Color(0xFF16303A);
  static const Color backgroundDark = Color(0xFF0B161A);
  static const Color borderDark = Color(0xFF24363C);

  // ── Papéis do modo CLARO (fonte única dos hex do AppTheme.light) ──
  // Espelham os mesmos hex usados inline no `_base(Brightness.light)` —
  // quem precisa de um papel do tema FORA do ThemeData (splash, paletas
  // const de telas) importa daqui em vez de repetir o hex.

  /// Fundo de scaffold claro (mesmo papel do `scaffoldBackgroundColor`).
  static const Color scaffoldLight = Color(0xFFFAFAFA);

  /// Texto principal sobre superfícies claras (mesmo papel do `onSurface`).
  static const Color onSurfaceLight = Color(0xFF161616);

  /// Texto secundário no escuro (mesmo papel do `onSurfaceVariant` dark).
  static const Color onSurfaceVariantDark = warmGray;

  /// Texto secundário no claro (mesmo papel do `onSurfaceVariant` light).
  static const Color onSurfaceVariantLight = Color(0xFF63646A);

  /// Bordas/linhas no claro (mesmo papel do `outlineVariant` light).
  static const Color borderLight = Color(0xFFE7E1DD);

  // ── Status semânticos (centralizados; cores de ícone/decorativas) ──
  // Paleta RE2: os antigos roxo/índigo/teal viram os três matizes da paleta
  // base — a diferenciação entre tipos de notificação/mensagem continua
  // existindo (petrol ≠ terracota ≠ slate), sem cores fora do sistema.
  static const Color statusError = Color(0xFFDC2626);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusInfo = petrol;
  static const Color statusPurple = terracotta;
  static const Color statusIndigo = slate;
  static const Color statusTeal = terracotta;

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
