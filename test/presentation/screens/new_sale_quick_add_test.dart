import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/entities/sale.dart';
import 'package:tareqo/domain/repositories/i_sale_processor.dart';
import 'package:tareqo/domain/repositories/i_sale_repository.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';
import 'package:tareqo/presentation/screens/sales/new_sale_sheet.dart';
import 'package:tareqo/presentation/widgets/app_button.dart';

import '../../helpers/store_context.dart';
import '../../helpers/test_app.dart';

/// Catálogo focado nos fluxos de alta frequência da Fase 4:
/// - `c1` caneta com PLU "123" (unidade) — quick-add e edição de quantidade;
/// - `f1` arroz por peso (fração) — mantém comportamento decimal existente.
class _CatalogUseCase implements GetProductsUseCase {
  @override
  Future<List<Product>> call({required String storeId}) async => const [
    Product(
      id: 'c1',
      code: '123',
      name: 'Caneta Azul',
      purchasePriceCents: 100,
      salePriceCents: 200,
      // 50 UNIDADES (50.000 milésimos) — stock realista para a edição
      // de quantidade (25 unidades) não ser capada pelo mínimo.
      stockQuantity: 50000,
    ),
    Product(
      id: 'f1',
      code: '456',
      name: 'Arroz 25kg',
      purchasePriceCents: 5000,
      salePriceCents: 8000,
      stockQuantity: 10000,
      vendaPorFracao: true,
      unitLabel: 'kg',
    ),
  ];
}

class _FakeProcessSaleUseCase implements ProcessSaleUseCase {
  int calls = 0;
  Sale? lastSale;

  @override
  Future<void> call(Sale sale) async {
    calls++;
    lastSale = sale;
  }

  @override
  ISaleAtomicProcessor? get processor => null;
}

/// Somente `getAll` é lido pelo cabeçalho "Hoje · N vendas"; demais membros
/// não são alcançados por estes testes.
class _FakeSalesRepository implements ISaleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Sale>> getAll({required String storeId}) async => const [];
}

Future<void> _pumpPdv(
  WidgetTester tester, {
  required _FakeProcessSaleUseCase processSale,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...storeContextOverrides(),
        getProductsUseCaseProvider.overrideWithValue(_CatalogUseCase()),
        processSaleUseCaseProvider.overrideWithValue(processSale),
        salesRepositoryProvider.overrideWithValue(_FakeSalesRepository()),
      ],
      child: testApp(home: Scaffold(body: NewSaleSheet())),
    ),
  );
  await tester.pumpAndSettle();
}

/// Campo de quantidade do diálogo aberto (o único TextField dentro do
/// AlertDialog — os campos do PDV ficam fora do diálogo).
Finder _dialogField() => find
    .descendant(of: find.byType(AlertDialog), matching: find.byType(TextField))
    .first;

void main() {
  testWidgets(
    'quick-add por PLU: Enter com código no campo de busca adiciona o produto',
    (tester) async {
      final processSale = _FakeProcessSaleUseCase();
      await _pumpPdv(tester, processSale: processSale);

      // Digita o PLU "123" (Caneta Azul) no campo de BUSCA e aperta Enter.
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // O produto entrou no carrinho — resumo do rodapé (estável mesmo com
      // a SliverList lazy). A venda ainda NÃO foi registada — só o
      // carrinho recebeu o item. O total "R$ 2,00" aparece no rodapé E na
      // pill/linha do catálogo (ambos visíveis desde o layout compacto).
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('R\$ 2,00'), findsWidgets);
      expect(processSale.calls, 0);

      // Confirmar registra a venda com o item do quick-add (1 unidade).
      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();
      expect(processSale.calls, 1);
      expect(processSale.lastSale!.items.single.productId, 'c1');
      expect(processSale.lastSale!.items.single.quantity, 1000);
    },
  );

  testWidgets(
    'quick-add com busca por NOME não dispara o pipeline de código',
    (tester) async {
      final processSale = _FakeProcessSaleUseCase();
      await _pumpPdv(tester, processSale: processSale);

      // "caneta" tem letras — Enter não deve adicionar nada (é busca por
      // nome; o filtro em tempo real já respondeu no onChanged).
      await tester.enterText(find.byType(TextField).at(1), 'caneta');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Carrinho vazio: o botão de confirmar segue desabilitado.
      final confirmButton = tester.widget<AppButton>(
        find.ancestor(
          of: find.text('Confirmar venda'),
          matching: find.byType(AppButton),
        ),
      );
      expect(confirmButton.onPressed, isNull);
      expect(processSale.calls, 0);
    },
  );

  testWidgets(
    'toque na quantidade de produto por UNIDADE abre edição e aplica inteiro',
    (tester) async {
      final processSale = _FakeProcessSaleUseCase();
      await _pumpPdv(tester, processSale: processSale);

      // A SliverList é lazy: com as linhas de pagamento em 48dp (Fase 6),
      // a linha do catálogo fica no cache extent (offstage) no viewport de
      // teste. Rola até a linha entrar em cena — o NOME é único aqui (a
      // pill só existe depois de adicionar; o código não é renderizado).
      await tester.scrollUntilVisible(
        find.text('Caneta Azul'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Adiciona 1 unidade via "+"; a pill do carrinho empurra a linha
      // para baixo — rola de novo até o stepper exibir a quantidade "1"
      // (exata; "0,05 un." não colide).
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('1'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // Diálogo de quantidade: digita 25 e confirma.
      await tester.enterText(_dialogField(), '25');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Confirma a venda — 25 canetas × 2,00 = 50,00.
      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();
      expect(processSale.calls, 1);
      expect(processSale.lastSale!.items.single.productId, 'c1');
      expect(processSale.lastSale!.items.single.quantity, 25000);
    },
  );

  testWidgets(
    'produto por peso mantém fração decimal ao editar quantidade',
    (tester) async {
      final processSale = _FakeProcessSaleUseCase();
      await _pumpPdv(tester, processSale: processSale);

      // Arroz por peso com quantidade 0: o stepper mostra "0 kg" (com
      // unidade). Rola até a linha (lazy) e digita 1,75 direto, sem tocar
      // no "+".
      await tester.scrollUntilVisible(
        find.text('0 kg'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('0 kg'));
      await tester.pumpAndSettle();
      await tester.enterText(_dialogField(), '1,75');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirmar venda'));
      await tester.pumpAndSettle();
      expect(processSale.lastSale!.items.single.productId, 'f1');
      expect(processSale.lastSale!.items.single.quantity, 1750);
    },
  );
}
