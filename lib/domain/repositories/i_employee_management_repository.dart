import '../entities/employee_management.dart';

/// Contrato de persistência do add-on Gestão de Funcionários (camada de
/// domínio) — ponto, taxas de comissão e metas por loja.
abstract interface class IEmployeeManagementRepository {
  Future<List<EmployeeAttendance>> getAttendance({
    required String storeId,
    required String workDate,
  });

  Future<EmployeeAttendance> clockIn({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockIn,
    String? recordedBy,
  });

  Future<EmployeeAttendance> clockOut({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockOut,
  });

  Future<List<EmployeeCommissionRate>> getCommissionRates({
    required String storeId,
  });

  Future<void> setCommissionRate({
    required String storeId,
    required String userId,
    required int rateBps,
  });

  Future<List<EmployeeTarget>> getTargets({
    required String storeId,
    String? month,
  });

  Future<void> setTarget({
    required String storeId,
    required String userId,
    required String month,
    required int targetCents,
  });

  Future<void> removeTarget(String id, {required String storeId});
}