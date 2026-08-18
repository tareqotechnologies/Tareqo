import '../../../core/utils/ids.dart';
import '../../../domain/entities/plan_request.dart';
import '../local/plan_request_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [PlanRequestLocalDataSource] sobre o Supabase.
///
/// O dono cria o pedido e consulta os do próprio tenant; o super admin
/// lista pendentes e decide (aprova/rejeita).
final class PlanRequestSupabaseDataSourceImpl
 implements PlanRequestLocalDataSource {
 const PlanRequestSupabaseDataSourceImpl();

 static const _table = 'plan_requests';
 static const _columns =
 'id, tenant_id, current_plan_id, requested_plan_id, '
 'status, decided_at, created_at';

 @override
 Future<List<PlanRequest>> getByTenant(String tenantId) async {
 final rows = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('tenant_id', tenantId)
 .order('created_at', ascending: false)
 .limit(SupabaseQueryLimits.pageSize);
 return List.unmodifiable([for (final row in rows) _map(row)]);
 }

 @override
 Future<PlanRequest?> getById(String id) async {
 final row = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('id', id)
 .maybeSingle();
 return row == null ? null : _map(row);
 }

 @override
 Future<List<PlanRequest>> getPending() async {
 final rows = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('status', PlanRequestStatus.pending.name)
 .order('created_at', ascending: true)
 .limit(SupabaseQueryLimits.pageSize);
 return List.unmodifiable([for (final row in rows) _map(row)]);
 }

 @override
 Future<PlanRequest> create({
 required String tenantId,
 required String currentPlanId,
 required String requestedPlanId,
 }) async {
 final rows = await supabaseClient
 .from(_table)
 .insert({
 'id': AppIds.newId('pr'),
 'tenant_id': tenantId,
 'current_plan_id': currentPlanId,
 'requested_plan_id': requestedPlanId,
 'status': PlanRequestStatus.pending.name,
 })
 .select(_columns);
 return _map(rows.first);
 }

 @override
 Future<void> decide(String id, {required bool approve}) async {
 final rows = await supabaseClient
 .from(_table)
 .update({
 'status': approve
 ? PlanRequestStatus.approved.name
 : PlanRequestStatus.rejected.name,
 'decided_at': DateTime.now().toUtc().toIso8601String(),
 })
 .eq('id', id)
 .select('id');
 if (rows.isEmpty) {
 throw StateError('Pedido de upgrade $id não encontrado.');
 }
 }

 PlanRequest _map(Map<String, dynamic> row) => PlanRequest(
 id: row['id'] as String,
 tenantId: row['tenant_id'] as String,
 currentPlanId: row['current_plan_id'] as String,
 requestedPlanId: row['requested_plan_id'] as String,
 status: PlanRequestStatus.values.byName(row['status'] as String),
 decidedAt: row['decided_at'] == null
 ? null
 : DateTime.parse(row['decided_at'] as String).toLocal(),
 createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
 );
}
