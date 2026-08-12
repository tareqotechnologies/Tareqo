import 'dart:convert';

import '../../../domain/entities/cash_closing.dart';
import '../local/cash_closing_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [CashClosingLocalDataSource] sobre o Supabase.
///
/// Leituras via REST (RLS isola por loja); o REGISTRO do fecho vai pela RPC
/// `close_cash_register` — o servidor calcula o esperado/total do dia e faz
/// o UPSERT em UMA transação, com a guarda gerencial `is_manager_of_store`.
/// A RPC devolve o fecho registrado (JSONB), que é mapeado de volta.
final class CashClosingSupabaseDataSourceImpl
    implements CashClosingLocalDataSource {
  /// [rpc] injetável para testes — mesmo contrato dos demais datasources
  /// remotos (`Future<dynamic> Function(String fn, Map<String, dynamic> params)`),
  /// permitindo o teste de CONTRATO da RPC `close_cash_register`
  /// sem inicializar o cliente real. `null` (padrão) → cliente global
  /// ([supabaseClient]).
  const CashClosingSupabaseDataSourceImpl({
    Future<dynamic> Function(String fn, Map<String, dynamic> params)? rpc,
  }) : _rpcOverride = rpc;

  final Future<dynamic> Function(String fn, Map<String, dynamic> params)?
  _rpcOverride;

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) =>
      _rpcOverride != null
          ? _rpcOverride(fn, params)
          : supabaseClient.rpc(fn, params: params);

  /// Em modo de teste (rpc injetado), o guard de sessão é ignorado — o
  /// teste controla o contrato. Em produção, falha cedo sem sessão.
  void _requireSessionOrTest() {
    if (_rpcOverride == null) requireCurrentUserId();
  }

  static const _table = 'cash_closings';

  /// Executa a RPC `close_cash_register` (fecho atômico server-side).
  ///
  /// A RPC recebe a contagem física e calcula NO SERVIDOR o esperado
  /// (Σ vendas ativas em dinheiro do dia) e o total — o cliente nunca
  /// envia valores calculados. Retorna o fecho persistido.
  Future<CashClosing> closeCashRegister({
    required String storeId,
    required DateTime day,
    required int countedCashCents,
  }) async {
    _requireSessionOrTest(); // Falha cedo (cliente) se não houver sessão.
    final data = await _rpc(
      'close_cash_register',
      {
        'p_store_id': storeId,
        'p_day': DateTime(day.year, day.month, day.day)
            .toUtc()
            .toIso8601String(),
        'p_counted_cash_cents': countedCashCents,
      },
    );

    // PostgREST devolve o JSONB da RPC (objeto único). Aceita também o
    // formato lista (defensivo) caso o schema mude para RETURNS TABLE.
    final map = data is List && data.isNotEmpty
        ? data.first as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return _map(map);
  }

  @override
  Future<CashClosing?> getByDay({
    required String storeId,
    required DateTime day,
  }) async {
    final rows = await supabaseClient
        .from(_table)
        .select('*')
        .eq('store_id', storeId)
        .eq(
          'closing_date',
          DateTime(day.year, day.month, day.day).toUtc().toIso8601String(),
        );
    if (rows.isEmpty) return null;
    return _map(rows.first);
  }

  @override
  Future<void> save(CashClosing closing) async {
    // ⚠️ Fallback REST (não usado pelo app no modo SaaS — o fecho vai pela
    // RPC close_cash_register, que persiste no servidor). Melhor esforço
    // para o caminho composto.
    await supabaseClient.from(_table).upsert({
      'id': closing.id,
      'user_id': requireCurrentUserId(),
      'store_id': closing.storeId,
      'closing_date': DateTime(
        closing.day.year,
        closing.day.month,
        closing.day.day,
      )
          .toUtc()
          .toIso8601String(),
      'total_sales': closing.totalSalesCents,
      'expected_cash': closing.expectedCashCents,
      'counted_cash': closing.countedCashCents,
      'sales_by_method': jsonEncode(closing.salesByMethodCents),
      'closed_at': closing.closedAt.toUtc().toIso8601String(),
    });
  }

  @override
  Future<List<CashClosing>> getAll({required String storeId}) async {
    final rows = await supabaseClient
        .from(_table)
        .select('*')
        .eq('store_id', storeId)
        .order('closing_date', ascending: false);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  CashClosing _map(Map<String, dynamic> row) => CashClosing(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    day: DateTime.parse(row['closing_date'] as String).toLocal(),
    totalSalesCents: (row['total_sales'] as num).toInt(),
    expectedCashCents: (row['expected_cash'] as num).toInt(),
    countedCashCents: (row['counted_cash'] as num).toInt(),
    salesByMethodCents: mapSalesByMethodCents(row['sales_by_method']),
    closedAt: DateTime.parse(row['closed_at'] as String).toLocal(),
  );
}
