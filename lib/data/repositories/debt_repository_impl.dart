import '../../domain/entities/debt.dart';
import '../../domain/repositories/i_debt_repository.dart';
import '../datasources/local/debt_local_data_source.dart';

/// Implementação concreta de [IDebtRepository] sobre um
/// [DebtLocalDataSource] — hoje em memória; a SQLite trocaria apenas o
/// datasource injetado, sem tocar no domínio.
final class DebtRepositoryImpl implements IDebtRepository {
 const DebtRepositoryImpl(this._dataSource);

 final DebtLocalDataSource _dataSource;

 @override
 Future<List<Debt>> getAll({required String storeId}) =>
 _dataSource.getAll(storeId: storeId);

 @override
 Future<void> add(Debt debt) => _dataSource.add(debt);

 @override
 Future<void> markAsPaid(String id, {required String storeId}) =>
 _dataSource.markAsPaid(id, storeId: storeId);
}
