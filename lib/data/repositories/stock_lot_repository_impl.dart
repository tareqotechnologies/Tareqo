import '../datasources/local/stock_lot_local_data_source.dart';
import '../../domain/entities/stock_lot.dart';
import '../../domain/repositories/i_stock_lot_repository.dart';

/// Implementação do [IStockLotRepository] — delega ao datasource local
/// (memória/SQLite/Supabase) sem conhecer a persistência.
final class StockLotRepositoryImpl implements IStockLotRepository {
 const StockLotRepositoryImpl(this._localDataSource);

 final StockLotLocalDataSource _localDataSource;

 @override
 Future<List<StockLot>> getActiveByProduct(
 String productId, {
 required String storeId,
 }) =>
 _localDataSource.getActiveByProduct(productId, storeId: storeId);

 @override
 Future<List<StockLot>> getByStore({required String storeId}) =>
 _localDataSource.getByStore(storeId: storeId);

 @override
 Future<void> add(StockLot lot) => _localDataSource.add(lot);

 @override
 Future<void> updateQuantity(
 String lotId,
 int newQuantity, {
 required String storeId,
 }) =>
 _localDataSource.updateQuantity(lotId, newQuantity, storeId: storeId);

 @override
 Future<void> increaseQuantity(
 String lotId,
 int quantity, {
 required String storeId,
 }) =>
 _localDataSource.increaseQuantity(lotId, quantity, storeId: storeId);
}
