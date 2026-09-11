import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:tareqo/core/share/receipt_sharer.dart';

/// Fake do [PathProviderPlatform] — diretório temporário REAL: o
/// `shareImage` grava o PNG em `$temp/recibo_venda_<id>.png` antes de
/// partilhar (Android/iOS exigem um `File` no share sheet).
class _FakePathProvider extends PathProviderPlatform {
  late Directory tempDir;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final fakePP = _FakePathProvider();
  final originalPP = PathProviderPlatform.instance;

  setUp(() async {
    fakePP.tempDir = await Directory.systemTemp.createTemp('tareqo_receipt');
    PathProviderPlatform.instance = fakePP;
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(shareChannel, null);
    messenger.setMockMethodCallHandler(launcherChannel, null);
    PathProviderPlatform.instance = originalPP;
    await fakePP.tempDir.delete(recursive: true);
  });

  test('shareImage grava o PNG temporário e partilha com nome por venda',
      () async {
    final calls = <Map<String, dynamic>>[];
    messenger.setMockMethodCallHandler(shareChannel, (call) async {
      expect(call.method, 'share');
      calls.add(Map<String, dynamic>.from(call.arguments as Map));
      return 'dev.fluttercommunity.plus/share/dismissed';
    });

    // PNG real (assinatura mágica + IHDR) — 1×1 pixel transparente.
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // assinatura
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
      ...List.filled(24, 0x00),
    ]);

    await const ReceiptSharer().shareImage(png, saleId: 'S-00042');

    expect(calls, hasLength(1));
    expect(calls.single['subject'], 'Recibo de venda');
    final paths = (calls.single['paths'] as List).cast<String>();
    // O id da venda no nome evita colisão entre recibos diferentes.
    expect(paths.single, endsWith('recibo_venda_S-00042.png'));
    expect((calls.single['mimeTypes'] as List).single, 'image/png');

    // O arquivo partilhado tem EXATAMENTE os bytes recebidos.
    final written = File(paths.single).readAsBytesSync();
    expect(written, png);
  });

  test('shareWhatsApp abre wa.me com o texto URL-encoded', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(launcherChannel, (call) async {
      expect(call.method, 'launch');
      calls.add(call);
      return true;
    });

    final ok = await const ReceiptSharer()
        .shareWhatsApp('*RECIBO*\nVenda S-1\nTotal: R\$ 15,00');

    expect(ok, isTrue);
    expect(calls, hasLength(1));
    final url = calls.single.arguments['url'] as String;
    expect(url, startsWith('https://wa.me/?text='));
    // O texto chega codificado e decodifica para o recibo original.
    expect(
      Uri.decodeComponent(url.split('text=').last),
      '*RECIBO*\nVenda S-1\nTotal: R\$ 15,00',
    );
  });

  test('shareWhatsApp devolve false quando o lado nativo não abre o link',
      () async {
    // `launchUrl` retorna false quando a plataforma consegue tratar a
    // intenção mas nada abre o wa.me (canal devolve false/null).
    messenger.setMockMethodCallHandler(launcherChannel, (call) async => false);

    final ok = await const ReceiptSharer().shareWhatsApp('recibo');

    expect(ok, isFalse);
  });

  test('shareWhatsApp PROPAGA PlatformException — classe fina, o chamador trata erros',
      () async {
    messenger.setMockMethodCallHandler(launcherChannel, (call) async {
      throw PlatformException(
        code: ' Could not launch https://wa.me',
        message: 'componentName is null',
      );
    });

    await expectLater(
      const ReceiptSharer().shareWhatsApp('recibo'),
      throwsA(isA<PlatformException>()),
    );
  });
}
