import '../entities/production_order.dart';

/// Processador **atômico** de produção (baixa FIFO dos componentes + criação
/// do lote do produto acabado + gravação da ordem em uma única transação do
/// banco).
///
/// Implementado apenas quando a plataforma oferece transação multi-tabela no
/// servidor — hoje, o Supabase via RPC (`process_production`,
/// `SECURITY DEFINER`). No SQLite/memória o `ProcessProductionUseCase` usa o
/// caminho composto com `IUnitOfWork` e este contrato fica sem implementação
/// registrada.
abstract interface class IProductionProcessor {
  /// Processa [order] atomicamente no servidor.
  ///
  /// Lança exceções de domínio equivalentes às do caminho composto (ex.:
  /// componentes inexistentes/desativados, estoque insuficiente) — o caso de
  /// uso traduz para a UI.
  Future<void> process(ProductionOrder order);
}
