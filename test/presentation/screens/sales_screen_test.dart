import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';
import 'package:dumbhanengue/presentation/screens/sales/sales_screen.dart';

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

void main() {
  testWidgets('exibe as vendas registradas pelo repositório', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          Sale(
            id: 's1',
            items: const [
              SaleItem(
                productId: 'p1',
                productName: 'Caneta',
                quantity: 2,
                unitPrice: 2.0,
              ),
            ],
            totalAmount: 4.0,
            paymentMethod: PaymentMethod.pix,
            dateTime: DateTime(2026, 8, 3, 14, 30),
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 item · Pix'), findsOneWidget);
    expect(find.text('R\$ 4,00'), findsOneWidget);
    expect(find.text('Nova venda'), findsOneWidget);
  });

  testWidgets('exibe estado vazio quando não há vendas', (tester) async {
    await tester.pumpWidget(_buildApp(_FakeSalesRepository(const [])));

    await tester.pumpAndSettle();

    expect(find.text('Nenhuma venda registrada'), findsOneWidget);
  });

  testWidgets('tocar no card abre a tela de detalhes da venda', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        _FakeSalesRepository([
          Sale(
            id: 's1',
            items: const [
              SaleItem(
                productId: 'p1',
                productName: 'Caneta',
                quantity: 2,
                unitPrice: 2.0,
              ),
            ],
            totalAmount: 4.0,
            paymentMethod: PaymentMethod.pix,
            dateTime: DateTime(2026, 8, 3, 14, 30),
          ),
        ]),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('1 item · Pix'));
    await tester.pumpAndSettle();

    // Tela de detalhes com os itens expandidos.
    expect(find.text('Detalhes da venda'), findsOneWidget);
    expect(find.text('Caneta'), findsOneWidget);
    expect(find.text('2 × R\$ 2,00'), findsOneWidget);
    // Subtotal do item + total (resumo e rodapé) da venda.
    expect(find.text('R\$ 4,00'), findsAtLeastNWidgets(2));
  });
}
