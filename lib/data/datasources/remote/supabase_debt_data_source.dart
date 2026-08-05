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
  const DebtSupabaseDataSourceImpl();

  static const _table = 'debts';

  /// Quita a dívida [debtId] da loja [storeId] **atomicamente** no servidor
  /// (RPC `settle_debt` — baixa + resolução da pendência vinculada, ou
  /// entrada direta no caixa para fiado antigo, em UMA transação).
  ///
  /// Usado pelo caminho atômico do [SettleDebtUseCase] no modo Supabase;
  /// o caminho composto ([markAsPaid] + entrada) permanece para os demais.
  Future<void> settleDebt(String debtId, {required String storeId}) async {
    requireCurrentUserId(); // Falha cedo (cliente) se não houver sessão.
    await supabaseClient.rpc('settle_debt', params: {
      'p_debt_id': debtId,
      'p_store': storeId,
    });
  }

  /// Registra a dívida E a pendência financeira vinculada **atomicamente**
  /// no servidor (RPC `register_debt` — uma única transação no banco).
  ///
  /// Usado pelo caminho atômico do [AddDebtUseCase] no modo Supabase;
  /// o [add] composto permanece para os demais backends.
  Future<void> registerDebt(Debt debt) async {
    requireCurrentUserId(); // Falha cedo (cliente) se não houver sessão.
    await supabaseClient.rpc('register_debt', params: {
      'p_debt': {
        'id': debt.id,
        'store_id': debt.storeId,
        'person_name': debt.personName,
        'amount': debt.amount,
        'due_date': debt.dueDate.toUtc().toIso8601String(),
        'is_customer_debt': debt.isCustomerDebt,
        if (debt.customerId != null) 'customer_id': debt.customerId,
      },
    });
  }

  @override
  Future<List<Debt>> getAll({required String storeId}) async {
    final rows = await supabaseClient
        .from(_table)
        .select(
          'id, store_id, person_name, amount, due_date, is_customer_debt, '
          'is_paid, paid_at, customer_id',
        )
        .eq('store_id', storeId)
        .order('due_date', ascending: true);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> add(Debt debt) async {
    await supabaseClient.from(_table).insert({
      'id': debt.id,
      'user_id': requireCurrentUserId(),
      'store_id': debt.storeId,
      'person_name': debt.personName,
      'amount': debt.amount,
      'due_date': debt.dueDate.toUtc().toIso8601String(),
      'is_customer_debt': debt.isCustomerDebt,
      'is_paid': debt.isPaid,
      if (debt.paidAt != null) 'paid_at': debt.paidAt!.toUtc().toIso8601String(),
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
        personName: row['person_name'] as String,
        amount: (row['amount'] as num).toDouble(),
        dueDate: DateTime.parse(row['due_date'] as String).toLocal(),
        isCustomerDebt: row['is_customer_debt'] as bool,
        isPaid: row['is_paid'] as bool,
        paidAt: row['paid_at'] == null
            ? null
            : DateTime.parse(row['paid_at'] as String).toLocal(),
        customerId: row['customer_id'] as String?,
      );
}
