import '../../core/utils/ids.dart';
import '../../domain/repositories/i_employee_account_service.dart';

/// Implementação local (dev sem Supabase) do [EmployeeAccountService].
///
/// Gera um id sintético — o vínculo do funcionário existe apenas na
/// memória do app de demonstração.
final class LocalEmployeeAccountService implements EmployeeAccountService {
  const LocalEmployeeAccountService();

  @override
  Future<String> createAccount({
    required String email,
    required String password,
    required String fullName,
  }) async =>
      AppIds.newId('emp');
}
