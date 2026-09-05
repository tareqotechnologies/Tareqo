import '../../../domain/entities/custom_invoice.dart';

/// Contrato de armazenamento de facturas personalizadas (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória (web/testes), SQLite (modo local),
/// Supabase (modo SaaS).
abstract interface class CustomInvoiceLocalDataSource {
  /// Facturas da loja [storeId], da mais recente para a mais antiga.
  Future<List<CustomInvoice>> getAll({required String storeId});

  /// Grava uma factura nova e devolve a entidade como ficou persistida
  /// (número sequencial da loja atribuído aqui — o banco é a autoridade).
  /// Lança [StateError] se já existir uma factura com o mesmo id.
  Future<CustomInvoice> add(CustomInvoice invoice);
}
