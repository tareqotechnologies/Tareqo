import '../../../domain/entities/quotation.dart';
import 'quotation_local_data_source.dart';

/// Implementação em memória do [QuotationLocalDataSource] (web/testes).
///
/// Dados não persistem entre sessões — apenas para o fluxo de dev sem
/// Supabase/SQLite (mesmo papel dos demais datasources em memória).
final class QuotationLocalDataSourceImpl implements QuotationLocalDataSource {
  QuotationLocalDataSourceImpl({List<Quotation> seed = const []})
    : _quotations = {for (final q in seed) q.id: q};

  final Map<String, Quotation> _quotations;

  @override
  Future<List<Quotation>> getAll({required String storeId}) async {
    final list = _quotations.values
        .where((q) => q.storeId == storeId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<Quotation> add(Quotation quotation) async {
    if (_quotations.containsKey(quotation.id)) {
      throw StateError('Cotação ${quotation.id} já existe.');
    }
    // Número SEQUENCIAL da loja (MAX+1) — o armazenamento é a autoridade,
    // mesma semântica do SQLite/Supabase (o número enviado é ignorado).
    var nextNumber = 0;
    for (final existing in _quotations.values) {
      if (existing.storeId == quotation.storeId &&
          existing.number > nextNumber) {
        nextNumber = existing.number;
      }
    }
    final persisted = quotation.copyWith(number: nextNumber + 1);
    _quotations[persisted.id] = persisted;
    return persisted;
  }

  @override
  Future<Quotation> update(Quotation quotation) async {
    final existing = _quotations[quotation.id];
    if (existing == null) {
      throw StateError('Cotação ${quotation.id} não existe.');
    }
    // Preserva o número sequencial da loja já atribuído na criação.
    _quotations[quotation.id] = quotation.copyWith(number: existing.number);
    return _quotations[quotation.id]!;
  }
}