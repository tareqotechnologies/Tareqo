import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';

/// Preview estático (amostra) da factura personalizada — o mesmo desenho
/// do PDF exportado, renderizado na tela de template.
///
/// Extraído de `custom_invoice_screen.dart` (auditoria M5 — tela-god):
/// isolado aqui porque não tem estado nem dependências da tela; recebe
/// apenas os dados do negócio e a cor primária do template.
///
/// **Exceção de documento (U-12):** esta miniatura espelha um documento
/// impresso em escala reduzida — os tamanhos 10/11 px e os pesos 400/600
/// seguem a escala do tema (bodySmall/labelSmall) sem `copyWith` de
/// tamanho; o texto branco sobre `primaryColor` é a cor do template
/// escolhido pelo utilizador (identidade do documento, não do app).
class CustomInvoicePreview extends StatelessWidget {
  const CustomInvoicePreview({
    super.key,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessTaxId,
    this.logoBytes,
    required this.primaryColor,
    this.currencySymbol = 'MT',
  });

  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessTaxId;
  final Uint8List? logoBytes;
  final Color primaryColor;

  /// Símbolo monetário dos preços de amostra. O chamador passa o símbolo
  /// ativo do tenant ([Formatters.currencySymbol]) — antes estava fixo em
  /// 'MT' mesmo para negócios em outra moeda. O default preserva a
  /// amostra do metical (moeda base do produto) quando não informado.
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final displayName = businessName.isNotEmpty
        ? businessName
        : l10n.customInvoicePreviewCompanyFallback;

    // Cor escura para texto (mesma lógica do PDF exporter).
    final primaryDark = HSLColor.fromColor(primaryColor)
        .withLightness(
          (HSLColor.fromColor(primaryColor).lightness * 0.7).clamp(0.0, 1.0),
        )
        .toColor();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
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
          Container(height: AppSpacing.xxs, color: primaryColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
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
                              borderRadius: AppRadius.xsAll,
                              child: Image.memory(
                                logoBytes!,
                                width: AppSpacing.xxl,
                                height: AppSpacing.xxl,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryDark,
                                  ),
                                ),
                                if (businessAddress.isNotEmpty)
                                  Text(
                                    // Endereço COMPLETO — quebra em linhas
                                    // (nunca truncar os dados do negócio).
                                    businessAddress,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (businessPhone.isNotEmpty)
                                  Text(
                                    businessPhone,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                if (businessTaxId.isNotEmpty)
                                  Text(
                                    l10n.pdfNifLine(businessTaxId),
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
                    const SizedBox(width: AppSpacing.xs),
                    // Badge FACTURA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: AppRadius.xsAll,
                      ),
                      child: Text(
                        l10n.pdfInvoiceDocWord,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.ice,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                // Nº + data (data DINÂMICA).
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${l10n.customInvoiceNumberPrefix('00001')}  •  ${Formatters.date(DateTime.now())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Divisor
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.xs),
                // ─── Cliente ──
                Text(
                  l10n.pdfClientHeading,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  l10n.customInvoicePreviewSampleClient,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.pdfPhoneLine('84 123 4567'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // ─── Tabela de itens (miniatura) ──
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xs),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.pdfItemHeader,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ice,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: AppSizes.avatarSm,
                        child: Text(
                          l10n.customInvoiceQty,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ice,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: AppSpacing.huge + AppSpacing.xxs,
                        child: Text(
                          l10n.pdfUnitPriceHeader,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ice,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rows
                _PreviewRow(
                  name: l10n.customInvoicePreviewSampleItemA,
                  qty: '2',
                  price: '150,00',
                  currencySymbol: currencySymbol,
                  primaryColor: primaryColor,
                ),
                _PreviewRow(
                  name: l10n.customInvoicePreviewSampleItemB,
                  qty: '1',
                  price: '250,00',
                  currencySymbol: currencySymbol,
                  primaryColor: primaryColor,
                  last: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                // ─── Total ──
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: AppRadius.xsAll,
                    ),
                    child: Text(
                      l10n.customInvoicePreviewTotal('550,00 $currencySymbol'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Rodapé
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    l10n.customInvoicePreviewFooter,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
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
    required this.currencySymbol,
    required this.primaryColor,
    this.last = false,
  });

  final String name;
  final String qty;
  final String price;
  final String currencySymbol;
  final Color primaryColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: last
            ? null
            : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: last
            ? const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xs))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: AppSizes.avatarSm,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          SizedBox(
            width: AppSpacing.huge + AppSpacing.xxs,
            child: Text(
              '$price $currencySymbol',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
