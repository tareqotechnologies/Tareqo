import '../repositories/i_customer_repository.dart';

/// Caso de uso: remover um cliente pelo seu [id].
class DeleteCustomerUseCase {
  const DeleteCustomerUseCase(this._repository);

  final ICustomerRepository _repository;

  /// Remove o cliente com o [id] informado.
  Future<void> call(String id) => _repository.delete(id);
}
