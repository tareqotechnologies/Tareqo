import '../entities/store_employee.dart';

/// Contrato de acesso a funcionários de lojas (camada de domínio).
abstract interface class IEmployeeRepository {
  /// Funcionários de um tenant.
  Future<List<StoreEmployee>> getByTenant(String tenantId);

  /// Funcionários de uma loja específica.
  Future<List<StoreEmployee>> getByStore(String storeId);

  /// Vincula um funcionário a uma loja do tenant.
  Future<void> add(StoreEmployee employee);

  /// Ativa/desativa um funcionário do tenant (dono).
  Future<void> setActive({
    required String employeeId,
    required bool isActive,
  });
}
