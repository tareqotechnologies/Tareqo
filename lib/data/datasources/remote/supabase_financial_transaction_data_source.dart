import '../../../domain/entities/financial_transaction.dart';
import '../local/financial_transaction_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [FinancialTransactionLocalDataSource] sobre o
/// Supabase.
///
/// Os enums são persistidos pelo nome (mesma convenção do SQLite) e as datas
/// como TIMESTAMPTZ (ISO 8601). O filtro por período continua no repositório
/// (contrato do domínio); aqui apenas listar, gravar e marcar como paga.
/// O RLS isola os dados por tenant (`auth.uid() = user_id`).
final class FinancialTransactionSupabaseDataSourceImpl
    implements FinancialTransactionLocalDataSource {
  const FinancialTransactionSupabaseDataSourceImpl();

  static const _table = 'financial_transactions';

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async {
    final rows = await supabaseClient
        .from(_table)
        .select(
          'id, store_id, description, amount, type, category, date, status, '
          'debt_id',
        )
        .eq('store_id', storeId)
        .order('date', ascending: false)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> add(FinancialTransaction transaction) async {
    await supabaseClient.from(_table).insert({
      'id': transaction.id,
      'user_id': requireCurrentUserId(),
      'store_id': transaction.storeId,
      'description': transaction.description,
      'amount': transaction.amount,
      'type': transaction.type.name,
      'category': transaction.category,
      'date': transaction.date.toUtc().toIso8601String(),
      'status': transaction.status.name,
      if (transaction.debtId != null) 'debt_id': transaction.debtId,
    }, defaultToNull: false);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    // A data também é carimbada: a realização no caixa acontece quando o
    // dinheiro entra (recebimento), não quando a pendência foi registrada —
    // mesma semântica do datasource SQLite. Escopo por loja: o filtro
    // store_id impede baixar transação de outra loja (defesa em
    // profundidade além do RLS).
    final rows = await supabaseClient
        .from(_table)
        .update({
          'status': TransactionStatus.paid.name,
          'date': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('store_id', storeId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Transação $id não encontrada para baixa.');
    }
  }

  FinancialTransaction _map(Map<String, dynamic> row) => FinancialTransaction(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    description: row['description'] as String,
    amount: (row['amount'] as num).toDouble(),
    type: TransactionType.values.byName(row['type'] as String),
    category: row['category'] as String,
    date: DateTime.parse(row['date'] as String).toLocal(),
    status: TransactionStatus.values.byName(row['status'] as String),
    debtId: row['debt_id'] as String?,
  );
}
