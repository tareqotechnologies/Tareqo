import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/addon_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/addon.dart';

TenantAddOn _record({
  required String tenantId,
  required String addOnId,
  bool isActive = true,
  DateTime? expiresAt,
}) =>
    TenantAddOn(
      id: 'ao-test',
      tenantId: tenantId,
      addOnId: addOnId,
      activatedAt: DateTime.now(),
      expiresAt: expiresAt,
      isActive: isActive,
    );

void main() {
 group('AddOnLocalDataSourceImpl', () {
  test('activate cria registo activo sem expiração', () async {
   final ds = AddOnLocalDataSourceImpl();

   await ds.activate('t1', 'ao_custom_invoice');

   expect(await ds.isActive('t1', 'ao_custom_invoice'), isTrue);
   expect(await ds.getActiveAddOnIds('t1'), {'ao_custom_invoice'});
   final byTenant = await ds.getByTenant('t1');
   expect(byTenant, hasLength(1));
   expect(byTenant.single.expiresAt, isNull);
  });

  test('reativação limpa a expiração antiga (add-on expirado volta activo)',
      () async {
   final past = DateTime.now().subtract(const Duration(days: 1));
   final ds = AddOnLocalDataSourceImpl(
    seed: [_record(tenantId: 't1', addOnId: 'ao_quotation', expiresAt: past)],
   );

   // Expirou: isActive() e a lista de activos rejeitam o registo.
   expect(await ds.isActive('t1', 'ao_quotation'), isFalse);
   expect(await ds.getActiveAddOnIds('t1'), isEmpty);

   // Renovação via activate(): limpa o expires_at antigo.
   await ds.activate('t1', 'ao_quotation');

   expect(await ds.isActive('t1', 'ao_quotation'), isTrue);
   expect(await ds.getActiveAddOnIds('t1'), {'ao_quotation'});
   final renewed = (await ds.getByTenant('t1')).single;
   expect(renewed.isActive, isTrue);
   expect(renewed.expiresAt, isNull);
  });

  test('getActiveAddOnIds não inclui expirados ainda marcados activos',
      () async {
   final past = DateTime.now().subtract(const Duration(hours: 2));
   final ds = AddOnLocalDataSourceImpl(
    seed: [
     _record(tenantId: 't1', addOnId: 'ao_reports'),
     _record(
      tenantId: 't1',
      addOnId: 'ao_multi_store',
      expiresAt: past,
     ),
     _record(tenantId: 't2', addOnId: 'ao_quotation'),
    ],
   );

   expect(await ds.getActiveAddOnIds('t1'), {'ao_reports'});
   // Outro tenant não é afetado.
   expect(await ds.getActiveAddOnIds('t2'), {'ao_quotation'});
  });

  test('deactivateExpired desactiva só os expirados e devolve a contagem',
      () async {
   final past = DateTime.now().subtract(const Duration(minutes: 5));
   final future = DateTime.now().add(const Duration(days: 30));
   final ds = AddOnLocalDataSourceImpl(
    seed: [
     _record(tenantId: 't1', addOnId: 'ao_a', expiresAt: past),
     _record(tenantId: 't1', addOnId: 'ao_b', expiresAt: future),
     _record(tenantId: 't1', addOnId: 'ao_c'),
    ],
   );

   expect(await ds.deactivateExpired(), 1);
   expect(await ds.getActiveAddOnIds('t1'), {'ao_b', 'ao_c'});
   final expired = (await ds.getByTenant('t1'))
     .firstWhere((r) => r.addOnId == 'ao_a');
   expect(expired.isActive, isFalse);
   expect(await ds.getExpired(), isEmpty);
  });

  test('register é idempotente: renovar substitui o registo, sem duplicar',
      () async {
   final ds = AddOnLocalDataSourceImpl();
   final firstExpiry = DateTime.now().add(const Duration(days: 7));
   final secondExpiry = DateTime.now().add(const Duration(days: 30));

   await ds.register(
    tenantId: 't1',
    addOnId: 'ao_employee_mgmt',
    expiresAt: firstExpiry,
   );
   await ds.register(
    tenantId: 't1',
    addOnId: 'ao_employee_mgmt',
    expiresAt: secondExpiry,
   );

   final byTenant = await ds.getByTenant('t1');
   expect(byTenant, hasLength(1));
   expect(byTenant.single.expiresAt!.isAfter(firstExpiry), isTrue);
   expect(await ds.isActive('t1', 'ao_employee_mgmt'), isTrue);
  });

  test('deactivate desliga o add-on e exclui-o da lista de activos', () async {
   final ds = AddOnLocalDataSourceImpl(
    seed: [_record(tenantId: 't1', addOnId: 'ao_custom_invoice')],
   );

   await ds.deactivate('t1', 'ao_custom_invoice');

   expect(await ds.isActive('t1', 'ao_custom_invoice'), isFalse);
   expect(await ds.getActiveAddOnIds('t1'), isEmpty);
   expect(await ds.getByTenant('t1'), hasLength(1));
  });
 });
}
