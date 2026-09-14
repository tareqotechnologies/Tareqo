/// Fatores em trânsito durante a matrícula TOTP no SERVIDOR (GoTrue).
///
/// `beginTotpEnrollment` cria o fator + challenge e devolve o secret
/// (gerado pelo SERVIDOR) para o app exibir (QR/entrada manual); o par
/// factor/challenge fica PENDENTE até `completeTotpEnrollment` verificar
/// o código do autenticador do usuário. `discardEnrollment` limpa fatores
/// abortados (mesma política do `tool/enroll_owner_mfa.dart`).
typedef MfaPendingEnrollment = ({
  String factorId,
  String challengeId,
  String secret,
});

/// Resultado da verificação do 2º fator no SERVIDOR (GoTrue).
///
/// Após [IMfaServerPort.verifyAndElevate] com código correto, a sessão é
/// RENOVADA com o claim `aal` em `aal2` — é isso que as guardas
/// `mfa_ok()`/`mfa_satisfied()` do RLS consultam. O estado local (flag no
/// armazenamento seguro) continua existindo para o gate de UI, mas o
/// SERVIDOR passa a ser a autoridade.
enum MfaElevationResult {
  /// Código correto: sessão renovada com aal2.
  success,

  /// Código inválido/janela expirada (tentar de novo).
  invalidCode,

  /// Nenhum fator TOTP verificado no GoTrue para esta conta (o dono ainda
  /// não matriculou — o gate local não deve assumir que o servidor aceita).
  noFactorEnrolled,
}

/// Porta para as operações de MFA que PRECISAM do servidor (GoTrue).
///
/// Separação de responsabilidades (P1 — auditoria forense):
///   * `MFAService` (TOTP local) — geração/validação de códigos para a UI;
///   * `MFAAuthUseCase` — orquestra local + servidor (esta porta);
///   * [IMfaServerPort] — matrícula e verificação no GoTrue: é o que faz o
///     fator EXISTIR e a sessão SUBIR para aal2 — o que o RLS passa a
///     exigir nas escritas de dinheiro quando `tenants.mfa_enforced`.
abstract interface class IMfaServerPort {
  /// A conta tem fator TOTP verificado no GoTrue?
  Future<bool> hasVerifiedFactor();

  /// Inicia a matrícula: cria o fator TOTP no GoTrue (o SERVIDOR gera o
  /// secret) e o challenge. Devolve o secret Base32 para exibição ao
  /// usuário (QR) + os identificadores do fator/challenge pendentes.
  ///
  /// Limpa previamente fatores não verificados de matrículas abortadas
  /// (idempotência com o fluxo do `tool/enroll_owner_mfa.dart`).
  Future<MfaPendingEnrollment> beginTotpEnrollment();

  /// Conclui a matrícula: verifica [code] no challenge pendente. O fator
  /// fica `verified` no GoTrue. Código errado NÃO lança — devolve `false`
  /// (a matrícula permanece pendente para nova tentativa).
  Future<bool> completeTotpEnrollment({
    required String factorId,
    required String challengeId,
    required String code,
  });

  /// Descarta um fator NÃO verificado (matrícula abortada pelo usuário).
  Future<void> discardEnrollment(String factorId);

  /// Verifica o código no SERVIDOR (challenge + verify) e renova a sessão
  /// com aal2. Retorna [MfaElevationResult.invalidCode] em código errado —
  /// NUNCA lança para entrada inválida (só para falhas de rede/transporte).
  Future<MfaElevationResult> verifyAndElevate(String code);

  /// Nível de garantia atual da sessão: `true` = aal2.
  Future<bool> sessionIsAal2();

  /// Remove TODOS os fatores TOTP (desativação no servidor).
  Future<void> unenrollAll();
}

/// Falha de servidor no fluxo MFA (transporte/resposta inesperada).
class MfaServerException implements Exception {
  const MfaServerException(this.message);

  final String message;

  @override
  String toString() => 'MfaServerException: $message';
}
