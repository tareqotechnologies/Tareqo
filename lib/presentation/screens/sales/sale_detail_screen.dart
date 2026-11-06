import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../domain/entities/sale.dart';
import '../../../domain/entities/sale_item.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/cancel_sale_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/payment_filter.dart'
    show PaymentMethodAccent, PaymentMethodIcon;
import '../../widgets/product_image.dart';
import '../../widgets/section_header.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/status_chip.dart';
import 'sale_receipt_share_sheet.dart';

/// Abre o detalhe da venda no **sheet padrão de eventos** — o mesmo chrome
/// usado pela Home ("Atividade de hoje"): handle, cabeçalho com ícone
/// circular e o conteúdo em linhas agrupadas sobre a superfície do sheet.
///
/// A tela completa ([SaleDetailScreen]) continua a ser usada pelo feed da
/// Home; na lista de Vendas o toque abre este sheet.
Future<void> showSaleDetailSheet(BuildContext context, Sale sale) {
  return showAppSheet<void>(
    context,
    builder: (_) => _SaleDetailSheet(sale: sale),
  );
}

/// Conteúdo do sheet de detalhe da venda.
class _SaleDetailSheet extends StatelessWidget {
  const _SaleDetailSheet({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final accent = sale.paymentMethod.accent(theme);
    final isCancelled = sale.status == SaleStatus.cancelled;
    final itemsLabel = l10n.dashboardSaleItems(sale.items.length);

    return Padding(
      padding: AppSpacing.sheetPadding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do sheet de eventos: ícone circular + referência.
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: IconTone.darkBackground(accent),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sale.paymentMethod.icon,
                    size: 18,
                    color: IconTone.lightForeground(accent),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Formatters.saleLabel(sale.number),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        '${Formatters.dateTime(sale.dateTime)} · $itemsLabel',
                        maxLines: 2,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusChip(
                  label: isCancelled
                      ? l10n.salesStatusCancelled
                      : l10n.salesStatusPaid,
                  color: isCancelled ? theme.expense : theme.income,
                  icon: isCancelled ? Icons.block : Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Itens da venda — o mesmo painel agrupado dos eventos da Home.
            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < sale.items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    _ItemRow(item: sale.items[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Total da venda — âncora do sheet.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.saleDetailTotalLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: SmartAmount(
                    cents: sale.totalAmountCents,
                    alignment: Alignment.centerRight,
                    style: isCancelled
                        ? theme.textTheme.headlineMedium?.copyWith(
                            color: scheme.outline,
                            decoration: TextDecoration.lineThrough,
                          )
                        : AppTypography.summaryAmount(scheme.onSurface),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela de detalhes de uma venda — layout clean Google-style.
///
/// Quando a venda está ativa e o usuário tem acesso gerencial,
/// oferece a ação de anular venda.
class SaleDetailScreen extends ConsumerStatefulWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final Sale sale;

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  bool _cancelling = false;

  Sale get sale => widget.sale;

  Store? _activeStore() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return null;
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return null;
    final storeId = ref.watch(activeStoreIdProvider(user.id));
    if (storeId == null) return null;
    final stores =
        ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    return stores.where((store) => store.id == storeId).firstOrNull;
  }

  void _openShareSheet(Store? store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SaleReceiptShareSheet(
        sale: sale,
        storeName: store?.name,
        storeAddress: (store?.address ?? '').isEmpty ? null : store?.address,
      ),
    );
  }

  Future<void> _confirmCancel() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.saleDetailCancelConfirmTitle,
      message: l10n.saleDetailCancelConfirmBody(
        Formatters.currency(sale.totalAmountCents),
      ),
      confirmLabel: l10n.saleDetailCancelConfirm,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    // M4 (auditoria): segunda barreira de identidade para a anulação —
    // operação financeira reversa (estorno de estoque + caixa). O guarda
    // `is_manager_of_store` existe no SERVIDOR, mas a UX local precisa
    // espelhá-lo: sem esta barreira, qualquer pessoa com o app desbloqueado
    // anula vendas. A biometria é exigida SE o aparelho suporta; sem
    // suporte (aparelho antigo), o diálogo textual permanece a única
    // barreira (degradação consciente, não bloqueio do negócio).
    final biometric = ref.read(biometricAuthUseCaseProvider);
    if (await biometric.isAvailable()) {
      // Reusa o `l10n` capturado no TOPO do método (antes do primeiro gap
      // assíncrono) — nunca `context` depois de await (lint
      // use_build_context_synchronously).
      final ok = await biometric.authenticate(
        localizedReason: l10n.saleDetailCancelBiometricReason,
        signInTitle: l10n.biometricSignInTitle,
        biometricHint: l10n.biometricHint,
        cancelButton: l10n.biometricCancel,
        fallbackTitle: l10n.biometricFallbackTitle,
        goToSettingsButton: l10n.biometricGoToSettingsButton,
        goToSettingsDescription: l10n.biometricGoToSettingsDescription,
        lockOut: l10n.biometricLockOut,
      );
      if (!mounted) return;
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.saleDetailCancelBiometricFailed)),
        );
        return;
      }
    }

    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));
    if (storeId == null) return;

    setState(() => _cancelling = true);
    try {
      await ref.read(cancelSaleUseCaseProvider).call(sale.id, storeId: storeId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.saleCancelledSuccess)),
      );
      ref.invalidate(salesListProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(cashFlowProvider);
      ref.invalidate(dashboardKpisProvider);
      Navigator.of(context).pop();
    } on SaleNotFoundException {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.saleNotFoundError)));
      ref.invalidate(salesListProvider);
      Navigator.of(context).pop();
    } on OfflineEnqueuedException {
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.syncOfflineSaved)));
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao anular venda');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.saleCancelError)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final canCancel = ref.watch(canCancelSalesProvider);
    final isCancelled = sale.status == SaleStatus.cancelled;
    final activeStore = _activeStore();
    final accent = sale.paymentMethod.accent(theme);
    final itemsLabel = l10n.dashboardSaleItems(sale.items.length);
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      title: l10n.saleDetailTitle,
      useSafeArea: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 32),
        children: [
          // ── Header: sale ID + date + payment chip ──
          Text(
            l10n.saleDetailId(Formatters.saleLabel(sale.number)),
            // Referência da venda = título de secção (20/w600).
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${Formatters.dateTime(sale.dateTime)}  ·  $itemsLabel',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (isCancelled)
            StatusChip(
              label: l10n.salesStatusCancelled,
              color: theme.expense,
              icon: Icons.block,
            )
          else
            StatusChip(
              label: sale.paymentMethod.labelFor(context.l10n),
              color: accent,
              icon: sale.paymentMethod.icon,
            ),
          if (isCancelled && sale.cancelledAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.saleDetailCancelledAt} '
              '${Formatters.dateTime(sale.cancelledAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Total ──
          Text(
            l10n.saleDetailTotalLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SmartAmount(
            cents: sale.totalAmountCents,
            alignment: Alignment.centerLeft,
            style: isCancelled
                ? theme.textTheme.headlineMedium?.copyWith(
                    color: scheme.outline,
                    decoration: TextDecoration.lineThrough,
                  )
                // Total da venda = valor principal da tela (24/w600).
                : theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Items ──
          SectionHeader(title: l10n.saleDetailItems),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < sale.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  _ItemRow(item: sale.items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Snapshot note ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock_outlined, size: 14, color: scheme.outline),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.saleDetailSnapshot,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Actions ──
          AppButton.primary(
            label: l10n.saleDetailShareAction,
            onPressed: () => _openShareSheet(activeStore),
            icon: const Icon(Icons.ios_share, size: 20),
          ),
          if (canCancel && !isCancelled) ...[
            const SizedBox(height: 12),
            AppButton.secondary(
              label: l10n.saleDetailCancelAction,
              onPressed: _cancelling ? null : _confirmCancel,
              icon: _cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.warning,
                side: BorderSide(color: theme.warning),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Single item row: product image, name, quantity × price, subtotal.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtotal = Quantity.lineTotal(item.quantity, item.unitPriceCents);
    final imagePath =
        ref
            .watch(productsProvider)
            .value
            ?.where((p) => p.id == item.productId)
            .map((p) => p.imagePath)
            .firstOrNull ??
        '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          ProductImage(imagePath: imagePath, size: 40, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Nome do produto = 14/w400 (descrição da linha).
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 1),
                Text(
                  '${Quantity.format(item.quantity, language: Formatters.currentLanguage)} × '
                  '${Formatters.currency(item.unitPriceCents)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            Formatters.currency(subtotal),
            // Total da linha = 15/w500, alinhado à direita.
            style: AppTypography.amountInRow(scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
