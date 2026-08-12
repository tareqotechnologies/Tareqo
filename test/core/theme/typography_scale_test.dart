import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/theme/app_theme.dart';

/// Auditoria da ESCALA TIPOGRÁFICA (Apple HIG / SF Pro, adaptada ao ERP
/// — ver docs/pt/05-apresentacao.md): trava os tamanhos
/// 34/28/24/22/20/17/15/14/13/12/11, os pesos de cada papel, o uso de
/// `tabularFigures` nos estilos numéricos (alinhamento dígito a dígito de
/// preços MZN e quantidades kg/un) e os três eixos de precisão do mestre
/// de tipografia:
///
///  - **tracking** (`letterSpacing`): negativo nos títulos (SF Pro usa
///    ~-0.4 a -0.6), neutro no corpo e positivo leve nos captions;
///  - **entrelinha** (`height`) na razão do SF Pro (~1.2 títulos, ~1.4
///    corpo — nunca 1.5+ que estica o layout);
///  - **eixo óptico** (`opsz`): a Inter é variável (14–32) e títulos
///    (≥20px) usam o corte Display (24–32); corpo fica no corte Texto.
///
/// Qualquer mudança na escala quebra aqui DELIBERADAMENTE — ao alterar o
/// tema, atualize este teste junto (a tabela é a especificação executável).
void main() {
  // (nome, papel do TextTheme, tamanho, peso, tracking, entrelinha, opsz,
  //  usa tabular figures?)
  final cases = <_Case>[
    (
      name: 'displaySmall — Large Title (34) — LIGHT w300',
      style: _displaySmall,
      size: 34,
      weight: FontWeight.w300,
      tracking: -0.6,
      height: 1.2,
      opsz: 32,
      tabular: true,
    ),
    (
      name: 'headlineMedium — Título 1 (28) — LIGHT w300',
      style: _headlineMedium,
      size: 28,
      weight: FontWeight.w300,
      tracking: -0.5,
      height: 1.2,
      opsz: 32,
      tabular: true,
    ),
    (
      name: 'headlineSmall — Título 1.5 (24)',
      style: _headlineSmall,
      size: 24,
      weight: FontWeight.w600,
      tracking: -0.4,
      height: 1.25,
      opsz: 32,
      tabular: true,
    ),
    (
      name: 'titleLarge — Título 2 (22)',
      style: _titleLarge,
      size: 22,
      weight: FontWeight.w600,
      tracking: -0.35,
      height: 1.27,
      opsz: 24,
      tabular: true,
    ),
    (
      name: 'titleMedium — Título 3 (20)',
      style: _titleMedium,
      size: 20,
      weight: FontWeight.w600,
      tracking: -0.3,
      height: 1.3,
      opsz: 24,
      tabular: true,
    ),
    (
      name: 'titleSmall — destaque de linha (14)',
      style: _titleSmall,
      size: 14,
      weight: FontWeight.w600,
      tracking: -0.15,
      height: 1.35,
      opsz: 0, // corpo (sem eixo Display)
      tabular: false,
    ),
    (
      name: 'bodyLarge — corpo destacado (17)',
      style: _bodyLarge,
      size: 17,
      weight: FontWeight.w400,
      tracking: -0.1,
      height: 1.4,
      opsz: 0,
      tabular: true,
    ),
    (
      name: 'bodyMedium — corpo (15)',
      style: _bodyMedium,
      size: 15,
      weight: FontWeight.w400,
      tracking: -0.1,
      height: 1.4,
      opsz: 0,
      tabular: true,
    ),
    (
      name: 'bodySmall — nota (13)',
      style: _bodySmall,
      size: 13,
      weight: FontWeight.w400,
      tracking: 0,
      height: 1.35,
      opsz: 0,
      tabular: true,
    ),
    (
      name: 'labelLarge — ações (14)',
      style: _labelLarge,
      size: 14,
      weight: FontWeight.w600,
      tracking: 0,
      height: 1.25,
      opsz: 0,
      tabular: false,
    ),
    (
      name: 'labelMedium — labels (12)',
      style: _labelMedium,
      size: 12,
      weight: FontWeight.w600,
      tracking: 0,
      height: 1.25,
      opsz: 0,
      tabular: false,
    ),
    (
      name: 'labelSmall — caption/badge (11)',
      style: _labelSmall,
      size: 11,
      weight: FontWeight.w500,
      tracking: 0.2,
      height: 1.25,
      opsz: 0,
      tabular: false,
    ),
  ];

  for (final theme in [AppTheme.light, AppTheme.dark]) {
    final brightness = theme.brightness.name;
    final textTheme = theme.textTheme;

    test('$brightness — escala de tamanhos e pesos', () {
      for (final c in cases) {
        final style = c.style(textTheme);
        expect(
          style,
          isNotNull,
          reason: '${c.name}: papel não definido no TextTheme',
        );
        expect(
          style!.fontSize,
          c.size,
          reason: '${c.name}: fontSize esperado ${c.size}',
        );
        expect(
          style.fontWeight,
          c.weight,
          reason: '${c.name}: peso esperado ${c.weight}',
        );
      }
    });

    test('$brightness — tracking, entrelinha e eixo óptico (SF Pro)', () {
      for (final c in cases) {
        final style = c.style(textTheme)!;
        expect(
          style.letterSpacing,
          c.tracking,
          reason: '${c.name}: tracking esperado ${c.tracking}',
        );
        expect(
          style.height,
          c.height,
          reason: '${c.name}: entrelinha esperada ${c.height}',
        );
        // opsz = 0 → o estilo NÃO carrega o eixo (fica no corte Texto,
        // default da fonte). opsz > 0 → corte Display esperado.
        final opsz = style.fontVariations
            ?.where((v) => v.axis == 'opsz')
            .map((v) => v.value)
            .firstOrNull;
        expect(
          opsz ?? 0,
          c.opsz,
          reason: '${c.name}: eixo óptico esperado opsz=${c.opsz}',
        );
      }
    });

    test('$brightness — tabularFigures apenas nos estilos numéricos', () {
      for (final c in cases) {
        final style = c.style(textTheme)!;
        // Comparação pelo NOME da feature: FontFeature não sobrescreve ==
        // em dart:ui (igualdade por identidade) — `contains` com instância
        // const não casaria com a instância de runtime do tema.
        final hasTnum =
            style.fontFeatures?.any((f) => f.feature == 'tnum') ?? false;
        expect(
          hasTnum,
          c.tabular,
          reason:
              '${c.name}: ${c.tabular ? 'deve ter' : 'não deve ter'} '
              'tabular figures (só estilos numéricos alinham)',
        );
      }
    });
  }

  // Superfícies com tipografia própria (fora do TextTheme).
  test('superfícies: AppBar 22, diálogo 22 e chips 13 seguem a escala', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final appBar = theme.appBarTheme.titleTextStyle!;
      expect(appBar.fontSize, 22, reason: 'AppBar — Título 2 da escala');
      expect(appBar.fontWeight, FontWeight.w600);
      // Tracking/entrelinha alinhados ao titleLarge (hierarquia conversa).
      expect(appBar.letterSpacing, -0.35);
      expect(appBar.height, 1.25);

      final dialog = theme.dialogTheme.titleTextStyle!;
      expect(dialog.fontSize, 22, reason: 'diálogo — Título 2 da escala');
      expect(dialog.fontWeight, FontWeight.w600);
      expect(dialog.letterSpacing, -0.35);
      expect(dialog.height, 1.27);

      final chip = theme.chipTheme.labelStyle!;
      expect(chip.fontSize, 13, reason: 'chip — corpo/nota da escala');
      expect(chip.fontWeight, FontWeight.w600);

      // Rótulos/hints dos CAMPOS (InputDecorationTheme): discretos e
      // MENORES que o texto digitado (bodyLarge 17) — sem fontSize, o
      // label herdava o 17 e truncava em campos estreitos ('Purchase
      // pr...', 'Stock quan...' — formulário de produto). floatingLabel
      // fixa o mesmo 13 quando o rótulo sobe para a borda do campo.
      final input = theme.inputDecorationTheme;
      expect(
        input.labelStyle!.fontSize,
        13,
        reason: 'label do campo — rótulo discreto (13)',
      );
      expect(input.labelStyle!.fontWeight, FontWeight.w400);
      expect(
        input.floatingLabelStyle!.fontSize,
        13,
        reason: 'label flutuante — mesmo 13 na borda (sem encolher p/ 0.75×)',
      );
      expect(
        input.hintStyle!.fontSize,
        14,
        reason: 'hint do campo — nota discreta (14), abaixo do texto 17',
      );
    }
  });

  testWidgets('título de AlertDialog renderiza com 22/w600 (Título 2)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(title: const Text('Confirmar')),
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
    expect(effective.fontSize, 22, reason: 'título do diálogo — Título 2');
    expect(effective.fontWeight, FontWeight.w600);
  });

  testWidgets('botão primário renderiza com 15/w400 (ultra-clean)', (
    tester,
  ) async {
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
    expect(effective.fontSize, 15);
    expect(effective.fontWeight, FontWeight.w400);
  });
}

// (nome, papel do TextTheme, tamanho, peso, tracking, entrelinha, opsz,
//  usa tabular figures?)
typedef _Case = ({
  String name,
  TextStyle? Function(TextTheme) style,
  double size,
  FontWeight weight,
  double tracking,
  double height,
  double opsz,
  bool tabular,
});

// Seletores dos papéis — função top-level para uso na lista.
TextStyle? _displaySmall(TextTheme t) => t.displaySmall;
TextStyle? _headlineMedium(TextTheme t) => t.headlineMedium;
TextStyle? _headlineSmall(TextTheme t) => t.headlineSmall;
TextStyle? _titleLarge(TextTheme t) => t.titleLarge;
TextStyle? _titleMedium(TextTheme t) => t.titleMedium;
TextStyle? _titleSmall(TextTheme t) => t.titleSmall;
TextStyle? _bodyLarge(TextTheme t) => t.bodyLarge;
TextStyle? _bodyMedium(TextTheme t) => t.bodyMedium;
TextStyle? _bodySmall(TextTheme t) => t.bodySmall;
TextStyle? _labelLarge(TextTheme t) => t.labelLarge;
TextStyle? _labelMedium(TextTheme t) => t.labelMedium;
TextStyle? _labelSmall(TextTheme t) => t.labelSmall;
