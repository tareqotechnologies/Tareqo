import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carrega as fontes REAIS usadas pelos goldens.
///
/// Sem isto o harness de teste renderiza com a fonte Ahem: o texto aparece
/// como blocos e os ícones como quadrados vazios — o master deixa de ser
/// uma prova visual fiel da tela. Carregamos:
///
/// * **Outfit** (`assets/fonts/Outfit-Variable.ttf`) — família do app;
/// * **MaterialIcons** (`materialicons-regular.otf` do SDK) — todos os
///   `Icon`/`IconData` do Material.
///
/// A fonte de ícones vive no cache do SDK, fora do bundle do projeto; o
/// caminho é resolvido por `FLUTTER_ROOT` (exportado pelo `flutter test`)
/// ou, como fallback, subindo a árvore a partir do próprio `flutter_tester`.
///
/// Uso: `setUpAll(loadGoldenFonts);`
Future<void> loadGoldenFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  await _loadFile('Outfit', 'assets/fonts/Outfit-Variable.ttf');

  final root = _flutterRoot();
  if (root == null) {
    throw StateError(
      'FLUTTER_ROOT não definido e o cache do SDK não foi encontrado — '
      'não é possível carregar MaterialIcons para os goldens.',
    );
  }
  await _loadFile(
    'MaterialIcons',
    '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
}

Future<void> _loadFile(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Fonte não encontrada para "$family": $path');
  }
  final bytes = file.readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

/// Raiz do SDK do Flutter: variável de ambiente ou ancestral do
/// `flutter_tester` (`…/bin/cache/artifacts/engine/<plataforma>/`).
String? _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;

  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 7; i++) {
    final marker = File(
      '${dir.path}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (marker.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}
