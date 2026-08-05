import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:dumbhanengue/data/datasources/local/debt_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/datasources/local/financial_transaction_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/datasources/local/product_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/datasources/local/sale_sqlite_data_source_impl.dart';
import 'package:dumbhanengue/data/repositories/debt_repository_impl.dart';
import 'package:dumbhanengue/data/repositories/financial_transaction_repository_impl.dart';
import 'package:dumbhanengue/data/repositories/product_repository_impl.dart';
import 'package:dumbhanengue/data/repositories/sale_repository_impl.dart';
import 'package:dumbhanengue/domain/entities/debt.dart';
import 'package:dumbhanengue/domain/entities/financial_transaction.dart';
import 'package:dumbhanengue/domain/entities/product.dart';
import 'package:dumbhanengue/domain/entities/sale.dart';
import 'package:dumbhanengue/domain/entities/sale_item.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_debts_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_products_use_case.dart';
import 'package:dumbhanengue/presentation/controllers/account_providers.dart';
import 'package:dumbhanengue/presentation/controllers/auth_providers.dart';
import 'package:dumbhanengue/presentation/controllers/debts_providers.dart';
import 'package:dumbhanengue/presentation/controllers/finance_providers.dart';
import 'package:dumbhanengue/presentation/controllers/products_providers.dart';
import 'package:dumbhanengue/presentation/controllers/sales_providers.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_sqlite.dart';

/// Isolamento por loja no nível de PROVIDER (Fase 2 do multi-tenancy).
///
/// Usa um backend REAL (SQLite) atrás dos casos de uso e verifica a cadeia
/// completa: `activeStoreIdProvider` → provider do módulo → use case →
/// repositório → datasource (filtro `store_id`). Ao trocar a loja ativa,
/// o `productsProvider`, `salesListProvider`, `pendingDebtsProvider` e
/// `transactionsProvider` recarregam e passam a expor APENAS os dados da
/// nova loja — nada da loja anterior vaza.
///
/// ⚠️ Usa `testWidgets` (e não `test`) porque o StreamProvider da sessão
/// só entrega eventos quando o binding de widget bombeia microtasks
/// (`pumpAndSettle`); o banco real é populado fora do FakeAsync via
/// `tester.runAsync`.
void main() {
  Future<void> seedDatabase(Database db) async {
    final productDataSource = ProductSqliteDataSourceImpl(db);
    final saleDataSource = SaleSqliteDataSourceImpl(db);

    await productDataSource.add(Product(
      id: 'p-centro',
      storeId: 'st1',
      name: 'Caneta Centro',
      description: '',
      purchasePrice: 1,
      salePrice: 2,
      stockQuantity: 10,
    ));
    await productDataSource.add(Product(
      id: 'p-shopping',
      storeId: 'st2',
      name: 'Café Shopping',
      description: '',
      purchasePrice: 10,
      salePrice: 15,
      stockQuantity: 10,
    ));

    await saleDataSource.add(Sale(
      id: 's-centro',
      storeId: 'st1',
      items: const [
        SaleItem(productId: 'p1', productName: 'Caneta', quantity: 2, unitPrice: 2),
      ],
      totalAmount: 4,
      paymentMethod: PaymentMethod.cash,
      dateTime: DateTime.now(),
    ));
    await saleDataSource.add(Sale(
      id: 's-shopping',
      storeId: 'st2',
      items: const [
        SaleItem(productId: 'p6', productName: 'Café', quantity: 1, unitPrice: 15),
      ],
      totalAmount: 15,
      paymentMethod: PaymentMethod.pix,
      dateTime: DateTime.now(),
    ));

    final debtDataSource = DebtSqliteDataSourceImpl(db);
    await debtDataSource.add(Debt(
      id: 'd-centro',
      storeId: 'st1',
      personName: 'Cliente Centro',
      amount: 50,
      dueDate: DateTime.now(),
      isCustomerDebt: true,
    ));
    await debtDataSource.add(Debt(
      id: 'd-shopping',
      storeId: 'st2',
      personName: 'Cliente Shopping',
      amount: 80,
      dueDate: DateTime.now(),
      isCustomerDebt: true,
    ));

    final financeDataSource = FinancialTransactionSqliteDataSourceImpl(db);
    await financeDataSource.add(FinancialTransaction(
      id: 't-centro',
      storeId: 'st1',
      description: 'Entrada Centro',
      amount: 100,
      type: TransactionType.income,
      category: 'Venda',
      date: DateTime.now(),
    ));
    await financeDataSource.add(FinancialTransaction(
      id: 't-shopping',
      storeId: 'st2',
      description: 'Entrada Shopping',
      amount: 200,
      type: TransactionType.income,
      category: 'Venda',
      date: DateTime.now(),
    ));
  }

  List<dynamic> overridesFor(Database db) => [
        ...storeContextOverrides(
          stores: const [
            Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
            Store(id: 'st2', tenantId: 'tn1', name: 'Loja Shopping'),
          ],
        ),
        getProductsUseCaseProvider.overrideWithValue(
          GetProductsUseCase(ProductRepositoryImpl(ProductSqliteDataSourceImpl(db))),
        ),
        salesRepositoryProvider.overrideWithValue(
          SaleRepositoryImpl(SaleSqliteDataSourceImpl(db)),
        ),
        getPendingDebtsUseCaseProvider.overrideWithValue(
          GetPendingDebtsUseCase(DebtRepositoryImpl(DebtSqliteDataSourceImpl(db))),
        ),
        financeRepositoryProvider.overrideWithValue(
          FinancialTransactionRepositoryImpl(
            FinancialTransactionSqliteDataSourceImpl(db),
          ),
        ),
      ];

  testWidgets('providers de produtos e vendas expõem apenas a loja ativa',
      (tester) async {
    final db = openTestDatabase();
    addTearDown(db.dispose);

    await tester.runAsync(() => seedDatabase(db));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overridesFor(db)],
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );

    // Resolve a cadeia de contexto (sessão → tenant → lojas) antes de ler
    // os providers de módulo: sem isso o build inicial ainda veria
    // `tenant/stores == null` e `activeStoreIdProvider` retornaria null.
    // O `listen` (a) faz o stream de sessão EMITIR — nada na árvore o
    // escuta — e (b) mantém os providers autoDispose VIVOS durante o
    // teste (um `read` avulso os descartaria logo após resolver).
    final authSub = container.listen(authStateProvider, (_, _) {});
    await tester.pumpAndSettle();
    expect(container.read(authStateProvider).value?.id, '1');

    final tenantSub =
        container.listen(myTenantProvider('1'), (_, _) {});
    final storesSub =
        container.listen(storesProvider('tn1'), (_, _) {});

    final tenant = await tester
        .runAsync(() => container.read(myTenantProvider('1').future));
    expect(tenant?.id, 'tn1');
    final stores = await tester
        .runAsync(() => container.read(storesProvider('tn1').future));
    expect(stores!.map((s) => s.id), ['st1', 'st2']);
    final active = container.read(activeStoreIdProvider('1'));
    expect(active, 'st1');

    addTearDown(() {
      authSub.close();
      tenantSub.close();
      storesSub.close();
    });

    // ── Loja ativa inicial = primeira loja do tenant (st1) ─────────────
    final productsSt1 =
        await tester.runAsync(() => container.read(productsProvider.future));
    final salesSt1 =
        await tester.runAsync(() => container.read(salesListProvider.future));

    expect(productsSt1!.map((p) => p.id), ['p-centro']);
    expect(productsSt1.every((p) => p.storeId == 'st1'), isTrue);
    expect(productsSt1.any((p) => p.id == 'p-shopping'), isFalse,
        reason: 'produto da Loja Shopping vazou para a leitura da Loja Centro');

    expect(salesSt1!.map((s) => s.id), ['s-centro']);
    expect(salesSt1.any((s) => s.id == 's-shopping'), isFalse,
        reason: 'venda da Loja Shopping vazou para a leitura da Loja Centro');

    // ── Fiado e financeiro também escopam pela loja ativa ─────────────
    final debtsSt1 =
        await tester.runAsync(() => container.read(pendingDebtsProvider.future));
    final txSt1 =
        await tester.runAsync(() => container.read(transactionsProvider.future));

    expect(debtsSt1!.map((d) => d.id), ['d-centro']);
    expect(debtsSt1.any((d) => d.id == 'd-shopping'), isFalse,
        reason: 'fiado da Loja Shopping vazou para a leitura da Loja Centro');

    expect(txSt1!.map((t) => t.id), ['t-centro']);
    expect(txSt1.any((t) => t.id == 't-shopping'), isFalse,
        reason: 'movimento da Loja Shopping vazou para a leitura da Loja Centro');

    // ── Troca a loja ativa para st2 pelo seletor ──────────────────────
    container.read(activeStoreIdProvider('1').notifier).select('st2');
    await tester.pumpAndSettle();

    final productsSt2 =
        await tester.runAsync(() => container.read(productsProvider.future));
    final salesSt2 =
        await tester.runAsync(() => container.read(salesListProvider.future));

    expect(productsSt2!.map((p) => p.id), ['p-shopping']);
    expect(productsSt2.every((p) => p.storeId == 'st2'), isTrue);
    expect(productsSt2.any((p) => p.id == 'p-centro'), isFalse,
        reason: 'produto da Loja Centro vazou para a leitura da Loja Shopping');

    expect(salesSt2!.map((s) => s.id), ['s-shopping']);
    expect(salesSt2.any((s) => s.id == 's-centro'), isFalse,
        reason: 'venda da Loja Centro vazou para a leitura da Loja Shopping');

    final debtsSt2 =
        await tester.runAsync(() => container.read(pendingDebtsProvider.future));
    final txSt2 =
        await tester.runAsync(() => container.read(transactionsProvider.future));

    expect(debtsSt2!.map((d) => d.id), ['d-shopping']);
    expect(debtsSt2.any((d) => d.id == 'd-centro'), isFalse,
        reason: 'fiado da Loja Centro vazou para a leitura da Loja Shopping');

    expect(txSt2!.map((t) => t.id), ['t-shopping']);
    expect(txSt2.any((t) => t.id == 't-centro'), isFalse,
        reason: 'movimento da Loja Centro vazou para a leitura da Loja Shopping');
  });

  testWidgets('voltar para a loja anterior restaura apenas os dados dela',
      (tester) async {
    final db = openTestDatabase();
    addTearDown(db.dispose);

    await tester.runAsync(() => seedDatabase(db));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...overridesFor(db)],
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SizedBox)),
    );

    // Resolve a cadeia de contexto (mesmo motivo do teste anterior):
    // escuta a sessão para o stream emitir + mantém os providers
    // autoDispose vivos via `listen`.
    final authSub = container.listen(authStateProvider, (_, _) {});
    await tester.pumpAndSettle();

    final tenantSub =
        container.listen(myTenantProvider('1'), (_, _) {});
    final storesSub =
        container.listen(storesProvider('tn1'), (_, _) {});
    await tester.runAsync(() => container.read(myTenantProvider('1').future));
    await tester.runAsync(() => container.read(storesProvider('tn1').future));
    expect(container.read(activeStoreIdProvider('1')), 'st1');

    addTearDown(() {
      authSub.close();
      tenantSub.close();
      storesSub.close();
    });

    // st1 → st2 → st1: o isolamento vale nos dois sentidos.
    final first =
        await tester.runAsync(() => container.read(productsProvider.future));
    expect(first!.map((p) => p.id), ['p-centro']);

    container.read(activeStoreIdProvider('1').notifier).select('st2');
    await tester.pumpAndSettle();
    final second =
        await tester.runAsync(() => container.read(productsProvider.future));
    expect(second!.map((p) => p.id), ['p-shopping']);

    container.read(activeStoreIdProvider('1').notifier).select('st1');
    await tester.pumpAndSettle();
    final third =
        await tester.runAsync(() => container.read(productsProvider.future));
    expect(third!.map((p) => p.id), ['p-centro']);
  });
}
