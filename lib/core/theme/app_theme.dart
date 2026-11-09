import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

// Re-exporta a paleta semântica: mantém `AppColors`, `AppColorsTheme` e
// `AppStatusColors` acessíveis para quem importa apenas `app_theme.dart`.
export 'app_colors.dart';

/// Cores auxiliares do [ThemeData] — paleta oficial (U-23).
/// Delegam para [AppColors] sem fracionamento de nomes.
final class _AppThemeAuxColors {
  /// Preto oficial (#0C0B0A) sobre gelo.
  static const Color inkDark = AppColors.brandBlack;
  static const Color inkLight = AppColors.softWhite;
}

/// Tema central TAREQO Signature — Material 3 com linguagem de interação Apple.
///
/// Identidade: neutros de inspiração Apple (canvas, tinta, preto OLED) e UM
/// acento quente (laranja) reservado a alertas. A ação principal é a própria
/// tinta — carvão no claro, branco suave no escuro — como um botão Apple.
///
/// Arquitetura:
/// * `AppTheme.light` / `AppTheme.dark` — dois [ThemeData] construídos
///   sobre um [ColorScheme] explícito por brilho (sem `seed`).
/// * Cores fora do [ColorScheme] (entrada/saída/alerta/acento) vivem em
///   [AppStatusColors] e são interpoladas na troca de tema.
/// * Tipografia em `AppTypography`; espaçamento, raios, elevação e
///   movimento em `AppTokens`.
///
/// Papéis do [ColorScheme] (contrato):
/// * `primary` = cor de AÇÃO com contraste forte sobre `surface` (usada como
///   texto/ícone/borda/seleção em todo o app) e `onPrimary` = o que se lê
///   sobre ela. Nunca branco-sobre-branco.
/// * `primaryContainer` = véu neutro de seleção/realce (sem laranja);
///   `errorContainer`/`tertiaryContainer` = fundos suaves com o respetivo
///   `on*Container` legível (≥ 4.5:1).
///
/// Contraste auditado (WCAG): texto ≥ 4.5:1 sobre todas as superfícies,
/// `onPrimary/primary` ≥ 16:1 em ambos os temas.
abstract final class AppTheme {
  /// Tema claro — canvas #F5F5F7, superfícies brancas, tinta #1D1D1F.
  static final ThemeData light = _base(Brightness.light);

  /// Tema escuro — preto OLED, superfícies #1C1C1E, texto branco suave.
  static final ThemeData dark = _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // ── Superfícies ──────────────────────────────────────────────────
    final canvas = isLight
        ? AppColors.lightBackground
        : AppColors.darkBackground;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final surfaceSecondary = isLight
        ? AppColors.lightSurfaceSecondary
        : AppColors.darkSurfaceSecondary;
    final surfaceElevated = isLight
        ? AppColors.lightSurfaceElevated
        : AppColors.darkSurfaceElevated;

    // ── Texto ────────────────────────────────────────────────────────
    final textPrimary = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final textSecondary = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    // ── Bordas ───────────────────────────────────────────────────────
    final border = isLight ? AppColors.lightBorder : AppColors.darkBorder;
    final separator = isLight ? AppColors.lightDivider : AppColors.darkDivider;

    // ── Ação / Primária ──────────────────────────────────────────────
    // `action` = preenchimento da ação E cor de destaque em texto/ícone
    // (carvão no claro, branco suave no escuro). `onAction` = rótulo sobre
    // o preenchimento (branco no claro, tinta no escuro).
    final action = isLight ? AppColors.lightPrimary : AppColors.darkPrimary;
    final onAction = isLight
        ? AppColors.lightOnPrimary
        : AppColors.darkOnPrimary;
    // Véu neutro de seleção/realce: a própria tinta a 7% (claro) / 12%
    // (escuro) sobre a superfície — substitui o creme laranja.
    final actionTint = Color.alphaBlend(
      action.withValues(alpha: isLight ? 0.07 : 0.12),
      surface,
    );

    // ── Laranja acento - APENAS para alertas e destaques ─────────────
    final accent = isLight
        ? AppColors.accentOrange
        : AppColors.darkAccentOrange;
    final warningText = isLight
        ? AppColors.warningText
        : AppColors.darkWarningText;
    final warningSoft = isLight
        ? AppColors.accentOrangeSoft
        : AppColors.darkAccentOrangeSoft;

    // ── Semântica ────────────────────────────────────────────────────
    final error = isLight ? AppColors.errorNeutral : AppColors.darkErrorNeutral;
    final errorSoft = isLight
        ? AppColors.lightErrorSoft
        : AppColors.darkErrorSoft;
    final onError = isLight ? AppColors.softWhite : AppColors.brandBlack;

    // ── ColorScheme (papéis explícitos) ──────────────────────────────
    final scheme = ColorScheme(
      brightness: brightness,
      primary: action,
      onPrimary: onAction,
      primaryContainer: actionTint,
      onPrimaryContainer: textPrimary,
      secondary: textSecondary,
      onSecondary: isLight ? AppColors.softWhite : AppColors.brandBlack,
      secondaryContainer: surfaceSecondary,
      onSecondaryContainer: textPrimary,
      tertiary: warningText,
      onTertiary: isLight ? AppColors.softWhite : AppColors.brandBlack,
      tertiaryContainer: warningSoft,
      onTertiaryContainer: warningText,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: isLight
          ? AppColors.softWhite
          : AppColors.darkBackground,
      surfaceContainerLow: isLight ? AppColors.softWhite : surface,
      surfaceContainer: surfaceSecondary,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainerHighest: canvas,
      outline: border,
      outlineVariant: border,
      error: error,
      onError: onError,
      errorContainer: errorSoft,
      onErrorContainer: error,
      inverseSurface: textPrimary,
      onInverseSurface: isLight ? AppColors.softWhite : AppColors.brandBlack,
      // Sobre `inverseSurface` (snackbar): o oposto da ação do tema.
      inversePrimary: isLight ? AppColors.darkPrimary : AppColors.lightPrimary,
      shadow: Colors.transparent,
      // Scrim = preto oficial em ambos os temas (modalBarrierColor).
      scrim: AppColors.brandBlack,
      surfaceTint: Colors.transparent,
    );

    // ── Overlays de interação (neutros, paleta oficial) ──────────────
    final stateVeil = isLight ? AppColors.brandBlack : AppColors.softWhite;
    WidgetStateProperty<Color?> surfaceOverlay() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          if (states.contains(WidgetState.pressed)) {
            return stateVeil.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return stateVeil.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.hovered)) {
            return stateVeil.withValues(alpha: 0.04);
          }
          return null;
        });

    // Botão preenchido: o véu vai na direção OPOSTA ao preenchimento (clareia
    // o preto no claro, escurece o gelo no escuro) para o press ser visível.
    final filledVeil = AppColors.brandBlack;
    WidgetStateProperty<Color?> filledOverlay() =>
        WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return null;
          if (states.contains(WidgetState.pressed)) {
            return filledVeil.withValues(alpha: isLight ? 0.16 : 0.12);
          }
          if (states.contains(WidgetState.focused)) {
            return filledVeil.withValues(alpha: isLight ? 0.12 : 0.08);
          }
          if (states.contains(WidgetState.hovered)) {
            return filledVeil.withValues(alpha: isLight ? 0.08 : 0.04);
          }
          return null;
        });

    final outlinedSide = WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: separator);
      }
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: action, width: 1.5);
      }
      return BorderSide(color: AppColors.controlBorder);
    });

    // ── ThemeData ────────────────────────────────────────────────────
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.family,
      // Escala única do app: os 15 papéis do Material vêm da AppTypography
      // (sem isto, papéis como display* herdariam a escala padrão).
      textTheme: AppTypography.forScheme(scheme),
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      dividerColor: separator,
      disabledColor: textSecondary.withValues(alpha: 0.5),
      splashFactory: InkRipple.splashFactory,
      // Realce de toque discreto (estilo Apple): véu neutro, sem "ondas" fortes.
      splashColor: stateVeil.withValues(alpha: 0.05),
      highlightColor: stateVeil.withValues(alpha: 0.04),
      hoverColor: stateVeil.withValues(alpha: 0.04),
      focusColor: stateVeil.withValues(alpha: 0.08),
      visualDensity: VisualDensity.standard,
      extensions: [isLight ? AppStatusColors.light : AppStatusColors.dark],

      // Transições de página Apple em todas as plataformas: deslize
      // lateral com paralaxe e gesto de voltar pela borda.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),

      // Cursor e seleção de texto na cor de ação (antes herdavam um primary
      // sem contraste).
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: action,
        selectionColor: action.withValues(alpha: 0.22),
        selectionHandleColor: action,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: action,
        linearTrackColor: separator,
        circularTrackColor: Colors.transparent,
      ),

      // ── AppBar ─────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: AppSpacing.md,
        toolbarHeight: AppSizes.appBarHeight,
        // Título de página = token `headline` (24/w600) em toda a app.
        titleTextStyle: AppTypography.headline.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary, size: AppSizes.iconLg),
        actionsIconTheme: IconThemeData(
          color: textPrimary,
          size: AppSizes.iconMd,
        ),
      ),

      // ── Cartões ──────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: AppElevation.e0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: separator, width: 1),
        ),
      ),

      // ── Campos de formulário ────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        labelStyle: AppTypography.labelMedium.copyWith(color: textSecondary),
        // Rótulo flutuante na cor de ação (antes: branco, ilegível no claro).
        floatingLabelStyle: AppTypography.labelLarge.copyWith(color: action),
        hintStyle: AppTypography.bodyMedium.copyWith(color: textSecondary),
        // Texto auxiliar do campo = 12 (metadado). Nunca 11: a instrução
        // do campo é necessária para concluir a ação.
        helperStyle: AppTypography.bodySmall.copyWith(color: textSecondary),
        errorStyle: AppTypography.labelMedium.copyWith(color: error),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: action, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: error, width: 1.5),
        ),
      ),

      // ── Botões ───────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              minimumSize: const Size(0, AppSizes.controlHeight),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              textStyle: AppTypography.labelLarge,
            ).copyWith(
              animationDuration: AppDurations.fast,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return textPrimary.withValues(alpha: 0.12);
                }
                return action;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return textPrimary.withValues(alpha: 0.45);
                }
                return onAction;
              }),
              overlayColor: filledOverlay(),
              elevation: const WidgetStatePropertyAll(AppElevation.e0),
            ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              minimumSize: const Size(0, AppSizes.controlHeight),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              backgroundColor: surface,
              foregroundColor: action,
              elevation: AppElevation.e0,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              textStyle: AppTypography.labelLarge,
            ).copyWith(
              animationDuration: AppDurations.fast,
              side: WidgetStatePropertyAll(BorderSide(color: border)),
              overlayColor: surfaceOverlay(),
            ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSizes.controlHeight),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              foregroundColor: textPrimary,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              textStyle: AppTypography.labelLarge,
            ).copyWith(
              side: outlinedSide,
              animationDuration: AppDurations.fast,
              overlayColor: surfaceOverlay(),
            ),
      ),

      textButtonTheme: TextButtonThemeData(
        style:
            TextButton.styleFrom(
              minimumSize: const Size(0, AppSizes.controlHeight),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              foregroundColor: textPrimary,
              textStyle: AppTypography.labelLarge,
            ).copyWith(
              animationDuration: AppDurations.fast,
              overlayColor: surfaceOverlay(),
            ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          foregroundColor: textPrimary,
        ).copyWith(overlayColor: surfaceOverlay()),
      ),

      // ── Chips / badges ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSecondary,
        selectedColor: actionTint,
        disabledColor: textPrimary.withValues(alpha: 0.08),
        checkmarkColor: action,
        showCheckmark: false,
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
      ),

      // ── Navegação ────────────────────────────────────────────────────
      // Seleção = pílula neutra + ícone/rótulo em cor de ação. (Antes:
      // indicador creme com ícone BRANCO → sem contraste no claro.)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.navBarHeight,
        indicatorColor: actionTint,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppSizes.navIcon,
            color: selected ? action : textSecondary,
          );
        }),
        // Navegação = labelMedium (13/w500) - conforme especificação.
        // Ativo usa w600 para estado selecionado.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.navigationLabel(
            selected ? action : textSecondary,
            selected: selected,
          );
        }),
        labelPadding: const EdgeInsets.only(top: AppSpacing.micro),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: actionTint,
        indicatorShape: const StadiumBorder(),
        minWidth: 80,
        groupAlignment: -0.85,
        selectedIconTheme: IconThemeData(color: action, size: AppSizes.navIcon),
        selectedLabelTextStyle: AppTypography.navigationLabel(
          action,
          selected: true,
        ),
        unselectedIconTheme: IconThemeData(
          color: textSecondary,
          size: AppSizes.navIcon,
        ),
        unselectedLabelTextStyle: AppTypography.navigationLabel(textSecondary),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: action,
        unselectedLabelColor: textSecondary,
        indicatorColor: action,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: separator,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w400,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: action,
        foregroundColor: onAction,
        elevation: AppElevation.e2,
        highlightElevation: AppElevation.e3,
        hoverElevation: AppElevation.e2,
        focusElevation: AppElevation.e2,
        hoverColor: filledVeil.withValues(alpha: 0.08),
        focusColor: filledVeil.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        sizeConstraints: const BoxConstraints.tightFor(
          width: AppSizes.fabSize,
          height: AppSizes.fabSize,
        ),
      ),

      // ── Divisores e listas ───────────────────────────────────────────
      dividerTheme: DividerThemeData(color: separator, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.sm,
        iconColor: textSecondary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      // ── Diálogos, sheets e menus ─────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.e4,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: AppTypography.titleMedium.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: textSecondary,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceElevated,
        modalBarrierColor: AppColors.brandBlack.withValues(
          alpha: isLight ? 0.40 : 0.60,
        ),
        modalElevation: AppElevation.e3,
        elevation: AppElevation.e0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.e3,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: separator),
        ),
        position: PopupMenuPosition.under,
        textStyle: AppTypography.bodyMedium.copyWith(color: textPrimary),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: AppElevation.e3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        // Fundo = tinta invertida (preto no claro, gelo no escuro).
        backgroundColor: textPrimary,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: isLight ? AppColors.softWhite : AppColors.brandBlack,
        ),
        // Ação legível sobre o fundo invertido (terracota sobre gelo
        // 4.0:1; no escuro, terracota sobre preto 3.3:1 — não-texto ok).
        actionTextColor: isLight ? accent : AppColors.warningText,
        closeIconColor: isLight
            ? AppColors.softWhite.withValues(alpha: 0.7)
            : AppColors.brandBlack,
      ),

      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: surfaceElevated,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: border),
        ),
        textStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
      ),

      // ── Controlos ────────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, AppSizes.touchTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          ),
          overlayColor: surfaceOverlay(),
          animationDuration: AppDurations.fast,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onAction;
          return isLight ? AppColors.softWhite : textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return action;
          return border;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return action;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(onAction),
        side: BorderSide(color: textSecondary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xsAll),
      ),
    );
  }
}
