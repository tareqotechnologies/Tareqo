import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_processor.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/process_sale_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';
import 'package:dumbhanengue/presentation/screens/sales/new_sale_sheet.dart';

import '../../helpers/store_context.dart';

class _FakeGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
        Product(
          id: 'p1',
          name: 'Caneta',
          purchasePrice: 1.0,
          salePrice: 2.0,
          stockQuantity: 10,
        ),
      ];
}

/// Registra a venda sem tocar em infraestrutura (o ProcessSaleUseCase já é
/// coberto por testes de domínio — aqui validamos apenas a orquestração da UI).
class _FakeProcessSaleUseCase implements ProcessSaleUseCase {
  int calls = 0;
  Sale? lastSale;

  @override
  Future<void> call(Sale sale) async {
    calls++;
    lastSale = sale;
  }

  @override
  ISaleAtomicProcessor? get processor => null;
}

void main() {
  testWidgets('confirmar venda chama o ProcessSaleUseCase e mostra o total',
      (tester) async {
    final processSale = _FakeProcessSaleUseCase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Contexto de loja — o carrinho usa os produtos da loja ativa
          // e carimba a loja na venda.
          ...storeContextOverrides(),
          getProductsUseCaseProvider
              .overrideWithValue(_FakeGetProductsUseCase()),
          processSaleUseCaseProvider.overrideWithValue(processSale),
        ],
        child: testApp(home: Scaffold(body: NewSaleSheet())),
      ),
    );
    await tester.pumpAndSettle();

    // Produto carregado; adiciona 1 unidade ao carrinho.
    expect(find.text('Caneta'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Confirma a venda.
    await tester.tap(find.text('Confirmar venda'));
    await tester.pumpAndSettle();

    // O use case foi chamado exatamente uma vez, com o total calculado.
    expect(processSale.calls, 1);
    expect(processSale.lastSale?.totalAmount, 2.0);
  });
}
