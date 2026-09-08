import '../../domain/entities/employee_management.dart';
import '../../domain/repositories/i_employee_management_repository.dart';
import '../datasources/local/employee_management_local_data_source.dart';

/// Implementação de [IEmployeeManagementRepository] sobre um
/// [EmployeeManagementLocalDataSource].
///
/// O repositório não sabe se os dados vêm da memória, do SQLite ou do
/// Supabase: apenas delega para o datasource injetado.
final class EmployeeManagementRepositoryImpl
    implements IEmployeeManagementRepository {
  const EmployeeManagementRepositoryImpl(this._dataSource);

  final EmployeeManagementLocalDataSource _dataSource;

  @override
  Future<List<EmployeeAttendance>> getAttendance({
    required String storeId,
    required String workDate,
  }) => _dataSource.getAttendance(storeId: storeId, workDate: workDate);

  @override
  Future<EmployeeAttendance> clockIn({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockIn,
    String? recordedBy,
  }) => _dataSource.clockIn(
    storeId: storeId,
    userId: userId,
    workDate: workDate,
    clockIn: clockIn,
    recordedBy: recordedBy,
  );

  @override
  Future<EmployeeAttendance> clockOut({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockOut,
  }) => _dataSource.clockOut(
    storeId: storeId,
    userId: userId,
    workDate: workDate,
    clockOut: clockOut,
  );

  @override
  Future<List<EmployeeCommissionRate>> getCommissionRates({
    required String storeId,
  }) => _dataSource.getCommissionRates(storeId: storeId);

  @override
  Future<void> setCommissionRate({
    required String storeId,
    required String userId,
    required int rateBps,
  }) => _dataSource.setCommissionRate(
    storeId: storeId,
    userId: userId,
    rateBps: rateBps,
  );

  @override
  Future<List<EmployeeTarget>> getTargets({
    required String storeId,
    String? month,
  }) => _dataSource.getTargets(storeId: storeId, month: month);

  @override
  Future<void> setTarget({
    required String storeId,
    required String userId,
    required String month,
    required int targetCents,
  }) => _dataSource.setTarget(
    storeId: storeId,
    userId: userId,
    month: month,
    targetCents: targetCents,
  );

  @override
  Future<void> removeTarget(String id, {required String storeId}) =>
      _dataSource.removeTarget(id, storeId: storeId);
}
