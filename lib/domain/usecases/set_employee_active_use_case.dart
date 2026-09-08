import '../entities/store_employee.dart';
import '../repositories/i_employee_repository.dart';

/// Exceção de domínio: funcionário não encontrado ao mudar o status.
final class EmployeeNotFoundException implements Exception {
  const EmployeeNotFoundException(this.message);

  final String message;

  @override
  String toString() => 'EmployeeNotFoundException: $message';
}

/// Caso de uso: ativar/desativar um funcionário do tenant (dono).
///
/// Apenas muda o status do vínculo em `store_employees` ([StoreEmployee.isActive]).
/// O bloqueio em si é duplo: o **app** mostra a tela de acesso suspenso no
/// AuthGate, e o **servidor** (RLS + guardas `is_my_store`/`is_manager_of_store`,
/// que exigem vínculo ativo) nega qualquer operação nas lojas — mesmo um
/// cliente modificado não consegue agir em nome de um funcionário suspenso.
class SetEmployeeActiveUseCase {
  const SetEmployeeActiveUseCase(this._employeeRepository);

  final IEmployeeRepository _employeeRepository;

  Future<void> call({
    required String tenantId,
    required String employeeId,
    required bool isActive,
  }) async {
    final employees = await _employeeRepository.getByTenant(tenantId);
    final employee = employees.where((e) => e.id == employeeId).firstOrNull;
    if (employee == null) {
      throw const EmployeeNotFoundException(
        'Funcionário não encontrado. Atualize a lista e tente novamente.',
      );
    }
    if (employee.isActive == isActive) return;
    await _employeeRepository.setActive(
      employeeId: employeeId,
      isActive: isActive,
    );
  }
}
