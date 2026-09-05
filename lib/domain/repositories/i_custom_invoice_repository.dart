import '../entities/custom_invoice.dart';

/// Contrato de acesso a facturas personalizadas (camada de domínio).
///
/// A factura é um documento por loja ([CustomInvoice.storeId]) com número
/// SEQUENCIAL dentro da loja (MAX+1 atribuído na gravação — o banco é a
/// autoridade, como nas vendas). Persistida de verdade: fecha o app,
/// reabre, a factura continua lá.
abstract interface class ICustomInvoiceRepository {
  /// Facturas da loja [storeId], da mais recente para a mais antiga.
  Future<List<CustomInvoice>> getByStore(String storeId);

  /// Persiste uma factura nova, atribuindo número sequencial da loja.
  /// Retorna a factura como ficou gravada.
  Future<CustomInvoice> add(CustomInvoice invoice);
}
