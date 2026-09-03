import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/security/secure_storage_service.dart';

/// Backend em memória — simula o Keychain/Keystore sem plataforma.
class _InMemoryBackend implements SecureStorageBackend {
 final Map<String, String> _store = {};

 @override
 Future<String?> read(String key) async => _store[key];

 @override
 Future<void> write(String key, String value) async {
 _store[key] = value;
 }

 @override
 Future<void> delete(String key) async {
 _store.remove(key);
 }
}

void main() {
 late _InMemoryBackend backend;
 late SecureStorageService service;

 setUp(() {
 backend = _InMemoryBackend();
 service = SecureStorageService(backend: backend);
 });

 test('grava e lê um token de forma transparente (round-trip)', () async {
 await service.write(SecureStorageKeys.accessToken, 'token-abc-123');

 expect(
 await service.read(SecureStorageKeys.accessToken),
 'token-abc-123',
 );
 });

 test('read retorna null e contains false quando a chave não existe',
 () async {
 expect(await service.read(SecureStorageKeys.apiKey), isNull);
 expect(await service.contains(SecureStorageKeys.apiKey), isFalse);
 });

 test('delete remove a chave do armazenamento', () async {
 await service.write(SecureStorageKeys.refreshToken, 'refresh-xyz');
 expect(await service.contains(SecureStorageKeys.refreshToken), isTrue);

 await service.delete(SecureStorageKeys.refreshToken);

 expect(await service.contains(SecureStorageKeys.refreshToken), isFalse);
 });

 test('chaves diferentes não se sobrescrevem', () async {
 await service.write(SecureStorageKeys.accessToken, 'token-A');
 await service.write(SecureStorageKeys.apiKey, 'chave-B');

 expect(await service.read(SecureStorageKeys.accessToken), 'token-A');
 expect(await service.read(SecureStorageKeys.apiKey), 'chave-B');
 });
}
