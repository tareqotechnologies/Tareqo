import '../../domain/entities/employee_management.dart';
import '../../domain/repositories/i_employee_commission_summary_repository.dart';
import '../datasources/remote/supabase_datasource_helpers.dart';

/// Implementação do [IEmployeeCommissionSummaryRepository] sobre a RPC
/// `get_employee_commission_summary` do Supabase (SECURITY DEFINER com
/// guarda is_my_store — mesmo padrão get_cash_flow/get_sales_report).
final class SupabaseEmployeeCommissionSummaryRepository
    implements IEmployeeCommissionSummaryRepository {
  const SupabaseEmployeeCommissionSummaryRepository();

  @override
  Future<List<EmployeeCommissionSummaryEntry>> getSummary({
    required String storeId,
    required String month,
  }) async {
    final rows = await supabaseClient.rpc(
      'get_employee_commission_summary',
      params: {'p_store_id': storeId, 'p_month': month},
    );
    final entries = <EmployeeCommissionSummaryEntry>[];
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      entries.add(
        EmployeeCommissionSummaryEntry(
          userId: map['user_id'] as String,
          fullName: map['full_name'] as String? ?? '',
          salesCents: (map['sales_cents'] as num).toInt(),
          rateBps: (map['rate_bps'] as num).toInt(),
          commissionCents: (map['commission_cents'] as num).toInt(),
        ),
      );
    }
    return List.unmodifiable(entries);
  }
}
