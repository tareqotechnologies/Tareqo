import '../entities/plan.dart';
import '../entities/store_employee.dart';
import '../entities/tenant.dart';
import '../repositories/i_employee_account_processor.dart';
import '../repositories/i_employee_account_service.dart';
import '../repositories/i_employee_repository.dart';
import '../repositories/i_plan_repository.dart';
import '../repositories/i_store_repository.dart';
import '../repositories/i_tenant_repository.dart';
import 'add_store_use_case.dart'
    show PlanLimitExceededException, TenantNotApprovedException;

/// Exceção de domínio: funcionário inválido (dados de entrada).
///
/// [code] identifica a variante de validação (estável, para a UI localizar
/// a mensagem); [message] permanece como fallback/legado (PT).
final class InvalidEmployeeException implements Exception {
  const InvalidEmployeeException(this.message, {this.code = ''});

  final String message;

  /// Variante: emptyNameOrEmail | noStore.
  final String code;

  @override
  String toString() => 'InvalidEmployeeException: $message';
}

/// Caso de uso: vincular um funcionário a uma loja do tenant (dono).
///
/// Valida os dados de entrada, a aprovação do tenant, a loja e o limite de
/// funcionários do [Plan] (mensagens amigáveis na UI; o banco também
/// valida no servidor).
///
/// A criação da conta de acesso fica a cargo do [IEmployeeAccountProcessor]
/// no modo Supabase — conta + vínculo em UMA transação (sem contas órfãs
/// se o limite for atingido) — ou do caminho composto no modo local
/// (conta sintética via [EmployeeAccountService] + repositório).
class AddEmployeeUseCase {
  const AddEmployeeUseCase(
    this._employeeRepository,
    this._tenantRepository,
    this._planRepository,
    this._storeRepository, {
    this._accountService,
    this._processor,
  });

  final IEmployeeRepository _employeeRepository;
  final ITenantRepository _tenantRepository;
  final IPlanRepository _planRepository;
  final IStoreRepository _storeRepository;

  /// Criação de conta LOCAL (dev sem Supabase) — id sintético. No modo
  /// Supabase é `null` (a conta é criada pelo [_processor], com vínculo).
  final EmployeeAccountService? _accountService;

  /// Processador atômico do modo Supabase (conta + vínculo numa transação);
  /// `null` nos modos SQLite/memória.
  final IEmployeeAccountProcessor? _processor;

  Future<void> call(StoreEmployee employee, {required String password}) async {
    if (employee.fullName.trim().isEmpty || employee.email.trim().isEmpty) {
      throw const InvalidEmployeeException(
        'Informe nome e e-mail do funcionário.',
        code: 'emptyNameOrEmail',
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
        code: 'noStore',
      );
    }

    final plan = await _planRepository.getById(tenant.planId);
    final employees = await _employeeRepository.getByTenant(tenant.id);
    if (plan != null && employees.length >= plan.maxEmployees) {
      throw PlanLimitExceededException(
        'O plano ${plan.name} permite até ${plan.maxEmployees} '
        '${plan.maxEmployees == 1 ? 'funcionário' : 'funcionários'}. '
        'Solicite um upgrade de plano para contratar mais.',
        planName: plan.name,
        limit: plan.maxEmployees,
        forEmployees: true,
      );
    }

    // Supabase: conta + vínculo em UMA transação (RPC
    // create_employee_account). O banco revalida o limite e a loja.
    final processor = _processor;
    if (processor != null) {
      await processor.create(employee: employee, password: password);
      return;
    }

    // Local: conta sintética + vínculo via repositório.
    final accountService = _accountService;
    if (accountService == null) {
      throw StateError('EmployeeAccountService não registrado no modo local.');
    }
    final userId = await accountService.createAccount(
      email: employee.email,
      password: password,
      fullName: employee.fullName,
    );
    await _employeeRepository.add(employee.copyWith(userId: userId));
  }
}
