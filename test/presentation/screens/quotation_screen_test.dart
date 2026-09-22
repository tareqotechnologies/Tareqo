import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:tareqo/data/datasources/local/quotation_sqlite_data_source_impl.dart';
import 'package:tareqo/data/repositories/quotation_repository_impl.dart';
import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/usecases/get_customers_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/quotation_providers.dart';
import 'package:tareqo/presentation/screens/addons/quotation_screen.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_sqlite.dart';

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

class _EmptyCustomersUseCase implements GetCustomersUseCase {
  @override
  Future<List<Customer>> call({required String storeId}) async => const [];
}

/// Fake do [PathProviderPlatform] — diretório temporário real para o
/// exporter gravar o PDF antes do share sheet.
class _TempDirPathProvider extends PathProviderPlatform {
  _TempDirPathProvider(this.tempDir);

  final Directory tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

/// Monta a tela com o REPOSITÓRIO REAL sobre um SQLite em memória — a
/// criação E as transições de estado passam pelo banco de verdade.
Future<void> _pumpQuotation(WidgetTester tester, Database db) async {
  final repo = QuotationRepositoryImpl(QuotationSqliteDataSourceImpl(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        quotationRepositoryProvider.overrideWithValue(repo),
        getProductsUseCaseProvider.overrideWithValue(_FakeGetProductsUseCase()),
        getCustomersUseCaseProvider.overrideWithValue(_EmptyCustomersUseCase()),
      ],
      child: testApp(home: const QuotationScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Cria uma cotação inteira pela UI (FAB → cliente → produto → item →
/// guardar). Número sequencial atribuído pelo banco; estado inicial = rascunho.
Future<void> _createQuotation(
  WidgetTester tester, {
  required String clientName,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextFormField, 'Nome do cliente'),
    clientName,
  );

  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Caneta').last);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Adicionar'));
  await tester.pumpAndSettle();

  await tester.ensureVisible(find.text('Guardar Cotação'));
  await tester.tap(find.text('Guardar Cotação'));
  await tester.pumpAndSettle();
}

void main() {
  late Database db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  testWidgets('cria cotação pela UI e PERSISTE no SQLite', (tester) async {
    await _pumpQuotation(tester, db);

    // Estado vazio honesto.
    expect(find.text('Nenhuma cotação'), findsOneWidget);

    await _createQuotation(tester, clientName: 'João Silva');

    // Número sequencial real + card em estado Rascunho.
    expect(find.text('Cotação nº 1 criada!'), findsOneWidget);
    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('Rascunho'), findsOneWidget);
    expect(find.text('Nº 00001'), findsOneWidget);

    // ── Prova de persistência: árvore NOVA, mesmo banco.
    await _pumpQuotation(tester, db);
    expect(find.text('Nenhuma cotação'), findsNothing);
    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('Nº 00001'), findsOneWidget);
  });

  testWidgets('transição rascunho → enviada PERSISTE no SQLite', (
    tester,
  ) async {
    await _pumpQuotation(tester, db);
    await _createQuotation(tester, clientName: 'João Silva');

    // Estado inicial: rascunho, com o botão Enviar disponível.
    expect(find.text('Rascunho'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);

    // Snackbar da criação ainda enfileirada (4s): expira antes de enviar
    // para a do estado não ficar bloqueada.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Envia → a transição é GRAVADA no repositório (nunca mutação local).
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('Estado da cotação atualizado'), findsOneWidget);

    // ── Prova de persistência: árvore NOVA, mesmo banco → a transição
    // veio do SQLite. Sem botão Enviar; acções de enviada (aceitar/rejeitar).
    await _pumpQuotation(tester, db);
    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('Rascunho'), findsNothing);
    expect(find.text('Enviar'), findsNothing);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Rejeitar'), findsOneWidget);
  });

  testWidgets('botão guardar só habilita com cliente e item válidos', (
    tester,
  ) async {
    await _pumpQuotation(tester, db);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Guardar Cotação'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('nome de cliente longo nunca trunca nem estoura o card', (
    tester,
  ) async {
    await _pumpQuotation(tester, db);

    // Nome suficientemente longo para expor truncatura/overflow — o card
    // deve quebrar o texto em linhas e renderizar SEM excessões de layout.
    const longName =
        'Cliente Comercial de Teste de Moçambique Limitada — Filial da Avenida';
    await _createQuotation(tester, clientName: longName);

    expect(tester.takeException(), isNull);
    expect(find.text(longName), findsOneWidget);
  });

  testWidgets(
    'partilha WhatsApp monta a mensagem com cliente, validade e total',
    (tester) async {
      const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final launched = <MethodCall>[];
      messenger.setMockMethodCallHandler(launcherChannel, (call) async {
        launched.add(call);
        return true;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(launcherChannel, null),
      );

      await _pumpQuotation(tester, db);
      await _createQuotation(tester, clientName: 'Maria Chissano');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // when — partilha por WhatsApp.
      // Acções viraram ÍCONES com tooltip (card minimalista V3).
      await tester.tap(find.byTooltip('WhatsApp'));
      await tester.pumpAndSettle();

      // then — wa.me aberto com a mensagem montada (URL-encoded). O
      // url_launcher envia os argumentos como Map {url: ...}.
      expect(launched, hasLength(1));
      final args = Map<String, dynamic>.from(launched.single.arguments as Map);
      final url = Uri.parse(args['url'] as String);
      expect(url.host, 'wa.me');
      // queryParameters já devolve o valor decodificado.
      final message = url.queryParameters['text']!;
      expect(message, contains('Maria Chissano'));
      expect(message, contains('TOTAL'));
      expect(message, contains('Caneta'));
      expect(message, contains('dias'));
    },
  );

  testWidgets('exportação PDF partilha o arquivo da cotação persistida', (
    tester,
  ) async {
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <Map<String, dynamic>>[];
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      calls.add(Map<String, dynamic>.from(call.arguments as Map));
      return 'dev.fluttercommunity.plus/share/dismissed';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(shareChannel, null));

    // path_provider falso (padrão dos testes de share): o exporter grava
    // o PDF num diretório temporário REAL antes de partilhar. createTempSync/
    // deleteSync: IO real dentro da fake-async zone só é seguro se for
    // síncrono — futures de IO real nunca completam ali.
    final tempDir = Directory.systemTemp.createTempSync('tareqo_quote_ui');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final originalPP = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TempDirPathProvider(tempDir);
    addTearDown(() => PathProviderPlatform.instance = originalPP);

    await _pumpQuotation(tester, db);
    await _createQuotation(tester, clientName: 'Maria Chissano');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // when — exporta PDF. O handler da tela faz IO real (grava o PDF) e
    // depois partilha; dentro da fake-async zone isso nunca completaria.
    // O tap + espera acontecem dentro de runAsync (contexto real), com
    // espera por CONDIÇÃO (calls não vazio) — sem delays fixos.
    await tester.runAsync(() async {
      // Acções viraram ÍCONES com tooltip (card minimalista V3).
      await tester.tap(find.byTooltip('PDF'));
      for (var i = 0; i < 100 && calls.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();

    // then — share sheet com o PDF da cotação nº 1.
    expect(calls, hasLength(1));
    final paths = (calls.single['paths'] as List).cast<String>();
    expect(paths.single, endsWith('.pdf'));
    expect(calls.single['subject'], contains('Nº 00001'));
    expect(File(paths.single).lengthSync(), greaterThan(500));
  });

  testWidgets('transição enviada → aceite PERSISTE (fluxo de negociação)', (
    tester,
  ) async {
    await _pumpQuotation(tester, db);
    await _createQuotation(tester, clientName: 'Maria Chissano');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();

    // then — estado aceite gravado no repositório real (árvore nova).
    await _pumpQuotation(tester, db);
    expect(find.text('Aceite'), findsOneWidget);
    expect(find.text('Enviada'), findsNothing);
  });
}
