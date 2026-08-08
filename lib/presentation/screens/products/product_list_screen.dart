import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/usecases/add_product_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/dashboard_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_chip.dart';
import '../../../core/observability/crash_reporting.dart';

/// Tela de listagem de produtos — busca local, pull-to-refresh e
/// cadastro via bottom sheet. Consome apenas o estado de
/// [productsProvider] (abstrações do domínio, nunca datasources).
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddSheet() async {
    await showAppSheet<void>(context, builder: (_) => const _AddProductSheet());
    if (!mounted) return;
    ref.invalidate(productsProvider);
    ref.invalidate(dashboardKpisProvider);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final l10n = context.l10n;
    // Funcionário comum NÃO cria produto (só vende): o cadastro fica para
    // dono e gerente (matriz de acesso). O servidor também restringe o
    // INSERT (política products_insert via is_my_store do dono/gerente).
    final canManageProducts =
        ref.watch(currentAccessLevelProvider) != UserAccessLevel.employee;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appNavProducts)),
      floatingActionButton: canManageProducts
          ? FloatingActionButton.extended(
              heroTag: 'fab-products',
              onPressed: _openAddSheet,
              icon: const Icon(Icons.add),
              label: Text(l10n.productsAddNew),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.productsSearchHint,
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: l10n.productsLoadError,
                details: error.toString(),
                onRetry: () => ref.invalidate(productsProvider),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: l10n.productsEmptyTitle,
                    subtitle: l10n.productsEmptySubtitle,
                  );
                }

                final filtered = _query.isEmpty
                    ? products
                    : products
                          .where(
                            (product) =>
                                product.name.toLowerCase().contains(_query) ||
                                product.description.toLowerCase().contains(
                                  _query,
                                ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: l10n.commonNoResults,
                    subtitle: l10n.commonNoResultsHint,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(productsProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _ProductTile(product: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Card minimalista do produto: avatar, nome, preços e estoque.
class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final lowStock = product.stockQuantity < 5;

    return Card(
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
                Icons.inventory_2_outlined,
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
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.productsBuySell(
                      Formatters.currency(product.purchasePriceCents),
                      Formatters.currency(product.salePriceCents),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Flexible: o chip encolhe (ellipsis) com escala de texto alta
            // ou estoque grande — o Expanded do nome cede espaço primeiro.
            Flexible(
              child: StatusChip(
                label: '${product.stockQuantity} ${l10n.commonUnits}',
                color: lowStock ? theme.warning : theme.colorScheme.primary,
                icon: lowStock
                    ? Icons.warning_amber_rounded
                    : Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de cadastro de produto.
class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet();

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // Interpreta o preço digitado como CENTAVOS inteiros (W4).
  int _parsePrice(String value) => Money.parse(value);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final purchasePriceCents = _parsePrice(_purchasePriceController.text);
    final salePriceCents = _parsePrice(_salePriceController.text);
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    // O produto pertence à loja ativa (cada loja tem seu próprio estoque).
    final user = ref.read(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.read(activeStoreIdProvider(user.id));

    final l10n = context.l10n;

    try {
      await ref
          .read(addProductUseCaseProvider)
          .call(
            Product(
              id: AppIds.newId('p'),
              storeId: storeId ?? 'st1',
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              purchasePriceCents: purchasePriceCents,
              salePriceCents: salePriceCents,
              stockQuantity: stock,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.productsAdded)));
    } on InvalidPriceException catch (error) {
      setState(() => _formError = error.message);
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao adicionar produto',
      );
      setState(() => _formError = l10n.productsAddError);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetHeader(title: l10n.productsAddNew),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.loginNameLabel,
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.productsNameError
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.productsDescriptionLabel,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.productsPurchasePrice,
                        prefixIcon: const Icon(Icons.south),
                      ),
                      validator: (value) => _parsePrice(value ?? '') <= 0
                          ? l10n.productsPurchasePriceError
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _salePriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.productsSalePrice,
                        prefixIcon: const Icon(Icons.north),
                      ),
                      validator: (value) => _parsePrice(value ?? '') <= 0
                          ? l10n.productsSalePriceError
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.productsStockQuantity,
                  prefixIcon: const Icon(Icons.warehouse_outlined),
                ),
                validator: (value) {
                  final quantity = int.tryParse(value?.trim() ?? '');
                  if (quantity == null || quantity < 0) {
                    return l10n.productsStockError;
                  }
                  return null;
                },
              ),
              if (_formError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _formError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.productsAddSubmit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
