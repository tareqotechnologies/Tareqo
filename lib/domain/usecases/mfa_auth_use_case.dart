import '../../core/security/mfa_service.dart';
import '../../core/security/secure_storage_service.dart';

/// Use case for Multi-Factor Authentication (MFA)
class MFAAuthUseCase {
  MFAAuthUseCase(this._mfaService, this._secureStorage);

  final MFAService _mfaService;
  final SecureStorageService _secureStorage;

  /// Check if MFA is enabled for the user
  Future<bool> isEnabled() async {
    final enabled = await _secureStorage.read(SecureStorageKeys.mfaEnabled);
    return enabled == 'true';
  }

  /// Start MFA setup: generate and store the secret, but do NOT
  /// mark as enabled yet. The user must verify a TOTP code first.
  /// Returns the secret key for the QR code.
  Future<String> generateSecret() async {
    final secret = await _mfaService.generateSecret();
    await _secureStorage.write(SecureStorageKeys.mfaSecret, secret);
    return secret;
  }

  /// Complete MFA setup after the user verifies a code.
  /// Only now do we mark MFA as enabled.
  Future<void> confirmEnable() async {
    await _secureStorage.write(SecureStorageKeys.mfaEnabled, 'true');
  }

  /// Disable MFA for the user
  Future<void> disable() async {
    await _secureStorage.delete(SecureStorageKeys.mfaSecret);
    await _secureStorage.delete(SecureStorageKeys.mfaEnabled);
  }

  /// Verify TOTP code
  Future<bool> verifyCode(String code) async {
    final secret = await _secureStorage.read(SecureStorageKeys.mfaSecret);
    if (secret == null) {
      return false;
    }

    return _mfaService.verifyTOTP(secret, code);
  }

  /// Generate QR code data for authenticator app setup
  Future<String> generateQRCodeData({
    required String issuer,
    required String account,
  }) async {
    final secret = await _secureStorage.read(SecureStorageKeys.mfaSecret);
    if (secret == null) {
      throw Exception('MFA not enabled. Please enable MFA first.');
    }

    return _mfaService.generateQRCodeData(
      issuer: issuer,
      account: account,
      secret: secret,
    );
  }

  /// Get time remaining until next TOTP code changes
  int getTimeRemaining() {
    return _mfaService.getTimeRemaining();
  }

  /// Validate secret format
  bool isValidSecret(String secret) {
    return _mfaService.isValidSecret(secret);
  }
}
