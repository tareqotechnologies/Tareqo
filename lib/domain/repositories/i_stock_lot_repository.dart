import '../entities/stock_lot.dart';

/// Contrato de persistência de LOTES de estoque (camada de domínio).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// Implementações: memória, SQLite e Supabase (RLS por tenant). A ordem
/// FIFO de consumo é responsabilidade da implementação em
/// [getActiveByProduct]: sempre `expiry_date ASC NULLS LAST` e, no
/// desempate, `entry_date ASC, id ASC` (mais antigo/vencimento mais
/// próximo primeiro).
abstract interface class IStockLotRepository {
  /// Retorna os lotes ATIVOS (`current_quantity > 0`) do produto [productId]
  /// na loja [storeId], em **ordem FIFO de consumo**: validade mais próxima
  /// primeiro; lotes sem validade no fim (FIFO por data de entrada).
  Future<List<StockLot>> getActiveByProduct(
    String productId, {
    required String storeId,
  });

  /// Retorna os lotes ATIVOS da loja [storeId] inteira (todos os produtos)
  /// — usado pelos alertas de validade do dashboard. Ordenado por data de
  /// validade (mais próxima primeiro; sem validade no fim).
  Future<List<StockLot>> getByStore({required String storeId});

  /// Registra um novo lote (entrada de mercadoria).
  Future<void> add(StockLot lot);

  /// Define a quantidade ATUAL do lote [lotId] da loja [storeId] (valor
  /// absoluto, em milésimos) — escopado pela loja.
  Future<void> updateQuantity(
    String lotId,
    int newQuantity, {
    required String storeId,
  });

  /// ACRESCENTA [quantity] milésimos à quantidade ATUAL do lote [lotId]
  /// da loja [storeId] — usado pela anulação de venda para devolver o
  /// estoque ao lote EXATO que foi consumido (a quantidade de um lote só
  /// diminui nas baixas, então devolver nunca excede o lote). Escopado
  /// pela loja.
  Future<void> increaseQuantity(
    String lotId,
    int quantity, {
    required String storeId,
  });
}
