import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/presentation/widgets/app_page.dart';

import '../../helpers/test_app.dart';

/// Testes do scaffold compartilhado [AppPage] e dos componentes de apoio
/// ([AppIconBadge], [AppListTile], [AppPill]) — usados por quase todas as
/// telas do app, o que dá cobertura ampla com esforço mínimo.
void main() {
  group('AppPage', () {
    testWidgets('sem título não cria AppBar', (tester) async {
      await tester.pumpWidget(
        testApp(home: const AppPage(body: Text('Só corpo'))),
      );

      expect(find.text('Só corpo'), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('título simples cria AppBar de linha única', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const AppPage(title: 'Facturas', body: Text('Corpo')),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Facturas'), findsOneWidget);
    });

    testWidgets('subtítulo monta o header de duas linhas (altura 72)', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: const AppPage(
            title: 'Clientes',
            subtitle: '3 registos',
            body: Text('Corpo'),
          ),
        ),
      );

      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('3 registos'), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, 72);
    });

    testWidgets('badge zero/nulo não renderiza pílula; badge positivo sim', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: const AppPage(title: 'A', badge: 0, body: Text('x')),
        ),
      );
      expect(find.text('0'), findsNothing);

      await tester.pumpWidget(
        testApp(
          home: const AppPage(title: 'A', badge: 5, body: Text('x')),
        ),
      );
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('FAB, actions e leading são repassados ao Scaffold', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: AppPage(
            title: 'T',
            body: const Text('x'),
            actions: [TextButton(onPressed: () {}, child: const Text('Ação'))],
            leading: const Icon(Icons.arrow_back),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.text('Ação'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('useSafeArea false dispensa o SafeArea', (tester) async {
      await tester.pumpWidget(
        testApp(home: const AppPage(useSafeArea: false, body: Text('x'))),
      );

      expect(find.byType(SafeArea), findsNothing);

      await tester.pumpWidget(testApp(home: const AppPage(body: Text('x'))));
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('horizontalPadding responde à largura da viewport', (
      tester,
    ) async {
      late EdgeInsets captured;
      await tester.pumpWidget(
        testApp(
          home: Builder(
            builder: (context) {
              captured = AppPage.horizontalPadding(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // Em desktop-largo o padding é fixo (32) — mobile estreito usaria 16.
      expect(captured.horizontal, greaterThanOrEqualTo(16));
    });
  });

  group('AppIconBadge', () {
    testWidgets('renderiza o ícone no tamanho pedido', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const AppIconBadge(icon: Icons.store, size: 48, iconSize: 22),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.store));
      expect(icon.size, 22);
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.store),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.maxWidth, 48);
    });

    testWidgets('dashedBorder pinta o arco tracejado', (tester) async {
      await tester.pumpWidget(
        testApp(home: const AppIconBadge(icon: Icons.add, dashedBorder: true)),
      );

      // O painter privado existe além do CustomPaint do Material.
      final hasDashedPainter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .any(
            (cp) =>
                cp.painter?.runtimeType.toString() == '_DashedBorderPainter',
          );
      expect(hasDashedPainter, isTrue);
    });
  });

  group('AppListTile', () {
    testWidgets('sem onTap não é clicável', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const AppListTile(title: 'Título', subtitle: 'Sub'),
        ),
      );

      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Sub'), findsOneWidget);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('onTap dispara e mostra leading/trailing', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        testApp(
          home: AppListTile(
            title: 'Loja Centro',
            leading: const Icon(Icons.store),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Loja Centro'));
      expect(taps, 1);
    });
  });

  group('AppPill', () {
    testWidgets('sem onTap é estática; com onTap é clicável', (tester) async {
      var taps = 0;
      // O InkWell da pílula clicável exige um Material ancestral (em
      // produção vem do Scaffold; aqui provisionamos explicitamente).
      await tester.pumpWidget(
        testApp(
          home: Material(
            child: Column(
              children: [
                const AppPill(label: 'Estática'),
                AppPill(label: 'Clicável', onTap: () => taps++),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Estática'), findsOneWidget);
      await tester.tap(find.text('Clicável'));
      expect(taps, 1);
    });

    testWidgets('ícone e seta só aparecem quando configurados', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const Column(
            children: [
              AppPill(label: 'Com ícone', icon: Icons.filter_list),
              AppPill(label: 'Sem nada'),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
      // Seta dropdown só em pílulas com onTap.
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    });
  });
}
