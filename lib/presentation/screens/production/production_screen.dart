import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/production_order.dart';
import '../../../domain/entities/recipe.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/production_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/product_type_badge.dart' show productTypeLabel;
import '../../widgets/section_header.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/store_scoped_content.dart';
import 'recipe_form_sheet.dart';
import 'record_production_sheet.dart';

/// Módulo PRODUÇÃO (Fase 2) — fichas técnicas (receitas) e histórico de
/// ordens de produção.
///
/// Uma ordem de produção consome os componentes da ficha (baixa FIFO por
/// lotes) e cria um novo lote do produto acabado, ao custo calculado — tudo
/// atómico (ver `ProcessProductionUseCase` / RPC `process_production`).
class ProductionScreen extends ConsumerWidget {
  const ProductionScreen({super.key});

  Future<void> _openRecipeForm(BuildContext context, {Recipe? initial}) async {
    await showAppSheet<void>(
      context,
      builder: (_) => RecipeFormSheet(initial: initial),
    );
  }

  Future<void> _openRecord(BuildContext context, Recipe recipe) =>
      showAppSheet<void>(
        context,
        builder: (_) => RecordProductionSheet(recipe: recipe),
      );

  Future<void> _deleteRecipe(
    BuildContext context,
    WidgetRef ref,
    Recipe recipe,
    String name,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.productionDeleteTitle,
      message: l10n.productionDeleteMessage,
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (confirmed != true) return;
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? 'st1'
        : (ref.read(activeStoreIdProvider(user.id)) ?? 'st1');
    await ref
        .read(deleteRecipeUseCaseProvider)
        .call(recipe.id, storeId: storeId);
    ref.invalidate(recipesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recipesAsync = ref.watch(recipesProvider);
    final orders = ref.watch(productionOrdersProvider).value ?? const [];
    final products = ref.watch(productsProvider).value ?? const <Product>[];
    final productsById = {for (final product in products) product.id: product};

    return AppPage(
      title: l10n.productionTitle,
      useSafeArea: false,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-production',
        onPressed: () => _openRecipeForm(context),
        tooltip: l10n.productionNewRecipe,
        child: const Icon(Icons.add),
      ),
      body: StoreScopedContent(
        child: recipesAsync.when(
          loading: () => const Skeleton(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  SkeletonBlock(height: 96, radius: AppRadius.lg),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBlock(height: 96, radius: AppRadius.lg),
                ],
              ),
            ),
          ),
          error: (error, _) => ErrorView(
            message: l10n.productionTitle,
            details: error.toString(),
            onRetry: () => ref.invalidate(recipesProvider),
          ),
          data: (recipes) => RefreshIndicator(
            onRefresh: () async {
              await ref.read(recipesProvider.notifier).refresh();
              await ref.read(productionOrdersProvider.notifier).refresh();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePaddingForWidth(
                  MediaQuery.sizeOf(context).width,
                ),
                AppSpacing.xs,
                AppSpacing.pagePaddingForWidth(
                  MediaQuery.sizeOf(context).width,
                ),
                AppSpacing.fabBottomClearance,
              ),
              children: [
                SectionHeader(title: l10n.productionRecipesSection),
                const SizedBox(height: AppSpacing.sm),
                if (recipes.isEmpty)
                  EmptyState(
                    icon: Icons.bakery_dining_outlined,
                    title: l10n.productionEmptyTitle,
                    subtitle: l10n.productionEmptySubtitle,
                    actionLabel: l10n.productionNewRecipe,
                    onAction: () => _openRecipeForm(context),
                  )
                else
                  for (final recipe in recipes) ...[
                    _RecipeCard(
                      recipe: recipe,
                      finished: productsById[recipe.productId],
                      onEdit: () => _openRecipeForm(context, initial: recipe),
                      onProduce: () => _openRecord(context, recipe),
                      onDelete: () => _deleteRecipe(
                        context,
                        ref,
                        recipe,
                        productsById[recipe.productId]?.name ?? '',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(title: l10n.productionHistorySection),
                const SizedBox(height: AppSpacing.sm),
                if (orders.isEmpty)
                  EmptyState(
                    icon: Icons.history,
                    title: l10n.productionHistoryEmpty,
                    subtitle: l10n.productionHistoryEmptySubtitle,
                  )
                else
                  for (final order in orders) ...[
                    _OrderCard(order: order),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.finished,
    required this.onEdit,
    required this.onProduce,
    required this.onDelete,
  });

  final Recipe recipe;
  final Product? finished;
  final VoidCallback onEdit;
  final VoidCallback onProduce;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  finished?.name ?? recipe.productId,
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Papel do produto como TEXTO — mesma linguagem de Produtos,
              // PDV e Compras (o selo colorido antigo saiu).
              if (finished != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  productTypeLabel(context, finished!.type),
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline, size: AppSizes.iconMd),
                tooltip: l10n.commonDelete,
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${l10n.productionYieldLabel}: '
            '${Quantity.format(recipe.yieldQuantity, language: Formatters.currentLanguage)}'
            ' · ${l10n.productionItemCount(recipe.items.length)}',
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton.secondary(
              label: l10n.productionProduce,
              icon: const Icon(Icons.play_arrow_rounded, size: AppSizes.iconMd),
              onPressed: onProduce,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ProductionOrder order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.productName,
                  style: AppTypography.labelLarge.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  Formatters.day(order.dateTime),
                  style: AppTypography.bodySmall.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Quantidade produzida em tinta: o "+" já diz a direção;
              // verde é reservado a dinheiro recebido, não a stock.
              Text(
                '+${Quantity.format(order.quantity, language: Formatters.currentLanguage)}',
                style: AppTypography.amountInRow(scheme.onSurface),
              ),
              Text(
                Formatters.currency(order.totalCostCents),
                style: AppTypography.bodySmall.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
