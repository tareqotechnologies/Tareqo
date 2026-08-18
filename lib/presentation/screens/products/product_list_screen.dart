import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../widgets/product_image.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
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
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/list_skeleton.dart';
import '../../widgets/search_field.dart';
import '../../widgets/smart_amount.dart';
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

 /// Filtro rápido (design system 2026 — botão de filtro no AppBar):
 /// Todos / Estoque baixo / Inativos. Sempre começa em Todos.
 _ProductFilter _filter = _ProductFilter.all;

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

 Future<void> _openEditSheet(Product product) async {
 await showAppSheet<void>(
 context,
 builder: (_) => _EditProductSheet(product: product),
 );
 if (!mounted) return;
 ref.invalidate(productsProvider);
 ref.invalidate(dashboardKpisProvider);
 }

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final productsAsync = ref.watch(productsProvider);
 final l10n = context.l10n;
 // Funcionário comum NÃO cria produto (só vende): o cadastro fica para
 // dono e gerente (matriz de acesso). O servidor também restringe o
 // INSERT (política products_insert via is_my_store do dono/gerente).
 final canManageProducts =
 ref.watch(currentAccessLevelProvider) != UserAccessLevel.employee;

 return Scaffold(
 // AppBar estilo iOS large title — mesmo padrão das demais telas.
 appBar: AppBar(
 toolbarHeight: 64,
 titleSpacing: 20,
 title: Text(
 l10n.appNavProducts,
 style: theme.textTheme.headlineSmall?.copyWith(
 fontWeight: FontWeight.w500,
 letterSpacing: -0.5,
 ),
 ),
 ),
 // CTA único: sem produtos, o FAB some — o estado vazio traz o botão
 // de cadastro centralizado (mantendo a regra canManageProducts).
 // FAB CIRCULAR verde (design system 2026 — igual ao app de
 // referência, que mostra apenas o sinal de +).
    floatingActionButton:
        canManageProducts
            ? FloatingActionButton(
                heroTag: 'fab-products',
                onPressed: _openAddSheet,
                tooltip: l10n.productsAddNew,
                child: const Icon(Icons.add),
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
 // Chips de filtro visíveis (canvas V3): Todos · N / Estoque
 // baixo · N / Inativos — a contagem real ao lado do rótulo, em
 // vez do menu escondido no AppBar.
 Padding(
 padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
 child: Align(
 alignment: Alignment.centerLeft,
 child: _FilterChips(
 filter: _filter,
 counts: (
 all: productsAsync.value?.length ?? 0,
 lowStock: (productsAsync.value ?? const [])
 .where(
 (p) =>
 p.isActive &&
 p.stockQuantity <
 Quantity.lowStockThresholdUnits *
 Quantity.milliFactor,
 )
 .length,
 ),
 onSelected: (value) => setState(() => _filter = value),
 ),
 ),
 ),
 Expanded(
 child: productsAsync.when(
 // Skeleton no primeiro carregamento (padrão das listas).
 loading: () => const ListSkeleton(),
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
 actionLabel: canManageProducts ? l10n.productsAddNew : null,
 onAction: canManageProducts ? _openAddSheet : null,
 );
 }

 // Query NORMALIZADO para minúsculas: sem isso, digitar
 // 'CANETA' não achava 'Caneta Azul' (o nome era convertido,
 // o termo digitado não).
 final query = _query.toLowerCase();
 final filtered = products.where((product) {
 final matchesQuery =
 query.isEmpty ||
 product.name.toLowerCase().contains(query) ||
 product.description.toLowerCase().contains(query);
 final matchesFilter = switch (_filter) {
 _ProductFilter.all => true,
 _ProductFilter.lowStock =>
 product.isActive &&
 product.stockQuantity <
 Quantity.lowStockThresholdUnits *
 Quantity.milliFactor,
 _ProductFilter.inactive => !product.isActive,
 };
 return matchesQuery && matchesFilter;
 }).toList();

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
 // Folha única estilo Home (FeedCard): um só card com os
 // produtos como linhas separadas por divisórias hairline.
 child: ListView(
 padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
 physics: const AlwaysScrollableScrollPhysics(),
 children: [
 FeedCard(
 rows: [
 for (final product in filtered)
 _ProductTile(
 product: product,
 // Edição é operação de gestão (dono/gerente):
 // o tile só é tocável para quem pode gerir.
 onTap: canManageProducts
 ? () => _openEditSheet(product)
 : null,
 ),
 ],
 ),
 ],
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

/// Filtro rápido da listagem (canvas V3 — chips VISÍVEIS com contagem,
/// em vez do menu escondido): Todos · N / Estoque baixo · N / Inativos.
enum _ProductFilter {
 all,
 lowStock,
 inactive;

 IconData get icon => switch (this) {
 _ProductFilter.all => Icons.inventory_2_outlined,
 _ProductFilter.lowStock => Icons.warning_amber_rounded,
 _ProductFilter.inactive => Icons.block_outlined,
 };

 String label(AppLocalizations l10n) => switch (this) {
 // Rótulos PRÓPRIOS do filtro: "Todos" (não o "Tudo" do período —
 // neutro, soa estranho) e "Inativos" (plural — o selo do tile
 // continua "Inativo", singular: descreve UM produto; o filtro é
 // uma categoria que abrange vários).
 _ProductFilter.all => l10n.productsFilterAll,
 _ProductFilter.lowStock => l10n.dashboardLowStock,
 _ProductFilter.inactive => l10n.productsFilterInactive,
 };
}

/// Chips de filtro (canvas V3): pílulas com rótulo + contagem real — o
/// ativo usa o container verde (primaryContainer), os inativos neutros.
class _FilterChips extends StatelessWidget {
 const _FilterChips({
 required this.filter,
 required this.counts,
 required this.onSelected,
 });

 final _ProductFilter filter;

 /// (total de produtos ativos, total em estoque baixo).
 final ({int all, int lowStock}) counts;
 final ValueChanged<_ProductFilter> onSelected;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final scheme = theme.colorScheme;

 Widget chip({required _ProductFilter value, required String label}) {
 final selected = filter == value;
 return Padding(
 padding: const EdgeInsets.only(right: 8),
 child: Material(
 color: selected
 ? scheme.primaryContainer
 : scheme.surfaceContainerLow,
 borderRadius: BorderRadius.circular(999),
 child: InkWell(
 onTap: () => onSelected(value),
 borderRadius: BorderRadius.circular(999),
 child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(999),
 border: Border.all(
 color: selected
 ? scheme.primary.withValues(alpha: 0.5)
 : scheme.outlineVariant,
 ),
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 Icon(
 value.icon,
 size: 14,
 color: selected ? scheme.primary : scheme.onSurfaceVariant,
 ),
 const SizedBox(width: 6),
 Text(
 label,
 style: theme.textTheme.labelMedium?.copyWith(
 color: selected
 ? scheme.onPrimaryContainer
 : scheme.onSurfaceVariant,
 fontWeight: selected ? FontWeight.w500 : FontWeight.w500,
 ),
 ),
 ],
 ),
 ),
 ),
 ),
 );
 }

 return SingleChildScrollView(
 scrollDirection: Axis.horizontal,
 child: Row(
 children: [
 chip(
 value: _ProductFilter.all,
 label: l10n.productsFilterAllCount(counts.all),
 ),
 chip(
 value: _ProductFilter.lowStock,
 label: l10n.productsFilterLowCount(counts.lowStock),
 ),
 chip(
 value: _ProductFilter.inactive,
 label: l10n.productsFilterInactive,
 ),
 ],
 ),
 );
 }
}

/// Linha do card de produto (estilo Apple): foto, nome + detalhe à
/// esquerda; preço de venda + estoque à direita — com divisória fina vinda
/// do separador da lista. Tocável para dono/gerente (abre a edição); o
/// produto INATIVO ganha o selo "Inativo" e o nome fica esmaecido.
class _ProductTile extends StatelessWidget {
 const _ProductTile({required this.product, this.onTap});

 final Product product;

 /// `null` para funcionário comum (só vende — não edita produtos).
 final VoidCallback? onTap;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 // W11: o estoque vive em MILÉSIMOS — o limiar de estoque baixo e a
 // exibição convertem para unidades (5 unidades).
 final lowStock =
 product.stockQuantity <
 Quantity.lowStockThresholdUnits * Quantity.milliFactor;
 final inactive = !product.isActive;

 // Detalhe sob o nome (canvas: SKU). O app não tem campo SKU próprio —
 // usa o código de barras/PLU quando existe (mesma função de
 // identificação rápida).
 final detail = product.code.isEmpty
 ? (product.description.isEmpty ? null : product.description)
 : product.code;

 // Linha do feed (estilo Home): transparente dentro da [FeedCard] — o
 // ripple cobre a linha; tocável apenas para quem pode gerir produtos.
 final content = Padding(
 padding: const EdgeInsets.symmetric(
 horizontal: AppSpacing.md,
 vertical: AppSpacing.sm + 2,
 ),
 child: Row(
 children: [
 // Foto do produto (fallback: ícone) — identifica o produto no
 // rolodex (dado real, mantido do design anterior).
 ProductImage(imagePath: product.imagePath, size: 40, radius: 10),
 const SizedBox(width: 12),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 // Nome COMPLETO do produto — quebra em linhas quando
 // necessário (nada de truncar nomes no rolodex).
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: inactive ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
 if (detail != null) ...[
 const SizedBox(height: 2),
 // Detalhe (código/PLU ou descrição) — trunca com
 // ellipsis (dado secundário; o nome nunca trunca).
 Text(
 detail,
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 fontFeatures: const [FontFeature.tabularFigures()],
 ),
 ),
 ],
 // Produto INATIVO: selo "Inativo" — não pode ser vendido
 // nem reposto até a reativação.
 if (inactive) ...[
 const SizedBox(height: 4),
 StatusChip(
 label: l10n.productsInactive,
 color: theme.colorScheme.outline,
 icon: Icons.block_outlined,
 ),
 ],
 ],
 ),
 ),
 const SizedBox(width: 12),
 // Coluna direita: preço de venda em destaque + estoque por
 // baixo, alinhados à direita. Flexible: com escala de texto alta
 // a coluna encolhe e o FittedBox do preço escala para caber.
 Flexible(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 // Preço de venda (semibold, tabular) — FittedBox: ENCOLHE
 // com escala de texto alta em vez de estourar (numa Column
 // vertical de lista, flex vertical é inválido).
 FittedBox(
 fit: BoxFit.scaleDown,
 alignment: Alignment.centerRight,
 child: SmartAmount(
 cents: product.salePriceCents,
 alignment: Alignment.centerRight,
 style: theme.textTheme.bodyMedium?.copyWith(
 fontWeight: FontWeight.w500,
 color: inactive
 ? theme.colorScheme.onSurfaceVariant
 : null,
 fontFeatures: const [FontFeature.tabularFigures()],
 ),
 ),
 ),
 const SizedBox(height: 2),
 // Estoque: vermelho quando baixo, neutro caso contrário.
 Text(
 '${Quantity.format(product.stockQuantity, unitLabel: product.vendaPorFracao ? product.unitLabel : null, language: Formatters.currentLanguage)}'
 '${product.vendaPorFracao ? '' : ' ${l10n.commonUnits}'}',
 maxLines: 1,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.bodySmall?.copyWith(
 color: lowStock
 ? theme.expense
 : theme.colorScheme.onSurfaceVariant,
 fontWeight: lowStock ? FontWeight.w500 : null,
 fontFeatures: const [FontFeature.tabularFigures()],
 ),
 ),
 ],
 ),
 ),
 ],
 ),
 );

 if (onTap == null) return content;
 return InkWell(onTap: onTap, child: content);
 }
}

/// Bottom sheet de cadastro de produto.
/// Seletor de foto do produto (design system ultra-clean): preview
/// quadrado arredondado + botões Câmera/Galeria + ação de remover.
/// [bytes] = foto NOVA escolhida (ainda não enviada); [imagePath] = foto
/// atual persistida (modo edição).
class _ProductPhotoPicker extends StatelessWidget {
 const _ProductPhotoPicker({
 required this.bytes,
 required this.imagePath,
 required this.onTakePhoto,
 required this.onPickGallery,
 required this.onRemove,
 });

 final Uint8List? bytes;
 final String imagePath;
 final VoidCallback onTakePhoto;
 final VoidCallback onPickGallery;
 final VoidCallback onRemove;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final l10n = context.l10n;
 final hasImage = bytes != null || imagePath.isNotEmpty;

 final preview = bytes != null
 ? ClipRRect(
 borderRadius: BorderRadius.circular(16),
 child: Image.memory(
 bytes!,
 width: 76,
 height: 76,
 fit: BoxFit.cover,
 ),
 )
 : ProductImage(imagePath: imagePath, size: 76, iconSize: 30);

 return Row(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 // Preview maior (76) com borda sutil — destaque discreto da foto.
 Container(
 decoration: BoxDecoration(
 borderRadius: BorderRadius.circular(16),
 border: Border.all(
 color: theme.colorScheme.outlineVariant,
 width: 1,
 ),
 ),
 child: preview,
 ),
 const SizedBox(width: 16),
 Expanded(
 child: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(
 l10n.productsPhotoLabel,
 style: theme.textTheme.bodySmall?.copyWith(
 color: theme.colorScheme.onSurfaceVariant,
 ),
 ),
 const SizedBox(height: 10),
 Row(
 children: [
 Expanded(
 child: OutlinedButton.icon(
 onPressed: onTakePhoto,
 icon: const Icon(Icons.photo_camera_outlined, size: 18),
 label: Text(l10n.productsPhotoTake),
 style: OutlinedButton.styleFrom(
 minimumSize: const Size.fromHeight(44),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 ),
 ),
 const SizedBox(width: 8),
 Expanded(
 child: OutlinedButton.icon(
 onPressed: onPickGallery,
 icon: const Icon(Icons.photo_library_outlined, size: 18),
 label: Text(l10n.productsPhotoGallery),
 style: OutlinedButton.styleFrom(
 minimumSize: const Size.fromHeight(44),
 shape: RoundedRectangleBorder(
 borderRadius: BorderRadius.circular(12),
 ),
 ),
 ),
 ),
 ],
 ),
 if (hasImage) ...[
 const SizedBox(height: 8),
 TextButton.icon(
 onPressed: onRemove,
 icon: const Icon(Icons.delete_outline, size: 16),
 label: Text(l10n.productsPhotoRemove),
 style: TextButton.styleFrom(
 foregroundColor: theme.colorScheme.error,
 visualDensity: VisualDensity.compact,
 padding: EdgeInsets.zero,
 ),
 ),
 ],
 ],
 ),
 ),
 ],
 );
 }
}

/// Rótulo de seção do formulário (design system ultra-clean): pequeno
/// rótulo com letter-spacing e o ícone da seção em acento — hierarquia
/// sutil que organiza os campos sem pesar visualmente.
class _SectionLabel extends StatelessWidget {
 const _SectionLabel({required this.icon, required this.title});

 final IconData icon;  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        // Capitalização NATURAL (nunca caixa alta): rótulos de seção
        // legíveis, sem o grito visual de letras maiúsculas.
        // FittedBox: encolhe em vez de estourar em telas estreitas.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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

 // Foto do produto: bytes da foto NOVA escolhida (câmera/galeria) —
 // enviada ao storage no submit; `null` = nenhuma foto nova.
 Uint8List? _imageBytes;

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

 /// Captura/pick de foto (câmera ou galeria) — comprimida na origem
 /// (1024px, JPEG 80) para uploads leves.
 Future<void> _pickPhoto(ImageSource source) async {
 final picked = await ImagePicker().pickImage(
 source: source,
 maxWidth: 1024,
 maxHeight: 1024,
 imageQuality: 80,
 );
 if (picked == null || !mounted) return;
 final bytes = await picked.readAsBytes();
 if (!mounted) return;
 setState(() => _imageBytes = bytes);
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

 // Foto: sobe a imagem (se houver) ANTES de persistir o produto e
 // guarda a referência (URL/caminho) em Product.imagePath.
 //
 // A foto é OPCIONAL — se o upload falhar (ex.: storage sem permissão
 // no servidor), o produto é salvo mesmo assim com aviso, em vez de
 // bloquear o cadastro inteiro (regressão 403 RLS no live).
 var uploadedImagePath = '';
 var photoFailed = false;
 try {
 final productId = AppIds.newId('p');
 final effectiveStoreId = storeId ?? 'st1';
 final bytes = _imageBytes;
 if (bytes != null) {
 try {
 uploadedImagePath = await ref
 .read(productImageStoreProvider)
 .saveImage(
 productId: productId,
 storeId: effectiveStoreId,
 bytes: bytes,
 );
 } catch (error, stackTrace) {
 photoFailed = true;
 CrashReporting.capture(
 error,
 stackTrace,
 hint: 'Foto não enviada ao adicionar produto',
 );
 }
 }

 await ref
 .read(addProductUseCaseProvider)
 .call(
 Product(
 id: productId,
 storeId: effectiveStoreId,
 name: _nameController.text.trim(),
 description: _descriptionController.text.trim(),
 imagePath: uploadedImagePath,
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
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 photoFailed ? l10n.productsAddedNoPhoto : l10n.productsAdded,
 ),
 ),
 );
 } on InvalidPriceException catch (error) {
 setState(() => _formError = error.message);
 } catch (error, stackTrace) {
 // Upload feito mas o produto não persistiu → remove a foto órfã
 // (best-effort — nunca deixa imagem sem produto no storage).
 if (uploadedImagePath.isNotEmpty) {
 unawaited(
 ref.read(productImageStoreProvider).deleteImage(uploadedImagePath),
 );
 }
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
 // FOTO — seção própria no topo (preview + câmera/galeria).
 const SizedBox(height: 16),
 _ProductPhotoPicker(
 bytes: _imageBytes,
 imagePath: '',
 onTakePhoto: () => _pickPhoto(ImageSource.camera),
 onPickGallery: () => _pickPhoto(ImageSource.gallery),
 onRemove: () => setState(() => _imageBytes = null),
 ),
 const SizedBox(height: 24),
 // INFORMAÇÕES — identidade do produto.
 _SectionLabel(
 icon: Icons.inventory_2_outlined,
 title: l10n.productsSectionInfo,
 ),
 const SizedBox(height: 10),
 AppTextField(
 controller: _nameController,
 textInputAction: TextInputAction.next,
 label: l10n.loginNameLabel,
 prefixIcon: Icons.inventory_2_outlined,
 validator: (value) => (value == null || value.trim().isEmpty)
 ? l10n.productsNameError
 : null,
 ),
 const SizedBox(height: 12),
 AppTextField(
 controller: _descriptionController,
 textInputAction: TextInputAction.next,
 label: l10n.productsDescriptionLabel,
 prefixIcon: Icons.notes_outlined,
 ),
 const SizedBox(height: 12),
 // W11: código de barras/PLU — usado pelas balanças
 // etiquetadoras (20PPPPPWWWWW) e pelo campo do PDV.
 AppTextField(
 controller: _codeController,
 textInputAction: TextInputAction.next,
 keyboardType: TextInputType.number,
 maxLength: 5,
 label: l10n.productsCodeLabel,
 helperText: l10n.productsCodeHint,
 prefixIcon: Icons.qr_code_2_outlined,
 validator: (value) {
 final digits = value?.trim() ?? '';
 if (digits.isNotEmpty &&
 !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
 return l10n.productsCodeError;
 }
 return null;
 },
 ),
 const SizedBox(height: 24),
 // PREÇOS — compra e venda lado a lado.
 _SectionLabel(
 icon: Icons.payments_outlined,
 title: l10n.productsSectionPricing,
 ),
 const SizedBox(height: 10),
 Row(
 children: [
 Expanded(
 child: AppTextField(
 controller: _purchasePriceController,
 keyboardType: TextInputType.number,
 // Sem prefixIcon: campo de MEIA largura — com ícone
 // (48px) o label flutuante 'Purchase price' ainda
 // comprimiria (o tema já o deixou em 13px — labels
 // discretos globais, app_theme). Ícone propositalmente
 // fora para a fileira de preços não apertar.
 label: l10n.productsPurchasePrice,
 validator: (value) => _parsePrice(value ?? '') <= 0
 ? l10n.productsPurchasePriceError
 : null,
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: AppTextField(
 controller: _salePriceController,
 keyboardType: TextInputType.number,
 label: l10n.productsSalePrice,
 validator: (value) => _parsePrice(value ?? '') <= 0
 ? l10n.productsSalePriceError
 : null,
 ),
 ),
 ],
 ),
 const SizedBox(height: 24),
 // ESTOQUE — quantidade + validade + venda por peso.
 _SectionLabel(
 icon: Icons.warehouse_outlined,
 title: l10n.productsSectionStock,
 ),
 const SizedBox(height: 10),
 AppTextField(
 controller: _stockController,
 keyboardType: const TextInputType.numberWithOptions(
 decimal: true,
 ),
 label: l10n.productsStockQuantity,
 helperText: _vendaPorFracao
 ? l10n.productsStockWeightHint
 : null,
 prefixIcon: Icons.warehouse_outlined,
 validator: (value) {
 // W11: aceita decimais (ex.: 1,75) — convertido para
 // milésimos no submit; rejeita texto/números negativos.
 final quantity = Quantity.parse(value?.trim() ?? '');
 if (quantity < 0 ||
 (value != null &&
 value.trim().isNotEmpty &&
 quantity == 0)) {
 return l10n.productsStockError;
 }
 return null;
 },
 ),
 const SizedBox(height: 4),
 // W11: validade opcional — o lote inicial do estoque de
 // abertura nasce com ela; o dashboard alerta (vermelho =
 // vencido; amarelo = vence em < 30 dias) quando expira.
 // Seletor MINIMALISTA: um único campo no padrão dos demais
 // inputs (borda sutil + ícone), sem botão largo separado.
 _ExpiryField(
 expiryDate: _expiryDate,
 onPick: _pickExpiry,
 onClear: _clearExpiry,
 ),
 const SizedBox(height: 4),
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
 if (_vendaPorFracao) ...[DropdownButtonFormField<String>(
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
              AppButton.primary(
                label: l10n.productsAddSubmit,
 onPressed: _isSubmitting ? null : _submit,
 icon: _isSubmitting
 ? const SizedBox(
 height: 20,
 width: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : null,
 ),
 ],
 ),
 ),
 ),
 );
 }
}

/// Bottom sheet de EDIÇÃO de produto — dono/gerente altera nome,
/// descrição, código/PLU, preços, venda por peso, estoque (AJUSTE MANUAL:
/// cria/consome lotes FIFO) e o status ativo (desativar tira o produto do
/// PDV e das compras; o estoque é preservado para a reativação).
class _EditProductSheet extends ConsumerStatefulWidget {
 const _EditProductSheet({required this.product});

 final Product product;

 @override
 ConsumerState<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends ConsumerState<_EditProductSheet> {
 final _formKey = GlobalKey<FormState>();
 late final TextEditingController _nameController;
 late final TextEditingController _descriptionController;
 late final TextEditingController _purchasePriceController;
 late final TextEditingController _salePriceController;
 late final TextEditingController _stockController;
 late final TextEditingController _codeController;

 late bool _vendaPorFracao;
 late String _unitLabel;
 late bool _isActive;

 // Foto do produto: bytes da foto NOVA escolhida, referência ATUAL
 // persistida e referência de uma foto REMOVIDA (apagada no submit).
 Uint8List? _imageBytes;
 late String _imagePath = widget.product.imagePath;
 String _removedImagePath = '';

 bool _isSubmitting = false;
 String? _formError;

 Product get _product => widget.product;

 @override
 void initState() {
 super.initState();
 // Pré-preenche com os valores atuais (a edição nunca parte em branco).
 _nameController = TextEditingController(text: _product.name);
 _descriptionController = TextEditingController(text: _product.description);
 // Pré-preenche com o valor SEM símbolo ("13.90") — o Money.parse
 // aceita vírgula ou ponto, então o texto volta ao banco como centavos.
 _purchasePriceController = TextEditingController(
 text: Money.toReais(_product.purchasePriceCents).toStringAsFixed(2),
 );
 _salePriceController = TextEditingController(
 text: Money.toReais(_product.salePriceCents).toStringAsFixed(2),
 );
 _stockController = TextEditingController(
 text: Quantity.format(
 _product.stockQuantity,
 unitLabel: _product.vendaPorFracao ? _product.unitLabel : null,
 language: Formatters.currentLanguage,
 ).split(' ').first,
 );
 _codeController = TextEditingController(text: _product.code);
 _vendaPorFracao = _product.vendaPorFracao;
 _unitLabel = _product.vendaPorFracao ? _product.unitLabel : 'un';
 _isActive = _product.isActive;
 }

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

 /// Captura/pick de foto (câmera ou galeria) — comprimida na origem
 /// (1024px, JPEG 80) para uploads leves.
 Future<void> _pickPhoto(ImageSource source) async {
 final picked = await ImagePicker().pickImage(
 source: source,
 maxWidth: 1024,
 maxHeight: 1024,
 imageQuality: 80,
 );
 if (picked == null || !mounted) return;
 final bytes = await picked.readAsBytes();
 if (!mounted) return;
 setState(() => _imageBytes = bytes);
 }

 /// Remove a foto: anota a referência atual para apagar no submit e
 /// limpa preview/estado.
 void _removePhoto() {
 setState(() {
 _removedImagePath = _imagePath;
 _imagePath = '';
 _imageBytes = null;
 });
 }

 Future<void> _submit() async {
 if (!_formKey.currentState!.validate()) return;

 setState(() {
 _isSubmitting = true;
 _formError = null;
 });

 final l10n = context.l10n;

 // Foto: sobe a imagem NOVA (se houver) ANTES de persistir; apaga a
 // imagem REMOVIDA (best-effort). O objeto/arquivo tem o MESMO caminho
 // por produto, então substituir não deixa órfão.
 //
 // A foto é OPCIONAL — se o upload falhar (ex.: storage sem permissão
 // no servidor), o produto é salvo mesmo assim com aviso, em vez de
 // bloquear a edição inteira (regressão 403 RLS no live).
 var uploadedImagePath = '';
 var photoFailed = false;
 try {
 final store = ref.read(productImageStoreProvider);
 final bytes = _imageBytes;
 final String imagePath;
 if (bytes != null) {
 try {
 uploadedImagePath = await store.saveImage(
 productId: _product.id,
 storeId: _product.storeId,
 bytes: bytes,
 );
 } catch (error, stackTrace) {
 photoFailed = true;
 CrashReporting.capture(
 error,
 stackTrace,
 hint: 'Foto não enviada ao editar produto',
 );
 }
 if (uploadedImagePath.isNotEmpty &&
 _removedImagePath.isNotEmpty &&
 _removedImagePath != uploadedImagePath) {
 unawaited(store.deleteImage(_removedImagePath));
 }
 // Falhou o upload → mantém a foto ATUAL (não apaga a existente);
 // a edição segue sem foto nova, com aviso no snackbar.
 imagePath = photoFailed && _imagePath.isNotEmpty
 ? _imagePath
 : uploadedImagePath;
 } else if (_removedImagePath.isNotEmpty) {
 unawaited(store.deleteImage(_removedImagePath));
 imagePath = '';
 } else {
 imagePath = _imagePath;
 }

 final useCase = ref.read(updateProductUseCaseProvider);
 final updated = _product.copyWith(
 name: _nameController.text.trim(),
 description: _descriptionController.text.trim(),
 imagePath: imagePath,
 purchasePriceCents: _parsePrice(_purchasePriceController.text),
 salePriceCents: _parsePrice(_salePriceController.text),
 code: _codeController.text.trim(),
 vendaPorFracao: _vendaPorFracao,
 unitLabel: _unitLabel,
 isActive: _isActive,
 );

 // 1) Campos do catálogo (nome/preços/código/fração/status ativo) —
 // o estoque NÃO entra neste update (invariante stock = Σ lotes).
 await useCase.updateDetails(updated);

 // 2) Ajuste MANUAL do estoque (apenas se o valor mudou): define a
 // quantidade exata criando/consumindo lotes FIFO na mesma transação.
 final stockMilli = Quantity.parse(_stockController.text.trim());
 if (stockMilli != _product.stockQuantity) {
 await useCase.adjustStock(
 _product.id,
 stockMilli,
 storeId: _product.storeId,
 );
 }

 if (!mounted) return;
 Navigator.of(context).pop();
 ScaffoldMessenger.of(context).showSnackBar(
 SnackBar(
 content: Text(
 photoFailed
 ? l10n.productsEditSavedNoPhoto
 : l10n.productsEditSaved,
 ),
 ),
 );
 } on InvalidPriceException catch (error) {
 setState(() => _formError = error.message);
 } catch (error, stackTrace) {
 // Upload feito mas o produto não persistiu → remove a foto órfã
 // (best-effort — nunca deixa imagem sem produto no storage).
 if (uploadedImagePath.isNotEmpty) {
 unawaited(
 ref.read(productImageStoreProvider).deleteImage(uploadedImagePath),
 );
 }
 CrashReporting.capture(error, stackTrace, hint: 'Erro ao editar produto');
 setState(() => _formError = l10n.productsEditError);
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
 maxHeight: MediaQuery.sizeOf(context).height * 0.9,
 ),
 child: SingleChildScrollView(
 padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
 child: Form(
 key: _formKey,
 child: Column(
 mainAxisSize: MainAxisSize.min,
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
 AppSheetHeader(title: l10n.productsEditTitle),
 // FOTO — seção própria no topo (preview + câmera/galeria).
 const SizedBox(height: 16),
 _ProductPhotoPicker(
 bytes: _imageBytes,
 imagePath: _imagePath,
 onTakePhoto: () => _pickPhoto(ImageSource.camera),
 onPickGallery: () => _pickPhoto(ImageSource.gallery),
 onRemove: _removePhoto,
 ),
 const SizedBox(height: 24),
 // INFORMAÇÕES — identidade do produto.
 _SectionLabel(
 icon: Icons.inventory_2_outlined,
 title: l10n.productsSectionInfo,
 ),
 const SizedBox(height: 10),
 AppTextField(
 controller: _nameController,
 textInputAction: TextInputAction.next,
 label: l10n.loginNameLabel,
 prefixIcon: Icons.inventory_2_outlined,
 validator: (value) => (value == null || value.trim().isEmpty)
 ? l10n.productsNameError
 : null,
 ),
 const SizedBox(height: 12),
 AppTextField(
 controller: _descriptionController,
 textInputAction: TextInputAction.next,
 label: l10n.productsDescriptionLabel,
 prefixIcon: Icons.notes_outlined,
 ),
 const SizedBox(height: 12),
 AppTextField(
 controller: _codeController,
 textInputAction: TextInputAction.next,
 keyboardType: TextInputType.number,
 maxLength: 5,
 label: l10n.productsCodeLabel,
 helperText: l10n.productsCodeHint,
 prefixIcon: Icons.qr_code_2_outlined,
 validator: (value) {
 final digits = value?.trim() ?? '';
 if (digits.isNotEmpty &&
 !RegExp(r'^\d{1,5}$').hasMatch(digits)) {
 return l10n.productsCodeError;
 }
 return null;
 },
 ),
 const SizedBox(height: 24),
 // PREÇOS — compra e venda lado a lado.
 _SectionLabel(
 icon: Icons.payments_outlined,
 title: l10n.productsSectionPricing,
 ),
 const SizedBox(height: 10),
 Row(
 children: [
 Expanded(
 child: AppTextField(
 controller: _purchasePriceController,
 keyboardType: TextInputType.number,
 // Sem prefixIcon: campo de MEIA largura — com ícone
 // (48px) o label flutuante 'Purchase price' ainda
 // comprimiria (o tema já o deixou em 13px — labels
 // discretos globais, app_theme). Ícone propositalmente
 // fora para a fileira de preços não apertar.
 label: l10n.productsPurchasePrice,
 validator: (value) => _parsePrice(value ?? '') <= 0
 ? l10n.productsPurchasePriceError
 : null,
 ),
 ),
 const SizedBox(width: 12),
 Expanded(
 child: AppTextField(
 controller: _salePriceController,
 keyboardType: TextInputType.number,
 label: l10n.productsSalePrice,
 validator: (value) => _parsePrice(value ?? '') <= 0
 ? l10n.productsSalePriceError
 : null,
 ),
 ),
 ],
 ),
 const SizedBox(height: 24),
 // ESTOQUE — quantidade exata + venda por peso (FIFO).
 _SectionLabel(
 icon: Icons.warehouse_outlined,
 title: l10n.productsSectionStock,
 ),
 const SizedBox(height: 10),
 // Ajuste MANUAL de estoque: campo SEMPRE preenchido com o
 // estoque atual — alterar define a quantidade exata,
 // criando/consumindo lotes FIFO (a invariante stock = Σ
 // lotes nunca quebra).
 AppTextField(
 controller: _stockController,
 keyboardType: const TextInputType.numberWithOptions(
 decimal: true,
 ),
 label: l10n.productsStockQuantity,
 helperText: _vendaPorFracao
 ? l10n.productsStockWeightHint
 : l10n.productsStockAdjustHint,
 prefixIcon: Icons.warehouse_outlined,
 validator: (value) {
 // Edição: aceita ZERO explícito (zerar o estoque é um
 // ajuste legítimo — ex.: quebra total). Vazio = 0.
 // Rejeita texto não numérico e negativos.
 final text = value?.trim() ?? '';
 if (text.isEmpty) return null;
 final normalized = text
 .replaceAll(' ', '')
 .replaceAll(',', '.');
 final parsed = double.tryParse(normalized);
 if (parsed == null || parsed < 0) {
 return l10n.productsStockError;
 }
 return null;
 },
 ),
 const SizedBox(height: 4),
 Material(
 type: MaterialType.transparency,
 child: SwitchListTile(
 contentPadding: EdgeInsets.zero,
 title: Text(l10n.productsWeighLabel),
 subtitle: Text(l10n.productsWeighHint),
 value: _vendaPorFracao,
 onChanged: (value) => setState(() {
 _vendaPorFracao = value;
 _unitLabel = value ? 'kg' : 'un';
 }),
 ),
 ),
 if (_vendaPorFracao) ...[DropdownButtonFormField<String>(
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
              const SizedBox(height: 24),
              // STATUS — ativar/desativar (inativo some do PDV e das
 // compras; o estoque é preservado — a reativação devolve a
 // venda).
 _SectionLabel(
 icon: Icons.toggle_on_outlined,
 title: l10n.productsSectionStatus,
 ),
 const SizedBox(height: 10),
 Material(
 type: MaterialType.transparency,
 child: SwitchListTile(
 contentPadding: EdgeInsets.zero,
 title: Text(l10n.productsActiveLabel),
 subtitle: Text(l10n.productsActiveHint),
 value: _isActive,
 onChanged: (value) => setState(() => _isActive = value),
 ),
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
 AppButton.primary(
 label: l10n.productsEditSubmit,
 onPressed: _isSubmitting ? null : _submit,
 icon: _isSubmitting
 ? const SizedBox(
 height: 20,
 width: 20,
 child: CircularProgressIndicator(strokeWidth: 2),
 )
 : null,
 ),
 ],
 ),
 ),
 ),
 );
 }
}

/// Seletor de validade MINIMALISTA (W11) — um único campo compacto no
/// padrão dos demais inputs do formulário (borda sutil + ícone de calendário),
/// em vez do botão largo com texto grande e botão de limpar solto.
///
/// Vazio: mostra apenas "Definir validade" (toque abre o date picker). Com
/// data: mostra "Validade · dd/mm/aaaa" em destaque + um X discreto à direita
/// (tooltip "Remover validade") para limpar — os mesmos rótulos/tooltips de
/// antes, só que integrados num único campo.
class _ExpiryField extends StatelessWidget {
 const _ExpiryField({
 required this.expiryDate,
 required this.onPick,
 required this.onClear,
 });

 final DateTime? expiryDate;
 final VoidCallback onPick;
 final VoidCallback onClear;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);
 final scheme = theme.colorScheme;
 final l10n = context.l10n;
 final hasDate = expiryDate != null;

 // Semantics: o campo inteiro é um botão (abre o date picker) — leitores
 // de tela anunciam a ação, não só o texto visível (como no X de limpar,
 // que já tem tooltip).
 return Semantics(
 button: true,
 child: InkWell(
 onTap: onPick,
 borderRadius: BorderRadius.circular(12),
 child: Container(
 // minHeight (e não altura fixa): com escala de texto alta a data
 // 'Validade · dd/mm/aaaa' quebra em 2 linhas sem cortar o texto.
 constraints: const BoxConstraints(minHeight: 56),
 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
 decoration: BoxDecoration(
 color: scheme.surface,
 borderRadius: BorderRadius.circular(12),
 border: Border.all(color: scheme.outlineVariant),
 ),
 child: Row(
 crossAxisAlignment: CrossAxisAlignment.center,
 children: [
 Icon(
 Icons.event_outlined,
 size: 20,
 color: scheme.onSurfaceVariant,
 ),
 const SizedBox(width: 12),
 Expanded(
 child: Text(
 hasDate
 ? '${l10n.productsExpiryLabel} · '
 '${Formatters.date(expiryDate!)}'
 : l10n.productsExpiryAdd,
 // Quebra em até 2 linhas — a data nunca é cortada.
 maxLines: 2,
 overflow: TextOverflow.ellipsis,
 style: theme.textTheme.bodyMedium?.copyWith(
 color: hasDate ? scheme.onSurface : scheme.onSurfaceVariant,
 fontWeight: hasDate ? FontWeight.w500 : null,
 ),
 ),
 ),
 if (hasDate) ...[
 const SizedBox(width: 4),
 IconButton(
 tooltip: l10n.productsExpiryClear,
 icon: const Icon(Icons.close, size: 18),
 padding: EdgeInsets.zero,
 constraints: const BoxConstraints(
 minWidth: 32,
 minHeight: 32,
 ),
 onPressed: onClear,
 ),
 ],
 ],
 ),
 ),
 ),
 );
 }
}
