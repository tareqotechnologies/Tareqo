import '../entities/customer.dart';
import '../repositories/i_customer_repository.dart';

/// Caso de uso: obter todos os clientes cadastrados da loja [storeId].
class GetCustomersUseCase {
  const GetCustomersUseCase(this._repository);

  final ICustomerRepository _repository;

  Future<List<Customer>> call({required String storeId}) =>
      _repository.getAll(storeId: storeId);
}
