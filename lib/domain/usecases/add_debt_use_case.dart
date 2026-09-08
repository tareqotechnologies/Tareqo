import '../../core/i18n/transaction_descriptions.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../entities/debt.dart';
import '../entities/financial_transaction.dart';
import '../repositories/i_debt_processor.dart';
import '../repositories/i_debt_repository.dart';
import '../repositories/i_financial_transaction_repository.dart';

/// Exceção de domínio: valor inválido para uma dívida.
final class InvalidDebtAmountException implements Exception {
  const InvalidDebtAmountException(this.message);

  final String message;

  @override
  String toString() => 'InvalidDebtAmountException: $message';
}

/// Exceção de domínio: a dívida foi registrada, mas a pendência financeira
/// vinculada não pôde ser gravada.
///
/// Sinalizada em separado para que a UI **não** sugira "tentar novamente"
/// (o que duplicaria a dívida) — o correto é informar que o fiado foi
/// registrado e que o Financeiro precisa de conferência.
final class PendingEntryRegistrationException implements Exception {
  const PendingEntryRegistrationException(this.cause);

  final Object cause;

  @override
  String toString() =>
      'PendingEntryRegistrationException: fiado registrado, mas a '
      'pendência financeira não foi criada ($cause).';
}

/// Caso de uso: registrar uma dívida ("fiado") a receber ou a pagar.
///
/// A validação do valor vive aqui (e não na UI) para que qualquer ponto
/// de entrada passe pela mesma regra antes de persistir. Além da dívida,
/// registra a **pendência financeira vinculada** — o livro reflete o
/// "fiado" desde o início (entrada pendente para contas a receber, saída
/// pendente para contas a pagar) e a baixa ([SettleDebtUseCase]) marca a
/// MESMA transação como paga.
///
/// Quando [processor] é fornecido (Supabase), a dívida + pendência são
/// gravadas atomicamente pelo servidor (RPC `register_debt`). Sem
/// processor (SQLite/memória), usa o caminho composto com a semântica
/// deliberada: se a pendência falhar, a dívida permanece registrada e a
/// UI orienta a conferir o Financeiro ([PendingEntryRegistrationException]).
class AddDebtUseCase {
  const AddDebtUseCase(
    this._debtRepository,
    this._transactionRepository, {
    this.processor,
  });

  final IDebtRepository _debtRepository;
  final IFinancialTransactionRepository _transactionRepository;

  /// Processador atômico opcional (Supabase via RPC).
  final IDebtAtomicProcessor? processor;

  /// Registra [debt], validando que o valor seja maior que zero, e cria a
  /// transação financeira pendente vinculada ([debtId]).
  ///
  /// Lança [InvalidDebtAmountException] em caso de falha de validação (nada
  /// é persistido) ou [PendingEntryRegistrationException] se a dívida foi
  /// gravada mas a pendência falhou.
  Future<void> call(Debt debt) async {
    if (debt.amountCents <= 0) {
      throw InvalidDebtAmountException(
        'O valor da dívida deve ser maior que zero.',
      );
    }

    // Caminho atômico (Supabase): o servidor grava dívida + pendência em
    // uma única transação (o RPC também valida o valor > 0).
    final atomicProcessor = processor;
    if (atomicProcessor != null) {
      await atomicProcessor.register(debt);
      return;
    }

    // 1. Registra a dívida (registro primário — a fonte de verdade do
    // "a receber / a pagar").
    await _debtRepository.add(debt);

    // 2. Pendência no livro financeiro, vinculada via debtId. A direção
    // segue a da dívida: cliente → entrada a receber; fornecedor →
    // saída a pagar. A dívida vem antes de propósito: se a pendência
    // falhar, o fiado continua existindo (a baixa cobre o caso).
    try {
      await _transactionRepository.add(
        FinancialTransaction(
          id: AppIds.newId('t'),
          // A pendência entra no caixa da MESMA loja da dívida.
          storeId: debt.storeId,
          description: TransactionDescriptions.debt(
            language: Formatters.currentLanguage,
            isCustomerDebt: debt.isCustomerDebt,
            personName: debt.personName,
          ),
          amountCents: debt.amountCents,
          type: debt.isCustomerDebt
              ? TransactionType.income
              : TransactionType.expense,
          category: TransactionDescriptions.debtCategory(
            Formatters.currentLanguage,
          ),
          date: DateTime.now(),
          status: TransactionStatus.pending,
          debtId: debt.id,
        ),
      );
    } catch (error) {
      throw PendingEntryRegistrationException(error);
    }
  }
}
