import '../../../domain/entities/store.dart';

/// Contrato de armazenamento de lojas (camada de dados).
abstract interface class StoreLocalDataSource {
 /// Lojas de um tenant (ordem de criação).
 Future<List<Store>> getByTenant(String tenantId);

 /// Cria uma loja.
 Future<void> add(Store store);
}
