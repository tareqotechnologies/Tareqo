import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Partilha do recibo de venda — única porta de saída para os dois meios:
///
/// 1. **Imagem** — recebe os bytes PNG do recibo visual ([SaleReceiptView]
/// capturado via `RepaintBoundary`) e abre o share sheet do sistema
/// (WhatsApp, e-mail, salvar no dispositivo...);
/// 2. **WhatsApp** — abre o aplicativo com o texto do recibo pré-preenchido
/// via deep link `https://wa.me/?text=...` (sem precisar de número —
/// o usuário escolhe o contato no próprio WhatsApp).
///
/// Classe fina sobre `share_plus`/`url_launcher`, criada via provider
/// ([receiptSharerProvider]) para ser substituída por um fake nos testes.
class ReceiptSharer {
 const ReceiptSharer();

 /// Partilha o recibo como IMAGEM PNG via o share sheet do sistema.
 ///
 /// No web o `XFile.fromData` é suportado nativamente (Web Share API com
 /// fallback de download); no mobile o PNG é gravado em um arquivo
 /// temporário para o share sheet ter um caminho real (Android/iOS exigem
 /// um `File`). Ambos entregam um `recibo_venda_<saleId>.png` nomeado — o
 /// id da venda no nome evita colisões ao partilhar recibos diferentes.
 Future<void> shareImage(Uint8List pngBytes, {String saleId = 'venda'}) async {
 final fileName = 'recibo_venda_$saleId.png';
 if (kIsWeb) {
 await SharePlus.instance.share(
 ShareParams(
 files: [XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName)],
 subject: 'Recibo de venda',
 ),
 );
 return;
 }
 final dir = await getTemporaryDirectory();
 final file = File('${dir.path}/$fileName');
 await file.writeAsBytes(pngBytes);
 await SharePlus.instance.share(
 ShareParams(
 files: [XFile(file.path, mimeType: 'image/png')],
 subject: 'Recibo de venda',
 ),
 );
 }

 /// Abre o WhatsApp com [text] (recibo em texto puro) pré-preenchido.
 ///
 /// Retorna `false` se o link não pôde ser aberto (ex.: nenhum app/browser
 /// consegue tratar `wa.me` — raro em Android/iOS/desktop/web).
 Future<bool> shareWhatsApp(String text) async {
 final uri = Uri.parse(
 'https://wa.me/?text=${Uri.encodeComponent(text)}',
 );
 return launchUrl(uri, mode: LaunchMode.externalApplication);
 }
}
