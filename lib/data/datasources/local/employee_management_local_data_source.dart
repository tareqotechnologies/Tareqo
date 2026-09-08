import '../../../domain/entities/employee_management.dart';

/// Contrato de persistência do add-on Gestão de Funcionários.
///
/// Três agregados por loja — ponto ([EmployeeAttendance]), taxas de
/// comissão ([EmployeeCommissionRate]) e metas ([EmployeeTarget]) — com o
/// resumo de comissões CALCULADO a partir das vendas reais
/// ([getCommissionSummary]). A implementação concreta (memória, SQLite ou
/// Supabase) vive na camada `data`.
abstract interface class EmployeeManagementLocalDataSource {
  // ── Ponto (attendance) ────────────────────────────────────────────────
  /// Regista do dia [workDate] na loja [storeId].
  Future<List<EmployeeAttendance>> getAttendance({
    required String storeId,
    required String workDate,
  });

  /// Entrada do funcionário [userId] no dia [workDate].
  ///
  /// Lança [StateError] se já existir registo aberto para o funcionário
  /// no dia (uma entrada por dia — a saída é um UPDATE na mesma linha).
  Future<EmployeeAttendance> clockIn({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockIn,
    String? recordedBy,
  });

  /// Saída do funcionário [userId] no dia [workDate].
  ///
  /// Lança [StateError] se não existir registo aberto (sem entrada).
  Future<EmployeeAttendance> clockOut({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockOut,
  });

  // ── Taxas de comissão ────────────────────────────────────────────────
  /// Taxas da loja [storeId].
  Future<List<EmployeeCommissionRate>> getCommissionRates({
    required String storeId,
  });

  /// Define (insere ou atualiza) a taxa do funcionário [userId] na loja.
  Future<void> setCommissionRate({
    required String storeId,
    required String userId,
    required int rateBps,
  });

  // ── Metas ────────────────────────────────────────────────────────────
  /// Metas da loja [storeId] (filtradas por [month] `YYYY-MM` se dado).
  Future<List<EmployeeTarget>> getTargets({
    required String storeId,
    String? month,
  });

  /// Define (insere ou atualiza) a meta do funcionário no mês.
  Future<void> setTarget({
    required String storeId,
    required String userId,
    required String month,
    required int targetCents,
  });

  /// Remove a meta [id] da loja [storeId] (sem efeito se não existir).
  Future<void> removeTarget(String id, {required String storeId});
}
