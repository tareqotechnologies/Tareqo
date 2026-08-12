import '../../domain/entities/cash_closing.dart';
import '../../domain/repositories/i_cash_closing_summary_repository.dart';
import '../../domain/usecases/get_cash_closing_summary_use_case.dart';
import '../datasources/remote/supabase_datasource_helpers.dart';

/// Agregação da PRÉVIA do fecho de caixa no SERVIDOR via RPC
/// `get_cash_closing_summary` (SECURITY DEFINER com guarda `is_my_store`) —
/// UMA chamada em vez de listar o histórico inteiro de vendas e somar no
/// cliente (escala H2, mesmo padrão de `get_cash_flow`/`get_sales_report`).
///
/// Valores em CENTAVOS inteiros (W4): a RPC devolve BIGINT; a abertura por
/// forma chega como JSONB (`method.name` → centavos).
final class SupabaseCashClosingSummaryRepository
    implements ICashClosingSummaryRepository {
  /// [rpc] injetável para testes — mesmo contrato dos datasources remotos
  /// (`Future<dynamic> Function(String fn, Map<String, dynamic> params)`),
  /// permitindo o teste de CONTRATO da RPC `get_cash_closing_summary` sem
  /// inicializar o cliente real. `null` (padrão) → cliente global.
  const SupabaseCashClosingSummaryRepository({
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

  @override
  Future<CashClosingSummary> fetchSummary({
    required String storeId,
    required DateTime day,
  }) async {
    _requireSessionOrTest(); // Falha cedo (cliente) se não houver sessão.
    final data = await _rpc(
      'get_cash_closing_summary',
      {
        'p_store_id': storeId,
        // Início do dia LOCAL convertido a UTC (mesma semântica da RPC
        // close_cash_register — a janela é [p_day, p_day + 1 dia)).
        'p_day': DateTime(day.year, day.month, day.day)
            .toUtc()
            .toIso8601String(),
      },
    );

    // PostgREST devolve o JSONB da RPC (objeto único). Aceita também o
    // formato lista (defensivo) caso o schema mude para RETURNS TABLE.
    final map = data is List && data.isNotEmpty
        ? data.first as Map<String, dynamic>
        : data as Map<String, dynamic>;

    return CashClosingSummary(
      day: DateTime.parse(map['day'] as String).toLocal(),
      totalSalesCents: (map['total_sales_cents'] as num).toInt(),
      expectedCashCents: (map['expected_cash_cents'] as num).toInt(),
      salesByMethodCents: mapSalesByMethodCents(map['sales_by_method_cents']),
      existingClosing: map['existing_closing'] == null
          ? null
          : _mapExistingClosing(map['existing_closing'] as Map<String, dynamic>),
    );
  }

  CashClosing _mapExistingClosing(Map<String, dynamic> row) => CashClosing(
    id: row['id'] as String,
    storeId: '', // não usado na prévia; o summary já escopa pela loja
    day: DateTime.parse(row['closing_date'] as String).toLocal(),
    totalSalesCents: (row['total_sales'] as num).toInt(),
    expectedCashCents: (row['expected_cash'] as num).toInt(),
    countedCashCents: (row['counted_cash'] as num).toInt(),
    salesByMethodCents: mapSalesByMethodCents(row['sales_by_method']),
    closedAt: DateTime.parse(row['closed_at'] as String).toLocal(),
  );
}
