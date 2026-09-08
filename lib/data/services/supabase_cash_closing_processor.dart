import '../../domain/entities/cash_closing.dart';
import '../../domain/repositories/i_cash_closing_processor.dart';
import '../datasources/remote/supabase_cash_closing_data_source.dart';

/// [ICashClosingProcessor] sobre o Supabase: delega à RPC
/// `close_cash_register`, que calcula NO SERVIDOR o esperado na gaveta
/// (Σ vendas ativas em dinheiro do dia) + o total, valida a guarda
/// gerencial `is_manager_of_store` e faz o UPSERT em UMA transação (ver
/// `supabase/schema.sql`) — o servidor é a autoridade, mesmo padrão dos
/// demais RPCs do dinheiro.
final class SupabaseCashClosingProcessor implements ICashClosingProcessor {
  const SupabaseCashClosingProcessor(this._dataSource);

  final CashClosingSupabaseDataSourceImpl _dataSource;

  @override
  Future<CashClosing> close({
    required String storeId,
    required DateTime day,
    required int countedCashCents,
  }) => _dataSource.closeCashRegister(
    storeId: storeId,
    day: day,
    countedCashCents: countedCashCents,
  );
}
