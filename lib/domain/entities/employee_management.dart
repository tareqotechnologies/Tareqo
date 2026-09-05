import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_management.freezed.dart';
part 'employee_management.g.dart';

/// Registo de PONTO de um funcionário num dia de trabalho.
///
/// Uma linha por funcionário por dia ([EmployeeAttendance.workDate] — chave
/// `UNIQUE(store_id, user_id, work_date)`): a entrada ([clockIn]) insere a
/// linha; a saída ([clockOut]) faz UPDATE na mesma linha. [recordedBy] é
/// quem executou a acção (dono/gerente registando pelo funcionário), e
/// [userId] é o funcionário (o SUJEITO) — colunas separadas de propósito:
/// o trigger `set_tenant_user_id` não pode forçar `user_id` = auth.uid()
/// aqui, senão o dono nunca registaria ponto de outra pessoa.
@freezed
abstract class EmployeeAttendance with _$EmployeeAttendance {
  const factory EmployeeAttendance({
    required String id,
    required String storeId,
    /// Funcionário (SUJEITO) — UUID do auth.users.
    required String userId,
    /// Dia de trabalho no formato `YYYY-MM-DD` (chave de unicidade).
    required String workDate,
    required DateTime clockIn,
    /// null enquanto o funcionário está presente (sem saída registada).
    DateTime? clockOut,
    /// Quem executou a acção (dono/gerente) — auth.uid() no servidor.
    @Default('') String recordedBy,
    required DateTime createdAt,
  }) = _EmployeeAttendance;

  factory EmployeeAttendance.fromJson(Map<String, dynamic> json) =>
      _$EmployeeAttendanceFromJson(json);
}

/// Taxa de comissão de um funcionário, em PONTOS BASE (integer math).
///
/// `rateBps / 100` = percentagem: 500 = 5%, 700 = 7%. Ponto base evita
/// floats na aritmética de dinheiro (mesma disciplina W4 do restante do
/// sistema). Uma taxa por funcionário por loja
/// (`UNIQUE(store_id, user_id)`).
@freezed
abstract class EmployeeCommissionRate with _$EmployeeCommissionRate {
  const factory EmployeeCommissionRate({
    required String id,
    required String storeId,
    required String userId,
    /// Pontos base (500 = 5%). Validado ≥ 0 e ≤ 10000 (100%).
    required int rateBps,
    required DateTime createdAt,
  }) = _EmployeeCommissionRate;

  factory EmployeeCommissionRate.fromJson(Map<String, dynamic> json) =>
      _$EmployeeCommissionRateFromJson(json);
}

/// Meta mensal de vendas de um funcionário.
///
/// Uma meta por funcionário por mês (`UNIQUE(store_id, user_id, month)` —
/// [month] no formato `YYYY-MM`). O progresso é calculado a partir das
/// VENDAS REAIS do funcionário no mês (nunca armazenado — evita
/// divergência com o histórico).
@freezed
abstract class EmployeeTarget with _$EmployeeTarget {
  const factory EmployeeTarget({
    required String id,
    required String storeId,
    required String userId,
    /// Mês da meta no formato `YYYY-MM`.
    required String month,
    /// Meta de vendas em centavos.
    required int targetCents,
    required DateTime createdAt,
  }) = _EmployeeTarget;

  factory EmployeeTarget.fromJson(Map<String, dynamic> json) =>
      _$EmployeeTargetFromJson(json);
}

/// Linha do resumo de comissões de um funcionário no mês.
///
/// CALCULADO (nunca persistido): `salesCents` = soma das vendas ATIVAS do
/// funcionário na loja no mês (coluna `sales.user_id` = caixa); `rateBps`
/// = taxa cadastrada (0 se não houver); `commissionCents` = sales × rate.
/// No Supabase vem da RPC `get_employee_commission_summary` (SECURITY
/// DEFINER + is_my_store); localmente é calculado pelo provider a partir
/// das vendas reais.
@freezed
abstract class EmployeeCommissionSummaryEntry with _$EmployeeCommissionSummaryEntry {
  const factory EmployeeCommissionSummaryEntry({
    required String userId,
    /// Nome do funcionário (join com store_employees).
    required String fullName,
    /// Vendas ATIVAS do funcionário na loja no mês (centavos).
    required int salesCents,
    /// Taxa cadastrada em pontos base (0 = sem taxa → comissão 0).
    @Default(0) int rateBps,
    /// Comissão calculada = salesCents × rateBps / 10000 (centavos).
    required int commissionCents,
  }) = _EmployeeCommissionSummaryEntry;

  factory EmployeeCommissionSummaryEntry.fromJson(
    Map<String, dynamic> json,
  ) =>
      _$EmployeeCommissionSummaryEntryFromJson(json);
}