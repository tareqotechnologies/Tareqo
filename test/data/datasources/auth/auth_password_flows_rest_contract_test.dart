import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tareqo/data/datasources/auth/supabase_auth_remote_data_source.dart';

import '../../../helpers/supabase_test_harness.dart';

/// Fluxos de SENHA do datasource de autenticação (contrato REST):
/// - `changePassword` EXIGE sessão (guarda), REAUTENTICA com a senha atual
///   e envia `current_password` no PUT /user — exigência do "Secure
///   password change" do GoTrue (sem o campo: 400 current_password_required);
/// - `setNewPassword` grava direto (fluxo de recovery — sem re-auth, sem
///   current_password: o GoTrue isenta sessões AMR=recovery dessa checagem);
/// - `resetPassword` aponta o redirect para o deep link `tareqo://callback`;
/// - `signUp` também embute o deep link no e-mail de confirmação
///   (`emailRedirectTo`) — sem isso o gotrue usa o `site_url` do projeto
///   (default: localhost:3000) e a confirmação nunca completa no app.
void main() {
  late StubSupabaseHttp stub;

  setUpAll(() async {
    stub = await initStubbedSupabase();
    // Sem signInStubUser aqui: o primeiro teste valida a guarda SEM sessão.
  });

  setUp(() {
    stub.handler = null;
    stub.requests.clear();
    stub.failNext = null;
  });

  Map<String, dynamic> userPayload() => {
    'id': 'u1',
    'aud': 'authenticated',
    'email': 'dono@test.local',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{'full_name': 'Dono Demo'},
    'created_at': '2026-01-01T00:00:00Z',
  };

  group('SupabaseAuthRemoteDataSourceImpl — fluxos de senha', () {
    final ds = SupabaseAuthRemoteDataSourceImpl();

    test(
      'changePassword sem sessão lança AuthException (nunca chama a API)',
      () async {
        await expectLater(
          ds.changePassword(
            currentPassword: 'atual-errada',
            newPassword: 'nova-forte-456',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Sessão expirada — entre novamente.',
            ),
          ),
        );
        // A guarda dispara ANTES de qualquer requisição de rede.
        expect(stub.requests.where((r) => r.method == 'PUT'), isEmpty);
      },
    );

    test(
      'changePassword reautentica, envia current_password no PUT e grava a nova',
      () async {
        await signInStubUser();

        stub.handler = (path, request) {
          if (path.contains('/user')) {
            // PUT {auth}/user — gravação da nova senha. O GoTrue com
            // "Secure password change" exige current_password no corpo.
            expect(request.method, 'PUT');
            final body = jsonBodyOf(request) as Map<String, dynamic>;
            expect(body['password'], 'nova-forte-456');
            expect(body['current_password'], 'senha-atual-123');
            return FakeResponse(userPayload());
          }
          // Reauth vai pelo /token (stub de sessão) — senha não vaza em log.
          return FakeResponse(<dynamic>[]);
        };

        await ds.changePassword(
          currentPassword: 'senha-atual-123',
          newPassword: 'nova-forte-456',
        );

        // A reautenticação aconteceu (POST /token) ANTES do PUT /user.
        final tokenIndex = stub.requests.indexWhere(
          (r) => r.url.path.endsWith('/token'),
        );
        final userIndex = stub.requests.indexWhere(
          (r) => r.url.path.contains('/user') && r.method == 'PUT',
        );
        expect(tokenIndex, isNot(-1));
        expect(userIndex, isNot(-1));
        expect(tokenIndex, lessThan(userIndex));
      },
    );

    test(
      'setNewPassword grava direto (fluxo recovery), sem reauth prévia',
      () async {
        await signInStubUser();
        stub.requests.clear(); // ignora as requisições do login de setup

        stub.handler = (path, request) {
          expect(request.method, 'PUT');
          final body = jsonBodyOf(request) as Map<String, dynamic>;
          expect(body['password'], 'senha-do-recovery-789');
          return FakeResponse(userPayload());
        };

        await ds.setNewPassword(newPassword: 'senha-do-recovery-789');

        // Nenhuma reautenticação: só o PUT do usuário.
        expect(
          stub.requests.where((r) => r.url.path.endsWith('/token')),
          isEmpty,
        );
      },
    );

    test('signUp embute tareqo://callback no e-mail de confirmação', () async {
      stub.handler = (path, request) {
        expect(path, contains('/signup'));
        expect(request.method, 'POST');
        // O redirect viaja como QUERY PARAM (gotrue fetch.dart), não no
        // corpo — igual ao /recover.
        expect(request.url.queryParameters['redirect_to'], 'tareqo://callback');
        final body = jsonBodyOf(request) as Map<String, dynamic>;
        expect(body['email'], 'dono@test.local');
        expect(body['data'], {'full_name': 'Dono Demo'});
        // Confirmação de e-mail ativa: resposta SEM sessão.
        return FakeResponse({'user': userPayload()});
      };

      final user = await ds.signUp(
        email: 'dono@test.local',
        password: 'senha-forte-123',
        fullName: 'Dono Demo',
      );
      expect(user.email, 'dono@test.local');
    });

    test('resetPassword aponta o redirect para tareqo://callback', () async {
      stub.handler = (path, request) {
        expect(path, contains('/recover'));
        expect(request.method, 'POST');
        final body = jsonBodyOf(request) as Map<String, dynamic>;
        expect(body['email'], 'dono@test.local');
        expect(request.url.queryParameters['redirect_to'], 'tareqo://callback');
        return FakeResponse(<dynamic>[]);
      };

      await ds.resetPassword(email: 'dono@test.local');
    });

    test('erro do servidor no PUT /user propaga AuthException', () async {
      await signInStubUser();

      stub.handler = (path, request) => FakeResponse({
        'msg': 'New password should be different',
      }, status: 422);

      await expectLater(
        ds.setNewPassword(newPassword: 'igual'),
        throwsA(isA<AuthException>()),
      );
    });

    test(
      'same_password (422) propaga AuthApiException com code mapeável',
      () async {
        await signInStubUser();

        stub.handler = (path, request) => FakeResponse({
          'code': 422,
          'error_code': 'same_password',
          'msg': 'New password should be different from the old password.',
        }, status: 422);

        await expectLater(
          ds.setNewPassword(newPassword: 'igual'),
          throwsA(
            isA<AuthApiException>().having(
              (e) => e.code,
              'code',
              'same_password',
            ),
          ),
        );
      },
    );

    test(
      'falha de rede no resetPassword propaga AuthRetryableFetchException',
      () async {
        stub.failNext = 1;

        // O gotrue envolve falhas de transporte em AuthRetryableFetchException
        // (o repositório traduz para mensagem amigável).
        await expectLater(
          ds.resetPassword(email: 'dono@test.local'),
          throwsA(isA<AuthRetryableFetchException>()),
        );
      },
    );
  });
}
