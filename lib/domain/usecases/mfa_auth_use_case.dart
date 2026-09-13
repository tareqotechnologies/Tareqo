import '../../core/security/mfa_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../repositories/i_mfa_server_port.dart';

/// Caso de uso de MFA (TOTP) — ORQUESTRA o servidor (GoTrue) e o estado
/// local do dispositivo.
///
/// P1 (auditoria forense): antes, o MFA era APENAS client-side — a flag
/// `mfa_enabled` no armazenamento seguro protegia só a UI; quem roubasse a
/// senha usava a API direto. Agora:
///   * a MATRÍCULA do fator é feita no GoTrue (`IMfaServerPort`) — o fator
///     existe no servidor, não só no app;
///   * a VERIFICAÇÃO no login sobe a sessão para `aal = aal2` no SERVIDOR —
///     é esse claim que as guardas `mfa_ok()` do RLS consultam quando
///     `tenants.mfa_enforced`;
///   * a flag local continua existindo para o gate de UI (sem rede no
///     arranque), mas o SERVIDOR é a autoridade.
class MFAAuthUseCase {
  MFAAuthUseCase(this._mfaService, this._secureStorage, this._serverPort);

  final MFAService _mfaService;
  final SecureStorageService _secureStorage;
  final IMfaServerPort _serverPort;

  /// Fator em matrícula (em memória — sobrevive apenas à tela de setup).
  MfaPendingEnrollment? _pendingEnrollment;

  // ── Estado / consultas ────────────────────────────────────────────────

  /// MFA está habilitado (flag LOCAL — gate rápido de UI, funciona sem
  /// rede). A autoridade final é o servidor: a verificação no login passa
  /// obrigatoriamente pelo GoTrue ([verifyAndElevate]).
  Future<bool> isEnabled() async {
    final enabled = await _secureStorage.read(SecureStorageKeys.mfaEnabled);
    return enabled == 'true';
  }

  /// A conta tem fator TOTP VERIFICADO no servidor?
  Future<bool> serverHasVerifiedFactor() => _serverPort.hasVerifiedFactor();

  /// A sessão atual está em nível aal2 no servidor?
  Future<bool> sessionIsAal2() => _serverPort.sessionIsAal2();

  // ── Matrícula (setup) ─────────────────────────────────────────────────

  /// Inicia a matrícula: o SERVIDOR gera o secret TOTP (via
  /// [IMfaServerPort.beginTotpEnrollment]); o app guarda o secret apenas
  /// para exibição (QR/entrada manual) e devolve o fator pendente.
  Future<MfaPendingEnrollment> beginSetup() async {
    final pending = await _serverPort.beginTotpEnrollment();
    _pendingEnrollment = pending;
    // Guarda o secret localmente para a UI (QR já visível em re-renders).
    await _secureStorage.write(SecureStorageKeys.mfaSecret, pending.secret);
    return pending;
  }

  /// Conclui a matrícula com o código do autenticador do usuário. Só
  /// APÓS o servidor verificar é que a flag local é ligada.
  /// Código errado → `false` (a matrícula segue pendente para nova
  /// tentativa); falha de rede → exceção.
  Future<bool> completeSetup({required String code}) async {
    final pending = _pendingEnrollment;
    if (pending == null) {
      throw const MfaServerException(
        'Nenhuma matrícula em andamento — chame beginSetup primeiro.',
      );
    }
    final ok = await _serverPort.completeTotpEnrollment(
      factorId: pending.factorId,
      challengeId: pending.challengeId,
      code: code,
    );
    if (ok) {
      _pendingEnrollment = null;
      await confirmEnable();
    }
    return ok;
  }

  /// Cancela a matrícula em andamento (usuário fechou a tela): remove o
  /// fator NÃO verificado do servidor e limpa o estado local.
  Future<void> cancelSetup() async {
    final pending = _pendingEnrollment;
    _pendingEnrollment = null;
    await _secureStorage.delete(SecureStorageKeys.mfaSecret);
    if (pending != null) {
      try {
        await _serverPort.discardEnrollment(pending.factorId);
      } on Object {
        // Melhor esforço: fator fica unverified no servidor e é limpo na
        // próxima beginSetup (política do enroll_owner_mfa.dart).
      }
    }
  }

  // ── Verificação no login (elevação para aal2) ─────────────────────────

  /// Verifica o código no SERVIDOR (challenge + verify). Com código
  /// correto, o GoTrue devolve uma nova sessão com claim `aal2` — é isso
  /// que autoriza as escritas de dinheiro quando o tenant exige MFA.
  ///
  /// Erros de negócio (código inválido / sem fator) voltam como resultado;
  /// só falhas de transporte lançam.
  Future<MfaElevationResult> verifyAndElevate(String code) =>
      _serverPort.verifyAndElevate(code);

  // ── Desativação ───────────────────────────────────────────────────────

  /// Desativa o MFA: remove os fatores NO SERVIDOR e limpa o estado local.
  /// Se o servidor falhar (rede), a flag local permanece — o usuário
  /// continua protegido e pode tentar de novo (segurança primeiro).
  Future<void> disable() async {
    await _serverPort.unenrollAll();
    await _secureStorage.delete(SecureStorageKeys.mfaSecret);
    await _secureStorage.delete(SecureStorageKeys.mfaEnabled);
  }

  // ── Utilitários locais (QR/tempo/validação de formato) ────────────────

  /// Gera QR code data para o secret atual (exibição na tela de setup).
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

  /// Marca o MFA como habilitado localmente (chamado pelo use case após
  /// o servidor verificar a matrícula).
  Future<void> confirmEnable() async {
    await _secureStorage.write(SecureStorageKeys.mfaEnabled, 'true');
  }

  /// Tempo restante até o próximo código TOTP.
  int getTimeRemaining() => _mfaService.getTimeRemaining();

  /// Valida o formato Base32 de um secret.
  bool isValidSecret(String secret) => _mfaService.isValidSecret(secret);
}

/// Porta MFA SEM servidor (app rodando sem credenciais do Supabase —
/// dev/testes). Reproduz a semântica local antiga para não quebrar o fluxo
/// quando não há GoTrue: o secret é gerado localmente e a "verificação de
/// servidor" é o próprio TOTP local. Nenhuma escrita de dinheiro real é
/// protegida por este modo (não há servidor para proteger).
final class LocalOnlyMfaServerPort implements IMfaServerPort {
  LocalOnlyMfaServerPort(this._mfaService);

  final MFAService _mfaService;

  String? _secret;
  int _counter = 0;

  @override
  Future<bool> hasVerifiedFactor() async => _secret != null;

  @override
  Future<MfaPendingEnrollment> beginTotpEnrollment() async {
    _secret = await _mfaService.generateSecret();
    return (
      factorId: 'local-${_counter++}',
      challengeId: 'local-challenge',
      secret: _secret!,
    );
  }

  @override
  Future<bool> completeTotpEnrollment({
    required String factorId,
    required String challengeId,
    required String code,
  }) async {
    final secret = _secret;
    if (secret == null) return false;
    return _mfaService.verifyTOTP(secret, code);
  }

  @override
  Future<void> discardEnrollment(String factorId) async {
    _secret = null;
  }

  @override
  Future<MfaElevationResult> verifyAndElevate(String code) async {
    final secret = _secret;
    if (secret == null) return MfaElevationResult.noFactorEnrolled;
    return _mfaService.verifyTOTP(secret, code)
        ? MfaElevationResult.success
        : MfaElevationResult.invalidCode;
  }

  @override
  Future<bool> sessionIsAal2() async => _secret != null;

  @override
  Future<void> unenrollAll() async {
    _secret = null;
  }
}
