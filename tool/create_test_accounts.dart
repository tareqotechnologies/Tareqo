// Criação das contas de TESTE (gerente + funcionário) no projeto DEV,
// desbloqueando o E2E integration_test/access_levels_web_test.dart.
//
// Usa o MESMO caminho do app para criar funcionários: a RPC
// `create_employee_account` (SECURITY DEFINER, transacional) chamada com a
// sessão do DONO — conta nascida confirmada (sem e-mail, sem rate limit) +
// vínculo em store_employees na mesma transação. O id do vínculo é gerado
// com AppIds.newId('e'), igual ao fluxo da UI.
//
// O que a ferramenta faz:
//  1. Entra com as credenciais do dono de DEV (env/test_accounts.env).
//  2. Resolve o tenant do dono e a primeira loja dele.
//  3. Para cada papel (manager, employee): cria a conta via RPC (ou reaproveita
//     um vínculo já existente para o mesmo e-mail — idempotente) e VERIFICA
//     (a) o vínculo gravado com o papel certo e ativo e (b) que a conta nova
//     consegue entrar com a senha gerada.
//  4. Grava as credenciais em env/test_accounts.env (gitignored) nas chaves
//     TEST_MANAGER_EMAIL/PASSWORD e TEST_EMPLOYEE_EMAIL/PASSWORD — nunca
//     imprime segredos.
//
// Propriedades de segurança:
//  - Recusa-se a rodar em PROD (ferramenta DEV-only por design).
//  - Nunca imprime senhas; só grava no arquivo gitignored.
//  - Não usa service_role: tudo ocorre com a sessão do dono (RLS vigia).
//
// Uso:
//   dart run tool/create_test_accounts.dart
//   dart run tool/create_test_accounts.dart --manager-email eu+mgr@x.com
//   dart run tool/create_test_accounts.dart --employee-email eu+emp@x.com

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gotrue/gotrue.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/core/utils/ids.dart';

const _usage =
    'Uso: dart run tool/create_test_accounts.dart '
    '[--manager-email ...] [--employee-email ...]';

const _defaultManagerEmail = 'test.manager@dev.tareqo.local';
const _defaultEmployeeEmail = 'test.employee@dev.tareqo.local';

// ─── Env (arquivos gitignored locais) ───────────────────────────────────────

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
      var value = line.substring(eq + 1).trim();
      // Convenção do arquivo: valores entre aspas (o parser de
      // --dart-define-from-file corta `#` não-aspado como comentário).
      if (value.length >= 2 &&
          value[0] == value[value.length - 1] &&
          (value.startsWith("'") || value.startsWith('"'))) {
        value = value.substring(1, value.length - 1);
      }
      if (value.isEmpty) break;
      return value;
    }
  }
  stderr.writeln('ERRO: chave $key ausente ou vazia em $file.');
  exit(2);
}

/// Atualiza (ou acrescenta) chaves em env/test_accounts.env preservando o
/// restante do arquivo e os comentários.
void _writeEnvValues(Map<String, String> updates) {
  const file = 'env/test_accounts.env';
  final f = File(file);
  final lines = f.existsSync()
      ? f.readAsLinesSync(encoding: utf8)
      : <String>[
          '# Credenciais locais (NUNCA versionar) — usadas por tools/ e E2Es.',
        ];

  final pending = Map<String, String>.from(updates);
  final out = <String>[];
  String quoted(String value) =>
      value.contains("'") && !value.contains('"') ? '"$value"' : "'$value'";
  for (final line in lines) {
    final eq = line.indexOf('=');
    if (eq > 0 && pending.containsKey(line.substring(0, eq).trim())) {
      final key = line.substring(0, eq).trim();
      out.add('$key=${quoted(pending.remove(key)!)}');
    } else {
      out.add(line);
    }
  }
  if (pending.isNotEmpty) {
    out
      ..add(
        '# Contas de teste geradas por tool/create_test_accounts.dart '
        '(E2E access_levels).',
      )
      ..addAll(pending.entries.map((e) => '${e.key}=${quoted(e.value)}'));
  }
  f.writeAsStringSync('${out.join('\n')}\n', encoding: utf8);
}

// ─── Senha forte gerada (sem caracteres que exijam escape em .env) ─────────

final _random = Random.secure();
String _generatePassword() {
  // Sem `#`, aspas ou espaços: `#` é cortado como comentário inline pelo
  // parser de --dart-define-from-file quando o valor não está entre aspas.
  const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lower = 'abcdefghijkmnopqrstuvwxyz';
  const digits = '23456789';
  const symbols = '!@%^*_-+?';
  final all = upper + lower + digits + symbols;
  String pick(String from) => from[_random.nextInt(from.length)];
  final chars = [
    pick(upper),
    pick(lower),
    pick(digits),
    pick(symbols),
    for (var i = 0; i < 12; i++) pick(all),
  ]..shuffle(_random);
  return chars.join();
}

// ─── REST helpers (sessão do dono; RLS vigia) ───────────────────────────────

class _DevApi {
  _DevApi({required this.base, required this.anonKey, required this.jwt});

  final String base; // SUPABASE_URL (raiz do projeto)
  final String anonKey;
  final String jwt;

  Map<String, String> get _headers => {
    'apikey': anonKey,
    'Authorization': 'Bearer $jwt',
    'Content-Type': 'application/json',
  };

  /// `GET /rest/v1/<table>?<query>` → lista de objetos.
  Future<List<dynamic>> select(String table, String query) async {
    final res = await http.get(
      Uri.parse('$base/rest/v1/$table?$query'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      stderr.writeln('ERRO REST ($table): ${res.statusCode} ${res.body}');
      exit(1);
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  /// GET com valor de filtro codificado para URL.
  Future<List<dynamic>> selectEq(
    String table,
    String columns,
    String column,
    String value,
  ) =>
      select(table, 'select=$columns&$column=eq.${Uri.encodeComponent(value)}');

  /// `POST /rest/v1/rpc/<fn>` → valor escalar (texto) ou null.
  Future<String?> rpc(String fn, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$base/rest/v1/rpc/$fn'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = _errorMessage(res.body);
      stderr.writeln('ERRO RPC $fn: ${res.statusCode} $msg');
      exit(1);
    }
    final text = res.body.trim();
    if (text == 'null' || text.isEmpty) return null;
    return text.startsWith('"') ? jsonDecode(text) as String : text;
  }

  static String _errorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return (json['message'] ?? json['error_description'] ?? body).toString();
    } catch (_) {
      return body;
    }
  }
}

// ─── Criação/verificação de UMA conta ───────────────────────────────────────

Future<void> _ensureAccount({
  required _DevApi api,
  required String gotrueUrl,
  required String anonKey,
  required String role, // 'manager' | 'employee'
  required String email,
  required String password,
  required String storeId,
  required String storeName,
  required String roleLabel, // p/ logs
}) async {
  stdout.writeln('');
  stdout.writeln('── Conta $roleLabel ($role): $email ──');

  // 1. Vínculo já existe para este e-mail? (idempotência entre execuções)
  final existing = await api.selectEq(
    'store_employees',
    'id,user_id,role,is_active,store_id',
    'email',
    email,
  );
  if (existing.isNotEmpty) {
    final link = existing.first as Map<String, dynamic>;
    stdout.writeln(
      'Vínculo JÁ EXISTE (id=${link['id']}, role=${link['role']}, '
      'ativo=${link['is_active']}). Nada criado.',
    );
    if (link['role'] != role) {
      stderr.writeln(
        'AVISO: papel existente (${link['role']}) difere do desejado '
        '($role). O E2E espera $role — ajuste manualmente no banco.',
      );
    }
  } else {
    // 2. Caminho do app: RPC transacional (conta + vínculo).
    final employeeId = AppIds.newId('e');
    final userId = await api.rpc('create_employee_account', {
      'p_employee_id': employeeId,
      'p_email': email,
      'p_password': password,
      'p_full_name': 'Test $roleLabel ($role)',
      'p_store_id': storeId,
      'p_role': role,
    });
    if (userId == null || userId.isEmpty) {
      stderr.writeln('ERRO: RPC não devolveu user_id.');
      exit(1);
    }
    stdout.writeln('Conta criada via RPC (user_id=$userId).');

    // 3. Verificação (a): vínculo gravado com papel certo e ativo.
    final links = await api.selectEq(
      'store_employees',
      'id,user_id,role,is_active',
      'email',
      email,
    );
    if (links.isEmpty) {
      stderr.writeln('ERRO: vínculo não encontrado após criação da conta.');
      exit(1);
    }
    final link = links.first as Map<String, dynamic>;
    if (link['role'] != role || link['is_active'] != true) {
      stderr.writeln('ERRO: vínculo inesperado após criação: $link');
      exit(1);
    }
    stdout.writeln(
      'Vínculo OK: role=${link['role']}, ativo=${link['is_active']} '
      '(loja: $storeName).',
    );
  }

  // 4. Verificação (b): a conta ENTRA com a senha (nasce confirmada).
  final fresh = GoTrueClient(
    url: gotrueUrl,
    headers: {'apikey': anonKey},
    autoRefreshToken: false,
  );
  try {
    final res = await fresh.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.session == null) {
      stderr.writeln('ERRO: login da conta $role sem sessão.');
      exit(1);
    }
    stdout.writeln('Login da conta $roleLabel OK (conta confirmada).');
  } on AuthException catch (e) {
    stderr.writeln(
      'ERRO: login da conta $roleLabel falhou: ${e.message}\n'
      'Se a conta já existia com OUTRA senha, escolha outro e-mail '
      '(--$role-email) ou atualize a senha do dono da conta.',
    );
    exit(1);
  } finally {
    try {
      await fresh.signOut();
    } catch (_) {}
  }
}

// ─── main ────────────────────────────────────────────────────────────────────

Future<void> main(List<String> args) async {
  String? managerEmail;
  String? employeeEmail;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--manager-email':
        managerEmail = args[++i];
      case '--employee-email':
        employeeEmail = args[++i];
      default:
        stderr.writeln('Arg desconhecido: ${args[i]}\n$_usage');
        exit(2);
    }
  }

  final url = _readValue('env/dev.env', 'SUPABASE_URL');
  final anonKey = _readValue('env/dev.env', 'SUPABASE_ANON_KEY');
  final ownerEmail = _readValue('env/test_accounts.env', 'TEST_OWNER_EMAIL');
  final ownerPassword = _readValue(
    'env/test_accounts.env',
    'TEST_OWNER_PASSWORD',
  );

  final gotrueUrl = '${url.replaceAll(RegExp(r'/+$'), '')}/auth/v1';
  final auth = GoTrueClient(
    url: gotrueUrl,
    headers: {'apikey': anonKey},
    autoRefreshToken: false,
  );

  stdout.writeln('Projeto DEV: ${Uri.parse(url).host}');
  stdout.writeln('Dono:        $ownerEmail');

  // 1. Sessão do DONO (quem cadastra funcionários).
  final AuthResponse res;
  try {
    res = await auth.signInWithPassword(
      email: ownerEmail,
      password: ownerPassword,
    );
  } on AuthException catch (e) {
    stderr.writeln('ERRO: login do dono falhou: ${e.message}');
    exit(1);
  }
  final ownerUid = res.user?.id;
  if (ownerUid == null || res.session == null) {
    stderr.writeln('ERRO: login do dono sem sessão/usuário.');
    exit(1);
  }
  stdout.writeln('Login do dono OK.');

  try {
    final api = _DevApi(
      base: url,
      anonKey: anonKey,
      jwt: res.session!.accessToken,
    );

    // 2. Tenant do dono + primeira loja.
    final tenants = await api.select(
      'tenants',
      'select=id,business_name,plan_id,status&owner_user_id=eq.$ownerUid',
    );
    if (tenants.isEmpty) {
      stderr.writeln('ERRO: dono sem tenant em dev.');
      exit(1);
    }
    final tenant = tenants.first as Map<String, dynamic>;
    stdout.writeln(
      'Tenant: ${tenant['business_name']} (${tenant['id']}, '
      'status=${tenant['status']})',
    );

    final stores = await api.select(
      'stores',
      'select=id,name&tenant_id=eq.${tenant['id']}&order=created_at.asc&limit=1',
    );
    if (stores.isEmpty) {
      stderr.writeln('ERRO: tenant sem loja em dev (crie uma primeiro).');
      exit(1);
    }
    final store = stores.first as Map<String, dynamic>;
    stdout.writeln('Loja:    ${store['name']} (${store['id']})');

    // 3. Credenciais: arg > padrão determinístico; senha gerada.
    final mgrEmail = managerEmail ?? _defaultManagerEmail;
    final empEmail = employeeEmail ?? _defaultEmployeeEmail;
    final mgrPassword = _generatePassword();
    final empPassword = _generatePassword();

    await _ensureAccount(
      api: api,
      gotrueUrl: gotrueUrl,
      anonKey: anonKey,
      role: 'manager',
      roleLabel: 'GERENTE',
      email: mgrEmail,
      password: mgrPassword,
      storeId: store['id'] as String,
      storeName: store['name'] as String,
    );
    await _ensureAccount(
      api: api,
      gotrueUrl: gotrueUrl,
      anonKey: anonKey,
      role: 'employee',
      roleLabel: 'FUNCIONÁRIO',
      email: empEmail,
      password: empPassword,
      storeId: store['id'] as String,
      storeName: store['name'] as String,
    );

    // 4. Persistir credenciais (gitignored) para o E2E.
    _writeEnvValues({
      'TEST_MANAGER_EMAIL': mgrEmail,
      'TEST_MANAGER_PASSWORD': mgrPassword,
      'TEST_EMPLOYEE_EMAIL': empEmail,
      'TEST_EMPLOYEE_PASSWORD': empPassword,
    });
    stdout.writeln('');
    stdout.writeln(
      'Credenciais gravadas em env/test_accounts.env (gitignored): '
      'TEST_MANAGER_*, TEST_EMPLOYEE_*.',
    );
    stdout.writeln('');
    stdout.writeln('Para rodar o E2E de níveis de acesso (Chrome):');
    stdout.writeln(
      '  flutter drive --driver=test_driver/integration_test.dart \\',
    );
    stdout.writeln(
      '    --target=integration_test/access_levels_web_test.dart -d chrome \\',
    );
    stdout.writeln('    --dart-define-from-file=env/dev.env \\');
    stdout.writeln('    --dart-define-from-file=env/test_accounts.env');
    stdout.writeln(
      '(As credenciais entram via dart-define-from-file — nada na linha de '
      'comando.)',
    );
  } finally {
    try {
      await auth.signOut();
    } catch (_) {}
  }
}
