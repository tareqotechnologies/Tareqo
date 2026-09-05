import 'dart:convert';

import '../../../domain/entities/quotation.dart';
import '../local/quotation_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [QuotationLocalDataSource] sobre o Supabase.
///
/// Tabela `quotations` (migração 20260905): documento por loja com RLS por
/// `is_my_store`. O número sequencial da loja é atribuído por TRIGGER no
/// servidor (advisory lock por loja) — o valor enviado (0) é substituído e
/// a linha devolvida traz o número real. Transições de estado (enviada /
/// aceite / rejeitada) gravam o payload atualizado via UPDATE.
final class QuotationSupabaseDataSourceImpl implements QuotationLocalDataSource {
  const QuotationSupabaseDataSourceImpl();

  static const _table = 'quotations';
  static const _columns =
      'id, store_id, quotation_number, payload, created_at';

  @override
  Future<List<Quotation>> getAll({required String storeId}) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<Quotation> add(Quotation quotation) async {
    final rows = await supabaseClient
        .from(_table)
        .insert({
          'store_id': quotation.storeId,
          'payload': jsonEncode(quotation.toJson()),
        })
        .select(_columns);
    return _map(rows.first);
  }

  @override
  Future<Quotation> update(Quotation quotation) async {
    final rows = await supabaseClient
        .from(_table)
        .update({'payload': jsonEncode(quotation.toJson())})
        .eq('id', quotation.id)
        .select(_columns);
    return _map(rows.first);
  }

  Quotation _map(Map<String, dynamic> row) {
    // O JSONB chega do PostgREST decodificado (Map) OU como String JSON —
    // aceita os dois formatos (mesmo padrão defensivo de mapSalesByMethodCents).
    final raw = row['payload'];
    final payload = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : Map<String, dynamic>.from(raw as Map);
    final quotation = Quotation.fromJson(payload);
    return quotation.copyWith(
      storeId: row['store_id'] as String,
      number: (row['quotation_number'] as num).toInt(),
    );
  }
}