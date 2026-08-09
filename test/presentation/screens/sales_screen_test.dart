import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';
import 'package:dumbhanengue/presentation/screens/sales/sales_screen.dart';
import 'package:dumbhanengue/presentation/widgets/sale_card.dart';

import '../../helpers/store_context.dart';

class _FakeSalesRepository implements ISaleRepository {
  _FakeSalesRepository(this._sales);

  final List<Sale> _sales;

  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<List<Sale>> getAll({required String storeId}) async =>
      List.unmodifiable(_sales);
}

Widget _buildApp(ISaleRepository repository) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — a lista de vendas escopa pela loja ativa.
      ...storeContextOverrides(),
      salesRepositoryProvider.overrideWithValue(repository),
    ],
    child: testApp(home: SalesScreen()),
  );
}

/// Venda com data fixa no PASSADO — o resumo do dia (hoje) nunca é afetado
/// pela data real da execução do teste (determinístico).
Sale _pastSale({
  String id = 's1',
  int number = 1,
  List<SaleItem>? items,
  int totalAmountCents = 400,
  PaymentMethod paymentMethod = PaymentMethod.mPesa,
}) {
  return Sale(
    id: id,
    number: number,
    items: items ??
        [
          SaleItem(
            productId: 'p1',
            productName: 'Produto p1',
            quantity: 1,
            unitPriceCents: totalAmountCents,
          ),
        ],
    totalAmountCents: totalAmountCents,
    paymentMethod: paymentMethod,
    dateTime: DateTime(2024, 1, 10, 14, 30),
  );
}

void main() {
  testWidgets('exibe as vendas registradas pelo repositório', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          _pastSale(
            items: const [
              SaleItem(
                productId: 'p1',
                productName: 'Caneta',
                quantity: 2,
                unitPriceCents: 200,
              ),
            ],
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // O card separa número SEQUENCIAL da venda (S-00001) + itens, com a
    // forma de pagamento em linha própria e o status "Pago".
    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('R\$ 4,00'), findsOneWidget);
    expect(find.text('Pago'), findsOneWidget);
    // Resumo do dia presente (venda antiga → hoje ainda zerado).
    expect(find.text('R\$ 0,00'), findsOneWidget);
    expect(find.text('0 transações'), findsOneWidget);
    expect(find.text('Nova venda'), findsOneWidget);
  });

  testWidgets('SalesCard com onTap personalizado não navega para detalhes', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: SalesCard(
            sale: _pastSale(),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('M-Pesa'));
    await tester.pumpAndSettle();

    // A ação personalizada foi chamada e a navegação padrão NÃO ocorreu.
    expect(tapped, isTrue);
    expect(find.text('Detalhes da venda'), findsNothing);
  });

  testWidgets('exibe estado vazio quando não há vendas', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeSalesRepository(const [])));

    await tester.pumpAndSettle();

    expect(find.text('Nenhuma venda registrada'), findsOneWidget);
    // CTA ÚNICO: no estado vazio o FAB some e o botão do EmptyState é o
    // único "Nova venda" (sem duplicação).
    expect(find.text('Nova venda'), findsOneWidget);
  });

  testWidgets('tocar no card abre a tela de detalhes da venda', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          _pastSale(
            items: const [
              SaleItem(
                productId: 'p1',
                productName: 'Caneta',
                quantity: 2000, // 2 unidades em MILÉSIMOS (W11)
                unitPriceCents: 200,
              ),
            ],
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('S-00001 · 1 item'));
    await tester.pumpAndSettle();

    // Tela de detalhes com os itens expandidos.
    expect(find.text('Detalhes da venda'), findsOneWidget);
    expect(find.text('Caneta'), findsOneWidget);
    expect(find.text('2 × R\$ 2,00'), findsOneWidget);
    // Subtotal do item + total (resumo e rodapé) da venda.
    expect(find.text('R\$ 4,00'), findsAtLeastNWidgets(2));
  });

  testWidgets('resumo mostra o total e o número de transações de hoje', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          Sale(
            id: 's1',
            number: 1,
            items: const [
              SaleItem(
                productId: 'p1',
                productName: 'Caneta',
                quantity: 2000,
                unitPriceCents: 200,
              ),
            ],
            totalAmountCents: 400,
            paymentMethod: PaymentMethod.mPesa,
            dateTime: DateTime.now(),
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // Valor do dia aparece no resumo E no card (2 instâncias).
    expect(find.text('R\$ 4,00'), findsNWidgets(2));
    expect(find.text('1 transação'), findsOneWidget);
  });

  testWidgets('filtra por período Hoje', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          Sale(
            id: 's1',
            number: 1,
            items: const [
              SaleItem(
                productId: 'p1',
                productName: 'Caneta',
                quantity: 1,
                unitPriceCents: 100,
              ),
            ],
            totalAmountCents: 100,
            paymentMethod: PaymentMethod.mPesa,
            dateTime: DateTime.now(),
          ),
          Sale(
            id: 's2',
            number: 2,
            items: const [
              SaleItem(
                productId: 'p1',
                productName: 'Caneta',
                quantity: 1,
                unitPriceCents: 200,
              ),
            ],
            totalAmountCents: 200,
            paymentMethod: PaymentMethod.cash,
            dateTime: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // Ambas as vendas visíveis inicialmente.
    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('S-00002 · 1 item'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Hoje'));
    await tester.pump();

    // Só a venda de hoje permanece.
    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('S-00002 · 1 item'), findsNothing);
  });

  testWidgets('busca por número da venda', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          _pastSale(id: 's1', number: 1),
          _pastSale(id: 's2', number: 2, totalAmountCents: 200),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'S-00002');
    await tester.pump();

    expect(find.text('S-00002 · 1 item'), findsOneWidget);
    expect(find.text('S-00001 · 1 item'), findsNothing);
  });

  testWidgets('filtra por forma de pagamento', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          _pastSale(id: 's1', number: 1, paymentMethod: PaymentMethod.cash),
          _pastSale(
            id: 's2',
            number: 2,
            totalAmountCents: 200,
            paymentMethod: PaymentMethod.mPesa,
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Dinheiro'));
    await tester.pump();

    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('S-00002 · 1 item'), findsNothing);
  });

  testWidgets('busca sem resultado mostra estado vazio e limpa filtros', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(_FakeSalesRepository([_pastSale()])),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('Nenhuma venda encontrada'), findsOneWidget);

    // O estado vazio fica abaixo do fold na viewport 800×600 com a barra
    // fixa de 10 chips — rola até o botão antes de tocar.
    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar filtros'));
    await tester.pump();

    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('Nenhuma venda encontrada'), findsNothing);
  });

  testWidgets('busca e filtros ficam fixos ao rolar a lista', (tester) async {
    // Várias vendas para permitir rolagem real.
    final sales = [
      for (var i = 1; i <= 15; i++)
        _pastSale(id: 's$i', number: i, totalAmountCents: 100 + i),
    ];
    await tester.pumpWidget(_buildApp(_FakeSalesRepository(sales)));
    await tester.pumpAndSettle();

    // Busca visível no topo, junto com o resumo do dia.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);

    // Rola a lista até o fim.
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    // A busca continua FIXA (pinned), mas o resumo rolou para fora.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNothing);
  });

  testWidgets('re-mede a barra fixa quando a escala de texto muda em runtime',
      (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([_pastSale(), _pastSale(id: 's2', number: 2)]),
      ),
    );
    await tester.pumpAndSettle();

    // Altura pintada do header fixo (RenderSliver, não RenderBox).
    double headerHeight() {
      final render = tester.renderObject(
        find.byType(SliverPersistentHeader),
      ) as RenderSliver;
      return render.geometry!.paintExtent;
    }

    final before = headerHeight();

    // Usuário ajusta a escala de texto do sistema DEPOIS da montagem:
    // a altura da barra fixa precisa ser re-medida (senão o conteúdo
    // ficaria cortado pelo extent antigo).
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpAndSettle();

    final after = headerHeight();
    expect(after, greaterThan(before));
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Rotação (UI): em paisagem a largura muda e a barra fixa precisa ser
  // re-medida em runtime (mesmo mecanismo do text-scale — o PinnedHeader
  // assina MediaQuery). O campo de busca continua fixo e sem overflow
  // após o giro; rolando, o resumo sai de cena e a busca permanece.
  testWidgets('busca fixa sobrevive à rotação para paisagem', (tester) async {
    // Retrato estreito: busca + filtros visíveis no topo.
    usePortraitViewport(tester);

    // Várias vendas para permitir rolagem real.
    final sales = [
      for (var i = 1; i <= 15; i++)
        _pastSale(id: 's$i', number: i, totalAmountCents: 100 + i),
    ];
    await tester.pumpWidget(_buildApp(_FakeSalesRepository(sales)));
    await tester.pumpAndSettle();

    // Busca fixa no topo, junto com o resumo do dia.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);

    // Gira para paisagem (800×600): a largura maior pode quebrar os chips
    // em menos linhas — a barra precisa re-medir o próprio extent.
    await rotateToLandscape(tester);

    // Sem overflow e a busca continua fixa após o giro.
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);

    // Rolando até o fim, a busca permanece FIXA e o resumo rolou para fora.
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // Regressão (UI): a coluna de total/data ficava sem Flexível — com
  // escala de texto 2.0 em tela estreita (e totais grandes), o card
  // estourava. Agora ela encolhe com ellipsis; overflows de RenderFlex
  // falham o teste via takeException.
  testWidgets('não estoura com escala de texto 2.0 em tela estreita', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // Estreita (360) porém alta: garante que o card seja construído/pintado
    // com escala 2.0 (abaixo do fold o overflow ficaria mascarado).
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          _pastSale(
            items: [
              for (var i = 0; i < 12; i++)
                SaleItem(
                  productId: 'p$i',
                  productName: 'Produto $i',
                  quantity: 3,
                  unitPriceCents: 99999,
                ),
            ],
            totalAmountCents: 999999999,
            // Cartão de crédito = pior caso (rótulo localizado longo +
            // ícone de cartão) na linha superior do card com o chip 'Pago'.
            paymentMethod: PaymentMethod.creditCard,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // O card segue renderizado e nenhum overflow foi registrado.
    expect(find.text('Nova venda'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
