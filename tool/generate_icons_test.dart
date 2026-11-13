// Ferramenta de geração dos recortes nativos/web da marca (W7) — NÃO é
// um teste de regressão e não faz parte da suíte normal (`flutter test`
// só corre test/). Uso manual:
//
// python tool/gen_tq_logo.py                 # masters da marca
// flutter test tool/generate_icons_test.dart # recortes nativos + web
// dart run flutter_launcher_icons            # ícones nativos finais
//
// Masters em assets/branding (Preto 100 #0A0E15 + Branco 100 #FFFFFF):
// - icon_official.png: tile tinta + monograma branco (1024, opaco);
// - splash_logo.png: branco sobre transparente (launch escuro);
// - splash_logo_ink.png: tinta sobre transparente (launch claro).
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
const _softLogoPath = 'assets/branding/splash_logo.png';
const _inkLogoPath = 'assets/branding/splash_logo_ink.png';

/// Tamanho do canvas dos masters (1024px, padrão do launcher).
const _nativeSize = 1024;

/// Fração do canvas do logotipo no launch nativo Android.
const _androidLaunchFraction = 1.0;

/// Android 12+ apresenta o ícone sem fundo em 288dp. Metade do canvas do
/// master (marca a 80%) resulta em 115dp, igual ao launch clássico de 144dp.
/// Todo o desenho permanece dentro do círculo seguro de 192dp.
const _android12LaunchFraction = 0.5;

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
  bool circular = false,
  ui.Color? backgroundColor,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (backgroundColor != null) {
    canvas.drawColor(backgroundColor, ui.BlendMode.src);
  }
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
  if (circular) canvas.clipPath(ui.Path()..addOval(dest));
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

    // Ícones redondos anteriores ao adaptive: o manifest também os usa.
    // Mantém os foregrounds mipmap legados sincronizados com a nova marca.
    for (final spec in [
      ('mdpi', 48),
      ('hdpi', 72),
      ('xhdpi', 96),
      ('xxhdpi', 144),
      ('xxxhdpi', 192),
    ]) {
      final directory = 'android/app/src/main/res/mipmap-${spec.$1}';
      await _writePng(
        await _drawImage(official, spec.$2, circular: true),
        '$directory/ic_launcher_round.png',
      );
      await _writePng(
        await _drawImage(soft, (spec.$2 * 2.25).round(), destFraction: 0.9),
        '$directory/ic_launcher_foreground.png',
      );
    }

    // Android — splash claro (monograma tinta) e escuro (suave).
    await _writePng(
      await _drawImage(ink, 512, destFraction: _androidLaunchFraction),
      'android/app/src/main/res/drawable-nodpi/launch_image.png',
    );
    await _writePng(
      await _drawImage(soft, 512, destFraction: _androidLaunchFraction),
      'android/app/src/main/res/drawable-night-nodpi/launch_image.png',
    );

    // Android 12+ — sem tile: mesma marca, com área segura da API de splash.
    await _writePng(
      await _drawImage(ink, 512, destFraction: _android12LaunchFraction),
      'android/app/src/main/res/drawable-nodpi/splash_icon.png',
    );
    await _writePng(
      await _drawImage(soft, 512, destFraction: _android12LaunchFraction),
      'android/app/src/main/res/drawable-night-nodpi/splash_icon.png',
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

    // Web — abertura positiva/negativa, sem tile nem dependência de fontes.
    await _writePng(await _drawImage(ink, 432), 'web/icons/splash-light.png');
    await _writePng(await _drawImage(soft, 432), 'web/icons/splash-dark.png');

    // PWA maskable: marca ligeiramente menor, incluindo as franjas AA,
    // inteiramente dentro do círculo seguro central de 80% do canvas.
    await _writePng(
      await _drawImage(
        official,
        512,
        destFraction: 0.9375,
        backgroundColor: const ui.Color(0xFF0A0E15),
      ),
      'web/icons/icon-maskable-512.png',
    );

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
