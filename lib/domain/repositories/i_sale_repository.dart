import '../entities/sale.dart';

/// Contrato de persistência de vendas (camada de domínio).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// A implementação concreta (ex.: `SaleRepositoryImpl` com SQLite) vive
/// na camada `data` e implementa este contrato.
abstract interface class ISaleRepository {
  /// Registra uma venda concluída.
  Future<void> registerSale(Sale sale);

  /// Retorna todas as vendas da loja [storeId] (sem ordenação garantida)
  /// — cada loja tem seu próprio histórico (Fase 2 do multi-tenancy).
  Future<List<Sale>> getAll({required String storeId});
}
