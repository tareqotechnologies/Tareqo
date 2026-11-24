import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fixtures.dart';
import '../../helpers/golden_fonts.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/utils/app_clock.dart';
import 'package:tareqo/presentation/screens/account/tenant_onboarding_screen.dart';
import 'package:tareqo/presentation/screens/auth/set_new_password_screen.dart';

/// Baseline visual dos FORMULÁRIOS fora de sheet — onboarding do dono e
/// definição de nova senha. Mesmo padrão do golden dos formulários de
/// produto: fonte Inter real (`loadGoldenFonts`), relógio em [kGoldenNow] e
/// fakes determinísticos de `golden_fixtures.dart`.
///
/// Viewport por tela, e não um único fixo:
/// * ONBOARDING é um formulário longo (nome, idioma, moeda, planos); numa
///   altura de telefone (915) o botão “Solicitar acesso” fica fora do
///   quadro. Usa-se 412×1400 para o formulário inteiro caber no diff.
/// * NOVA SENHA é curto e cabe no telefone — 412×915, a mesma régua dos
///   goldens de tela cheia, sem sobra de espaço em branco.
void main() {
  setUpAll(loadGoldenFonts);

  setUp(() => AppClock.inject(() => kGoldenNow));
  tearDown(AppClock.reset);

  for (final dark in [false, true]) {
    final brightness = dark ? 'dark' : 'light';
    final theme = dark ? AppTheme.dark : AppTheme.light;

    testWidgets('onboarding — $brightness', (tester) async {
      usePortraitViewport(tester, size: const Size(412, 1400));
      await tester.pumpWidget(onboardingGoldenApp(theme: theme));
      // O logo é um asset: descodificar fora do `runAsync` deixa a captura
      // sem imagem (mesma corrida documentada no golden do login).
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/branding/icon_official.png'),
          tester.element(find.byType(TenantOnboardingScreen)),
        );
      });
      await tester.pumpAndSettle();

      // Sanidade: o formulário renderizou com as três seções planas e a
      // acção primária (regressão de layout quebraria aqui, não no diff).
      expect(find.text('Nome do negócio'), findsOneWidget);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Moeda'), findsOneWidget);
      expect(find.text('Escolha o plano'), findsOneWidget);
      expect(find.text('Solicitar acesso'), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/onboarding_$brightness.png'),
      );
    });

    testWidgets('nova senha — $brightness', (tester) async {
      usePortraitViewport(tester, size: const Size(412, 915));
      await tester.pumpWidget(setNewPasswordGoldenApp(theme: theme));
      await tester.pumpAndSettle();

      expect(find.byType(SetNewPasswordScreen), findsOneWidget);
      expect(find.text('Guardar nova senha'), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/nova_senha_$brightness.png'),
      );
    });
  }
}
