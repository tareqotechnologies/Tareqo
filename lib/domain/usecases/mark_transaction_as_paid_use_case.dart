import '../repositories/i_financial_transaction_repository.dart';

/// Caso de uso: marcar uma transação financeira pendente como paga.
///
/// Completa o ciclo `pending → paid`: uma entrada registrada como
/// pendente (ex.: fiado) passa a contar no caixa realizado quando é
/// recebida. Usado pela tela de Financeiro no botão "Receber".
class MarkTransactionAsPaidUseCase {
 const MarkTransactionAsPaidUseCase(this._repository);

 final IFinancialTransactionRepository _repository;

 /// Marca a transação [transactionId] da loja [storeId] como paga — a
 /// baixa é escopada pela loja (não alcança transação de outra loja).
 Future<void> call(String transactionId, {required String storeId}) =>
 _repository.markAsPaid(transactionId, storeId: storeId);
}
