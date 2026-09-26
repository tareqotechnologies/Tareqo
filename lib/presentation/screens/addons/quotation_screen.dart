import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/share/quotation_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/quotation.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/quotation_use_cases.dart';
import '../../controllers/account_providers.dart';
import '../../controllers/auth_providers.dart';
import '../../controllers/customers_providers.dart';
import '../../controllers/invoice_template_providers.dart';
import '../../controllers/products_providers.dart';
import '../../controllers/quotation_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_picker_field.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/color_palette.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';

/// Ecra de cotações/orçamentos — lista e criação de cotações.
class QuotationScreen extends ConsumerStatefulWidget {
  const QuotationScreen({super.key});

  @override
  ConsumerState<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends ConsumerState<QuotationScreen> {
  /// Template PERSISTENTE (prefs via [invoiceTemplateProvider]) — antes
  /// vivia só no State da tela e era perdido ao reabrir o app.
  InvoiceTemplateConfig get _templateConfig =>
      ref.watch(invoiceTemplateProvider);

  /// Loja activa (as cotações são documento POR loja — número sequencial
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

    // Cotações PERSISTIDAS desta loja (estado real, não lista local).
    // Sem loja (ex.: onboarding incompleto) a tela mostra vazio honesto.
    final quotationsAsync = storeId == null
        ? null
        : ref.watch(quotationsProvider(storeId));
    final quotations = quotationsAsync?.value ?? const <Quotation>[];

    return AppPage(
      title: l10n.quotationTitle,
      // Título 3 (20/w600) — rótulo longo ('Cotações / Orçamentos')
      // truncava em titleLarge (22) no AppBar de 56px.
      titleStyle: Theme.of(context).textTheme.titleMedium,
      useSafeArea: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20),
          onPressed: _openTemplateSettings,
          tooltip: l10n.quotationTemplateTooltip,
        ),
      ],
      body: quotationsAsync?.hasError ?? false
          ? EmptyState(
              icon: Icons.error_outline,
              title: l10n.quotationLoadError,
              subtitle: l10n.quotationLoadErrorHint,
              actionLabel: l10n.commonRetry,
              onAction: () {
                if (storeId != null) {
                  ref.invalidate(quotationsProvider(storeId));
                }
              },
            )
          : quotations.isEmpty
          ? EmptyState(
              icon: Icons.request_quote_outlined,
              title: l10n.quotationEmpty,
              subtitle: l10n.quotationEmptySubtitle,
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                AppSpacing.lg,
                horizontal,
                AppSpacing.lg,
              ),
              itemCount: quotations.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _QuotationCard(
                quotation: quotations[index],
                templateConfig: _templateConfig,
                store: _activeStore(),
                onStatusChanged: _updateStatus,
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-quotation',
        onPressed: _openNewQuotation,
        tooltip: l10n.quotationNewFab,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _openNewQuotation() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _NewQuotationSheet(onSave: _saveQuotation),
    );
  }

  /// Persiste a cotação de VERDADE (nunca lista em memória): valida via
  /// use case de domínio e grava no repositório da loja activa.
  Future<void> _saveQuotation(_QuotationDraft data) async {
    final l10n = context.l10n;
    final storeId = _activeStoreId();
    if (storeId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    // Fecha a sheet só após a gravação confirmada (loading honesto).
    final navigator = Navigator.of(context);

    try {
      final entity = const CreateQuotationUseCase().call(
        storeId: storeId,
        customer: Customer(
          id: data.customerId ?? '',
          storeId: storeId,
          name: data.clientName,
          phone: data.clientPhone,
        ),
        items: [
          for (final item in data.items)
            QuotationItemInput(
              productId: '',
              productName: item.name,
              quantity: item.qty * 1000,
              unitPriceCents: item.unitPriceCents,
            ),
        ],
        validityDays: data.validityDays,
      );
      final saved = await ref
          .read(quotationRepositoryProvider)
          .add(entity.copyWith(id: AppIds.newId('qt')));
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.quotationCreated(saved.number))),
      );
      ref.invalidate(quotationsProvider(storeId));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.quotationSaveError)));
    }
  }

  /// Grava uma transição de estado (rascunho → enviada → aceite/rejeitada)
  /// de VERDADE no repositório — nunca mutação local que some ao sair.
  Future<void> _updateStatus(
    Quotation quotation,
    QuotationStatus status,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();

    try {
      final updated = quotation.copyWith(
        status: status,
        sentAt: status == QuotationStatus.sent ? now : quotation.sentAt,
        acceptedAt: status == QuotationStatus.accepted
            ? now
            : quotation.acceptedAt,
        rejectedAt: status == QuotationStatus.rejected
            ? now
            : quotation.rejectedAt,
      );
      await ref.read(quotationRepositoryProvider).update(updated);
      final storeId = _activeStoreId();
      if (storeId != null) {
        ref.invalidate(quotationsProvider(storeId));
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.quotationStatusSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.quotationStatusError)),
      );
    }
  }

  void _openTemplateSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _QuotationTemplateSettingsSheet(),
    );
  }
}

class _QuotationDraft {
  _QuotationDraft({
    required this.clientName,
    this.clientPhone = '',
    this.customerId,
    required this.items,
    required this.totalCents,
    required this.validityDays,
  });

  final String clientName;
  final String clientPhone;

  /// Cliente REAL seleccionado na sheet (null = nome digitado manualmente).
  final String? customerId;

  final List<_QuotationItemData> items;
  final int totalCents;
  final int validityDays;
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
    required this.quotation,
    this.templateConfig,
    this.store,
    required this.onStatusChanged,
  });

  /// Cotação PERSISTIDA (número sequencial real da loja vem da entidade).
  final Quotation quotation;
  final InvoiceTemplateConfig? templateConfig;

  /// Loja activa — nome/contatos reais entram no PDF quando o template
  /// não define dados da empresa.
  final Store? store;
  final void Function(Quotation quotation, QuotationStatus status)
  onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final validityDays = quotation.validUntil
        .difference(DateTime.now())
        .inDays
        .clamp(0, 365);

    // Card LEVE (mesmo padrão do card da Factura Personalizada — _InvoiceCard):
    // sem avatar, nome + nº + estado INLINE, metadados numa linha discreta e
    // valor à direita. O documento é a informação, não a moldura.
    return AppCard(
      elevated: true,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome + nº sequencial + estado INLINE (padrão Wrap do
                    // fiado) — nome COMPLETO quebra em linhas quando
                    // necessário (nunca truncar o nome do cliente).
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          quotation.customerName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.quotationNumberPrefix(
                            quotation.number.toString().padLeft(5, '0'),
                          ),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        _StatusChip(status: quotation.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Metadados em UMA linha discreta: itens · validade ·
                    // telefone.
                    Text(
                      '${l10n.quotationItemsCount(quotation.items.length)}'
                      '  •  ${l10n.quotationValidity}: '
                      '${l10n.quotationDays(validityDays)}'
                      '${quotation.customerPhone.isNotEmpty ? '  •  ${quotation.customerPhone}' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Valor à DIREITA em destaque — SmartAmount ENCOLHE para
              // caber (nunca trunca) e alinha dígito a dígito (tabular).
              Flexible(
                child: SmartAmount(
                  cents: quotation.totalAmountCents,
                  alignment: Alignment.centerRight,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ações em UMA linha: fluxo de estado (rótulos — decisão de
          // negócio, precisa ser legível) à esquerda; WhatsApp e PDF como
          // ÍCONES discretos à direita (padrão da Factura Personalizada).
          // Wrap nos dois grupos: em telas estreitas/escala alta os botões
          // fluem para a linha seguinte em vez de estourar.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (quotation.status == QuotationStatus.draft)
                    AppButton.primary(
                      label: l10n.quotationSend,
                      onPressed: () =>
                          onStatusChanged(quotation, QuotationStatus.sent),
                    ),
                  if (quotation.status == QuotationStatus.sent) ...[
                    AppButton.primary(
                      label: l10n.quotationAccept,
                      onPressed: () =>
                          onStatusChanged(quotation, QuotationStatus.accepted),
                    ),
                    AppButton.danger(
                      label: l10n.quotationReject,
                      onPressed: () =>
                          onStatusChanged(quotation, QuotationStatus.rejected),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 18),
                    color: scheme.onSurfaceVariant,
                    tooltip: l10n.customInvoiceWhatsApp,
                    onPressed: () => _shareWhatsApp(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    color: scheme.onSurfaceVariant,
                    tooltip: l10n.customInvoicePdf,
                    onPressed: () => _exportPdf(context),
                  ),
                ],
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
    buffer.writeln(l10n.quotationWhatsAppHeader);
    buffer.writeln(
      '${l10n.customInvoiceNumberShort}: '
      '${quotation.number.toString().padLeft(5, '0')}',
    );
    buffer.writeln(
      '${l10n.customInvoiceClientLabel}: ${quotation.customerName}',
    );
    if (quotation.customerPhone.isNotEmpty) {
      buffer.writeln(
        '${l10n.customInvoicePhoneLabel}: ${quotation.customerPhone}',
      );
    }
    final validityDays = quotation.validUntil
        .difference(DateTime.now())
        .inDays
        .clamp(0, 365);
    buffer.writeln(
      '${l10n.quotationValidity}: '
      '${l10n.quotationDays(validityDays)}',
    );
    buffer.writeln();
    for (final item in quotation.items) {
      // Quantidade guardada em MILÉSIMOS (1000 = 1 unidade).
      final units = item.quantity / 1000;
      final unitsText = units == units.roundToDouble()
          ? units.toStringAsFixed(0)
          : units.toStringAsFixed(2);
      buffer.writeln(
        '• ${item.productName} x$unitsText — '
        '${Formatters.currency((item.unitPriceCents * item.quantity / 1000).round())}',
      );
    }
    buffer.writeln();
    buffer.writeln(
      '${l10n.customInvoiceTotalLabel}: '
      '${Formatters.currency(quotation.totalAmountCents)}',
    );

    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(buffer.toString())}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _exportPdf(BuildContext context) async {
    // Exporta a cotação PERSISTIDA tal como está (número, itens, estado,
    // validade reais) — sem reconstruir uma entidade sintética.
    final quotationEntity = quotation;

    final config = templateConfig ?? InvoiceTemplateConfig();
    final l10n = context.l10n;
    await const QuotationPdfExporter().sharePdf(
      quotationEntity,
      templateStyle: config.templateStyle,
      labels: QuotationPdfLabels(
        docWord: l10n.pdfQuotationDocWord,
        numberLabelTemplate: l10n.quotationNumberPrefix('{number}'),
        clientHeading: l10n.pdfClientHeading,
        phoneLabelTemplate: l10n.pdfPhoneLine('{value}'),
        taxIdLabelTemplate: l10n.pdfNifLine('{value}'),
        itemHeader: l10n.pdfItemHeader,
        qtyHeader: l10n.customInvoiceQty,
        unitPriceHeader: l10n.pdfUnitPriceHeader,
        subtotalHeader: l10n.pdfSubtotalHeader,
        discountLabel: l10n.pdfDiscountLabel,
        totalLabel: l10n.customInvoiceTotalLabel,
        validityHeading: l10n.quotationValidity,
        notesHeading: l10n.pdfConditionsNotesHeading,
        generalConditionsHeading: l10n.pdfGeneralConditionsHeading,
        validConditionTemplate: l10n.pdfConditionValidBullet('{date}'),
        pricesConditionText: l10n.pdfConditionPricesBullet,
        contactConditionText: l10n.pdfConditionContactBullet,
        footerTemplate: l10n.pdfFooter('{date}'),
        fileNameBase: l10n.pdfQuotationFileBase,
        subjectWord: l10n.pdfQuotationSubjectWord,
        statusText: (status) => switch (status) {
          QuotationStatus.draft => l10n.quotationStatusDraft,
          QuotationStatus.sent => l10n.quotationStatusSent,
          QuotationStatus.accepted => l10n.quotationStatusAccepted,
          QuotationStatus.rejected => l10n.quotationStatusRejected,
          QuotationStatus.expired => l10n.quotationStatusExpired,
          QuotationStatus.converted => l10n.quotationStatusConverted,
        },
        daysLeftText: (days) => days > 0
            ? l10n.pdfValidityDaysLeft(days)
            : l10n.quotationStatusExpired,
      ),
      // Nome do negócio: template preenchido → nome da LOJA real →
      // fallback localizado (nunca 'My Business' com loja conhecida).
      businessName: config.businessName.isNotEmpty
          ? config.businessName
          : (store?.name.isNotEmpty ?? false)
          ? store!.name
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
// New Quotation Sheet
// ═══════════════════════════════════════════════════════════════════════════════

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
    final products = ref.read(productsProvider).value ?? [];
    final product = products
        .where((p) => p.id == _selectedProductId)
        .firstOrNull;
    // Produto não encontrado → ignora (antes o fallback caía no PRIMEIRO
    // produto da lista, adicionando um item errado à cotação).
    if (product == null) return;

    final price = double.tryParse(_priceController.text) ?? 0;
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (price <= 0 || qty <= 0) return;

    setState(() {
      _items.add(
        _QuotationItemData(
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

  void _removeItem(int index) => setState(() => _items.removeAt(index));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
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
              l10n.customInvoiceNew,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ─── Cliente ──
            _SectionLabel(text: l10n.customInvoiceClientSection),
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
              label: l10n.quotationPhoneOptional,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // ─── Produto ──
            _SectionLabel(text: l10n.customInvoiceProductSection),
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
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
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
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: scheme.primary,
                      ),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _removeItem(entry.key),
                        child: Icon(Icons.close, size: 16, color: scheme.error),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.customInvoiceBillTotal(Formatters.currency(_totalCents)),
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
              label: l10n.quotationSave,
              onPressed:
                  _clientController.text.trim().isNotEmpty && _items.isNotEmpty
                  ? () {
                      widget.onSave(
                        _QuotationDraft(
                          clientName: _clientController.text.trim(),
                          clientPhone: _phoneController.text.trim(),
                          customerId: _selectedCustomerId,
                          items: List.from(_items),
                          totalCents: _totalCents,
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
// Settings Sheet (usa o template PERSISTENTE de invoice_template_providers)
// ═══════════════════════════════════════════════════════════════════════════════

class _QuotationTemplateSettingsSheet extends ConsumerStatefulWidget {
  const _QuotationTemplateSettingsSheet();

  @override
  ConsumerState<_QuotationTemplateSettingsSheet> createState() =>
      _QuotationTemplateSettingsSheetState();
}

class _QuotationTemplateSettingsSheetState
    extends ConsumerState<_QuotationTemplateSettingsSheet> {
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
    // Config PERSISTIDA (provider) — o sheet edita e grava no Salvar.
    final c = ref.read(invoiceTemplateProvider);
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
            templateStyle: ref.read(invoiceTemplateProvider).templateStyle,
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
              l10n.quotationTemplateTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
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
                    label: l10n.quotationTemplatePhone,
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
                            child: Image.memory(_logoBytes!, fit: BoxFit.cover),
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.quotationTemplatePreview,
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
// Shared widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final QuotationStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final (label, color) = switch (status) {
      QuotationStatus.draft => (
        l10n.quotationStatusDraft,
        AppColors.statusWarning,
      ),
      QuotationStatus.sent => (l10n.quotationStatusSent, AppColors.statusInfo),
      QuotationStatus.accepted => (
        l10n.quotationStatusAccepted,
        AppColors.success,
      ),
      QuotationStatus.rejected => (
        l10n.quotationStatusRejected,
        AppColors.statusError,
      ),
      QuotationStatus.expired => (
        l10n.quotationStatusExpired,
        AppColors.statusError,
      ),
      QuotationStatus.converted => (
        l10n.quotationStatusConverted,
        AppColors.success,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.xs),
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
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Converte uma [Color] do Flutter para [PdfColor] do pdf package.
///
/// `color.r/g/b` JÁ são normalizados (0.0–1.0) no Flutter moderno —
/// dividir por 255 os esmagava para ~0 e o PDF saía sempre PRETO,
/// independentemente da cor do tema escolhida.
PdfColor _flutterColorToPdf(Color color) {
  return PdfColor(color.r, color.g, color.b, color.a);
}
