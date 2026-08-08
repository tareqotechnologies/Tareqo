import 'package:sqlite3/sqlite3.dart';

import '../../../core/database/app_database_io.dart';
import '../../../domain/entities/debt.dart';
import 'debt_local_data_source.dart';

/// Implementação SQLite do [DebtLocalDataSource].
///
/// Os booleanos (`is_customer_debt`, `is_paid`) são persistidos como 0/1;
/// o filtro "apenas a receber de clientes" continua no domínio
/// (GetPendingDebtsUseCase).
final class DebtSqliteDataSourceImpl implements DebtLocalDataSource {
  const DebtSqliteDataSourceImpl(this._db);

  final Database _db;

  static const _columns =
      'id, store_id, debt_number, person_name, amount, due_date, '
      'is_customer_debt, is_paid, paid_at, customer_id';

  @override
  Future<List<Debt>> getAll({required String storeId}) async {
    final rows = _db.select(
      'SELECT $_columns FROM debts WHERE store_id = ? ORDER BY due_date',
      [storeId],
    );
    return [for (final row in rows) _map(row)];
  }

  @override
  Future<void> add(Debt debt) async {
    AppDatabase.runInTransaction(_db, () {
      // Número SEQUENCIAL da dívida na loja: MAX+1 calculado DENTRO da
      // mesma transação (BEGIN IMMEDIATE segura a escrita) — duas dívidas
      // concorrentes na mesma loja nunca recebem o mesmo número. O valor
      // enviado no objeto é ignorado: o banco é a autoridade.
      final nextNumber = _db.select(
        'SELECT COALESCE(MAX(debt_number), 0) + 1 AS next '
        'FROM debts WHERE store_id = ?',
        [debt.storeId],
      ).first['next'] as int;

      _db.execute(
        'INSERT INTO debts ($_columns) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          debt.id,
          debt.storeId,
          nextNumber,
          debt.personName,
          debt.amountCents,
          debt.dueDate.millisecondsSinceEpoch,
          debt.isCustomerDebt ? 1 : 0,
          debt.isPaid ? 1 : 0,
          debt.paidAt?.millisecondsSinceEpoch,
          debt.customerId,
        ],
      );
    });
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    // Carimba também a data da baixa (histórico de quitações). Escopo por
    // loja: o WHERE com store_id impede baixar dívida de outra loja.
    _db.execute(
      'UPDATE debts SET is_paid = 1, paid_at = ? '
      'WHERE id = ? AND store_id = ?',
      [DateTime.now().millisecondsSinceEpoch, id, storeId],
    );
    if (_db.updatedRows == 0) {
      throw StateError('Dívida $id não encontrada para baixa.');
    }
  }

  Debt _map(Row row) => Debt(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    number: (row['debt_number'] as num).toInt(),
    personName: row['person_name'] as String,
    amountCents: (row['amount'] as num).toInt(),
    dueDate: DateTime.fromMillisecondsSinceEpoch(row['due_date'] as int),
    isCustomerDebt: (row['is_customer_debt'] as int) == 1,
    isPaid: (row['is_paid'] as int) == 1,
    paidAt: row['paid_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['paid_at'] as int),
    customerId: row['customer_id'] as String?,
  );
}
