import 'package:supabase_flutter/supabase_flutter.dart';

import 'secure_storage_service.dart';

/// [LocalStorage] do Supabase apoiado no [FlutterSecureStorageBackend]
/// (Keychain no iOS/macOS, Keystore criptografado no Android) em vez do
/// padrão do SDK — `SharedPreferencesLocalStorage` (texto claro).
///
/// **Por que isso importa (auditoria S1, Aug 6):** o `supabase_flutter`
/// persiste a sessão (access token + refresh token) num `shared_preferences`
/// por padrão — um arquivo XML em texto claro no dispositivo. Qualquer app
/// com acesso ao sandbox/armazenamento (ou um backup não criptografado)
/// conseguiria ler o refresh token e sequestrar a sessão. Com esta
/// implementação, a sessão inteira vive num único valor criptografado do
/// Keychain/Keystore — a mesma classe de proteção já usada pelo
/// [SecureStorageService] do app.
///
/// Atenção: **Web:** o `flutter_secure_storage` 10.x não suporta a web (o
/// `SupabaseBootstrap` mantém o default do SDK nessa plataforma — o
/// `localStorage` do navegador, limitação documentada). Este tipo só é
/// registrado em plataformas nativas.
final class SecureSupabaseLocalStorage implements LocalStorage {
  /// [backend] injetável para testes (padrão: backend real do Keychain).
  SecureSupabaseLocalStorage({SecureStorageBackend? backend})
    : _backend = backend ?? const FlutterSecureStorageBackend();

  final SecureStorageBackend _backend;

  /// Chave única onde a sessão serializada do Supabase é gravada.
  static const String sessionKey = 'sb_session';

  /// A sessão é criptografada no Keychain/Keystore — nada a fazer além de
  /// garantir o binding (as plataformas nativas inicializam sob demanda).
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _backend.read(sessionKey)) != null;

  @override
  Future<String?> accessToken() => _backend.read(sessionKey);

  @override
  Future<void> removePersistedSession() => _backend.delete(sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _backend.write(sessionKey, persistSessionString);
}

/// Armazenamento do **code verifier do fluxo PKCE** apoiado no mesmo backend
/// seguro (Keychain/Keystore).
///
/// O `supabase_flutter` guarda o verifier num `shared_preferences` por
/// padrão (via `SharedPreferencesGotrueAsyncStorage`). O verifier é
/// transitório e de uso único, mas é material de autenticação — manter tudo
/// no armazenamento criptografado remove a última peça em texto claro do
/// ciclo de login (auditoria S1, Aug 6).
final class SecureGotrueAsyncStorage implements GotrueAsyncStorage {
  /// [backend] injetável para testes (padrão: backend real do Keychain).
  SecureGotrueAsyncStorage({SecureStorageBackend? backend})
    : _backend = backend ?? const FlutterSecureStorageBackend();

  final SecureStorageBackend _backend;

  @override
  Future<String?> getItem({required String key}) => _backend.read(key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _backend.write(key, value);

  @override
  Future<void> removeItem({required String key}) => _backend.delete(key);
}
