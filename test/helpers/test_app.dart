import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:tareqo/core/security/secure_storage_service.dart';
import 'package:tareqo/core/theme/app_theme.dart';
import 'package:tareqo/l10n/generated/app_localizations.dart';

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

/// O [SecureStorageService] real é registrado no [ServiceLocator] apenas no
/// bootstrap (`main.dart` → `ServiceLocator.initialize`). As telas que
/// resolvem `mfaAuthUseCaseProvider`/`biometricAuthUseCaseProvider`
/// (ex.: [AuthGate]) quebrariam nos testes com GetIt vazio — registramos
/// aqui a mesma dependência com um backend em memória (mesmo padrão dos
/// testes de `core/security`). Idempotente por arquivo de teste.
///
/// Testes que montam o app de ponta a ponta ([TareqoApp]) sem passar por
/// [testApp] também devem chamá-la no `setUpAll`.
void registerTestSecureStorage() {
  final getIt = GetIt.instance;
  if (!getIt.isRegistered<SecureStorageService>()) {
    getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(backend: _InMemoryBackend()),
    );
  }
}

/// [MaterialApp] de teste com o delegate de localização do app e o locale
/// fixado em **pt** — as telas agora consomem `context.l10n` (AppLocalizations)
/// e, sem o delegate, quebrariam; e sem `locale` explícito o framework de
/// teste resolveria `en_US`, fazendo as asserções em português falharem.
///
/// O tema é o [AppTheme.dark] real do app (V3 — dark total): a suíte inteira
/// renderiza as telas sob o tema escuro de produção — teste visual
/// automatizado do modo escuro, incluindo as cores semânticas com variantes
/// por brilho (ver `theme_contrast_test.dart`, que valida as duas variantes).
///
/// Uso: `testApp(home: MinhaTela())` dentro do `ProviderScope`.
///
/// `theme` opcional: padrão [AppTheme.dark]; passe [AppTheme.light] para
/// testes que verificam o comportamento no modo claro (ex.: telas que
/// seguem o brilho do tema).
Widget testApp({
  required Widget home,
  Locale locale = const Locale('pt'),
  ThemeData? theme,
  // Inserido acima do Navigator (MaterialApp.builder) — mesmo papel do
  // AppLockOverlay em produção; coberto por app_lock_overlay_test.dart.
  Widget Function(BuildContext, Widget?)? builder,
}) {
  registerTestSecureStorage();
  return MaterialApp(
    locale: locale,
    theme: theme ?? AppTheme.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
    builder: builder,
  );
}
