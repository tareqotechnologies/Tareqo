import '../../../domain/entities/stock_lot.dart';
import 'stock_lot_local_data_source.dart';

/// Implementação em memória do [StockLotLocalDataSource] (web/fallback).
///
/// Mantém a MESMA ordenação FIFO do SQLite: validade mais próxima
/// primeiro; sem validade no fim (por data de entrada, depois por id).
final class StockLotLocalDataSourceImpl implements StockLotLocalDataSource {
  StockLotLocalDataSourceImpl({List<StockLot> seed = const []})
      : _lots = [...seed];

  final List<StockLot> _lots;

  static List<StockLot> _fifoSort(Iterable<StockLot> lots) {
    final sorted = [...lots]
      ..sort((a, b) {
        final aExp = a.expiryDate;
        final bExp = b.expiryDate;
        if (aExp == null && bExp == null) {
          final byEntry = a.entryDate.compareTo(b.entryDate);
          return byEntry != 0 ? byEntry : a.id.compareTo(b.id);
        }
        if (aExp == null) return 1; // sem validade no fim
        if (bExp == null) return -1;
        final byExpiry = aExp.compareTo(bExp);
        if (byExpiry != 0) return byExpiry;
        final byEntry = a.entryDate.compareTo(b.entryDate);
        return byEntry != 0 ? byEntry : a.id.compareTo(b.id);
      });
    return List.unmodifiable(sorted);
  }

  @override
  Future<List<StockLot>> getActiveByProduct(
    String productId, {
    required String storeId,
  }) async =>
      _fifoSort(
        _lots.where(
          (lot) =>
              lot.productId == productId &&
              lot.storeId == storeId &&
              lot.currentQuantity > 0,
        ),
      );

  @override
  Future<List<StockLot>> getByStore({required String storeId}) async =>
      _fifoSort(
        _lots.where(
          (lot) => lot.storeId == storeId && lot.currentQuantity > 0,
        ),
      );

  @override
  Future<void> add(StockLot lot) async {
    _lots.add(lot);
  }

  @override
  Future<void> updateQuantity(
    String lotId,
    int newQuantity, {
    required String storeId,
  }) async {
    final index = _lots.indexWhere(
      (lot) => lot.id == lotId && lot.storeId == storeId,
    );
    if (index == -1) {
      throw StateError('Lote $lotId não encontrado para atualização.');
    }
    _lots[index] = _lots[index].copyWith(currentQuantity: newQuantity);
  }

  @override
  Future<void> increaseQuantity(
    String lotId,
    int quantity, {
    required String storeId,
  }) async {
    final index = _lots.indexWhere(
      (lot) => lot.id == lotId && lot.storeId == storeId,
    );
    if (index == -1) {
      throw StateError('Lote $lotId não encontrado para atualização.');
    }
    _lots[index] = _lots[index].copyWith(
      currentQuantity: _lots[index].currentQuantity + quantity,
    );
  }
}
