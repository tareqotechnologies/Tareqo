import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/store_employee.dart';
import '../../domain/repositories/i_employee_account_processor.dart';
import '../../domain/repositories/i_employee_account_service.dart';

/// Implementação [IEmployeeAccountProcessor] sobre o Supabase via RPC.
///
/// A RPC `create_employee_account` (`SECURITY DEFINER` no schema) cria a
/// conta com `auth.admin_create_user` (confirmação IMEDIATA — sem e-mail de
/// confirmação, nada de rate limit) E o vínculo em `store_employees` em UMA
/// transação: se o vínculo falhar (ex.: limite do plano atingido), a conta
/// é desfeita junto — sem contas órfãs. A sessão do dono nunca é tocada
/// (bug S1 do antigo `auth.signUp` eliminado).
final class SupabaseEmployeeProcessor implements IEmployeeAccountProcessor {
  /// [rpc] injetável para testes (padrão: cliente real do Supabase).
  const SupabaseEmployeeProcessor({
    Future<dynamic> Function(String fn, Map<String, dynamic> params)? rpc,
  }) : _rpcOverride = rpc;

  final Future<dynamic> Function(String fn, Map<String, dynamic> params)?
  _rpcOverride;

  Future<dynamic> _rpc(String fn, Map<String, dynamic> params) =>
      _rpcOverride != null
      ? _rpcOverride(fn, params)
      : Supabase.instance.client.rpc(fn, params: params);

  @override
  Future<String> create({
    required StoreEmployee employee,
    required String password,
  }) async {
    try {
      final result = await _rpc('create_employee_account', {
        'p_employee_id': employee.id,
        'p_email': employee.email,
        'p_password': password,
        'p_full_name': employee.fullName,
        'p_store_id': employee.storeId,
        'p_role': employee.role.name,
      });
      final userId = result is String ? result : null;
      if (userId == null || userId.isEmpty) {
        throw const EmployeeAccountCreationException(
          'Não foi possível criar a conta do funcionário.',
          code: 'generic',
        );
      }
      return userId;
    } on PostgrestException catch (error) {
      // O RPC rejeita com mensagens claras (e-mail duplicado, não-dono,
      // senha fraca, loja inválida) — traduzidas para (código, texto
      // amigável); a UI localiza pelo código, o texto fica como fallback.
      final (code, friendly) = _friendlyMessage(error.message);
      throw EmployeeAccountCreationException(friendly, code: code);
    }
  }

  /// Traduz as mensagens do RPC (exceções do Postgres) para um par
  /// (código estável, texto amigável PT como fallback).
  static (String, String) _friendlyMessage(String serverMessage) {
    if (serverMessage.contains('Já existe uma conta')) {
      return (
        'emailInUse',
        'Já existe uma conta com este e-mail. Use outro e-mail ou peça '
            'ao funcionário para entrar com a conta dele.',
      );
    }
    if (serverMessage.contains('Apenas o dono')) {
      return (
        'ownerOnly',
        'Apenas o dono do tenant pode cadastrar funcionários.',
      );
    }
    if (serverMessage.contains('pelo menos 8 caracteres')) {
      return ('weakPassword', 'A senha deve ter pelo menos 8 caracteres.');
    }
    if (serverMessage.contains('Escolha uma loja')) {
      return ('noStore', 'Escolha uma loja do seu tenant.');
    }
    return (
      'generic',
      'Não foi possível criar a conta do funcionário. Tente novamente.',
    );
  }
}
