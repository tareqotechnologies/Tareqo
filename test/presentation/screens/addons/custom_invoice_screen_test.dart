import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/store_context.dart';
import '../../../helpers/test_app.dart';

import 'package:tareqo/core/utils/formatters.dart';
import 'package:tareqo/domain/entities/custom_invoice.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/repositories/i_custom_invoice_repository.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/presentation/controllers/custom_invoice_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/screens/addons/custom_invoice_screen.dart';

/// Repositório de facturas personalizadas em memória.
class _FakeCustomInvoiceRepository implements ICustomInvoiceRepository {
  final List<CustomInvoice> invoices;
  bool throwOnAdd = false;
  int addCalls = 0;
  CustomInvoice? lastAdded;

  _FakeCustomInvoiceRepository(this.invoices);

  @override
  Future<List<CustomInvoice>> getByStore(String storeId) async =>
      List.of(invoices)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<CustomInvoice> add(CustomInvoice invoice) async {
    addCalls++;
    if (throwOnAdd) throw Exception('falha ao gravar');
    lastAdded = invoice;
    invoices.add(invoice);
    return invoice;
  }
}

class _FailingCustomInvoiceRepository implements ICustomInvoiceRepository {
  @override
  Future<List<CustomInvoice>> getByStore(String storeId) async =>
      throw Exception('falha de rede');

  @override
  Future<CustomInvoice> add(CustomInvoice invoice) async =>
      throw Exception('falha ao gravar');
}

class _FakeGetProductsUseCase implements GetProductsUseCase {
  _FakeGetProductsUseCase(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

Product _product({
  String id = 'p1',
  String name = 'Paracetamol',
  int salePriceCents = 1500,
}) => Product(
  id: id,
  name: name,
  purchasePriceCents: 800,
  salePriceCents: salePriceCents,
  stockQuantity: 2500,
);

CustomInvoice _invoice({
  String id = 'ci1',
  int number = 1,
  int discountCents = 0,
  int taxCents = 0,
}) => CustomInvoice(
  id: id,
  number: number,
  storeId: 'st1',
  clientName: 'João Silva',
  clientPhone: '841234567',
  items: [
    // Convenção W11: quantidade em MILÉSIMOS (2 un = 2000).
    const CustomInvoiceItem(
      productName: 'Paracetamol',
      quantity: 2000,
      unitPriceCents: 1500,
      subtotalCents: 3000,
    ),
  ],
  totalAmountCents: 3000 - discountCents + taxCents,
  discountCents: discountCents,
  taxCents: taxCents,
  createdAt: DateTime(2026, 9, 1),
);

Widget _buildApp({
  required ICustomInvoiceRepository repository,
  List<Product> products = const [],
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      customInvoiceRepositoryProvider.overrideWithValue(repository),
      getProductsUseCaseProvider.overrideWithValue(
        _FakeGetProductsUseCase(products),
      ),
    ],
    child: testApp(
      home: const CustomInvoiceScreen(),
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

void main() {
  testWidgets('lista vazia mostra estado vazio', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FakeCustomInvoiceRepository([])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma factura'), findsOneWidget);
    expect(find.textContaining('facturas profissionais'), findsOneWidget);
  });

  testWidgets('card mostra número, telefone, itens e total', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FakeCustomInvoiceRepository([_invoice()])),
    );
    await tester.pumpAndSettle();

    expect(find.text('João Silva'), findsOneWidget);
    expect(find.textContaining('Nº 00001'), findsOneWidget);
    // Metadados numa linha única: itens • telefone (card minimalista).
    expect(find.textContaining('841234567'), findsOneWidget);
    expect(find.textContaining('1 item'), findsOneWidget);
    expect(find.textContaining('30,00'), findsOneWidget);
    // Ações do card MINIMALISTA: ícones com tooltip (não botões com
    // rótulo — sem Enviar; factura não tem transição de estado).
    expect(find.byTooltip('WhatsApp'), findsOneWidget);
    expect(find.byTooltip('PDF'), findsOneWidget);
  });

  testWidgets('card paga com desconto mostra total líquido', (tester) async {
    _useWideViewport(tester);
    // 3000 − 500 + 300 = 2800 → "28,00".
    await tester.pumpWidget(
      _buildApp(
        repository: _FakeCustomInvoiceRepository([
          _invoice(discountCents: 500, taxCents: 300),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('28,00'), findsOneWidget);
    expect(find.textContaining('30,00'), findsNothing);
  });

  testWidgets('erro de carga mostra EmptyState com retry', (tester) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FailingCustomInvoiceRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar as facturas.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    // Retry com o repositório ainda a falhar — erro persiste (sem crash).
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar as facturas.'), findsOneWidget);
  });

  testWidgets('criar factura: produto, qty, desconto, IVA e guardar', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeCustomInvoiceRepository([]);
    await tester.pumpWidget(
      _buildApp(repository: repository, products: [_product()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nova Factura'));
    await tester.pumpAndSettle();

    // Sem clientes: campo livre para o nome.
    await tester.enterText(find.byType(TextField).at(0), 'Maria Costa');
    await tester.enterText(find.byType(TextField).at(1), '879999999');

    // Selecciona produto → preço preenchido (1500¢ → 15.00).
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol').last);
    await tester.pumpAndSettle();
    expect(find.text('15.00'), findsOneWidget);

    // Qty 2 (ordem: nome, telefone, NIF, preço, qty).
    await tester.enterText(find.byType(TextField).at(4), '2');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Paracetamol x2'), findsOneWidget);

    // Desconto 5,00 e IVA 3,00 — os campos só EXISTEM com item na lista
    // (estão dentro do bloco `if (_items.isNotEmpty)`): índices 5 e 6.
    await tester.enterText(find.byType(TextField).at(5), '5');
    await tester.enterText(find.byType(TextField).at(6), '3');

    // O total e o botão guardar só re-avaliam no próximo setState (em
    // produção o teclado dispara via viewInsets). Re-selecionar o produto
    // é o setState mais limpo disponível — repõe o preço (15.00) sem
    // alterar o resto.
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol').last);
    await tester.pumpAndSettle();

    // Subtotal 30 − 5 + 3 = 28,00.
    expect(find.textContaining('28,00'), findsWidgets);

    await tester.tap(find.text('Criar Factura'));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    // Desconto/IVA em CENTAVOS (bug de precedência ?? corrigido na tela).
    expect(repository.lastAdded?.discountCents, 500);
    expect(repository.lastAdded?.taxCents, 300);
    expect(repository.lastAdded?.totalAmountCents, 2800);
    expect(repository.lastAdded?.clientTaxId, '');
    expect(find.textContaining('criada!'), findsOneWidget);
  });

  testWidgets('erro ao guardar mostra snackbar e mantém a sheet', (
    tester,
  ) async {
    _useWideViewport(tester);
    final repository = _FakeCustomInvoiceRepository([])..throwOnAdd = true;
    await tester.pumpWidget(
      _buildApp(repository: repository, products: [_product()]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Nova Factura'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Maria Costa');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paracetamol').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(3), '2');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Criar Factura'));
    await tester.pumpAndSettle();

    expect(repository.addCalls, 1);
    expect(
      find.text('Não foi possível criar a factura. Tente novamente.'),
      findsOneWidget,
    );
    // Sheet continua aberta (o texto da sheet continua visível).
    expect(find.text('Criar Factura'), findsOneWidget);
  });

  testWidgets('template settings abre, muda cor e salva', (tester) async {
    _useWideViewport(tester);
    // Moeda do mercado do produto (MZN): o preview reflete a moeda ativa
    // via Formatters (o harness não passa pelo bootstrap do app). Reset
    // no teardown para não vazar o estado estático entre testes.
    Formatters.applySettings(currencyCode: 'MZN', language: 'pt');
    addTearDown(
      () => Formatters.applySettings(currencyCode: 'BRL', language: 'pt'),
    );
    await tester.pumpWidget(
      _buildApp(repository: _FakeCustomInvoiceRepository([])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modelo da Factura'));
    await tester.pumpAndSettle();

    expect(find.text('Modelo da Factura'), findsOneWidget);
    expect(find.text('Logotipo da Empresa'), findsOneWidget);
    expect(find.text('Estilo'), findsOneWidget);
    expect(find.text('Clássico'), findsOneWidget);
    expect(find.text('Moderno'), findsOneWidget);
    expect(find.text('Compacto'), findsOneWidget);
    expect(find.text('Dados da Empresa'), findsOneWidget);

    // Preview embutido no sheet (widget isolado — CustomInvoicePreview).
    // O símbolo agora vem da moeda ativa do tenant (Formatters) — o app
    // exibe o CÓDIGO da moeda (MZN), não 'MT' fixo como antes.
    expect(find.text('FACTURA'), findsOneWidget);
    expect(find.text('CLIENTE'), findsOneWidget);
    expect(find.text('TOTAL: 550,00 MZN'), findsOneWidget);
    // Fallback do nome vazio — aparece no preview interno do sheet E no
    // widget isolado CustomInvoicePreview (2 instâncias).
    expect(find.text('Nome da Empresa'), findsWidgets);

    // Escolhe a cor "Moderno" (segunda pílula de cor) e salva.
    await tester.enterText(find.byType(TextField).first, 'Farmácia Vida');
    await tester.tap(find.text('Guardar Modelo'));
    await tester.pumpAndSettle();

    expect(find.text('Modelo guardado com sucesso'), findsOneWidget);
  });

  testWidgets('trocar estilo do template mantém o sheet aberto', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(repository: _FakeCustomInvoiceRepository([])),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Modelo da Factura'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Moderno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compacto'));
    await tester.pumpAndSettle();

    // Sheet continua aberta com os estilos visíveis.
    expect(find.text('Estilo'), findsOneWidget);
    expect(find.text('Guardar Modelo'), findsOneWidget);
  });
}
