import '../../domain/entities/cash_closing.dart';
import '../../domain/repositories/i_cash_closing_repository.dart';
import '../datasources/local/cash_closing_local_data_source.dart';

/// Implementação de [ICashClosingRepository] sobre um
/// [CashClosingLocalDataSource].
///
/// O repositório **não sabe** se os dados vêm da memória, do SQLite ou do
/// Supabase: apenas delega para o datasource injetado (mesmo padrão dos
/// demais repositórios do app).
final class CashClosingRepositoryImpl implements ICashClosingRepository {
 const CashClosingRepositoryImpl(this._localDataSource);

 final CashClosingLocalDataSource _localDataSource;

 @override
 Future<CashClosing?> getByDay({
 required String storeId,
 required DateTime day,
 }) =>
 _localDataSource.getByDay(storeId: storeId, day: day);

 @override
 Future<void> save(CashClosing closing) => _localDataSource.save(closing);

 @override
 Future<List<CashClosing>> getAll({required String storeId}) =>
 _localDataSource.getAll(storeId: storeId);
}
