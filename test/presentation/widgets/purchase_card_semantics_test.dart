import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;
import 'package:tareqo/presentation/widgets/app_card.dart';
import 'package:tareqo/presentation/widgets/focus_ring.dart';
import 'package:tareqo/presentation/widgets/purchase_card.dart';

Purchase _purchase() => Purchase(
  id: 'p1',
  number: 7,
  supplierName: 'Distribuidora Maputo',
  items: const [
    PurchaseItem(
      productId: 'pr1',
      productName: 'Caderno',
      quantity: 6000,
      unitPriceCents: 2500,
    ),
  ],
  totalAmountCents: 15000,
  paymentMethod: PaymentMethod.mPesa,
  dateTime: DateTime(2026, 9, 20, 14, 30),
);

void main() {
  // A11y (plano UI/UX — Fase 3.1): o card de compra é UM nó semântico —
  // "Distribuidora Maputo: M-Pesa, C-00007 · 1 item, 6 un. adicionadas,
  // 150,00, 20/09 · 14:30" — em vez de fornecedor/método/número/valor/data
  // anunciados como nós separados. Mesma convenção do SalesCard.
  testWidgets('PurchaseCard expõe UM nó semântico com o conteúdo completo', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      testApp(home: Scaffold(body: PurchaseCard(purchase: _purchase()))),
    );

    // O nó combinado carrega fornecedor, método, número e valor JUNTOS.
    expect(
      find.bySemanticsLabel(
        RegExp('Distribuidora Maputo.*M-Pesa.*C-00007.*150,00'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  // O toque fica FORA do nó combinado: o duplo-toque do leitor no nó
  // composto ativa o card inteiro (abre detalhes) — como num botão.
  testWidgets('toque no nó composto aciona o card clicável', (tester) async {
    var taps = 0;
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: PurchaseCard(purchase: _purchase(), onTap: () => taps++),
        ),
      ),
    );

    final node = find.bySemanticsLabel(RegExp('Distribuidora Maputo'));
    expect(node, findsOneWidget);
    // `warnIfMissed: false`: o CENTRO do nó composto cai no espaço vazio do
    // meio do card (a coluna da esquerda para antes do centro e a da direita
    // é ancorada à direita), então o hit test pousa no InkWell que ENVOLVE o
    // nó — que é o alvo real do toque — e não no RenderBox do próprio
    // Semantics. O toque continua verdadeiro: `expect(taps, 1)` falha se não
    // chegar ao card.
    await tester.tap(node, warnIfMissed: false);
    expect(taps, 1);
    handle.dispose();
  });

  // A11y (plano UI/UX — Fase 3.3): o anel pinta POR CIMA do conteúdo
  // (Positioned.fill + IgnorePointer) quando o widget está focado — e
  // sai da árvore quando o foco sai.
  testWidgets('FocusRing aparece com foco e desaparece sem ele', (tester) async {
    final node = FocusNode(debugLabel: 'probe');
    addTearDown(node.dispose);
    var focused = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          // StatefulBuilder: o onFocusChange precisa RECONSTRUIR para o
          // FocusRing receber o novo valor de [visible] (o que o app real
          // faz com setState no estado do card).
          body: StatefulBuilder(
            builder: (context, setState) => Focus(
              focusNode: node,
              onFocusChange: (f) => setState(() => focused = f),
              child: Stack(
                children: [
                  const SizedBox(width: 120, height: 60),
                  FocusRing(
                    visible: focused,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Sem foco: o anel não pinta nada (SizedBox.shrink, sem Positioned).
    expect(find.byType(Positioned), findsNothing);

    node.requestFocus();
    await tester.pump();
    expect(focused, isTrue);
    expect(find.byType(Positioned), findsOneWidget);
    final painted = tester.widget<Positioned>(find.byType(Positioned));
    expect(painted.left, 0.0);
    expect(painted.right, 0.0);
    expect(painted.top, 0.0);
    expect(painted.bottom, 0.0);
    // Nunca rouba o toque do widget focado (o IgnorePointer é o nosso —
    // dentro do Positioned.fill do anel; o framework adiciona os seus).
    expect(
      find.descendant(
        of: find.byType(Positioned),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );

    node.unfocus();
    await tester.pumpAndSettle();
    expect(focused, isFalse);
    expect(find.byType(Positioned), findsNothing);
  });

  // Integração: o AppCard clicável mostra o anel quando o seu InkWell
  // recebe foco de teclado — teclado físico/Bluetooth (scanner + teclado
  // nas lojas) precisa de foco VISÍVEL, não só do fill sutil.
  testWidgets('AppCard clicável ganha anel de foco ao ser focado', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: AppCard(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppRadiusProbe.value),
            child: const SizedBox(width: 200, height: 60),
          ),
        ),
      ),
    );

    // Sem foco: nenhum anel pintado sobre o card.
    expect(
      find.descendant(of: find.byType(AppCard), matching: find.byType(Positioned)),
      findsNothing,
    );

    // Caminho REAL do teclado físico: Tab move o foco para o primeiro
    // nó focusable da árvore — o InkWell do card.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      find.descendant(of: find.byType(AppCard), matching: find.byType(Positioned)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(AppCard), matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );
  });
}

/// Raio de card para o teste (evita importar o design system inteiro aqui).
class AppRadiusProbe {
  static const double value = 12;
}
