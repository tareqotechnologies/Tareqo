import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/share/invoice_pdf_exporter.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/ids.dart';
import '../../../domain/entities/custom_invoice.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/custom_invoice_use_cases.dart';
import '../../controllers/custom_invoice_providers.dart';
import '../../controllers/invoice_template_providers.dart';
import '../../widgets/app_page.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import 'document_shared.dart';

/// Ecra de facturas personalizadas — criação e gestão de facturas
/// com layout customizável.
///
/// Slice 2 do Fix #1: as partes verbatim-comuns com a Cotação
/// (resolução de loja, sheet de criação, sheet de modelo e helpers de
/// cor/quantidade) vivem agora em `document_shared.dart` — este ficheiro
/// guarda apenas o que é exclusivo da factura (cartão com desconto/IVA,
/// PDF/WhatsApp da factura, preview de template embutido).
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
  InvoiceTemplateConfig get _templateConfig =>
      ref.watch(invoiceTemplateProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final horizontal = AppSpacing.pagePaddingForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final storeId = activeStoreId(ref);

    // Facturas PERSISTIDAS desta loja (estado real, não lista local).
    // Sem loja (ex.: onboarding incompleto) a tela mostra vazio honesto.
    final invoicesAsync = storeId == null
        ? null
        : ref.watch(customInvoicesProvider(storeId));
    final invoices = invoicesAsync?.value ?? const <CustomInvoice>[];

    return AppPage(
      title: l10n.customInvoiceTitle,
      // Rótulo longo ('Factura Personalizada') cabe em titleMedium (16).
      titleStyle: AppTypography.titleMedium,
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
                AppSpacing.sm,
                horizontal,
                AppSpacing.fabBottomClearance,
              ),
              itemCount: invoices.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (context, index) => _InvoiceCard(
                invoice: invoices[index],
                templateConfig: _templateConfig,
                store: activeStore(ref),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-invoice',
        onPressed: _openNewInvoice,
        tooltip: l10n.customInvoiceNewFab,
        child: const Icon(Icons.add_rounded, size: AppSizes.iconXl),
      ),
    );
  }

  void _openNewInvoice() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          DocumentFormSheet(kind: DocumentKind.invoice, onSave: _saveInvoice),
    );
  }

  /// Persiste a factura de VERDADE (nunca lista em memória): valida via
  /// use case de domínio e grava no repositório da loja activa.
  Future<void> _saveInvoice(DocumentDraft data) async {
    final l10n = context.l10n;
    final storeId = activeStoreId(ref);
    if (storeId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    // Fecha a sheet só após a gravação confirmada (loading honesto).
    final navigator = Navigator.of(context);

    try {
      final entity = const CreateCustomInvoiceUseCase().call(
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
      builder: (_) =>
          const DocumentTemplateSettingsSheet(kind: DocumentKind.invoice),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Invoice Card — minimalista, padrão AppCard
// ═══════════════════════════════════════════════════════════════════════════════

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, this.templateConfig, this.store});

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

    // Card MINIMALISTA (mesmo padrão do fiado — _DebtCard): uma linha de
    // conteúdo + acções como ÍCONES discretos à direita. Sem avatar, sem
    // bloco de botões em largura total — o documento é a informação, não
    // a moldura.
    return AppCard(
      elevated: true,
      borderRadius: AppRadius.lgAll,
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
                    // Nome + nº sequencial INLINE (padrão Wrap do fiado) —
                    // nome COMPLETO quebra em linhas quando necessário
                    // (nunca truncar o nome do cliente).
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          invoice.clientName,
                          style: AppTypography.labelLarge.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          l10n.customInvoiceNumberPrefix(
                            invoice.number.toString().padLeft(5, '0'),
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    // Metadados em UMA linha discreta: itens · telefone.
                    Text(
                      '${l10n.customInvoiceItemsCount(invoice.items.length)}'
                      '${invoice.clientPhone.isNotEmpty ? '  •  ${invoice.clientPhone}' : ''}',
                      style: AppTypography.bodySmall.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Valor à DIREITA em destaque (padrão dos cards do app).
              Text(
                Formatters.currency(invoice.totalAmountCents),
                style: AppTypography.amountInRow(scheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Acções como ÍCONES discretos no canto (padrão das linhas de
          // itens da sheet): WhatsApp e PDF — rótulos ficam nos tooltips.
          Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: AppSizes.iconMd),
                color: scheme.onSurfaceVariant,
                tooltip: l10n.customInvoiceWhatsApp,
                onPressed: () => _shareWhatsApp(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: AppSizes.iconMd,
                ),
                color: scheme.onSurfaceVariant,
                tooltip: l10n.customInvoicePdf,
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
        '• ${item.productName} x${qtyToUnitsText(item.quantity)} — '
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
    await const InvoicePdfExporter().sharePdf(
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
      primaryColor: flutterColorToPdf(config.primaryColor),
    );
  }
}
