/// Exceção: falha ao criar a conta de acesso do funcionário.
///
/// Carrega uma mensagem amigável (ex.: e-mail já em uso, senha fraca,
/// usuário sem permissão) para exibição direta no formulário — em vez do
/// erro genérico do `catch` da tela.
final class EmployeeAccountCreationException implements Exception {
 const EmployeeAccountCreationException(this.message);

 final String message;

 @override
 String toString() => 'EmployeeAccountCreationException: $message';
}

/// Criação de contas de acesso de funcionário — modo LOCAL (dev sem
/// Supabase), onde o vínculo na loja é criado pelo caso de uso via
/// repositório com um id sintético.
///
/// No modo Supabase quem cria a conta E o vínculo é o processador atômico
/// [IEmployeeAccountProcessor] (RPC `create_employee_account` — conta +
/// vínculo em UMA transação); neste modo este serviço não é registrado.
abstract interface class EmployeeAccountService {
 /// Cria a conta de acesso e retorna o id do usuário criado.
 ///
 /// Lança [EmployeeAccountCreationException] com mensagem amigável quando
 /// a criação falha (e-mail já em uso, senha fraca, sem permissão...).
 Future<String> createAccount({
 required String email,
 required String password,
 required String fullName,
 });
}
