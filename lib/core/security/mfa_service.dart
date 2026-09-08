import 'package:otp/otp.dart';

/// Service for Multi-Factor Authentication (MFA) using TOTP
class MFAService {
  MFAService();

  final int _digits = 6;
  final int _period = 30; // seconds

  /// Generate a random secret key for TOTP
  Future<String> generateSecret() async {
    // OTP.randomSecret() already returns a base32 encoded string
    return OTP.randomSecret();
  }

  /// Generate TOTP code for the given secret
  String generateTOTP(String secret) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      return OTP.generateTOTPCodeString(
        secret,
        now,
        length: _digits,
        interval: _period,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } catch (e) {
      throw Exception('Failed to generate TOTP: $e');
    }
  }

  /// Verify TOTP code against the secret
  /// Allows for clock skew by checking current and adjacent time windows
  bool verifyTOTP(String secret, String code) {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check current window
      final current = OTP.generateTOTPCodeString(
        secret,
        now,
        length: _digits,
        interval: _period,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (OTP.constantTimeVerification(current, code)) return true;

      // Check previous window (clock skew tolerance)
      final previousTime = now - (_period * 1000);
      final previous = OTP.generateTOTPCodeString(
        secret,
        previousTime,
        length: _digits,
        interval: _period,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (OTP.constantTimeVerification(previous, code)) return true;

      // Check next window
      final nextTime = now + (_period * 1000);
      final next = OTP.generateTOTPCodeString(
        secret,
        nextTime,
        length: _digits,
        interval: _period,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (OTP.constantTimeVerification(next, code)) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get time remaining until next TOTP code changes
  int getTimeRemaining() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return _period - (now % _period);
  }

  /// Generate QR code data for authenticator apps
  /// Format: otpauth://totp/Label:Account?secret=Secret&issuer=Issuer
  String generateQRCodeData({
    required String issuer,
    required String account,
    required String secret,
  }) {
    final label = Uri.encodeComponent('$issuer:$account');
    final params = {
      'secret': secret,
      'issuer': issuer,
      'algorithm': 'SHA1',
      'digits': _digits.toString(),
      'period': _period.toString(),
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'otpauth://totp/$label?$queryString';
  }

  /// Validate secret format (Base32)
  bool isValidSecret(String secret) {
    try {
      if (secret.isEmpty) return false;
      // Try to generate TOTP - if it fails, secret is invalid
      generateTOTP(secret);
      return true;
    } catch (e) {
      return false;
    }
  }
}
