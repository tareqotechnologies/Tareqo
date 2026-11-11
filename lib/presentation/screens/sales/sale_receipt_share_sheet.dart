import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/observability/crash_reporting.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/receipt_text.dart';
import '../../../domain/entities/sale.dart';
import '../../controllers/sales_providers.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_sheet.dart';
import '../../widgets/premium_decor.dart';
import '../../widgets/sale_receipt_view.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';

/// Bottom sheet de partilha do recibo — o coração da funcionalidade:
///
/// - mostra a PRÉ-VISUALIZAÇÃO do recibo ([SaleReceiptView], cara de cupom
/// térmico) para o usuário conferir antes de enviar;
/// - **Partilhar como imagem** — captura o widget (RepaintBoundary → PNG)
/// e abre o share sheet do sistema (WhatsApp, e-mail, salvar...);
/// - **WhatsApp** — abre o aplicativo com o recibo em texto puro
/// pré-preenchido (`wa.me`), sem depender de número de telefone.
class SaleReceiptShareSheet extends ConsumerStatefulWidget {
  const SaleReceiptShareSheet({
    super.key,
    required this.sale,
    this.storeName,
    this.storeAddress,
  });

  final Sale sale;

  /// Nome do estabelecimento para o cabeçalho do recibo (opcional).
  final String? storeName;

  /// Endereço do estabelecimento para o cabeçalho do recibo (opcional).
  final String? storeAddress;

  @override
  ConsumerState<SaleReceiptShareSheet> createState() =>
      _SaleReceiptShareSheetState();
}

class _SaleReceiptShareSheetState extends ConsumerState<SaleReceiptShareSheet> {
  /// Chave do `RepaintBoundary` que envolve o recibo — origem da captura.
  final GlobalKey _receiptKey = GlobalKey();

  /// Evita toques duplicados enquanto uma partilha está em andamento.
  bool _sharing = false;

  /// Captura o recibo visual como PNG (3× para ficar nítido no WhatsApp).
  Future<Uint8List> _captureReceipt() async {
    final boundary =
        _receiptKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Partilha como IMAGEM: captura o recibo e abre o share sheet.
  Future<void> _shareImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureReceipt();
      await ref
          .read(receiptSharerProvider)
          .shareImage(bytes, saleId: widget.sale.id);
    } catch (error, stackTrace) {
      CrashReporting.capture(
        error,
        stackTrace,
        hint: 'Erro ao partilhar recibo',
      );
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.saleDetailShareError)),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Partilha via WHATSAPP: monta o texto e abre o `wa.me` pré-preenchido.
  Future<void> _shareWhatsApp() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _sharing = true);
    try {
      final text = ReceiptText.build(
        sale: widget.sale,
        storeName: widget.storeName,
        storeAddress: widget.storeAddress,
        language: Formatters.currentLanguage,
      );
      final opened = await ref.read(receiptSharerProvider).shareWhatsApp(text);
      if (!opened) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.saleDetailShareWhatsAppError)),
        );
      }
    } catch (error, stackTrace) {
      CrashReporting.capture(error, stackTrace, hint: 'Erro ao abrir WhatsApp');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.saleDetailShareWhatsAppError)),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alça de arraste padrão das sheets.
            const Center(child: SheetHandle()),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.saleDetailShareTitle,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Pré-visualização do recibo (fundo do sheet cinza claro para o
            // "papel" branco do cupom se destacar). O preview rola quando o
            // recibo é longo (muitos itens/escala de texto alta) — o
            // RepaintBoundary DENTRO do scroll continua capturando o recibo
            // INTEIRO (o toImage usa o próprio layer do boundary, sem o
            // recorte do ancestral), então a imagem partilhada fica completa.
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.xsAll,
                    boxShadow: PremiumDecor.softShadow(theme.colorScheme),
                  ),
                  child: RepaintBoundary(
                    key: _receiptKey,
                    child: SaleReceiptView(
                      sale: widget.sale,
                      storeName: widget.storeName,
                      storeAddress: widget.storeAddress,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Ação principal: partilhar como imagem (share sheet do sistema).
            AppButton.primary(
              expanded: true,
              onPressed: _sharing ? null : _shareImage,
              label: l10n.saleDetailShareImage,
              icon: _sharing
                  ? SizedBox(
                      width: AppSizes.iconMd,
                      height: AppSizes.iconMd,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.image_outlined),
            ),
            const SizedBox(height: AppSpacing.sm),
            // WhatsApp: abre o app com o recibo em texto pré-preenchido.
            AppButton.secondary(
              expanded: true,
              onPressed: _sharing ? null : _shareWhatsApp,
              // Paleta oficial: azul é azul em qualquer estado
              // (o verde brand do WhatsApp é uma cor de terceiros fora da
              // paleta — proibido na interface geral).
              // Texto em tinta/gelo (azul sobre a tinta mede 3.28:1 e
              // reprova AA); o contorno azul permanece como acento.
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                side: BorderSide(color: theme.colorScheme.primary),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: l10n.saleDetailShareWhatsApp,
            ),
          ],
        ),
      ),
    );
  }
}
