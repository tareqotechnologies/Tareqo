import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';

/// Tela do registro de auditoria — exibe o histórico de ações
/// administrativas com filtros, agrupamento por data e resumo estatístico.
class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  int _selectedFilter = 0; // 0=All, 1=Tenants, 2=Plans, 3=Upgrades
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auditLogAsync = ref.watch(auditLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adminAuditLogTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
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
          final filtered = _filterEntries(entries);
          final grouped = _groupByDate(filtered, l10n);
          final stats = _computeStats(entries);

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(auditLogProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // ── Stats Summary ──
                _StatsSummary(stats: stats, l10n: l10n),
                const SizedBox(height: AppSpacing.lg),

                // ── Search Bar ──
                _SearchBar(
                  controller: _searchController,
                  hintText: l10n.adminAuditLogSearchHint,
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Filter Chips ──
                _FilterChips(
                  selected: _selectedFilter,
                  l10n: l10n,
                  onSelected: (i) => setState(() => _selectedFilter = i),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Grouped Entries ──
                if (filtered.isEmpty)
                  EmptyState(
                    icon: Icons.history_outlined,
                    title: _searchQuery.isNotEmpty || _selectedFilter > 0
                        ? l10n.adminAuditLogNoResults
                        : l10n.adminAuditLogEmpty,
                    subtitle: _searchQuery.isEmpty && _selectedFilter == 0
                        ? l10n.adminAuditLogEmptySubtitle
                        : null,
                  )
                else
                  for (final group in grouped.entries) ...[
                    _DateHeader(label: group.key),
                    const SizedBox(height: AppSpacing.xs),
                    for (final entry in group.value)
                      _AuditLogTile(entry: entry),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<AuditEntry> _filterEntries(List<AuditEntry> entries) {
    var result = entries;

    // Filter by action type
    if (_selectedFilter > 0) {
      final actionMap = {
        1: 'tenant_decision',
        2: 'plan_change',
        3: 'plan_request_decision',
      };
      final action = actionMap[_selectedFilter];
      if (action != null) {
        result = result.where((e) => e.action == action).toList();
      }
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              e.actionLabel.toLowerCase().contains(query) ||
              e.entityTypeLabel.toLowerCase().contains(query) ||
              (e.entityId?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return result;
  }

  Map<String, List<AuditEntry>> _groupByDate(
    List<AuditEntry> entries,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final groups = <String, List<AuditEntry>>{};
    for (final entry in entries) {
      final entryDate = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );

      String key;
      if (!entryDate.isBefore(today)) {
        key = l10n.adminAuditLogToday;
      } else if (!entryDate.isBefore(yesterday)) {
        key = l10n.adminAuditLogYesterday;
      } else if (!entryDate.isBefore(weekAgo)) {
        key = l10n.adminAuditLogThisWeek;
      } else {
        key = l10n.adminAuditLogOlder;
      }

      groups.putIfAbsent(key, () => []).add(entry);
    }

    // Reorder: today first, then yesterday, this week, older
    final ordered = <String, List<AuditEntry>>{};
    for (final key in [
      l10n.adminAuditLogToday,
      l10n.adminAuditLogYesterday,
      l10n.adminAuditLogThisWeek,
      l10n.adminAuditLogOlder,
    ]) {
      if (groups.containsKey(key)) {
        ordered[key] = groups[key]!;
      }
    }

    return ordered;
  }

  _AuditStats _computeStats(List<AuditEntry> entries) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final total = entries.length;
    final approved = entries
        .where((e) => e.detail?['status'] == 'approved')
        .length;
    final rejected = entries
        .where((e) => e.detail?['status'] == 'rejected')
        .length;
    final recent = entries
        .where((e) => e.createdAt.isAfter(sevenDaysAgo))
        .length;

    final approvalRate = total > 0 ? ((approved / total) * 100).round() : 0;

    return _AuditStats(
      total: total,
      approved: approved,
      rejected: rejected,
      recent: recent,
      approvalRate: approvalRate,
    );
  }
}

class _AuditStats {
  const _AuditStats({
    required this.total,
    required this.approved,
    required this.rejected,
    required this.recent,
    required this.approvalRate,
  });

  final int total;
  final int approved;
  final int rejected;
  final int recent;
  final int approvalRate;
}

/// Stats summary row — total actions, approved, rejected, approval rate.
class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats, required this.l10n});

  final _AuditStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.adminAuditLogTotalActions,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _StatItem(
                value: '${stats.total}',
                label: l10n.adminAuditLogAll,
                color: scheme.onSurface,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatItem(
                value: '${stats.approved}',
                label: l10n.adminAuditLogApproved,
                color: scheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              _StatItem(
                value: '${stats.rejected}',
                label: l10n.adminAuditLogRejected,
                color: scheme.error,
              ),
              const Spacer(),
              _ApprovalRateBadge(rate: stats.approvalRate, l10n: l10n),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ApprovalRateBadge extends StatelessWidget {
  const _ApprovalRateBadge({required this.rate, required this.l10n});

  final int rate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = rate >= 70
        ? Colors.green
        : rate >= 40
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$rate%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            l10n.adminDashboardApprovalRate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Search bar for filtering audit entries.
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Filter chips for action type selection.
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.l10n,
    required this.onSelected,
  });

  final int selected;
  final AppLocalizations l10n;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = [
      l10n.adminAuditLogAll,
      l10n.adminAuditLogTenants,
      l10n.adminAuditLogPlans,
      l10n.adminAuditLogUpgrades,
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final isSelected = selected == index;
          return FilterChip(
            label: Text(labels[index]),
            selected: isSelected,
            onSelected: (_) => onSelected(index),
            selectedColor: scheme.primaryContainer,
            checkmarkColor: scheme.primary,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            shape: const StadiumBorder(),
            side: BorderSide(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.3)
                  : scheme.outlineVariant,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

/// Date header for grouped entries.
class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
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

    final status = entry.detail?['status'] as String?;
    final actionColor = _actionColor(entry.action, status);

    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone da ação com cor do status
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              _actionIcon(entry.action),
              size: 20,
              color: actionColor,
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
                const SizedBox(height: 4),

                // Detalhe + status badge
                if (entry.detail != null)
                  _DetailSummary(entry: entry)
                else
                  const SizedBox.shrink(),
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

  Color _actionColor(String action, String? status) {
    if (status == 'approved') return Colors.green;
    if (status == 'rejected') return Colors.red;

    switch (action) {
      case 'tenant_decision':
        return const Color(0xFF3B82F6);
      case 'plan_request_decision':
        return const Color(0xFFF59E0B);
      case 'plan_change':
        return const Color(0xFF7C3AED);
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

    final status = detail['status'] as String?;
    if (status == null) return const SizedBox.shrink();

    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
