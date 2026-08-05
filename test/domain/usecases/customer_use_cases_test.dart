import 'package:flutter_test/flutter_test.dart';

import 'package:dumbhanengue/domain/entities/customer.dart';
import 'package:dumbhanengue/domain/repositories/i_customer_repository.dart';
import 'package:dumbhanengue/domain/usecases/add_customer_use_case.dart';
import 'package:dumbhanengue/domain/usecases/get_customers_use_case.dart';

/// Fake em memória do [ICustomerRepository].
class _FakeCustomerRepository implements ICustomerRepository {
  final List<Customer> _customers = [];
  bool addCalled = false;

  @override
  Future<List<Customer>> getAll({required String storeId}) async =>
      List.unmodifiable(_customers);

  @override
  Future<void> add(Customer customer) async {
    addCalled = true;
    _customers.add(customer);
  }
}

void main() {
  group('AddCustomerUseCase', () {
    test('cadastra o cliente quando o nome não é vazio', () async {
      final repository = _FakeCustomerRepository();
      final useCase = AddCustomerUseCase(repository);

      await useCase(
        const Customer(id: 'c1', name: 'Maria', phone: '(11) 99999-0000'),
      );

      expect(repository.addCalled, isTrue);
      expect(
        repository.getAll(storeId: 'st1'),
        completion(hasLength(1)),
      );
      expect(
        (await repository.getAll(storeId: 'st1')).first.email,
        isEmpty,
      );
    });

    test('lança InvalidCustomerException quando o nome é vazio', () async {
      final repository = _FakeCustomerRepository();
      final useCase = AddCustomerUseCase(repository);

      await expectLater(
        useCase(const Customer(id: 'c1', name: '   ')),
        throwsA(isA<InvalidCustomerException>()),
      );

      expect(repository.addCalled, isFalse);
    });
  });

  group('GetCustomersUseCase', () {
    test('retorna a lista de clientes do repositório', () async {
      final repository = _FakeCustomerRepository();
      await repository.add(const Customer(id: 'c1', name: 'João'));

      final result =
          await GetCustomersUseCase(repository)(storeId: 'st1');

      expect(result, hasLength(1));
      expect(result.first.name, 'João');
    });
  });
}
