import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/invoice_notification.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/notification_providers.dart';
import '../../controllers/admin_message_providers.dart';
import '../../../domain/entities/admin_message.dart';
import '../../widgets/app_page.dart';
import '../../widgets/empty_state.dart';

/// Tela de notificações do tenant — lista as notificações de facturas
/// e mensagens do super admin com visual minimalista e detalhes em bottom sheet.
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
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(tenantNotificationsProvider);
    final adminMessagesAsync = ref.watch(tenantAdminMessagesProvider);

    final allNotifications =
        notificationsAsync.value ?? const <InvoiceNotification>[];
    final allAdminMessages = adminMessagesAsync.value ?? const <AdminMessage>[];
    final filteredNotifications = _showUnreadOnly
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;
    final filteredAdminMessages = _showUnreadOnly
        ? allAdminMessages.where((m) => !m.isRead).toList()
        : allAdminMessages;
    final unreadInvoiceCount = allNotifications.where((n) => !n.isRead).length;
    final unreadAdminCount = allAdminMessages.where((m) => !m.isRead).length;
    final unreadCount = unreadInvoiceCount + unreadAdminCount;
    final totalCount =
        filteredNotifications.length + filteredAdminMessages.length;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      backgroundColor: scheme.surface,
      title: l10n.notificationTitle,
      badge: unreadCount,
      useSafeArea: false,
      actions: [
        if (unreadCount > 0)
          TextButton(
            onPressed: _markAllAsRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.notificationMarkAllRead,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          // ── Filtros + contadores ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              0,
              horizontal,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                _Pill(
                  label: l10n.notificationTabAll,
                  selected: !_showUnreadOnly,
                  count: totalCount,
                  onTap: () => setState(() => _showUnreadOnly = false),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: l10n.notificationTabUnread,
                  selected: _showUnreadOnly,
                  count: unreadCount,
                  onTap: () => setState(() => _showUnreadOnly = true),
                  accent: true,
                ),
              ],
            ),
          ),

          // ── Lista ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(tenantNotificationsProvider.notifier).refresh();
                await ref.read(tenantAdminMessagesProvider.notifier).refresh();
              },
              child: totalCount == 0 && !notificationsAsync.isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.notifications_none_outlined,
                          title: _showUnreadOnly
                              ? l10n.notificationTabUnread
                              : l10n.notificationNoNotifications,
                          subtitle: l10n.notificationNoNotificationsHint,
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
                      itemCount: _buildItemList(
                        filteredAdminMessages,
                        filteredNotifications,
                        notificationsAsync.isLoading,
                      ).length,
                      itemBuilder: (context, index) {
                        final item = _buildItemList(
                          filteredAdminMessages,
                          filteredNotifications,
                          notificationsAsync.isLoading,
                        )[index];
                        return item;
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a flat list of widgets from admin messages + invoice notifications.
  List<Widget> _buildItemList(
    List<AdminMessage> adminMessages,
    List<InvoiceNotification> notifications,
    bool isLoading,
  ) {
    final items = <Widget>[];

    for (var i = 0; i < adminMessages.length; i++) {
      items.add(
        _NotificationTile.admin(
          message: adminMessages[i],
          l10n: context.l10n,
          showDivider: i < adminMessages.length - 1 || notifications.isNotEmpty,
          onTap: () => _showAdminMessageDetail(adminMessages[i]),
          onMarkAsRead: adminMessages[i].isRead
              ? null
              : () => _markAdminMessageAsRead(adminMessages[i]),
        ),
      );
    }

    for (var i = 0; i < notifications.length; i++) {
      items.add(
        _NotificationTile.invoice(
          notification: notifications[i],
          l10n: context.l10n,
          showDivider: i < notifications.length - 1,
          onTap: () => _showNotificationDetail(notifications[i]),
          onMarkAsRead: notifications[i].isRead
              ? null
              : () => _markAsRead(notifications[i]),
        ),
      );
    }

    if (isLoading && items.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return items;
  }

  // ── Detail bottom sheets ──

  void _showAdminMessageDetail(AdminMessage message) {
    if (!message.isRead) _markAdminMessageAsRead(message);
    _showDetailSheet(
      title: message.title,
      body: message.body,
      time: message.createdAt,
      typeLabel: _AdminMessageTypeLabel.label(message.type, context.l10n),
      typeColor: _AdminMessageTypeLabel.color(message.type),
      icon: _AdminMessageTypeLabel.icon(message.type),
    );
  }

  void _showNotificationDetail(InvoiceNotification notification) {
    if (!notification.isRead) _markAsRead(notification);
    _showDetailSheet(
      title: notification.title,
      body: notification.body,
      time: notification.createdAt,
      typeLabel: _InvoiceTypeLabel.label(notification.type, context.l10n),
      typeColor: _InvoiceTypeLabel.color(notification.type),
      icon: _InvoiceTypeLabel.icon(notification.type),
    );
  }

  void _showDetailSheet({
    required String title,
    required String body,
    required DateTime time,
    required String typeLabel,
    required Color typeColor,
    required IconData icon,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailBottomSheet(
        title: title,
        body: body,
        time: time,
        typeLabel: typeLabel,
        typeColor: typeColor,
        icon: icon,
      ),
    );
  }

  // ── Actions ──

  Future<void> _markAsRead(InvoiceNotification notification) async {
    try {
      await ref
          .read(markNotificationAsReadUseCaseProvider)
          .call(notification.id);
      if (!mounted) return;
      await ref.read(tenantNotificationsProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> _markAdminMessageAsRead(AdminMessage message) async {
    try {
      await ref.read(markAdminMessageAsReadUseCaseProvider).call(message.id);
      if (!mounted) return;
      await ref.read(tenantAdminMessagesProvider.notifier).refresh();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final tenantAsync = ref.read(myTenantProvider(user.id));
    final tenant = tenantAsync.value;
    if (tenant == null) return;
    try {
      await ref.read(markAllNotificationsAsReadUseCaseProvider).call(tenant.id);
      await ref.read(markAllAdminMessagesAsReadUseCaseProvider).call(tenant.id);
      if (!mounted) return;
      await ref.read(tenantNotificationsProvider.notifier).refresh();
      await ref.read(tenantAdminMessagesProvider.notifier).refresh();
    } catch (_) {}
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Tile minimalista — ícone à esquerda, conteúdo ao centro, ação à direita.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.typeLabel,
    required this.typeColor,
    required this.isRead,
    required this.onTap,
    this.onMarkAsRead,
    this.showDivider = true,
  });

  factory _NotificationTile.admin({
    required AdminMessage message,
    required AppLocalizations l10n,
    required VoidCallback? onTap,
    required VoidCallback? onMarkAsRead,
    bool showDivider = true,
  }) {
    final icon = _AdminMessageTypeLabel.icon(message.type);
    final color = _AdminMessageTypeLabel.color(message.type);
    return _NotificationTile(
      icon: icon,
      iconBg: color,
      iconFg: _deriveFg(color),
      title: message.title,
      subtitle: message.body,
      time: message.createdAt,
      typeLabel: _AdminMessageTypeLabel.label(message.type, l10n),
      typeColor: color,
      isRead: message.isRead,
      onTap: onTap,
      onMarkAsRead: onMarkAsRead,
      showDivider: showDivider,
    );
  }

  factory _NotificationTile.invoice({
    required InvoiceNotification notification,
    required AppLocalizations l10n,
    required VoidCallback? onTap,
    required VoidCallback? onMarkAsRead,
    bool showDivider = true,
  }) {
    final icon = _InvoiceTypeLabel.icon(notification.type);
    final color = _InvoiceTypeLabel.color(notification.type);
    return _NotificationTile(
      icon: icon,
      iconBg: color,
      iconFg: _deriveFg(color),
      title: notification.title,
      subtitle: notification.body,
      time: notification.createdAt,
      typeLabel: _InvoiceTypeLabel.iconLabel(notification.type, l10n),
      typeColor: color,
      isRead: notification.isRead,
      onTap: onTap,
      onMarkAsRead: onMarkAsRead,
      showDivider: showDivider,
    );
  }

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String subtitle;
  final DateTime time;
  final String typeLabel;
  final Color typeColor;
  final bool isRead;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ícone ──
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBg.withValues(alpha: isRead ? 0.08 : 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: iconFg),
                  ),
                  const SizedBox(width: 12),

                  // ── Conteúdo ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                  color: isRead
                                      ? scheme.onSurfaceVariant
                                      : scheme.onSurface,
                                  fontSize: 12,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              _formatTime(time, l10n),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                typeLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: typeColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (onMarkAsRead != null)
                              GestureDetector(
                                onTap: onMarkAsRead,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.done_all_outlined,
                                    size: 16,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            indent: 56,
          ),
      ],
    );
  }

  static Color _deriveFg(Color base) {
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness(0.55)
        .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
        .toColor();
  }

  static String _formatTime(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.notificationJustNow;
    if (diff.inHours < 1) {
      return l10n.dashboardActivityMinutesAgo(diff.inMinutes);
    }
    if (diff.inDays == 0) return DateFormat.Hm().format(date);
    if (diff.inDays == 1) return l10n.notificationYesterday;
    if (diff.inDays < 7) return l10n.notificationSinceDaysAgo(diff.inDays);
    return DateFormat('dd MMM', l10n.localeName).format(date);
  }
}

/// Bottom sheet de detalhes — visual minimalista com corpo scrollável.
class _DetailBottomSheet extends StatelessWidget {
  const _DetailBottomSheet({
    required this.title,
    required this.body,
    required this.time,
    required this.typeLabel,
    required this.typeColor,
    required this.icon,
  });

  final String title;
  final String body;
  final DateTime time;
  final String typeLabel;
  final Color typeColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      margin: EdgeInsets.only(top: topPadding + 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 22, color: typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              typeLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: typeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _DetailBottomSheet._formatTime(time, l10n),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: scheme.outlineVariant.withValues(alpha: 0.25),
            ),
          ),

          // ── Body ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Text(
                body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l10n.notificationJustNow;
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays == 0) return DateFormat.Hm().format(date);
    if (diff.inDays == 1) return l10n.notificationYesterday;
    if (diff.inDays < 7) return l10n.notificationDaysShort(diff.inDays);
    return DateFormat.yMMMd(l10n.localeName).format(date);
  }
}

/// Pill de filtro minimalista.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count = 0,
    this.accent = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int count;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeColor = accent ? scheme.error : scheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.1)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.25)
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                // Rótulo sempre legível (onSurface/onSurfaceVariant ≥ 4.5:1):
                // a seleção é sinalizada pela pílula, borda e badge — o
                // rótulo em activeColor dava ~4.4:1 (claro) e 3.6:1 (escuro).
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 0.5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? activeColor
                      : scheme.onSurfaceVariant.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        // Badge sólido: usa o "on" do papel de fundo
                        // (primary ou error) — branco puro falhava 3:1 no
                        // escuro sobre #F87171.
                        ? (accent ? scheme.onError : scheme.onPrimary)
                        : scheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

// ═══════════════════════════════════════════════════════════════════════════════
// HELPERS — Cores e ícones por tipo
// ═══════════════════════════════════════════════════════════════════════════════

abstract final class _AdminMessageTypeLabel {
  static IconData icon(AdminMessageType type) => switch (type) {
    AdminMessageType.billingQuote => Icons.receipt_long_outlined,
    AdminMessageType.planExpiryChange => Icons.event_repeat_outlined,
    AdminMessageType.planExpiringSoon => Icons.timer_outlined,
    AdminMessageType.general => Icons.mail_outline,
  };

  static Color color(AdminMessageType type) => switch (type) {
    AdminMessageType.billingQuote => AppColors.statusInfo,
    AdminMessageType.planExpiryChange => AppColors.statusPurple,
    AdminMessageType.planExpiringSoon => AppColors.statusWarning,
    AdminMessageType.general => AppColors.statusIndigo,
  };

  static String label(AdminMessageType type, AppLocalizations l10n) =>
      switch (type) {
        AdminMessageType.billingQuote => l10n.notificationAdminLabelQuote,
        AdminMessageType.planExpiryChange =>
          l10n.notificationAdminLabelValidity,
        AdminMessageType.planExpiringSoon =>
          l10n.notificationAdminLabelExpiring,
        AdminMessageType.general => l10n.notificationAdminLabelGeneral,
      };
}

abstract final class _InvoiceTypeLabel {
  static IconData icon(InvoiceNotificationType type) => switch (type) {
    InvoiceNotificationType.invoiceGenerated => Icons.add_circle_outline,
    InvoiceNotificationType.invoiceDueSoon => Icons.schedule_outlined,
    InvoiceNotificationType.invoiceExpired => Icons.cancel_outlined,
    InvoiceNotificationType.invoicePaid => Icons.check_circle_outline,
    InvoiceNotificationType.addOnExpiringSoon => Icons.warning_amber_rounded,
    InvoiceNotificationType.addOnExpired => Icons.extension_off_outlined,
  };

  static Color color(InvoiceNotificationType type) => switch (type) {
    InvoiceNotificationType.invoiceGenerated => AppColors.statusPurple,
    InvoiceNotificationType.invoiceDueSoon => AppColors.statusWarning,
    InvoiceNotificationType.invoiceExpired => AppColors.statusError,
    InvoiceNotificationType.invoicePaid => AppColors.statusTeal,
    InvoiceNotificationType.addOnExpiringSoon => AppColors.statusWarning,
    InvoiceNotificationType.addOnExpired => AppColors.statusError,
  };

  static String label(
    InvoiceNotificationType type,
    AppLocalizations l10n,
  ) => switch (type) {
    InvoiceNotificationType.invoiceGenerated =>
      l10n.notificationInvoiceGenerated,
    InvoiceNotificationType.invoiceDueSoon => l10n.notificationInvoiceDueSoon,
    InvoiceNotificationType.invoiceExpired => l10n.notificationInvoiceExpired,
    InvoiceNotificationType.invoicePaid => l10n.notificationInvoicePaid,
    InvoiceNotificationType.addOnExpiringSoon =>
      l10n.notificationAddonExpiringTitle,
    InvoiceNotificationType.addOnExpired => l10n.notificationAddonExpiredTitle,
  };

  static String iconLabel(
    InvoiceNotificationType type,
    AppLocalizations l10n,
  ) => switch (type) {
    InvoiceNotificationType.invoiceGenerated => l10n.notificationIconInvoice,
    InvoiceNotificationType.invoiceDueSoon => l10n.notificationIconDue,
    InvoiceNotificationType.invoiceExpired => l10n.notificationIconExpired,
    InvoiceNotificationType.invoicePaid => l10n.notificationIconPaid,
    InvoiceNotificationType.addOnExpiringSoon => l10n.notificationIconExpiring,
    InvoiceNotificationType.addOnExpired => l10n.notificationIconExpiredShort,
  };
}
