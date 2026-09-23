import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';

import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/sales/sales_screen.dart';
import 'package:tareqo/presentation/widgets/payment_filter.dart';
import 'package:tareqo/presentation/widgets/period_filter.dart';
import 'package:tareqo/presentation/widgets/sale_card.dart';

import '../../helpers/store_context.dart';

class _FakeSalesRepository implements ISaleRepository {
  _FakeSalesRepository(this._sales);

  final List<Sale> _sales;

  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<Sale?> getById(String id, {required String storeId}) async {
    for (final sale in _sales) {
      if (sale.id == id) return sale;
    }
    return null;
  }

  @override
  Future<void> markCancelled(String id, {required String storeId}) async {}

  @override
  Future<List<LotConsumption>> getLotConsumption(
    String saleId, {
    required String storeId,
  }) async => const [];

  @override
  Future<void> registerLotConsumption(
    String saleId,
    String storeId,
    List<LotConsumption> consumption,
  ) async {}

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
  DateTime? dateTime,
}) {
  return Sale(
    id: id,
    number: number,
    items:
        items ??
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
    dateTime: dateTime ?? DateTime(2024, 1, 10, 14, 30),
  );
}

void main() {
  // A11y (Fase 6): resumo do dia e cards de venda passam nos guidelines de
  // toque (≥48dp) e contraste de texto.
  testWidgets('a11y: vendas passa nos guidelines de toque e contraste', (
    tester,
  ) async {
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

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  // A11y (plano UI/UX — Fase 3.1): o card de venda é UM nó semântico com
  // rótulo composto (método, valor, número+itens, status) — lido de uma
  // vez — e o toque fica roteado ao nó combinado (duplo-toque ativa o
  // card inteiro, como num botão).
  testWidgets('card de venda expõe rótulo composto e toque acionável', (
    tester,
  ) async {
    var tapped = false;
    // Handle ANTES do pump: a árvore de semântica é construída no frame.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: SalesCard(
            sale: _pastSale(
              items: const [
                SaleItem(
                  productId: 'p1',
                  productName: 'Caneta',
                  quantity: 2,
                  unitPriceCents: 200,
                ),
              ],
            ),
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.bySemanticsLabel(
      'M-Pesa: R\$ 4,00, S-00001 · 1 item, Pago',
    );
    expect(card, findsOneWidget);
    // O toque no nó composto aciona o card (duplo-toque do leitor).
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    handle.dispose();
  });

  testWidgets('exibe as vendas registadas pelo repositório', (tester) async {
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
    // FAB circular com dados (sem label — tooltip, igual ao Novo produto).
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('SalesCard com onTap personalizado não navega para detalhes', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: SalesCard(sale: _pastSale(), onTap: () => tapped = true),
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

    expect(find.text('Nenhuma venda registada'), findsOneWidget);
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

    // Filtro minimalista (canvas V3): abre o seletor de período (chip
    // "Tudo") e escolhe "Hoje" no menu.
    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<PeriodFilter>, 'Hoje'));
    await tester.pumpAndSettle();

    // Só a venda de hoje permanece.
    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('S-00002 · 1 item'), findsNothing);
  });

  testWidgets('filtra por período Ontem', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          // Hoje.
          _pastSale(
            id: 's1',
            number: 1,
            totalAmountCents: 100,
            dateTime: DateTime.now(),
          ),
          // Ontem.
          _pastSale(
            id: 's2',
            number: 2,
            totalAmountCents: 200,
            dateTime: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // A busca por número saiu do redesign — o filtro de período cobre a
    // mesma intenção de estreitar a lista.
    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<PeriodFilter>, 'Ontem'));
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(PopupMenuItem<PaymentFilter>, 'Dinheiro'),
    );
    await tester.pumpAndSettle();

    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('S-00002 · 1 item'), findsNothing);
  });

  // Microcopy: a chip "todas as formas de pagamento" tem rótulo PRÓPRIO
  // ("Todas") — distinto do "Tudo" da linha de período acima (duas chips
  // idênticas empilhadas confundiam a leitura).
  testWidgets('filtro de pagamento usa rótulo próprio "Todas"', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeSalesRepository([_pastSale()])));
    await tester.pumpAndSettle();

    // A chip "todas" do pagamento existe com o rótulo distinto;
    // o período continua com "Tudo".
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Tudo'), findsOneWidget);
  });

  testWidgets('filtro sem resultados mostra estado vazio e limpa filtros', (
    tester,
  ) async {
    // Venda com data fixa (2024) — o filtro "Hoje" não a encontra.
    await tester.pumpWidget(_buildApp(_FakeSalesRepository([_pastSale()])));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<PeriodFilter>, 'Hoje'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma venda encontrada'), findsOneWidget);

    // O estado vazio fica abaixo do fold na viewport 800×600 com a barra
    // de filtros fixa — rola até o botão antes de tocar.
    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar filtros'));
    await tester.pump();

    expect(find.text('S-00001 · 1 item'), findsOneWidget);
    expect(find.text('Nenhuma venda encontrada'), findsNothing);
  });

  testWidgets('filtros ficam fixos ao rolar a lista', (tester) async {
    // Várias vendas para permitir rolagem real.
    final sales = [
      for (var i = 1; i <= 15; i++)
        _pastSale(id: 's$i', number: i, totalAmountCents: 100 + i),
    ];
    await tester.pumpWidget(_buildApp(_FakeSalesRepository(sales)));
    await tester.pumpAndSettle();

    // Chips de filtro visíveis no topo, junto com o resumo do dia.
    expect(find.text('Tudo'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);

    // Rola a lista até o fim.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    // Os filtros continuam FIXOS (pinned), mas o resumo rolou para fora.
    expect(find.text('Tudo'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNothing);
  });

  testWidgets('re-mede a barra fixa quando a escala de texto muda em runtime', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([_pastSale(), _pastSale(id: 's2', number: 2)]),
      ),
    );
    await tester.pumpAndSettle();

    // Altura pintada do header fixo (RenderSliver, não RenderBox).
    double headerHeight() {
      final render =
          tester.renderObject(find.byType(SliverPersistentHeader))
              as RenderSliver;
      return render.geometry!.paintExtent;
    }

    final before = headerHeight();

    // Utilizador ajusta a escala de texto do sistema DEPOIS da montagem:
    // a altura da barra fixa precisa ser re-medida (senão o conteúdo
    // ficaria cortado pelo extent antigo).
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpAndSettle();

    final after = headerHeight();
    expect(after, greaterThan(before));
    expect(find.text('Tudo'), findsOneWidget);
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

    // Chips de filtro fixos no topo, junto com o resumo do dia.
    expect(find.text('Tudo'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);

    // Gira para paisagem (800×600): a largura maior pode quebrar os chips
    // em menos linhas — a barra precisa re-medir o próprio extent.
    await rotateToLandscape(tester);

    // Sem overflow e os filtros continuam fixos após o giro.
    expect(tester.takeException(), isNull);
    expect(find.text('Tudo'), findsOneWidget);

    // Rolando até o fim, os filtros permanecem FIXOS e o resumo rolou fora.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Tudo'), findsOneWidget);
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

    // O card segue renderizado e nenhum overflow foi registado.
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('venda anulada: selo Anulada no card e fora do resumo do dia', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          // Ativa HOJE — entra no resumo e mostra 'Pago'.
          _pastSale(id: 's-active', totalAmountCents: 400, dateTime: today),
          // Anulada HOJE — NÃO entra no resumo e mostra 'Anulada'.
          _pastSale(
            id: 's-cancelled',
            number: 2,
            totalAmountCents: 700,
            paymentMethod: PaymentMethod.cash,
            dateTime: today,
          ).copyWith(
            status: SaleStatus.cancelled,
            cancelledAt: today.add(const Duration(hours: 1)),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    // Cards: ativa 'Pago', anulada 'Anulada'.
    expect(find.text('Pago'), findsOneWidget);
    expect(find.text('Anulada'), findsOneWidget);
    expect(find.text('R\$ 7,00'), findsOneWidget);

    // Resumo do dia: só a ativa conta (R\$ 4,00 no resumo + no card).
    expect(find.text('R\$ 4,00'), findsNWidgets(2));
    expect(find.text('R\$ 11,00'), findsNothing); // 400 + 700 NÃO soma
  });
}
