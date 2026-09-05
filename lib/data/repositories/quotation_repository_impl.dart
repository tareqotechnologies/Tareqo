import '../../domain/entities/quotation.dart';
import '../../domain/repositories/i_quotation_repository.dart';
import '../datasources/local/quotation_local_data_source.dart';

/// Implementação de [IQuotationRepository] sobre um
/// [QuotationLocalDataSource].
///
/// O repositório **não sabe** se os dados vêm da memória, do SQLite ou do
/// Supabase: apenas delega para o datasource injetado.
final class QuotationRepositoryImpl implements IQuotationRepository {
  const QuotationRepositoryImpl(this._dataSource);

  final QuotationLocalDataSource _dataSource;

  @override
  Future<List<Quotation>> getByStore(String storeId) =>
      _dataSource.getAll(storeId: storeId);

  @override
  Future<Quotation> add(Quotation quotation) => _dataSource.add(quotation);

  @override
  Future<Quotation> update(Quotation quotation) =>
      _dataSource.update(quotation);
}