import '../entities/financial_transaction.dart';
import '../repositories/i_financial_transaction_repository.dart';

/// Exceção de domínio: valor inválido para uma transação financeira.
final class InvalidAmountException implements Exception {
 const InvalidAmountException(this.message);

 final String message;

 @override
 String toString() => 'InvalidAmountException: $message';
}

/// Caso de uso: registrar uma transação financeira (entrada ou saída).
///
/// A validação do valor vive aqui (e não na UI) para que qualquer ponto
/// de entrada — formulário, importação, futura API — passe pela mesma
/// regra antes de persistir.
class AddFinancialTransactionUseCase {
 const AddFinancialTransactionUseCase(this._repository);

 final IFinancialTransactionRepository _repository;

 /// Registra [transaction], validando que o valor seja maior que zero.
 ///
 /// Lança [InvalidAmountException] em caso de falha; a transação **não**
 /// é persistida nesse caso.
 Future<void> call(FinancialTransaction transaction) async {
 if (transaction.amountCents <= 0) {
 throw InvalidAmountException(
 'O valor da transação deve ser maior que zero.',
 );
 }

 await _repository.add(transaction);
 }
}
