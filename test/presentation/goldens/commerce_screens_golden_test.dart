import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/utils/app_clock.dart';

/// Baseline visual das telas de comércio — o resto do catálogo que a Fase
/// 2.3 (tokens de espaçamento/raio) vai tocar. Cada tela em DOIS brilhos
/// (dark é o default do app; light é o tema auditado paralelo).
///
/// Mesmo contrato dos goldens existentes: fonte Inter real carregada (o
/// golden falha com a Ahem placeholder), relógio injetado em [kGoldenNow],
/// viewport retrato de telefone real (412×915) e fakes determinísticos de
/// `golden_fixtures.dart`.
///
/// A migração 2.3 é mecânica por design — `AppSpacing.lg` == `20.0` — e a
/// prova é este teste correndo VERDE depois dela, sem `--update-goldens`.
void main() {
  setUpAll(() async {
    final bytes = File('assets/fonts/Inter-Variable.ttf').readAsBytesSync();
    final loader = FontLoader('Inter')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  setUp(() => AppClock.inject(() => kGoldenNow));
  tearDown(AppClock.reset);

  Future<void> golden(
    WidgetTester tester,
    Widget app,
    String name,
  ) async {
    usePortraitViewport(tester, size: const Size(412, 915));
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('produtos — dark', (tester) async {
    await golden(tester, productGoldenApp(theme: AppTheme.dark), 'produtos_dark');
  });

  testWidgets('produtos — light', (tester) async {
    await golden(
      tester,
      productGoldenApp(theme: AppTheme.light),
      'produtos_light',
    );
  });

  testWidgets('vendas — dark', (tester) async {
    await golden(tester, salesGoldenApp(theme: AppTheme.dark), 'vendas_dark');
  });

  testWidgets('vendas — light', (tester) async {
    await golden(tester, salesGoldenApp(theme: AppTheme.light), 'vendas_light');
  });

  testWidgets('clientes — dark', (tester) async {
    await golden(
      tester,
      customersGoldenApp(theme: AppTheme.dark),
      'clientes_dark',
    );
  });

  testWidgets('clientes — light', (tester) async {
    await golden(
      tester,
      customersGoldenApp(theme: AppTheme.light),
      'clientes_light',
    );
  });

  testWidgets('crédito (fiado) — dark', (tester) async {
    await golden(tester, debtsGoldenApp(theme: AppTheme.dark), 'credito_dark');
  });

  testWidgets('crédito (fiado) — light', (tester) async {
    await golden(
      tester,
      debtsGoldenApp(theme: AppTheme.light),
      'credito_light',
    );
  });

  testWidgets('financeiro — dark', (tester) async {
    await golden(
      tester,
      financialGoldenApp(theme: AppTheme.dark),
      'financeiro_dark',
    );
  });

  testWidgets('financeiro — light', (tester) async {
    await golden(
      tester,
      financialGoldenApp(theme: AppTheme.light),
      'financeiro_light',
    );
  });
}
