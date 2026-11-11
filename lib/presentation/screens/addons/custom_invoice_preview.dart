import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/premium_decor.dart';

/// Preview estático (amostra) da factura personalizada — o mesmo desenho
/// do PDF exportado, renderizado na tela de template.
///
/// Extraído de `custom_invoice_screen.dart` (auditoria M5 — tela-god):
/// isolado aqui porque não tem estado nem dependências da tela; recebe
/// apenas os dados do negócio e a cor primária do template.
///
/// **Exceção de documento (U-12):** esta miniatura espelha um documento
/// impresso em escala reduzida — os tamanhos seguem a escala do tema
/// (bodySmall/labelSmall) e os pesos ficam em 400/500. O papel é claro
/// (como o PDF) em ambos os temas, com tinta preta da marca; o texto
/// sobre `primaryColor` usa a cor do template escolhido pelo utilizador
/// (identidade do documento, não do app).
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
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final displayName = businessName.isNotEmpty
        ? businessName
        : l10n.customInvoicePreviewCompanyFallback;

    // Miniatura de DOCUMENTO: o papel é claro como o PDF exportado, em
    // ambos os temas — antes usava `scheme.surface` (preto no escuro) com
    // tinta preta, e o conteúdo desaparecia. A cor primária continua a ser
    // a identidade escolhida pelo utilizador para o documento.
    const paper = AppColors.softWhite;
    const ink = AppColors.brandInk;
    final inkSecondary = AppColors.brandInk.withValues(alpha: 0.66);
    final hairline = AppColors.brandInk.withValues(alpha: 0.12);
    final onPrimaryFill = primaryColor.computeLuminance() > 0.22
        ? AppColors.brandInk
        : AppColors.softWhite;

    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: hairline),
        boxShadow: PremiumDecor.softShadow(scheme),
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
                                  style: AppTypography.bodySmall.copyWith(
                                    color: ink,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (businessAddress.isNotEmpty)
                                  Text(
                                    // Endereço COMPLETO — quebra em linhas
                                    // (nunca truncar os dados do negócio).
                                    businessAddress,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: inkSecondary,
                                    ),
                                  ),
                                if (businessPhone.isNotEmpty)
                                  Text(
                                    businessPhone,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: inkSecondary,
                                    ),
                                  ),
                                if (businessTaxId.isNotEmpty)
                                  Text(
                                    l10n.pdfNifLine(businessTaxId),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: inkSecondary,
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
                        style: AppTypography.labelSmall.copyWith(
                          color: onPrimaryFill,
                          fontWeight: FontWeight.w500,
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
                    style: AppTypography.bodySmall.copyWith(
                      color: inkSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Divisor
                Divider(height: 1, color: hairline),
                const SizedBox(height: AppSpacing.xs),
                // ─── Cliente ──
                Text(
                  l10n.pdfClientHeading,
                  style: AppTypography.bodySmall.copyWith(
                    color: inkSecondary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  l10n.customInvoicePreviewSampleClient,
                  style: AppTypography.bodySmall.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  l10n.pdfPhoneLine('84 123 4567'),
                  style: AppTypography.bodySmall.copyWith(color: inkSecondary),
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
                          style: AppTypography.bodySmall.copyWith(
                            color: onPrimaryFill,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: AppSizes.avatarSm,
                        child: Text(
                          l10n.customInvoiceQty,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: onPrimaryFill,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: AppSpacing.huge + AppSpacing.xxs,
                        child: Text(
                          l10n.pdfUnitPriceHeader,
                          textAlign: TextAlign.right,
                          style: AppTypography.bodySmall.copyWith(
                            color: onPrimaryFill,
                            fontWeight: FontWeight.w500,
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
                      style: AppTypography.bodySmall.copyWith(
                        color: ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Rodapé
                Divider(height: 1, color: hairline),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    l10n.customInvoicePreviewFooter,
                    style: AppTypography.bodySmall.copyWith(
                      color: inkSecondary,
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
    const ink = AppColors.brandInk;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        // Papel do documento — o zebrado é cinza de superfície oficial.
        color: last ? null : AppColors.surfaceGray.withValues(alpha: 0.6),
        borderRadius: last
            ? const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xs))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodySmall.copyWith(color: ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: AppSizes.avatarSm,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: ink),
            ),
          ),
          SizedBox(
            width: AppSpacing.huge + AppSpacing.xxs,
            child: Text(
              '$price $currencySymbol',
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                color: ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
