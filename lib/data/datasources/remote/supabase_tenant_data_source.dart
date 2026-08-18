import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/ids.dart';
import '../../../domain/entities/tenant.dart';
import '../../../domain/usecases/request_tenant_access_use_case.dart';
import '../local/tenant_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [TenantLocalDataSource] sobre o Supabase.
///
/// O dono cria a solicitação (`status = pending`) e consulta o próprio
/// tenant; o super admin decide. O RLS garante que cada papel enxergue
/// apenas o que pode (`auth.uid() = owner_user_id` para o dono; papel de
/// super admin baseado em BANCO — tabela `public.super_admins` via RPC
/// `is_super_admin` — para o painel).
final class TenantSupabaseDataSourceImpl implements TenantLocalDataSource {
 const TenantSupabaseDataSourceImpl();

 static const _table = 'tenants';
 static const _columns =
 'id, owner_user_id, business_name, plan_id, status, '
 'rejection_reason, approved_at, created_at, currency_code, language';

 @override
 Future<Tenant?> getMyTenant(String userId) async {
 // Dono do tenant.
 final row = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('owner_user_id', userId)
 .maybeSingle();
 if (row != null) return _map(row);

 // Funcionário vinculado a uma loja do tenant (Fase 1): resolve o
 // tenant através do vínculo em store_employees.
 final employee = await supabaseClient
 .from('store_employees')
 .select('tenant_id')
 .eq('user_id', userId)
 .limit(1)
 .maybeSingle();
 if (employee == null) return null;

 final viaEmployee = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('id', employee['tenant_id'] as String)
 .maybeSingle();
 return viaEmployee == null ? null : _map(viaEmployee);
 }

 @override
 Future<Tenant?> getById(String id) async {
 final row = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('id', id)
 .maybeSingle();
 return row == null ? null : _map(row);
 }

 @override
 Future<Tenant> requestAccess({
 required String ownerUserId,
 required String businessName,
 required String planId,
 required String currencyCode,
 required String language,
 }) async {
 try {
 final rows = await supabaseClient
 .from(_table)
 .insert({
 'id': AppIds.newId('tn'),
 'owner_user_id': ownerUserId,
 'business_name': businessName,
 'plan_id': planId,
 'status': TenantStatus.pending.name,
 'currency_code': currencyCode,
 'language': language,
 })
 .select(_columns);
 return _map(rows.first);
 } on PostgrestException catch (error) {
 // Anti-spam (auditoria S3): violação do índice único de tenant
 // pendente (23505) — corrida entre a guarda do use case e o INSERT.
 // Converte o erro cru do banco numa mensagem amigável.
 if (error.code == '23505') {
 throw const InvalidTenantRequestException(
 'Você já possui um cadastro de acesso. Aguarde a aprovação.',
 );
 }
 rethrow;
 }
 }

 @override
 Future<void> updateSettings(
 String id, {
 required String currencyCode,
 required String language,
 }) async {
 // A política RLS `tenants_update` só permite o SUPER ADMIN alterar o
 // tenant (status/plano são decisões administrativas) — um UPDATE direto
 // do dono retornava 0 linhas e os ajustes nunca salvavam. O dono troca
 // moeda/idioma pela RPC SECURITY DEFINER `update_tenant_settings`, que
 // valida is_tenant_owner e atualiza APENAS as colunas de apresentação.
 await supabaseClient.rpc(
 'update_tenant_settings',
 params: {
 'p_tenant_id': id,
 'p_currency_code': currencyCode,
 'p_language': language,
 },
 );
 }

 @override
 Future<void> approve(String id) async {
 final rows = await supabaseClient
 .from(_table)
 .update({
 'status': TenantStatus.approved.name,
 'approved_at': DateTime.now().toUtc().toIso8601String(),
 })
 .eq('id', id)
 .select('id');
 if (rows.isEmpty) {
 throw StateError('Tenant $id não encontrado para aprovação.');
 }
 }

 @override
 Future<void> reject(String id, String reason) async {
 final rows = await supabaseClient
 .from(_table)
 .update({
 'status': TenantStatus.rejected.name,
 'rejection_reason': reason,
 })
 .eq('id', id)
 .select('id');
 if (rows.isEmpty) {
 throw StateError('Tenant $id não encontrado para rejeição.');
 }
 }

 @override
 Future<void> updatePlan(String id, String planId) async {
 final rows = await supabaseClient
 .from(_table)
 .update({'plan_id': planId})
 .eq('id', id)
 .select('id');
 if (rows.isEmpty) {
 throw StateError('Tenant $id não encontrado para troca de plano.');
 }
 }

 @override
 Future<List<Tenant>> getPending() async {
 final rows = await supabaseClient
 .from(_table)
 .select(_columns)
 .eq('status', TenantStatus.pending.name)
 .order('created_at', ascending: true)
 .limit(SupabaseQueryLimits.pageSize);
 return List.unmodifiable([for (final row in rows) _map(row)]);
 }

 @override
 Future<List<Tenant>> getAll() async {
 final rows = await supabaseClient
 .from(_table)
 .select(_columns)
 .order('created_at', ascending: true)
 .limit(SupabaseQueryLimits.pageSize);
 return List.unmodifiable([for (final row in rows) _map(row)]);
 }

 Tenant _map(Map<String, dynamic> row) => Tenant(
 id: row['id'] as String,
 ownerUserId: row['owner_user_id'] as String,
 businessName: row['business_name'] as String,
 planId: row['plan_id'] as String,
 status: TenantStatus.values.byName(row['status'] as String),
 rejectionReason: row['rejection_reason'] as String?,
 approvedAt: row['approved_at'] == null
 ? null
 : DateTime.parse(row['approved_at'] as String).toLocal(),
 createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
 // Defaults para bancos ainda sem a migração das colunas.
 currencyCode: (row['currency_code'] as String?) ?? 'MZN',
 language: (row['language'] as String?) ?? 'pt',
 );
}
