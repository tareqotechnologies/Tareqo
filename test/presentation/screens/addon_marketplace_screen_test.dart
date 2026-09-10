import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/data/datasources/local/addon_local_data_source.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/addon_providers.dart';
import 'package:tareqo/presentation/screens/addons/addon_marketplace_screen.dart';
import 'package:tareqo/presentation/screens/addons/custom_invoice_screen.dart';

class _FakeAddOnDataSource implements AddOnLocalDataSource {
  _FakeAddOnDataSource(this._activeIds);

  final Set<String> _activeIds;

  @override
  Future<Set<String>> getActiveAddOnIds(String tenantId) async => _activeIds;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlanRepository implements IPlanRepository {
  _FakePlanRepository(this._plans);

  final List<Plan> _plans;

  @override
  Future<List<Plan>> getActivePlans() async => _plans;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Plano com o add-on de facturas personalizadas incluído.
const _planWithBundles = Plan(
  id: 'pl2',
  name: 'Demo',
  priceMonthlyCents: 0,
  bundledAddOns: ['ao_custom_invoice'],
);

Widget _buildApp({
  Set<String> activeIds = const {},
  List<Plan> plans = const [_planWithBundles],
  Key screenKey = const Key('screen'),
}) {
  // O screen lê `plansProvider` com `ref.read` durante o build (não
  // observa mudanças) — o override PRE-COMPLETA o futuro para que a
  // leitura em build já encontre os planos (determinístico).
  return ProviderScope(
    overrides: [
      ...storeContextOverrides(),
      addOnDataSourceProvider.overrideWithValue(
        _FakeAddOnDataSource(activeIds),
      ),
      getPlansUseCaseProvider.overrideWithValue(
        GetPlansUseCase(_FakePlanRepository(plans)),
      ),
      plansProvider.overrideWith((ref) async => plans),
    ],
    child: testApp(home: AddOnMarketplaceScreen(key: screenKey)),
  );
}

void main() {
  // NOTA (comportamento real): a tela lê `plansProvider` com ref.read
  // durante o build e NÃO observa mudanças — no primeiro frame o futuro
  // ainda não completou e bundledAddOns fica vazio. O card aparece nos
  // rebuilds seguintes (ex.: troca de aba no app real). Reproduzimos:
  // pump inicial → futuro settle → novo build com chave nova.

  testWidgets(
    'add-on do PLANO aparece com badge incluído (sem estar ativo no banco)',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      // 2º build com chave nova: o futuro dos planos já settleu e o
      // ref.read do build agora enxerga os planos (ver NOTA acima).
      await tester.pumpWidget(_buildApp(screenKey: const Key('screen2')));
      await tester.pumpAndSettle();

      // O add-on incluído no plano é visível e marcado como incluído.
      expect(find.text('Factura Personalizada'), findsOneWidget);
      expect(find.text('Incluído'), findsOneWidget);
      // NÃO está ativo no banco — não pode mostrar o badge de ativo.
      expect(find.text('Activo'), findsNothing);
    },
  );

  testWidgets('add-on ATIVO no banco aparece com badge de ativo e preço', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(activeIds: const {'ao_quotation'}));
    await tester.pumpAndSettle();

    expect(find.text('Cotação / Orçamento'), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);
    expect(find.text('Incluído'), findsNothing);
  });

  testWidgets(
    'add-on BLOQUEADO (isAvailable: false) nunca aparece no marketplace',
    (tester) async {
      await tester.pumpWidget(
        _buildApp(
          activeIds: const {
            'ao_mobile_money',
          }, // isAvailable: false no catálogo.
          plans: const [],
        ),
      );
      await tester.pumpAndSettle();

      // Nem o card, nem qualquer badge — a funcionalidade não existe.
      expect(find.text('Mobile Money'), findsNothing);
    },
  );

  testWidgets(
    'add-on sem vínculo (nem plano nem ativo) NÃO aparece — só se vende o que existe',
    (tester) async {
      await tester.pumpWidget(_buildApp(activeIds: const {}, plans: const []));
      await tester.pumpAndSettle();

      expect(find.text('Factura Personalizada'), findsNothing);
      expect(find.text('Cotação / Orçamento'), findsNothing);
      // O aviso de gestão pelo admin continua visível.
      expect(find.textContaining('administrador do sistema'), findsOneWidget);
    },
  );

  testWidgets('toque no add-on incluído navega para a tela do módulo', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_buildApp(screenKey: const Key('screen2')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Factura Personalizada'));
    await tester.pumpAndSettle();

    // Navegou: a tela de facturas personalizadas está no topo.
    expect(find.byType(CustomInvoiceScreen), findsOneWidget);
  });
}
