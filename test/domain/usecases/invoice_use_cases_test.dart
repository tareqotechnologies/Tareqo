import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/invoice.dart';
import 'package:dumbhanengue/domain/entities/plan.dart';
import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/repositories/i_invoice_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_plan_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_tenant_repository.dart';
import 'package:dumbhanengue/domain/usecases/approve_tenant_use_case.dart';
import 'package:dumbhanengue/domain/usecases/cancel_invoice_use_case.dart';
import 'package:dumbhanengue/domain/usecases/check_tenants_for_invoices_use_case.dart';
import 'package:dumbhanengue/domain/usecases/generate_invoice_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_all_invoices_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_pending_invoices_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_tenant_invoices_use_case.dart';
import 'package:dumbhanengue/domain/usecases/mark_invoice_as_paid_use_case.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class _FakeInvoiceRepository implements IInvoiceRepository {
  final List<Invoice> _invoices = [];
  bool createCalled = false;
  bool markAsPaidCalled = false;
  bool cancelCalled = false;

  @override
  Future<Invoice> create(Invoice invoice) async {
    createCalled = true;
    final number = _invoices.length + 1;
    final created = invoice.copyWith(
      id: invoice.id.isEmpty ? 'inv_$number' : invoice.id,
      number: number,
    );
    _invoices.add(created);
    return created;
  }

  @override
  Future<List<Invoice>> getByTenant(String tenantId) async =>
      List.unmodifiable(
        _invoices
            .where((i) => i.tenantId == tenantId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  @override
  Future<List<Invoice>> getPending() async => List.unmodifiable(
        _invoices
            .where((i) => i.status == InvoiceStatus.pending)
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );

  @override
  Future<List<Invoice>> getAll() async => List.unmodifiable(
        [..._invoices]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
      );

  @override
  Future<void> markAsPaid(String invoiceId) async {
    markAsPaidCalled = true;
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index < 0) {
      throw StateError('Factura $invoiceId não encontrada.');
    }
    _invoices[index] = _invoices[index].copyWith(
      status: InvoiceStatus.paid,
      paidAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancel(String invoiceId) async {
    cancelCalled = true;
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index < 0) {
      throw StateError('Factura $invoiceId não encontrada.');
    }
    _invoices[index] = _invoices[index].copyWith(
      status: InvoiceStatus.cancelled,
    );
  }

  @override
  Future<bool> hasPendingForPeriod(String tenantId, String period) async {
    return _invoices.any(
      (i) =>
          i.tenantId == tenantId &&
          i.period == period &&
          i.status == InvoiceStatus.pending,
    );
  }
}

class _FakePlanRepository implements IPlanRepository {
  final List<Plan> _plans = [];

  Future<void> addPlan(Plan plan) async => _plans.add(plan);

  @override
  Future<List<Plan>> getActivePlans() async =>
      List.unmodifiable(_plans.where((p) => p.isActive));

  @override
  Future<List<Plan>> getAllPlans() async => List.unmodifiable(_plans);

  @override
  Future<Plan?> getById(String id) async {
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  @override
  Future<void> add(Plan plan) async => _plans.add(plan);

  @override
  Future<void> update(Plan plan) async {
    final index = _plans.indexWhere((p) => p.id == plan.id);
    if (index >= 0) _plans[index] = plan;
  }
}

class _FakeTenantRepository implements ITenantRepository {
  final List<Tenant> _tenants = [];

  void seedTenant(Tenant tenant) => _tenants.add(tenant);

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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateSettings(
    String id, {
    required String currencyCode,
    required String language,
  }) async {}

  @override
  Future<void> approve(String id) async {
    final index = _tenants.indexWhere((t) => t.id == id);
    _tenants[index] = _tenants[index].copyWith(
      status: TenantStatus.approved,
      approvedAt: DateTime.now(),
    );
  }

  @override
  Future<void> reject(String id, String reason) async {}

  @override
  Future<void> updatePlan(String id, String planId) async {
    final index = _tenants.indexWhere((t) => t.id == id);
    _tenants[index] = _tenants[index].copyWith(planId: planId);
  }

  @override
  Future<List<Tenant>> getPending() async => List.unmodifiable(
        _tenants.where((t) => t.status == TenantStatus.pending),
      );

  @override
  Future<List<Tenant>> getAll() async => List.unmodifiable(_tenants);

  @override
  Future<void> updateBilling(
    String id, {
    required DateTime planExpiresAt,
    required DateTime nextInvoiceAt,
  }) async {
    final index = _tenants.indexWhere((t) => t.id == id);
    _tenants[index] = _tenants[index].copyWith(
      planExpiresAt: planExpiresAt,
      nextInvoiceAt: nextInvoiceAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Tenant _approvedTenant({
  String id = 'tn1',
  String planId = 'pl1',
  DateTime? planExpiresAt,
  DateTime? nextInvoiceAt,
}) =>
    Tenant(
      id: id,
      ownerUserId: 'u1',
      businessName: 'Comercial X',
      planId: planId,
      status: TenantStatus.approved,
      approvedAt: DateTime.now().subtract(const Duration(days: 14)),
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      planExpiresAt: planExpiresAt,
      nextInvoiceAt: nextInvoiceAt,
    );

Plan _basicPlan({
  String id = 'pl1',
  String name = 'Essencial',
  int priceMonthlyCents = 5000,
}) =>
    Plan(
      id: id,
      name: name,
      priceMonthlyCents: priceMonthlyCents,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GenerateInvoiceUseCase', () {
    test('cria factura quando tenant e plano existem e não há duplicação',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));
      tenantRepo.seedTenant(_approvedTenant(
        planExpiresAt: expiresAt,
      ));
      planRepo.add(_basicPlan());

      final useCase = GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final invoice = await useCase('tn1');

      expect(invoice, isNotNull);
      expect(invoice!.tenantId, 'tn1');
      expect(invoice.planId, 'pl1');
      expect(invoice.amountCents, 5000);
      expect(invoice.status, InvoiceStatus.pending);
      expect(invoice.dueDate, expiresAt);
      expect(invoice.period, isNotEmpty);
      expect(invoiceRepo.createCalled, isTrue);
    });

    test('retorna null quando tenant não existe', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final useCase = GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final invoice = await useCase('inexistente');

      expect(invoice, isNull);
      expect(invoiceRepo.createCalled, isFalse);
    });

    test('retorna null quando plano não existe', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      tenantRepo.seedTenant(_approvedTenant());
      // Não adiciona nenhum plano

      final useCase = GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final invoice = await useCase('tn1');

      expect(invoice, isNull);
      expect(invoiceRepo.createCalled, isFalse);
    });

    test('retorna null quando já existe factura pendente para o período',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      tenantRepo.seedTenant(_approvedTenant());
      planRepo.add(_basicPlan());

      // Cria primeira factura
      final useCase = GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      await useCase('tn1');
      expect(invoiceRepo._invoices, hasLength(1));

      // Tenta criar segunda factura (duplicação)
      final invoice = await useCase('tn1');
      expect(invoice, isNull);
      expect(invoiceRepo._invoices, hasLength(1)); // Não duplicou
    });

    test('usa planExpiresAt como dueDate quando definido', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final expiresAt = DateTime(2026, 9, 15);
      tenantRepo.seedTenant(_approvedTenant(planExpiresAt: expiresAt));
      planRepo.add(_basicPlan());

      final useCase = GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final invoice = await useCase('tn1');

      expect(invoice!.dueDate, expiresAt);
    });

    test('gera período no formato "Mês Ano"', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      tenantRepo.seedTenant(_approvedTenant());
      planRepo.add(_basicPlan());

      final useCase = GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final invoice = await useCase('tn1');

      // Verifica se o período contém mês e ano
      expect(invoice!.period, contains(' '));
      final parts = invoice.period.split(' ');
      expect(parts.length, 2);
      expect(int.tryParse(parts[1]), isNotNull); // Ano é numérico
    });
  });

  group('GetTenantInvoicesUseCase', () {
    test('retorna facturas de um tenant específico', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final now = DateTime.now();

      // Adiciona facturas de dois tenants
      invoiceRepo._invoices.addAll([
        Invoice(
          id: 'inv1',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 5000,
          dueDate: now,
          period: 'Agosto 2026',
          createdAt: now,
        ),
        Invoice(
          id: 'inv2',
          tenantId: 'tn2',
          planId: 'pl1',
          amountCents: 3000,
          dueDate: now,
          period: 'Agosto 2026',
          createdAt: now,
        ),
        Invoice(
          id: 'inv3',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 5000,
          dueDate: now,
          period: 'Julho 2026',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ]);

      final useCase = GetTenantInvoicesUseCase(invoiceRepo);
      final result = await useCase('tn1');

      expect(result, hasLength(2));
      expect(result.every((i) => i.tenantId == 'tn1'), isTrue);
    });

    test('retorna lista vazia quando tenant não tem facturas', () async {
      final invoiceRepo = _FakeInvoiceRepository();

      final useCase = GetTenantInvoicesUseCase(invoiceRepo);
      final result = await useCase('tn_inexistente');

      expect(result, isEmpty);
    });
  });

  group('GetPendingInvoicesUseCase', () {
    test('retorna apenas facturas pendentes', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final now = DateTime.now();

      invoiceRepo._invoices.addAll([
        Invoice(
          id: 'inv1',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 5000,
          status: InvoiceStatus.pending,
          dueDate: now,
          period: 'Agosto 2026',
          createdAt: now,
        ),
        Invoice(
          id: 'inv2',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 5000,
          status: InvoiceStatus.paid,
          dueDate: now,
          period: 'Julho 2026',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
        Invoice(
          id: 'inv3',
          tenantId: 'tn2',
          planId: 'pl1',
          amountCents: 3000,
          status: InvoiceStatus.cancelled,
          dueDate: now,
          period: 'Agosto 2026',
          createdAt: now,
        ),
      ]);

      final useCase = GetPendingInvoicesUseCase(invoiceRepo);
      final result = await useCase();

      expect(result, hasLength(1));
      expect(result.first.id, 'inv1');
      expect(result.first.status, InvoiceStatus.pending);
    });

    test('retorna lista vazia quando não há pendentes', () async {
      final invoiceRepo = _FakeInvoiceRepository();

      final useCase = GetPendingInvoicesUseCase(invoiceRepo);
      final result = await useCase();

      expect(result, isEmpty);
    });
  });

  group('GetAllInvoicesUseCase', () {
    test('retorna todas as facturas independentemente do estado', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final now = DateTime.now();

      invoiceRepo._invoices.addAll([
        Invoice(
          id: 'inv1',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 5000,
          status: InvoiceStatus.pending,
          dueDate: now,
          period: 'Agosto 2026',
          createdAt: now,
        ),
        Invoice(
          id: 'inv2',
          tenantId: 'tn1',
          planId: 'pl1',
          amountCents: 5000,
          status: InvoiceStatus.paid,
          dueDate: now,
          period: 'Julho 2026',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ]);

      final useCase = GetAllInvoicesUseCase(invoiceRepo);
      final result = await useCase();

      expect(result, hasLength(2));
    });
  });

  group('MarkInvoiceAsPaidUseCase', () {
    test('marca factura como paga', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final now = DateTime.now();

      invoiceRepo._invoices.add(Invoice(
        id: 'inv1',
        tenantId: 'tn1',
        planId: 'pl1',
        amountCents: 5000,
        status: InvoiceStatus.pending,
        dueDate: now,
        period: 'Agosto 2026',
        createdAt: now,
      ));

      final useCase = MarkInvoiceAsPaidUseCase(invoiceRepo);
      await useCase('inv1');

      expect(invoiceRepo.markAsPaidCalled, isTrue);
      expect(invoiceRepo._invoices.first.status, InvoiceStatus.paid);
      expect(invoiceRepo._invoices.first.paidAt, isNotNull);
    });

    test('lança StateError quando factura não existe', () async {
      final invoiceRepo = _FakeInvoiceRepository();

      final useCase = MarkInvoiceAsPaidUseCase(invoiceRepo);

      expect(
        () => useCase('inexistente'),
        throwsStateError,
      );
    });
  });

  group('CancelInvoiceUseCase', () {
    test('cancela factura', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final now = DateTime.now();

      invoiceRepo._invoices.add(Invoice(
        id: 'inv1',
        tenantId: 'tn1',
        planId: 'pl1',
        amountCents: 5000,
        status: InvoiceStatus.pending,
        dueDate: now,
        period: 'Agosto 2026',
        createdAt: now,
      ));

      final useCase = CancelInvoiceUseCase(invoiceRepo);
      await useCase('inv1');

      expect(invoiceRepo.cancelCalled, isTrue);
      expect(invoiceRepo._invoices.first.status, InvoiceStatus.cancelled);
    });

    test('lança StateError quando factura não existe', () async {
      final invoiceRepo = _FakeInvoiceRepository();

      final useCase = CancelInvoiceUseCase(invoiceRepo);

      expect(
        () => useCase('inexistente'),
        throwsStateError,
      );
    });
  });

  group('CheckTenantsForInvoicesUseCase', () {
    test('gera factura quando nextInvoiceAt já foi atingido', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));

      // Tenant com nextInvoiceAt no passado (deve receber factura)
      tenantRepo.seedTenant(_approvedTenant(
        planExpiresAt: now.add(const Duration(days: 23)),
        nextInvoiceAt: pastDate,
      ));
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      final generated = await checkUseCase();

      expect(generated, hasLength(1));
      expect(generated.first.tenantId, 'tn1');
      expect(invoiceRepo._invoices, hasLength(1));

      // Verifica que o billing foi actualizado
      final tenant = await tenantRepo.getById('tn1');
      expect(tenant!.nextInvoiceAt, isNotNull);
      expect(tenant.nextInvoiceAt!.isAfter(now), isTrue);
    });

    test('não gera factura quando nextInvoiceAt ainda não foi atingido',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 5));

      // Tenant com nextInvoiceAt no futuro (não deve receber factura)
      tenantRepo.seedTenant(_approvedTenant(
        planExpiresAt: now.add(const Duration(days: 12)),
        nextInvoiceAt: futureDate,
      ));
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      final generated = await checkUseCase();

      expect(generated, isEmpty);
      expect(invoiceRepo._invoices, isEmpty);
    });

    test('ignora tenants não aprovados', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();

      // Tenant pendente (não deve receber factura)
      tenantRepo.seedTenant(Tenant(
        id: 'tn1',
        ownerUserId: 'u1',
        businessName: 'Comercial X',
        planId: 'pl1',
        status: TenantStatus.pending,
        createdAt: now,
        nextInvoiceAt: now.subtract(const Duration(days: 1)),
      ));
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      final generated = await checkUseCase();

      expect(generated, isEmpty);
      expect(invoiceRepo._invoices, isEmpty);
    });

    test('ignora tenants sem nextInvoiceAt', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      // Tenant aprovado sem nextInvoiceAt
      tenantRepo.seedTenant(_approvedTenant());
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      final generated = await checkUseCase();

      expect(generated, isEmpty);
    });

    test('gera facturas para múltiplos tenants elegíveis', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));

      // Dois tenants elegíveis
      tenantRepo.seedTenant(_approvedTenant(
        id: 'tn1',
        planExpiresAt: now.add(const Duration(days: 23)),
        nextInvoiceAt: pastDate,
      ));
      tenantRepo.seedTenant(_approvedTenant(
        id: 'tn2',
        planId: 'pl2',
        planExpiresAt: now.add(const Duration(days: 20)),
        nextInvoiceAt: pastDate,
      ));
      planRepo.add(_basicPlan());
      planRepo.add(_basicPlan(id: 'pl2', name: 'Premium', priceMonthlyCents: 10000));

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      final generated = await checkUseCase();

      expect(generated, hasLength(2));
      expect(invoiceRepo._invoices, hasLength(2));
    });

    test('avança o ciclo mensal correctamente após gerar factura', () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 1));

      tenantRepo.seedTenant(_approvedTenant(
        planExpiresAt: now.add(const Duration(days: 23)),
        nextInvoiceAt: pastDate,
      ));
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      await checkUseCase();

      // Verifica que o billing foi actualizado para o próximo ciclo
      final tenant = await tenantRepo.getById('tn1');
      expect(tenant!.planExpiresAt, isNotNull);
      expect(tenant.nextInvoiceAt, isNotNull);

      // Próximo planExpiresAt deve ser ~30 dias no futuro
      final daysUntilExpires =
          tenant.planExpiresAt!.difference(now).inDays;
      expect(daysUntilExpires, greaterThanOrEqualTo(29));
      expect(daysUntilExpires, lessThanOrEqualTo(31));

      // Próximo nextInvoiceAt deve ser 7 dias antes de planExpiresAt
      final daysBetween =
          tenant.planExpiresAt!.difference(tenant.nextInvoiceAt!).inDays;
      expect(daysBetween, kInvoiceAdvanceDays);
    });

    test('retorna lista vazia quando nenhum tenant precisa de factura',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();

      // Tenant com nextInvoiceAt no futuro
      tenantRepo.seedTenant(_approvedTenant(
        nextInvoiceAt: now.add(const Duration(days: 5)),
      ));
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      final generated = await checkUseCase();

      expect(generated, isEmpty);
      expect(invoiceRepo._invoices, isEmpty);
    });
  });

  group('Ciclo de facturacao (integração)', () {
    test('trial de 14 dias: primeira factura gerada ao fim do trial',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();
      final trialEnd = now.subtract(const Duration(days: 1)); // trial já terminou

      // Tenant com trial de 14 dias que já expirou
      tenantRepo.seedTenant(_approvedTenant(
        planExpiresAt: now.add(const Duration(days: 13)),
        nextInvoiceAt: trialEnd, // factura gerada ontem (trial terminou)
      ));
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      // Simula que o trial terminou
      final generated = await checkUseCase();

      expect(generated, hasLength(1));
      expect(generated.first.amountCents, 5000);
    });

    test('ciclo mensal: após trial, facturas mensais são geradas',
        () async {
      final invoiceRepo = _FakeInvoiceRepository();
      final tenantRepo = _FakeTenantRepository();
      final planRepo = _FakePlanRepository();

      final now = DateTime.now();

      // Tenant com trial já expirado (factura pendente)
      tenantRepo.seedTenant(_approvedTenant(
        planExpiresAt: now.add(const Duration(days: 23)),
        nextInvoiceAt: now.subtract(const Duration(days: 1)),
      ));
      planRepo.add(_basicPlan());

      final generateUseCase =
          GenerateInvoiceUseCase(invoiceRepo, tenantRepo, planRepo);
      final checkUseCase =
          CheckTenantsForInvoicesUseCase(generateUseCase, tenantRepo);

      // Primeira factura (fim do trial)
      final first = await checkUseCase();
      expect(first, hasLength(1));

      // Próxima factura ainda não está disponível (nextInvoiceAt no futuro)
      final second = await checkUseCase();
      expect(second, isEmpty);
    });
  });
}
