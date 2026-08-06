// Ferramenta de geração do ícone da marca (W7) — NÃO é um teste de
// regressão e não faz parte da suíte normal (`flutter test` só corre
// test/). Uso manual:
//
//   flutter test tool/generate_icons_test.dart
//   dart run flutter_launcher_icons        # gera os ícones nativos
//
// Renderiza o ícone (gradiente esmeralda da identidade + glyph de loja)
// com o próprio motor do Flutter e grava os PNGs que alimentam o
// flutter_launcher_icons (Android/iOS) e o web (manifest + favicon).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _emeraldStart = Color(0xFF34D399);
const _emeraldEnd = Color(0xFF047857);

Widget _branding({required double size, required bool gradient}) {
  return RepaintBoundary(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: size,
        height: size,
        decoration: gradient
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_emeraldStart, _emeraldEnd],
                ),
              )
            : null,
        child: Center(
          child: Icon(
            Icons.storefront_rounded,
            // No foreground adaptativo o glyph precisa de folga (o launcher
            // aplica a própria máscara); no legacy pode ser maior.
            size: size * (gradient ? 0.56 : 0.62),
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  double size,
  bool gradient,
  String path,
) async {
  tester.view.physicalSize = Size(size, size);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_branding(size: size, gradient: gradient));
  await tester.pump();

  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  final image = await tester.runAsync(() => boundary.toImage());
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('gerado: $path (${File(path).lengthSync()} bytes)');
}

void main() {
  testWidgets('gera os PNGs da marca', (tester) async {
    // Foreground adaptativo (fundo transparente — o launcher pinta a cor).
    await _capture(tester, 1024, false, 'assets/branding/icon_fg.png');
    // Legacy (Android <8, iOS, web) — fundo gradiente opaco.
    await _capture(tester, 1024, true, 'assets/branding/icon_legacy.png');
    // Web: manifest + favicon.
    await _capture(tester, 512, true, 'web/icons/icon-512.png');
    await _capture(tester, 192, true, 'web/icons/icon-192.png');
    await _capture(tester, 48, true, 'web/icons/favicon.png');
  });
}
