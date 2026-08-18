import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Chaves centralizadas dos dados sensíveis persistidos no dispositivo.
///
/// Centralizar evita erros de digitação e facilita auditar exatamente
/// quais dados são tratados como sensíveis.
abstract final class SecureStorageKeys {
 /// Token de acesso da sessão do usuário.
 static const String accessToken = 'access_token';

 /// Token de renovação da sessão.
 static const String refreshToken = 'refresh_token';

 /// Chave de API de serviços externos (ex.: gateway de pagamento).
 static const String apiKey = 'api_key';
}

/// Backend de armazenamento criptografado (abstraído para testes).
///
/// A implementação real grava no Keychain (iOS) / Keystore (Android);
/// nos testes usamos um backend em memória (sem plataforma).
abstract interface class SecureStorageBackend {
 Future<String?> read(String key);

 Future<void> write(String key, String value);

 Future<void> delete(String key);
}

/// Backend real baseado em `flutter_secure_storage`.
///
/// - iOS/macOS: **Keychain** (enclave seguro do hardware);
/// - Android: **Android Keystore** com criptografia AES-GCM;
/// - Web/Windows/Linux: mecanismo seguro equivalente da plataforma.
final class FlutterSecureStorageBackend implements SecureStorageBackend {
 const FlutterSecureStorageBackend();

 static const FlutterSecureStorage _storage = FlutterSecureStorage();

 @override
 Future<String?> read(String key) => _storage.read(key: key);

 @override
 Future<void> write(String key, String value) =>
 _storage.write(key: key, value: value);

 @override
 Future<void> delete(String key) => _storage.delete(key: key);
}

/// Serviço que encapsula a persistência **criptografada** de tokens e
/// chaves de API.
///
/// Atenção: **Nunca** use `shared_preferences` para dados sensíveis — ele grava
/// em texto claro (ver README). Este serviço delega ao Keychain/Keystore,
/// onde a criptografia está amarrada ao hardware do dispositivo.
final class SecureStorageService {
 SecureStorageService({SecureStorageBackend? backend})
 : _backend = backend ?? const FlutterSecureStorageBackend();

 final SecureStorageBackend _backend;

 /// Grava [value] de forma criptografada sob [key].
 Future<void> write(String key, String value) => _backend.write(key, value);

 /// Lê o valor criptografado de [key]; `null` se não existir.
 Future<String?> read(String key) => _backend.read(key);

 /// Remove [key] do armazenamento seguro.
 Future<void> delete(String key) => _backend.delete(key);

 /// Verifica se [key] existe no armazenamento seguro.
 Future<bool> contains(String key) async =>
 (await _backend.read(key)) != null;
}
