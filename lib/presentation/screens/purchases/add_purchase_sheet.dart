import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../core/utils/quantity.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/sale.dart' show PaymentMethod;
import '../../../domain/usecases/add_purchase_use_case.dart';
import '../../../domain/usecases/update_product_stock_use_case.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/purchases_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/payment_method_picker.dart';
import '../../widgets/search_field.dart';
import '../../widgets/smart_amount.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../data/services/offline_sync_service.dart';

/// Carrinho de nova compra: fornecedor, produtos com steppers de quantidade
/// e VALIDADE OPCIONAL por item (cria o lote FIFO correspondente) e
/// confirmação via [ProcessPurchaseUseCase] (aumenta o estoque + saída no
/// caixa).
///
/// W11: quantidades em MILÉSIMOS; produtos por peso aceitam decimais
/// (ex.: 1,75 kg); a data de validade alimenta o lote da entrada.
class AddPurchaseSheet extends ConsumerStatefulWidget {
 const AddPurchaseSheet({super.key});

 @override
 ConsumerState<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends ConsumerState<AddPurchaseSheet> {
 final _supplierController = TextEditingController();
 final _searchController = TextEditingController();
 String _query = '';

 /// Carrinho: id do produto → quantidade em MILÉSIMOS.
 final Map<String, int> _cart = {};

 /// Validade opcional por item do carrinho (lote FIFO).
 final Map<String, DateTime?> _expiryByProduct = {};

 /// Catálogo por id — evita busca O(n) a cada interação do carrinho.
 Map<String, Product> _productsById = const {};

 // Padrão: M-Pesa (dinheiro móvel dominante em Moçambique — mesmo padrão
 // do carrinho de Vendas).
 PaymentMethod _paymentMethod = PaymentMethod.mPesa;

 bool _isSubmitting = false;
 String? _error;

 @override
 void dispose() {
 _supplierController.dispose();
 _searchController.dispose();
 super.dispose();
 }

 // Total em CENTAVOS inteiros (W4 + W11): qtd(milésimos) × preço ~/ 1000.
 int get _totalCents => _cart.entries.fold<int>(
 0,
 (sum, entry) =>
 sum +
 Quantity.lineTotal(
 entry.value,
 _productById(entry.key)?.purchasePriceCents ?? 0,
 ),
 );

 /// Contagem de itens em UNIDADES para exibição.
 int get _itemCount =>
 _cart.values.fold(0, (sum, quantity) => sum + quantity) ~/
 Quantity.milliFactor;

 Product? _productById(String id) => _productsById[id];

 void _add(Product product) {
 setState(() {
 _cart[product.id] =
 (_cart[product.id] ?? 0) + Quantity.milliFactor;
 });
 }

 void _addFraction(Product product) {
 setState(() {
 // Passo de 0,1 unidade (100 milésimos) para produtos por peso.
 _cart[product.id] = (_cart[product.id] ?? 0) + 100;
 });
 }

 void _remove(Product product) {
 final current = _cart[product.id] ?? 0;
 if (current <= 0) return;
 setState(() {
 if (current <= (product.vendaPorFracao ? 100 : Quantity.milliFactor)) {
 _cart.remove(product.id);
 _expiryByProduct.remove(product.id);
 } else {
 _cart[product.id] = current - (product.vendaPorFracao ? 100 : Quantity.milliFactor);
 }
 });
 }

 /// Define a quantidade exata (em milésimos) de um item do carrinho.
 void _setQuantity(Product product, int milli) {
 setState(() {
 if (milli <= 0) {
 _cart.remove(product.id);
 _expiryByProduct.remove(product.id);
 } else {
 _cart[product.id] = milli;
 }
 });
 }

 /// Diálogo de quantidade decimal (produtos por peso — ex.: 1,75).
 Future<void> _editFraction(Product product) async {
 final l10n = context.l10n;
 final controller = TextEditingController(
 text: Quantity.format(
 _cart[product.id] ?? 0,
 unitLabel: product.unitLabel,
 language: Formatters.currentLanguage,
 ).split(' ').first,
 );
 final result = await showDialog<String>(
 context: context,
 builder: (context) => AlertDialog(
 title: Text(product.name),
 content: AppTextField(
 controller: controller,
 autofocus: true,
 label: l10n.salesQuantityLabel,
 hintText: l10n.salesQuantityHint,
 suffixText: product.unitLabel,
 keyboardType: const TextInputType.numberWithOptions(decimal: true),
 onSubmitted: (value) => Navigator.of(context).pop(value),
 ),
 actions: [
 TextButton(
 onPressed: () => Navigator.of(context).pop(),
 child: Text(l10n.commonCancel),
 ),
 // AppButton (design system ultra-clean): altura 48, cantos 12,
 // texto w400 — a confirmação segue o padrão dos diálogos.
 AppButton.primary(
 onPressed: () => Navigator.of(context).pop(controller.text),
 label: l10n.commonConfirm,
 ),
 ],
 ),
 );
 if (result == null) return;
 final milli = Quantity.parse(result);
 if (milli > 0) _setQuantity(product, milli);
 }

 /// Abre o seletor de data de validade do item (lote FIFO).
 Future<void> _pickExpiry(Product product) async {
 final l10n = context.l10n;
 final current = _expiryByProduct[product.id];
 final now = DateTime.now();
 final picked = await showDatePicker(
 context: context,
 initialDate: current ?? now.add(const Duration(days: 30)),
 firstDate: now,
 lastDate: now.add(const Duration(days: 3650)),
 helpText: l10n.purchasesExpiryHelp,
 );
 if (picked == null || !mounted) return;
 setState(() => _expiryByProduct[product.id] = picked);
 }

 /// Remove a validade definida (produto não perecível).
 void _clearExpiry(Product product) {
 setState(() => _expiryByProduct.remove(product.id));
 }

 Future<void> _confirm() async {
 final l10n = context.l10n;

 if (_supplierController.text.trim().isEmpty) {
 setState(() => _error = l10n.purchasesSupplierError);
 return;
 }

 setState(() {
 _isSubmitting = true;
 _error = null;
 });

 final products = ref.read(productsProvider).value ?? const <Product>[];
 final productsById = {for (final product in products) product.id: product};

 final items = <PurchaseItem>[];
 for (final entry in _cart.entries) {
 final product = productsById[entry.key];
 if (product == null) {
 // Desfaz o loading antes de sair (o finally do try não cobre este
 // caminho).
 setState(() {
 _isSubmitting = false;
 _error = l10n.purchasesCartItemUnavailable;
 });
 return;
 }
 items.add(
 PurchaseItem(
 productId: product.id,
 productName: product.name,
 quantity: entry.value,
 unitPriceCents: product.purchasePriceCents,
 // W11: validade opcional — o lote FIFO da entrada nasce com ela.
 expiryDate: _expiryByProduct[product.id],
 ),
 );
 }

 // A compra pertence à loja ativa (a entrada de estoque é por loja).
 final user = ref.read(authStateProvider).value;
 final storeId = user == null
 ? null
 : ref.read(activeStoreIdProvider(user.id));

 final purchase = Purchase(
 id: AppIds.newId('pc'),
 storeId: storeId ?? 'st1',
 supplierName: _supplierController.text.trim(),
 items: items,
 totalAmountCents: _totalCents,
 paymentMethod: _paymentMethod,
 dateTime: DateTime.now(),
 );

 final messenger = ScaffoldMessenger.of(context);
 final navigator = Navigator.of(context);

 try {
 // ProcessPurchaseUseCase registra a compra, cria os lotes FIFO,
 // aumenta o estoque e lança a saída no caixa.
 await ref.read(processPurchaseUseCaseProvider).call(purchase);

 if (!mounted) return;
 navigator.pop();
 messenger.showSnackBar(
 SnackBar(
 content: Text(
 l10n.purchasesRegistered(Formatters.currency(purchase.totalAmountCents)),
 ),
 ),
 );
 } on OfflineEnqueuedException {
 // Sem conexão: a compra foi ENFILEIRADA (outbox) e será sincronizada.
 if (!mounted) return;
 navigator.pop();
 messenger.showSnackBar(SnackBar(content: Text(l10n.syncOfflineSaved)));
 } on ProductNotFoundException catch (error) {
 setState(() {
 _error = l10n.purchasesProductNotFound(error.productId);
 });
 } catch (error, stackTrace) {
 CrashReporting.capture(
 error,
 stackTrace,
 hint: 'Erro ao registrar compra',
 );
 setState(() {
 _error = l10n.purchasesRegisterError;
 });
 } finally {
 if (mounted) setState(() => _isSubmitting = false);
 }
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final productsAsync = ref.watch(productsProvider);
 // Mantém o catálogo por id em sincronia com o provider.
 _productsById = {
 for (final product in productsAsync.value ?? const <Product>[])
 product.id: product,
 };

 final bottomInset = MediaQuery.of(context).viewInsets.bottom;
 return ConstrainedBox(
 constraints: BoxConstraints(
 maxHeight: MediaQuery.sizeOf(context).height - bottomInset - 24,
 ),
 child: Column(
 children: [
 AppSheetHeader(title: l10n.purchasesAddNew),
 Padding(
 padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
 child: AppTextField(
 controller: _supplierController,
 textInputAction: TextInputAction.next,
 label: l10n.purchasesSupplierLabel,
 prefixIcon: Icons.local_shipping_outlined,
 ),
 ),
 Padding(
 padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
 child: SearchField(
 controller: _searchController,
 hintText: l10n.productsSearchHint,
 onChanged: (value) => setState(() => _query = value.trim()),
 ),
 ),
 Expanded(
 child: productsAsync.when(
 loading: () => const Center(child: CircularProgressIndicator()),
 error: (_, _) => Center(
 child: Text(
 l10n.productsLoadError,
 style: theme.textTheme.bodyMedium,
 ),
 ),
 data: (all) {
 // Só produtos ATIVOS (desativado não pode ser reposto — o
 // servidor também nega via lock_products_or_raise).
 final active = all
 .where((product) => product.isActive)
 .toList();
 // Query NORMALIZADO para minúsculas (mesmo padrão da busca
 // de Produtos): sem isso, digitar 'CANETA' não achava o
 // produto na compra.
 final query = _query.toLowerCase();
 final filtered = _query.isEmpty
 ? active
 : active
 .where(
 (product) =>
 product.name.toLowerCase().contains(query),
 )
 .toList();

 if (filtered.isEmpty) {
 return EmptyState(
 icon: Icons.search_off,
 title: l10n.purchasesNoProductsTitle,
 subtitle: l10n.purchasesNoProductsSubtitle,
 );
 }

 return ListView.separated(
 padding: const EdgeInsets.symmetric(horizontal: 24),
 itemCount: filtered.length,
 separatorBuilder: (_, _) => const SizedBox(height: 6),
 itemBuilder: (context, index) => _CartProductRow(
 product: filtered[index],
 quantity: _cart[filtered[index].id] ?? 0,
 expiry: _expiryByProduct[filtered[index].id],
 onAdd: () => _add(filtered[index]),
 onAddFraction: () => _addFraction(filtered[index]),
 onRemove: () => _remove(filtered[index]),
 onEdit: () => _editFraction(filtered[index]),
 onPickExpiry: () => _pickExpiry(filtered[index]),
 onClearExpiry: () => _clearExpiry(filtered[index]),
 ),
 );
 },
 ),
 ),
 // Rodapé: total + confirmar
 Container(
 decoration: BoxDecoration(
 color: theme.colorScheme.surface,
 border: Border(
 top: BorderSide(color: theme.colorScheme.outlineVariant),
 ),
 ),
 padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
 // O rodapé é COMPACTO (alturas calibradas) para caber junto com
 // o catálogo mesmo em sheets baixos/paisagem — o Expanded do
 // catálogo é o que encolhe primeiro.
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 // Forma de pagamento do fornecedor — MESMO seletor do
 // carrinho de Vendas (abas segmentadas + lista com radio).
 PaymentMethodPicker(
 value: _paymentMethod,
 onChanged: (method) =>
 setState(() => _paymentMethod = method),
 ),
 const SizedBox(height: 8),
 Row(
 children: [
 Expanded(
 child: Text(
 l10n.dashboardSaleItems(_itemCount),
 style: theme.textTheme.bodyMedium?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 ),
 // Total do carrinho em destaque (22) — SmartAmount:
 // o valor encolhe para SEMPRE caber, sem truncar nem
 // estourar o rodapé em telas estreitas.
 Flexible(
 child: SmartAmount(
 cents: _totalCents,
 alignment: Alignment.centerRight,
 style: theme.textTheme.titleLarge?.copyWith(
 color: theme.colorScheme.primary,
 ),
 ),
 ),
 ],
 ),
 if (_error != null) ...[
 const SizedBox(height: 6),
 Text(
 _error!,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.error,
 ),
 ),
 ],
 const SizedBox(height: 8),
 // AppButton ultra-clean: altura 48, cantos 12, texto w400.
 AppButton.primary(
 label: l10n.purchasesConfirm,
 onPressed: _cart.isEmpty || _isSubmitting ? null : _confirm,
 icon: _isSubmitting
 ? const SizedBox(
 height: 18,
 width: 18,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : const Icon(Icons.check, size: 20),
 ),
 ],
 ),
 ),
 ],
 ),
 );
 }
}

/// Linha do produto no carrinho de compra com stepper de quantidade e
/// VALIDADE opcional (lote FIFO).
class _CartProductRow extends StatelessWidget {
 const _CartProductRow({
 required this.product,
 required this.quantity,
 required this.expiry,
 required this.onAdd,
 required this.onAddFraction,
 required this.onRemove,
 required this.onEdit,
 required this.onPickExpiry,
 required this.onClearExpiry,
 });

 final Product product;
 final int quantity;
 final DateTime? expiry;
 final VoidCallback onAdd;
 final VoidCallback onAddFraction;
 final VoidCallback onRemove;
 final VoidCallback onEdit;
 final VoidCallback onPickExpiry;
 final VoidCallback onClearExpiry;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final isWeight = product.vendaPorFracao;

 // Card premium (estilo Apple): cantos 18, superfície elevada — a linha
 // do carrinho segue o padrão das listas principais.
 return AppCard(
 elevated: true,
 borderRadius: const BorderRadius.all(Radius.circular(18)),
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
 child: Row(
 children: [
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Nome COMPLETO do produto — quebra em linhas quando
 // necessário (nada de truncar nomes no carrinho).
 Text(
 product.name,
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w500,
 ),
 ),
 const SizedBox(height: 2),
 Text(
 '${Formatters.currency(product.purchasePriceCents)} · '
 '${l10n.purchasesStockLabel(
 Quantity.toUnits(product.stockQuantity).round(),
 l10n.commonUnits,
 )}',
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 // Validade definida (lote FIFO da entrada).
 if (expiry != null) ...[
 const SizedBox(height: 4),
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 Icons.event_available_outlined,
 size: 14,
 color: theme.colorScheme.primary,
 ),
 const SizedBox(width: 4),
 Flexible(
 child: Text(
 '${l10n.purchasesExpiryLabel} '
 '${Formatters.date(expiry!)}',
 // Quebra em até 2 linhas — a data nunca é cortada.
 maxLines: 2,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.primary,
 ),
 ),
 ),
 // IconButton com tooltip + alvo de toque de 32px
 // (mesmo padrão do _ExpiryField de Produtos) — o
 // antigo InkWell de ~17px era um alvo minúsculo sem
 // semântica.
 IconButton(
 tooltip: l10n.productsExpiryClear,
 icon: const Icon(Icons.close, size: 16),
 visualDensity: VisualDensity.compact,
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(
 minWidth: 32,
 minHeight: 32,
 ),
 onPressed: onClearExpiry,
 ),
 ],
 ),
 ],
 ],
 ),
 ),
 Column(
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 IconButton(
 visualDensity: VisualDensity.compact,
 icon: const Icon(Icons.event_outlined, size: 18),
 tooltip: l10n.purchasesExpiryAdd,
 onPressed: onPickExpiry,
 ),
 Container(
 decoration: BoxDecoration(
 color: theme.colorScheme.surfaceContainerHighest,
 borderRadius: BorderRadius.circular(999),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 IconButton(
 visualDensity: VisualDensity.compact,
 icon: const Icon(Icons.remove, size: 18),
 onPressed: quantity == 0 ? null : onRemove,
 ),
 InkWell(
 onTap: isWeight ? onEdit : null,
 borderRadius: BorderRadius.circular(8),
 child: Padding(
 padding: const EdgeInsets.symmetric(
 horizontal: 6,
 vertical: 8,
 ),
 child: Text(
 Quantity.format(
 quantity,
 unitLabel: isWeight ? product.unitLabel : null,
 language: Formatters.currentLanguage,
 ),
 textAlign: TextAlign.center,
 style: theme.textTheme.labelLarge,
 ),
 ),
 ),
 IconButton(
 visualDensity: VisualDensity.compact,
 icon: const Icon(Icons.add, size: 18),
 onPressed: isWeight ? onAddFraction : onAdd,
 ),
 ],
 ),
 ),
 ],
 ),
 ],
 ),
 ],
 ),
 );
 }
}
