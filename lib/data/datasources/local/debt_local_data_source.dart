import '../../../domain/entities/debt.dart';

/// Contrato de armazenamento local de dívidas (\"fiado\") — camada de dados.
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória (atual), SQLite, Hive, drift...
abstract interface class DebtLocalDataSource {
 /// Retorna todas as dívidas da loja [storeId] armazenadas localmente.
 Future<List<Debt>> getAll({required String storeId});

 /// Registra uma dívida no armazenamento local.
 Future<void> add(Debt debt);

 /// Marca a dívida [id] da loja [storeId] como quitada
 /// ([Debt.isPaid] = `true`) — escopado pela loja.
 Future<void> markAsPaid(String id, {required String storeId});
}
