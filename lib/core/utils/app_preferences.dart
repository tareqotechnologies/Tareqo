import 'package:shared_preferences/shared_preferences.dart';

/// Preferências locais simples (não-sensíveis) do app.
///
/// **Regra do projeto:** nada de dados sensíveis aqui — tokens/segredos
/// vão para o [SecureStorageService] (Keychain/Keystore). Este helper é
/// para preferências de UX (feedback tátil, template de fatura...).
///
/// Usa `SharedPreferencesAsync` (API nova do plugin, já dependência
/// direta via template persistente da fatura). Chaves prefixadas por
/// domínio — ver constantes públicas.
abstract final class AppPreferences {
  static Future<bool?> getBool(String key) =>
      SharedPreferencesAsync().getBool(key);

  static Future<void> setBool(String key, bool value) =>
      SharedPreferencesAsync().setBool(key, value);

  static Future<String?> getString(String key) =>
      SharedPreferencesAsync().getString(key);

  static Future<void> setString(String key, String value) =>
      SharedPreferencesAsync().setString(key, value);
}
