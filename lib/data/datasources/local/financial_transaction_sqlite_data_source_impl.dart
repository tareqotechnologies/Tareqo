import 'package:sqlite3/sqlite3.dart';

import '../../../domain/entities/financial_transaction.dart';
import 'financial_transaction_local_data_source.dart';

/// Implementação SQLite do [FinancialTransactionLocalDataSource].
///
/// Os enums são persistidos pelo **nome** (estável na serialização) e as
/// datas como epoch millis. O filtro por período continua no repositório
/// (contrato do domínio); aqui apenas listar e gravar.
final class FinancialTransactionSqliteDataSourceImpl
    implements FinancialTransactionLocalDataSource {
  const FinancialTransactionSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, description, amount, type, category, date, status, '
      'debt_id';

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM financial_transactions WHERE store_id = ? '
      'ORDER BY date DESC',
      [storeId],
    );
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<void> add(FinancialTransaction transaction) async {
    _db.execute(
      'INSERT INTO financial_transactions '
      '($_columns) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        transaction.id,
        transaction.storeId,
        transaction.description,
        transaction.amountCents,
        transaction.type.name,
        transaction.category,
        transaction.date.millisecondsSinceEpoch,
        transaction.status.name,
        transaction.debtId,
      ],
    );
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    // A data também é carimbada: a realização no caixa acontece quando o
    // dinheiro entra (recebimento), não quando a pendência foi registrada.
    // Escopo por loja: o WHERE com store_id impede baixar transação de
    // outra loja.
    _db.execute(
      "UPDATE financial_transactions SET status = 'paid', date = ? "
      'WHERE id = ? AND store_id = ?',
      [DateTime.now().millisecondsSinceEpoch, id, storeId],
    );
    if (_db.updatedRows == 0) {
      throw StateError('Transação $id não encontrada para baixa.');
    }
  }

  FinancialTransaction _map(Row row) => FinancialTransaction(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    description: row['description'] as String,
    amountCents: (row['amount'] as num).toInt(),
    type: TransactionType.values.byName(row['type'] as String),
    category: row['category'] as String,
    date: DateTime.fromMillisecondsSinceEpoch(row['date'] as int),
    status: TransactionStatus.values.byName(row['status'] as String),
    debtId: row['debt_id'] as String?,
  );
}
