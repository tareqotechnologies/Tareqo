// Backfill one-off do tipo estrutural do produto (`products.type`, Fase 1).
//
// A coluna nasceu com DEFAULT 'resale' e a migração NUNCA reclassifica nada
// sozinha. Esta ferramenta aplica o passo OPCIONAL do runbook 24 (Passo 6.4):
// lê os produtos da loja, classifica o NOME com
// `lib/domain/services/product_type_classifier.dart` e mostra o plano.
//
// Segurança por design:
//  - DRY-RUN por padrão: nada é gravado sem `--apply` explícito.
//  - Só reclassifica produtos ainda em `resale` (o default legado); quem já
//    tem tipo não-revenda foi reclassificado de propósito e NÃO é tocado
//    (use `--include-classified` para reaplicar as regras a todos).
//  - `--prod` mira o PROJETO DE PRODUÇÃO (env/prod.env + PROD_OWNER_*);
//    sem a flag, roda em DEV (env/dev.env + TEST_OWNER_*).
//  - Usa a SESSÃO DO DONO (RLS vigia): nada de service_role.
//  - Nunca imprime segredos.
//
// Uso:
//   dart run tool/backfill_product_types.dart                       # dry-run DEV
//   dart run tool/backfill_product_types.dart --store <id>          # 1 loja
//   dart run tool/backfill_product_types.dart --apply               # grava em DEV
//   dart run tool/backfill_product_types.dart --prod                # dry-run PROD
//   dart run tool/backfill_product_types.dart --prod --apply        # grava em PROD
//   dart run tool/backfill_product_types.dart --include-classified  # reaplica a todos

import 'dart:convert';
import 'dart:io';

import 'package:gotrue/gotrue.dart';
import 'package:http/http.dart' as http;

import 'package:tareqo/domain/entities/product.dart';
import 'package:tareqo/domain/services/product_type_classifier.dart';

const _usage =
    'Uso: dart run tool/backfill_product_types.dart '
    '[--apply] [--prod] [--include-classified] [--store <id>]';

Future<void> main(List<String> args) async {
  var apply = false;
  var useProd = false;
  var includeClassified = false;
  String? storeId;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--apply':
        apply = true;
      case '--prod':
        useProd = true;
      case '--include-classified':
        includeClassified = true;
      case '--store':
        storeId = args[++i];
      case '--help':
      case '-h':
        stdout.writeln(_usage);
        return;
      default:
        stderr.writeln('Arg desconhecido: ${args[i]}\n$_usage');
        exit(2);
    }
  }

  final envFile = useProd ? 'env/prod.env' : 'env/dev.env';
  final accountsFile = useProd ? 'env/prod.env' : 'env/test_accounts.env';
  final ownerEmailKey = useProd ? 'PROD_OWNER_EMAIL' : 'TEST_OWNER_EMAIL';
  final ownerPasswordKey = useProd
      ? 'PROD_OWNER_PASSWORD'
      : 'TEST_OWNER_PASSWORD';

  final url = _readValue(envFile, 'SUPABASE_URL');
  final anonKey = _readValue(envFile, 'SUPABASE_ANON_KEY');
  final ownerEmail = _readValue(accountsFile, ownerEmailKey);
  final ownerPassword = _readValue(accountsFile, ownerPasswordKey);

  stdout.writeln(
    'Projeto: ${useProd ? 'PRODUÇÃO' : 'DEV'} (${Uri.parse(url).host})',
  );
  stdout.writeln('Dono:    $ownerEmail');
  stdout.writeln(
    apply
        ? 'Modo:    APPLY (grava as reclassificações)'
        : 'Modo:    DRY-RUN (só mostra o plano — use --apply para gravar)',
  );

  final gotrueUrl = '${url.replaceAll(RegExp(r'/+$'), '')}/auth/v1';
  final auth = GoTrueClient(
    url: gotrueUrl,
    headers: {'apikey': anonKey},
    autoRefreshToken: false,
  );

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
  if (res.session == null) {
    stderr.writeln('ERRO: login do dono sem sessão.');
    exit(1);
  }

  try {
    final api = _Api(
      base: url,
      anonKey: anonKey,
      jwt: res.session!.accessToken,
    );

    final query = StringBuffer('select=id,name,type&order=name.asc');
    if (storeId != null) query.write('&store_id=eq.$storeId');
    final rows = await api.select('products', query.toString());

    final candidates = rows.map((row) {
      final map = row as Map<String, dynamic>;
      return ProductTypeCandidate(
        id: map['id'] as String,
        name: (map['name'] ?? '') as String,
        currentType: _parseType(map['type']),
      );
    }).toList();

    final plan = planProductTypeBackfill(
      candidates,
      onlyResale: !includeClassified,
    );

    stdout.writeln('');
    stdout.writeln(
      'Produtos lidos: ${candidates.length} | reclassificações propostas: '
      '${plan.length}',
    );
    for (final entry in plan) {
      stdout.writeln(
        '  ${entry.name}  ${entry.from.name} -> ${entry.to.name}  '
        '(regra: ${entry.reason})',
      );
    }

    if (plan.isEmpty) {
      stdout.writeln('Nada a reclassificar.');
      return;
    }

    if (!apply) {
      stdout.writeln('');
      stdout.writeln(
        'Dry-run: nenhuma alteração gravada. Reexecute com --apply para '
        'aplicar (recomendado após revisar a lista).',
      );
      return;
    }

    var updated = 0;
    for (final entry in plan) {
      await api.patch('products', 'id=eq.${entry.id}', <String, dynamic>{
        'type': entry.to.name,
      });
      updated++;
    }
    stdout.writeln('');
    stdout.writeln(
      'Aplicado: $updated produto(s) reclassificado(s) '
      'em ${Uri.parse(url).host}.',
    );
  } finally {
    try {
      await auth.signOut();
    } catch (_) {}
  }
}

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

/// Mapeia a coluna `type` para o enum, tolerando ausente/desconhecido — mesma
/// tolerância dos datasources (cai em [ProductType.resale], nunca lança).
ProductType _parseType(Object? raw) {
  final name = raw?.toString();
  if (name == null) return ProductType.resale;
  for (final type in ProductType.values) {
    if (type.name == name) return type;
  }
  return ProductType.resale;
}

// ─── REST helpers (sessão do dono; RLS vigia) ───────────────────────────────

class _Api {
  _Api({required this.base, required this.anonKey, required this.jwt});

  final String base;
  final String anonKey;
  final String jwt;

  Map<String, String> get _headers => {
    'apikey': anonKey,
    'Authorization': 'Bearer $jwt',
    'Content-Type': 'application/json',
  };

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

  Future<void> patch(
    String table,
    String filter,
    Map<String, dynamic> body,
  ) async {
    final res = await http.patch(
      Uri.parse('$base/rest/v1/$table?$filter'),
      headers: {..._headers, 'Prefer': 'return=minimal'},
      body: jsonEncode(body),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      stderr.writeln(
        'ERRO PATCH $table?$filter: ${res.statusCode} ${res.body}',
      );
      exit(1);
    }
  }
}
