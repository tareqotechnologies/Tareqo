import '../../domain/entities/invoice.dart';
import '../../domain/repositories/i_invoice_repository.dart';
import '../datasources/local/invoice_local_data_source.dart';

/// Implementação de [IInvoiceRepository] sobre um [InvoiceLocalDataSource].
final class InvoiceRepositoryImpl implements IInvoiceRepository {
  const InvoiceRepositoryImpl(this._localDataSource);

  final InvoiceLocalDataSource _localDataSource;

  @override
  Future<Invoice> create(Invoice invoice) =>
      _localDataSource.create(invoice);

  @override
  Future<List<Invoice>> getByTenant(String tenantId) =>
      _localDataSource.getByTenant(tenantId);

  @override
  Future<List<Invoice>> getPending() => _localDataSource.getPending();

  @override
  Future<List<Invoice>> getAll() => _localDataSource.getAll();

  @override
  Future<void> markAsPaid(String invoiceId) =>
      _localDataSource.markAsPaid(invoiceId);

  @override
  Future<void> cancel(String invoiceId) => _localDataSource.cancel(invoiceId);

  @override
  Future<bool> hasPendingForPeriod(String tenantId, String period) =>
      _localDataSource.hasPendingForPeriod(tenantId, period);
}
