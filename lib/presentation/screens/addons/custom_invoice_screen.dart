import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/share/invoice_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/custom_invoice.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/color_palette.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';

/// Ecra de facturas personalizadas — criação e gestão de facturas
/// com layout customizável.
class CustomInvoiceScreen extends ConsumerStatefulWidget {
  const CustomInvoiceScreen({super.key});

  @override
  ConsumerState<CustomInvoiceScreen> createState() =>
      _CustomInvoiceScreenState();
}

class _CustomInvoiceScreenState extends ConsumerState<CustomInvoiceScreen> {
  final List<_InvoiceData> _invoices = [];
  int _invoiceCounter = 0;
  final _templateConfig = InvoiceTemplateConfig();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );

    return AppPage(
      title: l10n.customInvoiceTitle,
      useSafeArea: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: _openTemplateSettings,
          tooltip: l10n.customInvoiceTemplateTooltip,
        ),
      ],
      body: _invoices.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.customInvoiceEmpty,
              subtitle: l10n.customInvoiceEmptySubtitle,
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.lg,
                horizontal,
                AppSpacing.lg,
              ),
              itemCount: _invoices.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _InvoiceCard(
                invoice: _invoices[index],
                invoiceNumber: _invoiceCounter - index,
                templateConfig: _templateConfig,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-invoice',
        onPressed: _openNewInvoice,
        tooltip: l10n.customInvoiceNewFab,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _openNewInvoice() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NewInvoiceSheet(
        onSave: (data) {
          setState(() {
            _invoiceCounter++;
            _invoices.insert(0, data);
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openTemplateSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TemplateSettingsSheet(config: _templateConfig),
    );
  }
}

class _InvoiceData {
  _InvoiceData({
    required this.clientName,
    required this.clientPhone,
    required this.items,
    required this.totalCents,
    required this.discountCents,
    required this.taxCents,
  });

  final String clientName;
  final String clientPhone;
  final List<_InvoiceItemData> items;
  final int totalCents;
  final int discountCents;
  final int taxCents;
}

class _InvoiceItemData {
  _InvoiceItemData({
    required this.name,
    required this.qty,
    required this.unitPriceCents,
  });

  final String name;
  final int qty;
  final int unitPriceCents;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice Card — minimalista, padrão AppCard
// ═══════════════════════════════════════════════════════════════════════════════

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    this.invoiceNumber = 0,
    this.templateConfig,
  });

  final _InvoiceData invoice;
  final int invoiceNumber;
  final InvoiceTemplateConfig? templateConfig;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: nome do cliente + total
          Row(
            children: [
              // Ícone com fundo tingido (padrão IconTone)
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: IconTone.darkBackground(ModuleColors.reports),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: IconTone.lightForeground(ModuleColors.reports),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.clientName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.customInvoiceNumberPrefix(invoiceNumber.toString()
                              .padLeft(5, '0')) +
                          (invoice.clientPhone.isNotEmpty
                              ? '  •  ${invoice.clientPhone}'
                              : ''),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.currency(invoice.totalCents),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Detalhes: contagem de itens
          Text(
            l10n.customInvoiceItemsCount(invoice.items.length),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Acções
          Row(
            children: [
              AppButton.secondary(
                label: l10n.customInvoiceWhatsApp,
                icon: const Icon(Icons.share_outlined, size: 16),
                onPressed: () => _shareWhatsApp(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton.secondary(
                label: l10n.customInvoicePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                onPressed: () => _exportPdf(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    buffer.writeln(l10n.customInvoiceWhatsAppHeader);
    buffer
        .writeln('${l10n.customInvoiceNumberShort}: ${invoiceNumber.toString().padLeft(5, '0')}');
    buffer.writeln('${l10n.customInvoiceClientLabel}: ${invoice.clientName}');
    if (invoice.clientPhone.isNotEmpty) {
      buffer.writeln('${l10n.customInvoicePhoneLabel}: ${invoice.clientPhone}');
    }
    buffer.writeln();
    for (final item in invoice.items) {
      buffer.writeln(
        '• ${item.name} x${item.qty} — ${Formatters.currency(item.unitPriceCents * item.qty)}',
      );
    }
    buffer.writeln();
    buffer.writeln('${l10n.customInvoiceTotalLabel}: ${Formatters.currency(invoice.totalCents)}');

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _exportPdf(BuildContext context) async {
    final invoiceEntity = CustomInvoice(
      id: '',
      number: invoiceNumber,
      storeId: '',
      clientName: invoice.clientName,
      clientPhone: invoice.clientPhone,
      items: [
        for (final item in invoice.items)
          CustomInvoiceItem(
            productName: item.name,
            quantity: item.qty,
            unitPriceCents: item.unitPriceCents,
            subtotalCents: item.qty * item.unitPriceCents,
          ),
      ],
      totalAmountCents: invoice.totalCents,
      discountCents: invoice.discountCents,
      taxCents: invoice.taxCents,
      createdAt: DateTime.now(),
    );

    final config = templateConfig ?? InvoiceTemplateConfig();
    final l10n = context.l10n;
    await InvoicePdfExporter().sharePdf(
      invoiceEntity,
      labels: InvoicePdfLabels(
        docWord: l10n.pdfInvoiceDocWord,
        numberLabelTemplate: l10n.customInvoiceNumberPrefix('{number}'),
        clientHeading: l10n.pdfClientHeading,
        phoneLabelTemplate: l10n.pdfPhoneLine('{value}'),
        emailLabelTemplate: l10n.pdfEmailLine('{value}'),
        taxIdLabelTemplate: l10n.pdfNifLine('{value}'),
        itemHeader: l10n.pdfItemHeader,
        qtyHeader: l10n.customInvoiceQty,
        unitPriceHeader: l10n.pdfUnitPriceHeader,
        subtotalHeader: l10n.pdfSubtotalHeader,
        discountLabel: l10n.pdfDiscountLabel,
        taxLabel: l10n.pdfTaxLabel,
        totalLabel: l10n.customInvoiceTotalLabel,
        paymentLabelTemplate: l10n.pdfPaymentLine('{value}'),
        referenceLabelTemplate: l10n.pdfReferenceLine('{value}'),
        notesHeading: l10n.pdfNotesHeading,
        footerTemplate: l10n.pdfFooter('{date}'),
        fileNameBase: l10n.pdfInvoiceFileBase,
        subjectWord: l10n.pdfInvoiceSubjectWord,
      ),
      businessName: config.businessName.isNotEmpty
          ? config.businessName
          : l10n.businessFallbackName,
      businessAddress:
          config.businessAddress.isNotEmpty ? config.businessAddress : null,
      businessPhone:
          config.businessPhone.isNotEmpty ? config.businessPhone : null,
      businessTaxId:
          config.businessTaxId.isNotEmpty ? config.businessTaxId : null,
      logoBytes: config.logoBytes,
      primaryColor: _flutterColorToPdf(config.primaryColor),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// New Invoice Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _NewInvoiceSheet extends ConsumerStatefulWidget {
  const _NewInvoiceSheet({required this.onSave});

  final ValueChanged<_InvoiceData> onSave;

  @override
  ConsumerState<_NewInvoiceSheet> createState() => _NewInvoiceSheetState();
}

class _NewInvoiceSheetState extends ConsumerState<_NewInvoiceSheet> {
  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final List<_InvoiceItemData> _items = [];
  String? _selectedProductId;
  String? _selectedCustomerId;

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
    // produto da lista, adicionando um item errado à factura).
    if (product == null) return;

    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (price <= 0 || qty <= 0) return;

    setState(() {
      _items.add(_InvoiceItemData(
        name: product.name,
        qty: qty,
        unitPriceCents: (price * 100).round(),
      ));
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
    final total = _subtotalCents - discount + tax;

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
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Cliente ──
            _SectionLabel(text: l10n.customInvoiceClientSection),
            const SizedBox(height: 6),
            if (customers.isNotEmpty)
              DropdownButtonFormField<String>(
                  initialValue: _selectedCustomerId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: InputDecoration(
                    labelText: l10n.customInvoiceClientSection,
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                  items: customers
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${c.name}${c.phone.isNotEmpty ? ' (${c.phone})' : ''}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
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
              label: l10n.customInvoicePhone,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _taxIdController,
              label: l10n.customInvoiceTaxIdOptional,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // ─── Produto ──
            _SectionLabel(text: l10n.customInvoiceProductSection),
            const SizedBox(height: 6),
            if (activeProducts.isNotEmpty)
              DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: InputDecoration(
                    labelText: l10n.customInvoiceProductSection,
                    prefixIcon:
                        const Icon(Icons.inventory_2_outlined, size: 20),
                  ),
                  items: activeProducts
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                l10n.customInvoiceProductOption(
                                  (p.stockQuantity ~/ 1000).toString(),
                                  p.unitLabel,
                                  Formatters.currency(p.salePriceCents),
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedProductId = id;
                      final p =
                          activeProducts.firstWhere((x) => x.id == id);
                      _priceController.text =
                          (p.salePriceCents / 100).toStringAsFixed(2);
                    });
                  },
                )
            else
              InputDecorator(
                decoration: InputDecoration(
                  hintText: l10n.customInvoiceProductPlaceholder,
                  prefixIcon:
                      const Icon(Icons.inventory_2_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  enabled: false,
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
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () =>
                                setState(() => _items.removeAt(entry.key)),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: scheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.customInvoiceBillTotal(
                  Formatters.currency(total > 0 ? total : 0),
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.end,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: l10n.customInvoiceCreate,
              onPressed: _clientController.text.trim().isNotEmpty &&
                      _items.isNotEmpty
                  ? () {
                      widget.onSave(
                        _InvoiceData(
                          clientName: _clientController.text.trim(),
                          clientPhone: _phoneController.text.trim(),
                          items: List.from(_items),
                          totalCents: total > 0 ? total : 0,
                          discountCents: discount,
                          taxCents: tax,
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
// Template Settings Sheet
// ═══════════════════════════════════════════════════════════════════════════════

/// Configurações do modelo de factura — logotipo, cores e dados da empresa.
class InvoiceTemplateConfig {
  InvoiceTemplateConfig({
    this.logoBytes,
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessTaxId = '',
    this.primaryColor = const Color(0xFF2563EB),
    this.templateStyle = 'Classic',
  });

  Uint8List? logoBytes;
  String businessName;
  String businessAddress;
  String businessPhone;
  String businessTaxId;
  Color primaryColor;
  String templateStyle;
}


class _TemplateSettingsSheet extends StatefulWidget {
  const _TemplateSettingsSheet({required this.config});

  final InvoiceTemplateConfig config;

  @override
  State<_TemplateSettingsSheet> createState() => _TemplateSettingsSheetState();
}

class _TemplateSettingsSheetState extends State<_TemplateSettingsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _taxIdController;
  late String _selectedTemplate;
  late Color _selectedColor;
  Uint8List? _logoBytes;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final c = widget.config;
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
    widget.config
      ..businessName = _nameController.text.trim()
      ..businessAddress = _addressController.text.trim()
      ..businessPhone = _phoneController.text.trim()
      ..businessTaxId = _taxIdController.text.trim()
      ..templateStyle = _selectedTemplate
      ..primaryColor = _selectedColor
      ..logoBytes = _logoBytes;
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
              l10n.customInvoiceTemplateTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Logotipo ──
            _SectionLabel(text: l10n.customInvoiceTemplateLogoSection),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                                padding: const EdgeInsets.all(4),
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
                            color: scheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 6),
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
            _SectionLabel(text: l10n.customInvoiceTemplateColorSection),
            const SizedBox(height: AppSpacing.sm),              Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: kColorPalettes.entries.map((entry) {
                final isSelected =
                    entry.value.toARGB32() == _selectedColor.toARGB32();
                return Tooltip(
                  message: paletteColorName(entry.key, l10n),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedColor = entry.value),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: scheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 18,
                              color: scheme.surface,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Estilo ──
            _SectionLabel(text: l10n.customInvoiceTemplateStyle),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _TemplateStyleChip(
                    name: l10n.customInvoiceTemplateStyleClassic,
                    icon: Icons.receipt_long_outlined,
                    isSelected: _selectedTemplate == 'Classic',
                    onTap: () =>
                        setState(() => _selectedTemplate = 'Classic'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _TemplateStyleChip(
                    name: l10n.customInvoiceTemplateStyleModern,
                    icon: Icons.auto_awesome_outlined,
                    isSelected: _selectedTemplate == 'Modern',
                    onTap: () =>
                        setState(() => _selectedTemplate = 'Modern'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _TemplateStyleChip(
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

            // ─── Dados da Empresa ──
            _SectionLabel(text: l10n.customInvoiceTemplateCompanySection),
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
                    label: l10n.customInvoicePhone,
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

            // ─── Preview ──
            _SectionLabel(text: l10n.commonPreview),
            const SizedBox(height: AppSpacing.sm),
            _InvoicePreview(
              businessName: _nameController.text,
              businessAddress: _addressController.text,
              businessPhone: _phoneController.text,
              businessTaxId: _taxIdController.text,
              logoBytes: _logoBytes,
              primaryColor: _selectedColor,
              templateStyle: _selectedTemplate,
            ),
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
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

/// Converte uma [Color] do Flutter para [PdfColor] do pdf package.
PdfColor _flutterColorToPdf(Color color) {
  return PdfColor(
    color.r / 255,
    color.g / 255,
    color.b / 255,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice Preview — miniatura profissional do PDF
// ═══════════════════════════════════════════════════════════════════════════════

class _InvoicePreview extends StatelessWidget {
  const _InvoicePreview({
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessTaxId,
    this.logoBytes,
    required this.primaryColor,
    required this.templateStyle,
  });

  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessTaxId;
  final Uint8List? logoBytes;
  final Color primaryColor;
  final String templateStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = businessName.isNotEmpty ? businessName : 'Nome da Empresa';

    // Cor escura para texto (mesma lógica do PDF exporter).
    final primaryDark = HSLColor.fromColor(primaryColor)
        .withLightness((HSLColor.fromColor(primaryColor).lightness * 0.7).clamp(0.0, 1.0))
        .toColor();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra superior simulando o topo da página PDF
          Container(
            height: 4,
            color: primaryColor,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Cabeçalho: empresa + badge FACTURA ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logotipo + dados da empresa
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (logoBytes != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                logoBytes!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: primaryDark,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (businessAddress.isNotEmpty)
                                  Text(
                                    businessAddress,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 9,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (businessPhone.isNotEmpty)
                                  Text(
                                    businessPhone,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 9,
                                    ),
                                  ),
                                if (businessTaxId.isNotEmpty)
                                  Text(
                                    'NIF: $businessTaxId',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 9,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge FACTURA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FACTURA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Nº + data
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Nº 00001  •  03/09/2026',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Divisor
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                // ─── Cliente ──
                Text(
                  'CLIENTE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'João Silva',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Tel: 84 123 4567',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 10),
                // ─── Tabela de itens (miniatura) ──
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Item',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          'Qtd',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          'Preço',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rows
                _PreviewRow(
                  name: 'Produto A',
                  qty: '2',
                  price: '150,00',
                  primaryColor: primaryColor,
                ),
                _PreviewRow(
                  name: 'Produto B',
                  qty: '1',
                  price: '250,00',
                  primaryColor: primaryColor,
                  last: true,
                ),
                const SizedBox(height: 8),
                // ─── Total ──
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TOTAL: 550,00 MT',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Rodapé
                Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Gerado pelo TAREQO',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de item no preview da factura.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.name,
    required this.qty,
    required this.price,
    required this.primaryColor,
    this.last = false,
  });

  final String name;
  final String qty;
  final String price;
  final Color primaryColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: last ? null : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: last
            ? const BorderRadius.vertical(bottom: Radius.circular(4))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$price MT',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateStyleChip extends StatelessWidget {
  const _TemplateStyleChip({
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
                color: isSelected
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
