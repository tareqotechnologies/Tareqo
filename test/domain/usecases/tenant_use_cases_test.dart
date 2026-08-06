import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/repositories/i_tenant_repository.dart';
import 'package:dumbhanengue/domain/usecases/approve_tenant_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_all_tenants_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_my_tenant_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_tenants_use_case.dart';
import 'package:dumbhanengue/domain/usecases/reject_tenant_use_case.dart';
import 'package:dumbhanengue/domain/usecases/request_tenant_access_use_case.dart';
import 'package:dumbhanengue/domain/usecases/update_tenant_settings_use_case.dart';

class _FakeTenantRepository implements ITenantRepository {
  final List<Tenant> _tenants = [];

  @override
  Future<Tenant?> getMyTenant(String userId) async {
    for (final tenant in _tenants) {
      if (tenant.ownerUserId == userId) return tenant;
    }
    return null;
  }

  @override
  Future<Tenant?> getById(String id) async {
    for (final tenant in _tenants) {
      if (tenant.id == id) return tenant;
    }
    return null;
  }

  @override
  Future<Tenant> requestAccess({
    required String ownerUserId,
    required String businessName,
    required String planId,
    required String currencyCode,
    required String language,
  }) async {
    final tenant = Tenant(
      id: 'tn1',
      ownerUserId: ownerUserId,
      businessName: businessName,
      planId: planId,
      status: TenantStatus.pending,
      createdAt: DateTime.now(),
      currencyCode: currencyCode,
      language: language,
    );
    _tenants.add(tenant);
    return tenant;
  }

  @override
  Future<void> updateSettings(
    String id, {
    required String currencyCode,
    required String language,
  }) async {
    final index = _tenants.indexWhere((tenant) => tenant.id == id);
    _tenants[index] = _tenants[index].copyWith(
      currencyCode: currencyCode,
      language: language,
    );
  }

  @override
  Future<void> approve(String id) async {
    final index = _tenants.indexWhere((tenant) => tenant.id == id);
    _tenants[index] = _tenants[index].copyWith(
      status: TenantStatus.approved,
      approvedAt: DateTime.now(),
    );
  }

  @override
  Future<void> reject(String id, String reason) async {
    final index = _tenants.indexWhere((tenant) => tenant.id == id);
    _tenants[index] = _tenants[index].copyWith(
      status: TenantStatus.rejected,
      rejectionReason: reason,
    );
  }

  @override
  Future<void> updatePlan(String id, String planId) async {}

  @override
  Future<List<Tenant>> getPending() async => List.unmodifiable(
        _tenants.where((tenant) => tenant.status == TenantStatus.pending),
      );

  @override
  Future<List<Tenant>> getAll() async => List.unmodifiable(_tenants);
}

void main() {
  group('RequestTenantAccessUseCase', () {
    test('cria a solicitação com status pending', () async {
      final repository = _FakeTenantRepository();
      final useCase = RequestTenantAccessUseCase(repository);

      final tenant = await useCase(
        ownerUserId: 'u1',
        businessName: 'Comercial X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );

      expect(tenant.status, TenantStatus.pending);
      expect(tenant.businessName, 'Comercial X');
      expect((await repository.getAll()), hasLength(1));
    });

    test('lança InvalidTenantRequestException sem nome do negócio', () async {
      final useCase = RequestTenantAccessUseCase(_FakeTenantRepository());

      await expectLater(
        useCase(
          ownerUserId: 'u1',
          businessName: '  ',
          planId: 'pl1',
          currencyCode: 'BRL',
          language: 'pt',
        ),
        throwsA(isA<InvalidTenantRequestException>()),
      );
    });

    test('lança InvalidTenantRequestException sem plano', () async {
      final useCase = RequestTenantAccessUseCase(_FakeTenantRepository());

      await expectLater(
        useCase(
          ownerUserId: 'u1',
          businessName: 'X',
          planId: '',
          currencyCode: 'BRL',
          language: 'pt',
        ),
        throwsA(isA<InvalidTenantRequestException>()),
      );
    });

    test('bloqueia nova solicitação quando o usuário já tem tenant (S3)',
        () async {
      final repository = _FakeTenantRepository();
      final useCase = RequestTenantAccessUseCase(repository);

      // Primeira solicitação é criada normalmente.
      await useCase(
        ownerUserId: 'u1',
        businessName: 'Comercial X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );

      // Segunda solicitação (re-submissão) é bloqueada com mensagem amigável.
      await expectLater(
        useCase(
          ownerUserId: 'u1',
          businessName: 'Comercial Y',
          planId: 'pl1',
          currencyCode: 'BRL',
          language: 'pt',
        ),
        throwsA(
          isA<InvalidTenantRequestException>().having(
            (e) => e.message,
            'message',
            contains('já possui um cadastro'),
          ),
        ),
      );
      expect(await repository.getAll(), hasLength(1));
    });
  });

  group('Fluxo de aprovação', () {
    test('aprova o tenant e marca a data', () async {
      final repository = _FakeTenantRepository();
      final request = await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u1',
        businessName: 'X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );

      await ApproveTenantUseCase(repository).call(request.id);

      final approved = await repository.getById(request.id);
      expect(approved!.status, TenantStatus.approved);
      expect(approved.approvedAt, isNotNull);
    });

    test('rejeita o tenant com motivo', () async {
      final repository = _FakeTenantRepository();
      final request = await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u1',
        businessName: 'X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );

      await RejectTenantUseCase(repository).call(
        request.id,
        'Cadastro incompleto',
      );

      final rejected = await repository.getById(request.id);
      expect(rejected!.status, TenantStatus.rejected);
      expect(rejected.rejectionReason, 'Cadastro incompleto');
    });

    test('getPending retorna apenas os pendentes', () async {
      final repository = _FakeTenantRepository();
      final request = await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u1',
        businessName: 'X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );
      await ApproveTenantUseCase(repository).call(request.id);
      await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u2',
        businessName: 'Y',
        planId: 'pl2',
        currencyCode: 'BRL',
        language: 'pt',
      );

      final pending = await GetPendingTenantsUseCase(repository)();
      expect(pending, hasLength(1));
      expect(pending.first.businessName, 'Y');
    });

    test('getAll retorna todos os tenants', () async {
      final repository = _FakeTenantRepository();
      await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u1',
        businessName: 'X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );
      await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u2',
        businessName: 'Y',
        planId: 'pl2',
        currencyCode: 'BRL',
        language: 'pt',
      );

      expect(await GetAllTenantsUseCase(repository)(), hasLength(2));
    });

    test('getMyTenant retorna o tenant do dono', () async {
      final repository = _FakeTenantRepository();
      await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u1',
        businessName: 'X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );

      final tenant = await GetMyTenantUseCase(repository).call('u1');
      expect(tenant, isNotNull);
      expect(tenant!.ownerUserId, 'u1');
      expect(await GetMyTenantUseCase(repository).call('u99'), isNull);
    });
  });

  group('UpdateTenantSettingsUseCase', () {
    test('atualiza moeda e idioma do tenant', () async {
      final repository = _FakeTenantRepository();
      final request = await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u1',
        businessName: 'X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );

      await UpdateTenantSettingsUseCase(repository).call(
        tenantId: request.id,
        currencyCode: 'USD',
        language: 'en',
      );

      final updated = await repository.getById(request.id);
      expect(updated!.currencyCode, 'USD');
      expect(updated.language, 'en');
    });

    test('normaliza valores fora do conjunto suportado', () async {
      final repository = _FakeTenantRepository();
      final request = await RequestTenantAccessUseCase(repository)(
        ownerUserId: 'u1',
        businessName: 'X',
        planId: 'pl1',
        currencyCode: 'BRL',
        language: 'pt',
      );

      await UpdateTenantSettingsUseCase(repository).call(
        tenantId: request.id,
        currencyCode: 'XXX',
        language: 'fr',
      );

      final updated = await repository.getById(request.id);
      expect(updated!.currencyCode, 'BRL');
      expect(updated.language, 'pt');
    });
  });
}
