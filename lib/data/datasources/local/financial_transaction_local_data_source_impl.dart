import '../../../domain/entities/financial_transaction.dart';
import 'financial_transaction_local_data_source.dart';

/// Implementação em memória do [FinancialTransactionLocalDataSource].
///
/// Simula a tabela de transações com uma `List<FinancialTransaction>`.
/// Inicia vazia por padrão (testes dependem disso) — sem dados de
/// demonstração. Para migrar a SQLite,
/// basta criar uma implementação com as mesmas assinaturas e trocá-la
/// no registro.
final class FinancialTransactionLocalDataSourceImpl
    implements FinancialTransactionLocalDataSource {
  FinancialTransactionLocalDataSourceImpl({
    List<FinancialTransaction> seed = const [],
  }) : _transactions = [...seed];

  final List<FinancialTransaction> _transactions;

  @override
  Future<List<FinancialTransaction>> getAll({required String storeId}) async =>
      List.unmodifiable(
        _transactions.where((transaction) => transaction.storeId == storeId),
      );

  @override
  Future<void> add(FinancialTransaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> markAsPaid(String id, {required String storeId}) async {
    // Escopo por loja: só a transação da loja informada é mutável.
    final index = _transactions.indexWhere(
      (t) => t.id == id && t.storeId == storeId,
    );
    if (index == -1) {
      throw StateError('Transação $id não encontrada para baixa.');
    }
    // FinancialTransaction é imutável: substitui por uma nova instância
    // com status pago e data do recebimento (o caixa é realizado quando o
    // dinheiro entra, não quando a pendência foi registrada).
    _transactions[index] = _transactions[index].copyWith(
      status: TransactionStatus.paid,
      date: DateTime.now(),
    );
  }
}
