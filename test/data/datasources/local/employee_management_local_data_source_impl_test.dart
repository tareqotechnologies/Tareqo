import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/local/employee_management_local_data_source_impl.dart';
import 'package:tareqo/data/repositories/employee_management_repository_impl.dart';

void main() {
  group('EmployeeManagementLocalDataSourceImpl', () {
    test('clockIn/clockOut registam ponto com uma linha por dia', () async {
      final dataSource = EmployeeManagementLocalDataSourceImpl();

      final open = await dataSource.clockIn(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockIn: DateTime(2026, 9, 5, 8, 0),
      );
      expect(open.clockOut, isNull);

      final closed = await dataSource.clockOut(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockOut: DateTime(2026, 9, 5, 17, 0),
      );
      expect(closed.clockOut, isNotNull);

      final all = await dataSource.getAttendance(
        storeId: 'st1',
        workDate: '2026-09-05',
      );
      expect(all, hasLength(1));
    });

    test('clockIn duplicado no dia lança StateError', () async {
      final dataSource = EmployeeManagementLocalDataSourceImpl();
      await dataSource.clockIn(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockIn: DateTime(2026, 9, 5, 8, 0),
      );

      await expectLater(
        dataSource.clockIn(
          storeId: 'st1',
          userId: 'u1',
          workDate: '2026-09-05',
          clockIn: DateTime(2026, 9, 5, 9, 0),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('taxas e metas usam UPSERT por funcionário (sem duplicar)', () async {
      final dataSource = EmployeeManagementLocalDataSourceImpl();
      await dataSource.setCommissionRate(
        storeId: 'st1',
        userId: 'u1',
        rateBps: 500,
      );
      await dataSource.setCommissionRate(
        storeId: 'st1',
        userId: 'u1',
        rateBps: 700,
      );
      expect(
        (await dataSource.getCommissionRates(storeId: 'st1')).single.rateBps,
        700,
      );

      await dataSource.setTarget(
        storeId: 'st1',
        userId: 'u1',
        month: '2026-09',
        targetCents: 150000,
      );
      await dataSource.setTarget(
        storeId: 'st1',
        userId: 'u1',
        month: '2026-09',
        targetCents: 200000,
      );
      expect(
        (await dataSource.getTargets(storeId: 'st1', month: '2026-09'))
            .single
            .targetCents,
        200000,
      );
    });
  });

  group('EmployeeManagementRepositoryImpl', () {
    test('delega ponto, taxas e metas para o datasource', () async {
      final repository = EmployeeManagementRepositoryImpl(
        EmployeeManagementLocalDataSourceImpl(),
      );

      final record = await repository.clockIn(
        storeId: 'st1',
        userId: 'u1',
        workDate: '2026-09-05',
        clockIn: DateTime(2026, 9, 5, 8, 0),
      );
      expect(record.clockOut, isNull);

      await repository.setCommissionRate(
        storeId: 'st1',
        userId: 'u1',
        rateBps: 500,
      );
      await repository.setTarget(
        storeId: 'st1',
        userId: 'u1',
        month: '2026-09',
        targetCents: 150000,
      );

      expect(
        await repository.getCommissionRates(storeId: 'st1'),
        hasLength(1),
      );
      expect(
        await repository.getTargets(storeId: 'st1', month: '2026-09'),
        hasLength(1),
      );
      expect(
        await repository.getAttendance(storeId: 'st1', workDate: '2026-09-05'),
        hasLength(1),
      );
    });
  });
}