import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliver;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/viewport.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart' show PaymentMethod;
import 'package:tareqo/domain/usecases/get_purchases_use_case.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/screens/purchases/purchases_screen.dart';
import 'package:tareqo/presentation/widgets/payment_filter.dart';
import 'package:tareqo/presentation/widgets/period_filter.dart';
import 'package:tareqo/presentation/widgets/skeleton.dart';

/// Fake do [GetPurchasesUseCase] — a tela nunca toca em GetIt nem em
/// datasources; o provider é sobrescrito no [ProviderScope].
class _FakeGetPurchasesUseCase implements GetPurchasesUseCase {
  _FakeGetPurchasesUseCase(this._purchases);

  final List<Purchase> _purchases;

  @override
  Future<List<Purchase>> call({required String storeId}) async => _purchases;
}

/// Fake que sempre falha, para exercitar o estado de erro.
class _ThrowingGetPurchasesUseCase implements GetPurchasesUseCase {
  @override
  Future<List<Purchase>> call({required String storeId}) async =>
      throw Exception('falha simulada ao buscar compras');
}

Widget _buildApp(GetPurchasesUseCase useCase) {
  return ProviderScope(
    overrides: [
      // Contexto de loja — a lista de compras escopa pela loja ativa.
      ...storeContextOverrides(),
      getPurchasesUseCaseProvider.overrideWithValue(useCase),
    ],
    child: testApp(home: const PurchasesScreen()),
  );
}

Purchase _purchase({
  required String id,
  required int number,
  required String supplierName,
  int totalAmountCents = 100,
  List<PurchaseItem>? items,
  PaymentMethod? paymentMethod,
  DateTime? dateTime,
}) {
  return Purchase(
    id: id,
    number: number,
    storeId: 'st1',
    supplierName: supplierName,
    items:
        items ??
        [
          PurchaseItem(
            productId: 'p1',
            productName: 'Caneta',
            quantity: 1,
            unitPriceCents: totalAmountCents,
          ),
        ],
    totalAmountCents: totalAmountCents,
    paymentMethod: paymentMethod ?? PaymentMethod.cash,
    // Data fixa no PASSADO: o resumo do dia (hoje) nunca é afetado pela
    // data real da execução do teste (determinístico).
    dateTime: dateTime ?? DateTime(2024, 1, 10, 9, 15),
  );
}

/// Compras com data fixa no passado (2024) — usadas pelos testes base.
List<Purchase> get _purchases => [
  _purchase(
    id: 'c1',
    number: 1,
    supplierName: 'Distribuidora Central',
    totalAmountCents: 8500,
    items: const [
      PurchaseItem(
        productId: 'p1',
        productName: 'Caneta',
        quantity: 50000, // 50 unidades em MILÉSIMOS (W11)
        unitPriceCents: 50,
      ),
      PurchaseItem(
        productId: 'p2',
        productName: 'Caderno',
        quantity: 20000,
        unitPriceCents: 300,
      ),
    ],
  ),
  _purchase(
    id: 'c2',
    number: 2,
    supplierName: 'Papelaria Souza',
    totalAmountCents: 2000,
    items: const [
      PurchaseItem(
        productId: 'p3',
        productName: 'Borracha',
        quantity: 100000,
        unitPriceCents: 20,
      ),
    ],
    dateTime: DateTime(2024, 1, 8, 16, 40),
  ),
];

void main() {
  testWidgets('exibe as compras registadas pelo caso de uso', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(_purchases)));

    // Estado inicial: carregando (skeleton).
    expect(find.byType(Skeleton), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.text('Papelaria Souza'), findsOneWidget);
    // Número SEQUENCIAL da compra na loja em cada card.
    expect(find.textContaining('C-00001 ·'), findsOneWidget);
    expect(find.textContaining('C-00002 ·'), findsOneWidget);
    // Nº de itens por card.
    expect(find.textContaining('2 itens'), findsOneWidget);
    expect(find.textContaining('1 item'), findsOneWidget);
    // Unidades adicionadas ao stock (50+20 e 100).
    expect(find.text('Stock +70 un.'), findsOneWidget);
    expect(find.text('Stock +100 un.'), findsOneWidget);
    // Valores dos cards.
    expect(find.text('R\$ 85,00'), findsOneWidget);
    expect(find.text('R\$ 20,00'), findsOneWidget);
    // Resumo do dia presente (compras antigas → hoje zerado).
    expect(find.text('R\$ 0,00'), findsOneWidget);
    expect(find.text('0 compras'), findsOneWidget);
  });

  testWidgets('exibe estado vazio quando não há compras', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(const [])));

    await tester.pumpAndSettle();

    expect(find.text('Nenhuma compra registada'), findsOneWidget);
    // CTA ÚNICO: no estado vazio o FAB some e o botão do EmptyState é o
    // único "Nova compra" (sem duplicação).
    expect(find.text('Nova compra'), findsOneWidget);
  });

  // Transição do CTA (regressão do padrão "FAB some no estado vazio"):
  // sem compras, o botão fica no EmptyState e o FAB some; quando a
  // primeira compra chega (pull-to-refresh), o estado vazio sai e o FAB
  // VOLTA como ação rápida — sempre um único "Nova compra".
  testWidgets('FAB volta quando chegam dados (estado vazio → com compras)', (
    tester,
  ) async {
    final list = <Purchase>[];
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(list)));
    await tester.pumpAndSettle();

    // Estado vazio: CTA único no EmptyState, sem FAB.
    expect(find.text('Nenhuma compra registada'), findsOneWidget);
    expect(find.text('Nova compra'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Chega a primeira compra → o refresh traz os dados.
    list.add(_purchase(id: 'c1', number: 1, supplierName: 'Fornecedor Teste'));
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Fornecedor Teste'), findsOneWidget);
    expect(find.text('Nenhuma compra registada'), findsNothing);
    // FAB circular visível com dados (sem label — tooltip, igual ao Novo
    // produto); o botão do EmptyState não existe mais.
    expect(find.text('Nova compra'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('exibe erro e permite tentar novamente', (tester) async {
    await tester.pumpWidget(_buildApp(_ThrowingGetPurchasesUseCase()));

    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as compras.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('o pull-to-refresh recarrega a lista', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(_purchases)));
    await tester.pumpAndSettle();

    // Arrastar para baixo dispara o RefreshIndicator.
    await tester.fling(
      find.text('Distribuidora Central'),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(find.text('Distribuidora Central'), findsOneWidget);
  });

  testWidgets('resumo mostra o gasto e o número de compras de hoje', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeGetPurchasesUseCase([
          _purchase(
            id: 'c1',
            number: 1,
            supplierName: 'Fornecedor Hoje',
            totalAmountCents: 8500,
            dateTime: DateTime.now(),
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // Valor do dia aparece no resumo E no card (2 instâncias).
    expect(find.text('R\$ 85,00'), findsNWidgets(2));
    expect(find.text('1 compra'), findsOneWidget);
  });

  testWidgets('filtra por forma de pagamento', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeGetPurchasesUseCase([
          _purchase(
            id: 'c1',
            number: 1,
            supplierName: 'Fornecedor M-Pesa',
            paymentMethod: PaymentMethod.mPesa,
          ),
          _purchase(id: 'c2', number: 2, supplierName: 'Fornecedor Dinheiro'),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // Ambos os fornecedores visíveis inicialmente.
    expect(find.text('Fornecedor M-Pesa'), findsOneWidget);
    expect(find.text('Fornecedor Dinheiro'), findsOneWidget);

    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(PopupMenuItem<PaymentFilter>, 'M-Pesa'),
    );
    await tester.pumpAndSettle();

    // Só a compra paga via M-Pesa permanece.
    expect(find.text('Fornecedor M-Pesa'), findsOneWidget);
    expect(find.text('Fornecedor Dinheiro'), findsNothing);
  });

  testWidgets('filtra por período Hoje', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeGetPurchasesUseCase([
          _purchase(
            id: 'c1',
            number: 1,
            supplierName: 'Fornecedor Hoje',
            dateTime: DateTime.now(),
          ),
          _purchase(
            id: 'c2',
            number: 2,
            supplierName: 'Fornecedor Ontem',
            dateTime: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    // Ambos os fornecedores visíveis inicialmente.
    expect(find.text('Fornecedor Hoje'), findsOneWidget);
    expect(find.text('Fornecedor Ontem'), findsOneWidget);

    // Filtro minimalista (canvas V3): abre o seletor de período (chip
    // "Tudo") e escolhe "Hoje" no menu.
    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<PeriodFilter>, 'Hoje'));
    await tester.pumpAndSettle();

    // Só a compra de hoje permanece.
    expect(find.text('Fornecedor Hoje'), findsOneWidget);
    expect(find.text('Fornecedor Ontem'), findsNothing);
  });

  testWidgets('filtro sem resultado mostra estado vazio e limpa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(_FakeGetPurchasesUseCase([_purchases.first])),
    );

    await tester.pumpAndSettle();

    // Compra de 2024 não cai no "Hoje" → estado vazio com ação de limpar.
    // Filtro minimalista (canvas V3): abre o seletor de período (chip
    // "Tudo") e escolhe "Hoje" no menu.
    await tester.tap(find.text('Tudo'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<PeriodFilter>, 'Hoje'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma compra encontrada'), findsOneWidget);

    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar filtros'));
    await tester.pump();

    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.text('Nenhuma compra encontrada'), findsNothing);
  });

  testWidgets('busca por fornecedor ou número da compra', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(_purchases)));

    await tester.pumpAndSettle();

    // Busca pelo número SEQUENCIAL da compra (C-00002).
    await tester.enterText(find.byType(TextField), 'C-00002');
    await tester.pump();

    expect(find.text('Papelaria Souza'), findsOneWidget);
    expect(find.text('Distribuidora Central'), findsNothing);

    // Busca pelo fornecedor (case-insensitive).
    await tester.enterText(find.byType(TextField), 'distribuidora');
    await tester.pump();

    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.text('Papelaria Souza'), findsNothing);
  });

  testWidgets('busca sem resultado limpa a busca junto com os filtros', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(_FakeGetPurchasesUseCase([_purchases.first])),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('Nenhuma compra encontrada'), findsOneWidget);

    await tester.ensureVisible(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar filtros'));
    await tester.pump();

    // A lista volta E o campo de busca foi limpo.
    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.text('Nenhuma compra encontrada'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('busca e filtros ficam fixos ao rolar a lista', (tester) async {
    // Várias compras para permitir rolagem real.
    final many = [
      for (var i = 1; i <= 15; i++)
        _purchase(
          id: 'c$i',
          number: i,
          supplierName: 'Fornecedor $i',
          totalAmountCents: 100 + i,
        ),
    ];
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(many)));
    await tester.pumpAndSettle();

    // Busca visível no topo, junto com o resumo do dia.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);

    // Rola a lista até o fim.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    // A busca continua FIXA (pinned), mas o resumo rolou para fora.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNothing);
  });

  testWidgets('re-mede a barra fixa quando a escala de texto muda em runtime', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(_FakeGetPurchasesUseCase([_purchases.first, _purchases.last])),
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
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('não estoura com escala de texto 2.0 em tela estreita', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    // Estreita (360) porém alta: garante que os cards sejam construídos/
    // pintados com escala 2.0 (abaixo do fold o overflow ficaria mascarado).
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(_purchases)));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Rotação (UI): em paisagem a largura muda e a barra fixa precisa ser
  // re-medida em runtime (mesmo mecanismo do text-scale — o PinnedHeader
  // assina MediaQuery). A busca continua fixa e sem overflow após o giro;
  // rolando, o resumo sai de cena e a busca permanece.
  testWidgets('busca fixa sobrevive à rotação para paisagem', (tester) async {
    // Retrato estreito: busca + filtros visíveis no topo.
    usePortraitViewport(tester);

    // Várias compras para permitir rolagem real.
    final many = [
      for (var i = 1; i <= 15; i++)
        _purchase(
          id: 'c$i',
          number: i,
          supplierName: 'Fornecedor $i',
          totalAmountCents: 100 + i,
        ),
    ];
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(many)));
    await tester.pumpAndSettle();

    // Busca fixa no topo, junto com o resumo do dia.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsOneWidget);

    // Gira para paisagem (800×600): a largura maior quebra os chips em
    // menos linhas — a barra precisa re-medir o próprio extent.
    await rotateToLandscape(tester);

    // Sem overflow e a busca continua fixa após o giro.
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);

    // Rolando até o fim, a busca permanece FIXA e o resumo rolou para fora.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('R\$ 0,00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('detalhes da compra (tap no card)', () {
    Purchase purchaseWithExpiry() => Purchase(
      id: 'c1',
      number: 7,
      storeId: 'st1',
      supplierName: 'Distribuidora Central',
      items: [
        PurchaseItem(
          productId: 'p1',
          productName: 'Caneta',
          quantity: 50000, // 50 un (W11)
          unitPriceCents: 50,
          expiryDate: DateTime(2027, 3, 15),
        ),
        const PurchaseItem(
          productId: 'p2',
          productName: 'Caderno',
          quantity: 20000, // 20 un
          unitPriceCents: 300,
          // Sem validade — produto não perecível.
        ),
      ],
      totalAmountCents: 8500,
      paymentMethod: PaymentMethod.mPesa,
      dateTime: DateTime(2024, 1, 10, 9, 15),
    );

    testWidgets('abrir a sheet mostra os detalhes da compra', (tester) async {
      await tester.pumpWidget(
        _buildApp(_FakeGetPurchasesUseCase([purchaseWithExpiry()])),
      );
      await tester.pumpAndSettle();

      // Tap no card da compra (fornecedor na linha do feed).
      await tester.tap(find.text('Distribuidora Central'));
      await tester.pumpAndSettle();

      // Cabeçalho padrão da sheet + número sequencial + dados principais.
      expect(find.text('Detalhes da compra'), findsOneWidget);
      expect(find.text('C-00007'), findsOneWidget);
      expect(find.text('Fornecedor'), findsOneWidget);
      expect(find.text('Distribuidora Central'), findsNWidgets(2));
      expect(find.text('Data e hora'), findsOneWidget);
      expect(find.text('10/01/2024 09:15'), findsOneWidget);
      expect(find.text('Pagamento'), findsOneWidget);
      // M-Pesa aparece no chip do card (atrás) E no da sheet.
      expect(find.text('M-Pesa'), findsNWidgets(2));
      // Total da compra (no card atrás + headline da sheet).
      expect(find.text('R\$ 85,00'), findsNWidgets(2));
      // Itens: quantidade × preço unitário e subtotal.
      expect(find.text('50 × R\$ 0,50'), findsOneWidget);
      expect(find.text('20 × R\$ 3,00'), findsOneWidget);
      expect(find.text('R\$ 25,00'), findsOneWidget);
      expect(find.text('R\$ 60,00'), findsOneWidget);
      // Validade FIFO: com data e "Sem validade".
      expect(find.textContaining('15/03/2027'), findsOneWidget);
      expect(find.textContaining('Sem validade'), findsOneWidget);
      // Notas de stock/snapshot.
      expect(find.textContaining('FIFO'), findsOneWidget);
    });

    testWidgets('fechar a sheet volta para a lista', (tester) async {
      await tester.pumpWidget(
        _buildApp(_FakeGetPurchasesUseCase([purchaseWithExpiry()])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Distribuidora Central'));
      await tester.pumpAndSettle();
      expect(find.text('C-00007'), findsOneWidget);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();

      expect(find.text('C-00007'), findsNothing);
      expect(find.text('Distribuidora Central'), findsOneWidget);
    });
  });
}
