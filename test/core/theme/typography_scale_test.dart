import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/theme/app_typography.dart';
import 'package:tareqo/presentation/screens/admin/admin_thin_theme.dart';

/// **Especificação executável da tipografia do TAREQO.**
///
/// Trava a escala global (tamanho / entrelinha / peso / tracking), a família
/// Inter, o `tabularFigures` dos valores financeiros e o mapeamento dos 15
/// papéis do [TextTheme] — este último é o que impede um papel sem mapeamento
/// de herdar a escala padrão do Material (outra família e outros tamanhos).
///
/// Qualquer mudança na escala quebra aqui DELIBERADAMENTE: ao alterar o tema,
/// atualize esta tabela junto (ela é o contrato, não um snapshot acidental).
void main() {
  // (nome, getter, tamanho, peso, tracking, entrelinha)
  final tokens = <_Token>[
    (
      name: 'display',
      style: () => AppTypography.display,
      size: 28,
      weight: FontWeight.w600,
      tracking: -0.6,
      lineHeight: 36,
    ),
    (
      name: 'headline',
      style: () => AppTypography.headline,
      size: 24,
      weight: FontWeight.w600,
      tracking: -0.5,
      lineHeight: 32,
    ),
    (
      name: 'titleLarge',
      style: () => AppTypography.titleLarge,
      size: 20,
      weight: FontWeight.w600,
      tracking: -0.35,
      lineHeight: 28,
    ),
    (
      name: 'titleMedium',
      style: () => AppTypography.titleMedium,
      size: 16,
      weight: FontWeight.w500,
      tracking: -0.3,
      lineHeight: 24,
    ),
    (
      name: 'bodyLarge',
      style: () => AppTypography.bodyLarge,
      size: 16,
      weight: FontWeight.w400,
      tracking: -0.1,
      lineHeight: 24,
    ),
    (
      name: 'bodyMedium',
      style: () => AppTypography.bodyMedium,
      size: 14,
      weight: FontWeight.w400,
      tracking: -0.1,
      lineHeight: 20,
    ),
    (
      name: 'bodySmall',
      style: () => AppTypography.bodySmall,
      size: 12,
      weight: FontWeight.w400,
      tracking: 0,
      lineHeight: 16,
    ),
    (
      name: 'labelLarge',
      style: () => AppTypography.labelLarge,
      size: 14,
      weight: FontWeight.w500,
      tracking: 0,
      lineHeight: 20,
    ),
    (
      name: 'labelMedium',
      style: () => AppTypography.labelMedium,
      size: 12,
      weight: FontWeight.w500,
      tracking: 0,
      lineHeight: 16,
    ),
    (
      name: 'labelSmall',
      style: () => AppTypography.labelSmall,
      size: 11,
      weight: FontWeight.w500,
      tracking: 0,
      lineHeight: 16,
    ),
  ];

  group('escala global', () {
    for (final t in tokens) {
      test('${t.name}: ${t.size}/${t.weight} e entrelinha ${t.lineHeight}', () {
        final style = t.style();
        expect(style.fontSize, t.size, reason: '${t.name}: fontSize');
        expect(style.fontWeight, t.weight, reason: '${t.name}: peso');
        expect(
          style.letterSpacing,
          t.tracking,
          reason: '${t.name}: tracking',
        );
        expect(
          style.height,
          closeTo(t.lineHeight / t.size, 1e-9),
          reason:
              '${t.name}: entrelinha deve ser ${t.lineHeight}px '
              '(height = ${t.lineHeight}/${t.size})',
        );
        expect(
          style.fontFamily,
          'Inter',
          reason: '${t.name}: família única do app',
        );
        // Valores financeiros alinham coluna a coluna em todos os papéis.
        expect(
          style.fontFeatures?.any((f) => f.feature == 'tnum') ?? false,
          isTrue,
          reason: '${t.name}: tabular figures obrigatórias',
        );
      });
    }

    test('família é o nome puro da Inter (nunca um stack CSS)', () {
      // Regressão: `'Inter, -apple-system, …'` NÃO é resolvido pelo motor e
      // caía silenciosamente na fonte padrão da plataforma.
      expect(AppTypography.family, 'Inter');
      expect(AppTypography.family.contains(','), isFalse);
      expect(AppTypography.familyFallback, isNotEmpty);
      expect(AppTypography.familyFallback.contains('Inter'), isFalse);
    });

    test('pesos usados são apenas 400/500/600', () {
      final allowed = {FontWeight.w400, FontWeight.w500, FontWeight.w600};
      for (final t in tokens) {
        expect(
          allowed.contains(t.style().fontWeight),
          isTrue,
          reason: '${t.name}: peso ${t.style().fontWeight} fora da escala',
        );
      }
    });

    test('nenhum papel fica abaixo de 12 exceto labelSmall', () {
      for (final t in tokens) {
        if (t.name == 'labelSmall') continue;
        expect(
          t.size,
          greaterThanOrEqualTo(12),
          reason: '${t.name}: texto essencial nunca abaixo de 12',
        );
      }
    });
  });

  group('TextTheme', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final brightness = theme.brightness.name;
      final textTheme = theme.textTheme;

      test('$brightness — os 15 papéis mapeiam para a escala', () {
        // (papel, tamanho esperado)
        final roles = <String, (TextStyle?, double)>{
          'displayLarge': (textTheme.displayLarge, 28),
          'displayMedium': (textTheme.displayMedium, 28),
          'displaySmall': (textTheme.displaySmall, 28),
          'headlineLarge': (textTheme.headlineLarge, 24),
          'headlineMedium': (textTheme.headlineMedium, 24),
          'headlineSmall': (textTheme.headlineSmall, 24),
          'titleLarge': (textTheme.titleLarge, 20),
          'titleMedium': (textTheme.titleMedium, 16),
          'titleSmall': (textTheme.titleSmall, 14),
          'bodyLarge': (textTheme.bodyLarge, 16),
          'bodyMedium': (textTheme.bodyMedium, 14),
          'bodySmall': (textTheme.bodySmall, 12),
          'labelLarge': (textTheme.labelLarge, 14),
          'labelMedium': (textTheme.labelMedium, 12),
          'labelSmall': (textTheme.labelSmall, 11),
        };
        for (final entry in roles.entries) {
          final style = entry.value.$1;
          expect(style, isNotNull, reason: '${entry.key}: não definido');
          expect(
            style!.fontSize,
            entry.value.$2,
            reason: '${entry.key}: tamanho fora da escala',
          );
          expect(
            style.fontFamily,
            'Inter',
            reason: '${entry.key}: precisa usar a Inter',
          );
        }
      });

      test('$brightness — o w600 fica restrito a títulos', () {
        // Títulos dominantes em w600; corpo/labels nunca.
        for (final style in [
          textTheme.displayLarge!,
          textTheme.headlineLarge!,
          textTheme.titleLarge!,
        ]) {
          expect(style.fontWeight, FontWeight.w600);
        }
        for (final style in [
          textTheme.bodyLarge!,
          textTheme.bodyMedium!,
          textTheme.bodySmall!,
          textTheme.labelLarge!,
          textTheme.labelMedium!,
        ]) {
          expect(
            style.fontWeight == FontWeight.w600,
            isFalse,
            reason: '${style.fontSize}: corpo/label não usa w600',
          );
        }
      });
    }
  });

  test('superfícies com tipografia própria seguem a escala', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      // Título de página (AppBar) = headline 24/w600.
      final appBar = theme.appBarTheme.titleTextStyle!;
      expect(appBar.fontSize, 24);
      expect(appBar.fontWeight, FontWeight.w600);
      expect(appBar.letterSpacing, -0.5);

      // Diálogo = titleMedium 16/w500.
      final dialog = theme.dialogTheme.titleTextStyle!;
      expect(dialog.fontSize, 16);
      expect(dialog.fontWeight, FontWeight.w500);

      // Chip/status = labelMedium 12/w500.
      final chip = theme.chipTheme.labelStyle!;
      expect(chip.fontSize, 12);
      expect(chip.fontWeight, FontWeight.w500);

      // Campos: rótulo 12, flutuante 14, hint 14, erro/auxiliar 12.
      final input = theme.inputDecorationTheme;
      expect(input.labelStyle!.fontSize, 12);
      expect(input.labelStyle!.fontWeight, FontWeight.w500);
      expect(input.floatingLabelStyle!.fontSize, 14);
      expect(input.hintStyle!.fontSize, 14);
      expect(input.errorStyle!.fontSize, 12);
      expect(input.helperStyle!.fontSize, 12);

      // Navegação = labelMedium (12), nunca 11; ativo w600.
      final navSelected =
          theme.navigationBarTheme.labelTextStyle!.resolve({
            WidgetState.selected,
          })!;
      final navUnselected =
          theme.navigationBarTheme.labelTextStyle!.resolve({})!;
      expect(navSelected.fontSize, 12);
      expect(navSelected.fontWeight, FontWeight.w600);
      expect(navUnselected.fontSize, 12);
      expect(navUnselected.fontWeight, FontWeight.w500);
    }
  });

  testWidgets('título de AlertDialog renderiza com 16/w500', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(title: Text('Confirmar')),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final effective = DefaultTextStyle.of(
      tester.element(find.text('Confirmar')),
    ).style;
    expect(effective.fontSize, 16);
    expect(effective.fontWeight, FontWeight.w500);
  });

  testWidgets('botão primário renderiza com 14/w500', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FilledButton(onPressed: () {}, child: const Text('Ok')),
        ),
      ),
    );

    final effective = DefaultTextStyle.of(
      tester.element(find.text('Ok')),
    ).style;
    expect(effective.fontSize, 14);
    expect(effective.fontWeight, FontWeight.w500);
  });

  // ── Painel do super admin (tema thin DERIVADO) ─────────────────────────
  // Exceção documentada: a escala é a MESMA do app; só os PESOS mudam
  // (hierarquia por tamanho e cor). Qualquer drift do segundo sistema
  // quebra aqui.
  group('admin thin — pesos derivados da escala base', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final brightness = theme.brightness.name;
      final thin = AdminThin.thinTextTheme(theme.textTheme);

      test('$brightness — tamanhos da escala, pesos leves', () {
        expect(thin.titleLarge?.fontSize, 20);
        expect(thin.titleLarge?.fontWeight, FontWeight.w300);
        expect(thin.titleMedium?.fontSize, 16);
        expect(thin.titleMedium?.fontWeight, FontWeight.w300);
        expect(thin.titleSmall?.fontSize, 14);
        expect(thin.titleSmall?.fontWeight, FontWeight.w400);
        expect(thin.labelLarge?.fontSize, 14);
        expect(thin.labelLarge?.fontWeight, FontWeight.w400);
        expect(thin.labelMedium?.fontSize, 12);
        expect(thin.labelMedium?.fontWeight, FontWeight.w400);
        expect(thin.bodyMedium?.fontSize, 14);
        expect(thin.bodyMedium?.fontWeight, FontWeight.w400);
        expect(thin.bodySmall?.fontSize, 12);
        expect(thin.bodySmall?.fontWeight, FontWeight.w400);
        expect(thin.labelSmall?.fontSize, 11);
        expect(thin.labelSmall?.fontWeight, FontWeight.w500);
      });

      test('$brightness — tamanhos e tabular sobrevivem à derivação', () {
        for (final pair in [
          MapEntry(thin.titleLarge, theme.textTheme.titleLarge),
          MapEntry(thin.titleSmall, theme.textTheme.titleSmall),
          MapEntry(thin.bodySmall, theme.textTheme.bodySmall),
          MapEntry(thin.labelSmall, theme.textTheme.labelSmall),
        ]) {
          expect(pair.key?.fontSize, pair.value?.fontSize);
          final tnumThin =
              pair.key?.fontFeatures?.any((f) => f.feature == 'tnum') ?? false;
          final tnumBase =
              pair.value?.fontFeatures?.any((f) => f.feature == 'tnum') ??
              false;
          expect(
            tnumThin,
            tnumBase,
            reason: 'tabular do base deve sobreviver ao thin',
          );
        }
      });

      testWidgets(
        '$brightness — superfícies thin: AppBar 19/w300, inputs/chips 13, snackbar 14',
        (tester) async {
          late ThemeData derived;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: AdminThin(
                child: Builder(
                  builder: (context) {
                    derived = Theme.of(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          );

          final appBar = derived.appBarTheme.titleTextStyle!;
          expect(appBar.fontSize, 19);
          expect(appBar.fontWeight, FontWeight.w300);
          expect(derived.appBarTheme.toolbarHeight, 52);

          expect(derived.inputDecorationTheme.labelStyle!.fontSize, 13);
          expect(
            derived.inputDecorationTheme.labelStyle!.fontWeight,
            FontWeight.w400,
          );
          expect(derived.chipTheme.labelStyle!.fontSize, 13);
          expect(derived.snackBarTheme.contentTextStyle!.fontSize, 14);
        },
      );
    }
  });
}

// (nome, getter, tamanho, peso, tracking, altura de linha em px)
typedef _Token = ({
  String name,
  TextStyle Function() style,
  double size,
  FontWeight weight,
  double tracking,
  double lineHeight,
});
