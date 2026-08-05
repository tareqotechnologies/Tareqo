import 'package:supabase_flutter/supabase_flutter.dart';

import 'employee_account_service.dart';

/// Implementação [EmployeeAccountService] sobre o Supabase (gotrue).
///
/// Usa `auth.signUp` para criar a conta com o e-mail/senha definidos pelo
/// dono. Se a confirmação de e-mail estiver ativa no projeto, o funcionário
/// recebe um e-mail para confirmar antes do primeiro login (a conta já é
/// criada e o vínculo na loja funciona imediatamente).
final class SupabaseEmployeeAccountService implements EmployeeAccountService {
  const SupabaseEmployeeAccountService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  Future<String> createAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Não foi possível criar a conta do funcionário.');
    }
    return user.id;
  }
}
