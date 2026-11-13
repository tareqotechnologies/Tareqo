import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/theme/app_tokens.dart';

/// Auditoria de contraste dos temas claro e escuro (WCAG 2.x).
///
/// Padrões exigidos (documentados — ver calibração no cabeçalho de cada
/// grupo):
/// - texto de corpo (≥ 13px) sobre superfícies: **4.5:1** (AA);
/// - texto grande (headlines ≥ 24px) e ícones/UI: **3:1**;
/// - chips de status (rótulo curto e em negrito sobre pílula colorida):
/// **3:1** — o chip é um indicador semântico decorativo; a informação é
/// redundante com ícone/texto adjacente (padrão comum em design systems,
/// equivalente à barra de não-texto do WCAG).
///
/// Os pares usam as cores EFETIVAS (após composição alfa): o [StatusChip]
/// pinta o fundo com `color@12%` sobre a superfície e o texto com a cor
/// sólida — os valores reais renderizados.

double _luminance(Color color) {
  double linear(double v) =>
      v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(color.r) +
      0.7152 * linear(color.g) +
      0.0722 * linear(color.b);
}

double _contrast(Color a, Color b) {
  final lighter = math.max(_luminance(a), _luminance(b));
  final darker = math.min(_luminance(a), _luminance(b));
  return (lighter + 0.05) / (darker + 0.05);
}

/// Composição alfa sobre fundo opaco (equivale a `fg.withValues(alpha: t)`
/// pintado sobre `bg`).
Color _compose(Color bg, Color fg, double alpha) => Color.lerp(bg, fg, alpha)!;

void _expectContrast(
  Color fg,
  Color bg,
  String label, {
  double minRatio = 4.5,
}) {
  final ratio = _contrast(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(minRatio),
    reason: '$label: contraste ${ratio.toStringAsFixed(2)} < $minRatio',
  );
}

void main() {
  group('tema claro', () {
    final theme = AppTheme.light;
    final scheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? Colors.white;
    final scaffold = theme.scaffoldBackgroundColor;
    final fieldFill = theme.inputDecorationTheme.fillColor ?? surface;
    final navBg = theme.navigationBarTheme.backgroundColor ?? surface;
    final snackBg =
        theme.snackBarTheme.backgroundColor ?? const Color(0xFF1C2623);
    final snackFg = theme.snackBarTheme.contentTextStyle?.color ?? Colors.white;

    Color chipBg(Color color) => _compose(surface, color, 0.12);
    Color summaryBg(Color color) => _compose(surface, color, 0.10);

    test('pares de texto do ColorScheme atingem AA 4.5:1', () {
      _expectContrast(scheme.onSurface, surface, 'onSurface/surface');
      _expectContrast(scheme.onSurface, scaffold, 'onSurface/scaffold');
      // Texto primário Preto 100 sobre o campo Branco 90 = 18.4:1.
      _expectContrast(scheme.onSurface, fieldFill, 'onSurface/campo');
      _expectContrast(scheme.onSurface, navBg, 'onSurface/nav');
      // Botões primários: tinta Preto 100 com rótulo Branco 100 = 19:1.
      _expectContrast(scheme.onPrimary, scheme.primary, 'onPrimary/primary');
      _expectContrast(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
        'onPrimaryContainer/primaryContainer',
      );
      _expectContrast(
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
        'onSecondaryContainer/secondaryContainer',
      );
      _expectContrast(snackFg, snackBg, 'snackbar');
    });

    test('alertas semânticos (paleta oficial) sobre superfícies', () {
      // Sem laranja: sucesso #2E7D32 (5.1:1 sobre branco), erro #C62828
      // (5.6:1) e aviso na tinta Preto 70 (7.3:1) — todos legíveis como
      // texto AA; a pílula tintada é auditada a 3:1 (indicador semântico
      // redundante com ícone e rótulo).
      for (final (label, color) in [
        ('income', theme.income),
        ('expense', theme.expense),
        ('warning', theme.warning),
      ]) {
        _expectContrast(
          color,
          surface,
          '$label/superfície (texto AA)',
          minRatio: 4.5,
        );
        _expectContrast(color, chipBg(color), '$label/chip', minRatio: 3.0);
        // Card de resumo do fiado: fundo com 10% da cor (texto grande, 3:1).
        _expectContrast(
          color,
          summaryBg(color),
          '$label/resumo (texto grande)',
          minRatio: 3.0,
        );
        // Ícone sobre o fundo tintado do chip (3:1).
        _expectContrast(color, chipBg(color), '$label/ícone', minRatio: 3.0);
      }
    });
  });

  group('tema escuro', () {
    final theme = AppTheme.dark;
    final scheme = theme.colorScheme;
    final surface = theme.cardTheme.color ?? const Color(0xFF171C1B);
    final scaffold = theme.scaffoldBackgroundColor;
    final fieldFill = theme.inputDecorationTheme.fillColor ?? surface;
    final navBg = theme.navigationBarTheme.backgroundColor ?? surface;
    final snackBg =
        theme.snackBarTheme.backgroundColor ?? const Color(0xFFEDF1EF);
    final snackFg =
        theme.snackBarTheme.contentTextStyle?.color ?? const Color(0xFF101413);

    Color chipBg(Color color) => _compose(surface, color, 0.12);
    Color chipFg(Color color) => color;
    Color summaryBg(Color color) => _compose(surface, color, 0.10);

    test('pares de texto do ColorScheme atingem AA 4.5:1', () {
      _expectContrast(scheme.onSurface, surface, 'onSurface/surface');
      _expectContrast(scheme.onSurface, scaffold, 'onSurface/scaffold');
      // Texto primário Branco 100 sobre o campo Preto 90 = 15.6:1.
      _expectContrast(scheme.onSurface, fieldFill, 'onSurface/campo');
      _expectContrast(scheme.onSurface, navBg, 'onSurface/nav');
      // Botão primário escuro: Branco 100 com rótulo Preto 100 = 19:1.
      _expectContrast(scheme.onPrimary, scheme.primary, 'onPrimary/primary');
      _expectContrast(
        scheme.onPrimaryContainer,
        scheme.primaryContainer,
        'onPrimaryContainer/primaryContainer',
      );
      _expectContrast(
        scheme.onSecondaryContainer,
        scheme.secondaryContainer,
        'onSecondaryContainer/secondaryContainer',
      );
      _expectContrast(snackFg, snackBg, 'snackbar');
    });

    test('alertas semânticos sobre os cards escuros (3:1 não-texto)', () {
      for (final (label, color) in [
        ('income', theme.income),
        ('expense', theme.expense),
        ('warning', theme.warning),
      ]) {
        // Ícone/valor sobre o card escuro — 3:1 (WCAG não-texto).
        _expectContrast(
          color,
          surface,
          '$label/card (não-texto)',
          minRatio: 3.0,
        );
        // Chips de status: a cor sólida sobre a pílula tintada (3:1).
        _expectContrast(
          chipFg(color),
          chipBg(color),
          '$label/chip',
          minRatio: 3.0,
        );
        // Resumo do fiado (texto grande, 3:1).
        _expectContrast(
          color,
          summaryBg(color),
          '$label/resumo (texto grande)',
          minRatio: 3.0,
        );
        // Ícone sobre o fundo tintado (3:1).
        _expectContrast(color, chipBg(color), '$label/ícone', minRatio: 3.0);
      }
    });

    test('valores semânticos como TEXTO no escuro atingem AA 4.5:1', () {
      // Os tons base de alerta (#2E7D32/#C62828) medem 3.84/3.50 sobre o
      // preto — servem para preenchimentos, não para valores monetários em
      // texto pequeno. `theme.income`/`theme.expense` no escuro devolvem os
      // tints de texto (#66BB6A/#FF8A80) e o aviso usa Branco 60 (8.8:1).
      for (final (label, color) in [
        ('income', theme.income),
        ('expense', theme.expense),
        ('warning', theme.warning),
      ]) {
        _expectContrast(color, surface, '$label/superfície (texto AA)');
        _expectContrast(color, scaffold, '$label/scaffold (texto AA)');
        _expectContrast(color, chipBg(color), '$label/chip (texto AA)');
        _expectContrast(color, summaryBg(color), '$label/resumo (texto AA)');
      }
    });
  });

  // Selo da forma de pagamento nos cards de Compra: círculo TINTA sólido
  // com ícone Branco 100 — mesmo idioma IconTone do feed da Home, do painel
  // de Vendas e do menu (a cor do método NÃO entra no selo). Requisito de
  // ícones/UI: 3:1 sobre o fundo.
  test('ícone do selo de pagamento atinge 3:1 sobre a tinta', () {
    final background = IconTone.darkBackground(AppColors.black100);
    final foreground = IconTone.lightForeground(AppColors.black100);
    _expectContrast(
      foreground,
      background,
      'selo de pagamento (tinta sólida)',
      minRatio: 3.0,
    );
  }); // Regressões auditadas (V5): onError explícito (branco sobre o
  // vermelho #C62828 = 5.6:1 no claro; Preto 100 sobre #FF8A80 = 9.3:1 no
  // escuro), ação do SnackBar (Branco 100 sobre Preto 90 = 15.6:1) e a
  // borda em repouso dos botões outline (3:1 — antes usava outlineVariant
  // ≈ 1.3:1, praticamente invisível).
  test('onError, ação do SnackBar e bordas outline têm contraste', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      final name = theme.brightness.name;
      final surface = theme.cardTheme.color ?? scheme.surface;
      final snackBg =
          theme.snackBarTheme.backgroundColor ?? scheme.inverseSurface;
      final action =
          theme.snackBarTheme.actionTextColor ?? scheme.inversePrimary;
      final side = theme.outlinedButtonTheme.style?.side?.resolve(
        const <WidgetState>{},
      );

      // Preenchimento de erro: Branco 100 sobre #C62828 no claro e Preto
      // 100 sobre #FF8A80 no escuro — AA de texto nos dois temas.
      _expectContrast(scheme.onError, scheme.error, 'onError/error ($name)');
      _expectContrast(
        scheme.onErrorContainer,
        scheme.errorContainer,
        'onErrorContainer/errorContainer ($name)',
      );
      _expectContrast(action, snackBg, 'ação do snackbar ($name)');
      if (side != null) {
        // Borda outline = controlBorder (Preto 60 #667085) nos dois
        // temas: 4.4:1 sobre o canvas claro e 3.05:1 sobre o cartão
        // escuro. É auditada sobre a superfície do botão (surface).
        _expectContrast(
          side.color,
          surface,
          'borda outline/superfície ($name)',
          minRatio: 3.0,
        );
      }
    }
  });

  // Campos de formulário: fill Branco 90 no claro e Preto 90 no escuro;
  // rótulo/flutuante usam o texto primário, o hint o secundário e a
  // borda controlBorder (≥ 3:1). Os pares abaixo são os tokens efetivos
  // aplicados pelo InputDecorationTheme.
  test('campos: rótulo, hint, borda e erro atingem contraste', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      final name = theme.brightness.name;
      final fill = theme.inputDecorationTheme.fillColor ?? scheme.surface;
      final canvas = theme.scaffoldBackgroundColor;
      final label = theme.inputDecorationTheme.labelStyle?.color;
      final floating = theme.inputDecorationTheme.floatingLabelStyle?.color;
      final hint = theme.inputDecorationTheme.hintStyle?.color;
      final enabled = theme.inputDecorationTheme.enabledBorder;
      final borderColor = enabled is OutlineInputBorder
          ? enabled.borderSide.color
          : null;

      if (label != null) {
        _expectContrast(label, fill, 'rótulo/campo ($name)');
      }
      if (floating != null) {
        _expectContrast(floating, fill, 'rótulo flutuante/campo ($name)');
      }
      if (hint != null) {
        // `hintStyle` pode ter alfa: o contraste é medido na cor composta.
        final effective = _compose(fill, hint, hint.a);
        _expectContrast(effective, fill, 'hint/campo ($name)');
      }
      if (borderColor != null) {
        // WCAG 1.4.11 — limite do campo ≥ 3:1 sobre o fill e o canvas.
        _expectContrast(
          borderColor,
          fill,
          'borda do campo/fill ($name)',
          minRatio: 3.0,
        );
        _expectContrast(
          borderColor,
          canvas,
          'borda do campo/canvas ($name)',
          minRatio: 3.0,
        );
      }
      // Erro como texto no campo e na superfície (vermelho AA nos dois
      // temas: #C62828 no claro, #FF8A80 no escuro).
      _expectContrast(scheme.error, fill, 'erro/campo ($name)');
      _expectContrast(scheme.error, scheme.surface, 'erro/superfície ($name)');
    }
  });

  test('AppColors.of resolve a variante correta por brilho', () {
    expect(
      AppColors.of(Brightness.light, AppColors.income, AppColors.incomeLight),
      AppColors.incomeLight,
    );
    expect(
      AppColors.of(Brightness.dark, AppColors.income, AppColors.incomeLight),
      AppColors.income,
    );
    expect(
      AppColors.of(Brightness.light, AppColors.warning, AppColors.warningLight),
      AppColors.warningLight,
    );
    expect(
      AppColors.of(Brightness.dark, AppColors.expense, AppColors.expenseLight),
      AppColors.expense,
    );
  });

  // Estados de interação dos botões (V6 — hover sem verde):
  // * Filled/primário: hover ESCURECE o preenchimento (véu preto 8%) e o
  //   texto branco continua ≥ 4.5:1; desabilitado usa cinza neutro (sem
  //   verde) com contraste suficiente para comunicar o estado.
  // * Outline/texto/ícone: véu de hover compõe um cinza neutro sobre a
  //   superfície — o texto continua ≥ 4.5:1 (feedback discreto, sem cor,
  //   brilho ou gradiente).
  // * FAB: hover escurece a tinta (véu preto) — ícone ≥ 3:1.
  test('estados de hover/pressed/disabled dos botões têm contraste', () {
    Color compose(Color bg, Color fg, double alpha) =>
        Color.lerp(bg, fg, alpha)!;

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final scheme = theme.colorScheme;
      final name = theme.brightness.name;
      final surface = theme.cardTheme.color ?? scheme.surface;

      // ── Primário (Filled): hover/pressed escurecem o fundo ──
      final filledStyle = theme.filledButtonTheme.style;
      final filledBg = filledStyle?.backgroundColor?.resolve(
        const <WidgetState>{},
      );
      final filledFg = filledStyle?.foregroundColor?.resolve(
        const <WidgetState>{},
      );
      final filledDisabledBg = filledStyle?.backgroundColor?.resolve(
        const <WidgetState>{WidgetState.disabled},
      );
      final filledDisabledFg = filledStyle?.foregroundColor?.resolve(
        const <WidgetState>{WidgetState.disabled},
      );
      final hoverVeil = filledStyle?.overlayColor?.resolve(const <WidgetState>{
        WidgetState.hovered,
      });
      if (filledBg != null &&
          filledFg != null &&
          hoverVeil != null &&
          hoverVeil.a > 0) {
        // Color.a já é 0.0–1.0 (sem divisão por 255).
        final hoveredBg = compose(filledBg, hoverVeil, hoverVeil.a);
        _expectContrast(filledFg, hoveredBg, 'primário hover ($name)');
        // O hover NÃO deve ficar mais claro que o repouso (a tinta
        // escurece ou mantém, nunca clareia o primário).
        expect(
          hoveredBg.computeLuminance(),
          lessThanOrEqualTo(filledBg.computeLuminance() + 0.001),
          reason: 'primário hover deve escurecer, não clarear ($name)',
        );
      }
      if (filledDisabledBg != null && filledDisabledFg != null) {
        // Cores translúcidas compõem sobre a SURFÁCIE (o que o usuário vê).
        // Disabled é isento de AA na WCAG — barra 2.5:1 para comunicar o
        // estado sem competir com ações ativas.
        final disabledBg = compose(
          surface,
          filledDisabledBg,
          filledDisabledBg.a,
        );
        final disabledFg = compose(
          disabledBg,
          filledDisabledFg,
          filledDisabledFg.a,
        );
        _expectContrast(
          disabledFg,
          disabledBg,
          'primário desabilitado ($name)',
          minRatio: 2.5,
        );
      }

      // ── Outline/texto/ícone: véu cinza sobre a superfície ──
      for (final (label, style) in [
        ('outline', theme.outlinedButtonTheme.style),
        ('texto', theme.textButtonTheme.style),
        ('ícone', theme.iconButtonTheme.style),
      ]) {
        final veil = style?.overlayColor?.resolve(const <WidgetState>{
          WidgetState.hovered,
        });
        if (veil == null || veil.a == 0) continue;
        final hoveredSurface = compose(surface, veil, veil.a);
        _expectContrast(
          scheme.onSurface,
          hoveredSurface,
          'texto sobre hover $label ($name)',
        );
        // O véu do hover NÃO pode ser uma cor semântica (verde/vermelho)
        // nem laranja: fica no neutro da tinta oficial. O Preto 100
        // #0A0E15 tem viés azul de 0.043 (Δrg 0.016 + Δgb 0.027), por
        // isso a barra é 0.06 em vez de 0.02 — qualquer tinta colorida
        // (laranja inclusive) fica bem acima.
        expect(
          (veil.r - veil.g).abs() + (veil.g - veil.b).abs(),
          lessThan(0.06),
          reason: 'hover de $label deve ser neutro, sem cor ($name)',
        );
      }

      // ── FAB: hover escurece o verde, ícone ≥ 3:1 ──
      final fabTheme = theme.floatingActionButtonTheme;
      if (fabTheme.hoverColor != null && fabTheme.backgroundColor != null) {
        final fabHoverBg = compose(
          fabTheme.backgroundColor!,
          fabTheme.hoverColor!,
          fabTheme.hoverColor!.a,
        );
        expect(
          fabHoverBg.computeLuminance(),
          lessThanOrEqualTo(
            fabTheme.backgroundColor!.computeLuminance() + 0.001,
          ),
          reason: 'FAB hover deve escurecer o verde, não clarear ($name)',
        );
        _expectContrast(
          fabTheme.foregroundColor!,
          fabHoverBg,
          'ícone do FAB em hover ($name)',
          minRatio: 3.0,
        );
      }
    }
  });
}
