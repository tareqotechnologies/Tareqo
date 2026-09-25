import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/invoice.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/tenant.dart';
import '../../controllers/admin_providers.dart';
import '../../controllers/invoice_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/error_view.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Painel do super admin — gestão de facturas de cobrança dos tenants.
///
/// Lista todas as facturas geradas automaticamente para renovação mensal
/// do plano. O admin pode visualizar, marcar como paga ou cancelar.
class AdminInvoicesScreen extends ConsumerStatefulWidget {
  const AdminInvoicesScreen({super.key});

  @override
  ConsumerState<AdminInvoicesScreen> createState() =>
      _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends ConsumerState<AdminInvoicesScreen> {
  bool _showPendingOnly = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingInvoicesProvider);
    final allAsync = ref.watch(allInvoicesProvider);
    final tenants = ref.watch(allTenantsProvider).value ?? const <Tenant>[];
    final plans = ref.watch(allPlansProvider).value ?? const <Plan>[];
    final l10n = context.l10n;

    final invoices = _showPendingOnly
        ? (pendingAsync.value ?? const <Invoice>[])
        : (allAsync.value ?? const <Invoice>[]);
    final filtered = _filterInvoices(invoices, tenants, plans);

    return AppPage(
      title: l10n.adminInvoicesTitle,
      useSafeArea: false,
      actions: [
        TextButton(
          onPressed: () => setState(() => _showPendingOnly = !_showPendingOnly),
          child: Text(_showPendingOnly ? l10n.adminAll : l10n.adminPendingOnly),
        ),
      ],
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hintText: l10n.adminInvoiceSearchHint,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _showPendingOnly
                ? _buildList(
                    context,
                    pendingAsync,
                    filtered,
                    tenants,
                    plans,
                    l10n.adminInvoicesEmptyPending,
                  )
                : _buildList(
                    context,
                    allAsync,
                    filtered,
                    tenants,
                    plans,
                    l10n.adminInvoicesEmpty,
                  ),
          ),
        ],
      ),
    );
  }

  List<Invoice> _filterInvoices(
    List<Invoice> invoices,
    List<Tenant> tenants,
    List<Plan> plans,
  ) {
    if (_searchQuery.isEmpty) return invoices;
    final query = _searchQuery.toLowerCase();
    return invoices.where((inv) {
      final tenant = tenants.where((t) => t.id == inv.tenantId).firstOrNull;
      if (tenant != null && tenant.businessName.toLowerCase().contains(query)) {
        return true;
      }
      if (inv.period.toLowerCase().contains(query)) return true;
      if (inv.id.toLowerCase().contains(query)) return true;
      final plan = plans.where((p) => p.id == inv.planId).firstOrNull;
      if (plan != null && plan.name.toLowerCase().contains(query)) return true;
      return false;
    }).toList();
  }

  Widget _buildList(
    BuildContext context,
    AsyncValue<List<Invoice>> asyncValue,
    List<Invoice> filtered,
    List<Tenant> tenants,
    List<Plan> plans,
    String emptyMessage,
  ) {
    return asyncValue.when(
      loading: () => const ListSkeleton(items: 5),
      error: (error, _) => ErrorView(
        message: context.l10n.adminInvoicesLoadError,
        details: error.toString(),
        onRetry: () {
          ref.invalidate(pendingInvoicesProvider);
          ref.invalidate(allInvoicesProvider);
        },
      ),
      data: (_) {
        if (filtered.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: _searchQuery.isNotEmpty
                ? context.l10n.commonNoResults
                : emptyMessage,
            subtitle: _searchQuery.isNotEmpty
                ? context.l10n.commonNoResultsHint
                : null,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(pendingInvoicesProvider.notifier).refresh();
            await ref.read(allInvoicesProvider.notifier).refresh();
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final invoice = filtered[index];
              final tenant = tenants
                  .where((t) => t.id == invoice.tenantId)
                  .firstOrNull;
              final plan = plans
                  .where((p) => p.id == invoice.planId)
                  .firstOrNull;
              return _InvoiceCard(
                invoice: invoice,
                tenantName: tenant?.businessName ?? invoice.tenantId,
                planName: plan?.name ?? invoice.planId,
                onMarkAsPaid: () => _markAsPaid(invoice),
                onCancel: () => _cancel(invoice),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _markAsPaid(Invoice invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(markInvoiceAsPaidUseCaseProvider).call(invoice.id);
      if (!mounted) return;
      await ref.read(pendingInvoicesProvider.notifier).refresh();
      await ref.read(allInvoicesProvider.notifier).refresh();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminInvoiceMarkedPaid)),
      );
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao marcar factura como paga',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminInvoiceMarkPaidError)),
      );
    }
  }

  Future<void> _cancel(Invoice invoice) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final confirmed = await _confirmCancel(invoice);
    if (confirmed != true) return;
    try {
      await ref.read(cancelInvoiceUseCaseProvider).call(invoice.id);
      if (!mounted) return;
      await ref.read(pendingInvoicesProvider.notifier).refresh();
      await ref.read(allInvoicesProvider.notifier).refresh();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminInvoiceCancelled)),
      );
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao cancelar factura',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.adminInvoiceCancelError)),
      );
    }
  }

  Future<bool?> _confirmCancel(Invoice invoice) {
    final l10n = context.l10n;
    return showConfirmDialog(
      context,
      title: l10n.adminInvoiceCancelTitle,
      message: l10n.adminInvoiceCancelConfirm(invoice.period),
      confirmLabel: l10n.adminInvoiceCancelConfirmButton,
      // Thin: o dialog é rota modal — não herda o Theme do shell.
      thinStyle: true,
    );
  }

  ThemeData get theme => Theme.of(context);
}

/// Card de factura no painel admin.
class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.tenantName,
    required this.planName,
    this.onMarkAsPaid,
    this.onCancel,
  });

  final Invoice invoice;
  final String tenantName;
  final String planName;
  final VoidCallback? onMarkAsPaid;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final dateFormat = DateFormat.yMMMd();

    final (statusColor, statusLabel) = switch (invoice.status) {
      InvoiceStatus.pending => (scheme.tertiary, l10n.invoiceStatusPending),
      InvoiceStatus.paid => (scheme.primary, l10n.invoiceStatusPaid),
      InvoiceStatus.expired => (scheme.error, l10n.invoiceStatusExpired),
      InvoiceStatus.cancelled => (scheme.outline, l10n.invoiceStatusCancelled),
    };

    final amount = (invoice.amountCents / 100).toStringAsFixed(2);

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      borderColor: statusColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '${invoice.period} · $planName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: AppSpacing.xs,
            children: [
              _InfoPill(
                icon: Icons.attach_money,
                label: '${l10n.adminInvoiceAmount} $amount',
              ),
              _InfoPill(
                icon: Icons.calendar_today_outlined,
                label:
                    '${l10n.adminInvoiceDue} ${dateFormat.format(invoice.dueDate)}',
              ),
              if (invoice.paidAt != null)
                _InfoPill(
                  icon: Icons.check_circle_outline,
                  label:
                      '${l10n.adminInvoicePaidAt} ${dateFormat.format(invoice.paidAt!)}',
                  color: scheme.primary,
                ),
            ],
          ),
          if (invoice.status == InvoiceStatus.pending) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 160,
                  child: AppButton.primary(
                    onPressed: onMarkAsPaid,
                    icon: const Icon(Icons.check, size: 16),
                    label: l10n.adminInvoiceMarkPaid,
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: AppButton.secondary(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 16),
                    label: l10n.adminInvoiceCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pill de informação (ícone + texto).
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: effectiveColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: effectiveColor),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
