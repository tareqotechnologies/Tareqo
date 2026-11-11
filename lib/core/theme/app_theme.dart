import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

// Re-exporta a paleta semântica: mantém `AppColors`, `AppColorsTheme` e
// `AppStatusColors` acessíveis para quem importa apenas `app_theme.dart`.
export 'app_colors.dart';

/// Tema central TAREQO — Material 3 sobre a paleta Outfit (guia em anexo).
///
/// Cinco cores sólidas: azul `#0067FF` (ação, foco, seleção), cinza médio
/// `#6E7174` (texto secundário claro), cinza `#E7E5E5` (campos e
/// divisores), suave `#F9F9F9` (canvas claro) e tinta `#232323`
/// (tinta e canvas escuro). O botão primário é azul com rótulo branco
/// suave. A pílula selecionada é preenchida de tinta no claro e de suave
/// no escuro, com contorno azul no estado em repouso.
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
/// * `primary` = azul `#0067FF`. `onPrimary` = suave `#F9F9F9` (4.55:1, AA).
/// * `primaryContainer` = o mesmo azul em véu sobre a superfície.
///   `errorContainer` guarda o alerta de erro.
///
/// Contraste auditado (WCAG): texto de corpo ≥ 4.5:1 sobre as superfícies.
/// Suave sobre azul passa AA de texto; azul sobre suave também (4.55:1).
abstract final class AppTheme {
  /// Tema claro — canvas #F9F9F9, campos #E7E5E5, tinta #232323, ação #0067FF.
  static final ThemeData light = _base(Brightness.light);

  /// Tema escuro — canvas #232323, texto #F9F9F9, ação #0067FF.
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
    // Borda de campo: `border` (cinza de superfície no claro) sumiria dentro
    // do próprio fill `#E7E5E5`. O cinza médio mede 3.9:1 sobre o fill no
    // claro; no escuro `darkBorder` mede 3.2:1 sobre a tinta (WCAG 1.4.11).
    final fieldBorder = isLight ? AppColors.grayMid : AppColors.darkBorder;

    // ── Ação / Primária ──────────────────────────────────────────────
    // `action` = azul #0067FF nos dois temas. `onAction` = branco suave
    // sobre o azul (4.55:1).
    final action = isLight ? AppColors.lightPrimary : AppColors.darkPrimary;
    final onAction = isLight
        ? AppColors.lightOnPrimary
        : AppColors.darkOnPrimary;
    // Véu do azul sobre a superfície: 7% no claro, 12% no escuro.
    final actionTint = Color.alphaBlend(
      action.withValues(alpha: isLight ? 0.07 : 0.12),
      surface,
    );

    // ── Avisos ───────────────────────────────────────────────────────
    final warningText = isLight
        ? AppColors.warningText
        : AppColors.darkWarningText;
    final warningSoft = isLight
        ? AppColors.accentBlueSoft
        : AppColors.darkAccentBlueSoft;

    // ── Semântica ────────────────────────────────────────────────────
    // No claro o erro é tinta sobre canvas suave; no escuro é o inverso
    // (suave sobre tinta). Antes o papel `error` valia `#232323` nos dois
    // temas e sumia no canvas escuro (1:1).
    final error = isLight ? AppColors.errorNeutral : AppColors.darkErrorNeutral;
    final errorSoft = isLight
        ? AppColors.lightErrorSoft
        : AppColors.darkErrorSoft;
    // Rótulo sobre o preenchimento de erro: suave sobre tinta no claro,
    // tinta sobre suave no escuro.
    final onError = isLight ? AppColors.softWhite : AppColors.brandInk;

    // ── ColorScheme (papéis explícitos) ──────────────────────────────
    final scheme = ColorScheme(
      brightness: brightness,
      primary: action,
      onPrimary: onAction,
      primaryContainer: actionTint,
      onPrimaryContainer: textPrimary,
      secondary: textSecondary,
      onSecondary: isLight ? AppColors.softWhite : AppColors.brandInk,
      secondaryContainer: surfaceSecondary,
      onSecondaryContainer: textPrimary,
      tertiary: warningText,
      onTertiary: isLight ? AppColors.softWhite : AppColors.brandInk,
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
      // `errorSoft` é a tinta oficial: o rótulo sobre ela é suave nos dois
      // temas (no escuro `error` é suave — texto sobre texto sumiria).
      errorContainer: errorSoft,
      onErrorContainer: AppColors.softWhite,
      inverseSurface: textPrimary,
      onInverseSurface: isLight ? AppColors.softWhite : AppColors.brandInk,
      // Sobre `inverseSurface` (snackbar): o oposto da ação do tema.
      inversePrimary: isLight ? AppColors.darkPrimary : AppColors.lightPrimary,
      shadow: Colors.transparent,
      // Scrim = preto oficial em ambos os temas (modalBarrierColor).
      scrim: AppColors.brandInk,
      surfaceTint: Colors.transparent,
    );

    // ── Overlays de interação (neutros, paleta oficial) ──────────────
    final stateVeil = isLight ? AppColors.brandInk : AppColors.softWhite;
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
    final filledVeil = AppColors.brandInk;
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
      // Contorno forte da paleta: preto no claro, suave no escuro (o preto
      // sobre canvas preto daria 1:1 — borda invisível).
      return BorderSide(
        color: isLight ? AppColors.controlBorder : AppColors.darkBorderStrong,
      );
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
        // Título de página = token `headline` (24/Medium) em toda a app.
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
        // Rótulo: tinta/gelo. O cinza médio sobre o fill `#E7E5E5` media
        // 3.91:1 (reprovava AA de texto pequeno) e o azul flutuante 3.82:1.
        labelStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
        floatingLabelStyle: AppTypography.labelLarge.copyWith(
          color: textPrimary,
        ),
        // Hint: tinta a 72% no claro (5.6:1 sobre o fill — ainda lê como
        // dica, não como valor) e o texto secundário no escuro (12.5:1).
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isLight
              ? AppColors.brandInk.withValues(alpha: 0.72)
              : textSecondary,
        ),
        // Texto auxiliar do campo = 12 (metadado). Nunca 11: a instrução
        // do campo é necessária para concluir a ação.
        helperStyle: AppTypography.bodySmall.copyWith(color: textSecondary),
        errorStyle: AppTypography.labelMedium.copyWith(color: error),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: fieldBorder),
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
          // Azul sobre a tinta mede 3.28:1 — o rótulo ativo usa texto
          // primário no escuro; o estado continua no ícone azul e no
          // indicador tintado.
          return AppTypography.navigationLabel(
            selected ? (isLight ? action : textPrimary) : textSecondary,
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
          isLight ? action : textPrimary,
          selected: true,
        ),
        unselectedIconTheme: IconThemeData(
          color: textSecondary,
          size: AppSizes.navIcon,
        ),
        unselectedLabelTextStyle: AppTypography.navigationLabel(textSecondary),
      ),

      tabBarTheme: TabBarThemeData(
        // Texto ativo: azul no claro (4.55:1); no escuro o azul só serve
        // para o indicador (não-texto) — o rótulo usa o texto primário.
        labelColor: isLight ? action : textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: action,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: separator,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w500,
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
        modalBarrierColor: AppColors.brandInk.withValues(
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
        // Fundo = azul da marca (feedback de ação) nos dois temas.
        backgroundColor: action,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: onAction,
        ),
        // Ação e fecho = branco suave sobre o azul (4.55:1, AA texto).
        actionTextColor: onAction,
        closeIconColor: onAction.withValues(alpha: 0.7),
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
          // Pílula do anexo: repouso com contorno azul; selecionado
          // preenchido (preto no claro, suave no escuro).
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (selected) {
              return isLight ? AppColors.brandInk : AppColors.softWhite;
            }
            return isLight ? AppColors.softWhite : AppColors.brandInk;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (selected) {
              return isLight ? AppColors.softWhite : AppColors.brandInk;
            }
            return isLight ? AppColors.brandInk : AppColors.softWhite;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (selected) {
              return BorderSide(
                color: isLight ? AppColors.brandInk : AppColors.softWhite,
              );
            }
            return const BorderSide(color: AppColors.brandBlue, width: 1.5);
          }),
          overlayColor: surfaceOverlay(),
          animationDuration: AppDurations.fast,
          textStyle: WidgetStatePropertyAll(AppTypography.labelLarge),
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
