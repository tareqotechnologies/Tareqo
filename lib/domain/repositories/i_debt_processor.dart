import '../entities/debt.dart';

/// Processador **atômico** de operações de fiado (dívida + pendência
/// financeira vinculada em uma única transação do banco).
///
/// Implementado apenas quando a plataforma de persistência oferece
/// transação multi-tabela no servidor — hoje, o Supabase via RPC
/// (`register_debt` / `settle_debt`, `SECURITY DEFINER`). No SQLite/memória
/// o [AddDebtUseCase] e o [SettleDebtUseCase] usam o caminho composto (que
/// preserva a semântica deliberada: a dívida sobrevive a uma falha da
/// pendência na origem).
abstract interface class IDebtAtomicProcessor {
  /// Registra [debt] e sua pendência financeira atomicamente no servidor.
  Future<void> register(Debt debt);

  /// Quita a dívida [debtId] da loja [storeId] **atomicamente**: baixa da
  /// dívida + resolução da pendência vinculada (ou entrada direta no caixa
  /// para fiado antigo sem pendência) em uma única transação do banco
  /// (RPC `settle_debt`). Idempotente no servidor.
  Future<void> settle(String debtId, {required String storeId});
}
