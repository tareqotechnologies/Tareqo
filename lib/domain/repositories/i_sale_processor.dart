import '../entities/sale.dart';

/// Processador **atômico** de vendas (venda + itens + baixa de estoque +
/// entrada no caixa em uma única transação do banco).
///
/// Implementado apenas quando a plataforma de persistência oferece
/// transação multi-tabela no servidor — hoje, o Supabase via RPC
/// (`process_sale`, `SECURITY DEFINER`). No SQLite/memória o
/// [ProcessSaleUseCase] usa o caminho composto com [IUnitOfWork] e este
/// contrato fica sem implementação registrada.
abstract interface class ISaleAtomicProcessor {
  /// Processa [sale] atomicamente no servidor.
  ///
  /// Lança exceções de domínio equivalentes às do caminho composto
  /// (ex.: estoque insuficiente) — o caso de uso traduz para a UI.
  Future<void> process(Sale sale);
}
