import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/core/security/secure_storage_service.dart';
import 'package:dumbhanengue/core/security/secure_supabase_local_storage.dart';

/// Backend em memória — simula o Keychain/Keystore sem plataforma (mesmo
/// padrão do teste do SecureStorageService).
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
 group('SecureSupabaseLocalStorage', () {
 late _InMemoryBackend backend;
 late SecureSupabaseLocalStorage storage;

 setUp(() {
 backend = _InMemoryBackend();
 storage = SecureSupabaseLocalStorage(backend: backend);
 });

 test(
 'persistSession grava a sessão no backend SEGURO (Keychain/Keystore)',
 () async {
 await storage.persistSession('{"access_token":"abc"}');

 expect(await backend.read(SecureSupabaseLocalStorage.sessionKey),
 '{"access_token":"abc"}');
 });

 test('hasAccessToken reflete a presença da sessão', () async {
 expect(await storage.hasAccessToken(), isFalse);

 await storage.persistSession('{"access_token":"abc"}');

 expect(await storage.hasAccessToken(), isTrue);
 });

 test('accessToken devolve a sessão persistida; null quando ausente',
 () async {
 expect(await storage.accessToken(), isNull);

 await storage.persistSession('{"access_token":"abc"}');

 expect(await storage.accessToken(), '{"access_token":"abc"}');
 });

 test('removePersistedSession apaga a sessão (logout limpo)', () async {
 await storage.persistSession('{"access_token":"abc"}');
 expect(await storage.hasAccessToken(), isTrue);

 await storage.removePersistedSession();

 expect(await storage.hasAccessToken(), isFalse);
 expect(await storage.accessToken(), isNull);
 });

 test('initialize é um no-op seguro (sem exigir binding de plataforma)',
 () async {
 await storage.initialize();
 expect(await storage.hasAccessToken(), isFalse);
 });
 });

 group('SecureGotrueAsyncStorage (PKCE code verifier no armazenamento seguro)',
 () {
 late _InMemoryBackend backend;
 late SecureGotrueAsyncStorage storage;

 setUp(() {
 backend = _InMemoryBackend();
 storage = SecureGotrueAsyncStorage(backend: backend);
 });

 test('setItem/getItem round-trip pelo backend seguro', () async {
 await storage.setItem(key: 'pkce_verifier', value: 'verifier-abc');

 expect(await storage.getItem(key: 'pkce_verifier'), 'verifier-abc');
 expect(await backend.read('pkce_verifier'), 'verifier-abc');
 });

 test('getItem retorna null para chave inexistente', () async {
 expect(await storage.getItem(key: 'nada'), isNull);
 });

 test('removeItem apaga a chave (verifier de uso único é descartado)',
 () async {
 await storage.setItem(key: 'pkce_verifier', value: 'verifier-abc');

 await storage.removeItem(key: 'pkce_verifier');

 expect(await storage.getItem(key: 'pkce_verifier'), isNull);
 });
 });
}
