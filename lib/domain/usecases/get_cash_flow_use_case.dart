import '../../core/utils/money.dart';
import '../entities/financial_transaction.dart';
import '../repositories/i_financial_transaction_repository.dart';

/// Exceção de domínio: período inválido para cálculo de fluxo de caixa.
final class InvalidPeriodException implements Exception {
  const InvalidPeriodException(this.message);

  final String message;

  @override
  String toString() => 'InvalidPeriodException: $message';
}

/// Resultado do fluxo de caixa em um período.
final class CashFlow {
  const CashFlow({required this.income, required this.expense});

  /// Total de entradas no período.
  final double income;

  /// Total de saídas no período.
  final double expense;

  /// Saldo: entradas − saídas.
  double get balance => income - expense;

  @override
  String toString() =>
      'CashFlow(income: $income, expense: $expense, balance: $balance)';
}

/// Caso de uso: calcular o fluxo de caixa (entradas − saídas) em um período.
class GetCashFlowUseCase {
  const GetCashFlowUseCase(this._repository);

  final IFinancialTransactionRepository _repository;

  /// Calcula o **fluxo de caixa realizado** da loja [storeId] no período
  /// `[start, end]` (inclusive) — considera apenas transações com
  /// [TransactionStatus.paid].
  ///
  /// Vendas "fiadas" (entradas pendentes) só contam quando recebidas;
  /// contas a pagar pendentes também não saem do caixa ainda.
  ///
  /// Lança [InvalidPeriodException] se `start` for posterior a `end`.
  Future<CashFlow> call({
    required String storeId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (start.isAfter(end)) {
      throw InvalidPeriodException(
        'A data inicial ($start) não pode ser posterior à final ($end).',
      );
    }

    final transactions = await _repository.getByPeriod(
      storeId: storeId,
      start: start,
      end: end,
    );

    // Acúmulo em CENTAVOS (auditoria H1): somar doubles como 0.1+0.2
    // acumula erro de representação; somar inteiros de centavos é exato.
    final incomeValues = <double>[];
    final expenseValues = <double>[];
    for (final transaction in transactions) {
      // Caixa realizado: ignora transações ainda pendentes.
      if (transaction.status != TransactionStatus.paid) continue;

      if (transaction.type == TransactionType.income) {
        incomeValues.add(transaction.amount);
      } else {
        expenseValues.add(transaction.amount);
      }
    }

    return CashFlow(
      income: Money.sum(incomeValues),
      expense: Money.sum(expenseValues),
    );
  }
}
