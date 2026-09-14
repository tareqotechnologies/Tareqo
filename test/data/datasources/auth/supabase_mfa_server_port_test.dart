import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/data/datasources/auth/supabase_mfa_server_port.dart';
import 'package:tareqo/domain/repositories/i_mfa_server_port.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Contrato REST da porta MFA sobre o GoTrue (stub HTTP — sem rede real):
/// - `listFactors` NÃO tem endpoint próprio: o SDK atualiza a sessão
///   (`POST {auth}/token`) e lê `user.factors` — o stub sobrescreve o
///   payload do token por teste ([StubSupabaseHttp.tokenPayloadOverride]);
/// - matrícula TOTP (secret gerado pelo SERVIDOR) + limpeza de fatores
///   abortados;
/// - verificação no login devolve resultado de negócio (código rejeitado
///   NUNCA vira AuthException para o chamador);
/// - falhas de TRANSPORTE propagam (o chamador distingue), exceto onde o
///   contrato manda engolir (`hasVerifiedFactor`/`sessionIsAal2`);
/// - nível de garantia (`aal2`) lido do claim `aal` do JWT da sessão.
void main() {
  late StubSupabaseHttp stub;

  setUpAll(() async {
    stub = await initStubbedSupabase();
    await signInStubUser();
  });

  setUp(() {
    stub.handler = null;
    stub.tokenPayloadOverride = null;
    stub.requests.clear();
  });

  final port = const SupabaseMfaServerPort();

  // ── Builders de payload ────────────────────────────────────────────────

  /// JWT mínimo com os claims que o SDK lê (`aal`, `exp`). Padding
  /// preservado — o decoder do GoTrue usa base64url COM padding.
  String jwt(Map<String, dynamic> claims) {
    String enc(Object o) => base64Url.encode(utf8.encode(jsonEncode(o)));
    return '${enc({'alg': 'HS256', 'typ': 'JWT'})}.${enc(claims)}.sig';
  }

  Map<String, dynamic> factor(String id, {String status = 'verified'}) => {
    'id': id,
    'friendly_name': 'TAREQO',
    'factor_type': 'totp',
    'status': status,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  };

  /// Payload do `POST {auth}/token` — define fatores + claim `aal` vistos
  /// pelo SDK após o refresh da sessão.
  Map<String, dynamic> sessionPayload({
    String aal = 'aal1',
    List<Map<String, dynamic>> factors = const [],
  }) => {
    'access_token': jwt({'aal': aal, 'sub': 'u1', 'exp': 4102444800}),
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': 4102444800,
    'refresh_token': 'refresh-x',
    'user': {
      'id': 'u1',
      'aud': 'authenticated',
      'email': 'dono@test.local',
      'factors': factors,
      'created_at': '2026-01-01T00:00:00Z',
    },
  };

  /// Resposta do `POST {auth}/factors/{id}/verify` — o SDK salva esta
  /// sessão (novo access token com o claim `aal` elevado).
  Map<String, dynamic> verifySessionPayload({String aal = 'aal2'}) => {
    'access_token': jwt({'aal': aal, 'sub': 'u1', 'exp': 4102444800}),
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'refresh-v',
    'user': {
      'id': 'u1',
      'aud': 'authenticated',
      'email': 'dono@test.local',
      'created_at': '2026-01-01T00:00:00Z',
    },
  };

  group('hasVerifiedFactor', () {
    test('true quando a sessão tem fator TOTP verificado', () async {
      stub.tokenPayloadOverride = () => sessionPayload(factors: [factor('f1')]);

      expect(await port.hasVerifiedFactor(), isTrue);
    });

    test('false sem fatores', () async {
      stub.tokenPayloadOverride = () => sessionPayload();

      expect(await port.hasVerifiedFactor(), isFalse);
    });

    test(
      'fator unverified (matrícula abortada) não conta como verificado',
      () async {
        stub.tokenPayloadOverride = () =>
            sessionPayload(factors: [factor('f1', status: 'unverified')]);

        expect(await port.hasVerifiedFactor(), isFalse);
      },
    );

    test(
      'AuthException de transporte → false (servidor bloqueia por si)',
      () async {
        stub.failNext = 1;

        expect(await port.hasVerifiedFactor(), isFalse);
      },
    );
  });

  group('beginTotpEnrollment', () {
    test(
      'fator verificado já existente → MfaServerException, sem matrícula',
      () async {
        stub.tokenPayloadOverride = () =>
            sessionPayload(factors: [factor('f1')]);

        await expectLater(
          port.beginTotpEnrollment(),
          throwsA(isA<MfaServerException>()),
        );
        // Idempotência: nenhum POST de matrícula foi emitido.
        expect(
          stub.requests.where(
            (r) => r.method == 'POST' && r.url.path.endsWith('/factors'),
          ),
          isEmpty,
        );
      },
    );

    test(
      'limpa fatores abortados (DELETE) e matricula com secret do servidor',
      () async {
        stub.tokenPayloadOverride = () =>
            sessionPayload(factors: [factor('stale', status: 'unverified')]);
        stub.handler = (path, request) {
          if (path.endsWith('/factors') && request.method == 'POST') {
            return FakeResponse({
              'id': 'f-novo',
              'type': 'totp',
              'totp': {
                'qr_code': '',
                'secret': 'JBSWY3DPEHPK3PXP',
                'uri': 'otpauth://totp/TAREQO',
              },
            });
          }
          if (path.endsWith('/factors/f-novo/challenge')) {
            return FakeResponse({'id': 'ch-1', 'expires_at': 4102444800});
          }
          // DELETE {auth}/factors/{id} (limpeza de abortadas) — o SDK faz
          // parse do corpo como Map.
          return FakeResponse({'id': 'ok'});
        };

        final pending = await port.beginTotpEnrollment();

        expect(pending.factorId, 'f-novo');
        expect(pending.challengeId, 'ch-1');
        expect(pending.secret, 'JBSWY3DPEHPK3PXP');
        // O fator abortado foi removido ANTES da nova matrícula.
        expect(
          stub.requests.where(
            (r) =>
                r.method == 'DELETE' && r.url.path.endsWith('/factors/stale'),
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'GoTrue sem secret na resposta → MfaServerException com mensagem',
      () async {
        stub.tokenPayloadOverride = () => sessionPayload();
        stub.handler = (path, request) {
          if (path.endsWith('/factors') && request.method == 'POST') {
            return FakeResponse({'id': 'f2', 'type': 'totp'});
          }
          return FakeResponse(<dynamic>[]);
        };

        await expectLater(
          port.beginTotpEnrollment(),
          throwsA(
            isA<MfaServerException>().having(
              (e) => e.message,
              'message',
              'GoTrue não devolveu o secret TOTP.',
            ),
          ),
        );
      },
    );
  });

  group('completeTotpEnrollment', () {
    test('código correto → true (fator verificado no servidor)', () async {
      stub.handler = (path, request) {
        if (path.endsWith('/factors/f1/verify')) {
          return FakeResponse(verifySessionPayload());
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(
        await port.completeTotpEnrollment(
          factorId: 'f1',
          challengeId: 'ch1',
          code: '123456',
        ),
        isTrue,
      );
    });

    test(
      'código rejeitado (422) → false (erro de negócio, não transporte)',
      () async {
        stub.handler = (path, request) => FakeResponse({
          'error': 'verify_failed',
          'msg': 'código inválido',
        }, status: 422);

        expect(
          await port.completeTotpEnrollment(
            factorId: 'f1',
            challengeId: 'ch1',
            code: '000000',
          ),
          isFalse,
        );
      },
    );
  });

  test('discardEnrollment emite DELETE do fator', () async {
    stub.handler = (path, request) => FakeResponse({'id': 'f1'});

    await port.discardEnrollment('f1');

    expect(
      stub.requests.where(
        (r) => r.method == 'DELETE' && r.url.path.endsWith('/factors/f1'),
      ),
      isNotEmpty,
    );
  });

  group('verifyAndElevate', () {
    test(
      'sem fator verificado → noFactorEnrolled (nenhum challenge)',
      () async {
        stub.tokenPayloadOverride = () =>
            sessionPayload(factors: [factor('f1', status: 'unverified')]);

        final result = await port.verifyAndElevate('123456');

        expect(result, MfaElevationResult.noFactorEnrolled);
        expect(
          stub.requests.where((r) => r.url.path.contains('/challenge')),
          isEmpty,
        );
      },
    );

    test('verificação no login → success (sessão renovada com aal2)', () async {
      stub.tokenPayloadOverride = () => sessionPayload(factors: [factor('f1')]);
      stub.handler = (path, request) {
        if (path.endsWith('/factors/f1/challenge')) {
          return FakeResponse({'id': 'ch-9', 'expires_at': 4102444800});
        }
        if (path.endsWith('/factors/f1/verify')) {
          return FakeResponse(verifySessionPayload());
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(await port.verifyAndElevate('654321'), MfaElevationResult.success);
    });

    test('código rejeitado em todos os fatores → invalidCode', () async {
      stub.tokenPayloadOverride = () =>
          sessionPayload(factors: [factor('f1'), factor('f2')]);
      stub.handler = (path, request) {
        if (path.endsWith('/challenge')) {
          return FakeResponse({'id': 'ch-x', 'expires_at': 4102444800});
        }
        if (path.endsWith('/verify')) {
          return FakeResponse({
            'error': 'verify_failed',
            'msg': 'inválido',
          }, status: 422);
        }
        return FakeResponse(<dynamic>[]);
      };

      expect(
        await port.verifyAndElevate('111111'),
        MfaElevationResult.invalidCode,
      );
    });
  });

  group('sessionIsAal2', () {
    test('claim aal2 no JWT da sessão → true', () async {
      stub.tokenPayloadOverride = () =>
          sessionPayload(aal: 'aal2', factors: [factor('f1')]);
      // sessionIsAal2 lê a sessão CORRENTE (sem refresh) — aquece a sessão
      // com o override antes (hasVerifiedFactor dispara o refresh).
      await port.hasVerifiedFactor();

      expect(await port.sessionIsAal2(), isTrue);
    });

    test('claim aal1 → false', () async {
      stub.tokenPayloadOverride = () => sessionPayload(aal: 'aal1');
      await port.hasVerifiedFactor();

      expect(await port.sessionIsAal2(), isFalse);
    });

    test('token ilegível como JWT → false (nunca propaga)', () async {
      // A sessão corrente carrega um token NÃO-JWT (o default do stub no
      // signIn) → o decode do claim falha e o contrato manda engolir.
      expect(await port.sessionIsAal2(), isFalse);
    });
  });

  test('unenrollAll remove TODOS os fatores da conta', () async {
    stub.tokenPayloadOverride = () =>
        sessionPayload(factors: [factor('f1'), factor('f2')]);
    stub.handler = (path, request) => FakeResponse({'id': 'ok'});

    await port.unenrollAll();

    final deletes = stub.requests
        .where((r) => r.method == 'DELETE' && r.url.path.contains('/factors/'))
        .toList();
    expect(deletes.length, 2);
  });
}
