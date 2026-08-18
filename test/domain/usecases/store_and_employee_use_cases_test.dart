import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/plan.dart';
import 'package:dumbhanengue/domain/entities/store.dart';
import 'package:dumbhanengue/domain/entities/store_employee.dart';
import 'package:dumbhanengue/domain/entities/tenant.dart';
import 'package:dumbhanengue/domain/repositories/i_employee_account_processor.dart';
import 'package:dumbhanengue/domain/repositories/i_employee_account_service.dart';
import 'package:dumbhanengue/domain/repositories/i_employee_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_plan_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_store_repository.dart';
import 'package:dumbhanengue/domain/repositories/i_tenant_repository.dart';
import 'package:dumbhanengue/domain/usecases/add_employee_use_case.dart';
import 'package:dumbhanengue/domain/usecases/add_store_use_case.dart';
import 'package:dumbhanengue/domain/usecases/set_employee_active_use_case.dart';

class _FakeTenantRepository implements ITenantRepository {
 final Tenant tenant;

 _FakeTenantRepository(this.tenant);

 @override
 Future<Tenant?> getMyTenant(String userId) async => tenant;

 @override
 Future<Tenant?> getById(String id) async =>
 tenant.id == id ? tenant : null;

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
 Future<void> approve(String id) async {}

 @override
 Future<void> reject(String id, String reason) async {}

 @override
 Future<void> updatePlan(String id, String planId) async {}

 @override
 Future<List<Tenant>> getPending() async => const [];

 @override
 Future<List<Tenant>> getAll() async => [tenant];
}

class _FakePlanRepository implements IPlanRepository {
 final Plan plan;

 _FakePlanRepository(this.plan);

 @override
 Future<List<Plan>> getActivePlans() async => [plan];

 @override
 Future<List<Plan>> getAllPlans() async => [plan];

 @override
 Future<Plan?> getById(String id) async =>
 plan.id == id ? plan : null;

 @override
 Future<void> add(Plan plan) async {}

 @override
 Future<void> update(Plan plan) async {}
}class _FakeStoreRepository implements IStoreRepository {
  final List<Store> _stores = [];
  bool addCalled = false;

  @override
  Future<List<Store>> getByTenant(String tenantId) async =>
      List.unmodifiable(_stores.where((store) => store.tenantId == tenantId));

  @override
  Future<void> add(Store store) async {
    addCalled = true;
    _stores.add(store);
  }

  @override
  Future<void> update(Store store) async {
    final index = _stores.indexWhere((s) => s.id == store.id);
    if (index != -1) _stores[index] = store;
  }
}

class _FakeEmployeeRepository implements IEmployeeRepository {
 final List<StoreEmployee> _employees = [];
 bool addCalled = false;
 String? lastSetActiveId;
 bool? lastSetActiveValue;

 @override
 Future<List<StoreEmployee>> getByTenant(String tenantId) async =>
 List.unmodifiable(_employees.where((e) => e.tenantId == tenantId));

 @override
 Future<List<StoreEmployee>> getByStore(String storeId) async =>
 List.unmodifiable(_employees.where((e) => e.storeId == storeId));

 @override
 Future<void> add(StoreEmployee employee) async {
 addCalled = true;
 _employees.add(employee);
 }

 @override
 Future<void> setActive({
 required String employeeId,
 required bool isActive,
 }) async {
 lastSetActiveId = employeeId;
 lastSetActiveValue = isActive;
 final index = _employees.indexWhere((e) => e.id == employeeId);
 if (index >= 0) {
 _employees[index] = _employees[index].copyWith(isActive: isActive);
 }
 }
}

/// Modo LOCAL: devolve um id sintético (o vínculo fica com o repositório).
class _FakeEmployeeAccountService implements EmployeeAccountService {
 @override
 Future<String> createAccount({
 required String email,
 required String password,
 required String fullName,
 }) async =>
 'u-sintetico';
}

/// Modo SUPABASE: processador atômico (conta + vínculo numa transação).
class _FakeEmployeeProcessor implements IEmployeeAccountProcessor {
 StoreEmployee? lastEmployee;
 String? lastPassword;
 int calls = 0;

 @override
 Future<String> create({
 required StoreEmployee employee,
 required String password,
 }) async {
 calls++;
 lastEmployee = employee;
 lastPassword = password;
 return 'u-remoto';
 }
}

Tenant approvedTenant({String planId = 'pl1'}) => Tenant(
 id: 'tn1',
 ownerUserId: 'u1',
 businessName: 'Comercial X',
 planId: planId,
 status: TenantStatus.approved,
 approvedAt: DateTime.now(),
 createdAt: DateTime.now(),
 );

void main() {
 group('AddStoreUseCase', () {
 test('cria a loja quando dentro do limite do plano', () async {
 final storeRepository = _FakeStoreRepository();
 final useCase = AddStoreUseCase(
 storeRepository,
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(
 id: 'pl1',
 name: 'Essencial',
 maxStores: 3,
 maxEmployees: 5,
 )),
 );

 await useCase(const Store(
 id: 'st1',
 tenantId: 'tn1',
 name: 'Loja Centro',
 ));

 expect(storeRepository.addCalled, isTrue);
 });

 test('lança PlanLimitExceededException ao atingir o limite', () async {
 final storeRepository = _FakeStoreRepository();
 await storeRepository.add(const Store(
 id: 'st1',
 tenantId: 'tn1',
 name: 'Loja 1',
 ));
 await storeRepository.add(const Store(
 id: 'st2',
 tenantId: 'tn1',
 name: 'Loja 2',
 ));

 final useCase = AddStoreUseCase(
 storeRepository,
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(
 id: 'pl1',
 name: 'Essencial',
 maxStores: 2,
 maxEmployees: 5,
 )),
 );

 await expectLater(
 useCase(const Store(
 id: 'st3',
 tenantId: 'tn1',
 name: 'Loja 3',
 )),
 throwsA(isA<PlanLimitExceededException>()),
 );
 });

 test('lança InvalidStoreException sem nome', () async {
 final useCase = AddStoreUseCase(
 _FakeStoreRepository(),
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(id: 'pl1', name: 'X')),
 );

 await expectLater(
 useCase(const Store(id: 'st1', tenantId: 'tn1', name: ' ')),
 throwsA(isA<InvalidStoreException>()),
 );
 });

 test('lança TenantNotApprovedException quando o tenant não está aprovado',
 () async {
 final useCase = AddStoreUseCase(
 _FakeStoreRepository(),
 _FakeTenantRepository(Tenant(
 id: 'tn1',
 ownerUserId: 'u1',
 businessName: 'X',
 planId: 'pl1',
 status: TenantStatus.pending,
 createdAt: DateTime.now(),
 )),
 _FakePlanRepository(const Plan(id: 'pl1', name: 'X')),
 );

 await expectLater(
 useCase(const Store(id: 'st1', tenantId: 'tn1', name: 'Loja')),
 throwsA(isA<TenantNotApprovedException>()),
 );
 });
 });

 group('AddEmployeeUseCase', () {
 test('vincula o funcionário dentro do limite do plano', () async {
 final employeeRepository = _FakeEmployeeRepository();
 final storeRepository = _FakeStoreRepository();
 await storeRepository.add(const Store(
 id: 'st1',
 tenantId: 'tn1',
 name: 'Loja Centro',
 ));

 final useCase = AddEmployeeUseCase(
 employeeRepository,
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(
 id: 'pl1',
 name: 'Essencial',
 maxStores: 3,
 maxEmployees: 5,
 )),
 storeRepository,
 accountService: _FakeEmployeeAccountService(),
 );

 await useCase(
 const StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u2',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 ),
 password: 'senha-forte',
 );

 expect(employeeRepository.addCalled, isTrue);
 // O id da conta sintética (modo local) foi copiado para o vínculo.
 expect(employeeRepository._employees.single.userId, 'u-sintetico');
 });

 test('lança PlanLimitExceededException ao atingir o limite', () async {
 final employeeRepository = _FakeEmployeeRepository();
 final storeRepository = _FakeStoreRepository();
 await storeRepository.add(const Store(
 id: 'st1',
 tenantId: 'tn1',
 name: 'Loja Centro',
 ));

 final useCase = AddEmployeeUseCase(
 employeeRepository,
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(
 id: 'pl1',
 name: 'Essencial',
 maxStores: 3,
 maxEmployees: 1,
 )),
 storeRepository,
 accountService: _FakeEmployeeAccountService(),
 );
 await employeeRepository.add(const StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u2',
 fullName: 'Ana',
 email: 'ana@loja.com',
 ));

 await expectLater(
 useCase(
 const StoreEmployee(
 id: 'e2',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u3',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 ),
 password: 'senha-forte',
 ),
 throwsA(isA<PlanLimitExceededException>()),
 );
 });

 test('lança InvalidEmployeeException quando a loja não é do tenant',
 () async {
 final storeRepository = _FakeStoreRepository();
 // Nenhuma loja cadastrada — o vínculo a stX falha.
 final useCase = AddEmployeeUseCase(
 _FakeEmployeeRepository(),
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(id: 'pl1', name: 'X')),
 storeRepository,
 accountService: _FakeEmployeeAccountService(),
 );

 await expectLater(
 useCase(
 const StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'stX',
 userId: 'u2',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 ),
 password: 'senha-forte',
 ),
 throwsA(isA<InvalidEmployeeException>()),
 );
 });

 test('lança InvalidEmployeeException sem nome ou e-mail', () async {
 final storeRepository = _FakeStoreRepository();
 await storeRepository.add(const Store(
 id: 'st1',
 tenantId: 'tn1',
 name: 'Loja Centro',
 ));
 final useCase = AddEmployeeUseCase(
 _FakeEmployeeRepository(),
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(id: 'pl1', name: 'X')),
 storeRepository,
 accountService: _FakeEmployeeAccountService(),
 );

 await expectLater(
 useCase(
 const StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u2',
 fullName: '',
 email: '',
 ),
 password: 'senha-forte',
 ),
 throwsA(isA<InvalidEmployeeException>()),
 );
 });

 test('modo Supabase: delega ao processador atômico e NÃO duplica o '
 'vínculo (conta + vínculo numa transação)', () async {
 final employeeRepository = _FakeEmployeeRepository();
 final storeRepository = _FakeStoreRepository();
 await storeRepository.add(const Store(
 id: 'st1',
 tenantId: 'tn1',
 name: 'Loja Centro',
 ));
 final processor = _FakeEmployeeProcessor();

 final useCase = AddEmployeeUseCase(
 employeeRepository,
 _FakeTenantRepository(approvedTenant()),
 _FakePlanRepository(const Plan(
 id: 'pl1',
 name: 'Essencial',
 maxStores: 3,
 maxEmployees: 5,
 )),
 storeRepository,
 processor: processor,
 );

 await useCase(
 const StoreEmployee(
 id: 'e1',
 tenantId: 'tn1',
 storeId: 'st1',
 userId: '',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 ),
 password: 'senha-forte',
 );

 // O processador recebeu o funcionário + senha (conta + vínculo em
 // UMA transação no servidor)...
 expect(processor.calls, 1);
 expect(processor.lastEmployee?.id, 'e1');
 expect(processor.lastEmployee?.email, 'carlos@loja.com');
 expect(processor.lastPassword, 'senha-forte');
 // ...e o vínculo NÃO foi inserido de novo pelo repositório (evita
 // o duplicado que existiria com o fluxo em duas chamadas).
 expect(employeeRepository.addCalled, isFalse);
 });
 });

 group('SetEmployeeActiveUseCase', () {
 StoreEmployee buildEmployee({
 String id = 'e1',
 bool isActive = true,
 }) =>
 StoreEmployee(
 id: id,
 tenantId: 'tn1',
 storeId: 'st1',
 userId: 'u1',
 fullName: 'Carlos',
 email: 'carlos@loja.com',
 role: EmployeeRole.employee,
 isActive: isActive,
 );

 test('desativa funcionário existente', () async {
 final repository = _FakeEmployeeRepository();
 repository._employees.add(buildEmployee());
 final useCase = SetEmployeeActiveUseCase(repository);

 await useCase.call(
 tenantId: 'tn1',
 employeeId: 'e1',
 isActive: false,
 );

 expect(repository.lastSetActiveId, 'e1');
 expect(repository.lastSetActiveValue, isFalse);
 expect(repository._employees.single.isActive, isFalse);
 });

 test('reativa funcionário desativado', () async {
 final repository = _FakeEmployeeRepository();
 repository._employees.add(buildEmployee(isActive: false));
 final useCase = SetEmployeeActiveUseCase(repository);

 await useCase.call(
 tenantId: 'tn1',
 employeeId: 'e1',
 isActive: true,
 );

 expect(repository.lastSetActiveValue, isTrue);
 expect(repository._employees.single.isActive, isTrue);
 });

 test('não chama o repositório quando o status já é o pedido', () async {
 final repository = _FakeEmployeeRepository();
 repository._employees.add(buildEmployee());
 final useCase = SetEmployeeActiveUseCase(repository);

 await useCase.call(
 tenantId: 'tn1',
 employeeId: 'e1',
 isActive: true,
 );

 expect(repository.lastSetActiveId, isNull);
 });

 test('lança EmployeeNotFoundException para vínculo inexistente',
 () async {
 final repository = _FakeEmployeeRepository();
 final useCase = SetEmployeeActiveUseCase(repository);

 expect(
 () => useCase.call(
 tenantId: 'tn1',
 employeeId: 'desconhecido',
 isActive: false,
 ),
 throwsA(isA<EmployeeNotFoundException>()),
 );
 expect(repository.lastSetActiveId, isNull);
 });
 });
}
