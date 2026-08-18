import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Abre a câmera de leitura de código de barras em um bottom sheet e
/// devolve o primeiro código lido (ou `null` se o usuário cancelar).
Future<String?> showBarcodeScanner(BuildContext context) {
 return showModalBottomSheet<String>(
 context: context,
 isScrollControlled: true,
 backgroundColor: Colors.black,
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
 color: Colors.black,
 alignment: Alignment.center,
 padding: const EdgeInsets.all(24),
 child: Text(
 'Câmera indisponível: $error',
 textAlign: TextAlign.center,
 style: const TextStyle(color: Colors.white70),
 ),
 ),
 ),
 ),
 // Moldura de mira.
 IgnorePointer(
 child: Container(
 width: 240,
 height: 240,
 decoration: BoxDecoration(
 border: Border.all(color: Colors.white, width: 3),
 borderRadius: BorderRadius.circular(24),
 ),
 ),
 ),
 Positioned(
 top: 12,
 right: 12,
 child: IconButton.filled(
 style: IconButton.styleFrom(backgroundColor: Colors.black54),
 icon: const Icon(Icons.close, color: Colors.white),
 onPressed: () => Navigator.of(context).pop(),
 ),
 ),
 const Positioned(
 bottom: 16,
 child: Text(
 'Aponte a câmera para o código de barras',
 style: TextStyle(color: Colors.white70),
 ),
 ),
 ],
 ),
 ),
 );
 }
}
