import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/share/quotation_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/quotation.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';

/// Ecra de cotações/orçamentos — lista e criação de cotações.
class QuotationScreen extends ConsumerStatefulWidget {
  const QuotationScreen({super.key});

  @override
  ConsumerState<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends ConsumerState<QuotationScreen> {
  final List<_QuotationDraft> _drafts = [];
  int _quotationCounter = 0;
  final _templateConfig = _QuotationTemplateConfig();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Cotações / Orçamentos',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: _openTemplateSettings,
            tooltip: 'Modelo da Cotação',
          ),
        ],
      ),
      body: _drafts.isEmpty
          ? EmptyState(
              icon: Icons.request_quote_outlined,
              title: 'Nenhuma cotação',
              subtitle:
                  'Crie cotações e orçamentos para os seus clientes',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _drafts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final draft = _drafts[index];
                return _QuotationCard(
                  draft: draft,
                  quotationNumber: _quotationCounter - index,
                  templateConfig: _templateConfig,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-quotation',
        onPressed: _openNewQuotation,
        tooltip: 'Nova Cotação',
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _openNewQuotation() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NewQuotationSheet(
        onSave: (draft) {
          setState(() {
            _quotationCounter++;
            _drafts.insert(0, draft);
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
      builder: (_) =>
          _QuotationTemplateSettingsSheet(config: _templateConfig),
    );
  }
}

enum _QuotationStatus { draft, sent, accepted, rejected }

class _QuotationDraft {
  _QuotationDraft({
    required this.clientName,
    this.clientPhone = '',
    required this.items,
    required this.totalCents,
    required this.validityDays,
  });

  final String clientName;
  final String clientPhone;
  final List<_QuotationItemData> items;
  final int totalCents;
  final int validityDays;

  _QuotationStatus status = _QuotationStatus.draft;
  DateTime createdAt = DateTime.now();
}

class _QuotationItemData {
  _QuotationItemData({
    required this.name,
    required this.qty,
    required this.unitPriceCents,
  });

  final String name;
  final int qty;
  final int unitPriceCents;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Quotation Card — minimalista, padrão AppCard
// ═══════════════════════════════════════════════════════════════════════════════

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({
    required this.draft,
    this.quotationNumber = 0,
    this.templateConfig,
  });

  final _QuotationDraft draft;
  final int quotationNumber;
  final _QuotationTemplateConfig? templateConfig;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho: nome do cliente + estado
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: IconTone.darkBackground(ModuleColors.credit),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.request_quote_outlined,
                  size: 16,
                  color: IconTone.lightForeground(ModuleColors.credit),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.clientName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nº ${quotationNumber.toString().padLeft(5, '0')}'
                      '${draft.clientPhone.isNotEmpty ? '  •  ${draft.clientPhone}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: draft.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Detalhes
          Text(
            '${draft.items.length} ${draft.items.length == 1 ? 'item' : 'itens'}'
            '  •  Validade: ${draft.validityDays} dias'
            '  •  ${Formatters.currency(draft.totalCents)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Acções
          Row(
            children: [
              AppButton.secondary(
                label: 'WhatsApp',
                icon: const Icon(Icons.share_outlined, size: 16),
                onPressed: _shareWhatsApp,
              ),
              const SizedBox(width: AppSpacing.xs),
              AppButton.secondary(
                label: 'PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                onPressed: () => _exportPdf(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (draft.status == _QuotationStatus.draft)
                AppButton.primary(
                  label: 'Enviar',
                  icon: const Icon(Icons.send_outlined, size: 16),
                  onPressed: () =>
                      draft.status = _QuotationStatus.sent,
                ),
              if (draft.status == _QuotationStatus.sent) ...[
                AppButton.primary(
                  label: 'Aceitar',
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  onPressed: () =>
                      draft.status = _QuotationStatus.accepted,
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton.danger(
                  label: 'Rejeitar',
                  onPressed: () =>
                      draft.status = _QuotationStatus.rejected,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareWhatsApp() async {
    final buffer = StringBuffer();
    buffer.writeln('═══ COTAÇÃO ═══');
    buffer.writeln('Nº: ${quotationNumber.toString().padLeft(5, '0')}');
    buffer.writeln('Cliente: ${draft.clientName}');
    if (draft.clientPhone.isNotEmpty) {
      buffer.writeln('Tel: ${draft.clientPhone}');
    }
    buffer.writeln('Validade: ${draft.validityDays} dias');
    buffer.writeln();
    for (final item in draft.items) {
      buffer.writeln(
        '• ${item.name} x${item.qty} — ${Formatters.currency(item.unitPriceCents * item.qty)}',
      );
    }
    buffer.writeln();
    buffer.writeln('TOTAL: ${Formatters.currency(draft.totalCents)}');

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _exportPdf(BuildContext context) async {
    final quotation = Quotation(
      id: '',
      number: quotationNumber,
      storeId: '',
      customerId: '',
      customerName: draft.clientName,
      items: [
        for (final item in draft.items)
          QuotationItem(
            productId: '',
            productName: item.name,
            quantity: item.qty * 1000,
            unitPriceCents: item.unitPriceCents,
          ),
      ],
      totalAmountCents: draft.totalCents,
      validUntil: DateTime.now().add(Duration(days: draft.validityDays)),
      createdAt: DateTime.now(),
    );

    final config = templateConfig ?? _QuotationTemplateConfig();
    await QuotationPdfExporter().sharePdf(
      quotation,
      businessName:
          config.businessName.isNotEmpty ? config.businessName : 'Minha Empresa',
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
// New Quotation Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _NewQuotationSheet extends ConsumerStatefulWidget {
  const _NewQuotationSheet({required this.onSave});

  final ValueChanged<_QuotationDraft> onSave;

  @override
  ConsumerState<_NewQuotationSheet> createState() =>
      _NewQuotationSheetState();
}

class _NewQuotationSheetState extends ConsumerState<_NewQuotationSheet> {
  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final List<_QuotationItemData> _items = [];
  String? _selectedProductId;
  String? _selectedCustomerId;

  @override
  void dispose() {
    _clientController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  int get _totalCents =>
      _items.fold(0, (sum, item) => sum + (item.qty * item.unitPriceCents));

  void _addItem() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (_selectedProductId == null || price <= 0) return;

    final products = ref.read(productsProvider).value ?? [];
    final product = products.firstWhere(
      (p) => p.id == _selectedProductId,
      orElse: () => products.first,
    );

    setState(() {
      _items.add(_QuotationItemData(
        name: product.name,
        qty: qty,
        unitPriceCents: (price * 100).round(),
      ));
      _selectedProductId = null;
      _priceController.clear();
      _qtyController.text = '1';
    });
  }

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final products = ref.watch(productsProvider).value ?? [];
    final customers = ref.watch(customersProvider).value ?? [];
    final activeProducts = products.where((p) => p.isActive).toList();

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
              'Nova Cotação',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Cliente ──
            _SectionLabel(text: 'Cliente'),
            const SizedBox(height: 6),
            if (customers.isNotEmpty)
              DropdownButtonFormField<String>(
                  initialValue: _selectedCustomerId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
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
                label: 'Nome do cliente',
                prefixIcon: Icons.person_outline,
              ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phoneController,
              label: 'Telefone (opcional)',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // ─── Produto ──
            _SectionLabel(text: 'Produto'),
            const SizedBox(height: 6),
            if (activeProducts.isNotEmpty)
              DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: const InputDecoration(
                    labelText: 'Produto',
                    prefixIcon:
                        Icon(Icons.inventory_2_outlined, size: 20),
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
                                'Estoque: ${p.stockQuantity ~/ 1000} ${p.unitLabel}  •  ${Formatters.currency(p.salePriceCents)}',
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
                  hintText: 'Sem produtos cadastrados',
                  prefixIcon:
                      const Icon(Icons.inventory_2_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                    label: 'Preço (MT)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _qtyController,
                    label: 'Qtd',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton.secondary(
                label: 'Adicionar',
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
                          Icon(Icons.check_circle_outline,
                              size: 16, color: scheme.primary),
                          const SizedBox(width: 8),
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
                            onTap: () => _removeItem(entry.key),
                            child: Icon(Icons.close,
                                size: 16, color: scheme.error),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Total: ${Formatters.currency(_totalCents)}',
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
              label: 'Guardar Cotação',
              onPressed: _clientController.text.trim().isNotEmpty &&
                      _items.isNotEmpty
                  ? () {
                      widget.onSave(_QuotationDraft(
                        clientName: _clientController.text.trim(),
                        clientPhone: _phoneController.text.trim(),
                        items: List.from(_items),
                        totalCents: _totalCents,
                        validityDays: 7,
                      ));
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
// Template Config + Settings Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _QuotationTemplateConfig {
  Uint8List? logoBytes;
  String businessName = '';
  String businessAddress = '';
  String businessPhone = '';
  String businessTaxId = '';
  Color primaryColor = const Color(0xFFD97706);
}

/// Paleta de cores profissional — a mesma usada na factura.
const _kColorPalettes = <String, Color>{
  'Azul': Color(0xFF2563EB),
  'Verde': Color(0xFF16A34A),
  'Vermelho': Color(0xFFDC2626),
  'Âmbar': Color(0xFFD97706),
  'Slate': Color(0xFF475569),
  'Violeta': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Indigo': Color(0xFF4338CA),
};

class _QuotationTemplateSettingsSheet extends StatefulWidget {
  const _QuotationTemplateSettingsSheet({required this.config});

  final _QuotationTemplateConfig config;

  @override
  State<_QuotationTemplateSettingsSheet> createState() =>
      _QuotationTemplateSettingsSheetState();
}

class _QuotationTemplateSettingsSheetState
    extends State<_QuotationTemplateSettingsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _taxIdController;
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
              title: const Text('Galeria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmara'),
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
      ..primaryColor = _selectedColor
      ..logoBytes = _logoBytes;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modelo guardado com sucesso')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
              'Modelo da Cotação',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Logotipo ──
            _SectionLabel(text: 'Logotipo da Empresa'),
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: _pickLogo,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
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
                            'Toque para carregar logotipo',
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
            _SectionLabel(text: 'Cor Principal'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _kColorPalettes.entries.map((entry) {
                final isSelected =
                    entry.value.toARGB32() == _selectedColor.toARGB32();
                return GestureDetector(
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
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Dados da Empresa ──
            _SectionLabel(text: 'Dados da Empresa'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _nameController,
              label: 'Nome da Empresa',
              prefixIcon: Icons.business_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _addressController,
              label: 'Morada',
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: _taxIdController,
                    label: 'NIF / NUIT',
                    prefixIcon: Icons.badge_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Preview ──
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
                              : 'Nome da Empresa',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Cotação • Preview',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Preview',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _selectedColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Botões ──
            AppButton.primary(
              expanded: true,
              label: 'Guardar Modelo',
              onPressed: _save,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.secondary(
              expanded: true,
              label: 'Cancelar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _QuotationStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (label, color) = switch (status) {
      _QuotationStatus.draft => ('Rascunho', const Color(0xFFF59E0B)),
      _QuotationStatus.sent => ('Enviada', const Color(0xFF3B82F6)),
      _QuotationStatus.accepted => ('Aceite', const Color(0xFF16A34A)),
      _QuotationStatus.rejected => ('Rejeitada', const Color(0xFFDC2626)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

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

/// Converte uma [Color] do Flutter para [PdfColor] do pdf package.
PdfColor _flutterColorToPdf(Color color) {
  return PdfColor(
    color.r / 255,
    color.g / 255,
    color.b / 255,
  );
}
