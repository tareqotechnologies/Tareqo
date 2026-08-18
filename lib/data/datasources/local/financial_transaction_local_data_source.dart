import '../../../domain/entities/financial_transaction.dart';

/// Contrato de armazenamento local de transações financeiras (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória (atual), SQLite, Hive, drift...
abstract interface class FinancialTransactionLocalDataSource {
 /// Retorna todas as transações da loja [storeId] armazenadas
 /// localmente.
 Future<List<FinancialTransaction>> getAll({required String storeId});

 /// Registra uma transação no armazenamento local.
 Future<void> add(FinancialTransaction transaction);

 /// Marca a transação [id] da loja [storeId] como paga
 /// ([TransactionStatus.paid]) e atualiza a data para o recebimento (a
 /// realização no caixa acontece quando o dinheiro entra) — escopado
 /// pela loja. Lança [StateError] se não existir.
 Future<void> markAsPaid(String id, {required String storeId});
}
