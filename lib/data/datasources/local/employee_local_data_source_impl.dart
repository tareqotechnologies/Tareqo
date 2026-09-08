import '../../../domain/entities/store_employee.dart';
import 'employee_local_data_source.dart';

/// Implementação em memória do [EmployeeLocalDataSource].
final class EmployeeLocalDataSourceImpl implements EmployeeLocalDataSource {
  EmployeeLocalDataSourceImpl({List<StoreEmployee> seed = const []})
    : _employees = [...seed];

  final List<StoreEmployee> _employees;

  @override
  Future<List<StoreEmployee>> getByTenant(String tenantId) async =>
      List.unmodifiable(_employees.where((e) => e.tenantId == tenantId));

  @override
  Future<List<StoreEmployee>> getByStore(String storeId) async =>
      List.unmodifiable(_employees.where((e) => e.storeId == storeId));

  @override
  Future<void> add(StoreEmployee employee) async {
    _employees.add(employee);
  }

  @override
  Future<void> setActive({
    required String employeeId,
    required bool isActive,
  }) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index < 0) return;
    _employees[index] = _employees[index].copyWith(isActive: isActive);
  }
}
