import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/share/quotation_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/quotation.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Ecra de cotações/orçamentos — lista e criação de cotações.
class QuotationScreen extends ConsumerStatefulWidget {
  const QuotationScreen({super.key});

  @override
  ConsumerState<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends ConsumerState<QuotationScreen> {
  final List<_QuotationDraft> _drafts = [];
  int _quotationCounter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
      ),
      body: _drafts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.request_quote_outlined,
                      size: 48,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nenhuma cotação',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Crie cotações e orçamentos para os seus clientes',
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
              itemCount: _drafts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) {
                final draft = _drafts[index];
                return _QuotationCard(
                  draft: draft,
                  quotationNumber: _quotationCounter - index,
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

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({required this.draft, this.quotationNumber = 0});

  final _QuotationDraft draft;
  final int quotationNumber;

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
                    draft.clientName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _StatusChip(status: draft.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${draft.items.length} itens  •  Validade: ${draft.validityDays} dias${draft.clientPhone.isNotEmpty ? '  •  ${draft.clientPhone}' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatMoney(draft.totalCents),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'WhatsApp',
                    icon: const Icon(Icons.share_outlined, size: 16),
                    onPressed: () => _shareWhatsApp(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppButton.secondary(
                    label: 'PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    onPressed: () => _exportPdf(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (draft.status == _QuotationStatus.draft)
                  Expanded(
                    child: AppButton.primary(
                      label: 'Enviar',
                      icon: const Icon(Icons.send_outlined, size: 16),
                      onPressed: () => draft.status = _QuotationStatus.sent,
                    ),
                  ),
                if (draft.status == _QuotationStatus.sent) ...[
                  Expanded(
                    child: AppButton.primary(
                      label: 'Aceitar',
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      onPressed: () => draft.status = _QuotationStatus.accepted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AppButton.danger(
                      label: 'Rejeitar',
                      onPressed: () => draft.status = _QuotationStatus.rejected,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
      buffer.writeln('• ${item.name} x${item.qty} — ${_formatMoney(item.unitPriceCents)}');
    }
    buffer.writeln();
    buffer.writeln('TOTAL: ${_formatMoney(draft.totalCents)}');

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

    await const QuotationPdfExporter().sharePdf(
      quotation,
      businessName: 'Minha Empresa',
    );
  }

  String _formatMoney(int cents) {
    final v = cents / 100;
    return '${v.toStringAsFixed(2)} MT';
  }
}

class _NewQuotationSheet extends ConsumerStatefulWidget {
  const _NewQuotationSheet({required this.onSave});

  final ValueChanged<_QuotationDraft> onSave;

  @override
  ConsumerState<_NewQuotationSheet> createState() => _NewQuotationSheetState();
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
            _sectionLabel('Cliente'),
            const SizedBox(height: 6),
            if (customers.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: AppRadius.mdAll,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCustomerId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: InputDecoration(
                    hintText: 'Selecionar cliente...',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12,
                    ),
                  ),
                  items: customers
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.name}${c.phone.isNotEmpty ? ' (${c.phone})' : ''}',
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedCustomerId = id;
                      final c = customers.firstWhere((x) => x.id == id);
                      _clientController.text = c.name;
                      _phoneController.text = c.phone;
                    });
                  },
                ),
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
            _sectionLabel('Produto'),
            const SizedBox(height: 6),
            if (activeProducts.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: AppRadius.mdAll,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  isExpanded: true,
                  menuMaxHeight: 250,
                  decoration: InputDecoration(
                    hintText: 'Selecionar produto...',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12,
                    ),
                  ),
                  items: activeProducts
                      .map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(p.name,
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  'Estoque: ${p.stockQuantity ~/ 1000} ${p.unitLabel}  •  ${_formatMoney(p.salePriceCents)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      _selectedProductId = id;
                      final p = activeProducts.firstWhere((x) => x.id == id);
                      _priceController.text =
                          (p.salePriceCents / 100).toStringAsFixed(2);
                    });
                  },
                ),
              )
            else
              InputDecorator(
                decoration: InputDecoration(
                  hintText: 'Sem produtos cadastrados',
                  prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                        _formatMoney(
                            entry.value.unitPriceCents * entry.value.qty),
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
                'Total: ${_formatMoney(_totalCents)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatMoney(int cents) {
    final v = cents / 100;
    return '${v.toStringAsFixed(2)} MT';
  }
}

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
