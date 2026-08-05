import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/purchase.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
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

/// Fake que retorna produtos DIFERENTES por loja — permite verificar que o
/// seletor realmente troca o escopo dos dados exibidos.
class _StoreScopedGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => [
        Product(
          id: 'p-$storeId',
          storeId: storeId,
          name: storeId == 'st1' ? 'Produto Loja Centro' : 'Produto Loja Shopping',
          purchasePrice: 1.0,
          salePrice: 2.0,
          stockQuantity: 2, // estoque baixo → aparece no dashboard
        ),
      ];
}

/// Fake de compras por loja — usado para verificar que o seletor também
/// funciona nas telas EMPURRADAS por cima do AppShell (fora da casca).
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
            PurchaseItem(productId: 'p1', productName: 'X', quantity: 1, unitPrice: 1),
          ],
          totalAmount: 10,
          dateTime: DateTime.now(),
        ),
      ];
}

class _EmptySalesRepository implements ISaleRepository {
  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<List<Sale>> getAll({required String storeId}) async => const [];
}

class _ZeroCashFlowUseCase implements GetCashFlowUseCase {
  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const CashFlow(income: 0, expense: 0);
}

void main() {
  testWidgets('seletor de loja aparece com 2+ lojas e troca a loja ativa',
      (tester) async {
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

    // Seletor visível com as duas lojas (chips).
    expect(find.widgetWithText(ChoiceChip, 'Loja Centro'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Loja Shopping'), findsOneWidget);

    // Dashboard mostra a loja ativa (primeira loja = Loja Centro) e o
    // produto dela.
    expect(find.text('Produto Loja Centro'), findsOneWidget);

    // Troca para a Loja Shopping pelo seletor.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Loja Shopping'));
    await tester.pumpAndSettle();

    // O dashboard reflete a nova loja ativa e os dados dela.
    expect(find.text('Produto Loja Shopping'), findsOneWidget);
    expect(find.text('Produto Loja Centro'), findsNothing);
  });

  testWidgets('seletor de loja aparece também em tela empurrada (Compras)',
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

    // A barra do seletor existe na tela empurrada, com as duas lojas.
    expect(find.widgetWithText(ChoiceChip, 'Loja Centro'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Loja Shopping'), findsOneWidget);

    // Dados da loja ativa (primeira = Loja Centro).
    expect(find.text('Fornecedor Centro'), findsOneWidget);

    // Troca a loja pelo seletor na própria tela empurrada.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Loja Shopping'));
    await tester.pumpAndSettle();

    expect(find.text('Fornecedor Shopping'), findsOneWidget);
    expect(find.text('Fornecedor Centro'), findsNothing);
  });

  testWidgets('seletor de loja NÃO aparece com uma única loja', (tester) async {
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

    // Sem barra de seleção (nada a selecionar) e a loja única é a ativa.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Produto Loja Centro'), findsOneWidget);
  });
}
