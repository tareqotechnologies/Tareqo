import '../../../domain/entities/store_employee.dart';

/// Contrato de armazenamento de funcionários (camada de dados).
abstract interface class EmployeeLocalDataSource {
 /// Funcionários de um tenant.
 Future<List<StoreEmployee>> getByTenant(String tenantId);

 /// Funcionários de uma loja.
 Future<List<StoreEmployee>> getByStore(String storeId);

 /// Vincula um funcionário a uma loja.
 Future<void> add(StoreEmployee employee);

 /// Ativa/desativa um funcionário do tenant (dono).
 Future<void> setActive({
 required String employeeId,
 required bool isActive,
 });
}
