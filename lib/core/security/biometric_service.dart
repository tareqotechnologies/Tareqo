import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// Service for biometric authentication (fingerprint, face ID, etc.)
class BiometricService {
  BiometricService() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Check if biometric authentication is available on the device
  Future<bool> get isAvailable async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate with biometrics
  /// Returns true if authentication succeeds, false otherwise
  ///
  /// As mensagens do prompt (sistema Android/iOS) são parametrizáveis para
  /// seguir o idioma ativo do app (auditoria M3): os callers passam os
  /// valores de `context.l10n`. Os defaults em pt preservam o
  /// comportamento anterior para chamadas sem localização.
  Future<bool> authenticate({
    String localizedReason = 'Autenticação biométrica',
    String signInTitle = 'Autenticação Biométrica',
    String biometricHint = 'Toque no sensor',
    String cancelButton = 'Cancelar',
    String fallbackTitle = 'Usar senha',
    String goToSettingsButton = 'Configurações',
    String goToSettingsDescription = 'Configure a autenticação biométrica',
    String lockOut = 'Tente novamente mais tarde',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
        authMessages: [
          AndroidAuthMessages(
            signInTitle: signInTitle,
            biometricHint: biometricHint,
            cancelButton: cancelButton,
          ),
          IOSAuthMessages(
            cancelButton: cancelButton,
            localizedFallbackTitle: fallbackTitle,
            goToSettingsButton: goToSettingsButton,
            goToSettingsDescription: goToSettingsDescription,
            lockOut: lockOut,
          ),
        ],
      );
    } on PlatformException {
      // Handle exceptions like user cancellation, lockout, etc.
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Stop authentication if it's in progress
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors when stopping
    }
  }

  /// Check if device supports fingerprint
  Future<bool> get hasFingerprint async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.fingerprint) ||
        types.contains(BiometricType.strong);
  }

  /// Check if device supports face recognition
  Future<bool> get hasFace async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.face);
  }

  /// Check if device supports iris recognition
  Future<bool> get hasIris async {
    final types = await getAvailableBiometrics();
    return types.contains(BiometricType.iris);
  }
}
