import '../entities/stock_lot.dart';
import '../repositories/i_stock_lot_repository.dart';

/// Caso de uso: leitura dos lotes ativos de uma loja.
///
/// Usado pelos alertas de validade do dashboard (vencidos / a expirar) —
/// leitura pura, sem mutação.
class GetStockLotsUseCase {
 const GetStockLotsUseCase(this._repository);

 final IStockLotRepository _repository;

 /// Lotes ativos (`current_quantity > 0`) da loja [storeId], em ordem
 /// FIFO por validade/entrada.
 Future<List<StockLot>> getByStore({required String storeId}) =>
 _repository.getByStore(storeId: storeId);
}
