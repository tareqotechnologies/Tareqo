import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/screens/admin/admin_thin_theme.dart';

void main() {
  // ── thinTextTheme (estático) ──────────────────────────────────────────────
  group('thinTextTheme', () {
    final base = ThemeData.light(useMaterial3: true).textTheme;
    final thin = AdminThin.thinTextTheme(base);

    test('títulos ficam leves (w400) e preservam o tamanho', () {
      expect(thin.titleLarge?.fontWeight, FontWeight.w400);
      expect(thin.titleLarge?.fontSize, base.titleLarge?.fontSize);
      expect(thin.titleMedium?.fontWeight, FontWeight.w400);
    });

    test('rótulos de ação baixam de w500 para w400', () {
      expect(thin.labelLarge?.fontWeight, FontWeight.w400);
      expect(thin.labelMedium?.fontWeight, FontWeight.w400);
      // titleSmall não tinha peso pesado — fica em 400 por definição.
      expect(thin.titleSmall?.fontWeight, FontWeight.w400);
    });

    test('corpo e captions ficam no peso leve 400 (legibilidade densa)', () {
      // O M3 default não define peso explícito no corpo — fn() fixa w400.
      expect(thin.bodyMedium?.fontWeight, FontWeight.w400);
      expect(thin.bodySmall?.fontWeight, FontWeight.w400);
      // labelSmall sem peso explícito no base cai no w400 do fn().
      expect(thin.labelSmall?.fontWeight, FontWeight.w400);
    });

    test('estilo ausente na base cai no TextStyle padrão (sem crash)', () {
      // Cobre o early-return `if (style == null) return const TextStyle()`.
      final empty = AdminThin.thinTextTheme(const TextTheme());
      expect(empty.titleLarge, isA<TextStyle>());
      expect(empty.titleLarge!.fontWeight, isNull);
    });
  });

  // ── AdminThin (widget) ────────────────────────────────────────────────────
  testWidgets('AdminThin deriva o tema fino para a subtree', (tester) async {
    late TextTheme insideTextTheme;
    late ThemeData insideTheme;

    // O appBar thin só é derivado quando o tema base define titleTextStyle
    // (como o tema real do app faz); sem base, copyWith não cria nada.
    const baseTitleStyle = TextStyle(fontSize: 22, fontWeight: FontWeight.w600);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            toolbarHeight: 56,
            titleTextStyle: baseTitleStyle,
          ),
        ),
        home: AdminThin(
          child: Builder(
            builder: (context) {
              insideTheme = Theme.of(context);
              insideTextTheme = insideTheme.textTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    // Tipografia: títulos leves dentro do painel.
    expect(insideTextTheme.titleLarge?.fontWeight, FontWeight.w400);

    // AppBar do painel: 52dp de altura e título derivado do titleLarge.
    expect(insideTheme.appBarTheme.toolbarHeight, 52);
    expect(insideTheme.appBarTheme.titleTextStyle?.fontSize, 22);
    expect(insideTheme.appBarTheme.titleTextStyle?.fontWeight, FontWeight.w400);
    expect(insideTheme.appBarTheme.titleTextStyle?.letterSpacing, -0.2);

    // Inputs e chips com rótulos do tema (labelMedium, 12dp).
    expect(insideTheme.inputDecorationTheme.labelStyle?.fontSize, 12);
    expect(insideTheme.chipTheme.labelStyle?.fontWeight, FontWeight.w500);

    // SnackBar thin mantém a cor herdada do tema base.
    expect(insideTheme.snackBarTheme.contentTextStyle?.fontSize, 14);
  });

  // ── AdminSectionLabel ─────────────────────────────────────────────────────
  testWidgets('AdminSectionLabel renderiza uppercase com tracking', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdminSectionLabel(label: 'tenants ativos')),
    );

    final text = tester.widget<Text>(find.text('TENANTS ATIVOS'));
    expect(text.style?.letterSpacing, 0.8);
    expect(text.style?.fontWeight, FontWeight.w400);
  });

  // ── AdminStatValue ────────────────────────────────────────────────────────
  testWidgets('AdminStatValue usa headline leve com dígitos tabulares', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminStatValue(value: '128', label: 'Lojas ativas'),
      ),
    );

    final value = tester.widget<Text>(find.text('128'));
    expect(value.style?.fontWeight, FontWeight.w400);
    expect(value.style?.letterSpacing, -0.4);
    expect(
      value.style?.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    // Sem cor explícita: onSurface.
    final scheme = Theme.of(
      tester.element(find.text('128')),
      // ignore: use_build_context_synchronously
    ).colorScheme;
    expect(value.style?.color, scheme.onSurface);

    final label = tester.widget<Text>(find.text('Lojas ativas'));
    expect(label.maxLines, 1);
    expect(label.overflow, TextOverflow.ellipsis);
  });

  testWidgets('AdminStatValue aplica cor de destaque quando fornecida', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminStatValue(
          value: '12',
          label: 'Pendentes',
          color: Colors.red,
        ),
      ),
    );

    final value = tester.widget<Text>(find.text('12'));
    expect(value.style?.color, Colors.red);
  });
}
