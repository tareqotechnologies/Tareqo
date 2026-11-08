import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Abre a câmera de leitura de código de barras em um bottom sheet e
/// devolve o primeiro código lido (ou `null` se o usuário cancelar).
///
/// Paleta oficial: fundo preto #212121 (a mira precisa de contraste com a
/// imagem da câmera), moldura e textos gelo #E0E0E0.
Future<String?> showBarcodeScanner(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.black,
    builder: (context) => const BarcodeScanSheet(),
  );
}

/// Leitor de código de barras por câmera (mobile_scanner).
///
/// Usado no PDV para ler etiquetas de balança (20PPPPPWWWWW) e PLUs de
/// produtos — o código lido é devolvido via [Navigator.pop] e processado
/// pelo mesmo fluxo do campo manual (scanner USB tipo teclado).
class BarcodeScanSheet extends StatefulWidget {
  const BarcodeScanSheet({super.key});

  @override
  State<BarcodeScanSheet> createState() => _BarcodeScanSheetState();
}

class _BarcodeScanSheetState extends State<BarcodeScanSheet> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty && mounted) {
        Navigator.of(context).pop(raw.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // O sheet é aberto via rota modal própria: traz os delegates de
    // localização do app para que o texto guia e o erro da câmera saiam
    // no idioma do tenant (pt/en/fr) mesmo fora do MaterialApp raiz.
    return Localizations.override(
      context: context,
      delegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) => Container(
                        color: AppColors.black,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          l10n.salesBarcodeCameraUnavailable('$error'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.ice),
                        ),
                      ),
                    ),
                  ),
                  // Moldura de mira (gelo sobre preto).
                  IgnorePointer(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.ice, width: 3),
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.gray.withValues(alpha: 0.54),
                      ),
                      icon: const Icon(Icons.close, color: AppColors.ice),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Text(
                      l10n.salesBarcodeCameraHint,
                      style: const TextStyle(color: AppColors.ice),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
