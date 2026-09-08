import '../../../domain/entities/quotation.dart';

/// Contrato de armazenamento de cotações (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória (web/testes), SQLite (modo local),
/// Supabase (modo SaaS).
abstract interface class QuotationLocalDataSource {
  /// Cotações da loja [storeId], da mais recente para a mais antiga.
  Future<List<Quotation>> getAll({required String storeId});

  /// Grava uma cotação nova e devolve a entidade como ficou persistida
  /// (número sequencial da loja atribuído aqui — o banco é a autoridade).
  /// Lança [StateError] se já existir uma cotação com o mesmo id.
  Future<Quotation> add(Quotation quotation);

  /// Grava mudanças numa cotação existente (estado, notas, itens).
  /// Lança [StateError] se a cotação não existir.
  Future<Quotation> update(Quotation quotation);
}
