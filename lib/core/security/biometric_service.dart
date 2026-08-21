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
  Future<bool> authenticate({
    String localizedReason = 'Autenticação biométrica',
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
            signInTitle: 'Autenticação Biométrica',
            biometricHint: 'Toque no sensor',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
            localizedFallbackTitle: 'Usar senha',
            goToSettingsButton: 'Configurações',
            goToSettingsDescription: 'Configure a autenticação biométrica',
            lockOut: 'Tente novamente mais tarde',
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
