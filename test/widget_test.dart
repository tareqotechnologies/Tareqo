import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/app.dart';
import 'package:dumbhanengue/domain/entities/customer.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/purchase.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_cash_flow_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_customers_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_purchases_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_settled_debts_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/customers_providers.dart';
import 'package:dumbhanengue/presentation/controllers/purchases_providers.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';

import 'helpers/store_context.dart';

class _FakeGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
        Product(
          id: 'p1',
          name: 'Caneta',
          purchasePriceCents: 100,
          salePriceCents: 200,
          stockQuantity: 10,
        ),
      ];
}

class _FakeSalesRepository implements ISaleRepository {
  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<List<Sale>> getAll({required String storeId}) async => [
        Sale(
          id: 's1',
          items: const [
            SaleItem(
              productId: 'p1',
              productName: 'Caneta',
              quantity: 2,
              unitPriceCents: 200,
            ),
          ],
          totalAmountCents: 400,
          paymentMethod: PaymentMethod.mPesa,
          dateTime: DateTime.now(),
        ),
      ];
}

class _FakeGetCashFlowUseCase implements GetCashFlowUseCase {
  @override
  final ICashFlowRepository? serverRepository = null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const CashFlow(incomeCents: 10000, expenseCents: 4000);
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  @override
  Future<List<Debt>> call({required String storeId}) async => [
        Debt(
          id: 'd1',
          personName: 'João',
          amountCents: 2500,
          dueDate: DateTime.now().add(const Duration(days: 3)),
          isCustomerDebt: true,
        ),
      ];
}

class _FakeGetSettledDebtsUseCase implements GetSettledDebtsUseCase {
  @override
  Future<List<Debt>> call({required String storeId}) async => const [];
}

class _FakeGetPurchasesUseCase implements GetPurchasesUseCase {
  @override
  Future<List<Purchase>> call({required String storeId}) async => const [];
}

class _FakeGetCustomersUseCase implements GetCustomersUseCase {
  @override
  Future<List<Customer>> call({required String storeId}) async => const [
        Customer(id: 'c1', name: 'João'),
      ];
}

void main() {
  testWidgets('Dashboard renderiza o ERP: KPIs, ações e navegação',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Contexto de loja (sessão + tenant aprovado + loja demo) — o
          // AuthGate roteia para o AppShell e a loja ativa é resolvida.
          ...storeContextOverrides(),
          getProductsUseCaseProvider
              .overrideWithValue(_FakeGetProductsUseCase()),
          salesRepositoryProvider.overrideWithValue(_FakeSalesRepository()),
          getCashFlowUseCaseProvider
              .overrideWithValue(_FakeGetCashFlowUseCase()),
          getPendingDebtsUseCaseProvider
              .overrideWithValue(_FakeGetPendingDebtsUseCase()),
          getSettledDebtsUseCaseProvider
              .overrideWithValue(_FakeGetSettledDebtsUseCase()),
          getCustomersUseCaseProvider
              .overrideWithValue(_FakeGetCustomersUseCase()),
          getPurchasesUseCaseProvider
              .overrideWithValue(_FakeGetPurchasesUseCase()),
        ],
        child: const DumbhanengueApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Saudação com o nome derivado do e-mail da sessão.
    expect(find.textContaining('Olá, dono'), findsOneWidget);
    // Indicadores do dashboard.
    expect(find.text('Total de vendas'), findsOneWidget);
    expect(find.text('Saldo em caixa'), findsOneWidget);
    expect(find.text('A receber (fiado)'), findsOneWidget);
    expect(find.text('Estoque em produtos'), findsOneWidget);
    // Navegação do shell (NavigationBar em telas estreitas).
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Produtos'), findsOneWidget);
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.text('Financeiro'), findsOneWidget);
    expect(find.text('Crédito'), findsOneWidget);
    // 'Clientes' aparece na aba E no card de módulo do dashboard.
    expect(find.text('Clientes'), findsWidgets);
  });
}
