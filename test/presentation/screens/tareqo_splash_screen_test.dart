import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/presentation/screens/auth/auth_gate.dart';

import '../../helpers/test_app.dart';

void main() {
  for (final theme in [AppTheme.light, AppTheme.dark]) {
    for (final size in [const Size(320, 568), const Size(640, 320)]) {
      for (final locale in [const Locale('pt'), const Locale('fr')]) {
        testWidgets(
          'splash ${theme.brightness.name} $size ${locale.languageCode} texto 2x',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final semantics = tester.ensureSemantics();
            await tester.pumpWidget(
              testApp(
                theme: theme,
                locale: locale,
                home: const TareqoSplashScreen(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
              ),
            );
            await tester.pump(const Duration(milliseconds: 250));
            final image = tester.widget<Image>(find.byType(Image));
            expect(
              (image.image as AssetImage).assetName,
              theme.brightness == Brightness.dark
                  ? 'assets/branding/splash_logo.png'
                  : 'assets/branding/splash_logo_ink.png',
            );
            expect(image.excludeFromSemantics, isTrue);
            expect(
              tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
              theme.scaffoldBackgroundColor,
            );
            expect(find.text('TAREQO'), findsOneWidget);
            expect(
              tester.getRect(find.text('TAREQO')).width,
              lessThanOrEqualTo(size.width),
            );
            final indicator = tester.widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            );
            expect(indicator.semanticsLabel, isNotEmpty);
            await tester.ensureVisible(find.byType(CircularProgressIndicator));
            await tester.pump();
            expect(tester.takeException(), isNull);
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            await tester.pumpWidget(const SizedBox.shrink());
            semantics.dispose();
          },
        );
      }
    }
  }
}
