import '../entities/quotation.dart';

/// Contrato de acesso a cotações/orçamentos (camada de domínio).
///
/// A cotação é um documento por loja ([Quotation.storeId]) com número
/// SEQUENCIAL dentro da loja (MAX+1 atribuído na gravação — o banco é a
/// autoridade, como nas vendas e facturas). Persistida de verdade: fecha o
/// app, reabre, a cotação e o seu estado continuam lá.
abstract interface class IQuotationRepository {
  /// Cotações da loja [storeId], da mais recente para a mais antiga.
  Future<List<Quotation>> getByStore(String storeId);

  /// Persiste uma cotação nova, atribuindo número sequencial da loja.
  /// Retorna a cotação como ficou gravada.
  Future<Quotation> add(Quotation quotation);

  /// Grava mudanças numa cotação existente (ex.: transição de estado
  /// rascunho → enviada → aceite/rejeitada). Retorna a entidade gravada.
  Future<Quotation> update(Quotation quotation);
}
