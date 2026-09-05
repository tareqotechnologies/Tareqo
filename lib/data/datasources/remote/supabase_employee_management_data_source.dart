import '../../../domain/entities/employee_management.dart';
import '../local/employee_management_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [EmployeeManagementLocalDataSource] sobre o
/// Supabase (migração 20260905).
///
/// RLS por `is_my_store` + guarda `is_store_employee_active` no INSERT
/// (o user_id alvo precisa ser funcionário ATIVO da loja). O actor
/// (`recorded_by`) é carimbado por trigger no servidor. O resumo de
/// comissões NÃO é uma tabela: é calculado pela RPC
/// `get_employee_commission_summary` (SECURITY DEFINER, guarda
/// is_my_store) a partir das vendas reais.
final class EmployeeManagementSupabaseDataSourceImpl
    implements EmployeeManagementLocalDataSource {
  const EmployeeManagementSupabaseDataSourceImpl();

  static const _attendance = 'employee_attendance';
  static const _attendanceColumns =
      'id, store_id, user_id, work_date, clock_in, clock_out, recorded_by, '
      'created_at';
  static const _rates = 'employee_commission_rates';
  static const _ratesColumns = 'id, store_id, user_id, rate_bps, created_at';
  static const _targets = 'employee_targets';
  static const _targetsColumns =
      'id, store_id, user_id, month, target_cents, created_at';

  // ── Ponto ────────────────────────────────────────────────────────────
  @override
  Future<List<EmployeeAttendance>> getAttendance({
    required String storeId,
    required String workDate,
  }) async {
    final rows = await supabaseClient
        .from(_attendance)
        .select(_attendanceColumns)
        .eq('store_id', storeId)
        .eq('work_date', workDate)
        .order('clock_in');
    return List.unmodifiable([for (final row in rows) _mapAttendance(row)]);
  }

  @override
  Future<EmployeeAttendance> clockIn({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockIn,
    String? recordedBy,
  }) async {
    final rows = await supabaseClient
        .from(_attendance)
        .insert({
          'store_id': storeId,
          'user_id': userId,
          'work_date': workDate,
          'clock_in': clockIn.toUtc().toIso8601String(),
        })
        .select(_attendanceColumns);
    return _mapAttendance(rows.first);
  }

  @override
  Future<EmployeeAttendance> clockOut({
    required String storeId,
    required String userId,
    required String workDate,
    required DateTime clockOut,
  }) async {
    final rows = await supabaseClient
        .from(_attendance)
        .update({'clock_out': clockOut.toUtc().toIso8601String()})
        .eq('store_id', storeId)
        .eq('user_id', userId)
        .eq('work_date', workDate)
        .isFilter('clock_out', null)
        .select(_attendanceColumns);
    if (rows.isEmpty) {
      throw StateError('Sem entrada registada para $userId em $workDate.');
    }
    return _mapAttendance(rows.first);
  }

  // ── Taxas de comissão ────────────────────────────────────────────────
  @override
  Future<List<EmployeeCommissionRate>> getCommissionRates({
    required String storeId,
  }) async {
    final rows = await supabaseClient
        .from(_rates)
        .select(_ratesColumns)
        .eq('store_id', storeId);
    return List.unmodifiable([for (final row in rows) _mapRate(row)]);
  }

  @override
  Future<void> setCommissionRate({
    required String storeId,
    required String userId,
    required int rateBps,
  }) async {
    if (rateBps < 0 || rateBps > 10000) {
      throw StateError('Taxa de comissão inválida: $rateBps bps.');
    }
    // UPSERT na chave UNIQUE (store_id, user_id) — define ou atualiza.
    final existing = await supabaseClient
        .from(_rates)
        .select('id')
        .eq('store_id', storeId)
        .eq('user_id', userId);
    if (existing.isEmpty) {
      await supabaseClient.from(_rates).insert({
        'id': 'crate_${storeId}_$userId',
        'store_id': storeId,
        'user_id': userId,
        'rate_bps': rateBps,
      });
    } else {
      await supabaseClient
          .from(_rates)
          .update({'rate_bps': rateBps})
          .eq('store_id', storeId)
          .eq('user_id', userId);
    }
  }

  // ── Metas ────────────────────────────────────────────────────────────
  @override
  Future<List<EmployeeTarget>> getTargets({
    required String storeId,
    String? month,
  }) async {
    var query = supabaseClient
        .from(_targets)
        .select(_targetsColumns)
        .eq('store_id', storeId);
    if (month != null) {
      query = query.eq('month', month);
    }
    final rows = await query.order('created_at');
    return List.unmodifiable([for (final row in rows) _mapTarget(row)]);
  }

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
    final existing = await supabaseClient
        .from(_targets)
        .select('id')
        .eq('store_id', storeId)
        .eq('user_id', userId)
        .eq('month', month);
    if (existing.isEmpty) {
      await supabaseClient.from(_targets).insert({
        'id': 'tgt_${storeId}_${userId}_$month',
        'store_id': storeId,
        'user_id': userId,
        'month': month,
        'target_cents': targetCents,
      });
    } else {
      await supabaseClient
          .from(_targets)
          .update({'target_cents': targetCents})
          .eq('store_id', storeId)
          .eq('user_id', userId)
          .eq('month', month);
    }
  }

  @override
  Future<void> removeTarget(String id, {required String storeId}) async {
    await supabaseClient
        .from(_targets)
        .delete()
        .eq('id', id)
        .eq('store_id', storeId);
  }

  // ── Mapeamento ───────────────────────────────────────────────────────
  EmployeeAttendance _mapAttendance(Map<String, dynamic> row) {
    final clockIn = DateTime.parse(row['clock_in'] as String).toLocal();
    return EmployeeAttendance(
      id: row['id'] as String,
      storeId: row['store_id'] as String,
      userId: row['user_id'] as String,
      workDate: row['work_date'] as String,
      clockIn: clockIn,
      clockOut: row['clock_out'] == null
          ? null
          : DateTime.parse(row['clock_out'] as String).toLocal(),
      recordedBy: row['recorded_by'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  EmployeeCommissionRate _mapRate(Map<String, dynamic> row) =>
      EmployeeCommissionRate(
        id: row['id'] as String,
        storeId: row['store_id'] as String,
        userId: row['user_id'] as String,
        rateBps: (row['rate_bps'] as num).toInt(),
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );

  EmployeeTarget _mapTarget(Map<String, dynamic> row) => EmployeeTarget(
        id: row['id'] as String,
        storeId: row['store_id'] as String,
        userId: row['user_id'] as String,
        month: row['month'] as String,
        targetCents: (row['target_cents'] as num).toInt(),
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      );
}