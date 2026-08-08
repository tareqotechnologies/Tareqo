import 'package:flutter/material.dart';

/// Cores semânticas usadas em várias telas (entradas/saídas, alertas).
///
/// Cada cor tem duas variantes por brilho do tema (WCAG 2.x): as cores base
/// (escuro) são tons luminosos que destacam nas superfícies escuras; as
/// variantes `*Light` são tons mais escuros que atingem AA (≥ 4.5:1) sobre
/// superfícies brancas do tema claro. Use [AppColors.of] para resolver a
/// variante do tema atual.
abstract final class AppColors {
  /// Entradas de caixa / valores positivos — tema escuro.
  static const Color income = Color(0xFF189A5E);

  /// Entradas de caixa / valores positivos — tema claro (AA sobre branco).
  static const Color incomeLight = Color(0xFF106B3E);

  /// Saídas de caixa / valores negativos — tema escuro.
  ///
  /// Clareado de `#D64550` para `#E05B64`: o valor anterior tinha contraste
  /// de apenas 3.96:1 sobre os cards escuros (texto de valor do Financeiro).
  static const Color expense = Color(0xFFE05B64);

  /// Saídas de caixa / valores negativos — tema claro (AA sobre branco).
  static const Color expenseLight = Color(0xFFB4232F);

  /// Avisos (estoque baixo, pendências, atrasos) — tema escuro.
  static const Color warning = Color(0xFFE08F2B);

  /// Avisos — tema claro (AA sobre branco).
  static const Color warningLight = Color(0xFF8A5500);

  /// Resolve a variante da cor conforme o brilho do tema.
  static Color of(Brightness brightness, Color dark, Color light) =>
      brightness == Brightness.light ? light : dark;
}

/// Acesso às cores semânticas resolvidas pelo brilho do tema atual
/// (`theme.income` = variante clara no modo claro, escura no escuro).
extension AppColorsTheme on ThemeData {
  Color get income =>
      AppColors.of(brightness, AppColors.income, AppColors.incomeLight);

  Color get expense =>
      AppColors.of(brightness, AppColors.expense, AppColors.expenseLight);

  Color get warning =>
      AppColors.of(brightness, AppColors.warning, AppColors.warningLight);
}

/// Tema central da aplicação (Material 3) — design minimalista moderno.
///
/// Diretrizes: superfícies neutras, cards com borda sutil (sem sombras
/// pesadas), cantos arredondados, campos preenchidos sem contorno e um
/// único acento (verde-esmeralda) para hierarquia.
abstract final class AppTheme {
  /// Cor semântica do ERP (verde-esmeralda profundo).
  static const Color _seed = Color(0xFF0E6B5A);

  static final ThemeData light = _base(Brightness.light);
  static final ThemeData dark = _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final surface = isLight ? Colors.white : const Color(0xFF171C1B);
    final border = isLight ? const Color(0xFFECEFED) : const Color(0xFF242B29);
    final fieldFill = isLight
        ? const Color(0xFFF1F3F2)
        : const Color(0xFF1C2220);
    final navBackground = isLight ? Colors.white : const Color(0xFF141918);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: isLight
          ? const Color(0xFFF7F8F7)
          : const Color(0xFF101413),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: fieldFill,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        // Tipografia compacta: evita que rótulos longos ('Customers',
        // 'Financeiro') quebrem em duas linhas nas telas estreitas.
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -0.1,
          ),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navBackground,
        indicatorColor: scheme.primaryContainer,
        groupAlignment: -0.9,
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isLight
            ? const Color(0xFF1C2623)
            : const Color(0xFFEDF1EF),
        contentTextStyle: TextStyle(
          color: isLight ? Colors.white : const Color(0xFF101413),
        ),
      ),

      textTheme: TextTheme(
        // Inter é desenhada com tracking negativo em corpo de título — a
        // hierarquia abaixo segue a escala Material 3 com ajustes finos.
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1.2,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
