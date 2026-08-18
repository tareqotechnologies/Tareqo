import '../../domain/entities/store_employee.dart';
import '../../domain/repositories/i_employee_repository.dart';
import '../datasources/local/employee_local_data_source.dart';

/// Implementação de [IEmployeeRepository] sobre um [EmployeeLocalDataSource].
final class EmployeeRepositoryImpl implements IEmployeeRepository {
 const EmployeeRepositoryImpl(this._localDataSource);

 final EmployeeLocalDataSource _localDataSource;

 @override
 Future<List<StoreEmployee>> getByTenant(String tenantId) =>
 _localDataSource.getByTenant(tenantId);

 @override
 Future<List<StoreEmployee>> getByStore(String storeId) =>
 _localDataSource.getByStore(storeId);

 @override
 Future<void> add(StoreEmployee employee) =>
 _localDataSource.add(employee);

 @override
 Future<void> setActive({
 required String employeeId,
 required bool isActive,
 }) =>
 _localDataSource.setActive(employeeId: employeeId, isActive: isActive);
}
