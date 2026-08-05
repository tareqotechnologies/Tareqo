// Helpers compartilhados dos datasources remotos (Supabase).

import 'package:supabase_flutter/supabase_flutter.dart';

/// Limites de leitura das listagens remotas (auditoria H2).
///
/// Paginação de UI (scroll infinito) está fora do escopo atual — até lá,
/// toda listagem é **capada explicitamente** no servidor: o PostgREST já
/// limita por padrão a 1000 linhas, mas deixar o limite explícito garante
/// que o app nunca carregue um dataset inteiro numa só requisição (resposta
/// enorme, memória e latência) nem dependa do default do servidor. Listagens
/// administrativas (tenants/plan requests pendentes) são naturalmente
/// pequenas e usam o mesmo teto por segurança.
abstract final class SupabaseQueryLimits {
  /// Teto de linhas por requisição de listagem.
  static const int pageSize = 1000;
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
