import '../entities/customer.dart';
import '../repositories/i_customer_repository.dart';

/// Exceção de domínio: cliente inválido (sem nome).
final class InvalidCustomerException implements Exception {
 const InvalidCustomerException(this.message);

 final String message;

 @override
 String toString() => 'InvalidCustomerException: $message';
}

/// Caso de uso: cadastrar um novo cliente.
///
/// A validação do nome vive aqui (e não na UI) para que qualquer ponto de
/// entrada passe pela mesma regra antes de persistir.
class AddCustomerUseCase {
 const AddCustomerUseCase(this._repository);

 final ICustomerRepository _repository;

 /// Cadastra [customer], validando que o nome não seja vazio.
 ///
 /// Lança [InvalidCustomerException] em caso de falha; o cliente **não** é
 /// persistido nesse caso.
 Future<void> call(Customer customer) async {
 if (customer.name.trim().isEmpty) {
 throw const InvalidCustomerException('Informe o nome do cliente.');
 }
 await _repository.add(customer);
 }
}
