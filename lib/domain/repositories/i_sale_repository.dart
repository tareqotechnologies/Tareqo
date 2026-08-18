import '../entities/sale.dart';
import '../entities/sale_lot_consumption.dart';

/// Contrato de persistência de vendas (camada de domínio).
///
/// Declara apenas *o que* o sistema precisa — **não** *como* é feito.
/// A implementação concreta (ex.: `SaleRepositoryImpl` com SQLite) vive
/// na camada `data` e implementa este contrato.
abstract interface class ISaleRepository {
 /// Registra uma venda concluída.
 Future<void> registerSale(Sale sale);

 /// Retorna todas as vendas da loja [storeId] (sem ordenação garantida)
 /// — cada loja tem seu próprio histórico (Fase 2 do multi-tenancy).
 Future<List<Sale>> getAll({required String storeId});

 /// Retorna a venda [id] da loja [storeId], ou `null` se não existir
 /// (ou pertencer a outra loja). Usada pela anulação para recuperar o
 /// total e a forma de pagamento a estornar.
 Future<Sale?> getById(String id, {required String storeId});

 /// Marca a venda [id] da loja [storeId] como [SaleStatus.cancelled],
 /// registrando o momento da anulação. Lança [StateError] se a venda
 /// não existir na loja.
 Future<void> markCancelled(String id, {required String storeId});

 /// Retorna os lotes consumidos pela venda [saleId] (ordem de consumo)
 /// — usada pela anulação para devolver o estoque aos lotes EXATOS.
 Future<List<LotConsumption>> getLotConsumption(
 String saleId, {
 required String storeId,
 });

 /// Registra o consumo de lotes de uma venda — gravado na MESMA
 /// transação da venda (caminho composto local; no Supabase o RPC
 /// `process_sale` grava sozinho). Permite a anulação exata depois.
 Future<void> registerLotConsumption(
 String saleId,
 String storeId,
 List<LotConsumption> consumption,
 );
}
