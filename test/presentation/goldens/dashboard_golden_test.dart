import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/utils/app_clock.dart';

/// Golden de tela cheia do Dashboard — a superfície de leitura diária do
/// dono da loja (KPIs, fluxo de caixa, feed de atividade).
///
/// Relógio injetado na âncora [kGoldenNow]: a data/saudação do cabeçalho e
/// os períodos de caixa são determinísticos — o golden não muda entre dias.
void main() {
  setUpAll(() async {
    final bytes = File('assets/fonts/Outfit-Variable.ttf').readAsBytesSync();
    final loader = FontLoader('Outfit')
      ..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  });

  setUp(() => AppClock.inject(() => kGoldenNow));
  tearDown(AppClock.reset);

  testWidgets('dashboard — dark', (tester) async {
    usePortraitViewport(tester, size: const Size(800, 2000));
    await tester.pumpWidget(dashboardGoldenApp(theme: AppTheme.dark));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_dark.png'),
    );
  });

  testWidgets('dashboard — light', (tester) async {
    usePortraitViewport(tester, size: const Size(800, 2000));
    await tester.pumpWidget(dashboardGoldenApp(theme: AppTheme.light));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/dashboard_light.png'),
    );
  });
}
