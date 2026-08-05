import '../entities/plan.dart';
import '../entities/store_employee.dart';
import '../entities/tenant.dart';
import '../repositories/i_employee_repository.dart';
import '../repositories/i_plan_repository.dart';
import '../repositories/i_store_repository.dart';
import '../repositories/i_tenant_repository.dart';
import 'add_store_use_case.dart' show PlanLimitExceededException, TenantNotApprovedException;

/// Exceção de domínio: funcionário inválido (dados de entrada).
final class InvalidEmployeeException implements Exception {
  const InvalidEmployeeException(this.message);

  final String message;

  @override
  String toString() => 'InvalidEmployeeException: $message';
}

/// Caso de uso: vincular um funcionário a uma loja do tenant (dono).
///
/// Aplica o limite de funcionários do [Plan]: se o total do tenant já
/// atingiu `maxEmployees`, lança [PlanLimitExceededException].
///
/// O dono informa nome, e-mail e a loja; a criação da conta de acesso do
/// funcionário fica a cargo da UI (que usa o cadastro do Supabase com o
/// e-mail/senha definidos pelo dono — Fase 1).
class AddEmployeeUseCase {
  const AddEmployeeUseCase(
    this._employeeRepository,
    this._tenantRepository,
    this._planRepository,
    this._storeRepository,
  );

  final IEmployeeRepository _employeeRepository;
  final ITenantRepository _tenantRepository;
  final IPlanRepository _planRepository;
  final IStoreRepository _storeRepository;

  Future<void> call(StoreEmployee employee) async {
    if (employee.fullName.trim().isEmpty || employee.email.trim().isEmpty) {
      throw const InvalidEmployeeException(
        'Informe nome e e-mail do funcionário.',
      );
    }

    final tenant = await _tenantRepository.getById(employee.tenantId);
    if (tenant == null || tenant.status != TenantStatus.approved) {
      throw const TenantNotApprovedException(
        'Seu acesso ao ERP ainda não foi aprovado.',
      );
    }

    // A loja precisa pertencer ao tenant do funcionário.
    final stores = await _storeRepository.getByTenant(tenant.id);
    if (!stores.any((store) => store.id == employee.storeId)) {
      throw const InvalidEmployeeException(
        'Escolha uma loja do seu tenant.',
      );
    }

    final plan = await _planRepository.getById(tenant.planId);
    final employees = await _employeeRepository.getByTenant(tenant.id);
    if (plan != null && employees.length >= plan.maxEmployees) {
      throw PlanLimitExceededException(
        'O plano ${plan.name} permite até ${plan.maxEmployees} '
        '${plan.maxEmployees == 1 ? 'funcionário' : 'funcionários'}. '
        'Solicite um upgrade de plano para contratar mais.',
      );
    }

    await _employeeRepository.add(employee);
  }
}
