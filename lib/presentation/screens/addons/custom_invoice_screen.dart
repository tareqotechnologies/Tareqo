import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/share/invoice_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/custom_invoice.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: AppSpacing.lg,
        title: Text(
          'Factura Personalizada',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: _openTemplateSettings,
            tooltip: 'Modelo da Factura',
          ),
        ],
      ),
      body: _invoices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nenhuma factura',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Crie facturas profissionais com layout\n'
                      'personalizado para os seus clientes',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _invoices.length,
              separatorBuilder: (_, __) =>
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
        tooltip: 'Nova Factura',
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

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadius.lgAll,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    invoice.clientName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  _formatMoney(invoice.totalCents),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${invoice.items.length} itens  •  ${invoice.clientPhone.isNotEmpty ? invoice.clientPhone : "Sem telefone"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AppButton.secondary(
                  label: 'Ver Factura',
                  onPressed: () {},
                ),
                const SizedBox(width: AppSpacing.xs),
                AppButton.secondary(
                  label: 'Exportar PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  onPressed: () => _exportPdf(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(int cents) {
    final v = cents / 100;
    return '${v.toStringAsFixed(2)} MT';
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
    await InvoicePdfExporter().sharePdf(
      invoiceEntity,
      businessName: config.businessName.isNotEmpty ? config.businessName : 'Minha Empresa',
      businessAddress: config.businessAddress.isNotEmpty ? config.businessAddress : null,
      businessPhone: config.businessPhone.isNotEmpty ? config.businessPhone : null,
      businessTaxId: config.businessTaxId.isNotEmpty ? config.businessTaxId : null,
    );
  }
}

class _NewInvoiceSheet extends StatefulWidget {
  const _NewInvoiceSheet({required this.onSave});

  final ValueChanged<_InvoiceData> onSave;

  @override
  State<_NewInvoiceSheet> createState() => _NewInvoiceSheetState();
}

class _NewInvoiceSheetState extends State<_NewInvoiceSheet> {
  final _clientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final List<_InvoiceItemData> _items = [];

  @override
  void dispose() {
    _clientController.dispose();
    _phoneController.dispose();
    _taxIdController.dispose();
    _productController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  int get _subtotalCents => _items.fold(
      0, (sum, item) => sum + item.qty * 1000 * item.unitPriceCents ~/ 1000);

  void _addItem() {
    final name = _productController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 1;
    if (name.isEmpty || price <= 0) return;

    setState(() {
      _items.add(_InvoiceItemData(
        name: name,
        qty: qty,
        unitPriceCents: (price * 100).round(),
      ));
      _productController.clear();
      _priceController.clear();
      _qtyController.text = '1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discount = (double.tryParse(_discountController.text) ?? 0 * 100).round();
    final tax = (double.tryParse(_taxController.text) ?? 0 * 100).round();
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
              'Nova Factura',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _clientController,
              label: 'Nome do cliente',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phoneController,
              label: 'Telefone',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _taxIdController,
              label: 'NIF / NUIT (opcional)',
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _productController,
              label: 'Produto',
              prefixIcon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppTextField(
                    controller: _priceController,
                    label: 'Preço (MT)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                onPressed: _addItem,
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
                            _formatMoney(entry.value.unitPriceCents),
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
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _discountController,
                label: 'Desconto (MT)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.discount_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: _taxController,
                label: 'IVA (MT)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.receipt_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Total: ${_formatMoney(total > 0 ? total : 0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.end,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              expanded: true,
              label: 'Criar Factura',
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

  String _formatMoney(int cents) {
    final v = cents / 100;
    return '${v.toStringAsFixed(2)} MT';
  }
}

/// Configurações do modelo de factura — logotipo, cores e dados da empresa.
///
/// Estado persistido em memória (poderia ser migrado para SecureStorage
/// ou SharedPreferences no futuro).
class InvoiceTemplateConfig {
  InvoiceTemplateConfig({
    this.logoBytes,
    this.businessName = '',
    this.businessAddress = '',
    this.businessPhone = '',
    this.businessTaxId = '',
    this.primaryColor = const Color(0xFF4338CA),
    this.templateStyle = 'Clássico',
  });

  Uint8List? logoBytes;
  String businessName;
  String businessAddress;
  String businessPhone;
  String businessTaxId;
  Color primaryColor;
  String templateStyle;
}

/// Paleta de cores predefinida para facturas.
const _kColorPalettes = <String, Color>{
  'Índigo': Color(0xFF4338CA),
  'Verde': Color(0xFF16A34A),
  'Vermelho': Color(0xFFDC2626),
  'Amber': Color(0xFFF59E0B),
  'Cinza': Color(0xFF475569),
  'Roxo': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Rosa': Color(0xFFDB2777),
};

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

    final picked = await _picker.pickImage(source: source, maxWidth: 400, imageQuality: 85);
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
              'Modelo da Factura',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Logotipo ───────────────────────────────────────
            Text(
              'Logotipo da Empresa',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    style: _logoBytes == null ? BorderStyle.solid : BorderStyle.none,
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
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
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

            // ─── Paleta de Cores ─────────────────────────────────
            Text(
              'Cor Principal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _kColorPalettes.entries.map((entry) {
                final isSelected = entry.value.toARGB32() == _selectedColor.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = entry.value),
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

            // ─── Estilo do Template ──────────────────────────────
            Text(
              'Estilo',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _TemplateStyleChip(
                    name: 'Clássico',
                    icon: Icons.receipt_long_outlined,
                    isSelected: _selectedTemplate == 'Clássico',
                    onTap: () => setState(() => _selectedTemplate = 'Clássico'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _TemplateStyleChip(
                    name: 'Moderno',
                    icon: Icons.auto_awesome_outlined,
                    isSelected: _selectedTemplate == 'Moderno',
                    onTap: () => setState(() => _selectedTemplate = 'Moderno'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _TemplateStyleChip(
                    name: 'Compacto',
                    icon: Icons.view_stream_outlined,
                    isSelected: _selectedTemplate == 'Compacto',
                    onTap: () => setState(() => _selectedTemplate = 'Compacto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Dados da Empresa ────────────────────────────────
            Text(
              'Dados da Empresa',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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

            // ─── Preview ─────────────────────────────────────────
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
                            Icons.receipt_long,
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
                          'Template: $_selectedTemplate',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

            // ─── Botões ──────────────────────────────────────────
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
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
