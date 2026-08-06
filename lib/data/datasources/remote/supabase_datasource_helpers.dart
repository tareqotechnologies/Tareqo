// Helpers compartilhados dos datasources remotos (Supabase).

import 'package:supabase_flutter/supabase_flutter.dart';

/// Limites de leitura das listagens remotas (auditoria H2).
///
/// Tamanho da PÁGINA da paginação keyset ([fetchAllKeyset]): o app nunca
/// carrega mais de [pageSize] linhas por requisição (resposta enorme,
/// memória e latência) — o loop percorre todas as páginas pelo cursor
/// estável `id` em vez de um `.limit` único que truncava lojas com 10k+
/// linhas. Listagens administrativas (tenants/plan requests pendentes) são
/// naturalmente pequenas e usam o mesmo teto por segurança.
abstract final class SupabaseQueryLimits {
  /// Teto de linhas por requisição de listagem (página da paginação keyset).
  static const int pageSize = 1000;
}

/// Busca TODAS as linhas de uma listagem usando **paginação keyset** (H2):
/// lotes de [SupabaseQueryLimits.pageSize] ordenados pelo [cursorColumn]
/// (o `id`, única e estável), com `gt(id, último)` na página seguinte — em
/// vez de um único `.limit(1000)` que truncava lojas com 10k+ linhas.
///
/// [query] deve já conter os filtros fixos (ex.: `.eq('store_id', ...)`);
/// o cursor e o teto são aplicados aqui. Devolve as linhas em ordem de
/// [cursorColumn] — a ordenação de exibição final é feita pelos providers
/// (ou por um sort explícito no datasource, quando o contrato exige).
Future<List<Map<String, dynamic>>> fetchAllKeyset(
  PostgrestFilterBuilder<List<Map<String, dynamic>>> query, {
  String cursorColumn = 'id',
}) async {
  final all = <Map<String, dynamic>>[];
  String? cursor;
  while (true) {
    var page = query;
    if (cursor != null) {
      page = page.gt(cursorColumn, cursor);
    }
    final rows = await page
        .order(cursorColumn, ascending: true)
        .limit(SupabaseQueryLimits.pageSize);
    all.addAll(rows);
    if (rows.length < SupabaseQueryLimits.pageSize) break;
    cursor = rows.last[cursorColumn] as String;
  }
  return all;
}

/// Cliente Supabase — requer `SupabaseBootstrap.initialize()` no `main()`
/// (garantido pelo ServiceLocator: os datasources remotos só são registrados
/// quando [SupabaseConfig.isConfigured]).
SupabaseClient get supabaseClient => Supabase.instance.client;

/// UUID do usuário autenticado (o *tenant* do modelo multi-tenant).
///
/// Todo INSERT dos datasources remotos grava a coluna `user_id` com este
/// valor — e o RLS (`auth.uid() = user_id`) + o trigger do schema garantem o
/// isolamento mesmo que um cliente tente forjar o id.
///
/// Lança [StateError] se não houver sessão ativa (as telas de dados só são
/// acessíveis após o login, via [AuthGate], então isso é um caso extremo).
String requireCurrentUserId() {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    throw StateError(
      'Usuário não autenticado: os dados do Supabase exigem uma sessão ativa.',
    );
  }
  return userId;
}
