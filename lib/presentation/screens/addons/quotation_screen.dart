import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/share/quotation_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/quotation.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/quotation_use_cases.dart';
import '../../controllers/invoice_template_providers.dart';
import '../../controllers/quotation_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/smart_amount.dart';
import '../../widgets/empty_state.dart';
import 'document_shared.dart';

/// Ecra de cotações/orçamentos — lista e criação de cotações.
///
/// Slice 2 do Fix #1: as partes verbatim-comuns com a Factura
/// Personalizada (resolução de loja, sheet de criação, sheet de modelo e
/// helpers de sabor/quantidade) vivem agora em `document_shared.dart` —
/// este ficheiro guarda apenas o que é exclusivo de cotações (cartão com
/// transição de estado, status chip, PDF/WhatsApp da cotação).
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final storeId = activeStoreId(ref);

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
                store: activeStore(ref),
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
      builder: (_) => DocumentFormSheet(
        kind: DocumentKind.quotation,
        onSave: _saveQuotation,
      ),
    );
  }

  /// Persiste a cotação de VERDADE (nunca lista em memória): valida via
  /// use case de domínio e grava no repositório da loja activa.
  Future<void> _saveQuotation(DocumentDraft data) async {
    final l10n = context.l10n;
    final storeId = activeStoreId(ref);
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
      final storeId = activeStoreId(ref);
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
      builder: (_) =>
          const DocumentTemplateSettingsSheet(kind: DocumentKind.quotation),
    );
  }
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
      final unitsText = qtyToUnitsText(item.quantity);
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
      primaryColor: flutterColorToPdf(config.primaryColor),
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
        AppColors.successNeutral,
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
        AppColors.successNeutral,
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
