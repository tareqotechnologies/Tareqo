import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:dumbhanengue/domain/entities/purchase.dart';
import 'package:dumbhanengue/domain/usecases/get_purchases_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/purchases_providers.dart';
import 'package:dumbhanengue/presentation/screens/purchases/purchases_screen.dart';

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

List<Purchase> get _purchases => [
  Purchase(
    id: 'c1',
    storeId: 'st1',
    supplierName: 'Distribuidora Central',
    items: const [
      PurchaseItem(
        productId: 'p1',
        productName: 'Caneta',
        quantity: 50,
        unitPrice: 0.5,
      ),
      PurchaseItem(
        productId: 'p2',
        productName: 'Caderno',
        quantity: 20,
        unitPrice: 3.0,
      ),
    ],
    totalAmount: 85.0,
    dateTime: DateTime(2026, 8, 3, 9, 15),
  ),
  Purchase(
    id: 'c2',
    storeId: 'st1',
    supplierName: 'Papelaria Souza',
    items: const [
      PurchaseItem(
        productId: 'p3',
        productName: 'Borracha',
        quantity: 100,
        unitPrice: 0.2,
      ),
    ],
    totalAmount: 20.0,
    dateTime: DateTime(2026, 8, 1, 16, 40),
  ),
];

void main() {
  testWidgets('exibe as compras registradas pelo caso de uso', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(_purchases)));

    // Estado inicial: carregando.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Distribuidora Central'), findsOneWidget);
    expect(find.text('Papelaria Souza'), findsOneWidget);
    // Nº de itens + data do dia (o formato da data varia com o relógio).
    expect(find.textContaining('2 itens ·'), findsOneWidget);
    expect(find.textContaining('1 item ·'), findsOneWidget);
    expect(find.text('R\$ 85,00'), findsOneWidget);
    expect(find.text('R\$ 20,00'), findsOneWidget);
  });

  testWidgets('exibe estado vazio quando não há compras', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(const [])));

    await tester.pumpAndSettle();

    expect(find.text('Nenhuma compra registrada'), findsOneWidget);
    // O botão de ação aparece no EmptyState e no FAB.
    expect(find.text('Nova compra'), findsNWidgets(2));
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

  testWidgets('o botão de atualizar recarrega a lista', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeGetPurchasesUseCase(_purchases)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('Distribuidora Central'), findsOneWidget);
  });
}
