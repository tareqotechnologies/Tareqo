import '../entities/employee_management.dart';
import '../entities/sale.dart';
import '../entities/store_employee.dart';

/// Calcula o resumo de comissões de um mês a partir de dados REAIS.
///
/// Função pura (sem IO): recebe o roster da loja, as vendas reais e as
/// taxas cadastradas e devolve, por funcionário: vendas ativas no mês ×
/// taxa (pontos base) = comissão. Nunca inventa valores — venda sem
/// `userId` (legada) ou sem taxa não gera comissão (zero honesto).
///
/// No Supabase o app usa a RPC `get_employee_commission_summary`
/// (agregação server-side com a MESMA semântica); esta função é o
/// caminho LOCAL/offline e a referência de teste.
List<EmployeeCommissionSummaryEntry> calculateEmployeeCommissions({
  required List<StoreEmployee> roster,
  required List<Sale> sales,
  required Map<String, int> rateBpsByUserId,
  required String storeId,
  required String month,
}) {
  final entries = <EmployeeCommissionSummaryEntry>[];
  for (final employee in roster.where((e) => e.storeId == storeId)) {
    final salesCents = sales
        .where(
          (sale) =>
              sale.storeId == storeId &&
              sale.userId == employee.userId &&
              sale.status == SaleStatus.active &&
              _monthOf(sale.dateTime) == month,
        )
        .fold<int>(0, (sum, sale) => sum + sale.totalAmountCents);
    final rateBps = rateBpsByUserId[employee.userId] ?? 0;
    entries.add(
      EmployeeCommissionSummaryEntry(
        userId: employee.userId,
        fullName: employee.fullName,
        salesCents: salesCents,
        rateBps: rateBps,
        commissionCents: salesCents * rateBps ~/ 10000,
      ),
    );
  }
  entries.sort((a, b) => b.commissionCents.compareTo(a.commissionCents));
  return List.unmodifiable(entries);
}

/// Formata um [DateTime] como `YYYY-MM` (mesmo contrato do banco).
String employeeMonthOf(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}';

String _monthOf(DateTime date) => employeeMonthOf(date);