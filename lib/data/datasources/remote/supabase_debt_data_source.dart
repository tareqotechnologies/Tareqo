import '../../../domain/entities/debt.dart';
import '../local/debt_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [DebtLocalDataSource] ("fiado") sobre o Supabase.
///
/// Booleanos são BOOLEAN no Postgres (o RLS isola por tenant via
/// `auth.uid() = user_id`). A baixa (`markAsPaid`) carimba `is_paid = true`
/// e `paid_at = now()` — alimenta o histórico de quitações, mesma semântica
/// do datasource SQLite.
final class DebtSupabaseDataSourceImpl implements DebtLocalDataSource {
 /// [rpc] injetável para testes — mesmo contrato do `SupabaseEmployeeProcessor`
 /// (`Future<dynamic> Function(String fn, Map<String, dynamic> params)`),
 /// que permite o teste de CONTRATO das RPCs atômicas (`settle_debt`,
 /// `register_debt`) sem inicializar o cliente real. `null` (padrão) →
 /// cliente global ([supabaseClient]).
 const DebtSupabaseDataSourceImpl({
 Future<dynamic> Function(String fn, Map<String, dynamic> params)? rpc,
 }) : _rpcOverride = rpc;

 final Future<dynamic> Function(String fn, Map<String, dynamic> params)?
 _rpcOverride;

 Future<dynamic> _rpc(String fn, Map<String, dynamic> params) =>
 _rpcOverride != null
 ? _rpcOverride(fn, params)
 : supabaseClient.rpc(fn, params: params);

 /// Em modo de teste (rpc injetado), o guard de sessão é ignorado — o
 /// teste controla o contrato da RPC. Em produção, falha cedo sem sessão.
 void _requireSessionOrTest() {
 if (_rpcOverride == null) requireCurrentUserId();
 }

 static const _table = 'debts';

 /// Quita a dívida [debtId] da loja [storeId] **atomicamente** no servidor
 /// (RPC `settle_debt` — baixa + resolução da pendência vinculada, ou
 /// entrada direta no caixa para fiado antigo, em UMA transação).
 ///
 /// Usado pelo caminho atômico do [SettleDebtUseCase] no modo Supabase;
 /// o caminho composto ([markAsPaid] + entrada) permanece para os demais.
 Future<void> settleDebt(String debtId, {required String storeId}) async {
 _requireSessionOrTest();
 await _rpc(
 'settle_debt',
 {'p_debt_id': debtId, 'p_store': storeId},
 );
 }

 /// Registra a dívida E a pendência financeira vinculada **atomicamente**
 /// no servidor (RPC `register_debt` — uma única transação no banco).
 ///
 /// Usado pelo caminho atômico do [AddDebtUseCase] no modo Supabase;
 /// o [add] composto permanece para os demais backends.
 Future<void> registerDebt(Debt debt) async {
 _requireSessionOrTest();
 await _rpc(
 'register_debt',
 {
 'p_debt': {
 'id': debt.id,
 'store_id': debt.storeId,
 'person_name': debt.personName,
 'amount': debt.amountCents,
 'due_date': debt.dueDate.toUtc().toIso8601String(),
 'is_customer_debt': debt.isCustomerDebt,
 if (debt.customerId != null) 'customer_id': debt.customerId,
 },
 },
 );
 }

 @override
 Future<List<Debt>> getAll({required String storeId}) async {
 // Paginação keyset (H2): lotes de pageSize pelo id, sem teto total.
 // A ordem final de exibição (vencimento/baixa) é aplicada pelo
 // provider (pendentes por due_date, quitadas por paid_at).
 final rows = await fetchAllKeyset(
 supabaseClient
 .from(_table)
 .select(
 'id, store_id, debt_number, person_name, amount, due_date, '
 'is_customer_debt, is_paid, paid_at, customer_id',
 )
 .eq('store_id', storeId),
 );
 return List.unmodifiable([for (final row in rows) _map(row)]);
 }

 @override
 Future<void> add(Debt debt) async {
 // Fallback não-atômico (não usado pelo app no modo SaaS — as dívidas
 // vão pela RPC register_debt, que numera no servidor). Melhor esforço:
 // lê o maior debt_number da loja e incrementa.
 final last = await supabaseClient
 .from(_table)
 .select('debt_number')
 .eq('store_id', debt.storeId)
 .order('debt_number', ascending: false)
 .limit(1);
 final nextNumber = last.isEmpty
 ? 1
 : ((last.first['debt_number'] as num).toInt() + 1);
 await supabaseClient.from(_table).insert({
 'id': debt.id,
 'user_id': requireCurrentUserId(),
 'store_id': debt.storeId,
 'debt_number': nextNumber,
 'person_name': debt.personName,
 'amount': debt.amountCents,
 'due_date': debt.dueDate.toUtc().toIso8601String(),
 'is_customer_debt': debt.isCustomerDebt,
 'is_paid': debt.isPaid,
 if (debt.paidAt != null)
 'paid_at': debt.paidAt!.toUtc().toIso8601String(),
 if (debt.customerId != null) 'customer_id': debt.customerId,
 }, defaultToNull: false);
 }

 @override
 Future<void> markAsPaid(String id, {required String storeId}) async {
 // Escopo por loja: o filtro store_id impede baixar dívida de outra
 // loja (defesa em profundidade além do RLS).
 final rows = await supabaseClient
 .from(_table)
 .update({
 'is_paid': true,
 'paid_at': DateTime.now().toUtc().toIso8601String(),
 })
 .eq('id', id)
 .eq('store_id', storeId)
 .select('id');
 if (rows.isEmpty) {
 throw StateError('Dívida $id não encontrada para baixa.');
 }
 }

 Debt _map(Map<String, dynamic> row) => Debt(
 id: row['id'] as String,
 storeId: row['store_id'] as String,
 number: (row['debt_number'] as num?)?.toInt() ?? 0,
 personName: row['person_name'] as String,
 amountCents: (row['amount'] as num).toInt(),
 dueDate: DateTime.parse(row['due_date'] as String).toLocal(),
 isCustomerDebt: row['is_customer_debt'] as bool,
 isPaid: row['is_paid'] as bool,
 paidAt: row['paid_at'] == null
 ? null
 : DateTime.parse(row['paid_at'] as String).toLocal(),
 customerId: row['customer_id'] as String?,
 );
}
