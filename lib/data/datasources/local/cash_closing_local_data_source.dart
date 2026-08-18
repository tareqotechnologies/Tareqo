import '../../../domain/entities/cash_closing.dart';

/// Contrato de armazenamento local dos fechos de caixa diários.
///
/// Um fecho por loja por dia — a implementação garante a unicidade
/// `(store_id, day)`: [save] é um UPSERT (atualiza o registro existente do
/// mesmo dia, nunca duplica).
abstract interface class CashClosingLocalDataSource {
 /// Retorna o fecho do dia [day] da loja [storeId], ou `null`.
 Future<CashClosing?> getByDay({
 required String storeId,
 required DateTime day,
 });

 /// Registra (ou atualiza) o fecho do dia.
 Future<void> save(CashClosing closing);

 /// Histórico de fechos da loja [storeId] (mais recentes primeiro).
 Future<List<CashClosing>> getAll({required String storeId});
}
