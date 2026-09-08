import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_attendance.freezed.dart';
part 'employee_attendance.g.dart';

/// Registo de ponto (entrada/saída) de um funcionário.
@freezed
abstract class EmployeeAttendance with _$EmployeeAttendance {
  const factory EmployeeAttendance({
    required String id,
    required String employeeId,
    required String storeId,

    /// Hora de entrada.
    required DateTime clockIn,

    /// Hora de saída (null se ainda não saiu).
    DateTime? clockOut,

    /// Total de minutos trabalhados (calculado ao registar saída).
    @Default(0) int totalMinutes,

    /// Se o registo foi editado manualmente (override do gerente).
    @Default(false) bool isManualOverride,

    /// Nota do override (ex.: "esqueceu-se de bater ponto").
    @Default('') String overrideNote,
    required DateTime date,
  }) = _EmployeeAttendance;

  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) =>
      _$EmployeeAttendanceFromJson(json);
}

/// Meta mensal de um funcionário.
@freezed
abstract class EmployeeTarget with _$EmployeeTarget {
  const factory EmployeeTarget({
    required String id,
    required String employeeId,
    required String storeId,

    /// Mês/ano da meta (formato "YYYY-MM").
    required String period,

    /// Meta de vendas em centavos.
    required int salesTargetCents,

    /// Meta de comissão percentual (ex.: 500 = 5%).
    @Default(500) int commissionBps,

    /// Vendas efectuadas no período (actualizado automaticamente).
    @Default(0) int salesAchievedCents,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _EmployeeTarget;

  factory EmployeeTarget.fromJson(Map<String, dynamic> json) =>
      _$EmployeeTargetFromJson(json);
}

/// Registo de comissão de um funcionário.
@freezed
abstract class EmployeeCommission with _$EmployeeCommission {
  const factory EmployeeCommission({
    required String id,
    required String employeeId,
    required String saleId,

    /// Valor da comissão em centavos.
    required int amountCents,

    /// Taxa aplicada em bps (basis points — 500 = 5%).
    required int rateBps,
    @Default(false) bool isPaid,
    DateTime? paidAt,
    required DateTime createdAt,
  }) = _EmployeeCommission;

  factory EmployeeCommission.fromJson(Map<String, dynamic> json) =>
      _$EmployeeCommissionFromJson(json);
}
