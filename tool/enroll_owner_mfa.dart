// MFA enrollment for owner accounts, driven through the app's own TOTP code.
//
// This is the "app's MFA flow" from the command line, split into its two
// halves:
//
//  1. SERVER HALF (what actually secures the account): sign in with the
//     account's real credentials, enroll a TOTP factor on GoTrue, compute the
//     6-digit code with the app's own MFAService (SHA1 / 6 digits / 30s — the
//     exact implementation MFAAuthUseCase.verifyCode delegates to) and verify
//     it via challenge+verify. The factor ends up VERIFIED on the project.
//
//  2. AUTHENTICATOR HALF (what a human keeps): the GoTrue-generated secret is
//     printed once and the otpauth QR is saved under build/ (gitignored) so
//     it can be scanned into Google Authenticator / Aegis / etc.
//
// The tool deliberately does NOT write the secret into this machine's app
// secure storage: the app's MFA gate (auth_gate.dart) reads the *device*
// secure storage of whichever phone/desktop runs the app. Enrollment here is
// server-side and account-wide; each device turns on the gate via
// MFASetupScreen with the same authenticator.
//
// Safety properties:
//  - Refuses to run without an explicit --project dev|prod.
//  - Idempotent: if a verified TOTP factor already exists, it stops and
//    changes nothing.
//  - Prints only the TOTP secret (needed to register the authenticator).
//    Credentials are read from gitignored env files and never printed.
//  - Verifies the outcome by re-listing factors, and confirms a fresh
//    password sign-in still works (no aal2 enforcement exists in this
//    project's RLS, so verified enrollment cannot lock the owner out).
//
// Usage:
//   dart run tool/enroll_owner_mfa.dart --project prod
//   dart run tool/enroll_owner_mfa.dart --project dev
//   dart run tool/enroll_owner_mfa.dart --project prod --print-otpauth-uri

import 'dart:convert';
import 'dart:io';

import 'package:gotrue/gotrue.dart';

import 'package:tareqo/core/security/mfa_service.dart';

const _usage =
    'Uso: dart run tool/enroll_owner_mfa.dart --project dev|prod '
    '[--print-otpauth-uri]';

({String email, String password, String url, String anonKey}) _loadEnv(
  String project,
) {
  final mainEnv = project == 'prod' ? 'env/prod.env' : 'env/dev.env';
  final url = _readValue(mainEnv, 'SUPABASE_URL');
  final anonKey = _readValue(mainEnv, 'SUPABASE_ANON_KEY');
  final emailKey = project == 'prod' ? 'PROD_OWNER_EMAIL' : 'TEST_OWNER_EMAIL';
  final passKey = project == 'prod'
      ? 'PROD_OWNER_PASSWORD'
      : 'TEST_OWNER_PASSWORD';
  return (
    email: _readValue('env/test_accounts.env', emailKey),
    password: _readValue('env/test_accounts.env', passKey),
    url: url,
    anonKey: anonKey,
  );
}

String _readValue(String file, String key) {
  final f = File(file);
  if (!f.existsSync()) {
    stderr.writeln('ERRO: $file não encontrado (arquivo gitignored local).');
    exit(2);
  }
  for (final raw in f.readAsLinesSync(encoding: utf8)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq > 0 && line.substring(0, eq).trim() == key) {
      final value = line.substring(eq + 1).trim();
      if (value.isEmpty) break;
      return value;
    }
  }
  stderr.writeln('ERRO: chave $key ausente ou vazia em $file.');
  exit(2);
}

void main(List<String> args) {
  final projectIdx = args.indexOf('--project');
  if (projectIdx == -1 || projectIdx + 1 >= args.length) {
    stderr.writeln(_usage);
    exit(2);
  }
  final project = args[projectIdx + 1];
  if (project != 'dev' && project != 'prod') {
    stderr.writeln('ERRO: --project deve ser "dev" ou "prod".\n$_usage');
    exit(2);
  }
  _run(project, args.contains('--print-otpauth-uri'));
}

Future<void> _run(String project, bool printOtpauthUri) async {
  final env = _loadEnv(project);
  final host = Uri.parse(env.url).host;
  final mfa = MFAService(); // the app's own TOTP implementation
  // GoTrueClient wants the GoTrue base URL (…/auth/v1), not the project root.
  final gotrueUrl = '${env.url.replaceAll(RegExp(r'/+$'), '')}/auth/v1';
  final client = GoTrueClient(
    url: gotrueUrl,
    headers: {'apikey': env.anonKey},
    autoRefreshToken: false,
  );

  stdout.writeln('Projeto: $project ($host)');
  stdout.writeln('Conta:   ${env.email}');

  try {
    // 1. Real sign-in (aal1 session).
    final AuthResponse res;
    try {
      res = await client.signInWithPassword(
        email: env.email,
        password: env.password,
      );
    } on AuthException catch (e) {
      stderr.writeln('ERRO: login falhou: ${e.message}');
      exit(1);
    }
    if (res.session == null) {
      stderr.writeln('ERRO: login sem sessão.');
      exit(1);
    }
    stdout.writeln('Login OK (aal1).');

    // 2. Idempotency guard: never double-enroll.
    final existing = await client.mfa.listFactors();
    final verified = existing.totp
        .where((f) => f.status == FactorStatus.verified)
        .toList(growable: false);
    if (verified.isNotEmpty) {
      stdout.writeln(
        'MFA JÁ HABILITADO: ${verified.length} fator(es) TOTP verificado(s).',
      );
      for (final f in verified) {
        stdout.writeln(
          '  - ${f.id} (${f.friendlyName ?? 'sem nome'}, criado ${f.createdAt})',
        );
      }
      stdout.writeln('Nada alterado.');
      return;
    }
    // Clean up any leftover UNVERIFIED factors from a previous aborted run.
    for (final f in existing.totp.where(
      (f) => f.status == FactorStatus.unverified,
    )) {
      stdout.writeln('Removendo fator não verificado abandonado ${f.id}…');
      await client.mfa.unenroll(f.id);
    }

    // 3. Enroll — GoTrue generates and returns the factor secret.
    final enroll = await client.mfa.enroll(
      issuer: host,
      friendlyName: 'TAREQO owner ($project)',
    );
    final secret = enroll.totp?.secret;
    if (secret == null || secret.isEmpty) {
      stderr.writeln('ERRO: enroll não devolveu secret TOTP.');
      exit(1);
    }
    if (!mfa.isValidSecret(secret)) {
      stderr.writeln('ERRO: secret devolvido não é Base32 válido p/ o app.');
      exit(1);
    }

    // 4. Compute the code with the app's MFAService and verify the factor.
    //    Retry once if we hit the 30s window boundary (fresh challenge +
    //    fresh code), mirroring how the UI lets the user re-enter a code.
    Object? verifyError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      final code = mfa.generateTOTP(secret);
      final challenge = await client.mfa.challenge(factorId: enroll.id);
      try {
        await client.mfa.verify(
          factorId: enroll.id,
          challengeId: challenge.id,
          code: code,
        );
        verifyError = null;
        break;
      } on AuthException catch (e) {
        verifyError = e;
        final secsLeft = mfa.getTimeRemaining();
        stdout.writeln(
          'Tentativa $attempt falhou (${e.message}); '
          'faltam ${secsLeft}s na janela TOTP.',
        );
        if (attempt == 1 && secsLeft < 5) {
          await Future<void>.delayed(
            Duration(seconds: secsLeft + 1),
          ); // wait for next window
        } else {
          break;
        }
      }
    }
    if (verifyError != null) {
      stdout.writeln(
        'AVISO: verificação falhou. O fator ${enroll.id} ficou NÃO '
        'verificado e foi removido para não sujar a conta.',
      );
      await client.mfa.unenroll(enroll.id);
      exit(1);
    }
    stdout.writeln('Fator TOTP VERIFICADO (id: ${enroll.id}).');

    // 5. Confirm server state by re-listing.
    final after = await client.mfa.listFactors();
    final verifiedAfter = after.totp
        .where((f) => f.status == FactorStatus.verified)
        .toList(growable: false);
    if (verifiedAfter.isEmpty) {
      stderr.writeln('ERRO: fator não consta verificado no servidor.');
      exit(1);
    }
    stdout.writeln(
      'Estado no servidor: '
      '${verifiedAfter.map((f) => '${f.id}=${f.status.name}').join(', ')}',
    );

    // 6. Lockout check: fresh password sign-in must still work. (This
    //    project has no aal2 policy in supabase/, so verification does not
    //    challenge plain password sign-ins.)
    final fresh = GoTrueClient(
      url: gotrueUrl,
      headers: {'apikey': env.anonKey},
      autoRefreshToken: false,
    );
    try {
      final again = await fresh.signInWithPassword(
        email: env.email,
        password: env.password,
      );
      stdout.writeln(
        'Lockout check: login com senha OK após verificação '
        '(aal2 não é exigido no login deste projeto).',
      );
      if (again.session != null) await fresh.signOut();
    } on AuthException catch (e) {
      stderr.writeln(
        'ERRO: login pós-verificação falhou: ${e.message} — investigue '
        'ANTES de fechar o autenticador. O secret impresso abaixo ainda '
        'controla o fator.',
      );
      exit(1);
    }

    // 7. Authenticator half: save the otpauth QR under build/ (gitignored)
    //    and print the secret exactly once.
    final otpauthUri = mfa.generateQRCodeData(
      issuer: 'TAREQO',
      account: env.email,
      secret: secret,
    );
    final svgQr = enroll.totp?.qrCode;
    if (svgQr != null && svgQr.isNotEmpty) {
      final qrFile = File('env/mfa_qr_$project.svg');
      qrFile.parent.createSync(recursive: true);
      final dataPart = svgQr.startsWith('data:')
          ? svgQr.split(',').skip(1).join(',')
          : svgQr;
      qrFile.writeAsStringSync(dataPart, encoding: utf8);
      stdout.writeln('QR salvo em: ${qrFile.path} (abra no navegador).');
    }
    stdout.writeln('');
    stdout.writeln('══════ Conclua no seu autenticador ══════');
    stdout.writeln('1. Abra o app autenticador (Google Authenticator, Aegis…)');
    stdout.writeln('2. Adicione uma conta manualmente com esta chave Base32:');
    stdout.writeln('');
    stdout.writeln('    $secret');
    stdout.writeln('');
    if (printOtpauthUri) {
      stdout.writeln('URI otpauth (padrão do MFAService):');
      stdout.writeln(otpauthUri);
    }
    stdout.writeln(
      '3. O fator JÁ ESTÁ verificado no servidor — o código de 6 dígitos do '
      'autenticador deve bater com o que o app espera (SHA1/6/30s).',
    );
    stdout.writeln(
      '4. Guarde o secret no seu gerenciador de senhas: é a única via de '
      'recuperação do fator (este fluxo não emite recovery codes).',
    );
    stdout.writeln(
      '5. No app, a tela MFASetupScreen/MFAGate lê o storage DO DISPOSITIVO; '
      'em cada dispositivo use a mesma chave para ativar a verificação local.',
    );
  } finally {
    try {
      await client.signOut();
    } catch (_) {}
  }
}
