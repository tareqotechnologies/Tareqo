import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/store_context.dart';
import '../../../helpers/test_app.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/quotation.dart';
import 'package:tareqo/domain/repositories/i_quotation_repository.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/quotation_providers.dart';
import 'package:tareqo/presentation/screens/addons/quotation_screen.dart';

/// Repositório de cotações em memória com contadores de chamadas.
class _FakeQuotationRepository implements IQuotationRepository {
  final List<Quotation> quotations;
  bool throwOnAdd = false;
  bool throwOnUpdate = false;
  int addCalls = 0;
  int updateCalls = 0;
  Quotation? lastAdded;
  Quotation? lastUpdated;

  _FakeQuotationRepository(this.quotations);

  @override
  Future<List<Quotation>> getByStore(String storeId) async =>
      List.of(quotations)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<Quotation> add(Quotation quotation) async {
    addCalls++;
    if (throwOnAdd) throw Exception('falha ao gravar');
    lastAdded = quotation;
    quotations.add(quotation);
    return quotation;
  }

  @override
  Future<Quotation> update(Quotation quotation) async {
    updateCalls++;
    if (throwOnUpdate) throw Exception('falha ao atualizar');
    lastUpdated = quotation;
    return quotation;
  }
}

class _FailingQuotationRepository implements IQuotationRepository {
  @override
  Future<List<Quotation>> getByStore(String storeId) async =>
      throw Exception('falha de rede');

  @override
  Future<Quotation> add(Quotation quotation) async =>
      throw Exception('falha ao gravar');

  @override
  Future<Quotation> update(Quotation quotation) async =>
      throw Exception('falha ao atualizar');
}

class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

class _FakeGetCustomersUseCase implements GetCustomersUseCase {
  _FakeGetCustomersUseCase(this._customers);

  final List<Customer> _customers;

  @override
  Future<List<Customer>> call({required String storeId}) async => _customers;
}

Product _product({
  String id = 'p1',
  String name = 'Paracetamol',
  int stock = 2500,
  int salePriceCents = 1500,
}) => Product(
  id: id,
  name: name,
  purchasePriceCents: 800,
  salePriceCents: salePriceCents,
  stockQuantity: stock,
);

Quotation _quotation({
  String id = 'qt1',
  int number = 1,
  QuotationStatus status = QuotationStatus.draft,
}) => Quotation(
  id: id,
  number: number,
  storeId: 'st1',
  customerId: 'c1',
  customerName: 'João Silva',
  customerPhone: '841234567',
  items: [
    const QuotationItem(
      productId: 'p1',
      productName: 'Paracetamol',
      quantity: 2000,
      unitPriceCents: 1500,
    ),
  ],
  totalAmountCents: 3000,
  status: status,
  validUntil: DateTime.now().add(const Duration(days: 5)),
  createdAt: DateTime(2026, 9, 1),
);

Widget _buildApp({
  required IQuotationRepository repository,
  List<Product> products = const [],
  List<Customer> customers = const [],
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      quotationRepositoryProvider.overrideWithValue(repository),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(products),
      ),
      getCustomersUseCaseProvider.overrideWithValue(
        _FakeGetCustomersUseCase(customers),
      ),
    ],
    child: testApp(
      home: const QuotationScreen(),
      // Fonte de teste Ahem é mais larga que a Outfit — clamp compensa.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 0.6, child: child!),
    ),
  );
}

void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1250, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Selecciona o produto no dropdown da sheet (último dropdown da coluna).
Future<void> _selectProduct(WidgetTester tester, String productName) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(productName).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista vazia mostra estado vazio', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FakeQuotationRepository([])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma cotação'), findsOneWidget);
    expect(
      find.text('Crie cotações e orçamentos para os seus clientes'),
      findsOneWidget,
    );
  });

  testWidgets('card de cotação mostra número, itens, validade e total', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FakeQuotationRepository([_quotation()])),
    );
    await tester.pumpAndSettle();

    expect(find.text('João Silva'), findsOneWidget);
    // Nº com padLeft(5) + telefone.
    expect(find.textContaining('Nº 00001'), findsOneWidget);
    expect(find.textContaining('841234567'), findsOneWidget);
    // "1 item • Validade: 5 dias • total".
    expect(find.textContaining('1 item'), findsOneWidget);
    expect(find.textContaining('2 itens'), findsNothing);
    expect(find.textContaining('30,00'), findsOneWidget);
    // Rascunho: chip + botão Enviar (sem Aceitar/Rejeitar).
    expect(find.text('Rascunho'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
    expect(find.text('Aceitar'), findsNothing);
  });

  testWidgets('status enviada mostra Aceitar/Rejeitar em vez de Enviar', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeQuotationRepository([
          _quotation(status: QuotationStatus.sent),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('Enviar'), findsNothing);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Rejeitar'), findsOneWidget);
  });

  testWidgets('erro de carga mostra EmptyState com retry', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FailingQuotationRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as cotações.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    // Retry com o repositório ainda a falhar — erro persiste (sem crash).
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar as cotações.'), findsOneWidget);
  });

  testWidgets('enviar cotação rascunho persiste a transição de estado', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeQuotationRepository([_quotation()]);
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.lastUpdated?.status, QuotationStatus.sent);
    expect(repository.lastUpdated?.sentAt, isNotNull);
    expect(find.text('Estado da cotação atualizado'), findsOneWidget);
  });

  testWidgets('erro na transição de estado mostra snackbar de erro', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeQuotationRepository([_quotation()])
      ..throwOnUpdate = true;
    await tester.pumpWidget(_buildApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(
      find.text('Não foi possível atualizar a cotação. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Estado da cotação atualizado'), findsNothing);
  });

  testWidgets('criar cotação via sheet: cliente, produto e guardar', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeQuotationRepository([]);
    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        products: [_product()],
        customers: const [
          Customer(id: 'c1', name: 'Maria Costa', phone: '879999999'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nova Cotação'));
    await tester.pumpAndSettle();

    // Selecciona cliente no dropdown → nome e telefone preenchidos.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Maria Costa (879999999)'), findsWidgets);
    await tester.tap(find.text('Maria Costa (879999999)').last);
    await tester.pumpAndSettle();

    // Selecciona produto → preço preenchido automaticamente (1500¢ → 15.00).
    await _selectProduct(tester, 'Paracetamol');
    expect(find.text('15.00'), findsOneWidget);

    // Quantidade 2 (3º TextField da sheet: phone, price, qty).
    await tester.enterText(find.byType(TextField).at(2), '2');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Paracetamol x2'), findsOneWidget);
    expect(find.textContaining('30,00'), findsWidgets);

    // Salva.
    await tester.tap(find.text('Guardar Cotação'));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    // Quantidade em MILÉSIMOS: 2 × 1000.
    expect(repository.lastAdded?.items.first.quantity, 2000);
    // Total em centavos reais: qty(2000 milésimos = 2 un) × 1500¢ = 3000
    // (regressão do bug de unidades — antes gravava 3.000.000).
    expect(repository.lastAdded?.totalAmountCents, 3000);
    expect(repository.lastAdded?.customerId, 'c1');
    expect(find.textContaining('criada!'), findsOneWidget);
  });

  testWidgets('sem clientes: campo de texto livre e guardar desabilitado', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeQuotationRepository([]),
        products: [_product()],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nova Cotação'));
    await tester.pumpAndSettle();

    // Sem clientes → AppTextField de nome livre (label do campo).
    expect(find.text('Nome do cliente'), findsOneWidget);
    // Botão guardar desabilitado sem cliente e sem itens.
    final saveButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Guardar Cotação'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('template settings abre e salva configuração', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FakeQuotationRepository([])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modelo da Cotação'));
    await tester.pumpAndSettle();

    expect(find.text('Modelo da Cotação'), findsOneWidget);
    expect(find.text('Logotipo da Empresa'), findsOneWidget);
    expect(find.text('Cor Principal'), findsOneWidget);
    expect(find.text('Dados da Empresa'), findsOneWidget);

    // Preenche o nome da empresa e salva.
    await tester.enterText(find.byType(TextField).first, 'Farmácia Vida, Lda');
    await tester.tap(find.text('Guardar Modelo'));
    await tester.pumpAndSettle();

    expect(find.text('Modelo guardado com sucesso'), findsOneWidget);
  });
}
