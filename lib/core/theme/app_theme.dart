import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

// Re-exporta a paleta semântica: mantém `AppColors`, `AppColorsTheme` e
// `AppStatusColors` acessíveis para quem importa apenas `app_theme.dart`.
export 'app_colors.dart';

/// Tema central — Material 3, dark-first, identidade petróleo/terracota.
///
/// Arquitetura:
/// * `AppTheme` — constrói os dois [ThemeData] (light/dark) sobre um único
///   [ColorScheme] por brilho, com as variantes de cada papel definidas
///   por função (ver `AppColors`).
/// * Cores fora do [ColorScheme] (income/expense/warning/accent) vivem em
///   [AppStatusColors] (ThemeExtension) e são interpoladas na troca de tema.
/// * Tipografia em `AppTypography`; espaçamento/raios/tamanhos em `AppTokens`.
///
/// Calibração de contraste (WCAG 2.x, auditada em
/// `test/core/theme/theme_contrast_test.dart`):
/// * Claro: primário = slate (#3D4D55) — branco sobre ele 8.8:1.
/// * Escuro: primário = bege (#D3C3B9) — preto suave sobre ele 10.6:1 e o
///   preenchimento destaca 9.5:1 contra a superfície petróleo.
/// * Terracota (#B58863) = acento RESERVADO do escuro (FAB, links, cursor,
///   ícones): 5.1:1 sobre as superfícies petróleo — nunca preenchimento de
///   massa (regra anti-excesso).
/// * Nenhum verde no tema: hover/pressed são véus neutros (preto nos
///   preenchidos, onSurface nos de superfície).
abstract final class AppTheme {
  /// Tema claro — superfícies brancas/creme quente, texto preto suave.
  static final ThemeData light = _base(Brightness.light);

  /// Tema escuro — superfícies petróleo, texto quase-branco, acento bege.
  static final ThemeData dark = _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // ── ColorScheme M3 (funções do Material 3) ─────────────────────────────
    // Todos os papéis explícitos — o seed não influencia o resultado.
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.petrol,
          brightness: brightness,
        ).copyWith(
          // Primário: slate no claro (texto branco 8.8:1) e bege no escuro
          // (texto preto suave 10.6:1) — ambos AA/AAA nos dois temas.
          primary: isLight ? AppColors.slate : AppColors.warmBeige,
          onPrimary: isLight ? Colors.white : AppColors.softBlack,
          // Container do primário (chips selecionados, indicador de navegação):
          // bege no claro com preto suave (12.2:1); slate no escuro com bege
          // (5.1:1) — pílula visível (1.9:1 de preenchimento contra a
          // superfície petróleo) sem competir com o botão primário.
          primaryContainer: isLight
              ? AppColors.warmBeige
              : AppColors.slate,
          onPrimaryContainer: isLight
              ? AppColors.softBlack
              : AppColors.warmBeige,
          secondary: isLight
              ? const Color(0xFF6B7B82)
              : const Color(0xFF9FB0B5),
          secondaryContainer: isLight
              ? AppColors.borderLight
              : const Color(0xFF1E3A41),
          onSecondaryContainer: isLight
              ? AppColors.slate
              : const Color(0xFFCDD6D8),
          surface: isLight ? Colors.white : AppColors.surfaceDark,
          onSurface: isLight
              ? AppColors.onSurfaceLight
              : const Color(0xFFFAFAFA),
          onSurfaceVariant: isLight
              ? AppColors.onSurfaceVariantLight
              : AppColors.onSurfaceVariantDark,
          surfaceContainerHighest: isLight
              ? const Color(0xFFF1EDE9)
              : AppColors.surfaceElevatedDark,
          surfaceContainerHigh: isLight
              ? AppColors.borderLight
              : const Color(0xFF142B32),
          surfaceContainerLow: isLight
              ? const Color(0xFFFAFAFA)
              : const Color(0xFF0E1E24),
          outlineVariant: isLight
              ? AppColors.borderLight
              : AppColors.borderDark,
          // outline: bordas de CONTROLES interativos (botões outline) — ≥ 3:1
          // sobre as superfícies (3.9:1 no claro, 4.7:1 no escuro).
          outline: isLight
              ? const Color(0xFF85817E)
              : const Color(0xFF7E8C90),
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
        ? const Color(0xFFF1EDE9)
        : const Color(0xFF172A31);
    final navBackground = isLight ? Colors.white : AppColors.backgroundDark;
    // Indicador de navegação/chips selecionados = container do primário.
    final selectionFill = scheme.primaryContainer;
    // Conteúdo sobre o indicador: o "on" do container — legível nos dois temas.
    final selectionContent = scheme.onPrimaryContainer;

    // Estados dos botões outline: a borda descansa em `outline` (≥3:1) e
    // perde força quando desabilitado (padrão M3). No foco, a borda assume
    // o primary (1.5px) — indicador de foco visível que não depende apenas
    // de cor (o véu de foco é sutil).
    final outlinedSide = WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: scheme.outlineVariant);
      }
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: scheme.primary, width: 1.5);
      }
      return BorderSide(color: scheme.outline);
    });

    // ── Estados de interação (hover/pressed/focus) — SOBRES e NEUTROS ────
    // O padrão M3 deriva o véu de hover do `primary` — mantido aqui neutro
    // e discreto, em ambos os temas:
    // * Botões de SUPERFÍCIE (outline/texto/ícone/segmented/elevated): véu
    //   cinza via `onSurface` com alfa baixo — cinza claro no tema claro,
    //   clareamento sutil no escuro. Sem acento, brilho ou gradiente.
    // * Botões PREENCHIDOS (primário/destrutivo): véu PRETO translúcido —
    //   ESCURECE o preenchimento (slate e bege ficam mais sóbrios no hover;
    //   o vermelho do destrutivo idem). Neutro (r=g=b), nunca neon.
    // Transição de 150ms (AppDurations.fast) — dentro da faixa 120–180ms.
    WidgetStateProperty<Color?> surfaceOverlay() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          if (states.contains(WidgetState.pressed)) {
            return scheme.onSurface.withValues(alpha: 0.10);
          }
          if (states.contains(WidgetState.focused)) {
            return scheme.onSurface.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.onSurface.withValues(alpha: 0.06);
          }
          return null;
        });

    WidgetStateProperty<Color?> filledOverlay() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          if (states.contains(WidgetState.pressed)) {
            return Colors.black.withValues(alpha: 0.14);
          }
          if (states.contains(WidgetState.focused)) {
            return Colors.black.withValues(alpha: 0.10);
          }
          if (states.contains(WidgetState.hovered)) {
            return Colors.black.withValues(alpha: 0.08);
          }
          return null;
        });

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Inter (variável) — tipografia do ERP, aplicada em todos os textos.
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight
          ? AppColors.scaffoldLight
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
        ).copyWith(
          animationDuration: AppDurations.fast,
          // Normal: primário sóbrio (slate/bege) + conteúdo auditado.
          // Disabled: cinza neutro, sem sombra.
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              // Cinza neutro sutil sobre a superfície — desabilitado lê-se
              // como "inativo", não como ação.
              return scheme.onSurface.withValues(alpha: 0.08);
            }
            return scheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              // Texto desabilitado: neutro desatenue com contraste
              // suficiente (~2.8:1 composto; isento de AA na WCAG, mas
              // legível).
              return scheme.onSurface.withValues(alpha: 0.45);
            }
            return scheme.onPrimary;
          }),
          // Hover/pressed: escurece o preenchimento — véu preto translúcido,
          // sem brilho, gradiente ou elevação extra.
          overlayColor: filledOverlay(),
          elevation: const WidgetStatePropertyAll(0),
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
        ).copyWith(
          animationDuration: AppDurations.fast,
          // Hover/pressed: véu cinza neutro.
          overlayColor: surfaceOverlay(),
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
        ).copyWith(
          side: outlinedSide,
          animationDuration: AppDurations.fast,
          // Hover/pressed: véu cinza claro discreto — borda/texto neutros.
          overlayColor: surfaceOverlay(),
        ),
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
        ).copyWith(
          animationDuration: AppDurations.fast,
          // Hover/pressed: véu cinza neutro (o rótulo no acento da marca —
          // ação de marca — mas o FUNDO de hover nunca é colorido).
          overlayColor: surfaceOverlay(),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ).copyWith(
          // Hover/pressed/focus: véu cinza neutro.
          overlayColor: surfaceOverlay(),
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
        // selecionado, nos dois temas). Rótulo do chip em corpo/nota da
        // escala (13/w600): legível e consistente com o StatusChip.
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
        // FAB = ação mais importante do ecrã → recebe o acento RESERVADO:
        // slate no claro (ícone branco 8.8:1) e terracota no escuro
        // (ícone preto suave 5.7:1) — o primário preenchido continua bege
        // no escuro; a terracota fica só onde o destaque é justificado.
        backgroundColor: isLight ? AppColors.slate : AppColors.terracotta,
        foregroundColor: isLight ? Colors.white : AppColors.softBlack,
        elevation: 2,
        highlightElevation: 4,
        // Hover/focus: escurece o preenchimento com véu preto sutil (mesma
        // linguagem dos botões preenchidos) — sem brilho ou lift exagerado.
        hoverColor: Colors.black.withValues(alpha: 0.08),
        focusColor: Colors.black.withValues(alpha: 0.10),
        hoverElevation: 2,
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
        // Inversão por brilho: claro = preto suave da paleta; escuro = bege
        // (mesma voz do primário). Conteúdo sempre auditado:
        // branco/preto suave ≥ 10:1.
        backgroundColor: isLight
            ? AppColors.softBlack
            : AppColors.warmBeige,
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          color: isLight ? Colors.white : AppColors.softBlack,
        ),
        // Ação explícita (padrão M3 usa inversePrimary não auditado):
        // snackbar claro = preto suave → bege (10.6:1); escuro = bege →
        // slate (5.1:1). Ambos ≥ 4.5:1.
        actionTextColor: isLight ? AppColors.warmBeige : AppColors.slate,
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
          // Hover/pressed: véu cinza neutro.
          overlayColor: surfaceOverlay(),
          animationDuration: AppDurations.fast,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        // No escuro o acento RESERVADO (terracota) garante 5.1:1 sobre as
        // superfícies petróleo (não-texto ≥ 3:1); no claro, o primário.
        color: isLight ? scheme.primary : AppColors.terracotta,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      textTheme: AppTypography.forScheme(scheme),
    );
  }
}
