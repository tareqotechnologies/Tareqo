import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/i18n/payment_method_l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sale.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import 'new_sale_sheet.dart';
import 'sale_detail_screen.dart';

/// Tela de vendas — histórico e registro de novas vendas.
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  Future<void> _openNewSale(BuildContext context, WidgetRef ref) async {
    await showAppSheet<void>(context, builder: (_) => const NewSaleSheet());
    if (!context.mounted) return;
    // O carrinho pode ter registrado uma venda e baixado o estoque.
    ref.invalidate(salesListProvider);
    ref.invalidate(productsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesTitle),
        actions: [
          IconButton(
            tooltip: l10n.commonRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(salesListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-sales',
        onPressed: () => _openNewSale(context, ref),
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(l10n.salesNewSale),
      ),
      body: salesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: l10n.salesLoadError,
          details: error.toString(),
          onRetry: () => ref.invalidate(salesListProvider),
        ),
        data: (sales) {
          if (sales.isEmpty) {
            return EmptyState(
              icon: Icons.point_of_sale_outlined,
              title: l10n.salesEmptyTitle,
              subtitle: l10n.salesEmptySubtitle,
              actionLabel: l10n.salesNewSale,
              onAction: () => _openNewSale(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(salesListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sales.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _SaleCard(sale: sales[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Card de venda: dia, forma de pagamento, itens e total.
class _SaleCard extends StatelessWidget {
  const _SaleCard({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsLabel = context.l10n.dashboardSaleItems(sale.items.length);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => SaleDetailScreen(sale: sale)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.point_of_sale_outlined,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$itemsLabel · '
                          '${sale.paymentMethod.labelFor(context.l10n)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.day(sale.dateTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(sale.totalAmountCents),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Formatters.dateTime(sale.dateTime),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
