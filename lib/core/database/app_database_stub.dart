import 'package:get_it/get_it.dart';

/// Versão **web** do bootstrap SQLite: `dart:ffi` não existe no
/// navegador, então o SQLite nunca está disponível — o ServiceLocator
/// usa os datasources em memória (mesmos contratos, mesma UI).
abstract final class AppDatabase {
  /// ⚠️ Manter as assinaturas de `openAppDatabase()`,
  /// `registerDatasources()` e `registerOfflineQueue()` em sincronia com
  /// `app_database_io.dart`.
  static Future<bool> openAppDatabase() async => false;

  static void registerDatasources(GetIt instance) {
    // Nunca chamado na web: openAppDatabase sempre retorna false.
  }

  static void registerOfflineQueue(GetIt instance) {
    // Nunca chamado na web: openAppDatabase sempre retorna false.
  }
}
