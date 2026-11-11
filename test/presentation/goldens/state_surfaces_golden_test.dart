import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_fonts.dart';
import '../../helpers/test_app.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/core/theme/app_tokens.dart';
import 'package:tareqo/presentation/widgets/empty_state.dart';
import 'package:tareqo/presentation/widgets/error_view.dart';
import 'package:tareqo/presentation/widgets/inline_error_card.dart';
import 'package:tareqo/presentation/widgets/list_skeleton.dart';

/// Auditoria visual dos estados vazios/erro/loading (passo 10) — as
/// superfícies partilhadas que aparecem em todas as listagens, em light,
/// dark e com tipografia a 2.0×.
///
/// Skeletons pulsantes ficam determinísticos via `disableAnimations` (o
/// [Skeleton] respeita reduce-motion e desenha estático).
void main() {
  setUpAll(loadGoldenFonts);

  Future<void> pumpStates(
    WidgetTester tester, {
    required ThemeData theme,
    required double scale,
  }) async {
    tester.view.physicalSize = const Size(420, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: testApp(
          theme: theme,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto',
                    subtitle: 'Adicione o primeiro produto da loja.',
                    actionLabel: 'Adicionar produto',
                    onAction: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'Nenhum resultado',
                    subtitle: 'Ajuste os filtros para ver mais vendas.',
                    actionLabel: 'Limpar filtros',
                    outlinedAction: true,
                    onAction: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const InlineEmpty(
                    icon: Icons.payments_outlined,
                    message: 'Sem movimentos neste dia.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const InlineEmpty(message: 'Nenhum item para mostrar.'),
                  const SizedBox(height: AppSpacing.xl),
                  InlineErrorCard(
                    message: 'Falha ao carregar o resumo.',
                    onRetry: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ErrorView(
                    message: 'Não foi possível carregar os dados.',
                    details: 'Sem conexão com o servidor.',
                    onRetry: () {},
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SizedBox(height: 360, child: ListSkeleton(items: 3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scale in const <double>[1.0, 2.0]) {
    final tag = '${scale}x'.replaceAll('.', '_');

    testWidgets('estados — light ${scale}x', (tester) async {
      await pumpStates(tester, theme: AppTheme.light, scale: scale);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/states_light_$tag.png'),
      );
    });

    testWidgets('estados — dark ${scale}x', (tester) async {
      await pumpStates(tester, theme: AppTheme.dark, scale: scale);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/states_dark_$tag.png'),
      );
    });
  }
}
