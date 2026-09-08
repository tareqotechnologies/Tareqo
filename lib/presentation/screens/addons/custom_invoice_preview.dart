import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';

/// Preview estático (amostra) da factura personalizada — o mesmo desenho
/// do PDF exportado, renderizado na tela de template.
///
/// Extraído de `custom_invoice_screen.dart` (auditoria M5 — tela-god):
/// isolado aqui porque não tem estado nem dependências da tela; recebe
/// apenas os dados do negócio e a cor primária do template.
class CustomInvoicePreview extends StatelessWidget {
  const CustomInvoicePreview({
    super.key,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessTaxId,
    this.logoBytes,
    required this.primaryColor,
  });

  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessTaxId;
  final Uint8List? logoBytes;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = businessName.isNotEmpty
        ? businessName
        : 'Nome da Empresa';

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
            color: Colors.black.withValues(alpha: 0.06),
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
          Container(height: 4, color: primaryColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                logoBytes!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                    fontSize: 13,
                                  ),
                                ),
                                if (businessAddress.isNotEmpty)
                                  Text(
                                    // Endereço COMPLETO — quebra em linhas
                                    // (nunca truncar os dados do negócio).
                                    businessAddress,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                if (businessPhone.isNotEmpty)
                                  Text(
                                    businessPhone,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 9,
                                    ),
                                  ),
                                if (businessTaxId.isNotEmpty)
                                  Text(
                                    'NIF: $businessTaxId',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 9,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge FACTURA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FACTURA',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Nº + data (B5: data DINÂMICA — antes ficava fixa em
                // 03/09/2026 e envelhecia no preview).
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Nº 00001  •  ${Formatters.date(DateTime.now())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Divisor
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                // ─── Cliente ──
                Text(
                  'CLIENTE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'João Silva',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Tel: 84 123 4567',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 10),
                // ─── Tabela de itens (miniatura) ──
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Item',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          'Qtd',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          'Preço',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Rows
                _PreviewRow(
                  name: 'Produto A',
                  qty: '2',
                  price: '150,00',
                  primaryColor: primaryColor,
                ),
                _PreviewRow(
                  name: 'Produto B',
                  qty: '1',
                  price: '250,00',
                  primaryColor: primaryColor,
                  last: true,
                ),
                const SizedBox(height: 8),
                // ─── Total ──
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TOTAL: 550,00 MT',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: primaryDark,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Rodapé
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Gerado pelo TAREQO',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 8,
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
    required this.primaryColor,
    this.last = false,
  });

  final String name;
  final String qty;
  final String price;
  final Color primaryColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: last
            ? null
            : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: last
            ? const BorderRadius.vertical(bottom: Radius.circular(4))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '$price MT',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
