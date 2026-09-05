import '../../../domain/entities/custom_invoice.dart';
import 'custom_invoice_local_data_source.dart';

/// Implementação em memória do [CustomInvoiceLocalDataSource] (web/testes).
///
/// Dados não persistem entre sessões — apenas para o fluxo de dev sem
/// Supabase/SQLite (mesmo papel dos demais datasources em memória).
final class CustomInvoiceLocalDataSourceImpl
    implements CustomInvoiceLocalDataSource {
  CustomInvoiceLocalDataSourceImpl({List<CustomInvoice> seed = const []})
    : _invoices = {for (final invoice in seed) invoice.id: invoice};

  final Map<String, CustomInvoice> _invoices;

  @override
  Future<List<CustomInvoice>> getAll({required String storeId}) async {
    final list = _invoices.values
        .where((invoice) => invoice.storeId == storeId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<CustomInvoice> add(CustomInvoice invoice) async {
    if (_invoices.containsKey(invoice.id)) {
      throw StateError('Factura ${invoice.id} já existe.');
    }
    // Número SEQUENCIAL da loja (MAX+1) — o armazenamento é a autoridade,
    // mesma semântica do SQLite/Supabase (o número enviado é ignorado).
    var nextNumber = 0;
    for (final existing in _invoices.values) {
      if (existing.storeId == invoice.storeId &&
          existing.number > nextNumber) {
        nextNumber = existing.number;
      }
    }
    final persisted = invoice.copyWith(number: nextNumber + 1);
    _invoices[persisted.id] = persisted;
    return persisted;
  }
}
