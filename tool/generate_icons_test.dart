// Ferramenta de geração do ícone da marca (W7) — NÃO é um teste de
// regressão e não faz parte da suíte normal (`flutter test` só corre
// test/). Uso manual:
//
// flutter test tool/generate_icons_test.dart
// dart run flutter_launcher_icons # gera os ícones nativos
//
// Processa a IMAGEM-FONTE `assets/branding/icon_official.png`
// (1024×1024, design OFICIAL do utilizador: fundo branco + quadrado azul
// arredondado com gradiente (azul-céu → azul pálido), arco no topo, "D"
// branco recortado (haste + bojo) e ponto azul ao centro) e grava os PNGs
// que alimentam o flutter_launcher_icons (Android/iOS) e o web (manifest
// + favicon).
//
// Atenção: O MESTRE é GERADO a partir do anexo do utilizador (fiel, escala
// uniforme + key do fundo branco por inundação):
// python tool/apply_official_icon.py # mestre 1024 + favicon SVG
// python tool/icon_preview.py # contact sheet para revisão visual
//
// DESIGN (oficial — anexo do utilizador):
// - A fonte JÁ É o ícone completo (fundo branco + desenho azul), sem
// tile separado — os ícones legacy/iOS/web usam a imagem inteira;
// - icon_legacy.png: a imagem inteira (1024, opaca) — Android <8, iOS e web;
// - icon_fg.png: o DESENHO em ~92% do canvas transparente — o fundo
// (branco) sai por INUNDAÇÃO a partir das bordas, preservando o "D"
// branco e o interior do arco (brancos ENCERRADOS pelo azul).
// Foreground do adaptativo sobre o fundo branco `adaptive_icon_background`;
// - icon_mono.png: silhueta MONOCROMÁTICA do desenho (luminância > 60 —
// todo o azul do corpo; o fundo já saiu no key) — themed icons do
// Android 13+ (só o alpha conta);
// - splash_logo.png: o desenho em ~88% do canvas transparente — marca do
// SPLASH (tela in-app + web);
// - launch_image.png (Android, drawable-nodpi) e LaunchImage 1x/2x/3x
// (iOS) — o logotipo para as telas de abertura NATIVAS;
// - Web: favicon + manifest a partir da imagem inteira.
//
// Key do fundo: o branco da fonte vira transparente nos recortes
// (fg/splash/launch); o azul do desenho (saturação alta) sobrevive sempre.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Offset, Rect;
import 'package:flutter_test/flutter_test.dart';

/// Caminho da imagem-fonte da marca (1024×1024, RGB opaco — design oficial
/// azul/branco, upscaled a partir do `dumbhanengue.ico`).
const _sourcePath = 'assets/branding/icon_official.png';

/// Fração do canvas ocupada pelo desenho no foreground adaptativo.
/// O desenho JÁ ocupa ~76%×91% da fonte; desenhá-lo a 92% do canvas deixa
/// o logotipo com o tamanho "normal" do ícone (a máscara do launcher corta
/// só os cantos do quadrado azul).
const _logoCanvasFraction = 0.92;

/// Frações do canvas nos outros recortes (splash, launch, LaunchImage).
const _splashLogoFraction = 0.88;
const _androidLaunchFraction = 0.95;
const _iosLaunchFraction = 1.0;

/// Limiar de luminância (0-255) que separa o desenho azul do fundo
/// transparente nos themed icons do Android 13+. O desenho vai do
/// azul-céu (lum ~240) ao azul pálido (lum ~200); 60 captura tudo e
/// deixa o fundo (0) de fora.
const _monoLuminanceThreshold = 60;

/// Limiar de key do fundo: pixel claro com pouca saturação (branco)
/// vira transparente — o azul do desenho tem saturação alta e sobrevive.
/// (Saturação 30 preserva TODOS os tons do azul, inclusive os azul-claros
/// do gradiente do corpo — um key mais agressivo (60) comia essas partes.)
const _keyMinChannel = 200;
const _keyMaxSaturation = 30;

/// Tamanho do canvas dos ícones nativos (1024px, padrão do launcher).
const _nativeSize = 1024;

/// Desenha [src] (região [srcRect] em pixels da fonte) em um canvas
/// [size]×[size] transparente. Se [destFraction] for informado, a imagem
/// ocupa [destFraction] do canvas, centralizada; senão, preenche o canvas.
Future<ui.Image> _drawImage(
  ui.Image src,
  Rect srcRect,
  int size, {
  double? destFraction,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
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

/// Remove o fundo da imagem por INUNDAÇÃO a partir das bordas: os pixels
/// claros (branco de baixa saturação) CONECTADOS à borda do canvas
/// viram transparentes (RGB zerado). Os brancos ENCERRADOS pelo desenho —
/// o "D" e o interior do arco — são preservados, pois a inundação nunca
/// os alcança. Usado nos recortes (fg/splash/launch).
Future<ui.Image> _keyOutBackground(ui.Image image) async {
  final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = raw!.buffer.asUint8List();
  final w = image.width;
  final h = image.height;

  // Marcação de "fundo": 1 = pixel claro conectado à borda (vira transparente).
  final keyed = Uint8List(w * h);
  final stack = <int>[];

  bool isLightBackground(int idx) {
    final i = idx * 4;
    final r = pixels[i];
    final g = pixels[i + 1];
    final b = pixels[i + 2];
    final maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
    return maxChannel >= _keyMinChannel &&
        (maxChannel - minChannel) <= _keyMaxSaturation;
  }

  void push(int idx) {
    if (keyed[idx] == 0 && isLightBackground(idx)) {
      keyed[idx] = 1;
      stack.add(idx);
    }
  }

  // Sementes: todos os pixels das 4 bordas do canvas.
  for (var x = 0; x < w; x++) {
    push(x);
    push((h - 1) * w + x);
  }
  for (var y = 1; y < h - 1; y++) {
    push(y * w);
    push(y * w + w - 1);
  }

  // Inundação (DFS) pelos vizinhos claros.
  while (stack.isNotEmpty) {
    final idx = stack.removeLast();
    final x = idx % w;
    final y = idx ~/ w;
    if (x > 0) push(idx - 1);
    if (x < w - 1) push(idx + 1);
    if (y > 0) push(idx - w);
    if (y < h - 1) push(idx + w);
  }

  // Aplica o key nos pixels marcados.
  for (var idx = 0; idx < keyed.length; idx++) {
    if (keyed[idx] == 1) {
      final i = idx * 4;
      pixels[i] = 0;
      pixels[i + 1] = 0;
      pixels[i + 2] = 0;
      pixels[i + 3] = 0;
    }
  }

  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    w,
    h,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
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

/// Converte [image] na silhueta monocromática: pixels com luminância acima
/// do limiar viram branco opaco; o resto vira transparente (só o alpha
/// importa para os themed icons do Android 13+).
Future<ui.Image> _toMonochrome(ui.Image image, int luminanceThreshold) async {
  final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = raw!.buffer.asUint8List();
  for (var i = 0; i < pixels.length; i += 4) {
    final r = pixels[i];
    final g = pixels[i + 1];
    final b = pixels[i + 2];
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    if (lum > luminanceThreshold) {
      pixels[i] = 255;
      pixels[i + 1] = 255;
      pixels[i + 2] = 255;
      pixels[i + 3] = 255;
    } else {
      pixels[i] = 0;
      pixels[i + 1] = 0;
      pixels[i + 2] = 0;
      pixels[i + 3] = 0;
    }
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    image.width,
    image.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera os PNGs da marca a partir da imagem-fonte oficial', () async {
    // Decodifica a imagem-fonte (1024×1024).
    final sourceBytes = File(_sourcePath).readAsBytesSync();
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final source = frame.image;
    expect(source.width, _nativeSize);
    expect(source.height, _nativeSize);

    // A fonte inteira (fundo branco + logotipo azul) — sem tile separado.
    final fullSrc = Rect.fromLTWH(
      0,
      0,
      source.width.toDouble(),
      source.height.toDouble(),
    );

    // Legacy (Android <8, iOS, web) — a imagem inteira, opaca (como o .ico).
    final legacy = await _drawImage(source, fullSrc, _nativeSize);
    await _writePng(legacy, 'assets/branding/icon_legacy.png');

    // Foreground adaptativo — o LOGOTIPO (fundo keyado) em ~92% do canvas
    // (tamanho normal do .ico; antes ficava em 62% e o logo saía minúsculo).
    final keyed = await _keyOutBackground(source);
    final foreground = await _drawImage(
      keyed,
      fullSrc,
      _nativeSize,
      destFraction: _logoCanvasFraction,
    );
    await _writePng(foreground, 'assets/branding/icon_fg.png');

    // Monocromático (Android 13+ themed icons) — logotipo como silhueta.
    final monochrome = await _toMonochrome(foreground, _monoLuminanceThreshold);
    await _writePng(monochrome, 'assets/branding/icon_mono.png');

    // Splash: o logotipo em ~88% do canvas transparente — usado pela tela
    // de abertura in-app (asset empacotado) e como base dos nativos.
    final splash = await _drawImage(
      keyed,
      fullSrc,
      _nativeSize,
      destFraction: _splashLogoFraction,
    );
    await _writePng(splash, 'assets/branding/splash_logo.png');

    // Android: tela de abertura nativa — logotipo em ~95% do canvas (o
    // launch_background.xml pinta o fundo e centraliza este PNG).
    final androidLaunch = await _drawImage(
      keyed,
      fullSrc,
      512,
      destFraction: _androidLaunchFraction,
    );
    await _writePng(
      androidLaunch,
      'android/app/src/main/res/drawable-nodpi/launch_image.png',
    );

    // iOS: LaunchImage 1x/2x/3x (substitui o placeholder 1×1 do template).
    for (final spec in [(168, 1), (336, 2), (504, 3)]) {
      final size = spec.$1;
      final suffix = spec.$2 == 1 ? '' : '@${spec.$2}x';
      final ios = await _drawImage(
        keyed,
        fullSrc,
        size,
        destFraction: _iosLaunchFraction,
      );
      await _writePng(
        ios,
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
      );
    }

    // Web: manifest + favicon (a partir da imagem inteira).
    for (final size in [512, 192, 48]) {
      final web = await _drawImage(source, fullSrc, size);
      final name = size == 48
          ? 'web/icons/favicon.png'
          : 'web/icons/icon-$size.png';
      await _writePng(web, name);
    }
  });
}
