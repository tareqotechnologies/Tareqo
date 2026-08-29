import '../../../domain/entities/invoice.dart';

/// Contrato de armazenamento de facturas (camada de dados).
abstract interface class InvoiceLocalDataSource {
  /// Cria uma nova factura (estado `pending`).
  Future<Invoice> create(Invoice invoice);

  /// Facturas de um tenant (ordenadas por data de criação desc).
  Future<List<Invoice>> getByTenant(String tenantId);

  /// Todas as facturas pendentes (painel admin).
  Future<List<Invoice>> getPending();

  /// Todas as facturas (painel admin).
  Future<List<Invoice>> getAll();

  /// Marca uma factura como paga.
  Future<void> markAsPaid(String invoiceId);

  /// Cancela uma factura.
  Future<void> cancel(String invoiceId);

  /// Verifica se já existe factura pendente para o tenant no período.
  Future<bool> hasPendingForPeriod(String tenantId, String period);
}
