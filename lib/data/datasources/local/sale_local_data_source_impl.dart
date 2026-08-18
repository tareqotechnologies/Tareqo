import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_lot_consumption.dart';
import 'sale_local_data_source.dart';

/// Implementação em memória do [SaleLocalDataSource].
///
/// Simula a tabela de vendas com uma `List<Sale>` e o consumo de lotes
/// com um mapa `saleId → List<LotConsumption>`. Inicia vazia por padrão
/// (testes dependem disso) — sem dados de demonstração.
final class SaleLocalDataSourceImpl implements SaleLocalDataSource {
 SaleLocalDataSourceImpl({List<Sale> seed = const []})
 : _sales = [...seed];

 final List<Sale> _sales;

 /// Consumo de lotes por venda (para a anulação exata).
 final Map<String, List<LotConsumption>> _consumption = {};

 @override
 Future<List<Sale>> getAll({required String storeId}) async =>
 List.unmodifiable(_sales.where((sale) => sale.storeId == storeId));

 @override
 Future<Sale?> getById(String id, {required String storeId}) async {
 for (final sale in _sales) {
 if (sale.id == id && sale.storeId == storeId) return sale;
 }
 return null;
 }

 @override
 Future<void> add(Sale sale) async {
 _sales.add(sale);
 }

 @override
 Future<void> markCancelled(String id, {required String storeId}) async {
 final index = _sales.indexWhere(
 (sale) => sale.id == id && sale.storeId == storeId,
 );
 if (index == -1) {
 throw StateError('Venda $id não encontrada para anulação.');
 }
 _sales[index] = _sales[index].copyWith(
 status: SaleStatus.cancelled,
 cancelledAt: DateTime.now(),
 );
 }

 @override
 Future<List<LotConsumption>> getLotConsumption(
 String saleId, {
 required String storeId,
 }) async =>
 List.unmodifiable(_consumption[saleId] ?? const []);

 @override
 Future<void> registerLotConsumption(
 String saleId,
 String storeId,
 List<LotConsumption> consumption,
 ) async {
 _consumption[saleId] = [...consumption];
 }
}
