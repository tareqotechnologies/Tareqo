import '../../domain/entities/custom_invoice.dart';
import '../../domain/repositories/i_custom_invoice_repository.dart';
import '../datasources/local/custom_invoice_local_data_source.dart';

/// Implementação de [ICustomInvoiceRepository] sobre um
/// [CustomInvoiceLocalDataSource].
///
/// O repositório **não sabe** se os dados vêm da memória, do SQLite ou do
/// Supabase: apenas delega para o datasource injetado.
final class CustomInvoiceRepositoryImpl implements ICustomInvoiceRepository {
  const CustomInvoiceRepositoryImpl(this._dataSource);

  final CustomInvoiceLocalDataSource _dataSource;

  @override
  Future<List<CustomInvoice>> getByStore(String storeId) =>
      _dataSource.getAll(storeId: storeId);

  @override
  Future<CustomInvoice> add(CustomInvoice invoice) => _dataSource.add(invoice);
}
