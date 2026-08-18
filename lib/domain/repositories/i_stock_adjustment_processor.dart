/// Processador **atômico** de ajuste manual de estoque (contagem física,
/// quebra/perda) — define a quantidade absoluta do produto criando/consumindo
/// LOTES FIFO em uma única transação do banco.
///
/// Implementado apenas quando a plataforma de persistência oferece transação
/// multi-tabela no servidor — hoje, o Supabase via RPC `adjust_product_stock`
/// (`SECURITY DEFINER`, guarda gerencial `is_manager_of_store`). No
/// SQLite/memória o [UpdateProductUseCase] usa o caminho composto com
/// [IUnitOfWork] e [FifoStockUseCase], e este contrato fica sem implementação
/// registrada.
abstract interface class IStockAdjustmentProcessor {
 /// Define a quantidade em estoque do produto [productId] da loja
 /// [storeId] para [newQuantity] milésimos, ajustando os lotes FIFO na
 /// MESMA transação (a invariante `stock = Σ lotes` nunca quebra).
 ///
 /// Lança exceções de domínio equivalentes às do caminho composto
 /// (ex.: produto inexistente) — o caso de uso traduz para a UI.
 Future<void> adjustStock(
 String productId,
 int newQuantity, {
 required String storeId,
 });
}
