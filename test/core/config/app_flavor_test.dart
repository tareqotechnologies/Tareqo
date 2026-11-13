import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/config/app_flavor.dart';

void main() {
  const compiledFlavor = String.fromEnvironment(
    'FLUTTER_APP_FLAVOR',
    defaultValue: String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev'),
  );
  const expectedFlavor = compiledFlavor == 'prod'
      ? AppFlavor.prod
      : AppFlavor.dev;

  // Também executado em Chrome, com e sem APP_FLAVOR=prod: ler o ambiente
  // do sistema no navegador causava UnsupportedError antes do primeiro frame.
  test('detecta o flavor compilado sem exigir ambiente nativo', () {
    expect(AppFlavorConfig.current, expectedFlavor);
  });

  test('isProd acompanha o flavor compilado', () {
    expect(AppFlavorConfig.isProd, expectedFlavor == AppFlavor.prod);
  });

  test('rótulo acompanha o flavor compilado', () {
    expect(AppFlavorConfig.label, expectedFlavor.name);
  });
}
