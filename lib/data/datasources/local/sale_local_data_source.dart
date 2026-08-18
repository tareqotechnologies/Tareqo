import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_lot_consumption.dart';

/// Contrato de armazenamento local de vendas (camada de dados).
///
/// Declara apenas *o que* a persistência precisa fazer — não *como*.
/// Implementações possíveis: memória (atual), SQLite, Hive, drift...
abstract interface class SaleLocalDataSource {
 /// Retorna todas as vendas da loja [storeId] armazenadas localmente.
 Future<List<Sale>> getAll({required String storeId});

 /// Retorna a venda [id] da loja [storeId], ou `null` se não existir
 /// (ou pertencer a outra loja).
 Future<Sale?> getById(String id, {required String storeId});

 /// Registra uma venda no armazenamento local.
 Future<void> add(Sale sale);

 /// Marca a venda [id] da loja [storeId] como anulada, registrando o
 /// momento da anulação. Lança [StateError] se a venda não existir.
 Future<void> markCancelled(String id, {required String storeId});

 /// Retorna os lotes consumidos pela venda [saleId] da loja [storeId]
 /// (para a anulação devolver o estoque aos lotes exatos).
 Future<List<LotConsumption>> getLotConsumption(
 String saleId, {
 required String storeId,
 });

 /// Registra o consumo de lotes de uma venda (mesma transação da venda
 /// no caminho composto local; no Supabase o RPC grava sozinho).
 Future<void> registerLotConsumption(
 String saleId,
 String storeId,
 List<LotConsumption> consumption,
 );
}
