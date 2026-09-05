import '../../../core/utils/ids.dart';
import '../../../domain/entities/employee_management.dart';
import 'employee_management_local_data_source.dart';

/// Implementação em memória do [EmployeeManagementLocalDataSource].
///
/// Usada na web (sem sqlite3) e nos testes.
final class EmployeeManagementLocalDataSourceImpl
    implements EmployeeManagementLocalDataSource {
  EmployeeManagementLocalDataSourceImpl();

  final List<EmployeeAttendance> _attendance = [];
  final Map<String, EmployeeCommissionRate> _rates = {};
  final List<EmployeeTarget> _targets = [];

  // ── Ponto ────────────────────────────────────────────────────────────
  @override
  Future<List<EmployeeAttendance>> getAttendance({
    required String storeId,
    required String workDate,
  }) async =>
      List.unmodifiable(
        _attendance.where(
          (a) => a.storeId == storeId && a.workDate == workDate,
        ),
      );

  @override
  Future<EmployeeAttendance> clockIn({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockIn,
    String? recordedBy,
  }) async {
    final existing = _attendance.where(
      (a) =>
          a.storeId == storeId &&
          a.userId == userId &&
          a.workDate == workDate &&
          a.clockOut == null,
    );
    if (existing.isNotEmpty) {
      throw StateError('Ponto já registado para $userId em $workDate.');
    }
    final record = EmployeeAttendance(
      id: AppIds.newId('att'),
      storeId: storeId,
      userId: userId,
      workDate: workDate,
      clockIn: clockIn,
      recordedBy: recordedBy ?? '',
      createdAt: DateTime.now(),
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
    final index = _attendance.indexWhere(
      (a) =>
          a.storeId == storeId &&
          a.userId == userId &&
          a.workDate == workDate &&
          a.clockOut == null,
    );
    if (index == -1) {
      throw StateError('Sem entrada registada para $userId em $workDate.');
    }
    final closed = _attendance[index].copyWith(clockOut: clockOut);
    _attendance[index] = closed;
    return closed;
  }

  // ── Taxas de comissão ────────────────────────────────────────────────
  @override
  Future<List<EmployeeCommissionRate>> getCommissionRates({
    required String storeId,
  }) async =>
      List.unmodifiable(
        _rates.values.where((rate) => rate.storeId == storeId),
      );

  @override
  Future<void> setCommissionRate({
    required String storeId,
    required String userId,
    required int rateBps,
  }) async {
    if (rateBps < 0 || rateBps > 10000) {
      throw StateError('Taxa de comissão inválida: $rateBps bps.');
    }
    final existing = _rates.values.where(
      (rate) => rate.storeId == storeId && rate.userId == userId,
    );
    if (existing.isEmpty) {
      _rates['$storeId:$userId'] = EmployeeCommissionRate(
        id: AppIds.newId('crate'),
        storeId: storeId,
        userId: userId,
        rateBps: rateBps,
        createdAt: DateTime.now(),
      );
    } else {
      final rate = existing.first;
      _rates['$storeId:$userId'] = rate.copyWith(rateBps: rateBps);
    }
  }

  // ── Metas ────────────────────────────────────────────────────────────
  @override
  Future<List<EmployeeTarget>> getTargets({
    required String storeId,
    String? month,
  }) async =>
      List.unmodifiable(
        _targets.where(
          (target) =>
              target.storeId == storeId &&
              (month == null || target.month == month),
        ),
      );

  @override
  Future<void> setTarget({
    required String storeId,
    required String userId,
    required String month,
    required int targetCents,
  }) async {
    if (targetCents < 0) {
      throw StateError('Meta inválida: $targetCents.');
    }
    final existing = _targets.where(
      (target) =>
          target.storeId == storeId &&
          target.userId == userId &&
          target.month == month,
    );
    if (existing.isEmpty) {
      _targets.add(
        EmployeeTarget(
          id: AppIds.newId('tgt'),
          storeId: storeId,
          userId: userId,
          month: month,
          targetCents: targetCents,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      final index = _targets.indexOf(existing.first);
      _targets[index] = existing.first.copyWith(targetCents: targetCents);
    }
  }

  @override
  Future<void> removeTarget(String id, {required String storeId}) async {
    _targets.removeWhere(
      (target) => target.id == id && target.storeId == storeId,
    );
  }
}