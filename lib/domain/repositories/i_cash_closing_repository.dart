import '../entities/cash_closing.dart';

/// Contrato de persistência dos fechos de caixa diários (Z-report).
///
/// Um fecho por loja por dia: a unicidade `(store_id, day)` é garantida
/// pelo banco (índice único no SQLite; `UNIQUE` no Supabase). [save] é um
/// UPSERT — refazer o fecho do mesmo dia atualiza o registro (corrigindo
/// a contagem física), nunca duplica.
abstract interface class ICashClosingRepository {
  /// Retorna o fecho do dia [day] da loja [storeId], ou `null` se o dia
  /// ainda não foi fechado.
  Future<CashClosing?> getByDay({
    required String storeId,
    required DateTime day,
  });

  /// Registra (ou atualiza) o fecho do dia — UPSERT por `(store_id, day)`.
  Future<void> save(CashClosing closing);

  /// Histórico de fechos da loja [storeId] (mais recentes primeiro).
  Future<List<CashClosing>> getAll({required String storeId});
}
