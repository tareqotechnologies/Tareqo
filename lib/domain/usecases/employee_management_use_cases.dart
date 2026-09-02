import '../entities/employee_attendance.dart';

/// Caso de uso para registar entrada (clock-in) de funcionário.
class ClockInUseCase {
  const ClockInUseCase();

  EmployeeAttendance call({
    required String employeeId,
    required String storeId,
  }) {
    final now = DateTime.now();
    return EmployeeAttendance(
      id: '', // Atribuído pelo banco
      employeeId: employeeId,
      storeId: storeId,
      clockIn: now,
      date: DateTime(now.year, now.month, now.day),
    );
  }
}

/// Caso de uso para registar saída (clock-out) de funcionário.
class ClockOutUseCase {
  const ClockOutUseCase();

  /// Calcula os minutos trabalhados e actualiza o registo.
  EmployeeAttendance call(EmployeeAttendance attendance) {
    if (attendance.clockOut != null) {
      throw StateError('Este registo já tem saída registada.');
    }

    final now = DateTime.now();
    final diff = now.difference(attendance.clockIn);
    final totalMinutes = diff.inMinutes;

    return attendance.copyWith(
      clockIn: attendance.clockIn,
      clockOut: now,
      totalMinutes: totalMinutes,
    );
  }
}

/// Caso de uso para calcular comissão de uma venda.
class CalculateCommissionUseCase {
  const CalculateCommissionUseCase();

  /// Calcula a comissão de um funcionário com base na taxa (bps) e no
  /// valor da venda.
  ///
  /// [rateBps] é em basis points: 500 = 5%, 1000 = 10%, etc.
  /// Retorna o valor da comissão em centavos.
  int call({
    required int saleAmountCents,
    required int rateBps,
  }) {
    if (rateBps <= 0) return 0;
    return (saleAmountCents * rateBps) ~/ 10000;
  }
}

/// Caso de uso para criar uma meta mensal de funcionário.
class CreateEmployeeTargetUseCase {
  const CreateEmployeeTargetUseCase();

  EmployeeTarget call({
    required String employeeId,
    required String storeId,
    required String period,
    required int salesTargetCents,
    int commissionBps = 500,
  }) {
    return EmployeeTarget(
      id: '', // Atribuído pelo banco
      employeeId: employeeId,
      storeId: storeId,
      period: period,
      salesTargetCents: salesTargetCents,
      commissionBps: commissionBps,
      createdAt: DateTime.now(),
    );
  }
}

/// Caso de uso para calcular progresso de meta.
class CalculateTargetProgressUseCase {
  const CalculateTargetProgressUseCase();

  /// Retorna a percentagem de progresso (0-100+).
  double call(EmployeeTarget target) {
    if (target.salesTargetCents <= 0) return 0;
    return (target.salesAchievedCents / target.salesTargetCents) * 100;
  }
}
