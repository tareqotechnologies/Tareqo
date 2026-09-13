import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/domain/repositories/i_employee_account_service.dart';

/// A exceção carrega mensagem amigável para exibição direta no formulário
/// (o `toString` inclui o tipo — visível em logs de erro).
void main() {
  test('toString inclui o tipo e a mensagem amigável', () {
    const exception = EmployeeAccountCreationException('E-mail já em uso');

    expect(exception.message, 'E-mail já em uso');
    expect(
      exception.toString(),
      'EmployeeAccountCreationException: E-mail já em uso',
    );
  });
}
