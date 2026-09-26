import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:tareqo/core/utils/quantity.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_lot_consumption.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';

import '../../helpers/store_context.dart';

class _FakeGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
    Product(
      id: 'p1',
      name: 'Caneta',
      purchasePriceCents: 100,
      salePriceCents: 200,
      stockQuantity: 10 * Quantity.milliFactor,
    ),
  ];
}

class _FakeProcessSaleUseCase implements ProcessSaleUseCase {
  @override
  Future<void> call(Sale sale) async {}

  @override
  ISaleAtomicProcessor? get processor => null;
}

class _FakeSalesRepository implements ISaleRepository {
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

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        getProductsUseCaseProvider.overrideWithValue(_FakeGetProductsUseCase()),
        processSaleUseCaseProvider.overrideWithValue(_FakeProcessSaleUseCase()),
        salesRepositoryProvider.overrideWithValue(_FakeSalesRepository()),
      ],
      child: testApp(home: const Scaffold(body: NewSaleSheet())),
    ),
  );
  await tester.pumpAndSettle();
}

/// AnimatedOpacity que envolve [of], se houver — o MAIS INTERNO é o dim
/// do modo foco (o campo pode ter AnimatedOpacity próprio de erro).
AnimatedOpacity? _dimOf(WidgetTester tester, Finder of) {
  final ancestors = find.ancestor(of: of, matching: find.byType(AnimatedOpacity));
  if (ancestors.evaluate().isEmpty) return null;
  return tester.widget<AnimatedOpacity>(ancestors.last);
}

void main() {
  // Modo foco (plano UI/UX — F4.1): com a busca focada, o catálogo recua
  // (dim 40%) e o carrinho — a venda em progresso — fica em evidência.
  testWidgets('modo foco: catálogo esmaece com a busca focada; carrinho não', (
    tester,
  ) async {
    await _pump(tester);

    // Sem foco: nada esmaecido.
    expect(_dimOf(tester, find.text('Caneta')), isNull);

    // Adiciona ao carrinho: a pill "1×" é o conteúdo a proteger.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Foca a busca (caminho real: tap no campo).
    await tester.tap(find.byType(TextField).at(1));
    await tester.pumpAndSettle();

    // Catálogo esmaecido a 0.6 (dim de 40%, AnimatedOpacity 200ms).
    final catalogDim = _dimOf(tester, find.text('Caneta'));
    expect(catalogDim, isNotNull);
    expect(catalogDim!.opacity, 0.6);

    // A pill do carrinho NÃO está dentro de um dim — fica a 100%.
    expect(_dimOf(tester, find.text('1×')), isNull);

    // Sai do foco: o catálogo volta ao opaco (o dim SAI da árvore).
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(_dimOf(tester, find.text('Caneta')), isNull);
  });

  // A zona de scanner também recua — o campo de busca é o protagonista
  // enquanto digita; o estado vazio NÃO esmaece (é a resposta à busca).
  testWidgets('modo foco: zona de scanner recua; estado vazio não esmaece', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byType(TextField).at(1));
    await tester.pumpAndSettle();

    final scannerDim = _dimOf(tester, find.text('20 12345 00175'));
    expect(scannerDim, isNotNull);
    expect(scannerDim!.opacity, 0.6);
  });
}
