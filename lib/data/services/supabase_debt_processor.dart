import '../../domain/entities/debt.dart';
import '../../domain/repositories/i_debt_processor.dart';
import '../datasources/remote/supabase_debt_data_source.dart';

/// [IDebtAtomicProcessor] sobre o Supabase: delega às RPCs `register_debt`
/// e `settle_debt`, que executam cada operação em uma única transação no
/// banco (ver `supabase/schema.sql`).
final class SupabaseDebtProcessor implements IDebtAtomicProcessor {
  const SupabaseDebtProcessor(this._dataSource);

  final DebtSupabaseDataSourceImpl _dataSource;

  @override
  Future<void> register(Debt debt) => _dataSource.registerDebt(debt);

  @override
  Future<void> settle(String debtId, {required String storeId}) =>
      _dataSource.settleDebt(debtId, storeId: storeId);
}
