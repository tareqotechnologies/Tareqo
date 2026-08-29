import '../entities/invoice.dart';

/// Contrato de acesso a facturas de cobrança (camada de domínio).
///
/// Facturas são geradas automaticamente 7 dias antes do plano do tenant
/// expirar. O super admin pode visualizá-las e marcá-las como pagas.
abstract interface class IInvoiceRepository {
  /// Cria uma nova factura para o tenant (estado `pending`).
  Future<Invoice> create(Invoice invoice);

  /// Retorna todas as facturas de um tenant, ordenadas por data de
  /// criação (mais recente primeiro).
  Future<List<Invoice>> getByTenant(String tenantId);

  /// Retorna todas as facturas pendentes no sistema (painel admin).
  Future<List<Invoice>> getPending();

  /// Retorna todas as facturas (painel admin).
  Future<List<Invoice>> getAll();

  /// Marca uma factura como paga.
  Future<void> markAsPaid(String invoiceId);

  /// Cancela uma factura.
  Future<void> cancel(String invoiceId);

  /// Verifica se já existe uma factura pendente para o tenant no período
  /// indicado (evita duplicação).
  Future<bool> hasPendingForPeriod(String tenantId, String period);
}
