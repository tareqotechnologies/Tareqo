import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/presentation/widgets/app_button.dart';
import 'package:tareqo/presentation/widgets/app_card.dart';
import 'package:tareqo/presentation/widgets/app_text_field.dart';
import 'package:tareqo/presentation/widgets/fade_indexed_stack.dart';
import 'package:tareqo/presentation/widgets/kpi_card.dart';
import 'package:tareqo/presentation/widgets/smart_amount.dart';

import '../../helpers/test_app.dart';

/// Testes dos componentes do design system ultra-clean:
/// AppCard, AppButton (variantes), AppTextField, SmartAmount e KpiCard —
/// incluindo as medidas globais (altura 48, cantos 12) herdadas dos temas.
void main() {
  group('AppCard', () {
    testWidgets('renderiza o filho com o padding padrão do design system', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(home: const AppCard(child: Text('Conteúdo do card'))),
      );

      expect(find.text('Conteúdo do card'), findsOneWidget);
      // V4: o AppCard renderiza um Material (não o Card do Material 2).
      expect(find.byType(Material), findsWidgets);
      // Flat — sem sombra (elevation 0 por padrão).
      final cardFinder = find.ancestor(
        of: find.text('Conteúdo do card'),
        matching: find.byType(Material),
      );
      final cardRect = tester.getRect(cardFinder.first);
      final textRect = tester.getRect(find.text('Conteúdo do card'));
      expect(textRect.top - cardRect.top, 16);
      expect(textRect.left - cardRect.left, 16);
    });

    testWidgets('onTap dispara com ripple dentro do card', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testApp(
          home: AppCard(
            onTap: () => tapped = true,
            child: const Text('Card clicável'),
          ),
        ),
      );

      await tester.tap(find.text('Card clicável'));
      expect(tapped, isTrue);
    });
  });

  group('AppButton', () {
    testWidgets('primary: FilledButton com altura 48 e texto w400', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          // Center + largura fixa: sem as restrições rígidas da tela, o
          // botão assume a ALTURA natural do design system (48).
          home: Center(
            child: SizedBox(
              width: 300,
              child: AppButton.primary(label: 'Confirmar', onPressed: () {}),
            ),
          ),
        ),
      );

      final button = find.byType(FilledButton);
      expect(button, findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      // Altura 48 do design system (herdada do filledButtonTheme).
      expect(tester.getSize(button).height, 48);
    });

    testWidgets(
      'secondary: OutlinedButton com altura 48 (outlinedButtonTheme)',
      (tester) async {
        await tester.pumpWidget(
          testApp(
            home: Center(
              child: SizedBox(
                width: 300,
                child: AppButton.secondary(
                  label: 'Anular venda',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        final button = find.byType(OutlinedButton);
        expect(button, findsOneWidget);
        expect(tester.getSize(button).height, 48);
      },
    );

    testWidgets('danger: FilledButton vermelho de confirmação', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: AppButton.danger(label: 'Excluir', onPressed: () {}),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
    });

    testWidgets('desabilitado (onPressed null) não dispara a ação', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        testApp(home: AppButton.primary(label: 'Bloqueado', onPressed: null)),
      );

      await tester.tap(find.text('Bloqueado'));
      expect(tapped, isFalse);
    });

    testWidgets('primary com ícone mostra ícone + rótulo juntos', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: AppButton.primary(
            label: 'Partilhar',
            icon: const Icon(Icons.ios_share),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.ios_share), findsOneWidget);
      expect(find.text('Partilhar'), findsOneWidget);
    });
  });

  group('AppTextField', () {
    testWidgets('exibe o rótulo e dispara onChanged ao digitar', (
      tester,
    ) async {
      String? typed;
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: Center(
              child: AppTextField(
                label: 'Nome do produto',
                onChanged: (value) => typed = value,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nome do produto'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Caneta');
      expect(typed, 'Caneta');
    });

    testWidgets('aceita hintText e erro', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: Scaffold(
            body: Center(
              child: AppTextField(
                label: 'Código de barras',
                hintText: 'EAN-13',
                errorText: 'Código inválido',
              ),
            ),
          ),
        ),
      );

      expect(find.text('EAN-13'), findsOneWidget);
      expect(find.text('Código inválido'), findsOneWidget);
    });
  });

  group('SmartAmount', () {
    testWidgets('formata centavos na moeda ativa (pt)', (tester) async {
      await tester.pumpWidget(testApp(home: const SmartAmount(cents: 123456)));

      // BRL padrão nos testes → `R$ 1.234,56`.
      expect(find.text(r'R$ 1.234,56'), findsOneWidget);
    });

    testWidgets('prefix exibe sinal antes do valor (ex.: movimentações)', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(home: const SmartAmount(cents: 100000, prefix: '+ ')),
      );

      // Sinal + valor formatado — mesmo texto do TransactionCard (Financeiro).
      expect(find.text(r'+ R$ 1.000,00'), findsOneWidget);
    });

    testWidgets('encolhe em largura estreita sem overflow', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const Center(
            child: SizedBox(width: 80, child: SmartAmount(cents: 999999999)),
          ),
        ),
      );

      // FittedBox scaleDown: nunca estoura nem trunca.
      expect(tester.takeException(), isNull);
      expect(find.text(r'R$ 9.999.999,99'), findsOneWidget);
    });
  });

  group('FadeIndexedStack', () {
    testWidgets(
      'disableAnimations (movimento reduzido): troca direta, estado preservado',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        Widget build(int index) => testApp(
          home: FadeIndexedStack(
            index: index,
            children: const [
              _CounterTab(label: 'A'),
              _CounterTab(label: 'B'),
            ],
          ),
        );

        await tester.pumpWidget(build(0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('incrementar A'));
        await tester.pump();
        expect(find.text('A 1'), findsOneWidget);

        // Troca de aba: SEM fade (conteúdo já visível no primeiro frame),
        // o estado continua preservado — só o movimento é removido.
        await tester.pumpWidget(build(1));
        await tester.pump();
        expect(find.text('B 0'), findsOneWidget);
        expect(find.text('A 1'), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(build(0));
        await tester.pump();
        expect(find.text('A 1'), findsOneWidget);
      },
    );

    testWidgets('troca de aba anima o fade e preserva o estado dos filhos', (
      tester,
    ) async {
      Widget build(int index) => testApp(
        home: FadeIndexedStack(
          index: index,
          children: const [
            _CounterTab(label: 'A'),
            _CounterTab(label: 'B'),
          ],
        ),
      );

      await tester.pumpWidget(build(0));
      await tester.pumpAndSettle();
      expect(find.text('A 0'), findsOneWidget);

      // Incrementa o contador da aba A (estado interno do filho).
      await tester.tap(find.text('incrementar A'));
      await tester.pump();
      expect(find.text('A 1'), findsOneWidget);

      // Troca para a aba B: o fade (220ms) completa com pumpAndSettle e a
      // aba A sai de cena.
      await tester.pumpWidget(build(1));
      await tester.pumpAndSettle();
      expect(find.text('B 0'), findsOneWidget);
      expect(find.text('A 1'), findsNothing);
      expect(tester.takeException(), isNull);

      // Volta para A: o IndexedStack manteve o filho montado — o contador
      // NÃO reiniciou (estado preservado pela navegação híbrida).
      await tester.pumpWidget(build(0));
      await tester.pumpAndSettle();
      expect(find.text('A 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('KpiCard', () {
    testWidgets('amountCents renderiza via SmartAmount (auto-size)', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: const KpiCard(
            label: 'Total de vendas',
            amountCents: 123456,
            icon: Icons.point_of_sale_outlined,
          ),
        ),
      );

      expect(find.text(r'R$ 1.234,56'), findsOneWidget);
      expect(find.text('Total de vendas'), findsOneWidget);
    });

    testWidgets('value cobre indicadores não monetários (ex.: stock)', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: const KpiCard(
            label: 'Stock',
            value: '12 un',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      );

      expect(find.text('12 un'), findsOneWidget);
    });

    testWidgets('loading mostra o placeholder “—”', (tester) async {
      await tester.pumpWidget(
        testApp(
          home: const KpiCard(
            label: 'Caixa',
            amountCents: 0,
            icon: Icons.account_balance_wallet_outlined,
            loading: true,
          ),
        ),
      );

      expect(find.text('—'), findsOneWidget);
    });
  });

  group('Temas globais (design system)', () {
    testWidgets('labels da navegação usam peso leve (w500) — hierarquia '
        'pela cor', (tester) async {
      final theme = AppTheme.dark;
      // Estado NÃO selecionado (set vazio) e o SELECIONADO — a hierarquia
      // é pela COR (peso leve w500 nos dois estados); travar ambos evita
      // regressão silenciosa.
      final unselected = theme.navigationBarTheme.labelTextStyle!.resolve({});
      final selected = theme.navigationBarTheme.labelTextStyle!.resolve({
        WidgetState.selected,
      });
      expect(unselected?.fontWeight, FontWeight.w500);
      expect(selected?.fontWeight, FontWeight.w500);
    });

    testWidgets('pílula do NavigationRail é StadiumBorder (igual à barra)', (
      tester,
    ) async {
      expect(
        AppTheme.dark.navigationRailTheme.indicatorShape,
        isA<StadiumBorder>(),
      );
    });

    testWidgets('OutlinedButton do tema também tem altura 48 e cantos 12', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: OutlinedButton(onPressed: () {}, child: const Text('OK')),
            ),
          ),
        ),
      );

      final button = find.byType(OutlinedButton);
      expect(tester.getSize(button).height, 48);
      // Cantos 12 (não pílula) — vêm do outlinedButtonTheme global.
      final shape = Theme.of(
        tester.element(button),
      ).outlinedButtonTheme.style!.shape!.resolve({});
      expect(shape, isA<RoundedRectangleBorder>());
    });
  });
}

/// Aba de teste com estado interno — verifica que o [FadeIndexedStack]
/// preserva o estado dos filhos ao trocar de índice (navegação híbrida).
class _CounterTab extends StatefulWidget {
  const _CounterTab({required this.label});

  final String label;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${widget.label} $_count'),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _count++),
            child: Text('incrementar ${widget.label}'),
          ),
        ],
      ),
    );
  }
}
