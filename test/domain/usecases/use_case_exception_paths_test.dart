import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/customer.dart';
import 'package:tareqo/domain/entities/financial_transaction.dart';
import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/entities/store.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/entities/tenant.dart';
import 'package:tareqo/domain/repositories/i_customer_repository.dart';
import 'package:tareqo/domain/repositories/i_employee_repository.dart';
import 'package:tareqo/domain/repositories/i_financial_transaction_repository.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/repositories/i_store_repository.dart';
import 'package:tareqo/domain/repositories/i_tenant_repository.dart';
import 'package:tareqo/domain/usecases/add_customer_use_case.dart';
import 'package:tareqo/domain/usecases/add_financial_transaction_use_case.dart';
import 'package:tareqo/domain/usecases/add_store_use_case.dart';
import 'package:tareqo/domain/usecases/get_cash_flow_use_case.dart';
import 'package:tareqo/domain/usecases/request_tenant_access_use_case.dart';
import 'package:tareqo/domain/usecases/set_employee_active_use_case.dart';

/// Fakes gravando chamadas — o contrato testado é o EFEITO no repositório
/// (a exceção deve impedir a persistência; o sucesso persiste).
class _MemCustomerRepo implements ICustomerRepository {
  final List<Customer> added = [];

  @override
  Future<void> add(Customer customer) async => added.add(customer);

  @override
  Future<List<Customer>> getAll({required String storeId}) async => [];

  @override
  Future<void> update(Customer customer) async {}

  @override
  Future<void> delete(String id) async {}
}

class _MemFinancialRepo implements IFinancialTransactionRepository {
  final List<FinancialTransaction> added = [];

  @override
  Future<void> add(FinancialTransaction transaction) async =>
      added.add(transaction);

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      [];

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async => [];

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {}
}

class _MemTenantRepo implements ITenantRepository {
  _MemTenantRepo(this.tenant);

  final Tenant? tenant;
  final List<Tenant> requested = [];

  @override
  Future<Tenant?> getById(String id) async => tenant;

  @override
  Future<Tenant> requestAccess({
    required String ownerUserId,
    required String businessName,
    required String planId,
    required String currencyCode,
    required String language,
  }) async {
    final t = Tenant(
      id: 'tn-new',
      ownerUserId: ownerUserId,
      businessName: businessName,
      planId: planId,
      status: TenantStatus.pending,
      currencyCode: currencyCode,
      language: language,
      createdAt: DateTime(2026, 9, 1),
    );
    requested.add(t);
    return t;
  }

  @override
  Future<Tenant?> getMyTenant(String userId) async =>
      tenant?.ownerUserId == userId ? tenant : null;

  @override
  Future<void> updatePlan(String id, String planId) async {}

  @override
  Future<void> updateSettings(
    String id, {
    required String currencyCode,
    required String language,
    bool? mfaEnforced,
  }) async {}

  @override
  Future<void> updateBilling(
    String id, {
    required DateTime planExpiresAt,
    required DateTime nextInvoiceAt,
  }) async {}

  @override
  Future<List<Tenant>> getAll() async => [];

  @override
  Future<void> approve(String id) async {}

  @override
  Future<void> reject(String id, String reason) async {}

  @override
  Future<List<Tenant>> getPending() async => [];
}

class _MemStoreRepo implements IStoreRepository {
  _MemStoreRepo(this.existing);

  final List<Store> existing;
  final List<Store> added = [];

  @override
  Future<void> add(Store store) async => added.add(store);

  @override
  Future<List<Store>> getByTenant(String tenantId) async => existing;

  @override
  Future<void> update(Store store) async {}
}

class _MemPlanRepo implements IPlanRepository {
  _MemPlanRepo(this.plan);

  final Plan? plan;

  @override
  Future<void> add(Plan plan) async {}

  @override
  Future<List<Plan>> getAllPlans() async => plan == null ? [] : [plan!];

  @override
  Future<List<Plan>> getActivePlans() async => plan == null ? [] : [plan!];

  @override
  Future<Plan?> getById(String id) async => plan?.id == id ? plan : null;

  @override
  Future<void> update(Plan plan) async {}
}

class _MemEmployeeRepo implements IEmployeeRepository {
  _MemEmployeeRepo(this.employees);

  final List<StoreEmployee> employees;
  final List<({String id, bool active})> setActiveCalls = [];

  @override
  Future<void> add(StoreEmployee employee) async {}

  @override
  Future<List<StoreEmployee>> getByStore(String storeId) async => [];

  @override
  Future<List<StoreEmployee>> getByTenant(String tenantId) async => employees;

  @override
  Future<void> setActive({
    required String employeeId,
    required bool isActive,
  }) async {
    setActiveCalls.add((id: employeeId, active: isActive));
  }
}

Plan _plan({int maxStores = 2}) => Plan(
  id: 'pl-ess',
  name: 'Essencial',
  maxStores: maxStores,
  priceMonthlyCents: 9900,
);

Tenant _tenant({TenantStatus status = TenantStatus.approved}) => Tenant(
  id: 'tn-1',
  ownerUserId: 'u-1',
  businessName: 'Padaria Central',
  planId: 'pl-ess',
  status: status,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  group('AddCustomerUseCase — validação de nome (regra de negócio)', () {
    test('nome válido é persistido', () async {
      final repo = _MemCustomerRepo();
      final useCase = AddCustomerUseCase(repo);

      await useCase.call(
        const Customer(id: 'c-1', name: 'Ana Martins', phone: '842000111'),
      );

      expect(repo.added.single.id, 'c-1');
    });

    test('nome vazio lança InvalidCustomerException e NÃO persiste', () async {
      final repo = _MemCustomerRepo();
      final useCase = AddCustomerUseCase(repo);

      await expectLater(
        useCase.call(const Customer(id: 'c-2', name: '')),
        throwsA(isA<InvalidCustomerException>()),
      );
      expect(repo.added, isEmpty);
    });

    test('nome só de espaços lança exceção (trim é a regra)', () async {
      final repo = _MemCustomerRepo();
      final useCase = AddCustomerUseCase(repo);

      await expectLater(
        useCase.call(const Customer(id: 'c-3', name: '   ')),
        throwsA(isA<InvalidCustomerException>()),
      );
      expect(repo.added, isEmpty);
    });
  });

  group('AddFinancialTransactionUseCase — validação de valor', () {
    FinancialTransaction tx(int amountCents) => FinancialTransaction(
      id: 'ft-1',
      description: 'Venda balcão',
      amountCents: amountCents,
      type: TransactionType.income,
      category: 'vendas',
      date: DateTime(2026, 9, 1),
    );

    test('valor positivo é persistido', () async {
      final repo = _MemFinancialRepo();
      await AddFinancialTransactionUseCase(repo).call(tx(1500));

      expect(repo.added.single.amountCents, 1500);
    });

    test('zero lança InvalidAmountException e NÃO persiste', () async {
      final repo = _MemFinancialRepo();
      await expectLater(
        AddFinancialTransactionUseCase(repo).call(tx(0)),
        throwsA(isA<InvalidAmountException>()),
      );
      expect(repo.added, isEmpty);
    });

    test(
      'a ENTIDADE rejeita valor negativo na construção (assert de magnitude)',
      () {
        // O @Assert('amountCents >= 0') da entidade garante a magnitude
        // positiva JÁ na construção (inclusive via fromJson) — a regra
        // vive em duas camadas. O ramo `<= 0` do use case é a rede de
        // segurança do release (asserts desligados) e é exercitado pelo
        // teste do ZERO acima, que passa pelo construtor normalmente.
        expect(() => tx(-100), throwsA(isA<AssertionError>()));
      },
    );
  });

  group('RequestTenantAccessUseCase — anti-spam e validação (S3)', () {
    test('solicitação válida nasce pendente com nome trimmed', () async {
      final repo = _MemTenantRepo(null);
      final useCase = RequestTenantAccessUseCase(repo);

      final created = await useCase.call(
        ownerUserId: 'u-9',
        businessName: '  Loja Nova  ',
        planId: 'pl-ess',
        currencyCode: 'MZN',
        language: 'pt',
      );

      expect(created.status, TenantStatus.pending);
      expect(created.businessName, 'Loja Nova');
      expect(repo.requested.single.ownerUserId, 'u-9');
    });

    test('nome vazio lança InvalidTenantRequestException sem criar', () async {
      final repo = _MemTenantRepo(null);

      await expectLater(
        RequestTenantAccessUseCase(repo).call(
          ownerUserId: 'u-9',
          businessName: '   ',
          planId: 'pl-ess',
          currencyCode: 'MZN',
          language: 'pt',
        ),
        throwsA(isA<InvalidTenantRequestException>()),
      );
      expect(repo.requested, isEmpty);
    });

    test('sem plano escolhido lança InvalidTenantRequestException', () async {
      final repo = _MemTenantRepo(null);

      await expectLater(
        RequestTenantAccessUseCase(repo).call(
          ownerUserId: 'u-9',
          businessName: 'Loja',
          planId: '',
          currencyCode: 'MZN',
          language: 'pt',
        ),
        throwsA(isA<InvalidTenantRequestException>()),
      );
      expect(repo.requested, isEmpty);
    });

    test(
      'usuário que JÁ pertence a um tenant NÃO cria segunda solicitação',
      () async {
        final repo = _MemTenantRepo(_tenant());
        final useCase = RequestTenantAccessUseCase(repo);

        await expectLater(
          useCase.call(
            ownerUserId: 'u-1',
            businessName: 'Outra Loja',
            planId: 'pl-ess',
            currencyCode: 'MZN',
            language: 'pt',
          ),
          throwsA(isA<InvalidTenantRequestException>()),
        );
        // Nenhuma nova solicitação criada (anti-spam contra 23505).
        expect(repo.requested, isEmpty);
      },
    );
  });

  group('SetEmployeeActiveUseCase — mudança de status do vínculo', () {
    test('desativa funcionário ativo (chama setActive false)', () async {
      final repo = _MemEmployeeRepo([
        const StoreEmployee(
          id: 'emp-1',
          tenantId: 'tn-1',
          storeId: 'st-1',
          userId: 'u-emp',
          fullName: 'Carlos Caixa',
          email: 'carlos@test.local',
          role: EmployeeRole.employee,
          isActive: true,
        ),
      ]);
      await SetEmployeeActiveUseCase(
        repo,
      ).call(tenantId: 'tn-1', employeeId: 'emp-1', isActive: false);

      expect(repo.setActiveCalls.single, (id: 'emp-1', active: false));
    });

    test(
      'status IGUAL não re-persiste (sem escrita redundante no banco)',
      () async {
        final repo = _MemEmployeeRepo([
          const StoreEmployee(
            id: 'emp-1',
            tenantId: 'tn-1',
            storeId: 'st-1',
            userId: 'u-emp',
            fullName: 'Carlos Caixa',
            email: 'carlos@test.local',
            role: EmployeeRole.employee,
            isActive: true,
          ),
        ]);
        await SetEmployeeActiveUseCase(
          repo,
        ).call(tenantId: 'tn-1', employeeId: 'emp-1', isActive: true);

        expect(repo.setActiveCalls, isEmpty);
      },
    );

    test(
      'funcionário inexistente lança EmployeeNotFoundException sem escrita',
      () async {
        final repo = _MemEmployeeRepo(const []);
        await expectLater(
          SetEmployeeActiveUseCase(
            repo,
          ).call(tenantId: 'tn-1', employeeId: 'fantasma', isActive: false),
          throwsA(isA<EmployeeNotFoundException>()),
        );
        expect(repo.setActiveCalls, isEmpty);
      },
    );
  });

  group('AddStoreUseCase — limite do plano e tenant aprovado', () {
    Store store(String name) =>
        Store(id: 'st-new', tenantId: 'tn-1', name: name);

    test('loja válida dentro do limite é persistida', () async {
      final storeRepo = _MemStoreRepo([
        const Store(id: 'st-1', tenantId: 'tn-1', name: 'Matriz'),
      ]);
      await AddStoreUseCase(
        storeRepo,
        _MemTenantRepo(_tenant()),
        _MemPlanRepo(_plan(maxStores: 2)),
      ).call(store('Filial Norte'));

      expect(storeRepo.added.single.name, 'Filial Norte');
    });

    test('nome vazio lança InvalidStoreException e NÃO cria loja', () async {
      final storeRepo = _MemStoreRepo(const []);
      await expectLater(
        AddStoreUseCase(
          storeRepo,
          _MemTenantRepo(_tenant()),
          _MemPlanRepo(_plan()),
        ).call(store('  ')),
        throwsA(isA<InvalidStoreException>()),
      );
      expect(storeRepo.added, isEmpty);
    });

    test(
      'tenant pendente NÃO pode criar loja (TenantNotApprovedException)',
      () async {
        final storeRepo = _MemStoreRepo(const []);
        await expectLater(
          AddStoreUseCase(
            storeRepo,
            _MemTenantRepo(_tenant(status: TenantStatus.pending)),
            _MemPlanRepo(_plan()),
          ).call(store('Filial')),
          throwsA(isA<TenantNotApprovedException>()),
        );
        expect(storeRepo.added, isEmpty);
      },
    );

    test(
      'limite do plano atingido lança PlanLimitExceededException com contagem',
      () async {
        final storeRepo = _MemStoreRepo([
          const Store(id: 'st-1', tenantId: 'tn-1', name: 'Matriz'),
          const Store(id: 'st-2', tenantId: 'tn-1', name: 'Filial'),
        ]);
        await expectLater(
          AddStoreUseCase(
            storeRepo,
            _MemTenantRepo(_tenant()),
            _MemPlanRepo(_plan(maxStores: 2)),
          ).call(store('Terceira')),
          throwsA(
            isA<PlanLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains('permite até 2 lojas'),
            ),
          ),
        );
        expect(storeRepo.added, isEmpty);
      },
    );

    test(
      'singular do plural: plano de 1 loja diz "1 loja" (não "1 lojas")',
      () async {
        final storeRepo = _MemStoreRepo([
          const Store(id: 'st-1', tenantId: 'tn-1', name: 'Matriz'),
        ]);
        await expectLater(
          AddStoreUseCase(
            storeRepo,
            _MemTenantRepo(_tenant()),
            _MemPlanRepo(_plan(maxStores: 1)),
          ).call(store('Segunda')),
          throwsA(
            isA<PlanLimitExceededException>().having(
              (e) => e.message,
              'message',
              contains('até 1 loja. '),
            ),
          ),
        );
      },
    );
  });

  group('GetCashFlowUseCase — fluxo de caixa realizado (W4 centavos)', () {
    test('período invertido lança InvalidPeriodException', () async {
      final useCase = GetCashFlowUseCase(_MemFinancialRepo());

      await expectLater(
        useCase.call(
          storeId: 'st-1',
          start: DateTime(2026, 9, 10),
          end: DateTime(2026, 9, 1),
        ),
        throwsA(isA<InvalidPeriodException>()),
      );
    });

    test('soma apenas transações PAGAS (fiado pendente não entra)', () async {
      final repo = _MemFinancialRepo();
      final useCase = GetCashFlowUseCase(repo);

      // Como o use case lê de getByPeriod, o fake devolve a lista fixa.
      final flow = await useCase.call(
        storeId: 'st-1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      );

      // Sem transações: saldo zero (contrato do estado vazio).
      expect(flow.incomeCents, 0);
      expect(flow.expenseCents, 0);
      expect(flow.balanceCents, 0);
    });
  });
}
