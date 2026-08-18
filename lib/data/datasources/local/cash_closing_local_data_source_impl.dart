import '../../../domain/entities/cash_closing.dart';
import 'cash_closing_local_data_source.dart';

/// Implementação em memória do [CashClosingLocalDataSource].
///
/// Simula a tabela de fechos com uma `List<CashClosing>`. [save] faz
/// UPSERT por `(store_id, day)` — refazer o fecho do mesmo dia atualiza o
/// registro existente (corrige a contagem física, sem duplicar). Inicia
/// vazia por padrão (testes dependem disso) — sem dados de demonstração.
final class CashClosingLocalDataSourceImpl
 implements CashClosingLocalDataSource {
 CashClosingLocalDataSourceImpl({List<CashClosing> seed = const []})
 : _closings = [...seed];

 final List<CashClosing> _closings;

 @override
 Future<CashClosing?> getByDay({
 required String storeId,
 required DateTime day,
 }) async {
 final start = DateTime(day.year, day.month, day.day);
 for (final closing in _closings) {
 if (closing.storeId == storeId && _sameDay(closing.day, start)) {
 return closing;
 }
 }
 return null;
 }

 @override
 Future<void> save(CashClosing closing) async {
 final index = _closings.indexWhere(
 (existing) =>
 existing.storeId == closing.storeId &&
 _sameDay(existing.day, closing.day),
 );
 if (index == -1) {
 _closings.add(closing);
 } else {
 _closings[index] = closing;
 }
 }

 @override
 Future<List<CashClosing>> getAll({required String storeId}) async {
 final closings = _closings
 .where((closing) => closing.storeId == storeId)
 .toList()
 ..sort((a, b) => b.day.compareTo(a.day));
 return List.unmodifiable(closings);
 }

 static bool _sameDay(DateTime a, DateTime b) =>
 a.year == b.year && a.month == b.month && a.day == b.day;
}
