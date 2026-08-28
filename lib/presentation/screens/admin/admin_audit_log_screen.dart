import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';

/// Tela do registro de auditoria — exibe o histórico de ações
/// administrativas (aprovação/rejeição de tenants, alterações de planos,
/// decisões de upgrade). Dados vindos da tabela `audit_log` via RPC
/// `get_audit_log` (exige `is_super_admin()`).
class AdminAuditLogScreen extends ConsumerWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auditLogAsync = ref.watch(auditLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminAuditLogTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: l10n.commonRetry,
            onPressed: () => ref.read(auditLogProvider.notifier).refresh(),
          ),
        ],
      ),
      body: auditLogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(auditLogProvider.notifier).refresh(),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.history_outlined,
              title: l10n.adminAuditLogEmpty,
              subtitle: l10n.adminAuditLogEmptySubtitle,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(auditLogProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _AuditLogTile(entry: entries[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Tile individual de uma entrada de auditoria — ícone + ação + entidade +
/// timestamp formatado.
class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();
    final timeFormat = DateFormat.Hm();

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone da ação
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _actionColor(entry.action).withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              _actionIcon(entry.action),
              size: 20,
              color: _actionColor(entry.action),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha principal: ação + entidade
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: entry.actionLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: ' · ${entry.entityTypeLabel}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      if (entry.entityId != null)
                        TextSpan(
                          text: ' (${entry.entityId})',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Detalhe resumido (se disponível)
                if (entry.detail != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _DetailSummary(entry: entry),
                ],
              ],
            ),
          ),

          // Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                timeFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'tenant_decision':
        return Colors.blue;
      case 'plan_request_decision':
        return Colors.orange;
      case 'plan_change':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'tenant_decision':
        return Icons.person_add_outlined;
      case 'plan_request_decision':
        return Icons.upgrade_outlined;
      case 'plan_change':
        return Icons.workspaces_outlined;
      default:
        return Icons.info_outline;
    }
  }
}

/// Resumo do campo `detail` JSONB — extrai o status novo para exibição.
class _DetailSummary extends StatelessWidget {
  const _DetailSummary({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final detail = entry.detail;
    if (detail == null) return const SizedBox.shrink();

    // Tenta extrair o status do payload.
    final status = detail['status'] as String?;
    if (status == null) return const SizedBox.shrink();

    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
