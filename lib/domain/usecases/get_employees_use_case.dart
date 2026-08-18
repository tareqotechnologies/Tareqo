import '../entities/store_employee.dart';
import '../repositories/i_employee_repository.dart';

/// Caso de uso: listar os funcionários de um tenant.
class GetEmployeesUseCase {
 const GetEmployeesUseCase(this._repository);

 final IEmployeeRepository _repository;

 Future<List<StoreEmployee>> call(String tenantId) =>
 _repository.getByTenant(tenantId);
}
