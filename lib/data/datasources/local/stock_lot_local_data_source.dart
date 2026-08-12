import '../../../domain/entities/stock_lot.dart';

/// Contrato de armazenamento local de LOTES de estoque (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações: memória, SQLite e Supabase (RLS por tenant). A ordem
/// FIFO de consumo é parte do contrato (mesma do [IStockLotRepository]).
abstract interface class StockLotLocalDataSource {
  /// Lotes ativos (`current_quantity > 0`) do produto [productId] na loja
  /// [storeId], em ordem FIFO: validade mais próxima primeiro; sem
  /// validade no fim (por data de entrada).
  Future<List<StockLot>> getActiveByProduct(
    String productId, {
    required String storeId,
  });

  /// Lotes ativos da loja [storeId] (todos os produtos) — alertas de
  /// validade do dashboard. Ordem FIFO por validade/entrada.
  Future<List<StockLot>> getByStore({required String storeId});

  /// Adiciona um lote ao armazenamento.
  Future<void> add(StockLot lot);

  /// Define a quantidade atual do lote [lotId] da loja [storeId]
  /// (valor absoluto, milésimos) — escopado pela loja.
  Future<void> updateQuantity(
    String lotId,
    int newQuantity, {
    required String storeId,
  });

  /// ACRESCENTA [quantity] milésimos à quantidade atual do lote [lotId]
  /// da loja [storeId] (anulação de venda — devolve ao lote exato
  /// consumido). Escopado pela loja.
  Future<void> increaseQuantity(
    String lotId,
    int quantity, {
    required String storeId,
  });
}
