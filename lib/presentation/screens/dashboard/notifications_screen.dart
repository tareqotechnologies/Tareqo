import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/invoice_notification.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/notification_providers.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/status_chip.dart';

/// Tela de notificações do tenant — lista as notificações de facturas
/// geradas automaticamente (factura criada, para vencer, expirada, paga).
///
/// O dono do tenant pode ver, marcar como lida e marcar todas como lidas.
/// Acesso apenas para o dono do tenant (não funcionários).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(tenantNotificationsProvider);

    final allNotifications = notificationsAsync.value ?? const <InvoiceNotification>[];
    final filtered = _showUnreadOnly
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;
    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.notificationTitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(l10n.notificationMarkAllRead),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filtro: Todas / Não lidas
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: l10n.notificationTabAll,
                  selected: !_showUnreadOnly,
                  onTap: () => setState(() => _showUnreadOnly = false),
                ),
                const SizedBox(width: AppSpacing.xs),
                _FilterChip(
                  label: l10n.notificationTabUnread,
                  selected: _showUnreadOnly,
                  onTap: () => setState(() => _showUnreadOnly = true),
                  badgeCount: unreadCount,
                ),
              ],
            ),
          ),
          // Lista de notificações
          Expanded(
            child: notificationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: l10n.adminInvoicesLoadError,
                details: error.toString(),
                onRetry: () => ref.invalidate(tenantNotificationsProvider),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.notifications_none_outlined,
                    title: _showUnreadOnly
                        ? l10n.notificationTabUnread
                        : l10n.notificationNoNotifications,
                    subtitle: l10n.notificationNoNotificationsHint,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(tenantNotificationsProvider.notifier)
                        .refresh();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      return _NotificationCard(
                        notification: notification,
                        onMarkAsRead: notification.isRead
                            ? null
                            : () => _markAsRead(notification),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(InvoiceNotification notification) async {
    try {
      await ref
          .read(markNotificationAsReadUseCaseProvider)
          .call(notification.id);
      if (!mounted) return;
      await ref.read(tenantNotificationsProvider.notifier).refresh();
    } catch (_) {
      // Silenciar erros — notificação é best-effort
    }
  }

  Future<void> _markAllAsRead() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final tenantAsync = ref.read(myTenantProvider(user.id));
    final tenant = tenantAsync.value;
    if (tenant == null) return;
    try {
      await ref.read(markAllNotificationsAsReadUseCaseProvider).call(tenant.id);
      if (!mounted) return;
      await ref.read(tenantNotificationsProvider.notifier).refresh();
    } catch (_) {
      // Silenciar erros — notificação é best-effort
    }
  }
}

/// Card de notificação individual.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    this.onMarkAsRead,
  });

  final InvoiceNotification notification;
  final VoidCallback? onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final (icon, color) = _iconAndColor(notification.type);
    final timeLabel = _formatTime(notification.createdAt, l10n);

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      borderColor: notification.isRead
          ? scheme.outlineVariant.withValues(alpha: 0.3)
          : color.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone da notificação
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: notification.isRead
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 12,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    StatusChip(
                      label: _typeLabel(notification.type, l10n),
                      color: color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botão marcar como lida
          if (onMarkAsRead != null)
            IconButton(
              onPressed: onMarkAsRead,
              icon: Icon(
                Icons.mark_email_read_outlined,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: l10n.notificationMarkAsRead,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
                maxWidth: 32,
                maxHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  static (IconData, Color) _iconAndColor(InvoiceNotificationType type) {
    return switch (type) {
      InvoiceNotificationType.invoiceGenerated => (
        Icons.receipt_long_outlined,
        const Color(0xFF7C3AED), // violet
      ),
      InvoiceNotificationType.invoiceDueSoon => (
        Icons.schedule_outlined,
        const Color(0xFFF59E0B), // amber
      ),
      InvoiceNotificationType.invoiceExpired => (
        Icons.error_outline,
        const Color(0xFFEF4444), // red
      ),
      InvoiceNotificationType.invoicePaid => (
        Icons.check_circle_outline,
        const Color(0xFF10B981), // green
      ),
    };
  }

  static String _typeLabel(
    InvoiceNotificationType type,
    AppLocalizations l10n,
  ) {
    return switch (type) {
      InvoiceNotificationType.invoiceGenerated =>
        l10n.notificationInvoiceGenerated,
      InvoiceNotificationType.invoiceDueSoon =>
        l10n.notificationInvoiceDueSoon,
      InvoiceNotificationType.invoiceExpired =>
        l10n.notificationInvoiceExpired,
      InvoiceNotificationType.invoicePaid =>
        l10n.notificationInvoicePaid,
    };
  }

  static String _formatTime(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.notificationJustNow;
    if (diff.inHours < 1) return l10n.dashboardActivityMinutesAgo(diff.inMinutes);
    if (diff.inDays == 0) return DateFormat.Hm().format(date);
    if (diff.inDays == 1) return l10n.notificationYesterday;
    if (diff.inDays < 7) return l10n.notificationSinceDaysAgo(diff.inDays);
    return DateFormat.yMMMd().format(date);
  }
}

/// Chip de filtro minimalista (Todas / Não lidas).
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.3)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: scheme.tertiary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$badgeCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
