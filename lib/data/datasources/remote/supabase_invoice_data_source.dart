import '../../../domain/entities/invoice.dart';
import '../local/invoice_local_data_source.dart';
import 'supabase_datasource_helpers.dart';

/// Implementação remota do [InvoiceLocalDataSource] sobre o Supabase.
///
/// Facturas são geradas pelo app (GenerateInvoiceUseCase) e persistidas
/// na tabela `invoices` com RLS restrito ao super admin.
final class InvoiceSupabaseDataSourceImpl implements InvoiceLocalDataSource {
  const InvoiceSupabaseDataSourceImpl();

  static const _table = 'invoices';
  static const _columns =
      'id, number, tenant_id, plan_id, amount_cents, status, '
      'due_date, period, paid_at, notes, created_at';

  @override
  Future<Invoice> create(Invoice invoice) async {
    final rows = await supabaseClient
        .from(_table)
        .insert({
          'id': invoice.id,
          'tenant_id': invoice.tenantId,
          'plan_id': invoice.planId,
          'amount_cents': invoice.amountCents,
          'status': invoice.status.name,
          'due_date': invoice.dueDate.toUtc().toIso8601String(),
          'period': invoice.period,
          'notes': invoice.notes,
        })
        .select(_columns);
    return _map(rows.first);
  }

  @override
  Future<List<Invoice>> getByTenant(String tenantId) async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<List<Invoice>> getPending() async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .eq('status', InvoiceStatus.pending.name)
        .order('created_at', ascending: true)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<List<Invoice>> getAll() async {
    final rows = await supabaseClient
        .from(_table)
        .select(_columns)
        .order('created_at', ascending: true)
        .limit(SupabaseQueryLimits.pageSize);
    return List.unmodifiable([for (final row in rows) _map(row)]);
  }

  @override
  Future<void> markAsPaid(String invoiceId) async {
    final rows = await supabaseClient
        .from(_table)
        .update({
          'status': InvoiceStatus.paid.name,
          'paid_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', invoiceId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Factura $invoiceId não encontrada.');
    }
  }

  @override
  Future<void> cancel(String invoiceId) async {
    final rows = await supabaseClient
        .from(_table)
        .update({'status': InvoiceStatus.cancelled.name})
        .eq('id', invoiceId)
        .select('id');
    if (rows.isEmpty) {
      throw StateError('Factura $invoiceId não encontrada.');
    }
  }

  @override
  Future<bool> hasPendingForPeriod(String tenantId, String period) async {
    final rows = await supabaseClient
        .from(_table)
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('period', period)
        .eq('status', InvoiceStatus.pending.name)
        .limit(1);
    return rows.isNotEmpty;
  }

  Invoice _map(Map<String, dynamic> row) => Invoice(
    id: row['id'] as String,
    number: row['number'] as int? ?? 0,
    tenantId: row['tenant_id'] as String,
    planId: row['plan_id'] as String,
    amountCents: row['amount_cents'] as int,
    status: InvoiceStatus.values.byName(row['status'] as String),
    dueDate: DateTime.parse(row['due_date'] as String).toLocal(),
    period: (row['period'] as String?) ?? '',
    paidAt: row['paid_at'] == null
        ? null
        : DateTime.parse(row['paid_at'] as String).toLocal(),
    notes: row['notes'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}
