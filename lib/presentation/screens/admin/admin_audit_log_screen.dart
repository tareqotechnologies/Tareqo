import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/audit_entry.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/admin_providers.dart';
import '../../widgets/admin_thin_bridge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/list_skeleton.dart';

/// Registro de auditoria — visual minimalista com detalhes claros.
class AdminAuditLogScreen extends ConsumerStatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  ConsumerState<AdminAuditLogScreen> createState() =>
      _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends ConsumerState<AdminAuditLogScreen> {
  int _selectedFilter = 0;
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
      backgroundColor: theme.colorScheme.surface,
      body: auditLogAsync.when(
        loading: () => const ListSkeleton(items: 8),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(auditLogProvider.notifier).refresh(),
        ),
        data: (entries) {
          final filtered = _filterEntries(entries);
          final grouped = _groupByDate(filtered, l10n);
          final stats = _computeStats(entries);

          return RefreshIndicator(
            onRefresh: () => ref.read(auditLogProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Compact Stats Strip ──
                SliverToBoxAdapter(
                  child: _CompactStats(stats: stats, l10n: l10n),
                ),

                // ── Search + Filters ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        _SearchField(
                          controller: _searchController,
                          hintText: l10n.adminAuditLogSearchHint,
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _FilterRow(
                          selected: _selectedFilter,
                          l10n: l10n,
                          onSelected: (i) =>
                              setState(() => _selectedFilter = i),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),

                // ── Entries ──
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.history_outlined,
                      title: _searchQuery.isNotEmpty || _selectedFilter > 0
                          ? l10n.adminAuditLogNoResults
                          : l10n.adminAuditLogEmpty,
                      subtitle: _searchQuery.isEmpty && _selectedFilter == 0
                          ? l10n.adminAuditLogEmptySubtitle
                          : null,
                    ),
                  )
                else
                  for (final group in grouped.entries) ...[
                    SliverToBoxAdapter(child: _DateHeader(label: group.key)),
                    SliverList.separated(
                      itemCount: group.value.length,
                      separatorBuilder: (_, _) => const Divider(
                        height: 1,
                        indent: 72,
                        endIndent: AppSpacing.lg,
                      ),
                      itemBuilder: (_, i) => _AuditTile(entry: group.value[i]),
                    ),
                  ],

                // ── Bottom padding ──
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<AuditEntry> _filterEntries(List<AuditEntry> entries) {
    var result = entries;

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

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (e) =>
                e.actionLabel.toLowerCase().contains(q) ||
                e.entityTypeLabel.toLowerCase().contains(q) ||
                (e.entityId?.toLowerCase().contains(q) ?? false),
          )
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
      final d = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );

      String key;
      if (!d.isBefore(today)) {
        key = l10n.adminAuditLogToday;
      } else if (!d.isBefore(yesterday)) {
        key = l10n.adminAuditLogYesterday;
      } else if (!d.isBefore(weekAgo)) {
        key = l10n.adminAuditLogThisWeek;
      } else {
        key = l10n.adminAuditLogOlder;
      }
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final ordered = <String, List<AuditEntry>>{};
    for (final key in [
      l10n.adminAuditLogToday,
      l10n.adminAuditLogYesterday,
      l10n.adminAuditLogThisWeek,
      l10n.adminAuditLogOlder,
    ]) {
      if (groups.containsKey(key)) ordered[key] = groups[key]!;
    }
    return ordered;
  }

  _AuditStats _computeStats(List<AuditEntry> entries) {
    final total = entries.length;
    final approved = entries
        .where((e) => e.detail?['status'] == 'approved')
        .length;
    final rejected = entries
        .where((e) => e.detail?['status'] == 'rejected')
        .length;
    final rate = total > 0 ? ((approved / total) * 100).round() : 0;
    return _AuditStats(
      total: total,
      approved: approved,
      rejected: rejected,
      rate: rate,
    );
  }
}

// ─── Stats ───────────────────────────────────────────────────────────────────

class _AuditStats {
  const _AuditStats({
    required this.total,
    required this.approved,
    required this.rejected,
    required this.rate,
  });

  final int total;
  final int approved;
  final int rejected;
  final int rate;
}

/// Stats compactas — pills inline sem card.
class _CompactStats extends StatelessWidget {
  const _CompactStats({required this.stats, required this.l10n});

  final _AuditStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          _Pill(
            count: stats.total,
            label: l10n.adminAuditLogAll,
            color: scheme.onSurface,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: stats.approved,
            label: l10n.adminAuditLogApproved,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs),
          _Pill(
            count: stats.rejected,
            label: l10n.adminAuditLogRejected,
            color: AppColors.statusError,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _rateColor(stats.rate).withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Text(
              '${stats.rate}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _rateColor(stats.rate),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _rateColor(int rate) {
    if (rate >= 70) return AppColors.success;
    if (rate >= 40) return AppColors.statusWarning;
    return AppColors.statusError;
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.count, required this.label, required this.color});

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Search + Filters ────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
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

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 0,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 0,
          ),
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
            borderSide: BorderSide(
              color: scheme.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
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
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = selected == i;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: active
                    ? scheme.primary
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              alignment: Alignment.center,
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Date Header ─────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxs,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Tile ────────────────────────────────────────────────────────────────────

/// Tile minimalista — linha com acento de cor, texto de ação, e tempo relativo.
class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = entry.detail?['status'] as String?;
    final accent = _accentColor(entry.action, status);

    return InkWell(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        child: Row(
          children: [
            // ── Color accent dot ──
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action + entity
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        TextSpan(text: entry.actionLabel),
                        TextSpan(
                          text: '  ${entry.entityTypeLabel}',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        if (entry.entityId != null)
                          TextSpan(
                            text: '  ${entry.entityId}',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 2),
                    _StatusDot(status: status, l10n: context.l10n),
                  ],
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // ── Relative time ──
            Text(
              _relativeTime(entry.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(String action, String? status) {
    if (status == 'approved') return AppColors.success;
    if (status == 'rejected') return AppColors.statusError;
    switch (action) {
      case 'tenant_decision':
        return AppColors.statusInfo;
      case 'plan_request_decision':
        return AppColors.statusWarning;
      case 'plan_change':
        return AppColors.statusPurple;
      default:
        // Neutro semântico (sem papel de cor): mantém cinza neutro.
        return Colors.grey;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(dt);
  }

  void _showDetail(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Thin: rotas modais não herdam o Theme local do shell.
      builder: (sheetContext) => adminThinIfNeeded(
        sheetContext,
        thinStyle: true,
        child: _AuditDetailSheet(entry: entry),
      ),
    );
  }
}

// ─── Status Dot ──────────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status, required this.l10n});

  final String status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.decisionStatusColor(status);
    final label = status.toUpperCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, letterSpacing: 0.5),
        ),
      ],
    );
  }
}

// ─── Detail Sheet ────────────────────────────────────────────────────────────

/// Bottom sheet minimalista com todos os detalhes da entrada.
class _AuditDetailSheet extends StatelessWidget {
  const _AuditDetailSheet({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = entry.detail?['status'] as String?;
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.7,
      expand: false,
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            // ── Handle ──
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──
            Text(
              entry.actionLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${entry.entityTypeLabel}  ${entry.entityId ?? '—'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            if (status != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _StatusDot(status: status, l10n: context.l10n),
            ],
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // ── Fields ──
            _DetailRow(label: context.l10n.commonId, value: '#${entry.id}'),
            _DetailRow(
              label: l10n.adminAuditLogDate,
              value: DateFormat.yMMMd().add_Hm().format(entry.createdAt),
            ),
            if (entry.actorUserId != null)
              _DetailRow(
                label: l10n.adminAuditLogActor,
                value: entry.actorUserId!,
              ),
            _DetailRow(
              label: l10n.adminAuditLogEntity,
              value: entry.entityTypeLabel,
            ),
            if (entry.entityId != null)
              _DetailRow(
                label: l10n.adminAuditLogAction,
                value: entry.entityId!,
              ),

            // ── Detail JSON ──
            if (entry.detail != null && entry.detail!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Detail',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...entry.detail!.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${e.value}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
