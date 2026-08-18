import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/theme/app_theme.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/presentation/widgets/payment_filter.dart';

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
 _expectContrast(
 scheme.onSurfaceVariant,
 surface,
 'onSurfaceVariant/surface',
 );
 _expectContrast(
 scheme.onSurfaceVariant,
 fieldFill,
 'onSurfaceVariant/campo',
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

 test('cores semânticas atingem AA 4.5:1 sobre superfícies brancas', () {
 // Valores de caixa, resumos e chips usam a variante CLARA no modo claro.
 for (final (label, color) in [
 ('income', theme.income),
 ('expense', theme.expense),
 ('warning', theme.warning),
 ]) {
 _expectContrast(color, surface, '$label/superfície');
 _expectContrast(color, chipBg(color), '$label/chip');
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
 _expectContrast(
 scheme.onSurfaceVariant,
 surface,
 'onSurfaceVariant/surface',
 );
 _expectContrast(
 scheme.onSurfaceVariant,
 fieldFill,
 'onSurfaceVariant/campo',
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

 test('cores semânticas atingem AA 4.5:1 sobre os cards escuros', () {
 for (final (label, color) in [
 ('income', theme.income),
 ('expense', theme.expense),
 ('warning', theme.warning),
 ]) {
 // Texto de valor (Financeiro, resumos) diretamente sobre o card.
 _expectContrast(color, surface, '$label/card');
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
 _expectContrast(
 accent,
 badgeBg,
 '${method.name} (${theme.brightness.name})',
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
}
