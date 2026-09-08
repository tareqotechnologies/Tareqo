import '../../../domain/entities/purchase.dart';

/// Contrato de armazenamento local de compras (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória, SQLite, Supabase... O repositório
/// depende desta abstração, e não de uma implementação.
abstract interface class PurchaseLocalDataSource {
  /// Retorna todas as compras da loja [storeId] armazenadas.
  Future<List<Purchase>> getAll({required String storeId});

  /// Registra uma compra no armazenamento (compra + itens).
  Future<void> add(Purchase purchase);
}
