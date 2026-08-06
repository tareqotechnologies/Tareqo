import 'package:integration_test/integration_test_driver.dart';

/// Driver do teste de integração — usado por `flutter drive`:
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/access_levels_web_test.dart -d web-server \
///     --dart-define-from-file=env/dev.env --dart-define=TEST_*_EMAIL/PASSWORD
Future<void> main() => integrationDriver();
