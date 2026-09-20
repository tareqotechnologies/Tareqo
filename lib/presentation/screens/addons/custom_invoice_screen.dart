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
import '../../../core/utils/ids.dart';
import '../../../domain/entities/custom_invoice.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/custom_invoice_use_cases.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/custom_invoice_providers.dart';
import '../../controllers/invoice_template_providers.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/products_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_picker_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/color_palette.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import 'custom_invoice_preview.dart';

/// Ecra de facturas personalizadas — criação e gestão de facturas
/// com layout customizável.
class CustomInvoiceScreen extends ConsumerStatefulWidget {
  const CustomInvoiceScreen({super.key});

  @override
  ConsumerState<CustomInvoiceScreen> createState() =>
      _CustomInvoiceScreenState();
}

class _CustomInvoiceScreenState extends ConsumerState<CustomInvoiceScreen> {
  /// Template PERSISTENTE do PDF (prefs via [invoiceTemplateProvider]) —
  /// antes vivia só no State da tela e era perdido ao reabrir o app,
  /// fazendo o PDF sair sempre com o design padrão.
  InvoiceTemplateConfig get _templateConfig => ref.watch(invoiceTemplateProvider);

  /// Loja activa (as facturas são documento POR loja — número sequencial
  /// dentro da loja). Resolvida como nas demais telas de dados.
  String? _activeStoreId() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return null;
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return null;
    final storeId = ref.watch(activeStoreIdProvider(user.id));
    if (storeId != null) return storeId;
    // Sem loja activa: cai para a primeira loja do tenant (como vendas).
    final stores =
        ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    return stores.isEmpty ? null : stores.first.id;
  }

  /// Loja activa (entidade) — nome/contatos reais para o PDF.
  Store? _activeStore() {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return null;
    final tenant = ref.watch(myTenantProvider(user.id)).value;
    if (tenant == null) return null;
    final stores =
        ref.watch(storesProvider(tenant.id)).value ?? const <Store>[];
    if (stores.isEmpty) return null;
    final storeId = ref.watch(activeStoreIdProvider(user.id));
    return stores.where((s) => s.id == storeId).firstOrNull ?? stores.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final storeId = _activeStoreId();

    // Facturas PERSISTIDAS desta loja (estado real, não lista local).
    // Sem loja (ex.: onboarding incompleto) a tela mostra vazio honesto.
    final invoicesAsync = storeId == null
        ? null
        : ref.watch(customInvoicesProvider(storeId));
    final invoices = invoicesAsync?.value ?? const <CustomInvoice>[];

    return AppPage(
      title: l10n.customInvoiceTitle,
      // Título 3 (20/w600) — rótulo longo ('Factura Personalizada')
      // truncava em titleLarge (22) no AppBar de 56px.
      titleStyle: Theme.of(context).textTheme.titleMedium,
      useSafeArea: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: _openTemplateSettings,
          tooltip: l10n.customInvoiceTemplateTooltip,
        ),
      ],
      body: invoicesAsync?.hasError ?? false
          ? EmptyState(
              icon: Icons.error_outline,
              title: l10n.customInvoiceLoadError,
              subtitle: l10n.customInvoiceLoadErrorHint,
              actionLabel: l10n.commonRetry,
              onAction: () {
                if (storeId != null) {
                  ref.invalidate(customInvoicesProvider(storeId));
                }
              },
            )
          : invoices.isEmpty
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
              itemCount: invoices.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _InvoiceCard(
                invoice: invoices[index],
                templateConfig: _templateConfig,
                store: _activeStore(),
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
      builder: (_) => _NewInvoiceSheet(onSave: _saveInvoice),
    );
  }

  /// Persiste a factura de VERDADE (nunca lista em memória): valida via
  /// use case de domínio e grava no repositório da loja activa.
  Future<void> _saveInvoice(_InvoiceData data) async {
    final l10n = context.l10n;
    final storeId = _activeStoreId();
    if (storeId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    // Fecha a sheet só após a gravação confirmada (loading honesto).
    final navigator = Navigator.of(context);

    try {
      final entity = CreateCustomInvoiceUseCase().call(
        storeId: storeId,
        clientName: data.clientName,
        clientPhone: data.clientPhone,
        clientTaxId: data.clientTaxId,
        items: [
          for (final item in data.items)
            CustomInvoiceItemInput(
              productName: item.name,
              // Convenção W11 do app: quantidade em MILÉSIMOS
              // (1000 = 1 unidade) — o exporter do PDF e o preview
              // textual dividem por 1000. Sem o ×1000, o PDF mostrava
              // "0.0 un" (qty crua 2 ÷ 1000) e a quantidade ficava
              // errada na factura impressa.
              quantity: item.qty * 1000,
              unitPriceCents: item.unitPriceCents,
            ),
        ],
        discountCents: data.discountCents,
        taxCents: data.taxCents,
      );
      final saved = await ref
          .read(customInvoiceRepositoryProvider)
          .add(entity.copyWith(id: AppIds.newId('ci')));
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.customInvoiceCreated(saved.number))),
      );
      ref.invalidate(customInvoicesProvider(storeId));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.customInvoiceSaveError)),
      );
    }
  }

  void _openTemplateSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _TemplateSettingsSheet(),
    );
  }
}

class _InvoiceData {
  _InvoiceData({
    required this.clientName,
    required this.clientPhone,
    this.clientTaxId = '',
    required this.items,
    required this.totalCents,
    required this.discountCents,
    required this.taxCents,
  });

  final String clientName;
  final String clientPhone;
  final String clientTaxId;
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
    this.templateConfig,
    this.store,
  });

  /// Factura PERSISTIDA (número sequencial real da loja vem da entidade).
  final CustomInvoice invoice;
  final InvoiceTemplateConfig? templateConfig;

  /// Loja activa — nome/contatos reais entram no PDF quando o template
  /// não define dados da empresa.
  final Store? store;

  /// Nome real da loja (fallback do nome no PDF).
  String? get storeName => store?.name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
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
                      // Nome COMPLETO — quebra em linhas quando necessário
                      // (nunca truncar o nome do cliente).
                      invoice.clientName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.customInvoiceNumberPrefix(
                            invoice.number.toString().padLeft(5, '0'),
                          ) +
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
                Formatters.currency(invoice.totalAmountCents),
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
          // Acções — Wrap (não Row): em ecrãs estreitos os botões fluem
          // para a linha seguinte em vez de estourarem/cortarem o rótulo.
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton.secondary(
                label: l10n.customInvoiceWhatsApp,
                icon: const Icon(Icons.share_outlined, size: 16),
                onPressed: () => _shareWhatsApp(context),
              ),
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

  /// Milésimos → texto de unidades ("2" ou "1.5" para frações).
  String _qtyToUnits(int millesimos) {
    final units = millesimos / 1000;
    return units == units.roundToDouble()
        ? units.toStringAsFixed(0)
        : units.toStringAsFixed(2);
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    buffer.writeln(l10n.customInvoiceWhatsAppHeader);
    buffer.writeln(
      '${l10n.customInvoiceNumberShort}: ${invoice.number.toString().padLeft(5, '0')}',
    );
    buffer.writeln('${l10n.customInvoiceClientLabel}: ${invoice.clientName}');
    if (invoice.clientPhone.isNotEmpty) {
      buffer.writeln('${l10n.customInvoicePhoneLabel}: ${invoice.clientPhone}');
    }
    buffer.writeln();
    for (final item in invoice.items) {
      buffer.writeln(
        // Quantidade guardada em MILÉSIMOS (1000 = 1 unidade) — exibir
        // em unidades reais (mesmo padrão do card da cotação).
        '• ${item.productName} x${_qtyToUnits(item.quantity)} — '
        '${Formatters.currency((item.unitPriceCents * item.quantity / 1000).round())}',
      );
    }
    buffer.writeln();
    buffer.writeln(
      '${l10n.customInvoiceTotalLabel}: ${Formatters.currency(invoice.totalAmountCents)}',
    );

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _exportPdf(BuildContext context) async {
    // Exporta a factura PERSISTIDA tal como está (número, itens, data
    // reais) — sem reconstruir uma entidade sintética.
    final invoiceEntity = invoice;

    final config = templateConfig ?? InvoiceTemplateConfig();
    final l10n = context.l10n;
    await InvoicePdfExporter().sharePdf(
      invoiceEntity,
      templateStyle: config.templateStyle,
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
      // Nome do negócio: template preenchido → nome da LOJA real
      // (dono vê a própria loja; funcionário pode não ter acesso a stores,
      // aí cai no fallback do template) → fallback localizado.
      businessName: config.businessName.isNotEmpty
          ? config.businessName
          : (storeName?.isNotEmpty ?? false)
          ? storeName!
          : l10n.businessFallbackName,
      businessAddress: config.businessAddress.isNotEmpty
          ? config.businessAddress
          : (store?.address.isNotEmpty ?? false)
          ? store!.address
          : null,
      businessPhone: config.businessPhone.isNotEmpty
          ? config.businessPhone
          : (store?.phone.isNotEmpty ?? false)
          ? store!.phone
          : null,
      businessTaxId: config.businessTaxId.isNotEmpty
          ? config.businessTaxId
          : (store?.nuit.isNotEmpty ?? false)
          ? store!.nuit
          : null,
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
      _items.add(
        _InvoiceItemData(
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
                              fontSize: 11,
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
                        onTap: () => setState(() => _items.removeAt(entry.key)),
                        child: Icon(Icons.close, size: 16, color: scheme.error),
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
              onPressed:
                  _clientController.text.trim().isNotEmpty && _items.isNotEmpty
                  ? () {
                      widget.onSave(
                        _InvoiceData(
                          clientName: _clientController.text.trim(),
                          clientPhone: _phoneController.text.trim(),
                          clientTaxId: _taxIdController.text.trim(),
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

class _TemplateSettingsSheet extends ConsumerStatefulWidget {
  const _TemplateSettingsSheet();

  @override
  ConsumerState<_TemplateSettingsSheet> createState() =>
      _TemplateSettingsSheetState();
}

class _TemplateSettingsSheetState
    extends ConsumerState<_TemplateSettingsSheet> {
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
            templateStyle: _selectedTemplate,
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
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
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
                    onTap: () => setState(() => _selectedTemplate = 'Classic'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _TemplateStyleChip(
                    name: l10n.customInvoiceTemplateStyleModern,
                    icon: Icons.auto_awesome_outlined,
                    isSelected: _selectedTemplate == 'Modern',
                    onTap: () => setState(() => _selectedTemplate = 'Modern'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _TemplateStyleChip(
                    name: l10n.customInvoiceTemplateStyleCompact,
                    icon: Icons.view_stream_outlined,
                    isSelected: _selectedTemplate == 'Compact',
                    onTap: () => setState(() => _selectedTemplate = 'Compact'),
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
            CustomInvoicePreview(
              businessName: _nameController.text,
              businessAddress: _addressController.text,
              businessPhone: _phoneController.text,
              businessTaxId: _taxIdController.text,
              logoBytes: _logoBytes,
              primaryColor: _selectedColor,
              currencySymbol: Formatters.currencySymbol,
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
///
/// `color.r/g/b` JÁ são normalizados (0.0–1.0) no Flutter moderno —
/// dividir por 255 os esmagava para ~0 e o PDF saía sempre PRETO,
/// independentemente da cor do tema escolhida.
PdfColor _flutterColorToPdf(Color color) {
  return PdfColor(color.r, color.g, color.b, color.a);
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
