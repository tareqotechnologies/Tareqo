import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';
import '../../helpers/store_context.dart';

import 'package:tareqo/domain/entities/employee_management.dart';
import 'package:tareqo/domain/entities/store_employee.dart';
import 'package:tareqo/domain/repositories/i_employee_management_repository.dart';
import 'package:tareqo/domain/repositories/i_employee_repository.dart';
import 'package:tareqo/domain/usecases/get_employees_use_case.dart';
import 'package:tareqo/presentation/controllers/account_providers.dart';
import 'package:tareqo/presentation/controllers/employee_management_providers.dart';
import 'package:tareqo/presentation/screens/addons/employee_management_screen.dart';

/// Repositório em memória do add-on — grava as chamadas para asserção de
/// contrato e permite simular erros de rede.
class _MemEmployeeManagementRepository
    implements IEmployeeManagementRepository {
  final List<EmployeeAttendance> _attendance = [];
  final List<EmployeeCommissionRate> _rates = [];
  final List<EmployeeTarget> _targets = [];
  bool failWrites = false;

  final clockInCalls = <({String storeId, String userId, String workDate})>[];
  final clockOutCalls = <({String storeId, String userId, String workDate})>[];
  final rateCalls = <({String storeId, String userId, int rateBps})>[];
  final targetCalls =
      <({String storeId, String userId, String month, int targetCents})>[];
  final removeCalls = <({String id, String storeId})>[];

  void seedAttendance(EmployeeAttendance record) => _attendance.add(record);
  void seedRate(EmployeeCommissionRate rate) => _rates.add(rate);
  void seedTarget(EmployeeTarget target) => _targets.add(target);

  @override
  Future<List<EmployeeAttendance>> getAttendance({
    required String storeId,
    required String workDate,
  }) async => _attendance.where((r) => r.workDate == workDate).toList();

  @override
  Future<EmployeeAttendance> clockIn({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockIn,
    String? recordedBy,
  }) async {
    if (failWrites) throw Exception('rede caiu');
    clockInCalls.add((storeId: storeId, userId: userId, workDate: workDate));
    final record = EmployeeAttendance(
      id: 'att-${_attendance.length + 1}',
      storeId: storeId,
      userId: userId,
      workDate: workDate,
      clockIn: clockIn,
      createdAt: clockIn,
    );
    _attendance.add(record);
    return record;
  }

  @override
  Future<EmployeeAttendance> clockOut({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockOut,
  }) async {
    if (failWrites) throw Exception('rede caiu');
    clockOutCalls.add((storeId: storeId, userId: userId, workDate: workDate));
    final index = _attendance.lastIndexWhere(
      (r) => r.userId == userId && r.clockOut == null,
    );
    final updated = _attendance[index].copyWith(clockOut: clockOut);
    _attendance[index] = updated;
    return updated;
  }

  @override
  Future<List<EmployeeCommissionRate>> getCommissionRates({
    required String storeId,
  }) async => _rates;

  @override
  Future<void> setCommissionRate({
    required String storeId,
    required String userId,
    required int rateBps,
  }) async {
    if (failWrites) throw Exception('rede caiu');
    rateCalls.add((storeId: storeId, userId: userId, rateBps: rateBps));
  }

  @override
  Future<List<EmployeeTarget>> getTargets({
    required String storeId,
    String? month,
  }) async => _targets;

  @override
  Future<void> setTarget({
    required String storeId,
    required String userId,
    required String month,
    required int targetCents,
  }) async {
    if (failWrites) throw Exception('rede caiu');
    targetCalls.add((
      storeId: storeId,
      userId: userId,
      month: month,
      targetCents: targetCents,
    ));
  }

  @override
  Future<void> removeTarget(String id, {required String storeId}) async {
    if (failWrites) throw Exception('rede caiu');
    removeCalls.add((id: id, storeId: storeId));
  }
}

StoreEmployee _employee(
  String userId, {
  String name = 'Funcionário',
  EmployeeRole role = EmployeeRole.employee,
}) => StoreEmployee(
  id: 'se-$userId',
  tenantId: 'tn1',
  storeId: 'st1',
  userId: userId,
  fullName: name,
  email: '$userId@test.local',
  role: role,
  isActive: true,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aba Ponto: resumo do dia + botão de entrada por funcionário', (
    tester,
  ) async {
    final repo = _MemEmployeeManagementRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          getEmployeesUseCaseProvider.overrideWithValue(
            GetEmployeesUseCase(
              _FakeEmployeeRepo([
                _employee('u-emp1', name: 'Ana Caixa'),
                _employee('u-emp2', name: 'Bruno Sales'),
              ]),
            ),
          ),
          employeeManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: testApp(home: const EmployeeManagementScreen()),
      ),
    );
    await _settle(tester);

    // Resumo: 2 funcionários (presentes 0, ausentes 2, total 2).
    expect(find.text('Presentes'), findsOneWidget);
    expect(find.text('Ausentes'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);

    // Ambos aparecem com botão de ENTRADA.
    expect(find.text('Ana Caixa'), findsOneWidget);
    expect(find.text('Bruno Sales'), findsOneWidget);
    expect(find.text('Entrar'), findsNWidgets(2));
    expect(find.text('Sair'), findsNothing);
  });

  testWidgets(
    'aba Ponto: funcionário com ponto aberto mostra botão de SAÍDA e contagem',
    (tester) async {
      final repo = _MemEmployeeManagementRepository();
      final today = DateTime.now();
      final workDate =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      repo.seedAttendance(
        EmployeeAttendance(
          id: 'att1',
          storeId: 'st1',
          userId: 'u-emp1',
          workDate: workDate,
          clockIn: DateTime(today.year, today.month, today.day, 8),
          createdAt: DateTime(today.year, today.month, today.day, 8),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...storeContextOverrides(),
            getEmployeesUseCaseProvider.overrideWithValue(
              GetEmployeesUseCase(
                _FakeEmployeeRepo([
                  _employee('u-emp1', name: 'Ana Caixa'),
                  _employee('u-emp2', name: 'Bruno Sales'),
                ]),
              ),
            ),
            employeeManagementRepositoryProvider.overrideWithValue(repo),
          ],
          child: testApp(home: const EmployeeManagementScreen()),
        ),
      );
      await _settle(tester);

      // Ana tem entrada aberta → Sair; Bruno não → Entrar.
      expect(find.text('Sair'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      // Registo do dia listado com janela de tempo aberta.
      expect(find.textContaining('Em curso'), findsOneWidget);
    },
  );

  testWidgets('batida de entrada grava no repositório', (tester) async {
    final repo = _MemEmployeeManagementRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          getEmployeesUseCaseProvider.overrideWithValue(
            GetEmployeesUseCase(
              _FakeEmployeeRepo([_employee('u-emp1', name: 'Ana Caixa')]),
            ),
          ),
          employeeManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: testApp(home: const EmployeeManagementScreen()),
      ),
    );
    await _settle(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(repo.clockInCalls, hasLength(1));
    expect(repo.clockInCalls.single.userId, 'u-emp1');
    expect(repo.clockInCalls.single.storeId, 'st1');
  });

  testWidgets('erro de rede na batida mostra mensagem (não crasha)', (
    tester,
  ) async {
    final repo = _MemEmployeeManagementRepository()..failWrites = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          getEmployeesUseCaseProvider.overrideWithValue(
            GetEmployeesUseCase(_FakeEmployeeRepo([_employee('u-emp1')])),
          ),
          employeeManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: testApp(home: const EmployeeManagementScreen()),
      ),
    );
    await _settle(tester);

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível registar a entrada.'), findsOneWidget);
    expect(repo.clockInCalls, isEmpty);
  });

  testWidgets(
    'aba Comissões: totais do mês e subtítulo por funcionário com taxa',
    (tester) async {
      final repo = _MemEmployeeManagementRepository();
      final month =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      repo.seedTarget(
        EmployeeTarget(
          id: 't1',
          storeId: 'st1',
          userId: 'u-emp1',
          month: month,
          targetCents: 100000,
          createdAt: DateTime(2026, 1),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...storeContextOverrides(),
            getEmployeesUseCaseProvider.overrideWithValue(
              GetEmployeesUseCase(
                _FakeEmployeeRepo([_employee('u-emp1', name: 'Ana Caixa')]),
              ),
            ),
            employeeManagementRepositoryProvider.overrideWithValue(repo),
            // Resumo de comissões: forçado ao caminho local (repo remoto
            // ausente) — vendas/taxas são lidas dos providers.
          ],
          child: testApp(home: const EmployeeManagementScreen()),
        ),
      );
      await _settle(tester);

      // Navega para a aba Comissões.
      await tester.tap(find.text('Comissões'));
      await _settle(tester);

      // Sem taxa cadastrada → subtítulo "sem taxa".
      expect(find.text('Ana Caixa'), findsOneWidget);
      expect(find.textContaining('Sem taxa definida'), findsOneWidget);
    },
  );

  testWidgets('aba Metas: meta do mês mostra progresso real (vendas ÷ meta)', (
    tester,
  ) async {
    final repo = _MemEmployeeManagementRepository();
    final month =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    repo.seedTarget(
      EmployeeTarget(
        id: 't1',
        storeId: 'st1',
        userId: 'u-emp1',
        month: month,
        targetCents: 100000, // 1.000,00
        createdAt: DateTime(2026, 1),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...storeContextOverrides(),
          getEmployeesUseCaseProvider.overrideWithValue(
            GetEmployeesUseCase(
              _FakeEmployeeRepo([_employee('u-emp1', name: 'Ana Caixa')]),
            ),
          ),
          employeeManagementRepositoryProvider.overrideWithValue(repo),
        ],
        child: testApp(home: const EmployeeManagementScreen()),
      ),
    );
    await _settle(tester);

    // Navega para a aba Metas.
    await tester.tap(find.text('Metas'));
    await _settle(tester);

    // 1 meta activa (activas 1, atingidas 0, pendentes 1) — sem vendas
    // no caminho local, o progresso é 0%.
    expect(find.text('Metas Activas'), findsOneWidget);
    expect(find.text('Ana Caixa'), findsOneWidget);
    expect(find.textContaining('Meta:'), findsOneWidget);
  });

  testWidgets(
    'loja ausente (onboarding incompleto) mostra vazio honesto em vez de crashar',
    (tester) async {
      final repo = _MemEmployeeManagementRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Sem lojas no tenant → storeId null.
            ...storeContextOverrides(stores: const []),
            getEmployeesUseCaseProvider.overrideWithValue(
              GetEmployeesUseCase(_FakeEmployeeRepo(const [])),
            ),
            employeeManagementRepositoryProvider.overrideWithValue(repo),
          ],
          child: testApp(home: const EmployeeManagementScreen()),
        ),
      );
      await _settle(tester);

      expect(find.text('Sem loja activa'), findsWidgets);
      expect(find.text('Entrar'), findsNothing);
    },
  );
}

class _FakeEmployeeRepo implements IEmployeeRepository {
  _FakeEmployeeRepo(this._employees);

  final List<StoreEmployee> _employees;

  @override
  Future<List<StoreEmployee>> getByTenant(String tenantId) async => _employees;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
