import '../../../domain/entities/sale.dart';

/// Contrato de armazenamento local de vendas (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória (atual), SQLite, Hive, drift...
abstract interface class SaleLocalDataSource {
  /// Retorna todas as vendas da loja [storeId] armazenadas localmente.
  Future<List<Sale>> getAll({required String storeId});

  /// Registra uma venda no armazenamento local.
  Future<void> add(Sale sale);
}
