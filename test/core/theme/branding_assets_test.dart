import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';
const _androidNamespace = 'http://schemas.android.com/apk/res/android';

Future<ui.Image> _decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('splash clássico fixa dimensão no item e preenche com bitmap', () {
    for (final directory in ['drawable', 'drawable-v21']) {
      final xml = File(
        '$_res/$directory/launch_background.xml',
      ).readAsStringSync();
      expect(xml, contains(_androidNamespace));
      expect(
        xml,
        matches(
          RegExp(
            r'<item\s+android:width="144dp"\s+android:height="144dp"\s+android:gravity="center">',
          ),
        ),
      );
      final bitmap = RegExp(r'<bitmap[^>]*/>').firstMatch(xml)!.group(0)!;
      expect(bitmap, contains('android:gravity="fill"'));
      expect(bitmap, isNot(contains('android:width')));
      expect(bitmap, isNot(contains('android:height')));
    }
  });

  test('ícone redondo usa novos foregrounds e mesma margem do adaptive', () {
    final xml = File(
      '$_res/mipmap-anydpi-v26/ic_launcher_round.xml',
    ).readAsStringSync();
    expect(xml, contains('@drawable/ic_launcher_foreground'));
    expect(xml, contains('@drawable/ic_launcher_monochrome'));
    expect(xml, isNot(contains('@mipmap/ic_launcher_foreground')));
    expect(RegExp('android:inset="16%"').allMatches(xml), hasLength(2));
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      expect(
        File('$_res/mipmap-$density/ic_launcher_round.png').existsSync(),
        isTrue,
      );
    }
  });

  for (final directory in ['drawable-nodpi', 'drawable-night-nodpi']) {
    test('Android 12 $directory: marca na área circular segura', () async {
      final image = await _decode('$_res/$directory/splash_icon.png');
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final bytes = data.buffer.asUint8List();
      expect(image.width, 512);
      expect(image.height, 512);
      final radius = image.width * (192 / 288) / 2;
      var count = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          if (bytes[(y * image.width + x) * 4 + 3] <= 8) continue;
          count++;
          final dx = x + 0.5 - image.width / 2;
          final dy = y + 0.5 - image.height / 2;
          expect(math.sqrt(dx * dx + dy * dy), lessThan(radius));
        }
      }
      expect(count, greaterThan(1000));
      image.dispose();
    });
  }

  test('PWA maskable é opaco e toda a marca cabe no círculo seguro', () async {
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    expect(manifest['background_color'], '#F0F1F5');
    expect(manifest['theme_color'], '#0A0E15');
    final icon = (manifest['icons'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((icon) => icon['purpose'] == 'maskable');
    final image = await _decode('web/${icon['src']}');
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    var markPixels = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final index = (y * image.width + x) * 4;
        expect(bytes[index + 3], 255);
        // Qualquer pixel mais claro que a tinta é parte da marca ou da franja AA.
        if (bytes[index] <= 12 &&
            bytes[index + 1] <= 16 &&
            bytes[index + 2] <= 23) {
          continue;
        }
        markPixels++;
        final dx = x + 0.5 - image.width / 2;
        final dy = y + 0.5 - image.height / 2;
        expect(math.sqrt(dx * dx + dy * dy), lessThan(image.width * 0.4));
      }
    }
    expect(markPixels, greaterThan(1000));
    image.dispose();
  });
}
