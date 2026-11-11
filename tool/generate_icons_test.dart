// Ferramenta de geração dos recortes nativos/web da marca (W7) — NÃO é
// um teste de regressão e não faz parte da suíte normal (`flutter test`
// só corre test/). Uso manual:
//
// python tool/gen_tq_logo.py                 # masters da marca
// flutter test tool/generate_icons_test.dart # recortes nativos + web
// dart run flutter_launcher_icons            # ícones nativos finais
//
// Masters em assets/branding (paleta oficial #232323 + #F9F9F9):
// - icon_official.png: tile tinta + monograma suave (1024, opaco);
// - icon_fg.png: monograma suave sobre transparente (launch/splash escuro);
// - icon_fg_ink.png: monograma tinta sobre transparente (launch claro).
//
// Este tool deriva, sem keying (os masters já vêm recortados):
// - Android: drawable-nodpi/launch_image.png (tinta — splash claro) e
//   drawable-night-nodpi/launch_image.png (suave — splash escuro); o
//   launch_background.xml pinta o fundo e centraliza o PNG;
// - iOS: LaunchImage 1x/2x/3x (tinta) + LaunchImageDark 1x/2x/3x (suave),
//   combinados com o LaunchBackground.colorset claro/escuro;
// - Web: favicon.png + icon-192/512 a partir do tile completo.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Offset, Rect;
import 'package:flutter_test/flutter_test.dart';

const _officialPath = 'assets/branding/icon_official.png';
const _softLogoPath = 'assets/branding/icon_fg.png';
const _inkLogoPath = 'assets/branding/icon_fg_ink.png';

/// Tamanho do canvas dos masters (1024px, padrão do launcher).
const _nativeSize = 1024;

/// Fração do canvas do logotipo no launch nativo Android.
const _androidLaunchFraction = 0.95;

Future<ui.Image> _load(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Desenha [src] num canvas [size]×[size] transparente, centrado; com
/// [destFraction] a imagem ocupa essa fração do canvas, senão preenche.
Future<ui.Image> _drawImage(
  ui.Image src,
  int size, {
  double? destFraction,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final srcRect = Rect.fromLTWH(
    0,
    0,
    src.width.toDouble(),
    src.height.toDouble(),
  );
  final dest = destFraction != null
      ? Rect.fromCenter(
          center: Offset(size / 2, size / 2),
          width: size * destFraction,
          height: size * destFraction,
        )
      : Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  canvas.drawImageRect(
    src,
    srcRect,
    dest,
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  picture.dispose();
  return image;
}

/// Grava [image] como PNG em [path].
Future<void> _writePng(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('gerado: $path (${File(path).lengthSync()} bytes)');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deriva os recortes nativos e web dos masters oficiais', () async {
    final official = await _load(_officialPath);
    expect(official.width, _nativeSize);
    expect(official.height, _nativeSize);
    final soft = await _load(_softLogoPath);
    final ink = await _load(_inkLogoPath);

    // Android — splash claro (monograma tinta) e escuro (suave).
    await _writePng(
      await _drawImage(ink, 512, destFraction: _androidLaunchFraction),
      'android/app/src/main/res/drawable-nodpi/launch_image.png',
    );
    await _writePng(
      await _drawImage(soft, 512, destFraction: _androidLaunchFraction),
      'android/app/src/main/res/drawable-night-nodpi/launch_image.png',
    );

    // iOS — LaunchImage claro (tinta) + escuro (suave), 1x/2x/3x.
    for (final spec in [(168, 1), (336, 2), (504, 3)]) {
      final size = spec.$1;
      final suffix = spec.$2 == 1 ? '' : '@${spec.$2}x';
      await _writePng(
        await _drawImage(ink, size),
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
      );
      await _writePng(
        await _drawImage(soft, size),
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImageDark$suffix.png',
      );
    }

    // Web — manifest + favicon (tile completo: fundo tinta + desenho suave).
    for (final size in [512, 192, 48]) {
      final web = await _drawImage(official, size);
      final name = size == 48
          ? 'web/icons/favicon.png'
          : 'web/icons/icon-$size.png';
      await _writePng(web, name);
    }
  });
}
