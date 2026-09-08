import '../../../domain/entities/customer.dart';

/// Contrato de armazenamento local de clientes (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória, SQLite, Supabase... O repositório
/// depende desta abstração, e não de uma implementação.
abstract interface class CustomerLocalDataSource {
  /// Retorna todos os clientes da loja [storeId] armazenados.
  Future<List<Customer>> getAll({required String storeId});

  /// Registra um cliente no armazenamento.
  Future<void> add(Customer customer);

  /// Atualiza os dados de um cliente existente.
  Future<void> update(Customer customer);

  /// Remove um cliente pelo seu [id].
  Future<void> delete(String id);
}
