import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

// Re-exporta a paleta semântica: mantém `AppColors`, `AppColorsTheme` e
// `AppStatusColors` acessíveis para quem importa apenas `app_theme.dart`.
export 'app_colors.dart';

/// Tema central — Material 3, dark-first, acento verde profissional.
///
/// Arquitetura:
/// * `AppTheme` — constrói os dois [ThemeData] (light/dark) sobre um único
///   [ColorScheme] por brilho, com as variantes de cada papel definidas
///   por função (ver `AppColors`).
/// * Cores fora do [ColorScheme] (income/expense/warning/accent) vivem em
///   [AppStatusColors] (ThemeExtension) e são interpoladas na troca de tema.
/// * Tipografia em `AppTypography`; espaçamento/raios/tamanhos em `AppTokens`.
abstract final class AppTheme {
  /// Tema claro — superfícies brancas/cinza-claro, texto quase-preto.
  static final ThemeData light = _base(Brightness.light);

  /// Tema escuro — superfícies quase-pretas azuladas, texto quase-branco.
  static final ThemeData dark = _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // ── ColorScheme M3 (funções do Material 3) ─────────────────────────────
    // Calibração AA (WCAG 2.x):
    // * primary = verde-médio (#15803D): branco sobre ele = 5.0:1 nos DOIS
    //   temas — o verde vivo (#16A34A) fica para ícones/destaques/FAB.
    // * onSurfaceVariant sobre fieldFill ≥ 4.5:1 (auditado em teste).
    // * outline ≥ 3:1 sobre superfícies (bordas de controles interativos).
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.brandMuted,
          onPrimary: Colors.white,
          primaryContainer: isLight
              ? AppColors.brandContainerLight
              : AppColors.brandContainerDark,
          onPrimaryContainer: isLight
              ? AppColors.onBrandContainerLight
              : AppColors.onBrandContainerDark,
          secondary: isLight
              ? const Color(0xFF64748B)
              : const Color(0xFF71717A),
          secondaryContainer: isLight
              ? const Color(0xFFF1F5F9)
              : const Color(0xFF27272A),
          onSecondaryContainer: isLight
              ? const Color(0xFF334155)
              : const Color(0xFFE4E4E7),
          surface: isLight ? Colors.white : AppColors.surfaceDark,
          onSurface: isLight
              ? const Color(0xFF18181B)
              : const Color(0xFFFAFAFA),
          onSurfaceVariant: isLight
              ? const Color(0xFF6E6E77)
              : const Color(0xFFA1A1AA),
          surfaceContainerHighest: isLight
              ? const Color(0xFFF4F4F5)
              : AppColors.surfaceElevatedDark,
          surfaceContainerHigh: isLight
              ? const Color(0xFFE4E4E7)
              : const Color(0xFF232328),
          surfaceContainerLow: isLight
              ? const Color(0xFFFAFAFA)
              : const Color(0xFF111114),
          outlineVariant: isLight
              ? const Color(0xFFE4E4E7)
              : AppColors.borderDark,
          // outline: bordas de CONTROLES interativos (botões outline) — ≥ 3:1
          // sobre as superfícies. No claro é um cinza médio; no escuro é mais
          // claro que o antigo #52525B para não sumir sobre #131316.
          outline: isLight ? const Color(0xFF8A8A94) : const Color(0xFF71717A),
          error: isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171),
          // onError explícito: texto/ícones sobre a cor de erro. No escuro o
          // branco daria só 2.8:1 sobre #F87171 — usa-se o vermelho-escuro.
          onError: isLight ? Colors.white : const Color(0xFF450A0A),
          errorContainer: isLight
              ? const Color(0xFFFEE2E2)
              : const Color(0xFF450A0A),
          onErrorContainer: isLight
              ? const Color(0xFF991B1B)
              : const Color(0xFFFECACA),
        );

    // ── Papéis derivados do scheme (fonte única — sem repetir hex) ────────
    final surface = scheme.surface;
    final border = scheme.outlineVariant;
    final fieldFill = isLight
        ? const Color(0xFFF4F4F5)
        : const Color(0xFF1F1F23);
    final navBackground = isLight ? Colors.white : AppColors.backgroundDark;
    // Indicador de navegação/chips selecionados = container do verde de marca.
    final selectionFill = scheme.primaryContainer;
    // Conteúdo sobre o indicador: o "on" do container — legível nos dois temas.
    final selectionContent = scheme.onPrimaryContainer;

    // Estados dos botões outline: a borda descansa em `outline` (≥3:1) e
    // perde força quando desabilitado (padrão M3).
    final outlinedSide = WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: scheme.outlineVariant);
      }
      return BorderSide(color: scheme.outline);
    });

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Inter (variável) — tipografia do ERP, aplicada em todos os textos.
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight
          ? const Color(0xFFFAFAFA)
          : AppColors.backgroundDark,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [isLight ? AppStatusColors.light : AppStatusColors.dark],

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
        toolbarHeight: 56,
        // Título 2 da escala (22/w600) — hierarquia conversa com titleLarge.
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.35,
          height: 1.25,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: border, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          // Texto de ação ultra-clean: 15/w400 — o peso vem da superfície
          // (Filled) e da hierarquia, não do peso da fonte.
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          backgroundColor: scheme.surfaceContainerLow,
          foregroundColor: scheme.primary,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        // A borda varia por estado; como o styleFrom só aceita BorderSide
        // fixa, aplica-se a propriedade por cima com copyWith.
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ).copyWith(side: outlinedSide),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizes.touchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        selectedColor: selectionFill,
        // Pílula completa (Apple): os chips de filtro viram cápsulas — o
        // mesmo shape StadiumBorder da navegação.
        shape: const StadiumBorder(),
        side: BorderSide.none,
        // Rótulo em onSurface (≥ 13:1 sobre fieldFill E sobre o container
        // selecionado, nos dois temas): o antigo onSurfaceVariant dava só
        // 4.45:1 (claro) e 3.55:1 (escuro) quando o chip estava selecionado.
        // (Neste SDK o labelStyle do chip é fixo — sem estados por tema.)
        // Rótulo do chip em corpo/nota da escala (13/w600): legível e
        // consistente com os textos inline de status (StatusChip).
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.navBarHeight,
        indicatorColor: selectionFill,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? selectionContent : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.15,
            letterSpacing: 0,
            color: selected ? selectionContent : scheme.onSurfaceVariant,
          );
        }),
        labelPadding: const EdgeInsets.only(top: 2),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navBackground,
        indicatorColor: selectionFill,
        indicatorShape: const StadiumBorder(),
        minWidth: 72,
        groupAlignment: -0.85,
        selectedIconTheme: IconThemeData(color: selectionContent),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: selectionContent,
        ),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isLight ? AppColors.brandMuted : AppColors.brand,
        foregroundColor: isLight ? Colors.white : const Color(0xFF052E16),
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        // Título 2 da escala (22/w600) — mesmo corpo do titleLarge.
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.35,
          height: 1.27,
          color: scheme.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),

      // Bottom sheet: mesmo papel de superfície do M3 (surfaceContainerLow)
      // com cantos superiores do design system (20) e sombra suave.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainerLow,
        modalElevation: 2,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        backgroundColor: isLight
            ? const Color(0xFF18181B)
            : const Color(0xFFFAFAFA),
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: isLight ? Colors.white : const Color(0xFF18181B),
        ),
        // Ação explícita (padrão M3 usa inversePrimary não auditado):
        // snackbar claro = fundo escuro → verde-claro; escuro = fundo claro
        // → verde-médio da marca. Ambos ≥ 4.5:1 (testado).
        actionTextColor: isLight
            ? const Color(0xFF34D399)
            : AppColors.brandMuted,
      ),

      // Menus de seleção (PopupMenu/Dropdown) — minimalistas e reais:
      // overlay chapado (surfaceContainerLow, sem tinta M3), raio fino do
      // sistema (12), sombra discreta, itens de 44px e texto 13/w400 —
      // a mesma voz do corpo, sem a escala exagerada do padrão M3.
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow.withValues(alpha: 0.14),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        position: PopupMenuPosition.under,
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: scheme.onSurface,
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        minVerticalPadding: AppSpacing.sm,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          // Alvo de toque ≥ 48dp (WCAG/androidTapTargetGuideline): sem a
          // densidade compacta — o segmento é um botão de baixa frequência,
          // não um stepper (onde o compacto já passou no guideline).
          // minimumSize: 0 desvia para o default M3 (40dp) — fixado em 48.
          minimumSize: const WidgetStatePropertyAll(Size(0, AppSizes.touchTarget)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        // No escuro o primary (#15803D) é pouco visível sobre as superfícies
        // escuras; o verde vivo da marca garante ≥ 3:1 (não-texto).
        color: isLight ? scheme.primary : AppColors.brand,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      textTheme: AppTypography.forScheme(scheme),
    );
  }
}
