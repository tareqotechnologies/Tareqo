import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/tenant_local_data_source_impl.dart';
import 'package:tareqo/domain/entities/tenant.dart';

Tenant _tenant(
  String id, {
  String owner = 'u1',
  TenantStatus status = TenantStatus.pending,
  DateTime? createdAt,
}) => Tenant(
  id: id,
  ownerUserId: owner,
  businessName: 'Loja $id',
  planId: 'pl_starter',
  status: status,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
);

void main() {
  group('TenantLocalDataSourceImpl (memória — web/fallback)', () {
    test('getMyTenant resolve pelo DONO antes de tudo', () async {
      final ds = TenantLocalDataSourceImpl(
        seed: [_tenant('tn1', owner: 'u1', status: TenantStatus.approved)],
        employeeUserIds: ['u1'], // u1 também aparece como funcionário (seed).
      );

      final tenant = await ds.getMyTenant('u1');

      // Dono vence mesmo se o id também estiver na lista de funcionários.
      expect(tenant!.id, 'tn1');
    });

    test('getMyTenant devolve null para usuário desconhecido', () async {
      final ds = TenantLocalDataSourceImpl(seed: [_tenant('tn1')]);
      expect(await ds.getMyTenant('u-fantasma'), isNull);
    });

    test(
      'getMyTenant resolve FUNCIONÁRIO vinculado (não dono) ao 1º tenant',
      () async {
        final ds = TenantLocalDataSourceImpl(
          seed: [_tenant('tn1', status: TenantStatus.approved)],
          employeeUserIds: ['u-emp'],
        );

        final tenant = await ds.getMyTenant('u-emp');

        expect(tenant!.id, 'tn1');
      },
    );

    test(
      'getMyTenant vazio (sem seed) devolve null mesmo p/ funcionário',
      () async {
        final ds = TenantLocalDataSourceImpl(employeeUserIds: ['u2']);
        expect(await ds.getMyTenant('u2'), isNull);
      },
    );

    test('getById encontra o tenant certo (ou null)', () async {
      final ds = TenantLocalDataSourceImpl(
        seed: [
          _tenant('tn1'),
          _tenant('tn2', owner: 'u2'),
        ],
      );
      expect((await ds.getById('tn2'))!.id, 'tn2');
      expect(await ds.getById('tn-fantasma'), isNull);
    });

    test(
      'requestAccess cria tenant PENDING com moeda/idioma escolhidos',
      () async {
        final ds = TenantLocalDataSourceImpl();

        final tenant = await ds.requestAccess(
          ownerUserId: 'u9',
          businessName: 'Padaria Central',
          planId: 'pl_starter',
          currencyCode: 'MZN',
          language: 'pt',
        );

        expect(tenant.status, TenantStatus.pending);
        expect(tenant.ownerUserId, 'u9');
        expect(tenant.businessName, 'Padaria Central');
        expect(tenant.currencyCode, 'MZN');
        expect(tenant.language, 'pt');
        expect(tenant.id, startsWith('tn'));
        // Persistido no armazenamento:
        expect((await ds.getById(tenant.id))!.status, TenantStatus.pending);
      },
    );

    test('approve/reject/updatePlan/updateSettings mutam o estado', () async {
      final ds = TenantLocalDataSourceImpl(seed: [_tenant('tn1')]);

      await ds.approve('tn1');
      expect((await ds.getById('tn1'))!.status, TenantStatus.approved);
      expect((await ds.getById('tn1'))!.approvedAt, isNotNull);

      await ds.reject('tn1', 'documentação incompleta');
      expect((await ds.getById('tn1'))!.status, TenantStatus.rejected);
      expect(
        (await ds.getById('tn1'))!.rejectionReason,
        'documentação incompleta',
      );

      await ds.updatePlan('tn1', 'pl_pro');
      expect((await ds.getById('tn1'))!.planId, 'pl_pro');

      await ds.updateSettings('tn1', currencyCode: 'USD', language: 'en');
      final updated = await ds.getById('tn1');
      expect(updated!.currencyCode, 'USD');
      expect(updated.language, 'en');
    });

    test('updateBilling grava as datas de renovação', () async {
      final ds = TenantLocalDataSourceImpl(
        seed: [_tenant('tn1', status: TenantStatus.approved)],
      );
      final expires = DateTime(2026, 10, 1);
      final nextInvoice = DateTime(2026, 9, 24);

      await ds.updateBilling(
        'tn1',
        planExpiresAt: expires,
        nextInvoiceAt: nextInvoice,
      );

      final tenant = await ds.getById('tn1');
      expect(tenant!.planExpiresAt, expires);
      expect(tenant.nextInvoiceAt, nextInvoice);
    });

    test(
      'mutação de tenant inexistente lança StateError (não silencia)',
      () async {
        final ds = TenantLocalDataSourceImpl();
        await expectLater(ds.approve('fantasma'), throwsA(isA<StateError>()));
        await expectLater(
          ds.updatePlan('fantasma', 'pl_pro'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('getPending devolve só pendentes, ordenados por criação', () async {
      final ds = TenantLocalDataSourceImpl(
        seed: [
          _tenant('tn-velho', createdAt: DateTime(2026, 1, 1)),
          _tenant('tn-aprovado', status: TenantStatus.approved),
          _tenant('tn-novo', owner: 'u2', createdAt: DateTime(2026, 2, 1)),
        ],
      );

      final pending = await ds.getPending();

      expect(pending.map((t) => t.id), ['tn-velho', 'tn-novo']);
    });

    test('getAll devolve TODOS ordenados por criação', () async {
      final ds = TenantLocalDataSourceImpl(
        seed: [
          _tenant('tn2', createdAt: DateTime(2026, 2, 1)),
          _tenant('tn1', createdAt: DateTime(2026, 1, 1)),
        ],
      );

      expect((await ds.getAll()).map((t) => t.id), ['tn1', 'tn2']);
    });
  });
}
