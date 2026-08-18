import '../../../domain/entities/purchase.dart';
import 'purchase_local_data_source.dart';

/// Implementação em memória do [PurchaseLocalDataSource].
///
/// Simula a tabela de compras com uma `List<Purchase>`. Inicia vazia por
/// padrão (testes dependem disso) — sem dados de demonstração.
final class PurchaseLocalDataSourceImpl implements PurchaseLocalDataSource {
 PurchaseLocalDataSourceImpl({List<Purchase> seed = const []})
 : _purchases = [...seed];

 final List<Purchase> _purchases;

 @override
 Future<List<Purchase>> getAll({required String storeId}) async =>
 List.unmodifiable(
 _purchases.where((purchase) => purchase.storeId == storeId),
 );

 @override
 Future<void> add(Purchase purchase) async {
 _purchases.add(purchase);
 }
}
