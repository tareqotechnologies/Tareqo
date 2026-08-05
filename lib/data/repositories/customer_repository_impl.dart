import '../../domain/entities/customer.dart';
import '../../domain/repositories/i_customer_repository.dart';
import '../datasources/local/customer_local_data_source.dart';

/// Implementação de [ICustomerRepository] sobre um [CustomerLocalDataSource].
///
/// O repositório **não sabe** se os dados vêm da memória, do SQLite ou do
/// Supabase: apenas delega para o datasource injetado.
final class CustomerRepositoryImpl implements ICustomerRepository {
  const CustomerRepositoryImpl(this._localDataSource);

  final CustomerLocalDataSource _localDataSource;

  @override
  Future<List<Customer>> getAll({required String storeId}) =>
      _localDataSource.getAll(storeId: storeId);

  @override
  Future<void> add(Customer customer) => _localDataSource.add(customer);
}
