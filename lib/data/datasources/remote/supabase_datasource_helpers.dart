// Helpers compartilhados dos datasources remotos (Supabase).

import 'package:supabase_flutter/supabase_flutter.dart';

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
