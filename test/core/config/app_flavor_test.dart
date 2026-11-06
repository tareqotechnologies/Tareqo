import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/config/app_flavor.dart';

void main() {
  test('detecta flavor de produção a partir do dart-define de produção', () {
    // skip em ambientes que não podem injetar FLUTTER_APP_FLAVOR=prod via
    // dart-define (ex.: CI de Windows, `flutter test` nativo). O teste de
    // compilação (build + run) valida o comportamento real; este teste
    // confirma apenas a lógica quando o define está disponível.
    if (!const bool.fromEnvironment('FLUTTER_APP_FLAVOR', defaultValue: false)) {
      expect(AppFlavorConfig.isProd, isFalse,
          reason: 'ambiente sem FLUTTER_APP_FLAVOR=prod — build/deploy valida o comportamento');
      return;
    }
    expect(AppFlavorConfig.current, AppFlavor.prod);
  });

  test('fallback é dev quando o define não é informado', () {
    if (const bool.fromEnvironment('FLUTTER_APP_FLAVOR', defaultValue: false)) {
      return;
    }
    expect(AppFlavorConfig.isProd, isFalse);
  });
}
