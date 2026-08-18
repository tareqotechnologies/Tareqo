import '../entities/store.dart';

/// Contrato de acesso a lojas (camada de domínio).
abstract interface class IStoreRepository {  /// Lojas de um tenant (ordem de criação).
  Future<List<Store>> getByTenant(String tenantId);

  /// Cria uma loja no tenant.
  Future<void> add(Store store);

  /// Atualiza os dados de uma loja (nome, endereço, contacto, NUIT).
  Future<void> update(Store store);
}
