import '../entities/purchase.dart';
import '../repositories/i_purchase_repository.dart';

/// Caso de uso: obter todas as compras registradas da loja [storeId].
class GetPurchasesUseCase {
 const GetPurchasesUseCase(this._repository);

 final IPurchaseRepository _repository;

 Future<List<Purchase>> call({required String storeId}) =>
 _repository.getAll(storeId: storeId);
}
