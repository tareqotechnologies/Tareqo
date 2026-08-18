import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Cores semânticas usadas em várias telas (entradas/saídas, alertas).
abstract final class AppColors {
 static const Color income = Color(0xFF34D399);

 /// Verde claro AA (≥4.5:1 sobre branco e chip@14% — W4 calibrado).
 static const Color incomeLight = Color(0xFF03754F);

 static const Color expense = Color(0xFFF87171);

 /// Vermelho claro AA (≥4.5:1 sobre branco e chip@14% — W4 calibrado).
 static const Color expenseLight = Color(0xFFC81E1E);

 static const Color warning = Color(0xFFFBBF24);

 /// Âmbar claro AA (≥4.5:1 sobre branco e chip@14% — W4 calibrado).
 static const Color warningLight = Color(0xFF9A5308);

 static const Color accent = Color(0xFF22C55E);
 static const Color accentLight = Color(0xFF16A34A);

 static const Color surfaceDark = Color(0xFF131316);
 static const Color surfaceElevatedDark = Color(0xFF1A1A1F);
 static const Color backgroundDark = Color(0xFF09090B);
 static const Color borderDark = Color(0xFF27272A);

 static Color of(Brightness brightness, Color dark, Color light) =>
 brightness == Brightness.light ? light : dark;
}

extension AppColorsTheme on ThemeData {
 Color get income =>
 AppColors.of(brightness, AppColors.income, AppColors.incomeLight);

 Color get expense =>
 AppColors.of(brightness, AppColors.expense, AppColors.expenseLight);

 Color get warning =>
 AppColors.of(brightness, AppColors.warning, AppColors.warningLight);

 Color get accent =>
 AppColors.of(brightness, AppColors.accent, AppColors.accentLight);
}

/// Tema central V4 — Material 3, dark-first, acento verde profissional.
abstract final class AppTheme {
 static const Color _seed = Color(0xFF16A34A);

 static final ThemeData light = _base(Brightness.light);
 static final ThemeData dark = _base(Brightness.dark);

 static ThemeData _base(Brightness brightness) {
 final isLight = brightness == Brightness.light;
 final scheme = ColorScheme.fromSeed(
 seedColor: _seed,
 brightness: brightness,
 ).copyWith(
 // Primary: verde-médio AA (branco sobre ele = 5.0:1) nos DOIS temas —
 // o verde vivo (#22C55E) fica para ícones/bordas via `theme.accent` e
 // para o FAB (que usa cor própria), nunca para texto sobre superfície.
 primary: const Color(0xFF15803D),
 onPrimary: Colors.white,
 primaryContainer: isLight
 ? const Color(0xFFD1FAE5)
 : const Color(0xFF14532D),
 onPrimaryContainer: isLight
 ? const Color(0xFF064E3B)
 : const Color(0xFFBBF7D0),
 secondary: isLight ? const Color(0xFF64748B) : const Color(0xFF71717A),
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
 outline: isLight ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
 error: isLight ? const Color(0xFFDC2626) : const Color(0xFFF87171),
 errorContainer: isLight
 ? const Color(0xFFFEE2E2)
 : const Color(0xFF450A0A),
 onErrorContainer: isLight
 ? const Color(0xFF991B1B)
 : const Color(0xFFFECACA),
 );

 final surface = scheme.surface;
 final border = scheme.outlineVariant;
 final fieldFill = isLight
 ? const Color(0xFFF4F4F5)
 : const Color(0xFF1F1F23);
 final navBackground = isLight ? Colors.white : AppColors.backgroundDark;
 final accent = AppColors.of(
 brightness,
 AppColors.accent,
 AppColors.accentLight,
 );
 final navSelectedColor = accent;
 final navIndicator = isLight
 ? const Color(0xFFD1FAE5)
 : const Color(0xFF14532D);

 return ThemeData(
 useMaterial3: true,
 // Inter (variável) — tipografia do ERP, aplicada em todos os textos.
 fontFamily: 'Inter',
 colorScheme: scheme,
 scaffoldBackgroundColor: isLight
 ? const Color(0xFFFAFAFA)
 : AppColors.backgroundDark,
 splashFactory: InkRipple.splashFactory,
 visualDensity: VisualDensity.standard,    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleSpacing: AppSpacing.lg,
      toolbarHeight: 56,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
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
 textStyle: const TextStyle(
 fontSize: 15,
 fontWeight: FontWeight.w400,
 letterSpacing: -0.1,
 ),
 ),
 ),    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSizes.touchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppSizes.touchTarget),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

 iconButtonTheme: IconButtonThemeData(
 style: IconButton.styleFrom(
 minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
 shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
 ),
 ),    chipTheme: ChipThemeData(
      backgroundColor: fieldFill,
      selectedColor: isLight
          ? const Color(0xFFD1FAE5)
          : const Color(0xFF14532D),
      // Pílula completa (Apple): os chips de filtro viram cápsulas — o
      // mesmo shape StadiumBorder da navegação.
      shape: const StadiumBorder(),
      side: BorderSide.none,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
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
 indicatorColor: navIndicator,
 indicatorShape: const StadiumBorder(),
 labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
 iconTheme: WidgetStateProperty.resolveWith((states) {
 final selected = states.contains(WidgetState.selected);
 return IconThemeData(
 size: 22,
 color: selected ? navSelectedColor : scheme.onSurfaceVariant,
 );
 }),      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.15,
          letterSpacing: 0,
          color: selected ? navSelectedColor : scheme.onSurfaceVariant,
        );
      }),
 labelPadding: const EdgeInsets.only(top: 2),
 ),    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: navBackground,
      indicatorColor: navIndicator,
      indicatorShape: const StadiumBorder(),
      minWidth: 72,
      groupAlignment: -0.85,
      selectedLabelTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: navSelectedColor,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
    ),

 floatingActionButtonTheme: FloatingActionButtonThemeData(
 backgroundColor: isLight
 ? const Color(0xFF15803D)
 : const Color(0xFF22C55E),
 foregroundColor: isLight ? Colors.white : const Color(0xFF052E16),
 elevation: 2,
 highlightElevation: 4,
 shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
 sizeConstraints: const BoxConstraints.tightFor(
 width: 56,
 height: 56,
 ),
 ),

 dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.35,
        height: 1.27,
        color: scheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
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
 color: isLight ? Colors.white : const Color(0xFF18181B),
 ),
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
 visualDensity: VisualDensity.compact,
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

 textTheme: TextTheme(
 // Escala modular Apple HIG/SF Pro (spec executável — ver
 // test/core/theme/typography_scale_test.dart): 34/28/24/22/20/17/15/
 // 14/13/12/11; títulos ≥20px usam o corte Display da Inter (opsz).
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
 ),    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.4,
      height: 1.25,
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontVariations: const [FontVariation('opsz', 32)],
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.35,
      height: 1.27,
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontVariations: const [FontVariation('opsz', 24)],
    ),
    titleMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.3,
      height: 1.3,
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontVariations: const [FontVariation('opsz', 24)],
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.15,
      height: 1.35,
      color: scheme.onSurface,
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
 ),    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.25,
      color: scheme.onSurface,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      height: 1.25,
      color: scheme.onSurfaceVariant,
    ),
 labelSmall: TextStyle(
 fontSize: 11,
 fontWeight: FontWeight.w500,
 letterSpacing: 0.2,
 height: 1.25,
 color: scheme.onSurfaceVariant,
 ),
 ),
 );
 }
}
