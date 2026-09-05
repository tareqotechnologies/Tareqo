import '../entities/employee_management.dart';

/// Resumo de comissões CALCULADO no servidor (Supabase).
///
/// Espelha o padrão dos demais agregados H2/W5 (`get_cash_flow`,
/// `get_sales_report`): registrado APENAS no modo remoto — a RPC
/// `get_employee_commission_summary` agrega as vendas reais da loja
/// (`sales.user_id` = caixa, status 'active', mês) × taxa cadastrada.
/// No modo local/offline o provider usa [calculateEmployeeCommissions]
/// sobre as vendas reais (mesma semântica).
abstract interface class IEmployeeCommissionSummaryRepository {
  Future<List<EmployeeCommissionSummaryEntry>> getSummary({
    required String storeId,
    required String month,
  });
}