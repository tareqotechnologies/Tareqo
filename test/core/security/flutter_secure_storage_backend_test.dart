import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/security/secure_storage_service.dart';

/// Cobre o backend REAL ([FlutterSecureStorageBackend]) sobre o method
/// channel mockado — o teste dos métodos delegantes (read/write/delete/
/// contains) que os testes com backend em memória não exercitam. O canal
/// é o do plugin (plugins.it_nomads.com/flutter_secure_storage).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final store = <String, String>{};

  setUp(() {
    store.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final key = args['key'] as String?;
      switch (call.method) {
        case 'write':
          store[key!] = args['value'] as String;
          return null;
        case 'read':
          return store[key];
        case 'delete':
          store.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(store);
        case 'containsKey':
          return store.containsKey(key);
        default:
          return null;
      }
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('write/read fazem round-trip pelo canal do Keychain/Keystore', () async {
    const backend = FlutterSecureStorageBackend();
    final service = SecureStorageService(backend: backend);

    await service.write(SecureStorageKeys.mfaSecret, 'JBSWY3DPEHPK3PXP');

    expect(await service.read(SecureStorageKeys.mfaSecret), 'JBSWY3DPEHPK3PXP');
    // A flag mfaEnabled nunca foi gravada.
    expect(await service.contains(SecureStorageKeys.mfaEnabled), isFalse);
  });

  test('delete remove a chave (logout não deixa resíduo sensível)', () async {
    const backend = FlutterSecureStorageBackend();
    final service = SecureStorageService(backend: backend);

    await service.write(SecureStorageKeys.accessToken, 'jwt-xyz');
    await service.delete(SecureStorageKeys.accessToken);

    expect(await service.read(SecureStorageKeys.accessToken), isNull);
    expect(store, isNot(contains(SecureStorageKeys.accessToken)));
  });
}
