import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
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
import '../../widgets/payment_filter.dart';
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

/// Conteúdo do sheet de detalhe da venda — layout idêntico ao feed de
/// "Atividade de hoje" na Home: ícone circular tingido, título/detalhes à
/// esquerda e valor/badge à direita, com divisórias de 60px entre itens.
class _SaleDetailSheet extends StatelessWidget {
  const _SaleDetailSheet({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: AppSpacing.sheetPadding,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linha do sale no feed — ícone circular + título + detalhes + total
            _SaleFeedRow(
              sale: sale,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.saleDetailView,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF101413),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Itens expandidos — mesmo padrão do feed: ícone circular laranja,
            // título + quantidade × preço à esquerda, subtotal à direita.
            for (var i = 0; i < sale.items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  indent: 60,
                  endIndent: AppSpacing.md,
                ),
              _SaleItemRow(item: sale.items[i]),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

/// Linha de sale no feed — ícone circular laranja à esquerda, título, data e
/// quantidade de itens ao centro, valor total à direita, seguindo o mesmo
/// padrão do _ActivityRow do dashboard.
class _SaleFeedRow extends StatelessWidget {
  const _SaleFeedRow({
    required this.sale,
    this.trailing,
  });

  final Sale sale;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final subtotal = sale.items.fold(0, (sum, item) =>
        sum + Quantity.lineTotal(item.quantity, item.unitPriceCents));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          // Container circular do ícone (40px) — padrão do feed, cor laranja.
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.accentOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.north_east_rounded,
              size: 18,
              color: Colors.white,
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
                const SizedBox(height: 2),
                Text(
                  '${sale.paymentMethod.labelFor(l10n)} · ${Formatters.time(sale.dateTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Total à direita, igual ao padrão do feed.
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: trailing ?? Text(
                Formatters.signedAmount(subtotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de item de venda no padrão do feed de atividade — ícone circular
/// laranja à esquerda, título e quantidade × preço ao centro, valor à direita.

/// Tela de detalhes de uma venda — layout clean Google-style.
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
    final l10n = context.l10n;
    final canCancel = ref.watch(canCancelSalesProvider);
    final isCancelled = sale.status == SaleStatus.cancelled;
    final activeStore = _activeStore();

    return AppPage(
      title: l10n.saleDetailTitle,
      useSafeArea: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
        children: [
          // ── Header: sale ID + date + payment chip ──
          Text(
            l10n.saleDetailId(Formatters.saleLabel(sale.number)),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.dateTime(sale.dateTime),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
              color: AppColors.accentOrange,
              icon: sale.paymentMethod.icon,
            ),
          if (isCancelled && sale.cancelledAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.saleDetailCancelledAt} ${Formatters.dateTime(sale.cancelledAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // ── Items ──
          // Usa o mesmo padrão de linhas do feed de atividade da Home,
          // com indent: 60 e ícone circular em laranja.
          for (var i = 0; i < sale.items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 60,
                endIndent: AppSpacing.md,
                color: theme.colorScheme.outlineVariant,
              ),
            _SaleItemRow(item: sale.items[i]),
          ],
          const SizedBox(height: 16),

          // ── Total ──
          // Feed row de total: ícone circular laranja + label + valor em
          // destaque à direita — mesmo chrome do "Atividade de hoje".
          _SaleFeedRow(sale: sale),
          const SizedBox(height: AppSpacing.md),

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
}/// Linha de item de venda no padrão do feed de atividade — ícone circular
/// laranja à esquerda, título e quantidade × preço ao centro, valor à direita.
class _SaleItemRow extends ConsumerWidget {
  const _SaleItemRow({required this.item});

  final SaleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtotal = Quantity.lineTotal(item.quantity, item.unitPriceCents);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          // Ícone circular laranja — padrão do feed.
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.accentOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.north_east_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${Quantity.format(item.quantity, language: Formatters.currentLanguage)} × '
                  '${Formatters.currency(item.unitPriceCents)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                Formatters.currency(subtotal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}