import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/invoice_notification.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/business_alerts_provider.dart';
import '../../controllers/notification_providers.dart';
import '../../controllers/admin_message_providers.dart';
import '../../../domain/entities/admin_message.dart';
import '../../navigation/app_routes.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/premium_decor.dart';
import '../products/product_form_sheets.dart' show EditProductSheet;
import '../shell/app_shell.dart' show AppSection;

/// Tela de notificações do tenant — lista as notificações de facturas
/// e mensagens do super admin com visual minimalista e detalhes em bottom sheet.
enum _NotificationFilter { all, unread, alerts }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final notificationsAsync = ref.watch(tenantNotificationsProvider);
    final adminMessagesAsync = ref.watch(tenantAdminMessagesProvider);
    final businessAlertsAsync = ref.watch(businessAlertsProvider);

    final allNotifications =
        notificationsAsync.value ?? const <InvoiceNotification>[];
    final allAdminMessages = adminMessagesAsync.value ?? const <AdminMessage>[];
    final allBusinessAlerts =
        businessAlertsAsync.value ?? const <BusinessAlert>[];
    final filteredNotifications = _filter == _NotificationFilter.unread
        ? allNotifications.where((n) => !n.isRead).toList()
        : _filter == _NotificationFilter.alerts
        ? const <InvoiceNotification>[]
        : allNotifications;
    final filteredAdminMessages = _filter == _NotificationFilter.unread
        ? allAdminMessages.where((m) => !m.isRead).toList()
        : _filter == _NotificationFilter.alerts
        ? const <AdminMessage>[]
        : allAdminMessages;
    final filteredBusinessAlerts =
        _filter == _NotificationFilter.alerts ||
            _filter == _NotificationFilter.all
        ? allBusinessAlerts
        : const <BusinessAlert>[];
    final unreadInvoiceCount = allNotifications.where((n) => !n.isRead).length;
    final unreadAdminCount = allAdminMessages.where((m) => !m.isRead).length;
    final unreadCount = unreadInvoiceCount + unreadAdminCount;
    final activeAlertCount = allBusinessAlerts.length;
    final totalCount =
        allNotifications.length + allAdminMessages.length + activeAlertCount;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      backgroundColor: scheme.surface,
      title: l10n.notificationTitle,
      badge: unreadCount + activeAlertCount,
      useSafeArea: false,
      actions: [
        if (unreadCount > 0)
          // Acção em ícone: o texto longo não cabe no AppBar a 412px
          // (cortava) nem em escalas de texto grandes; o tooltip mantém
          // o rótulo para leitores de ecrã.
          IconButton(
            tooltip: l10n.notificationMarkAllRead,
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all, size: AppSizes.iconMd),
          ),
        const SizedBox(width: AppSpacing.xs),
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
                  selected: _filter == _NotificationFilter.all,
                  count: totalCount,
                  onTap: () =>
                      setState(() => _filter = _NotificationFilter.all),
                ),
                const SizedBox(width: AppSpacing.xs),
                _Pill(
                  label: l10n.notificationTabUnread,
                  selected: _filter == _NotificationFilter.unread,
                  count: unreadCount,
                  onTap: () =>
                      setState(() => _filter = _NotificationFilter.unread),
                  accent: true,
                ),
                const SizedBox(width: AppSpacing.xs),
                _Pill(
                  label: l10n.notificationsTabAlerts,
                  selected: _filter == _NotificationFilter.alerts,
                  count: activeAlertCount,
                  onTap: () =>
                      setState(() => _filter = _NotificationFilter.alerts),
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
                ref.invalidate(businessAlertsProvider);
                await ref.read(businessAlertsProvider.future);
              },
              child:
                  (filteredNotifications.isEmpty &&
                          filteredAdminMessages.isEmpty &&
                          filteredBusinessAlerts.isEmpty) &&
                      !notificationsAsync.isLoading &&
                      !adminMessagesAsync.isLoading &&
                      !businessAlertsAsync.isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        EmptyState(
                          icon: businessAlertsAsync.hasError
                              ? Icons.cloud_off_outlined
                              : _filter == _NotificationFilter.alerts
                              ? Icons.check_circle_outline
                              : Icons.notifications_none_outlined,
                          title: _filter == _NotificationFilter.unread
                              ? l10n.notificationTabUnread
                              : _filter == _NotificationFilter.alerts
                              ? l10n.notificationsTabAlerts
                              : l10n.notificationNoNotifications,
                          subtitle: _filter == _NotificationFilter.alerts
                              ? businessAlertsAsync.hasError
                                    ? l10n.notificationsAlertsLoadError
                                    : l10n.notificationsNoActiveAlerts
                              : l10n.notificationNoNotificationsHint,
                          actionLabel: businessAlertsAsync.hasError
                              ? l10n.commonRetry
                              : null,
                          onAction: businessAlertsAsync.hasError
                              ? () => ref.invalidate(businessAlertsProvider)
                              : null,
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        AppSpacing.xs,
                        horizontal,
                        AppSpacing.xl,
                      ),
                      itemCount: _buildItemList(
                        filteredAdminMessages,
                        filteredNotifications,
                        filteredBusinessAlerts,
                        notificationsAsync.isLoading ||
                            adminMessagesAsync.isLoading ||
                            businessAlertsAsync.isLoading,
                      ).length,
                      itemBuilder: (context, index) {
                        final item = _buildItemList(
                          filteredAdminMessages,
                          filteredNotifications,
                          filteredBusinessAlerts,
                          notificationsAsync.isLoading ||
                              adminMessagesAsync.isLoading ||
                              businessAlertsAsync.isLoading,
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

  /// Builds the current alerts and persistent notifications in one inbox.
  List<Widget> _buildItemList(
    List<AdminMessage> adminMessages,
    List<InvoiceNotification> notifications,
    List<BusinessAlert> businessAlerts,
    bool isLoading,
  ) {
    final items = <Widget>[];

    for (var i = 0; i < businessAlerts.length; i++) {
      items.add(
        _NotificationTile.businessAlert(
          alert: businessAlerts[i],
          l10n: context.l10n,
          onTap: () => _openBusinessAlert(businessAlerts[i]),
          showDivider:
              i < businessAlerts.length - 1 ||
              adminMessages.isNotEmpty ||
              notifications.isNotEmpty,
        ),
      );
    }

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
          padding: EdgeInsets.symmetric(vertical: AppSpacing.huge),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    return items;
  }

  void _openBusinessAlert(BusinessAlert alert) {
    if (ref.read(currentAccessLevelProvider) == UserAccessLevel.employee) {
      AppNavigator.pushSection(context, AppSection.products);
      return;
    }
    showAppSheet<void>(
      context,
      builder: (_) => EditProductSheet(product: alert.product),
    );
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
      // Título localizado por tipo: o título/corpo persistidos foram criados
      // sem contexto (dado armazenado, PT) — na exibição localizamos o que
      // dá; o corpo permanece o armazenado como fallback.
      title: _InvoiceTypeLabel.label(notification.type, context.l10n),
      body: _InvoiceTypeLabel.body(notification, context.l10n),
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
// HELPERS — Cores do tipo no tile e na sheet
// ═══════════════════════════════════════════════════════════════════════════════

/// Texto do selo sobre o tint do tipo: neutro (informação) → tinta;
/// alertas → as variantes AA de sucesso/erro do tema.
Color _typeTextColor(Color base, ThemeData theme) {
  if (base == AppColors.neutralInfo || base == AppColors.accentBlue) {
    return theme.colorScheme.onSurface;
  }
  if (base == AppColors.successNeutral) return theme.income;
  return theme.expense;
}

/// Glifo sobre o fundo do ícone, só com as cores do anexo.
/// Neutro: tinta no claro e branco no escuro. Alertas: o próprio tom no
/// claro e o tint AA no escuro.
Color _deriveFg(Color base, Brightness brightness) {
  final light = brightness == Brightness.light;
  if (base == AppColors.neutralInfo || base == AppColors.accentBlue) {
    return light ? AppColors.brandInk : AppColors.softWhite;
  }
  if (base == AppColors.alertError) {
    return light ? AppColors.alertError : AppColors.errorTextDark;
  }
  if (base == AppColors.alertSuccess) {
    return light ? AppColors.alertSuccess : AppColors.successTextDark;
  }
  return light ? AppColors.brandInk : AppColors.softWhite;
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

/// Tile minimalista — ícone à esquerda, conteúdo ao centro, ação à direita.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconBg,
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
      // Título/corpo localizados por tipo (os persistidos são dados).
      title: _InvoiceTypeLabel.label(notification.type, l10n),
      subtitle: _InvoiceTypeLabel.body(notification, l10n),
      time: notification.createdAt,
      typeLabel: _InvoiceTypeLabel.iconLabel(notification.type, l10n),
      typeColor: color,
      isRead: notification.isRead,
      onTap: onTap,
      onMarkAsRead: onMarkAsRead,
      showDivider: showDivider,
    );
  }

  factory _NotificationTile.businessAlert({
    required BusinessAlert alert,
    required AppLocalizations l10n,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    final product = alert.product;
    final quantity = Quantity.format(
      alert.quantity,
      unitLabel: product.vendaPorFracao ? product.unitLabel : null,
      language: Formatters.currentLanguage,
    );
    final expiryDate = alert.expiryDate == null
        ? ''
        : Formatters.day(alert.expiryDate!);
    final color = switch (alert.type) {
      BusinessAlertType.outOfStock ||
      BusinessAlertType.expired => AppColors.alertError,
      BusinessAlertType.lowStock ||
      BusinessAlertType.expiring => AppColors.neutralInfo,
    };
    final (icon, title, subtitle) = switch (alert.type) {
      BusinessAlertType.outOfStock => (
        Icons.remove_shopping_cart_outlined,
        l10n.notificationOutOfStockTitle(product.name),
        l10n.notificationOutOfStockBody,
      ),
      BusinessAlertType.lowStock => (
        Icons.warning_amber_rounded,
        l10n.notificationLowStockTitle(product.name),
        l10n.notificationLowStockBody(quantity),
      ),
      BusinessAlertType.expired => (
        Icons.event_busy_outlined,
        l10n.notificationExpiryExpiredTitle(product.name),
        l10n.notificationExpiryExpiredBody(quantity, expiryDate),
      ),
      BusinessAlertType.expiring => (
        Icons.event_outlined,
        l10n.notificationExpirySoonTitle(product.name),
        l10n.notificationExpirySoonBody(
          alert.daysRemaining ?? 0,
          quantity,
          expiryDate,
        ),
      ),
    };

    return _NotificationTile(
      icon: icon,
      iconBg: color,
      title: title,
      subtitle: subtitle,
      time: null,
      typeLabel: l10n.notificationAlertLabel,
      typeColor: color,
      isRead: false,
      onTap: onTap,
      showDivider: showDivider,
    );
  }

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final DateTime? time;
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
    final typeTextColor = _typeTextColor(typeColor, theme);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xxs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Ícone ──
                  Container(
                    width: AppSizes.avatarMd,
                    height: AppSizes.avatarMd,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBg.withValues(alpha: isRead ? 0.08 : 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      icon,
                      size: AppSizes.iconMd,
                      color: _deriveFg(iconBg, theme.brightness),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

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
                                // Não lida = tinta; lida = secundária.
                                style: AppTypography.labelLarge.copyWith(
                                  color: isRead
                                      ? scheme.onSurfaceVariant
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                width: AppSpacing.xs,
                                height: AppSpacing.xs,
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            if (time != null) ...[
                              Text(
                                _formatTime(time!, l10n),
                                style: AppTypography.bodySmall.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.micro,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                typeLabel,
                                // Selo em tinta/semântica AA — o tom azul
                                // a 12px falhava contraste.
                                style: AppTypography.labelMedium.copyWith(
                                  color: typeTextColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (onMarkAsRead != null)
                              IconButton(
                                // A11y: alvo de toque 48dp + rótulo para
                                // leitores de ecrã.
                                tooltip: l10n.notificationMarkRead,
                                onPressed: onMarkAsRead,
                                icon: Icon(
                                  Icons.done_all_outlined,
                                  size: AppSizes.iconSm,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: AppSizes.iconMd,
                              color: scheme.onSurfaceVariant,
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
            color: PremiumDecor.hairline(scheme),
            // Alinhado ao início do texto (ícone 40 + gap 12 + respiro 4).
            indent: AppSizes.avatarMd + AppSpacing.sm + AppSpacing.xxs,
          ),
      ],
    );
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
      margin: EdgeInsets.only(top: topPadding + AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        border: Border(top: BorderSide(color: PremiumDecor.hairline(scheme))),
        boxShadow: PremiumDecor.upwardShadow(scheme),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle (barra padrão das sheets) ──
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
            child: SheetHandle(),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppSizes.avatarMd,
                  height: AppSizes.avatarMd,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Icon(
                    icon,
                    size: AppSizes.iconMd,
                    color: _deriveFg(typeColor, theme.brightness),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.micro,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              typeLabel,
                              style: AppTypography.labelMedium.copyWith(
                                color: _typeTextColor(typeColor, theme),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _DetailBottomSheet._formatTime(time, l10n),
                            style: AppTypography.bodySmall.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  // A11y: leitor de ecrã anuncia a ação (mesmo padrão
                  // das outras sheets do app).
                  tooltip: l10n.appSheetClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: AppSizes.iconMd,
                    color: scheme.onSurfaceVariant,
                  ),
                  padding: EdgeInsets.zero,
                  // A11y: alvo de toque ≥48dp.
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Divider(height: 1, color: PremiumDecor.hairline(scheme)),
          ),

          // ── Body ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Text(
                body,
                style: AppTypography.bodyMedium.copyWith(
                  color: scheme.onSurfaceVariant,
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

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // A11y: alvo de toque com 48dp de altura (androidTapTargetGuideline)
        // sem alterar o visual da pílula — a área extra é transparente.
        child: SizedBox(
          height: AppSizes.touchTarget,
          child: Center(
            widthFactor: 1,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
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
                    style: AppTypography.labelMedium.copyWith(
                      // Rótulo sempre legível (onSurface/onSurfaceVariant ≥ 4.5:1):
                      // a seleção é sinalizada pela pílula, borda e badge — o
                      // rótulo em activeColor dava ~4.4:1 (claro) e 3.6:1 (escuro).
                      color: selected
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
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
                        style: AppTypography.labelMedium.copyWith(
                          color: selected
                              // Badge sólido: usa o "on" do papel de fundo
                              // (primary ou error) — branco puro falhava 3:1 no
                              // escuro sobre #F87171.
                              ? (accent ? scheme.onError : scheme.onPrimary)
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
    AdminMessageType.billingQuote => AppColors.neutralInfo,
    AdminMessageType.planExpiryChange => AppColors.neutralInfo,
    AdminMessageType.planExpiringSoon => AppColors.neutralInfo,
    AdminMessageType.general => AppColors.neutralInfo,
  };

  static String label(
    AdminMessageType type,
    AppLocalizations l10n,
  ) => switch (type) {
    AdminMessageType.billingQuote => l10n.notificationAdminLabelQuote,
    AdminMessageType.planExpiryChange => l10n.notificationAdminLabelValidity,
    AdminMessageType.planExpiringSoon => l10n.notificationAdminLabelExpiring,
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
    InvoiceNotificationType.invoiceGenerated => AppColors.neutralInfo,
    InvoiceNotificationType.invoiceDueSoon => AppColors.neutralInfo,
    InvoiceNotificationType.invoiceExpired => AppColors.errorNeutral,
    InvoiceNotificationType.invoicePaid => AppColors.successNeutral,
    InvoiceNotificationType.addOnExpiringSoon => AppColors.neutralInfo,
    InvoiceNotificationType.addOnExpired => AppColors.errorNeutral,
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

  /// Corpo localizado a partir de [InvoiceNotification.bodyParams] — o
  /// corpo persistido é dado (PT) e fica como fallback para notificações
  /// legadas (params nulos).
  static String body(InvoiceNotification notification, AppLocalizations l10n) {
    final p = notification.bodyParams;
    if (p == null) return notification.body;
    final days = int.tryParse(p['days'] ?? '') ?? 0;
    return switch (notification.type) {
      InvoiceNotificationType.invoiceGenerated =>
        l10n.notificationBodyInvoiceGenerated(
          p['period'] ?? '',
          p['amount'] ?? '',
          p['currency'] ?? '',
          p['dueDate'] ?? '',
        ),
      InvoiceNotificationType.invoiceDueSoon =>
        l10n.notificationBodyInvoiceDueSoon(
          p['period'] ?? '',
          p['amount'] ?? '',
          p['currency'] ?? '',
          days,
        ),
      InvoiceNotificationType.invoiceExpired =>
        l10n.notificationBodyInvoiceExpired(
          p['period'] ?? '',
          p['amount'] ?? '',
          p['currency'] ?? '',
        ),
      InvoiceNotificationType.invoicePaid => l10n.notificationBodyInvoicePaid(
        p['period'] ?? '',
        p['amount'] ?? '',
        p['currency'] ?? '',
      ),
      InvoiceNotificationType.addOnExpiringSoon =>
        l10n.notificationBodyAddOnExpiringSoon(
          p['addonName'] ?? '',
          days,
          p['date'] ?? '',
        ),
      InvoiceNotificationType.addOnExpired => l10n.notificationBodyAddOnExpired(
        p['addonName'] ?? '',
        p['date'] ?? '',
      ),
    };
  }

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
