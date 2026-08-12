import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/purchase.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_lot_consumption.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_cash_flow_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_purchases_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/controllers/purchases_providers.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';
import 'package:dumbhanengue/presentation/screens/purchases/purchases_screen.dart';
import 'package:dumbhanengue/presentation/screens/shell/app_shell.dart';

import '../../helpers/store_context.dart';

/// Fake que retorna produtos DIFERENTES por loja — permite verificar que a
/// troca de loja (agora em Lojas → Ajustes) realmente muda o escopo dos
/// dados exibidos.
class _StoreScopedGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => [
        Product(
          id: 'p-$storeId',
          storeId: storeId,
          name: storeId == 'st1' ? 'Produto Loja Centro' : 'Produto Loja Shopping',
          purchasePriceCents: 100,
          salePriceCents: 200,
          stockQuantity: 2, // estoque baixo → aparece no dashboard
        ),
      ];
}

/// Fake de compras por loja — usado para verificar que as telas EMPURRADAS
/// por cima do AppShell exibem os dados da loja ativa (sem banner).
class _StoreScopedGetPurchasesUseCase implements GetPurchasesUseCase {
  @override
  Future<List<Purchase>> call({required String storeId}) async => [
        Purchase(
          id: 'pc-$storeId',
          storeId: storeId,
          supplierName: storeId == 'st1'
              ? 'Fornecedor Centro'
              : 'Fornecedor Shopping',
          items: const [
            PurchaseItem(productId: 'p1', productName: 'X', quantity: 1, unitPriceCents: 100),
          ],
          totalAmountCents: 1000,
          dateTime: DateTime.now(),
        ),
      ];
}

class _EmptySalesRepository implements ISaleRepository {
  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<Sale?> getById(String id, {required String storeId}) async => null;

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
  Future<List<Sale>> getAll({required String storeId}) async => const [];
}

class _ZeroCashFlowUseCase implements GetCashFlowUseCase {
  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const CashFlow(incomeCents: 0, expenseCents: 0);
}

void main() {
  // Regressão: o banner de seleção de loja NÃO existe mais no topo das
  // telas (migrado para Lojas → Ajustes). O dashboard continua exibindo a
  // loja ativa e os dados dela.
  testWidgets('banner de loja removido do topo (AppShell) — dados da loja '
      'ativa seguem no dashboard', (tester) async {
    // Viewport alto: o dashboard usa ListView preguiçoso e o card de
    // estoque baixo (que exibe o nome do produto) fica abaixo da dobra.
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(
            stores: const [
              Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
              Store(id: 'st2', tenantId: 'tn1', name: 'Loja Shopping'),
            ],
          ),
          getProductsUseCaseProvider
              .overrideWithValue(_StoreScopedGetProductsUseCase()),
          salesRepositoryProvider.overrideWithValue(_EmptySalesRepository()),
          getCashFlowUseCaseProvider.overrideWithValue(_ZeroCashFlowUseCase()),
        ],
        child: testApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    // SEM banner no topo: nenhum ChoiceChip de loja no shell.
    expect(find.widgetWithText(ChoiceChip, 'Loja Centro'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Loja Shopping'), findsNothing);

    // O dashboard mostra os dados da loja ativa (primeira = Loja Centro).
    expect(find.text('Produto Loja Centro'), findsOneWidget);
  });

  testWidgets('banner de loja também removido de tela empurrada (Compras)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(
            stores: const [
              Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
              Store(id: 'st2', tenantId: 'tn1', name: 'Loja Shopping'),
            ],
          ),
          getPurchasesUseCaseProvider
              .overrideWithValue(_StoreScopedGetPurchasesUseCase()),
        ],
        child: testApp(home: PurchasesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Sem banner na tela empurrada; os dados são da loja ativa.
    expect(find.widgetWithText(ChoiceChip, 'Loja Centro'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Loja Shopping'), findsNothing);
    expect(find.text('Fornecedor Centro'), findsOneWidget);
  });

  testWidgets('com uma única loja não há seletor nem banner', (tester) async {
    // Viewport alto (mesmo motivo do teste anterior).
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(), // 1 loja (st1) por padrão
          getProductsUseCaseProvider
              .overrideWithValue(_StoreScopedGetProductsUseCase()),
          salesRepositoryProvider.overrideWithValue(_EmptySalesRepository()),
          getCashFlowUseCaseProvider.overrideWithValue(_ZeroCashFlowUseCase()),
        ],
        child: testApp(home: AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    // Sem ChoiceChip no shell (nada a selecionar) e a loja única é a ativa.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Produto Loja Centro'), findsOneWidget);
  });
}
