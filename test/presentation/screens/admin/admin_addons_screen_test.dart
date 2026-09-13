import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

import 'package:tareqo/data/datasources/local/addon_local_data_source.dart';
import 'package:tareqo/domain/entities/addon.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_tenants_use_case.dart';
import 'package:tareqo/presentation/controllers/addon_providers.dart';
import 'package:tareqo/presentation/controllers/admin_providers.dart';
import 'package:tareqo/presentation/screens/admin/admin_addons_screen.dart';

class _FakeGetAllTenantsUseCase implements GetAllTenantsUseCase {
  _FakeGetAllTenantsUseCase(this._tenants, {this.throwOnCall = false});

  final List<Tenant> _tenants;
  final bool throwOnCall;

  @override
  Future<List<Tenant>> call() async {
    if (throwOnCall) throw Exception('falha ao carregar tenants');
    return _tenants;
  }
}

class _FakeGetAllPlansUseCase implements GetAllPlansUseCase {
  _FakeGetAllPlansUseCase(this._plans);

  final List<Plan> _plans;

  @override
  Future<List<Plan>> call() async => _plans;
}

/// Backend de add-ons em memória com registro de chamadas — cobre os
/// fluxos de activação individual (manager) e em lote (sheet).
class _SpyAddOnDataSource implements AddOnLocalDataSource {
  _SpyAddOnDataSource({Set<String>? active, this.throwOnActivateFor = const {}})
    : _active = {...?active};

  final Set<String> _active;
  final Set<String> throwOnActivateFor;

  final List<(String method, String tenantId, String addOnId)> calls = [];

  @override
  Future<Set<String>> getActiveAddOnIds(String tenantId) async => {..._active};

  @override
  Future<void> activate(String tenantId, String addOnId) async {
    calls.add(('activate', tenantId, addOnId));
    if (throwOnActivateFor.contains(addOnId)) {
      throw Exception('falha na activação');
    }
    _active.add(addOnId);
  }

  @override
  Future<void> deactivate(String tenantId, String addOnId) async {
    calls.add(('deactivate', tenantId, addOnId));
    _active.remove(addOnId);
  }

  @override
  Future<void> register({
    required String tenantId,
    required String addOnId,
    DateTime? expiresAt,
  }) async {}

  @override
  Future<bool> isActive(String tenantId, String addOnId) async =>
      _active.contains(addOnId);

  @override
  Future<List<TenantAddOn>> getByTenant(String tenantId) async => const [];

  @override
  Future<int> deactivateExpired() async => 0;

  @override
  Future<List<TenantAddOn>> getExpired() async => const [];
}

Tenant _approvedTenant({String id = 'tn1', String name = 'Comercial Demo'}) =>
    Tenant(
      id: id,
      ownerUserId: 'owner12345',
      businessName: name,
      planId: 'pl1',
      status: TenantStatus.approved,
      createdAt: DateTime(2026, 8, 1),
    );

/// Viewport largo e alto (1000×1600): a fonte de teste (Ahem) é bem mais
/// larga que a Inter de produção — tiles/sheets estouram no padrão 400px.
void _useWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _buildApp({
  required List<Tenant> tenants,
  _SpyAddOnDataSource? addOns,
  GetAllTenantsUseCase? tenantsUseCase,
}) {
  return ProviderScope(
    overrides: [
      getAllTenantsUseCaseProvider.overrideWithValue(
        tenantsUseCase ?? _FakeGetAllTenantsUseCase(tenants),
      ),
      getAllPlansUseCaseProvider.overrideWithValue(
        _FakeGetAllPlansUseCase(const [
          Plan(id: 'pl1', name: 'Essencial', priceMonthlyCents: 2990),
        ]),
      ),
      if (addOns != null) addOnDataSourceProvider.overrideWithValue(addOns),
    ],
    child: testApp(
      home: const AdminAddOnsScreen(),
      // A fonte de teste (Ahem) é mais larga que a Inter de produção — o
      // sheet de activação em lote (largura limitada pelo framework)
      // estoura a linha categoria · preço. Clamp compensa sem afetar
      // as asserções de texto.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 0.75,
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('lista apenas tenants aprovados com o nome do plano', (
    tester,
  ) async {
    _useWideViewport(tester);
    final tenants = [
      _approvedTenant(),
      _approvedTenant(id: 'tn2', name: 'Mercado Central'),
      // Pendente e rejeitado NUNCA aparecem no picker.
      Tenant(
        id: 'tn3',
        ownerUserId: 'owner33333',
        businessName: 'Aguardando Ltda',
        planId: 'pl1',
        status: TenantStatus.pending,
        createdAt: DateTime(2026, 8, 2),
      ),
      Tenant(
        id: 'tn4',
        ownerUserId: 'owner44444',
        businessName: 'Rejeitada Ltda',
        planId: 'pl1',
        status: TenantStatus.rejected,
        createdAt: DateTime(2026, 8, 3),
      ),
    ];

    await tester.pumpWidget(_buildApp(tenants: tenants));
    await tester.pumpAndSettle();

    expect(find.text('Comercial Demo'), findsOneWidget);
    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Aguardando Ltda'), findsNothing);
    expect(find.text('Rejeitada Ltda'), findsNothing);
    expect(find.text('Plano: Essencial'), findsNWidgets(2));
    expect(find.text('Buscar tenants...'), findsOneWidget);
  });

  testWidgets('busca filtra por nome e estado vazio orienta o admin', (
    tester,
  ) async {
    _useWideViewport(tester);
    final tenants = [
      _approvedTenant(),
      _approvedTenant(id: 'tn2', name: 'Mercado Central'),
    ];

    await tester.pumpWidget(_buildApp(tenants: tenants));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mercado');
    await tester.pumpAndSettle();

    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Comercial Demo'), findsNothing);

    // Sem correspondência → estado vazio com dica de busca.
    await tester.enterText(find.byType(TextField), 'zzz-inexistente');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum tenant encontrado'), findsOneWidget);
    expect(find.text('Tente outro termo de busca'), findsOneWidget);
  });

  testWidgets('sem tenants aprovados mostra o estado vazio apropriado', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(_buildApp(tenants: const []));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum tenant encontrado'), findsOneWidget);
    expect(find.text('Nenhum tenant aprovado ainda'), findsOneWidget);
  });

  testWidgets('erro ao carregar tenants é exibido (nunca silencioso)', (
    tester,
  ) async {
    _useWideViewport(tester);
    await tester.pumpWidget(
      _buildApp(
        tenants: const [],
        tenantsUseCase: _FakeGetAllTenantsUseCase(const [], throwOnCall: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Erro: Exception: falha ao carregar tenants'),
      findsOneWidget,
    );
  });

  testWidgets('gestão individual: stats, preços e toggle de add-ons', (
    tester,
  ) async {
    _useWideViewport(tester);
    final addOns = _SpyAddOnDataSource(active: {'ao_custom_invoice'});
    final tenants = [_approvedTenant()];

    await tester.pumpWidget(_buildApp(tenants: tenants, addOns: addOns));
    await tester.pumpAndSettle();

    // Entra no manager do tenant.
    await tester.tap(find.text('Comercial Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Comercial Demo'), findsOneWidget);
    expect(find.textContaining('ID:'), findsOneWidget);

    // Stats iniciais: 5 disponíveis (BLOCKED fora), 1 activo, 4 inactivos.
    expect(find.text('5'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    // Preço do primeiro add-on (Formatters padrão BRL em testes).
    expect(find.text('R\$ 300,00/mês'), findsOneWidget);
    expect(find.text('Facturação'), findsOneWidget);

    // O add-on activo tem o switch ligado (primeiro tile do catálogo).
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);

    // Desligar → deactivate persistido e stats recarregadas
    // (Total 5 + Inactivos 5 → dois textos "5").
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(addOns.calls.last.$1, 'deactivate');
    expect(addOns.calls.last.$2, 'tn1');
    expect(addOns.calls.last.$3, 'ao_custom_invoice');
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isFalse);
    expect(find.text('5'), findsNWidgets(2));

    // Ligar o último add-on → activate.
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(addOns.calls.last.$1, 'activate');
    expect(addOns.calls.last.$3, 'ao_multi_store');
    expect(find.text('1'), findsOneWidget); // volta a 1 activo
    expect(find.text('4'), findsOneWidget); // 4 inactivos

    // Voltar à lista.
    await tester.tap(find.byTooltip('Voltar à lista'));
    await tester.pumpAndSettle();

    expect(find.text('Buscar tenants...'), findsOneWidget);
  });

  testWidgets('erro no toggle mostra snackbar sem desligar a UI', (
    tester,
  ) async {
    _useWideViewport(tester);
    final addOns = _SpyAddOnDataSource(
      throwOnActivateFor: {'ao_custom_invoice'},
    );
    final tenants = [_approvedTenant()];

    await tester.pumpWidget(_buildApp(tenants: tenants, addOns: addOns));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comercial Demo'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Erro ao actualizar add-on: Exception: falha na activação',
      ),
      findsOneWidget,
    );
  });

  testWidgets('modo lote: seleção, sheet de add-on e activação em massa', (
    tester,
  ) async {
    _useWideViewport(tester);
    final addOns = _SpyAddOnDataSource();
    final tenants = [
      _approvedTenant(),
      _approvedTenant(id: 'tn2', name: 'Mercado Central'),
    ];

    await tester.pumpWidget(_buildApp(tenants: tenants, addOns: addOns));
    await tester.pumpAndSettle();

    // Long press no card entra em modo de seleção já marcando o tenant.
    await tester.longPress(find.text('Comercial Demo'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    // Com 1 selecionado → botão de activar em massa visível.
    expect(find.text('Activar add-on'), findsOneWidget);

    // Seleciona o segundo tenant via checkbox do card.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Desmarcar todos'), findsOneWidget);

    // Abre o sheet de activação em lote.
    await tester.tap(find.text('Activar add-on'));
    await tester.pumpAndSettle();

    expect(find.text('Activar add-on em lote'), findsOneWidget);
    expect(find.text('2 tenants selecionados'), findsOneWidget);
    // Só add-ons DISPONÍVEIS (o M-Pesa/E-Mola bloqueado fica fora).
    expect(find.text('Factura Personalizada'), findsOneWidget);
    expect(find.text('Integração M-Pesa / E-Mola'), findsNothing);
    expect(find.text('Activar'), findsNWidgets(5));
    expect(find.text('Desactivar'), findsNWidgets(5));

    // Activa o primeiro add-on nos 2 tenants selecionados.
    await tester.tap(find.text('Activar').first);
    await tester.pumpAndSettle();

    expect(addOns.calls.where((c) => c.$1 == 'activate').map((c) => c.$2), [
      'tn1',
      'tn2',
    ]);
    expect(addOns.calls.first.$3, 'ao_custom_invoice');
    expect(
      find.text('Factura Personalizada activado em 2 tenants'),
      findsOneWidget,
    );
    // Modo lote encerrado após aplicar.
    expect(find.text('2 / 2'), findsNothing);
  });
}
