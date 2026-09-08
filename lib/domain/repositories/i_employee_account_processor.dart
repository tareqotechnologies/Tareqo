import '../entities/store_employee.dart';

/// Processador **atômico** de cadastro de funcionário (conta + vínculo).
///
/// Implementado apenas quando a plataforma de persistência oferece
/// transação multi-tabela no servidor — hoje, o Supabase via RPC
/// (`create_employee_account`, `SECURITY DEFINER`): a conta de acesso E o
/// vínculo em `store_employees` são criados em UMA transação. Se o vínculo
/// falhar (ex.: limite de funcionários do plano — trigger
/// `enforce_employee_limit`), a conta nem chega a existir (sem contas
/// órfãs). No SQLite/memória o [AddEmployeeUseCase] usa o caminho composto
/// (conta sintética + repositório) e este contrato fica sem implementação
/// registrada.
abstract interface class IEmployeeAccountProcessor {
  /// Cria a conta de acesso e o vínculo na loja; retorna o id do usuário.
  ///
  /// Lança [EmployeeAccountCreationException] com mensagem amigável quando
  /// a criação falha (e-mail em uso, senha fraca, loja inválida...).
  Future<String> create({
    required StoreEmployee employee,
    required String password,
  });
}
