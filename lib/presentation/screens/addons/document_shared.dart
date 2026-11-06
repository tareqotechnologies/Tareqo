import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/store.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/invoice_template_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_picker_field.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/color_palette.dart';
import '../../widgets/section_label.dart';
import 'custom_invoice_preview.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Partes VERBATIM partilhadas por quotation_screen e custom_invoice_screen
// (deduplicação do Fix #1 slice 2). Nenhuma peça muda o output: cada bloco
// é uma cópia fiel do original — a diferença entre os dois ecrãs vive nos
// rótulos/ramos selecionados por [DocumentKind].
// ═══════════════════════════════════════════════════════════════════════════════

/// Loja activa (id) — documento POR loja (número sequencial dentro da
/// loja). Resolvida como nas demais telas de dados. Era copiada
/// private-static nos dois ecrãs, caractere por caractere, até nos
/// comentários.
String? activeStoreId(WidgetRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final tenant = ref.watch(myTenantProvider(user.id)).value;
  if (tenant == null) return null;
  final storeId = ref.watch(activeStoreIdProvider(user.id));
  if (storeId != null) return storeId;
  // Sem loja activa: cai para a primeira loja do tenant (como vendas).
  final stores = ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
  return stores.isEmpty ? null : stores.first.id;
}

/// Loja activa (entidade) — nome/contatos reais para o PDF.
Store? activeStore(WidgetRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  final tenant = ref.watch(myTenantProvider(user.id)).value;
  if (tenant == null) return null;
  final stores = ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
  if (stores.isEmpty) return null;
  final storeId = ref.watch(activeStoreIdProvider(user.id));
  return stores.where((s) => s.id == storeId).firstOrNull ?? stores.first;
}

/// Converte uma [Color] do Flutter para [PdfColor] do pdf package.
///
/// `color.r/g/b` JÁ são normalizados (0.0–1.0) no Flutter moderno —
/// dividir por 255 os esmagava para ~0 e o PDF saía sempre PRETO,
/// independentemente da cor do tema escolhida.
PdfColor flutterColorToPdf(Color color) {
  return PdfColor(color.r, color.g, color.b, color.a);
}

/// Milésimos (convenção W11: 1000 = 1 unidade) → texto de unidades
/// ("2" ou "1.5" para frações). Usado no cartão e no texto de WhatsApp.
String qtyToUnitsText(int millesimos) {
  final units = millesimos / 1000;
  return units == units.roundToDouble()
      ? units.toStringAsFixed(0)
      : units.toStringAsFixed(2);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Draft do formulário de criação (sheet) — submetido ao ecrã, que é quem
// valida via use case e grava no repositório (as sheets nunca gravam).
// ═══════════════════════════════════════════════════════════════════════════════

/// Um item de rascunho (linhas de produto adicionadas na sheet).
class DocumentItemData {
  DocumentItemData({
    required this.name,
    required this.qty,
    required this.unitPriceCents,
  });

  final String name;
  final int qty;
  final int unitPriceCents;
}

/// Matriz comum do rascunho. Os campos de factura (discount/tax/taxId)
/// são zero/'' para cotações — por isso a mesma sheet serve aos dois.
class DocumentDraft {
  DocumentDraft({
    required this.clientName,
    required this.clientPhone,
    this.clientTaxId = '',
    this.customerId,
    required this.items,
    required this.totalCents,
    this.discountCents = 0,
    this.taxCents = 0,
    this.validityDays = 7,
  });

  final String clientName;
  final String clientPhone;

  /// Cliente REAL seleccionado na sheet (null = nome digitado manualmente).
  final String? customerId;

  final String clientTaxId;
  final List<DocumentItemData> items;
  final int totalCents;
  final int discountCents;
  final int taxCents;

  /// Só usado por cotações (7 dias, como no original).
  final int validityDays;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sheet de criação unificada — era _NewQuotationSheet/_NewInvoiceSheet,
// quase idênticas (se sempre: cliente → telefone → [NIF] → produto →
// preço/qty → adicionar → linhas → [desconto/IVA] → total → guardar).
// ═══════════════════════════════════════════════════════════════════════════════

/// Ecrã de destino do rascunho: cotação ou factura personalizada.
enum DocumentKind { quotation, invoice }

class DocumentFormSheet extends ConsumerStatefulWidget {
  const DocumentFormSheet({
    super.key,
    required this.kind,
    required this.onSave,
  });

  final DocumentKind kind;
  final ValueChanged<DocumentDraft> onSave;

  @override
  ConsumerState<DocumentFormSheet> createState() => _DocumentFormSheetState();
}

class _DocumentFormSheetState extends ConsumerState<DocumentFormSheet> {
  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final List<DocumentItemData> _items = [];
  String? _selectedProductId;
  String? _selectedCustomerId;

  bool get _isInvoice => widget.kind == DocumentKind.invoice;

  @override
  void dispose() {
    _clientController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  int get _subtotalCents =>
      _items.fold(0, (sum, item) => sum + (item.qty * item.unitPriceCents));

  void _addItem() {
    final products = ref.read(productsProvider).value ?? [];
    final product = products
        .where((p) => p.id == _selectedProductId)
        .firstOrNull;
    // Produto não encontrado → ignora (antes o fallback caía no PRIMEIRO
    // produto da lista, adicionando um item errado ao documento).
    if (product == null) return;

    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (price <= 0 || qty <= 0) return;

    setState(() {
      _items.add(
        DocumentItemData(
          name: product.name,
          qty: qty,
          unitPriceCents: (price * 100).round(),
        ),
      );
      _selectedProductId = null;
      _priceController.clear();
      _qtyController.text = '1';
    });
  }

  /// Lê um valor monetário (MZN) digitado e devolve em CENTAVOS inteiros,
  /// nunca negativo (vazio/inválido/negativo = 0).
  int _toCents(String raw) {
    final value = double.tryParse(raw) ?? 0;
    if (value <= 0) return 0;
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final products = ref.watch(productsProvider).value ?? [];
    final customers = ref.watch(customersProvider).value ?? [];
    final activeProducts = products.where((p) => p.isActive).toList();
    // Desconto/IVA digitados em MZN → centavos inteiros. Bug anterior:
    // `?? 0 * 100` (precedência do `??`) devolvia o valor digitado SEM o
    // ×100 — um desconto de 10 saía como 10 CENTAVOS (e não 1.000).
    final discount = _toCents(_discountController.text);
    final tax = _toCents(_taxController.text);
    final invoiceTotal = _subtotalCents - discount + tax;
    final displayTotalCents = _isInvoice
        ? (invoiceTotal > 0 ? invoiceTotal : 0)
        : _subtotalCents;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.customInvoiceNew,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Cliente ──
            SectionLabel(text: l10n.customInvoiceClientSection),
            const SizedBox(height: 8),
            if (customers.isNotEmpty)
              AppPickerField<String>(
                value: _selectedCustomerId,
                isExpanded: true,
                label: l10n.customInvoiceClientSection,
                prefixIcon: Icons.person_outline,
                items: [
                  for (final c in customers)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.name}${c.phone.isNotEmpty ? ' (${c.phone})' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  setState(() {
                    _selectedCustomerId = id;
                    final c = customers.firstWhere((x) => x.id == id);
                    _clientController.text = c.name;
                    _phoneController.text = c.phone;
                  });
                },
              )
            else
              AppTextField(
                controller: _clientController,
                label: l10n.customInvoiceClientName,
                prefixIcon: Icons.person_outline,
              ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phoneController,
              // Factura: telefone obrigatório (label factura); cotação:
              // opcional (rótulo próprio). Idêntico ao original, por ecrã.
              label: _isInvoice
                  ? l10n.customInvoicePhone
                  : l10n.quotationPhoneOptional,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            if (_isInvoice) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _taxIdController,
                label: l10n.customInvoiceTaxIdOptional,
                prefixIcon: Icons.badge_outlined,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // ─── Produto ──
            SectionLabel(text: l10n.customInvoiceProductSection),
            const SizedBox(height: 8),
            if (activeProducts.isNotEmpty)
              AppPickerField<String>(
                value: _selectedProductId,
                isExpanded: true,
                label: l10n.customInvoiceProductSection,
                prefixIcon: Icons.inventory_2_outlined,
                items: [
                  for (final p in activeProducts)
                    DropdownMenuItem(
                      value: p.id,
                      // Linha ÚNICA: o item seleccionado é exibido no
                      // campo de altura compacta — uma Column de duas
                      // linhas estourava o InputDecorator em 7px
                      // (RenderFlex overflow) ao seleccionar o produto.
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.customInvoiceProductOption(
                              (p.stockQuantity ~/ 1000).toString(),
                              p.unitLabel,
                              Formatters.currency(p.salePriceCents),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (id) {
                  setState(() {
                    _selectedProductId = id;
                    final p = activeProducts.firstWhere((x) => x.id == id);
                    _priceController.text = (p.salePriceCents / 100)
                        .toStringAsFixed(2);
                  });
                },
              )
            else
              InputDecorator(
                decoration: InputDecoration(
                  hintText: l10n.customInvoiceProductPlaceholder,
                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  // À cotação faltava este `enabled: false` no original;
                  // mantido por ecrã para não alterar o visual nenhum.
                  enabled: !_isInvoice,
                ),
                child: const Text(''),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _priceController,
                    label: l10n.customInvoicePrice,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _qtyController,
                    label: l10n.customInvoiceQty,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.secondary(
                label: l10n.customInvoiceAddItem,
                onPressed: _selectedProductId != null ? _addItem : null,
              ),
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ..._items.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                  child: Row(
                    children: [
                      // A cotação mostrava check à esquerda; a factura
                      // não. Idêntico ao original, por ecrã.
                      if (!_isInvoice) ...[
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          '${entry.value.name} x${entry.value.qty}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        Formatters.currency(
                          entry.value.unitPriceCents * entry.value.qty,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() => _items.removeAt(entry.key)),
                        child: Icon(Icons.close, size: 16, color: scheme.error),
                      ),
                    ],
                  ),
                ),
              ),
              // Só a FACTURA tem desconto/IVA (bloco `if (_items.isNotEmpty)`
              // do original — índices de TextField 5 e 6 nos testes).
              if (_isInvoice) ...[
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _discountController,
                  label: l10n.customInvoiceDiscount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.discount_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: _taxController,
                  label: l10n.customInvoiceTax,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.receipt_outlined,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.customInvoiceBillTotal(
                  Formatters.currency(displayTotalCents),
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.end,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: _isInvoice ? l10n.customInvoiceCreate : l10n.quotationSave,
              onPressed:
                  _clientController.text.trim().isNotEmpty && _items.isNotEmpty
                  ? () {
                      widget.onSave(
                        DocumentDraft(
                          clientName: _clientController.text.trim(),
                          clientPhone: _phoneController.text.trim(),
                          clientTaxId: _isInvoice
                              ? _taxIdController.text.trim()
                              : '',
                          customerId: _selectedCustomerId,
                          items: List.from(_items),
                          totalCents: displayTotalCents,
                          discountCents: _isInvoice ? discount : 0,
                          taxCents: _isInvoice ? tax : 0,
                          validityDays: 7,
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sheet de configuração do modelo (usa o template PERSISTENTE de
// invoice_template_providers) — era _TemplateSettingsSheet (factura) e
// _QuotationTemplateSettingsSheet (cotação), com ramos por tipo.
// ═══════════════════════════════════════════════════════════════════════════════

class DocumentTemplateSettingsSheet extends ConsumerStatefulWidget {
  const DocumentTemplateSettingsSheet({super.key, required this.kind});

  final DocumentKind kind;

  @override
  ConsumerState<DocumentTemplateSettingsSheet> createState() =>
      _DocumentTemplateSettingsSheetState();
}

class _DocumentTemplateSettingsSheetState
    extends ConsumerState<DocumentTemplateSettingsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _taxIdController;
  late String _selectedTemplate;
  late Color _selectedColor;
  Uint8List? _logoBytes;

  final _picker = ImagePicker();

  bool get _isInvoice => widget.kind == DocumentKind.invoice;

  @override
  void initState() {
    super.initState();
    // Config PERSISTIDA (provider) — o sheet edita uma cópia local e só
    // grava no provider no Salvar.
    final c = ref.read(invoiceTemplateProvider);
    _nameController = TextEditingController(text: c.businessName);
    _addressController = TextEditingController(text: c.businessAddress);
    _phoneController = TextEditingController(text: c.businessPhone);
    _taxIdController = TextEditingController(text: c.businessTaxId);
    _selectedTemplate = c.templateStyle;
    _selectedColor = c.primaryColor;
    _logoBytes = c.logoBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(ctx.l10n.imageSourceGallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(ctx.l10n.imageSourceCamera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 400,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _logoBytes = bytes);
    }
  }

  void _removeLogo() => setState(() => _logoBytes = null);

  void _save() {
    // Grava no provider PERSISTENTE (prefs) — sobrevive ao fechar do app.
    // A cotação NÃO edita o estilo no seu sheet (preserva o estilo actual,
    // como no original); a factura grava o chip selecionado.
    ref
        .read(invoiceTemplateProvider.notifier)
        .save(
          InvoiceTemplateConfig(
            logoBytes: _logoBytes,
            businessName: _nameController.text.trim(),
            businessAddress: _addressController.text.trim(),
            businessPhone: _phoneController.text.trim(),
            businessTaxId: _taxIdController.text.trim(),
            primaryColor: _selectedColor,
            templateStyle: _isInvoice
                ? _selectedTemplate
                : ref.read(invoiceTemplateProvider).templateStyle,
          ),
        );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.customInvoiceTemplateSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isInvoice
                  ? l10n.customInvoiceTemplateTitle
                  : l10n.quotationTemplateTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Logotipo ──
            SectionLabel(text: l10n.customInvoiceTemplateLogoSection),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(
                    color: scheme.outlineVariant,
                    style: _logoBytes == null
                        ? BorderStyle.solid
                        : BorderStyle.none,
                  ),
                ),
                child: _logoBytes != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.memory(
                            _logoBytes!,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: _removeLogo,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: scheme.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: scheme.onError,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 28,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.customInvoiceTemplateLogoHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Cor Principal ──
            SectionLabel(text: l10n.customInvoiceTemplateColorSection),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: kColorPalettes.entries.map((entry) {
                final isSelected =
                    entry.value.toARGB32() == _selectedColor.toARGB32();
                return Tooltip(
                  message: paletteColorName(entry.key, l10n),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = entry.value),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: scheme.onSurface, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, size: 18, color: scheme.surface)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Estilo (só FACTURA — Classic/Modern/Compact) ──
            if (_isInvoice) ...[
              SectionLabel(text: l10n.customInvoiceTemplateStyle),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _DocumentStyleChip(
                      name: l10n.customInvoiceTemplateStyleClassic,
                      icon: Icons.receipt_long_outlined,
                      isSelected: _selectedTemplate == 'Classic',
                      onTap: () =>
                          setState(() => _selectedTemplate = 'Classic'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _DocumentStyleChip(
                      name: l10n.customInvoiceTemplateStyleModern,
                      icon: Icons.auto_awesome_outlined,
                      isSelected: _selectedTemplate == 'Modern',
                      onTap: () => setState(() => _selectedTemplate = 'Modern'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: _DocumentStyleChip(
                      name: l10n.customInvoiceTemplateStyleCompact,
                      icon: Icons.view_stream_outlined,
                      isSelected: _selectedTemplate == 'Compact',
                      onTap: () =>
                          setState(() => _selectedTemplate = 'Compact'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ─── Dados da Empresa ──
            SectionLabel(text: l10n.customInvoiceTemplateCompanySection),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _nameController,
              label: l10n.customInvoiceTemplateCompanyName,
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _addressController,
              label: l10n.customInvoiceTemplateAddress,
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _phoneController,
                    // Rótulos originais por ecrã: cotação usava
                    // `quotationTemplatePhone`; factura `customInvoicePhone`.
                    label: _isInvoice
                        ? l10n.customInvoicePhone
                        : l10n.quotationTemplatePhone,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _taxIdController,
                    label: l10n.customInvoiceTemplateTaxId,
                    prefixIcon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Preview (formas diferentes por tipo, como no original) ──
            if (_isInvoice) ...[
              SectionLabel(text: l10n.commonPreview),
              const SizedBox(height: AppSpacing.sm),
              CustomInvoicePreview(
                businessName: _nameController.text,
                businessAddress: _addressController.text,
                businessPhone: _phoneController.text,
                businessTaxId: _taxIdController.text,
                logoBytes: _logoBytes,
                primaryColor: _selectedColor,
                currencySymbol: Formatters.currencySymbol,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.06),
                  borderRadius: AppRadius.lgAll,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: _logoBytes != null
                          ? ClipRRect(
                              borderRadius: AppRadius.smAll,
                              child: Image.memory(
                                _logoBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.request_quote,
                              size: 20,
                              color: scheme.surface,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : l10n.customInvoicePreviewCompanyFallback,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            l10n.quotationTemplatePreview,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        l10n.quotationTemplatePreviewBadge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _selectedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // ─── Botões ──
            AppButton.primary(
              expanded: true,
              label: l10n.customInvoiceTemplateSave,
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              expanded: true,
              label: l10n.commonCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Chip de estilo do template (era _TemplateStyleChip, na factura).
// ═══════════════════════════════════════════════════════════════════════════════

class _DocumentStyleChip extends StatelessWidget {
  const _DocumentStyleChip({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? scheme.primaryContainer.withValues(alpha: 0.3)
          : scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
