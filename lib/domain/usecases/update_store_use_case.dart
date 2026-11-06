import '../entities/store.dart';
import '../entities/tenant.dart';
import '../repositories/i_store_repository.dart';
import '../repositories/i_tenant_repository.dart';
import 'add_store_use_case.dart' show TenantNotApprovedException, InvalidStoreException;

/// Caso de uso: atualizar os detalhes de uma loja (nome, endereço, etc.).
///
/// Apenas o dono do tenant pode editar; a autorização de UI é verificada
/// na tela, mas o caso de uso garante que o tenant está aprovado e os
/// dados são válidos.
class UpdateStoreUseCase {
  const UpdateStoreUseCase(
    this._storeRepository,
    this._tenantRepository,
  );

  final IStoreRepository _storeRepository;
  final ITenantRepository _tenantRepository;

  Future<void> call(Store store) async {
    if (store.name.trim().isEmpty) {
      throw const InvalidStoreException('Informe o nome da loja.');
    }

    final tenant = await _tenantRepository.getById(store.tenantId);
    if (tenant == null || tenant.status != TenantStatus.approved) {
      throw const TenantNotApprovedException(
        'Seu acesso ao ERP ainda não foi aprovado.',
      );
    }

    await _storeRepository.update(store);
  }
}
