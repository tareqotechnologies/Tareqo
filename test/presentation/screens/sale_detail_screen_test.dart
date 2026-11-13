import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/theme/app_colors.dart';
import 'package:tareqo/core/theme/app_tokens.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';

import 'package:tareqo/core/security/biometric_service.dart';
import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/core/share/receipt_sharer.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/entities/sale_item.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/usecases/biometric_auth_use_case.dart';
import 'package:tareqo/domain/usecases/cancel_sale_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:get_it/get_it.dart';
import 'package:tareqo/presentation/screens/sales/sale_detail_screen.dart';

/// Fake do [ReceiptSharer] — grava as chamadas (share_plus/url_launcher
/// não rodam no ambiente de teste).
class _FakeReceiptSharer implements ReceiptSharer {
  Uint8List? lastImageBytes;
  String? lastSaleId;
  String? lastWhatsAppText;
  bool whatsAppOpened = true;

  @override
  Future<void> shareImage(Uint8List pngBytes, {String saleId = 'venda'}) async {
    lastImageBytes = pngBytes;
    lastSaleId = saleId;
  }

  @override
  Future<bool> shareWhatsApp(String text) async {
    lastWhatsAppText = text;
    return whatsAppOpened;
  }
}

/// Fake do [CancelSaleUseCase] — conta as chamadas (o caminho composto e
/// o processador atômico já são cobertos pelos testes de domínio).
class _FakeCancelSaleUseCase implements CancelSaleUseCase {
  int calls = 0;
  String? lastSaleId;

  @override
  final ISaleCancellationProcessor? processor = null;

  @override
  Future<void> call(String saleId, {required String storeId}) async {
    calls++;
    lastSaleId = saleId;
  }
}

/// Biometria fake para a 2ª barreira da anulação (M4) — mesmo padrão do
/// app_lock_overlay_test: nunca toca no plugin nativo.
///
/// [available] simula aparelho SEM leitor (o fluxo segue só com o diálogo
/// textual); [result] programa o resultado do prompt quando disponível.
class _FakeBiometricService extends BiometricService {
  _FakeBiometricService({this.available = false, this.result = true});

  final bool available;
  final bool result;
  int attempts = 0;

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<bool> authenticate({
    String localizedReason = '',
    String signInTitle = '',
    String biometricHint = '',
    String cancelButton = '',
    String fallbackTitle = '',
    String goToSettingsButton = '',
    String goToSettingsDescription = '',
    String lockOut = '',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    attempts++;
    return result;
  }
}

/// Monta o use case biométrico fake com storage seguro em memória.
/// O service devolvido expõe `attempts` para o teste afirmar o prompt.
({BiometricAuthUseCase useCase, _FakeBiometricService service})
_fakeBiometricUseCase({bool available = false, bool result = true}) {
  registerTestSecureStorage();
  final service = _FakeBiometricService(available: available, result: result);
  return (
    useCase: BiometricAuthUseCase(
      service,
      GetIt.instance<SecureStorageService>(),
    ),
    service: service,
  );
}

/// Rola até o botão 'Partilhar recibo' — o design system 2026 deixou a
/// tela mais alta (círculo verde do resumo, selo do pagamento, card de
/// total) e a ação fica abaixo da dobra no viewport de teste (600px).
Future<void> _scrollToShare(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Partilhar recibo'),
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Sale _sale() => Sale(
  id: 's1',
  number: 1,
  items: const [
    SaleItem(
      productId: 'p1',
      productName: 'Caneta',
      quantity: 2000, // 2 unidades em MILÉSIMOS (W11)
      unitPriceCents: 200,
    ),
    SaleItem(
      productId: 'p2',
      productName: 'Caderno',
      quantity: 1000,
      unitPriceCents: 990,
    ),
  ],
  totalAmountCents: 1390,
  paymentMethod: PaymentMethod.mPesa,
  dateTime: DateTime(2026, 8, 3, 14, 30),
);

void main() {
  testWidgets('exibe resumo, itens com preço unitário e subtotais', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...storeContextOverrides()],
        child: testApp(home: SaleDetailScreen(sale: _sale())),
      ),
    );

    // Resumo.
    expect(find.text('Detalhes da venda'), findsOneWidget);
    // O número SEQUENCIAL da venda na loja vira 'Venda S-00001'.
    expect(find.text('Venda S-00001'), findsOneWidget);
    expect(find.text('M-Pesa'), findsOneWidget);

    // Itens com quantidade × preço unitário e subtotal — mesmo padrão do
    // feed de "Atividade de hoje": ícone circular azul, título + linha de
    // quantidade × preço à esquerda, valor à direita, divisórias indent: 60.
    expect(find.text('Caneta'), findsOneWidget);
    expect(find.text('2 × R\$ 2,00'), findsOneWidget);
    expect(find.text('R\$ 4,00'), findsOneWidget); // subtotal de Caneta
    expect(find.text('Caderno'), findsOneWidget);
    expect(
      find.text('1 × R\$ 9,90'),
      findsOneWidget,
    ); // Total em destaque e nota de snapshot.
    expect(
      find.textContaining('13,90'),
      findsAtLeastNWidgets(1),
    ); // total (header + rodapé)
    // Chrome do feed: ícone circular de tinta (40px) no cabeçalho da venda +
    // em cada item — header + 2 itens = 3 ícones.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == AppColors.darkVoid &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
            widget.constraints?.maxWidth == 40 &&
            widget.constraints?.maxHeight == 40,
      ),
      findsNWidgets(3), // header + Caneta + Caderno
    );
    // Divisória do item: indent: 60, mesma largura usada pelo dashboard feed.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Divider &&
            (widget).indent == 60 &&
            (widget).endIndent == AppSpacing.md,
      ),
      findsOneWidget, // após Caneta (o total é o _SaleFeedRow, sem divisória extra)
    );
  });

  testWidgets('dono vê Anular venda e o fluxo confirma e chama o use case', (
    tester,
  ) async {
    final fakeCancel = _FakeCancelSaleUseCase();
    // M4: biometria INDISPONÍVEL no aparelho simulado — a 2ª barreira é
    // pulada (degradação consciente) e o fluxo textual segue sozinho.

    // Rota empurrada dentro de um ProviderScope com o use case fake (o
    // ServiceLocator não é inicializado nos testes de widget).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          cancelSaleUseCaseProvider.overrideWithValue(fakeCancel),
          biometricAuthUseCaseProvider.overrideWithValue(
            _fakeBiometricUseCase(available: false).useCase,
          ),
        ],
        child: testApp(
          home: Builder(
            builder: (context) => Consumer(
              // No app real o AppShell mantém a loja ativa resolvida; no
              // teste, a rota base assiste o provider para pré-resolvê-la
              // (o ActiveStoreNotifier é síncrono e na 1ª leitura as lojas
              // ainda podem estar carregando).
              builder: (context, ref, _) {
                ref.watch(activeStoreIdProvider('1'));
                return Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SaleDetailScreen(sale: _sale()),
                        ),
                      ),
                      child: const Text('abrir'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // Dono (storeContextOverrides) vê a ação gerencial. O botão de
    // Partilhar recibo fica acima — no viewport de teste (600px) a ação de
    // anular pode ficar abaixo da dobra; rola até ela.
    await tester.scrollUntilVisible(
      find.text('Anular venda'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Anular venda'), findsOneWidget);

    await tester.tap(find.text('Anular venda'));
    await tester.pumpAndSettle();
    // Confirmação com o valor a estornar (total aparece no resumo, no
    // rodapé e no corpo do diálogo).
    expect(find.text('Anular esta venda?'), findsOneWidget);
    expect(find.textContaining('R\$ 13,90'), findsWidgets);

    await tester.tap(find.text('Sim, anular'));
    await tester.pumpAndSettle();

    expect(fakeCancel.calls, 1);
    expect(fakeCancel.lastSaleId, 's1');
    // Sucesso: snackbar + rota de detalhes fechada (voltou para 'abrir').
    expect(find.text('Venda anulada.'), findsOneWidget);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets(
    'biometria disponível: prompt confirma identidade antes de anular',
    (tester) async {
      final fakeCancel = _FakeCancelSaleUseCase();
      final biometric = _fakeBiometricUseCase(available: true, result: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...storeContextOverrides(),
            cancelSaleUseCaseProvider.overrideWithValue(fakeCancel),
            biometricAuthUseCaseProvider.overrideWithValue(biometric.useCase),
          ],
          child: testApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) {
                  ref.watch(activeStoreIdProvider('1'));
                  return Scaffold(
                    body: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SaleDetailScreen(sale: _sale()),
                          ),
                        ),
                        child: const Text('abrir'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Anular venda'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Anular venda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sim, anular'));
      await tester.pumpAndSettle();

      // 2ª barreira: o prompt biométrico FOI exibido antes da anulação e a
      // operação só aconteceu após o sucesso da identidade.
      expect(biometric.service.attempts, greaterThanOrEqualTo(1));
      expect(fakeCancel.calls, 1);
      expect(fakeCancel.lastSaleId, 's1');
    },
  );

  testWidgets('funcionário comum NÃO vê a ação Anular venda', (tester) async {
    // Tenant de OUTRO dono + vínculo 'employee' do utilizador logado →
    // currentAccessLevel = employee (mesma regra de Compras/Relatórios).
    final overrides = [
      authStateProvider.overrideWith(
        (ref) => Stream.value(const AppUser(id: 'u1', email: 'func@loja.com')),
      ),
      getMyTenantUseCaseProvider.overrideWithValue(
        FakeGetMyTenantUseCase(approvedTenant(ownerUserId: 'dono')),
      ),
      getStoresUseCaseProvider.overrideWithValue(
        FakeGetStoresUseCase(const [
          Store(id: 'st1', tenantId: 'tn1', name: 'Loja Centro'),
        ]),
      ),
      adminRepositoryProvider.overrideWithValue(const FakeAdminRepository()),
      employeesProvider('tn1').overrideWith(
        (ref) async => const [
          StoreEmployee(
            id: 'e1',
            tenantId: 'tn1',
            storeId: 'st1',
            userId: 'u1',
            fullName: 'Funcionária',
            email: 'func@loja.com',
            role: EmployeeRole.employee,
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: testApp(home: SaleDetailScreen(sale: _sale())),
      ),
    );

    expect(find.text('Anular venda'), findsNothing);
  });

  testWidgets('venda anulada mostra selo Anulada e não oferece anular', (
    tester,
  ) async {
    final cancelled = _sale().copyWith(
      status: SaleStatus.cancelled,
      cancelledAt: DateTime(2026, 8, 4, 10),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...storeContextOverrides()],
        child: testApp(home: SaleDetailScreen(sale: cancelled)),
      ),
    );

    expect(find.text('Anulada'), findsOneWidget);
    expect(find.textContaining('Anulada em'), findsOneWidget);
    expect(find.text('Anular venda'), findsNothing);
  });

  testWidgets(
    'Partilhar recibo abre o sheet com a pré-visualização do recibo',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...storeContextOverrides()],
          child: testApp(home: SaleDetailScreen(sale: _sale())),
        ),
      );
      // Deixa tenant/lojas resolverem (o cabeçalho do recibo usa a loja
      // ativa — providers assíncronos do contexto de teste).
      await tester.pumpAndSettle();

      await _scrollToShare(tester);
      expect(find.text('Partilhar recibo'), findsOneWidget);
      await tester.tap(find.text('Partilhar recibo'));
      await tester.pumpAndSettle();

      // Bottom sheet: título, pré-visualização do recibo (loja do contexto
      // de teste + itens) e as duas ações.
      expect(find.text('Partilhar recibo'), findsNWidgets(2)); // botão + sheet
      expect(find.text('LOJA CENTRO'), findsOneWidget); // cabeçalho do recibo
      expect(find.text('RECIBO DE VENDA'), findsOneWidget);
      expect(find.text('Caneta'), findsWidgets);
      expect(find.text('Partilhar como imagem'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    },
  );

  testWidgets('Partilhar como imagem captura o recibo e chama o sharer', (
    tester,
  ) async {
    final fakeSharer = _FakeReceiptSharer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          receiptSharerProvider.overrideWithValue(fakeSharer),
        ],
        child: testApp(home: SaleDetailScreen(sale: _sale())),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToShare(tester);
    await tester.tap(find.text('Partilhar recibo'));
    await tester.pumpAndSettle();
    // A captura do RepaintBoundary usa `toImage` (raster real) — só
    // completa no ambiente de teste dentro de runAsync.
    await tester.runAsync(() async {
      await tester.tap(find.text('Partilhar como imagem'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    // O share sheet abriu com bytes PNG válidos (assinatura do PNG) e o
    // id da venda chegou ao sharer (nome do arquivo temporário).
    final bytes = fakeSharer.lastImageBytes;
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(8));
    expect(bytes.sublist(0, 8), [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    expect(fakeSharer.lastSaleId, 's1');
  });

  testWidgets('WhatsApp monta o texto do recibo e chama o sharer', (
    tester,
  ) async {
    final fakeSharer = _FakeReceiptSharer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          receiptSharerProvider.overrideWithValue(fakeSharer),
        ],
        child: testApp(home: SaleDetailScreen(sale: _sale())),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToShare(tester);
    await tester.tap(find.text('Partilhar recibo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    final text = fakeSharer.lastWhatsAppText;
    expect(text, isNotNull);
    expect(text, contains('LOJA CENTRO'));
    expect(text, contains('RECIBO DE VENDA'));
    expect(text, contains('Caneta'));
    expect(text, contains('Total: R\$ 13,90'));
  });

  testWidgets('WhatsApp sem suporte mostra o erro', (tester) async {
    final fakeSharer = _FakeReceiptSharer()..whatsAppOpened = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          receiptSharerProvider.overrideWithValue(fakeSharer),
        ],
        child: testApp(home: SaleDetailScreen(sale: _sale())),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToShare(tester);
    await tester.tap(find.text('Partilhar recibo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível abrir o WhatsApp. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('recibo de venda anulada mostra o título com (ANULADA)', (
    tester,
  ) async {
    final cancelled = _sale().copyWith(
      status: SaleStatus.cancelled,
      cancelledAt: DateTime(2026, 8, 4, 10),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...storeContextOverrides()],
        child: testApp(home: SaleDetailScreen(sale: cancelled)),
      ),
    );
    await tester.pumpAndSettle();

    await _scrollToShare(tester);
    await tester.tap(find.text('Partilhar recibo'));
    await tester.pumpAndSettle();

    // Pré-visualização do recibo marcada como anulada ('Anulada em' aparece
    // no corpo da tela E no rodapé do recibo).
    expect(find.text('RECIBO DE VENDA (ANULADA)'), findsOneWidget);
    expect(find.textContaining('Anulada em'), findsNWidgets(2));
  });
}
