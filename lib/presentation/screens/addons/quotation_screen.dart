import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/share/quotation_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/entities/quotation.dart';
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
              separatorBuilder: (_, __) =>
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
    this.notes = '',
  });

  final String clientName;
  final String clientPhone;
  final List<String> items;
  final int totalCents;
  final int validityDays;
  final String notes;
  _QuotationStatus status = _QuotationStatus.draft;
  DateTime createdAt = DateTime.now();
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
              '${draft.items.length} itens  •  Validade: ${draft.validityDays} dias',
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
    buffer.writeln('Validade: ${draft.validityDays} dias');
    buffer.writeln();
    for (final item in draft.items) {
      buffer.writeln('• $item');
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
        for (var i = 0; i < draft.items.length; i++)
          QuotationItem(
            productId: '',
            productName: draft.items[i],
            quantity: 1000,
            unitPriceCents: draft.totalCents ~/ draft.items.length,
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

class _NewQuotationSheet extends StatefulWidget {
  const _NewQuotationSheet({required this.onSave});

  final ValueChanged<_QuotationDraft> onSave;

  @override
  State<_NewQuotationSheet> createState() => _NewQuotationSheetState();
}

class _NewQuotationSheetState extends State<_NewQuotationSheet> {
  final _clientController = TextEditingController();
  final _productController = TextEditingController();
  final _priceController = TextEditingController();
  final List<String> _items = [];
  int _totalCents = 0;

  @override
  void dispose() {
    _clientController.dispose();
    _productController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    final product = _productController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0;
    if (product.isEmpty) return;

    setState(() {
      _items.add(product);
      _totalCents += (price * 100).round();
      _productController.clear();
      _priceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
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
          AppTextField(
            controller: _clientController,
            label: 'Nome do cliente',
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _productController,
            label: 'Produto',
            prefixIcon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _priceController,
            label: 'Preço unitário (MT)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.attach_money,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton.secondary(
              label: 'Adicionar Item',
              onPressed: _addItem,
            ),
          ),
          if (_items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ..._items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Total: ${_formatMoney(_totalCents)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            expanded: true,
            label: 'Guardar Cotação',
            onPressed: _clientController.text.trim().isNotEmpty && _items.isNotEmpty
                ? () {
                    widget.onSave(
                      _QuotationDraft(
                        clientName: _clientController.text.trim(),
                        items: List.from(_items),
                        totalCents: _totalCents,                    validityDays: 7,
                  ),
                );
              }
            : null,
      ),
    ],
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
