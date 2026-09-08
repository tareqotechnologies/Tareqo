import '../../../domain/entities/customer.dart';
import 'customer_local_data_source.dart';

/// Implementação em memória do [CustomerLocalDataSource].
///
/// Simula a tabela de clientes com uma `List<Customer>`. Inicia vazia por
/// padrão (testes dependem disso) — nunca há dados de demonstração; o
/// ServiceLocator injeta apenas o que a aplicação cria de real.
final class CustomerLocalDataSourceImpl implements CustomerLocalDataSource {
  CustomerLocalDataSourceImpl({List<Customer> seed = const []})
    : _customers = [...seed];

  final List<Customer> _customers;

  @override
  Future<List<Customer>> getAll({required String storeId}) async {
    // Filtra pela loja ativa e mantém a mesma ordenação do SQLite (por
    // nome, case-insensitive).
    final filtered = _customers.where((c) => c.storeId == storeId);
    final sorted = [...filtered]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(sorted);
  }

  @override
  Future<void> add(Customer customer) async {
    _customers.add(customer);
  }

  @override
  Future<void> update(Customer customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) _customers[index] = customer;
  }

  @override
  Future<void> delete(String id) async {
    _customers.removeWhere((c) => c.id == id);
  }
}
