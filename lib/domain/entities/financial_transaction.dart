import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_transaction.freezed.dart';
part 'financial_transaction.g.dart';

/// Direção do movimento financeiro.
///
/// O [FinancialTransaction.amountCents] é sempre um valor **positivo**
/// (magnitude); a direção é definida por este enum.
enum TransactionType {
  income('Entrada'),
  expense('Saída');

  const TransactionType(this.label);

  /// Rótulo exibido na UI (a serialização JSON usa o nome do enum).
  final String label;
}

/// Situação do pagamento de uma transação.
///
/// Venda "fiada" = transação de entrada com [TransactionStatus.pending];
/// ao receber, o comerciante marca como [TransactionStatus.paid].
enum TransactionStatus {
  paid('Pago'),
  pending('Pendente');

  const TransactionStatus(this.label);

  /// Rótulo exibido na UI (a serialização JSON usa o nome do enum).
  final String label;
}

/// Entidade de domínio que representa um movimento financeiro
/// (entrada ou saída de caixa).
///
/// Separada de [Sale] (ver README): registra tanto **vendas** quanto
/// **despesas fixas** (aluguel, energia elétrica, salários, impostos) e
/// outras entradas/saídas sem relação com itens de venda ou estoque.
@freezed
abstract class FinancialTransaction with _$FinancialTransaction {
  // O valor é sempre magnitude positiva; a direção é definida por [type].
  // Assertions rodam em desenvolvimento e testes (em produção, valide no
  // use case e use CHECK no banco).
  @Assert('amountCents >= 0', 'O valor da transação deve ser positivo.')
  const factory FinancialTransaction({
    required String id,
    // Loja dona do movimento — o caixa é por loja (Fase 2 do
    // multi-tenancy).
    @Default('st1') String storeId,
    required String description,
    // Valor em CENTAVOS inteiros (W4 — migração de dinheiro para
    // centavos; o banco persiste BIGINT/INTEGER).
    required int amountCents,
    required TransactionType type,
    required String category,
    required DateTime date,
    @Default(TransactionStatus.paid) TransactionStatus status,
    // Vínculo opcional com a dívida de "fiado" que originou a pendência
    // (ex.: seed). Permite que a baixa (SettleDebtUseCase) marque a MESMA
    // transação como paga, em vez de criar uma duplicata no caixa.
    String? debtId,
  }) = _FinancialTransaction;

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) =>
      _$FinancialTransactionFromJson(json);
}
