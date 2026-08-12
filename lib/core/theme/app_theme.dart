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
  ///
  /// Verde vivo do novo design system (2026): o mesmo acento usado nos
  /// selos "Pago", no FAB e nos ícones dos cards de métrica.
  static const Color income = Color(0xFF22C55E);

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

  /// Acento verde do design system — ícones, bordas e destaques no tema
  /// escuro (verde vivo que aparece nos cards de métrica do dashboard).
  static const Color accent = Color(0xFF22C55E);

  /// Acento verde — tema claro (AA sobre branco).
  static const Color accentLight = Color(0xFF15803D);

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

  /// Acento verde do design system (ícones/bordas/destaques).
  Color get accent =>
      AppColors.of(brightness, AppColors.accent, AppColors.accentLight);
}

/// Tema central da aplicação (Material 3) — design system 2026.
///
/// Linguagem visual (espelha o app de referência): fundo quase-preto no modo
/// escuro, cards em carvão, cantos arredondados, campos preenchidos sem
/// contorno pesado e UM único acento (verde vivo) para hierarquia — ícones,
/// bordas, FAB, pílula ativa da navegação e selos de status.
abstract final class AppTheme {
  /// Semente do ColorScheme (verde do design system).
  static const Color _seed = Color(0xFF16A34A);

  static final ThemeData light = _base(Brightness.light);
  static final ThemeData dark = _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    ).copyWith(
      // Acento verde explícito (AA garantido pelas duplas abaixo):
      // no escuro o botão sólido é verde-médio com texto branco; o verde
      // vivo fica para ícones/bordas via `theme.accent`.
      primary: isLight ? const Color(0xFF15803D) : const Color(0xFF15803D),
      onPrimary: isLight ? Colors.white : Colors.white,
      primaryContainer: isLight
          ? const Color(0xFFD6F5E0)
          : const Color(0xFF123F26),
      onPrimaryContainer: isLight
          ? const Color(0xFF0B3B1E)
          : const Color(0xFFB7F0C7),
      // Superfície dos cards — #161D22 (design system ultra-clean):
      // carvão azulado frio, quase preto, distinto do fundo #111111.
      surface: isLight ? Colors.white : const Color(0xFF161D22),
      onSurface: isLight ? const Color(0xFF1A1C1B) : const Color(0xFFF4F4F5),
      onSurfaceVariant:
          isLight ? const Color(0xFF5F6B64) : const Color(0xFFA1A1AA),
      // Borda sutil dos cards/campos — #222E35 (0.5px nos cards).
      outlineVariant:
          isLight ? const Color(0xFFECEFED) : const Color(0xFF222E35),
      outline: isLight ? const Color(0xFF6B756F) : const Color(0xFF8A8A90),
    );

    final surface = scheme.surface;
    final border = scheme.outlineVariant;
    final fieldFill = isLight
        ? const Color(0xFFF1F3F2)
        : const Color(0xFF26262A);
    final navBackground = isLight ? Colors.white : const Color(0xFF0D0D0D);
    final accent = AppColors.of(brightness, AppColors.accent, AppColors.accentLight);

    // Cor do ícone/label selecionado da navegação: verde vivo no escuro,
    // verde-médio no claro (mesmo acento do design system).
    final navSelectedColor = accent;
    final navIndicator =
        isLight ? const Color(0xFFD6F5E0) : const Color(0xFF123F26);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: isLight
          ? const Color(0xFFF7F8F7)
          : const Color(0xFF111111),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          // Título 2 da escala (22) — cabeçalhos de páginas.
          fontSize: 22,
          fontWeight: FontWeight.w600,
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
          // AppCard ultra-clean: radius 12, borda externa 0.5px, FLAT
          // (sem sombra — elevation 0 acima).
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 0.5),
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
        // Rótulos DISCRETOS dentro dos campos (13 — 2 tamanhos abaixo do
        // texto digitado): sem fontSize, o label herdava o bodyLarge (17)
        // e truncava em campos estreitos ('Purchase pr...', 'Stock quan...')
        // — os rótulos flutuantes do formulário de produto. w400 leve +
        // onSurfaceVariant sutil; floatingLabelStyle fixa o tamanho quando
        // o rótulo sobe para a borda (sem encolher para 0.75× do default).
        // ⚠️ floatingLabelStyle NÃO fixa a cor: sem color, o InputDecorator
        // mantém o feedback de foco do M3 (rótulo tinge de primary/verde ao
        // focar) e onSurfaceVariant em repouso.
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        // Hints (textos informativos do tipo 'Pesquisar…') discretos: 14
        // — um pouco abaixo do texto digitado (17), sem parecer erro.
        hintStyle: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        // AppTextField ultra-clean: borda sutil em repouso que muda para o
        // acento no FOCo (o InputDecorator anima a cor suavemente — 200ms).
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // AppButton ultra-clean: altura 48, cantos 12, texto w400.
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // AppButton.secondary ultra-clean: altura 48, cantos 12, w400 —
          // cores sóbrias da superfície (borda outlineVariant).
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
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
        // Pílula ativa: fundo verde-escuro com ícone/label no acento vivo
        // (formato de pílula — StadiumBorder — igual ao app de referência).
        indicatorColor: navIndicator,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? navSelectedColor : scheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            // Ultra-clean: peso LEVE (w500) — a hierarquia vem da COR
            // (acento no ativo), nunca do peso pesado.
            fontWeight: FontWeight.w500,
            height: 1.15,
            letterSpacing: -0.1,
            color: selected ? navSelectedColor : scheme.onSurfaceVariant,
          );
        }),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navBackground,
        indicatorColor: navIndicator,
        // Pílula (StadiumBorder) do rail no MESMO padrão da barra mobile —
        // navegação consistente em qualquer largura (ultra-clean).
        indicatorShape: const StadiumBorder(),
        groupAlignment: -0.9,
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          // Ultra-clean: peso LEVE — hierarquia pela cor, não pelo peso.
          fontWeight: FontWeight.w500,
          color: navSelectedColor,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
      ),

      // FAB do design system: verde vivo (escuro) / verde-médio (claro),
      // sempre com o ícone em alto contraste.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isLight
            ? const Color(0xFF15803D)
            : const Color(0xFF16A34A),
        foregroundColor: isLight ? Colors.white : const Color(0xFF052E16),
        shape: const CircleBorder(),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      dialogTheme: DialogThemeData(
        // Título 2 da escala (22) — diálogos de confirmação e de
        // quantidade (AlertDialog) seguem o mesmo papel das sheets.
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.3,
          color: scheme.onSurface,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),

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
        // Escala tipográfica modular (Apple HIG / Google Material) adaptada
        // ao ERP: 34/28/22/20/17/15/13/11. Em vez de exagerar na variedade
        // de tamanhos, a hierarquia combina tamanhos médios com variações
        // de peso (w400 texto comum, w600+ valores/rótulos importantes).
        // Estilos que carregam NÚMEROS (preços em MZN, quantidades kg/un)
        // usam `tabularFigures` para as colunas alinharem dígito a dígito.
        displaySmall: TextStyle(
          // Large Title (34) — login, boas-vindas, fecho de caixa.
          // Ultra-clean: LIGHT (w300) — hierarquia pelo tamanho, não peso.
          fontSize: 34,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.8,
          height: 1.15,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          // Título 1 (28) — cabeçalhos de páginas e seções principais.
          // Ultra-clean: LIGHT (w300), como o display.
          fontSize: 28,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.6,
          height: 1.2,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineSmall: TextStyle(
          // Título 1.5 (24) — valores de KPIs e totais em destaque.
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          height: 1.25,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleLarge: TextStyle(
          // Título 2 (22) — cartões de resumo, cabeçalhos de modais.
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          height: 1.3,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleMedium: TextStyle(
          // Título 3 (20) — subtítulos, cabeçalhos de seções e totais
          // em colunas (recebe tabular figures: carrega valores em MZN).
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          height: 1.35,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleSmall: TextStyle(
          // Destaques de linha (14) — nomes em cards de vendas/compras.
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          height: 1.4,
        ),
        bodyLarge: TextStyle(
          // Corpo destacado (17) — textos principais de formulários.
          fontSize: 17,
          fontWeight: FontWeight.w400,
          height: 1.5,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        bodyMedium: TextStyle(
          // Corpo padrão (15) — descrições e valores de linhas.
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        bodySmall: TextStyle(
          // Nota (13) — validades FIFO, códigos de barras, rodapés.
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.4,
          fontFeatures: [FontFeature.tabularFigures()],
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
          // Caption/badges (11) — etiquetas de estado e indicadores.
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
