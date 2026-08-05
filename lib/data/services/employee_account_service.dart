/// Contrato de criação de contas de funcionário.
///
/// O dono cadastra o funcionário (nome + e-mail + senha) e escolhe a loja
/// e o cargo; o funcionário só faz login depois. A criação da conta de
/// acesso (auth) é responsabilidade deste serviço — o resultado é o id do
/// usuário criado, usado no vínculo [StoreEmployee].
abstract interface class EmployeeAccountService {
  /// Cria a conta de acesso e retorna o id do usuário criado.
  Future<String> createAccount({
    required String email,
    required String password,
    required String fullName,
  });
}
