import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/repositories/i_mfa_server_port.dart';

/// Implementação [IMfaServerPort] sobre o GoTrue (Supabase auth).
///
/// O fluxo espelha o `tool/enroll_owner_mfa.dart` (mesma API, versão in-app):
///   * [beginTotpEnrollment] / [completeTotpEnrollment] — enroll (o SERVIDOR
///     gera o secret) → o app mostra o secret ao usuário (QR) → challenge +
///     verify com o código do autenticador → fator fica `verified` no
///     projeto;
///   * [verifyAndElevate] — challenge + verify no LOGIN: o GoTrue devolve um
///     NOVO access token com claim `aal = aal2` e o `_saveSession` do SDK o
///     persiste (mesma sessão, nível mais alto) — é esse claim que as
///     guardas `mfa_ok()`/`mfa_satisfied()` do RLS consultam;
///   * [sessionIsAal2] — lê o claim `aal` da sessão atual.
///
/// Erros de NEGÓCIO (código inválido) viram resultado/`false` — só falhas
/// de transporte propagam exceção (o chamador distingue).
final class SupabaseMfaServerPort implements IMfaServerPort {
  const SupabaseMfaServerPort();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Future<bool> hasVerifiedFactor() async {
    try {
      final factors = await _auth.mfa.listFactors();
      return factors.all.any((f) => f.status == FactorStatus.verified);
    } on AuthException {
      // Sem sessão/sem rede: trata como "não verificado" (o gate de UI
      // decide o que fazer; o SERVIDOR rejeitará escritas por si só).
      return false;
    }
  }

  @override
  Future<MfaPendingEnrollment> beginTotpEnrollment() async {
    // Idempotência: fator verificado já existente → nada a fazer.
    final existing = await _auth.mfa.listFactors();
    if (existing.all.any((f) => f.status == FactorStatus.verified)) {
      throw const MfaServerException(
        'A conta já possui um fator TOTP verificado no servidor.',
      );
    }
    // Limpa fatores não verificados de matrículas abortadas (mesma
    // política do tool/enroll_owner_mfa.dart).
    for (final f in existing.all.where(
      (f) => f.status == FactorStatus.unverified,
    )) {
      await _auth.mfa.unenroll(f.id);
    }

    // Matrícula: o SERVIDOR gera e devolve o secret TOTP.
    final enroll = await _auth.mfa.enroll(
      factorType: FactorType.totp,
      friendlyName: 'TAREQO',
    );
    final secret = enroll.totp?.secret;
    if (secret == null || secret.isEmpty) {
      throw const MfaServerException('GoTrue não devolveu o secret TOTP.');
    }
    // Challenge imediato: o par fica pendente até o verify do usuário.
    final challenge = await _auth.mfa.challenge(factorId: enroll.id);
    return (
      factorId: enroll.id,
      challengeId: challenge.id,
      secret: secret,
    );
  }

  @override
  Future<bool> completeTotpEnrollment({
    required String factorId,
    required String challengeId,
    required String code,
  }) async {
    try {
      await _auth.mfa.verify(
        factorId: factorId,
        challengeId: challengeId,
        code: code,
      );
      return true;
    } on AuthException {
      // Código rejeitado: a matrícula permanece pendente (a UI deixa o
      // usuário tentar outro código; discardEnrollment limpa ao sair).
      return false;
    }
  }

  @override
  Future<void> discardEnrollment(String factorId) async {
    await _auth.mfa.unenroll(factorId);
  }

  @override
  Future<MfaElevationResult> verifyAndElevate(String code) async {
    final factors = await _auth.mfa.listFactors();
    final verified = factors.all
        .where((f) => f.status == FactorStatus.verified)
        .toList(growable: false);
    if (verified.isEmpty) {
      return MfaElevationResult.noFactorEnrolled;
    }
    for (final factor in verified) {
      final challenge = await _auth.mfa.challenge(factorId: factor.id);
      try {
        await _auth.mfa.verify(
          factorId: factor.id,
          challengeId: challenge.id,
          code: code,
        );
        // Sucesso: o SDK salvou a sessão nova com claim aal2.
        return MfaElevationResult.success;
      } on AuthException {
        // Código rejeitado neste fator — tenta o próximo (multi-fator);
        // se todos falharem, é entrada inválida.
        continue;
      }
    }
    return MfaElevationResult.invalidCode;
  }

  @override
  Future<bool> sessionIsAal2() async {
    try {
      return _auth.mfa.getAuthenticatorAssuranceLevel().currentLevel ==
          AuthenticatorAssuranceLevels.aal2;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> unenrollAll() async {
    final factors = await _auth.mfa.listFactors();
    for (final f in factors.all) {
      await _auth.mfa.unenroll(f.id);
    }
  }
}
