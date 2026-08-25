import '../entities/customer.dart';
import '../repositories/i_customer_repository.dart';
import 'add_customer_use_case.dart';

/// Caso de uso: atualizar dados de um cliente existente.
///
/// Valida que o nome não seja vazio antes de persistir — a mesma regra
/// do [AddCustomerUseCase] garante consistência em qualquer ponto de entrada.
class UpdateCustomerUseCase {
  const UpdateCustomerUseCase(this._repository);

  final ICustomerRepository _repository;

  /// Atualiza [customer], validando que o nome não seja vazio.
  ///
  /// Lança [InvalidCustomerException] em caso de falha de validação.
  Future<void> call(Customer customer) async {
    if (customer.name.trim().isEmpty) {
      throw const InvalidCustomerException('Informe o nome do cliente.');
    }
    await _repository.update(customer);
  }
}
