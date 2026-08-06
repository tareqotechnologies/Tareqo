import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/purchase.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/finance_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/store_scoped_content.dart';
import 'add_purchase_sheet.dart';

/// Tela de compras — histórico de entradas de mercadoria de fornecedores.
/// Registrar uma compra aumenta o estoque e lança a saída no caixa
/// (ProcessPurchaseUseCase).
class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  Future<void> _openNewPurchase(BuildContext context, WidgetRef ref) async {
    await showAppSheet<void>(
      context,
      builder: (_) => const AddPurchaseSheet(),
    );
    if (!context.mounted) return;
    // Estoque, compras, caixa e KPIs mudaram — as telas recarregam.
    ref.invalidate(purchasesProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(cashFlowProvider);
    ref.invalidate(dashboardKpisProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.purchasesTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(purchasesProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-purchases',
        onPressed: () => _openNewPurchase(context, ref),
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(l10n.purchasesAddNew),
      ),
      // A tela é empurrada por cima do AppShell (fora da casca): o seletor
      // de loja ativa é re-adicionado para o usuário ver/trocar a loja e
      // as compras da loja selecionada.
      body: StoreScopedContent(
        child: purchasesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorView(
            message: l10n.purchasesLoadError,
            details: error.toString(),
            onRetry: () => ref.invalidate(purchasesProvider),
          ),
          data: (purchases) {
            if (purchases.isEmpty) {
              return EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: l10n.purchasesEmptyTitle,
                subtitle: l10n.purchasesEmptySubtitle,
                actionLabel: l10n.purchasesAddNew,
                onAction: () => _openNewPurchase(context, ref),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(purchasesProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: purchases.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _PurchaseCard(purchase: purchases[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Card de compra: fornecedor, nº de itens, dia e total.
class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.purchase});

  final Purchase purchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final itemsLabel = l10n.dashboardSaleItems(purchase.items.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.supplierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$itemsLabel · ${Formatters.day(purchase.dateTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(purchase.totalAmount),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateTime(purchase.dateTime),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
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
