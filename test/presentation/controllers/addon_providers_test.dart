import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/addon_local_data_source.dart';
import 'package:tareqo/domain/entities/addon.dart';
import 'package:tareqo/domain/entities/app_user.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/usecases/get_my_tenant_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/addon_providers.dart';
import 'package:tareqo/presentation/controllers/auth_providers.dart';

/// DataSource falso que grava as chamadas — o estado do notifier deve
/// refletir exatamente o que o datasource responde (contrato, não internos).
/// `_active` é mutável e cada teste decide o que o "banco" aceita.
class _RecordingAddOnDataSource implements AddOnLocalDataSource {
  _RecordingAddOnDataSource({Set<String> active = const {}})
    : activeIds = {...active};

  final Set<String> activeIds;
  final List<String> activateCalls = [];
  final List<String> deactivateCalls = [];

  @override
  Future<Set<String>> getActiveAddOnIds(String tenantId) async => {
    ...activeIds,
  };

  @override
  Future<void> activate(String tenantId, String addOnId) async =>
      activateCalls.add(addOnId);

  @override
  Future<void> deactivate(String tenantId, String addOnId) async =>
      deactivateCalls.add(addOnId);

  @override
  Future<void> register({
    required String tenantId,
    required String addOnId,
    DateTime? expiresAt,
  }) async {}

  @override
  Future<bool> isActive(String tenantId, String addOnId) async =>
      activeIds.contains(addOnId);

  @override
  Future<List<TenantAddOn>> getByTenant(String tenantId) async => [];

  @override
  Future<int> deactivateExpired() async => 0;

  @override
  Future<List<TenantAddOn>> getExpired() async => [];
}

class _FakeGetMyTenant implements GetMyTenantUseCase {
  _FakeGetMyTenant(this.tenant);

  final Tenant? tenant;

  @override
  Future<Tenant?> call(String userId) async => tenant;
}

Tenant _tenant() => Tenant(
  id: 'tn1',
  ownerUserId: 'u1',
  businessName: 'Loja Demo',
  planId: 'pl2',
  status: TenantStatus.approved,
  createdAt: DateTime(2026, 9, 1),
);

/// Monta o container com sessão + tenant + datasource espião.
(ProviderContainer, _RecordingAddOnDataSource) buildContainer({
  Set<String> active = const {},
  bool withTenant = true,
}) {
  final ds = _RecordingAddOnDataSource(active: active);
  final container = ProviderContainer(
    overrides: [
      authStateProvider.overrideWith(
        (ref) => Stream.value(const AppUser(id: 'u1', email: 'd@l.com')),
      ),
      getMyTenantUseCaseProvider.overrideWithValue(
        _FakeGetMyTenant(withTenant ? _tenant() : null),
      ),
      addOnDataSourceProvider.overrideWithValue(ds),
    ],
  );
  return (container, ds);
}

/// Resolve a cadeia auth → tenant → add-ons (testWidgets bombear os
/// microtask dos streams — mesma razão de tenant_settings_provider_test).
Future<void> settleAuthChain(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: SizedBox())),
  );
  final authSub = c.listen(authStateProvider, (_, _) {});
  await tester.pumpAndSettle();
  final tenantSub = c.listen(myTenantProvider('u1'), (_, _) {});
  await tester.runAsync(() => c.read(myTenantProvider('u1').future));
  addTearDown(() {
    authSub.close();
    tenantSub.close();
    c.dispose();
  });
}

void main() {
  testWidgets('estado inicial reflete os add-ons activos do datasource', (
    tester,
  ) async {
    final (c, _) = buildContainer(active: {'ao_invoices', 'ao_employees'});
    await settleAuthChain(tester, c);

    final ids = await tester.runAsync(
      () => c.read(activeAddOnIdsProvider.future),
    );
    expect(ids, {'ao_invoices', 'ao_employees'});
  });

  testWidgets('com sessão sem tenant o conjunto é vazio', (tester) async {
    final (c, _) = buildContainer(withTenant: false);
    await settleAuthChain(tester, c);

    final ids = await tester.runAsync(
      () => c.read(activeAddOnIdsProvider.future),
    );
    expect(ids, isEmpty);
  });

  testWidgets('activate persiste no datasource e refresca o estado', (
    tester,
  ) async {
    final (c, ds) = buildContainer();
    await settleAuthChain(tester, c);

    final notifier = c.read(activeAddOnIdsProvider.notifier);
    await tester.runAsync(() async {
      ds.activeIds.add('ao_invoices'); // o "banco" aceita a ativação
      await notifier.activate('ao_invoices');
    });

    expect(ds.activateCalls, ['ao_invoices']);
    final ids = await tester.runAsync(
      () => c.read(activeAddOnIdsProvider.future),
    );
    expect(ids, contains('ao_invoices'));
  });

  testWidgets('deactivate persiste e o estado deixa de conter o add-on', (
    tester,
  ) async {
    final (c, ds) = buildContainer(active: {'ao_invoices'});
    await settleAuthChain(tester, c);

    final notifier = c.read(activeAddOnIdsProvider.notifier);
    await tester.runAsync(() async {
      ds.activeIds.remove('ao_invoices'); // o "banco" aceita a desativação
      await notifier.deactivate('ao_invoices');
    });

    expect(ds.deactivateCalls, ['ao_invoices']);
    final ids = await tester.runAsync(
      () => c.read(activeAddOnIdsProvider.future),
    );
    expect(ids, isNot(contains('ao_invoices')));
  });

  testWidgets('toggle activa quando inactivo', (tester) async {
    final (c, ds) = buildContainer();
    await settleAuthChain(tester, c);

    // Garante o estado inicial resolvido antes do toggle (state.value).
    await tester.runAsync(() => c.read(activeAddOnIdsProvider.future));

    final notifier = c.read(activeAddOnIdsProvider.notifier);
    await tester.runAsync(() => notifier.toggle('ao_invoices'));

    expect(ds.activateCalls, ['ao_invoices']);
    expect(ds.deactivateCalls, isEmpty);
  });

  testWidgets('toggle desactiva quando activo', (tester) async {
    final (c, ds) = buildContainer(active: {'ao_invoices'});
    await settleAuthChain(tester, c);

    await tester.runAsync(() => c.read(activeAddOnIdsProvider.future));

    final notifier = c.read(activeAddOnIdsProvider.notifier);
    await tester.runAsync(() => notifier.toggle('ao_invoices'));

    expect(ds.deactivateCalls, ['ao_invoices']);
    expect(ds.activateCalls, isEmpty);
  });

  testWidgets('activate retorna AsyncData com o conjunto actualizado', (
    tester,
  ) async {
    final (c, ds) = buildContainer();
    await settleAuthChain(tester, c);

    final notifier = c.read(activeAddOnIdsProvider.notifier);
    await tester.runAsync(() async {
      ds.activeIds.add('ao_invoices');
      await notifier.activate('ao_invoices');
    });

    final value = c.read(activeAddOnIdsProvider);
    expect(value.hasValue, isTrue);
    expect(value.value, contains('ao_invoices'));
  });

  testWidgets('tenantActiveAddOnIdsProvider consulta o datasource por tenant', (
    tester,
  ) async {
    final (c, _) = buildContainer(active: {'ao_transfers'});
    await settleAuthChain(tester, c);

    final ids = await tester.runAsync(
      () => c.read(tenantActiveAddOnIdsProvider('tn1').future),
    );
    expect(ids, {'ao_transfers'});
  });

  testWidgets('isAddOnActiveProvider reflete o conjunto activo por id', (
    tester,
  ) async {
    final (c, _) = buildContainer(active: {'ao_invoices'});
    await settleAuthChain(tester, c);

    await tester.runAsync(() => c.read(activeAddOnIdsProvider.future));
    expect(c.read(isAddOnActiveProvider('ao_invoices')), isTrue);
    expect(c.read(isAddOnActiveProvider('ao_employees')), isFalse);
  });
}
