import 'dart:convert';

import '../../../domain/entities/custom_invoice.dart';
import '../local/custom_invoice_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [CustomInvoiceLocalDataSource] sobre o Supabase.
///
/// Tabela `custom_invoices` (migração 20260905): documento por loja com
/// RLS por `is_my_store`. O número sequencial da loja é atribuído por
/// TRIGGER no servidor (advisory lock por loja) — o valor enviado (0) é
/// substituído e a linha devolvida traz o número real.
final class CustomInvoiceSupabaseDataSourceImpl
    implements CustomInvoiceLocalDataSource {
  const CustomInvoiceSupabaseDataSourceImpl();

  static const _table = 'custom_invoices';
  static const _columns = 'id, store_id, invoice_number, payload, created_at';

  @override
  Future<List<CustomInvoice>> getAll({required String storeId}) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('store_id', storeId)
        .order('created_at', ascending: false)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<CustomInvoice> add(CustomInvoice invoice) async {
    final rows = await supabaseClient
        .from(_table)
        .insert({
          'id': invoice.id,
          'store_id': invoice.storeId,
          'payload': jsonEncode(invoice.toJson()),
        })
        .select(_columns);
    return _map(rows.first);
  }

  CustomInvoice _map(Map<String, dynamic> row) {
    // O JSONB chega do PostgREST decodificado (Map) OU como String JSON —
    // aceita os dois formatos (mesmo padrão defensivo de mapSalesByMethodCents).
    final raw = row['payload'];
    final payload = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : Map<String, dynamic>.from(raw as Map);
    final invoice = CustomInvoice.fromJson(payload);
    return invoice.copyWith(
      storeId: row['store_id'] as String,
      number: (row['invoice_number'] as num).toInt(),
    );
  }
}
