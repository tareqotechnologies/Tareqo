import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/repositories/i_cash_flow_repository.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';
import 'package:tareqo/presentation/controllers/finance_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/screens/addons/advanced_reports_screen.dart';

class _FakeGetProducts implements GetProductsUseCase {
  _FakeGetProducts(this._products);

  final List<Product> _products;

  @override
  Future<List<Product>> call({required String storeId}) async => _products;
}

/// Fake do fluxo de caixa — grava a janela pedida para asserção de
/// contrato (o período do chip deve virar [start, end] corretamente).
class _FakeGetCashFlow implements GetCashFlowUseCase {
  _FakeGetCashFlow(this._cashFlow);

  final CashFlow _cashFlow;
  final windows = <({DateTime start, DateTime end})>[];

  @override
  ICashFlowRepository? get serverRepository => null;

  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    windows.add((start: start, end: end));
    return _cashFlow;
  }
}

Product _product(
  String name, {
  int stockMilli = 5000,
  int salePriceCents = 1000,
}) => Product(
  id: 'p-$name',
  storeId: 'st1',
  name: name,
  purchasePriceCents: 500,
  salePriceCents: salePriceCents,
  stockQuantity: stockMilli,
);

Widget _buildApp({
  List<Product> products = const [],
  GetCashFlowUseCase? cashFlow,
}) {
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      getProductsUseCaseProvider.overrideWithValue(_FakeGetProducts(products)),
      if (cashFlow != null)
        getCashFlowUseCaseProvider.overrideWithValue(cashFlow),
    ],
    child: testApp(home: const AdvancedReportsScreen()),
  );
}

void main() {
  testWidgets(
    'aba Vendas: KPIs de estoque calculados dos produtos reais (centavos exactos)',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          products: [
            _product(
              'Arroz',
              stockMilli: 50000,
              salePriceCents: 1000,
            ), // 50 un × 10
            _product(
              'Óleo',
              stockMilli: 2700,
              salePriceCents: 1599,
            ), // 2,7 × 15,99
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 2 produtos; 1 com estoque baixo (Óleo 2 un ≤ 10; Arroz 50 não).
      // Valor: (50000×1000 + 2700×1599) ~/ 1000 = 50000 + 4317 = 54317 cents.
      expect(find.text('2'), findsAtLeast(2)); // KPI + badge do top-card
      expect(find.text('1'), findsOneWidget); // estoque baixo
      expect(find.text('R\$ 543,17'), findsOneWidget); // valor exacto
      expect(find.text('Arroz'), findsOneWidget);
      expect(find.text('Óleo'), findsOneWidget);
    },
  );

  testWidgets('aba Vendas sem produtos mostra mensagem de vazio', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Sem produtos cadastrados'), findsOneWidget);
  });

  testWidgets(
    'aba Financeiro: KPIs do fluxo de caixa real (entradas/saídas/líquido)',
    (tester) async {
      final fake = _FakeGetCashFlow(
        const CashFlow(incomeCents: 150000, expenseCents: 45000),
      );
      await tester.pumpWidget(_buildApp(cashFlow: fake));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Financeiro'));
      await tester.pumpAndSettle();

      // KPI + barra do gráfico mostram o mesmo valor (2 widgets cada).
      expect(find.text('R\$ 1.500,00'), findsNWidgets(2)); // receita
      expect(find.text('R\$ 450,00'), findsNWidgets(2)); // despesa
      expect(find.text('R\$ 1.050,00'), findsOneWidget); // líquido
      // A janela pedida começa no início do mês (período padrão "Este Mês").
      final now = DateTime.now();
      expect(fake.windows.single.start, DateTime(now.year, now.month));
    },
  );

  testWidgets(
    'aba Financeiro: erro do fluxo de caixa mostra retry (nunca silencia)',
    (tester) async {
      final fake = _AlwaysThrowCashFlow();
      await tester.pumpWidget(_buildApp(cashFlow: fake));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Financeiro'));
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar o relatório.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
    },
  );

  testWidgets(
    'aba Estoque: produto zerado conta como ruptura, estoque saudável vazio',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          products: [
            _product('Arroz', stockMilli: 50000), // 50 un → saudável
            _product('Açúcar', stockMilli: 0), // ruptura
            _product('Sal', stockMilli: 500), // 0 un → baixo
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Estoque'));
      await tester.pumpAndSettle();

      // 2 produtos em estoque baixo (Açúcar 0 + Sal 0,5 ≤ 10) listados;
      // o saudável (Arroz) não aparece na lista de baixos.
      expect(find.text('2'), findsWidgets); // KPI baixo + badge
      expect(find.text('Açúcar'), findsOneWidget);
      expect(find.text('Sal'), findsOneWidget);
      expect(find.text('Arroz'), findsNothing);
      // Mensagem de estoque saudável só aparece quando NENHUM produto está baixo.
      expect(find.textContaining('estoque adequado'), findsNothing);
    },
  );

  testWidgets(
    'aba Estoque: todos os produtos saudáveis mostra mensagem de estoque adequado',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          products: [
            _product('Arroz', stockMilli: 50000), // 50 un → saudável
            _product('Feijão', stockMilli: 25000), // 25 un → saudável
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Estoque'));
      await tester.pumpAndSettle();

      // Nenhum produto baixo → lista vazia + mensagem de estoque saudável.
      expect(find.textContaining('estoque adequado'), findsOneWidget);
      expect(find.text('0'), findsWidgets); // KPIs baixo/ruptura zerados
      // KPI de valor: (50000×1000)/1000 + (25000×1000)/1000 = 75.000 centavos.
      expect(find.text('R\$ 750,00'), findsOneWidget);
    },
  );

  testWidgets('troca de período no chip refaz a consulta com a nova janela', (
    tester,
  ) async {
    final fake = _FakeGetCashFlow(
      const CashFlow(incomeCents: 10000, expenseCents: 0),
    );
    await tester.pumpWidget(_buildApp(cashFlow: fake));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Financeiro'));
    await tester.pumpAndSettle();
    final firstCount = fake.windows.length;
    expect(firstCount, greaterThanOrEqualTo(1));

    // Troca o período para "Hoje" via chip do AppBar.
    await tester.tap(find.text('Este mês'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoje').last);
    await tester.pumpAndSettle();

    // A janela "Hoje" tem início no dia corrente (00:00 local).
    final now = DateTime.now();
    final todayWindow = fake.windows.last;
    expect(todayWindow.start, DateTime(now.year, now.month, now.day));
  });
}

class _AlwaysThrowCashFlow implements GetCashFlowUseCase {
  @override
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    throw Exception('banco indisponível');
  }

  @override
  ICashFlowRepository? get serverRepository => null;
}
