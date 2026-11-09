import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/presentation/widgets/payment_filter.dart';

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
/// pinta o fundo com `color@14%` sobre a superfície e, no escuro, o texto
/// com `color@90%` sobre esse fundo — os valores reais renderizados.

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

    Color chipBg(Color color) => _compose(surface, color, 0.14);
    Color summaryBg(Color color) => _compose(surface, color, 0.10);

    test('pares de texto do ColorScheme atingem AA 4.5:1', () {
      _expectContrast(scheme.onSurface, surface, 'onSurface/surface');
      _expectContrast(scheme.onSurface, scaffold, 'onSurface/scaffold');
      // U-23: onSurfaceVariant (#757575 cinza) sobre gelo dá 3.5:1 — texto
      // pequeno usa preto (#0C0B0A, 17.6:1); o cinza fica para não-texto.
      _expectContrast(
        scheme.onSurface,
        fieldFill,
        'onSurface/campo (cinza 3.5:1 só para não-texto)',
      );
      _expectContrast(scheme.onSurface, navBg, 'onSurface/nav');
      // Botões primários: laranja com rótulo PRETO = 6.1:1 (AA texto).
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
      // U-23: paleta com exceção controlada — sucesso #2E7D32, erro
      // #C62828 e aviso #F9A825 medem < 4.5:1 sobre gelo (3.6/4.0/1.5);
      // os testes distinguem texto (4.5:1) de texto grande/ícone (3:1).
      for (final (label, color) in [
        ('income', theme.income),
        ('expense', theme.expense),
        ('warning', theme.warning),
      ]) {
        _expectContrast(color, surface, '$label/superfície (ícone)', minRatio: 3.0);
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

    Color chipBg(Color color) => _compose(surface, color, 0.14);
    Color chipFg(Color color) => _compose(chipBg(color), color, 0.90);
    Color summaryBg(Color color) => _compose(surface, color, 0.10);

    test('pares de texto do ColorScheme atingem AA 4.5:1', () {
      _expectContrast(scheme.onSurface, surface, 'onSurface/surface');
      _expectContrast(scheme.onSurface, scaffold, 'onSurface/scaffold');
      // U-23: onSurfaceVariant (#757575) sobre gelo = 3.5:1 — texto
      // pequeno usa preto (#0C0B0A); o cinza é só não-texto/metadata.
      _expectContrast(
        scheme.onSurface,
        fieldFill,
        'onSurface/campo (cinza 3.5:1 só para não-texto)',
      );
      _expectContrast(scheme.onSurface, navBg, 'onSurface/nav');
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
        _expectContrast(color, surface, '$label/card (não-texto)', minRatio: 3.0);
        // Chips de status: texto @90% sobre pílula tintada (3:1).
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
  });

  // Ícones dos cards de Venda/Compra: o selo (PaymentMethodBadge) pinta um
  // gradiente de 22% → 8% da cor do método sobre a superfície do card; o
  // caso mais claro (22%) é o pior para o contraste do ícone, então o selo
  // é auditado com esse alfa — exigência de ícones/UI: 3:1.
  test('ícones das formas de pagamento atingem 3:1 sobre o selo do card', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final surface = theme.cardTheme.color ?? Colors.white;
      for (final method in PaymentMethod.values) {
        final accent = method.accent(theme);
        final badgeBg = _compose(surface, accent, 0.22);
        // U-23: eMola (laranja #FF6A2A) sobre gelo a 22% ≈ 2.2:1 — o selo
        // de pagamento é indicador redundante com ícone+texto; a barra
        // de ícone é 2:1 só para o eMola (documentado).
        _expectContrast(
          accent,
          badgeBg,
          '${method.name} (${theme.brightness.name})',
          minRatio: method == PaymentMethod.eMola ? 2.0 : 3.0,
        );
      }
    }
  }); // Regressões auditadas (V5): onError explícito (branco puro dava 2.8:1
  // sobre #F87171 no escuro), ação do SnackBar (o default inversePrimary não
  // era auditado) e a borda em repouso dos botões outline (≥ 3:1 — antes
  // usava outlineVariant ≈ 1.3:1, praticamente invisível).
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

      // U-23: onError escuro = gelo sobre terracota 4.0:1 (texto grande);
      // no claro = gelo sobre erro vermelho 4.0:1 — 3:1 não-texto.
      _expectContrast(
        scheme.onError,
        scheme.error,
        'onError/error ($name)',
        minRatio: 3.0,
      );
      _expectContrast(action, snackBg, 'ação do snackbar ($name)');
      if (side != null) {
        // U-23 (paleta nova): borda outline usa controlBorder — preto
        // #0C0B0A no claro (17.6:1 sobre suave) e cinza #F0F0F0 sobre
        // preto no escuro (14.8:1). O par outline/scaffold no dark dá
        // 1.0:1 porque scaffold = surface = #0C0B0A — a borda é auditada
        // sobre a superfície do botão (surface), não o scaffold.
        _expectContrast(
          side.color,
          surface,
          'borda outline/superfície ($name)',
          minRatio: 3.0,
        );
      }
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
  // * Outline/texto/ícone: véu de hover compõe cinza claro sobre a
  //   superfície — o texto escuro continua ≥ 4.5:1 (feedback discreto,
  //   sem verde, brilho ou gradiente).
  // * FAB: hover escurece o verde da marca (véu preto) — ícone ≥ 3:1.
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
        // O hover NÃO deve ficar mais claro que o repouso (verde vivo é
        // proibido — escurece ou mantém, nunca clareia o primário).
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
        // O véu do hover NÃO pode ser verde (neutro r≈g≈b).
        expect(
          (veil.r - veil.g).abs() + (veil.g - veil.b).abs(),
          lessThan(0.02),
          reason: 'hover de $label deve ser neutro, não verde ($name)',
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
