import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

import 'package:dumbhanengue/domain/entities/customer.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/repositories/i_financial_transaction_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_sale_repository.dart';
import 'package:dumbhanengue/domain/usecases/get_cash_flow_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_customers_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_settled_debts_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/customers_providers.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';
import 'package:dumbhanengue/presentation/screens/shell/app_shell.dart';

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

class _FakeSalesRepository implements ISaleRepository {
  @override
  Future<void> registerSale(Sale sale) async {}

  @override
  Future<List<Sale>> getAll({required String storeId}) async => const [];
}

class _FakeGetCashFlowUseCase implements GetCashFlowUseCase {
  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const CashFlow(income: 0, expense: 0);
}

class _FakeGetPendingDebtsUseCase implements GetPendingDebtsUseCase {
  @override
  Future<List<Debt>> call({required String storeId}) async => const [];
}

class _FakeGetSettledDebtsUseCase implements GetSettledDebtsUseCase {
  @override
  Future<List<Debt>> call({required String storeId}) async => const [];
}

class _FakeGetCustomersUseCase implements GetCustomersUseCase {
  @override
  Future<List<Customer>> call({required String storeId}) async => const [
        Customer(id: 'c1', name: 'João'),
      ];
}

class _FakeFinanceRepository implements IFinancialTransactionRepository {
  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      const [];

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      const [];

  @override
  Future<void> add(FinancialTransaction transaction) async {}

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {}
}

void main() {
  testWidgets('AppShell exibe as 5 seções e navega entre elas',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Contexto de loja (sessão + tenant aprovado + loja demo) — os
          // módulos escopam pela loja ativa.
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
          financeRepositoryProvider.overrideWithValue(_FakeFinanceRepository()),
          getCustomersUseCaseProvider
              .overrideWithValue(_FakeGetCustomersUseCase()),
        ],
        child: testApp(home: AppShell()),
      ),
    );

    await tester.pumpAndSettle();

    // Todas as abas estão visíveis na barra de navegação.
    for (final label in [
      'Início',
      'Produtos',
      'Vendas',
      'Financeiro',
      'Crédito',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // 'Clientes' aparece na aba E no card de módulo do dashboard.
    expect(find.text('Clientes'), findsWidgets);

    // Navega para a aba de Vendas (lista vazia no fake).
    await tester.tap(find.text('Vendas'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma venda registrada'), findsOneWidget);
  });
}
