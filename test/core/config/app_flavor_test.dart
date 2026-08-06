import 'package:dumbhanengue/core/config/app_flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFlavorConfig', () {
    test('sem dart-define, o padrão é dev (nunca confundir com produção)', () {
      // Os testes não passam --dart-define=FLUTTER_APP_FLAVOR, logo o
      // valor observado tem de ser o padrão `dev`.
      expect(AppFlavorConfig.rawFlavor, 'dev');
      expect(AppFlavorConfig.current, AppFlavor.dev);
      expect(AppFlavorConfig.isProd, isFalse);
      expect(AppFlavorConfig.label, 'dev');
    });
  });
}
