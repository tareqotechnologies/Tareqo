import '../../domain/entities/financial_transaction.dart';
import '../../domain/repositories/i_financial_transaction_repository.dart';
import '../datasources/local/financial_transaction_local_data_source.dart';

/// Implementação concreta de [IFinancialTransactionRepository] sobre um
/// [FinancialTransactionLocalDataSource].
///
/// O filtro por período acontece aqui (em Dart). Em uma futura
/// implementação SQLite, o `WHERE date BETWEEN` viveria no datasource —
/// o contrato do domínio permanece o mesmo.
final class FinancialTransactionRepositoryImpl
    implements IFinancialTransactionRepository {
  const FinancialTransactionRepositoryImpl(this._dataSource);

  final FinancialTransactionLocalDataSource _dataSource;

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) =>
      _dataSource.getAll(storeId: storeId);

  @override
  Future<void> add(FinancialTransaction transaction) =>
      _dataSource.add(transaction);

  @override
  Future<void> markAsPaid(String id, {required String storeId}) =>
      _dataSource.markAsPaid(id, storeId: storeId);

  @override
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    final all = await _dataSource.getAll(storeId: storeId);
    return all
        .where(
          (transaction) =>
              !transaction.date.isBefore(start) &&
              !transaction.date.isAfter(end),
        )
        .toList();
  }
}
