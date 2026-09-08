import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/custom_invoice_sqlite_data_source_impl.dart';
import 'package:tareqo/data/repositories/custom_invoice_repository_impl.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/presentation/controllers/custom_invoice_providers.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/screens/addons/custom_invoice_screen.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_sqlite.dart';

/// Catálogo real mínimo — a sheet só permite adicionar itens quando há
/// produto activo seleccionado (sem produtos, não há como criar).
class _FakeGetProductsUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
    Product(
      id: 'p1',
      name: 'Caneta',
      purchasePriceCents: 100,
      salePriceCents: 200,
      stockQuantity: 1000,
    ),
  ];
}

/// Sem clientes cadastrados — a sheet cai no campo manual "Nome do
/// cliente" (caminho mais directo de preencher no teste).
class _EmptyCustomersUseCase implements GetCustomersUseCase {
  @override
  Future<List<Customer>> call({required String storeId}) async => const [];
}

/// Monta a tela com o REPOSITÓRIO REAL sobre um SQLite em memória — o
/// fluxo testado é o de produção (sem fakes no caminho de persistência).
Future<void> _pumpInvoice(WidgetTester tester, Database db) async {
  final repo = CustomInvoiceRepositoryImpl(
    CustomInvoiceSqliteDataSourceImpl(db),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        customInvoiceRepositoryProvider.overrideWithValue(repo),
        getProductsUseCaseProvider.overrideWithValue(_FakeGetProductsUseCase()),
        getCustomersUseCaseProvider.overrideWithValue(_EmptyCustomersUseCase()),
      ],
      child: testApp(home: const CustomInvoiceScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Cria uma factura inteira pela UI (FAB → cliente → produto → item →
/// criar). O número sequencial é atribuído pelo BANCO, não pela UI.
Future<void> _createInvoice(
  WidgetTester tester, {
  required String clientName,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  // Cliente manual (sem clientes cadastrados → campo de texto).
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Nome do cliente'),
    clientName,
  );

  // Produto do catálogo → preço é pré-preenchido (200 MT = 20000 centavos).
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Caneta').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Adicionar'));
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Criar Factura'));
  await tester.tap(find.text('Criar Factura'));
  await tester.pumpAndSettle();
}

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  testWidgets(
    'cria factura pela UI e PERSISTE no SQLite (reabre e continua lá)',
    (tester) async {
      await _pumpInvoice(tester, db);

      // Estado vazio honesto (nada em memória).
      expect(find.text('Nenhuma factura'), findsOneWidget);

      await _createInvoice(tester, clientName: 'João Silva');

      // Snackbar com o número SEQUENCIAL real (1 = primeira da loja).
      expect(find.text('Factura nº 1 criada!'), findsOneWidget);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Nº 00001'), findsOneWidget);

      // ── Prova de persistência: árvore NOVA, mesmo banco → a factura vem
      // do SQLite (não de estado do widget). Número e cliente intactos.
      await _pumpInvoice(tester, db);
      expect(find.text('Nenhuma factura'), findsNothing);
      expect(find.text('João Silva'), findsOneWidget);
      expect(find.text('Nº 00001'), findsOneWidget);
    },
  );

  testWidgets('números sequenciais por loja (MAX+1 real no banco)', (
    tester,
  ) async {
    await _pumpInvoice(tester, db);

    await _createInvoice(tester, clientName: 'Ana Souza');
    expect(find.text('Factura nº 1 criada!'), findsOneWidget);

    // Snackbars enfileiram (4s): expira a anterior antes da segunda.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await _createInvoice(tester, clientName: 'Bruno Lima');
    expect(find.text('Factura nº 2 criada!'), findsOneWidget);

    // Ambas persistidas lado a lado.
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Bruno Lima'), findsOneWidget);
    expect(find.text('Nº 00001'), findsOneWidget);
    expect(find.text('Nº 00002'), findsOneWidget);
  });

  testWidgets('botão criar só habilita com cliente e item válidos', (
    tester,
  ) async {
    await _pumpInvoice(tester, db);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Sem cliente e sem itens o botão fica desabilitado.
    final createButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Criar Factura'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(createButton.onPressed, isNull);
  });

  testWidgets('nome de cliente longo nunca trunca nem estoura o card', (
    tester,
  ) async {
    await _pumpInvoice(tester, db);

    // Nome suficientemente longo para expor truncatura/overflow — o card
    // deve quebrar o texto em linhas e renderizar SEM excessões de layout.
    const longName =
        'Cliente Comercial de Teste de Moçambique Limitada — Filial da Avenida';
    await _createInvoice(tester, clientName: longName);

    expect(tester.takeException(), isNull);
    expect(find.text(longName), findsOneWidget);
  });
}
