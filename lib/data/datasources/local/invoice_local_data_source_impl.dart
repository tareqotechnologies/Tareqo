import '../../../core/utils/ids.dart';
import '../../../domain/entities/invoice.dart';
import 'invoice_local_data_source.dart';

/// Implementação em memória do [InvoiceLocalDataSource].
///
/// Usada em testes e no modo local (sem Supabase). Inicia vazia por padrão.
final class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  InvoiceLocalDataSourceImpl({List<Invoice> seed = const []})
    : _invoices = [...seed];

  final List<Invoice> _invoices;

  @override
  Future<Invoice> create(Invoice invoice) async {
    final number = _invoices.length + 1;
    final created = invoice.copyWith(
      id: invoice.id.isEmpty ? AppIds.newId('inv') : invoice.id,
      number: number,
    );
    _invoices.add(created);
    return created;
  }

  @override
  Future<List<Invoice>> getByTenant(String tenantId) async => List.unmodifiable(
    _invoices.where((i) => i.tenantId == tenantId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  @override
  Future<List<Invoice>> getPending() async => List.unmodifiable(
    _invoices.where((i) => i.status == InvoiceStatus.pending).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
  );

  @override
  Future<List<Invoice>> getAll() async => List.unmodifiable(
    [..._invoices]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
  );

  @override
  Future<void> markAsPaid(String invoiceId) async {
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index < 0) {
      throw StateError('Factura $invoiceId não encontrada.');
    }
    _invoices[index] = _invoices[index].copyWith(
      status: InvoiceStatus.paid,
      paidAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancel(String invoiceId) async {
    final index = _invoices.indexWhere((i) => i.id == invoiceId);
    if (index < 0) {
      throw StateError('Factura $invoiceId não encontrada.');
    }
    _invoices[index] = _invoices[index].copyWith(
      status: InvoiceStatus.cancelled,
    );
  }

  @override
  Future<bool> hasPendingForPeriod(String tenantId, String period) async {
    return _invoices.any(
      (i) =>
          i.tenantId == tenantId &&
          i.period == period &&
          i.status == InvoiceStatus.pending,
    );
  }
}
