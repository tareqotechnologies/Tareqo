import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
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
              itemBuilder: (context, index) =>
                  _InvoiceCard(invoice: _invoices[index]),
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
          setState(() => _invoices.insert(0, data));
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
      builder: (_) => _TemplateSettingsSheet(),
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
  const _InvoiceCard({required this.invoice});

  final _InvoiceData invoice;

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
                  label: 'Enviar',
                  onPressed: () {},
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

class _TemplateSettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
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
          Text(
            'Personalise o layout das suas facturas com logotipo, '
            'cores, campos adicionais e rodapé personalizado.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Template selection
          _TemplateOption(
            name: 'Clássico',
            description: 'Layout limpo e profissional',
            isSelected: true,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          _TemplateOption(
            name: 'Moderno',
            description: 'Design minimalista com cores vibrantes',
            isSelected: false,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xs),
          _TemplateOption(
            name: 'Compacto',
            description: 'Otimizado para impressão térmica',
            isSelected: false,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.secondary(
            expanded: true,
            label: 'Fechar',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
  const _TemplateOption({
    required this.name,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final String description;
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
