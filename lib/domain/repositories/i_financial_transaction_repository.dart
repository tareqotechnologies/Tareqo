import '../entities/financial_transaction.dart';

/// Contrato de persistência de transações financeiras (camada de domínio).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// A implementação concreta (ex.: SQLite com `WHERE date BETWEEN`)
/// vive na camada `data`.
abstract interface class IFinancialTransactionRepository {
  /// Retorna as transações da loja [storeId] com [date] dentro do
  /// intervalo `[start, end]` (inclusive) — o caixa é por loja (Fase 2
  /// do multi-tenancy).
  Future<List<FinancialTransaction>> getByPeriod({
    required String storeId,
    required DateTime start,
    required DateTime end,
  });

  /// Retorna todas as transações da loja [storeId] (sem ordenação
  /// garantida).
  Future<List<FinancialTransaction>> getAll({required String storeId});

  /// Registra uma nova transação financeira.
  Future<void> add(FinancialTransaction transaction);

  /// Marca a transação [id] da loja [storeId] como paga
  /// ([TransactionStatus.paid]).
  ///
  /// Usado na baixa de fiado ([SettleDebtUseCase]) e no recebimento
  /// manual de pendências — a transação passa a contar no caixa realizado.
  /// A **data passa a ser a do recebimento**: a realização no caixa acontece
  /// quando o dinheiro entra, não quando a pendência foi registrada.
  /// A baixa é escopada pela loja: um id de outra loja não é alcançável.
  /// Lança [StateError] se a transação não existir.
  Future<void> markAsPaid(String id, {required String storeId});
}
