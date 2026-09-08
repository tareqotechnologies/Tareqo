import '../entities/purchase.dart';

/// Processador **atômico** de compras (compra + itens + entrada de estoque
/// + saída no caixa em uma única transação do banco).
///
/// Implementado apenas quando a plataforma de persistência oferece
/// transação multi-tabela no servidor — hoje, o Supabase via RPC
/// (`process_purchase`, `SECURITY DEFINER`). No SQLite/memória o
/// [ProcessPurchaseUseCase] usa o caminho composto com [IUnitOfWork] e
/// este contrato fica sem implementação registrada.
abstract interface class IPurchaseAtomicProcessor {
  /// Processa [purchase] atomicamente no servidor.
  ///
  /// Lança exceções de domínio equivalentes às do caminho composto
  /// (ex.: produto inexistente) — o caso de uso traduz para a UI.
  Future<void> process(Purchase purchase);
}
