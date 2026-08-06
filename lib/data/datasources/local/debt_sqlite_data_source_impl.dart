import 'package:sqlite3/sqlite3.dart';

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
      'id, store_id, person_name, amount, due_date, is_customer_debt, '
      'is_paid, paid_at, customer_id';

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
    _db.execute(
      'INSERT INTO debts ($_columns) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        debt.id,
        debt.storeId,
        debt.personName,
        debt.amountCents,
        debt.dueDate.millisecondsSinceEpoch,
        debt.isCustomerDebt ? 1 : 0,
        debt.isPaid ? 1 : 0,
        debt.paidAt?.millisecondsSinceEpoch,
        debt.customerId,
      ],
    );
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
