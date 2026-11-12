import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

// Re-exporta a paleta semântica: mantém `AppColors`, `AppColorsTheme` e
// `AppStatusColors` acessíveis para quem importa apenas `app_theme.dart`.
export 'app_colors.dart';

/// Tema central TAREQO — Material 3 sobre a escala "Shades of gray" (2026).
///
/// Escala neutra de 10 passos (Preto 100→60 / Branco 100→60), sem
/// nenhum laranja. O acento é a própria tinta: Preto 100 no claro e
/// Branco 100 no escuro, reservados a CTA primário, foco, selecção e
/// marca. A linguagem é minimalista: canvas em camada, cartões brancos
/// sobre canvas cinza (claro), superfícies Preto 90/80 (escuro), sombras
/// neutras difusas, campos preenchidos e foco a acender a borda na tinta.
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
/// * `primary` = Preto 100 no claro, Branco 100 no escuro (19:1).
/// * `primaryContainer` = tinta em véu sobre a superfície.
/// * `secondary` = texto secundário AA; `outline` = borda não-texto.
///
/// Contraste auditado (WCAG): texto de corpo ≥ 4.5:1 sobre as superfícies;
/// ícones/foco usam a tinta (19:1 no claro, 15.6:1 no escuro).
abstract final class AppTheme {
  /// Tema claro — canvas Branco 90, cartões Branco 100, tinta Preto 100.
  static final ThemeData light = _base(Brightness.light);

  /// Tema escuro — canvas Preto 100, cartões Preto 90, elevadas Preto 80.
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
    // Divisor Apple: Branco 80 no claro; Preto 70 a 55% no escuro (Preto
    // 80 puro ficaria pesado sobre os cartões Preto 90).
    final separator = isLight
        ? AppColors.lightDivider
        : AppColors.black70.withValues(alpha: 0.55);
    // Borda de campo: Preto 60 nos dois temas. No claro mede 4.4:1 sobre o
    // fill/canvas Branco 90; no escuro 3.05:1 sobre Preto 90 (WCAG 1.4.11
    // exige >=3:1). A tinta ficaria pesada para a linguagem minimalista.
    final fieldBorder = AppColors.controlBorder;

    // ── Ação / Primária ──────────────────────────────────────────────
    // `action` = tinta (Preto 100 no claro, Branco 100 no escuro).
    // `onAction` = Branco 100 / Preto 100 (19:1).
    final action = isLight ? AppColors.lightPrimary : AppColors.darkPrimary;
    final onAction = isLight
        ? AppColors.lightOnPrimary
        : AppColors.darkOnPrimary;
    // Acento de TEXTO/ícone: a mesma tinta (19:1 no claro; branco sobre
    // Preto 90 no escuro) — sem laranja.
    final actionText = isLight
        ? AppColors.lightActionText
        : AppColors.darkAction;
    // Véu da tinta sobre a superfície: 7% no claro, 12% no escuro.
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
    // Erro AA nos dois temas: #C62828 no claro (5.4:1) e #FF8A80 no
    // escuro (7.5:1 sobre Gluon).
    final error = isLight ? AppColors.errorNeutral : AppColors.darkErrorNeutral;
    final errorSoft = isLight
        ? AppColors.lightErrorSoft
        : AppColors.darkErrorSoft;
    // Rótulo sobre o preenchimento de erro: Snow no claro, Void no escuro.
    final onError = isLight ? AppColors.snow : AppColors.darkVoid;

    // ── ColorScheme (papéis explícitos) ──────────────────────────────
    final scheme = ColorScheme(
      brightness: brightness,
      primary: action,
      onPrimary: onAction,
      primaryContainer: actionTint,
      onPrimaryContainer: textPrimary,
      secondary: textSecondary,
      onSecondary: isLight ? AppColors.snow : AppColors.darkVoid,
      secondaryContainer: surfaceSecondary,
      onSecondaryContainer: textPrimary,
      tertiary: warningText,
      onTertiary: isLight ? AppColors.snow : AppColors.darkVoid,
      tertiaryContainer: warningSoft,
      onTertiaryContainer: warningText,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: isLight
          ? AppColors.snow
          : AppColors.darkBackground,
      surfaceContainerLow: isLight ? AppColors.snow : surface,
      // Zonas agrupadas: SnowMist no claro, Slate no escuro.
      surfaceContainer: surfaceSecondary,
      surfaceContainerHigh: surfaceElevated,
      surfaceContainerHighest: surfaceSecondary,
      // Outline = borda não-texto AA (Dusty); outlineVariant = hairline.
      outline: AppColors.controlBorder,
      outlineVariant: isLight
          ? AppColors.lightBorder
          : AppColors.black70.withValues(alpha: 0.6),
      error: error,
      onError: onError,
      // `errorSoft` (#C62828) nos dois temas; o rótulo é Snow.
      errorContainer: errorSoft,
      onErrorContainer: AppColors.snow,
      inverseSurface: textPrimary,
      onInverseSurface: isLight ? AppColors.snow : AppColors.darkVoid,
      // Sobre `inverseSurface` (snackbar): o oposto da ação do tema.
      inversePrimary: isLight ? AppColors.darkPrimary : AppColors.lightPrimary,
      // Preto 100: as sombras premium (PremiumDecor) finalmente visíveis.
      shadow: AppColors.darkVoid,
      // Scrim = Void em ambos os temas (modalBarrierColor).
      scrim: AppColors.darkVoid,
      surfaceTint: Colors.transparent,
    );

    // ── Overlays de interação (neutros, paleta oficial) ──────────────
    final stateVeil = isLight ? AppColors.darkVoid : AppColors.snow;
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

    // Botão preenchido: o véu escurece a tinta no press/hover (o rótulo Void
    // mantém contraste AA; escurecer também lê como "afundar").
    final filledVeil = AppColors.darkVoid;
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
        return BorderSide(color: actionText, width: 2);
      }
      // Contorno não-texto AA: Dusty nos dois temas (3.5:1 no claro,
      // 4.8:1 sobre Gluon no escuro).
      return const BorderSide(color: AppColors.controlBorder);
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

      // Cursor e seleção de texto no acento AA (tinta no claro, tinta no
      // escuro) — a tinta pura mede 2.85:1 sobre Snow.
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: actionText,
        selectionColor: actionText.withValues(alpha: 0.22),
        selectionHandleColor: actionText,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: actionText,
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
      // Linguagem Apple: campo preenchido (SnowMist/Slate), sem contorno
      // pesado; o foco acende a borda no acento AA com 2 px.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Campo preenchido: Branco 90 no claro; no escuro o próprio cartão
        // (Preto 90) — a borda Preto 60 desenha o limite (>=3:1 nos dois).
        fillColor: isLight ? surfaceSecondary : surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        labelStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
        floatingLabelStyle: AppTypography.labelLarge.copyWith(
          color: textPrimary,
        ),
        // Hint: texto secundário AA nos dois temas (lê como dica, nunca
        // como valor).
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isLight ? AppColors.black70 : AppColors.white60,
        ),
        // Texto auxiliar do campo = 12 (metadado). Nunca 11.
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
          borderSide: BorderSide(color: actionText, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: error, width: 2),
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
              foregroundColor: actionText,
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
        // Seleccionado = véu neutro da tinta (o acento fica no CTA/foco).
        selectedColor: textPrimary.withValues(alpha: 0.06),
        disabledColor: textPrimary.withValues(alpha: 0.08),
        checkmarkColor: actionText,
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
            color: selected ? actionText : textSecondary,
          );
        }),
        // Navegação = labelMedium (13/w500) - conforme especificação.
        // Ativo usa w600 para estado selecionado.
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          // No escuro o rótulo ativo usa texto primário (Snow); no claro
          // usa o acento AA (tinta). O estado continua no ícone e no
          // indicador tintado.
          return AppTypography.navigationLabel(
            selected ? (isLight ? actionText : textPrimary) : textSecondary,
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
        selectedIconTheme: IconThemeData(
          color: actionText,
          size: AppSizes.navIcon,
        ),
        selectedLabelTextStyle: AppTypography.navigationLabel(
          isLight ? actionText : textPrimary,
          selected: true,
        ),
        unselectedIconTheme: IconThemeData(
          color: textSecondary,
          size: AppSizes.navIcon,
        ),
        unselectedLabelTextStyle: AppTypography.navigationLabel(textSecondary),
      ),

      tabBarTheme: TabBarThemeData(
        // Texto ativo: tinta no claro (tinta mede 2.85:1); no escuro o
        // rótulo usa texto primário e a tinta fica no indicador.
        labelColor: isLight ? actionText : textPrimary,
        unselectedLabelColor: textSecondary,
        indicatorColor: actionText,
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
        shadowColor: scheme.shadow,
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
        modalBarrierColor: AppColors.darkVoid.withValues(
          alpha: isLight ? 0.45 : 0.65,
        ),
        modalElevation: AppElevation.e4,
        elevation: AppElevation.e0,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shadowColor: scheme.shadow,
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
        // Fundo = tinta elevada (Preto 90) nos dois temas: barra escura e
        // silenciosa; a ação usa Branco 100 (15:1) com sublinhado de foco —
        // sem qualquer laranja.
        backgroundColor: AppColors.black90,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.white100,
        ),
        actionTextColor: AppColors.white100,
        closeIconColor: AppColors.white100.withValues(alpha: 0.8),
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
          // Pílula segmentada minimalista: repouso em superfície com
          // hairline Preto 60; seleccionado preenchido de tinta com rótulo
          // inverso (19:1) — o acento não se repete em cada controlo.
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (selected) return textPrimary;
            return isLight ? AppColors.white100 : surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            if (selected) return isLight ? AppColors.white100 : canvas;
            return textPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return BorderSide(
              color: selected ? textPrimary : AppColors.controlBorder,
            );
          }),
          overlayColor: surfaceOverlay(),
          animationDuration: AppDurations.fast,
          textStyle: WidgetStatePropertyAll(AppTypography.labelLarge),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onAction;
          return isLight ? AppColors.white100 : textSecondary;
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
