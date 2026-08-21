import '../entities/store.dart';
import '../repositories/i_store_repository.dart';
import 'add_store_use_case.dart' show InvalidStoreException;

/// Caso de uso: atualizar os dados da loja (nome, endereço, contacto e
/// NUIT) — o dono ajusta em Lojas → Ajustes e os dados aparecem no
/// cabeçalho do recibo de venda (factura).
///
/// A autoridade real é o servidor: a política RLS `stores_update` restringe
/// o UPDATE ao dono do tenant (ou super admin) — este caso de uso apenas
/// valida os dados de entrada e delega ao repositório.
class UpdateStoreUseCase {
  const UpdateStoreUseCase(this._storeRepository);

  final IStoreRepository _storeRepository;

  Future<void> call(Store store) async {
    if (store.name.trim().isEmpty) {
      throw const InvalidStoreException('Informe o nome da loja.');
    }
    await _storeRepository.update(store);
  }
}
