import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/quantity.dart';
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
      // CTA único: sem produtos, o FAB some — o estado vazio traz o botão
      // de cadastro centralizado (mantendo a regra canManageProducts).
      floatingActionButton: canManageProducts &&
              (productsAsync.value?.isNotEmpty ?? false)
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
                    // CTA único no estado vazio (o FAB some) — só para
                    // quem pode gerir produtos (dono/gerente).
                    actionLabel: canManageProducts
                        ? l10n.productsAddNew
                        : null,
                    onAction: canManageProducts ? _openAddSheet : null,
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
    // W11: o estoque vive em MILÉSIMOS — o limiar de estoque baixo e a
    // exibição convertem para unidades (5 unidades).
    final lowStock =
        product.stockQuantity <
        Quantity.lowStockThresholdUnits * Quantity.milliFactor;

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
                  // FittedBox: o par "Compra: X · Venda: Y" ENCOLHE para
                  // caber — nunca trunca ("MTn 30...."); o preço completo
                  // fica visível mesmo com o chip de estoque ao lado.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.productsBuySell(
                        Formatters.currency(product.purchasePriceCents),
                        Formatters.currency(product.salePriceCents),
                      ),
                      maxLines: 1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Align + Flexible: o chip de ESTOQUE fica ANCORADO à direita
            // do card (não flutuando colado ao texto) e encolhe (ellipsis
            // interno) com escala de texto alta ou estoque grande.
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: StatusChip(
                  label:
                      '${Quantity.format(product.stockQuantity, unitLabel: product.vendaPorFracao ? product.unitLabel : null, language: Formatters.currentLanguage)}'
                      '${product.vendaPorFracao ? '' : ' ${l10n.commonUnits}'}',
                  color: lowStock
                      ? theme.warning
                      : theme.colorScheme.primary,
                  icon: lowStock
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                ),
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
  // W11: código de barras/PLU (5 dígitos, opcional) — usado pelas balanças
  // etiquetadoras (formato 20PPPPPWWWWW) e pelo campo do PDV.
  final _codeController = TextEditingController();

  // W11: venda por PESO (fração) + unidade de venda (kg, g, l, ml...).
  bool _vendaPorFracao = false;
  String _unitLabel = 'un';

  // W11: validade opcional do produto — o lote inicial do estoque de
  // abertura nasce com ela e o dashboard alerta quando está para expirar.
  DateTime? _expiryDate;

  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // Interpreta o preço digitado como CENTAVOS inteiros (W4).
  int _parsePrice(String value) => Money.parse(value);

  /// Abre o seletor de data de validade do produto (lote inicial W11).
  Future<void> _pickExpiry() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: l10n.productsExpiryHelp,
    );
    if (picked == null || !mounted) return;
    setState(() => _expiryDate = picked);
  }

  /// Remove a validade definida (produto não perecível).
  void _clearExpiry() {
    setState(() => _expiryDate = null);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final purchasePriceCents = _parsePrice(_purchasePriceController.text);
    final salePriceCents = _parsePrice(_salePriceController.text);
    // W11: estoque digitado em UNIDADES (ou kg) → MILÉSIMOS.
    final stockMilli = Quantity.parse(_stockController.text.trim());

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
              stockQuantity: stockMilli,
              code: _codeController.text.trim(),
              vendaPorFracao: _vendaPorFracao,
              unitLabel: _unitLabel,
            ),
            // W11: validade opcional do lote inicial (alimenta os alertas
            // de validade do dashboard: vermelho = vencido, amarelo =
            // vence em menos de 30 dias).
            expiryDate: _expiryDate,
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
              // W11: código de barras/PLU — usado pelas balanças
              // etiquetadoras (20PPPPPWWWWW) e pelo campo do PDV.
              TextFormField(
                controller: _codeController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                maxLength: 5,
                decoration: InputDecoration(
                  labelText: l10n.productsCodeLabel,
                  helperText: l10n.productsCodeHint,
                  prefixIcon: const Icon(Icons.qr_code_2_outlined),
                ),
                validator: (value) {
                  final digits = value?.trim() ?? '';
                  if (digits.isNotEmpty &&
                      !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
                    return l10n.productsCodeError;
                  }
                  return null;
                },
              ),
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.productsStockQuantity,
                  helperText: _vendaPorFracao
                      ? l10n.productsStockWeightHint
                      : null,
                  prefixIcon: const Icon(Icons.warehouse_outlined),
                ),
                validator: (value) {
                  // W11: aceita decimais (ex.: 1,75) — convertido para
                  // milésimos no submit; rejeita texto/números negativos.
                  final quantity = Quantity.parse(value?.trim() ?? '');
                  if (quantity < 0 ||
                      (value != null && value.trim().isNotEmpty && quantity == 0)) {
                    return l10n.productsStockError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // W11: validade opcional — o lote inicial do estoque de
              // abertura nasce com ela; o dashboard alerta (vermelho =
              // vencido; amarelo = vence em < 30 dias) quando expira.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickExpiry,
                      icon: const Icon(Icons.event_outlined, size: 18),
                      label: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _expiryDate == null
                              ? l10n.productsExpiryAdd
                              : '${l10n.productsExpiryLabel} · '
                                    '${Formatters.date(_expiryDate!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (_expiryDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.productsExpiryClear,
                      icon: const Icon(Icons.close),
                      onPressed: _clearExpiry,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // W11: venda por PESO (fração) — o PDV passa a aceitar
              // quantidades decimais e o código de barras de balança.
              // Material explícito: o SwitchListTile pinta o fundo e o ink no
              // Material ancestral; dentro do Container colorido do app_sheet
              // (DecoratedBox) o Flutter emite a assertion "ListTile
              // background color or ink splashes may be invisible" (mesmo
              // padrão já usado no add_transaction_sheet).
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.productsWeighLabel),
                  subtitle: Text(l10n.productsWeighHint),
                  value: _vendaPorFracao,
                  onChanged: (value) => setState(() {
                    _vendaPorFracao = value;
                    // W11: ao alternar, a unidade volta a um valor VÁLIDO da
                    // lista do dropdown (kg/g/l/ml). Se ficasse 'un' (padrão
                    // de unidade), o DropdownButtonFormField renderizaria com
                    // um valor fora dos itens e lançaria a asserção "exactly
                    // one item with value 'un'" — crash em produção.
                    _unitLabel = value ? 'kg' : 'un';
                  }),
                ),
              ),
              if (_vendaPorFracao) ...[
                DropdownButtonFormField<String>(
                  initialValue: _unitLabel,
                  decoration: InputDecoration(
                    labelText: l10n.productsUnitLabel,
                    prefixIcon: const Icon(Icons.scale_outlined),
                  ),
                  items: [
                    for (final unit in const ['kg', 'g', 'l', 'ml'])
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                  onChanged: (value) =>
                      setState(() => _unitLabel = value ?? 'kg'),
                ),
              ],
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
