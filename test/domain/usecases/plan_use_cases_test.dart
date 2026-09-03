import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/entities/plan.dart';
import 'package:tareqo/domain/repositories/i_plan_repository.dart';
import 'package:tareqo/domain/usecases/add_plan_use_case.dart';
import 'package:tareqo/domain/usecases/get_all_plans_use_case.dart';
import 'package:tareqo/domain/usecases/get_plans_use_case.dart';
import 'package:tareqo/domain/usecases/update_plan_use_case.dart';

class _FakePlanRepository implements IPlanRepository {
 final List<Plan> _plans = [];
 bool addCalled = false;
 bool updateCalled = false;

 @override
 Future<List<Plan>> getActivePlans() async =>
 List.unmodifiable(_plans.where((plan) => plan.isActive));

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
 Future<void> add(Plan plan) async {
 addCalled = true;
 // Simula a PRIMARY KEY do banco: inserir um plano com id já existente
 // é um erro — exatamente o que o Supabase faz (23505 duplicate key).
 if (_plans.any((p) => p.id == plan.id)) {
 throw StateError('duplicate key: ${plan.id}');
 }
 _plans.add(plan);
 }

 @override
 Future<void> update(Plan plan) async {
 updateCalled = true;
 final index = _plans.indexWhere((p) => p.id == plan.id);
 if (index >= 0) _plans[index] = plan;
 }
}

void main() {
 group('AddPlanUseCase', () {
 test('cria o plano quando válido', () async {
 final repository = _FakePlanRepository();
 final useCase = AddPlanUseCase(repository);

 await useCase(const Plan(
 id: 'pl1',
 name: 'Essencial',
 maxStores: 1,
 maxEmployees: 3,
 ));

 expect(repository.addCalled, isTrue);
 expect((await repository.getAllPlans()), hasLength(1));
 });

 test('lança InvalidPlanException com nome vazio', () async {
 final useCase = AddPlanUseCase(_FakePlanRepository());

 await expectLater(
 useCase(const Plan(id: 'pl1', name: ' ')),
 throwsA(isA<InvalidPlanException>()),
 );
 });

 test('lança InvalidPlanException com maxStores < 1', () async {
 final useCase = AddPlanUseCase(_FakePlanRepository());

 await expectLater(
 useCase(const Plan(id: 'pl1', name: 'X', maxStores: 0)),
 throwsA(isA<InvalidPlanException>()),
 );
 });

 test('lança InvalidPlanException com preço negativo', () async {
 final useCase = AddPlanUseCase(_FakePlanRepository());

 await expectLater(
 useCase(const Plan(
 id: 'pl1',
 name: 'X',
 priceMonthlyCents: -100,
 )),
 throwsA(isA<InvalidPlanException>()),
 );
 });
 });

 group('UpdatePlanUseCase', () {
 test('atualiza o plano existente sem chamar add (INSERT)', () async {
 final repository = _FakePlanRepository();
 await repository.add(const Plan(id: 'pl1', name: 'A'));
 // Reset do flag do setup: o interesse é o que o use case chama.
 repository.addCalled = false;

 final useCase = UpdatePlanUseCase(repository);
 await useCase(const Plan(
 id: 'pl1',
 name: 'B',
 maxStores: 5,
 maxEmployees: 10,
 ));

 // O UPDATE não pode inserir (PK duplicada no banco) — só atualizar.
 expect(repository.addCalled, isFalse);
 expect(repository.updateCalled, isTrue);
 expect((await repository.getById('pl1'))!.name, 'B');
 expect((await repository.getById('pl1'))!.maxStores, 5);
 // Sem duplicação na lista.
 expect((await repository.getAllPlans()), hasLength(1));
 });

 test('lança InvalidPlanException com nome vazio (validação do update)',
 () async {
 final repository = _FakePlanRepository();
 await repository.add(const Plan(id: 'pl1', name: 'A'));
 repository.addCalled = false;
 final useCase = UpdatePlanUseCase(repository);

 await expectLater(
 useCase(const Plan(id: 'pl1', name: ' ')),
 throwsA(isA<InvalidPlanException>()),
 );
 // Nada foi persistido (nem add, nem update).
 expect(repository.addCalled, isFalse);
 expect(repository.updateCalled, isFalse);
 });
 });

 group('GetPlansUseCase / GetAllPlansUseCase', () {
 test('GetPlansUseCase retorna apenas os ativos', () async {
 final repository = _FakePlanRepository();
 await repository.add(const Plan(id: 'pl1', name: 'A'));
 await repository.add(const Plan(
 id: 'pl2',
 name: 'B',
 isActive: false,
 ));

 final result = await GetPlansUseCase(repository)();
 expect(result, hasLength(1));
 expect(result.first.id, 'pl1');
 });

 test('GetAllPlansUseCase retorna todos, inclusive inativos', () async {
 final repository = _FakePlanRepository();
 await repository.add(const Plan(id: 'pl1', name: 'A'));
 await repository.add(const Plan(
 id: 'pl2',
 name: 'B',
 isActive: false,
 ));

 final result = await GetAllPlansUseCase(repository)();
 expect(result, hasLength(2));
 });
 });
}
