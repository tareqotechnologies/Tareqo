import '../../core/security/biometric_service.dart';
import '../../core/security/secure_storage_service.dart';

/// Use case for biometric authentication
class BiometricAuthUseCase {
  BiometricAuthUseCase(this._biometricService, this._secureStorage);

  final BiometricService _biometricService;
  final SecureStorageService _secureStorage;

  /// Check if biometric authentication is available
  Future<bool> isAvailable() => _biometricService.isAvailable;

  /// Check if biometric authentication is enabled for the user
  Future<bool> isEnabled() async {
    return await _secureStorage.contains(SecureStorageKeys.biometricEnabled);
  }

  /// Enable biometric authentication
  Future<void> enable() async {
    await _secureStorage.write(SecureStorageKeys.biometricEnabled, 'true');
  }

  /// Disable biometric authentication
  Future<void> disable() async {
    await _secureStorage.delete(SecureStorageKeys.biometricEnabled);
  }

  /// Authenticate with biometrics
  /// Returns true if authentication succeeds
  ///
  /// As mensagens do prompt são repassadas ao [BiometricService] já
  /// localizadas pelos callers (auditoria M3) — o use case não conhece o
  /// contexto de UI.
  Future<bool> authenticate({
    String localizedReason = 'Autenticação biométrica',
    String signInTitle = 'Autenticação Biométrica',
    String biometricHint = 'Toque no sensor',
    String cancelButton = 'Cancelar',
    String fallbackTitle = 'Usar senha',
    String goToSettingsButton = 'Configurações',
    String goToSettingsDescription = 'Configure a autenticação biométrica',
    String lockOut = 'Tente novamente mais tarde',
  }) async {
    // Check if biometric is available on the device
    final available = await _biometricService.isAvailable;
    if (!available) {
      return false;
    }

    // Perform authentication
    return await _biometricService.authenticate(
      localizedReason: localizedReason,
      signInTitle: signInTitle,
      biometricHint: biometricHint,
      cancelButton: cancelButton,
      fallbackTitle: fallbackTitle,
      goToSettingsButton: goToSettingsButton,
      goToSettingsDescription: goToSettingsDescription,
      lockOut: lockOut,
    );
  }

  /// Get available biometric types
  Future<List<String>> getAvailableBiometrics() async {
    final types = await _biometricService.getAvailableBiometrics();
    return types.map((type) => type.toString()).toList();
  }
}
