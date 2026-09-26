import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/haptic_spy.dart';
import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/debt.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/purchase.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/repositories/i_debt_processor.dart';
import 'package:tareqo/domain/repositories/i_purchase_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/add_debt_use_case.dart';
import 'package:tareqo/domain/usecases/add_purchase_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/domain/usecases/update_product_stock_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/purchases_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/credit/add_debt_sheet.dart';
import 'package:tareqo/presentation/screens/purchases/add_purchase_sheet.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';
import 'package:tareqo/presentation/widgets/app_sheet.dart';

/// Contrato de fiação da camada de haptics (commit 9c8e550 + complementos):
/// cada fluxo de DINHEIRO confirma com [Haptics.success] e falha bloqueante
/// com [Haptics.error]; os steppers do balcão/buy com [Haptics.selection].
/// O espia prova os disparos reais no canal — sem tocar na plataforma.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HapticSpy spy;
  setUp(() => spy = HapticSpy()..install());
  tearDown(() => spy.uninstall());

  group('PDV (new_sale_sheet)', () {
    testWidgets(
      'stepper dispara selectionClick e sucesso dispara mediumImpact',
      (tester) async {
        await _pumpPdv(tester);

        // A SliverList é lazy: rola até a linha do produto entrar em cena.
        await tester.scrollUntilVisible(
          find.text('Caneta'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final before = spy.selectionClicks;
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pump();
        expect(spy.selectionClicks, greaterThan(before));

        // Venda concluída: mediumImpact (Haptics.success) — o vendedor sente a
        // confirmação sem olhar a tela.
        await tester.tap(find.text('Confirmar venda'));
        await tester.pumpAndSettle();
        expect(spy.mediumImpacts, 1);
      },
    );

    testWidgets('erro bloqueante do use case dispara vibrate', (tester) async {
      // Insuficiência de stock: erro de negócio que exige atenção.
      final processSale = _FakeProcessSaleUseCase(
        const InsufficientStockException(
          productId: 'p1',
          available: 0,
          requested: 1,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...storeContextOverrides(),
            getProductsUseCaseProvider.overrideWithValue(_CatalogUseCase()),
            processSaleUseCaseProvider.overrideWithValue(processSale),
            salesRepositoryProvider.overrideWithValue(_FakeSalesRepository()),
          ],
          child: testApp(home: const Scaffold(body: NewSaleSheet())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Caneta'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();

      expect(processSale.calls, 1);
      expect(spy.vibrates, 1);
    });
  });

  group('compra (add_purchase_sheet)', () {
    testWidgets(
      'stepper dispara selectionClick e sucesso dispara mediumImpact',
      (tester) async {
        final processPurchase = _FakeProcessPurchaseUseCase();
        await _pumpPurchaseSheet(tester, processPurchase);

        final before = spy.selectionClicks;
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pump();
        expect(spy.selectionClicks, greaterThan(before));

        await tester.enterText(
          find.widgetWithText(TextField, 'Fornecedor'),
          'Distribuidora',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
        await tester.pumpAndSettle();

        expect(processPurchase.calls, 1);
        expect(spy.mediumImpacts, 1);
      },
    );

    testWidgets('erro do use case dispara vibrate e mantém o sheet aberto', (
      tester,
    ) async {
      final processPurchase = _FakeProcessPurchaseUseCase(
        const ProductNotFoundException('p1'),
      );
      await _pumpPurchaseSheet(tester, processPurchase);

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Fornecedor'),
        'Distribuidora',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar compra'));
      await tester.pumpAndSettle();

      expect(find.byType(AddPurchaseSheet), findsOneWidget);
      expect(spy.mediumImpacts, 0);
      expect(spy.vibrates, 1);
    });
  });

  group('fiado (add_debt_sheet)', () {
    testWidgets('sucesso dispara mediumImpact (antes do pop)', (tester) async {
      final addDebt = _FakeAddDebtUseCase();
      await _pumpDebtSheet(tester, addDebt);

      await tester.enterText(find.byType(TextFormField).at(0), 'Maria Souza');
      await tester.enterText(find.byType(TextFormField).at(1), '50,00');
      await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
      await tester.pumpAndSettle();

      expect(addDebt.calls, 1);
      expect(spy.mediumImpacts, 1);
    });

    testWidgets('valor inválido do use case dispara vibrate', (tester) async {
      final addDebt = _FakeAddDebtUseCase(
        const InvalidDebtAmountException(
          'O valor da dívida deve ser maior que zero.',
        ),
      );
      await _pumpDebtSheet(tester, addDebt);

      await tester.enterText(find.byType(TextFormField).at(0), 'Maria');
      await tester.enterText(find.byType(TextFormField).at(1), '50,00');
      await tester.tap(find.widgetWithText(FilledButton, 'Registar fiado'));
      await tester.pumpAndSettle();

      expect(addDebt.calls, 1);
      expect(spy.mediumImpacts, 0);
      expect(spy.vibrates, 1);
    });
  });
}

// ── Fakes e helpers ─────────────────────────────────────────────────────────

class _CatalogUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
    Product(
      id: 'p1',
      name: 'Caneta',
      purchasePriceCents: 50,
      salePriceCents: 200,
      stockQuantity: 10,
    ),
  ];
}

class _FakeProcessPurchaseUseCase implements ProcessPurchaseUseCase {
  _FakeProcessPurchaseUseCase([this._error]);

  final Object? _error;
  int calls = 0;

  @override
  Future<void> call(Purchase purchase) async {
    calls++;
    final e = _error;
    if (e != null) throw e;
  }

  @override
  IPurchaseAtomicProcessor? get processor => null;
}

class _FakeProcessSaleUseCase implements ProcessSaleUseCase {
  _FakeProcessSaleUseCase([this._error]);

  final Object? _error;
  int calls = 0;

  @override
  Future<void> call(Sale sale) async {
    calls++;
    final e = _error;
    if (e != null) throw e;
  }

  @override
  ISaleAtomicProcessor? get processor => null;
}

class _FakeSalesRepository implements ISaleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Sale>> getAll({required String storeId}) async => const [];
}

class _FakeAddDebtUseCase implements AddDebtUseCase {
  _FakeAddDebtUseCase([this._error]);

  final Object? _error;
  int calls = 0;

  @override
  Future<void> call(Debt debt) async {
    calls++;
    final e = _error;
    if (e != null) throw e;
  }

  @override
  IDebtAtomicProcessor? get processor => null;
}

class _FakeCustomersNotifier extends CustomersNotifier {
  @override
  Future<List<Customer>> build() async => const [
    Customer(id: 'c1', name: 'Maria Souza'),
  ];
}

Future<void> _pumpPdv(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        getProductsUseCaseProvider.overrideWithValue(_CatalogUseCase()),
        processSaleUseCaseProvider.overrideWithValue(_FakeProcessSaleUseCase()),
        salesRepositoryProvider.overrideWithValue(_FakeSalesRepository()),
      ],
      child: testApp(home: const Scaffold(body: NewSaleSheet())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPurchaseSheet(
  WidgetTester tester,
  _FakeProcessPurchaseUseCase processPurchase,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        getProductsUseCaseProvider.overrideWithValue(_CatalogUseCase()),
        processPurchaseUseCaseProvider.overrideWithValue(processPurchase),
      ],
      child: testApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showAppSheet<void>(
                  context,
                  builder: (_) => const AddPurchaseSheet(),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

Future<void> _pumpDebtSheet(
  WidgetTester tester,
  _FakeAddDebtUseCase addDebt,
) async {
  final container = ProviderContainer(
    overrides: [
      addDebtUseCaseProvider.overrideWithValue(addDebt),
      customersProvider.overrideWith(_FakeCustomersNotifier.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      // Rota real: o sucesso dá pop antes do snackbar (mesmo padrão do
      // add_debt_sheet_test.dart).
      child: testApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: AddDebtSheet()),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}
