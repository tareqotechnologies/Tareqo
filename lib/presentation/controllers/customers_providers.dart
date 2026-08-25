import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/add_customer_use_case.dart';
import '../../domain/usecases/delete_customer_use_case.dart';
import '../../domain/usecases/get_customers_use_case.dart';
import '../../domain/usecases/update_customer_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Ponte com o ServiceLocator (GetIt): expõe os casos de uso como providers,
/// permitindo substituí-los facilmente em testes.
final getCustomersUseCaseProvider = Provider<GetCustomersUseCase>(
 (ref) => ServiceLocator.instance<GetCustomersUseCase>(),
);

final addCustomerUseCaseProvider = Provider<AddCustomerUseCase>(
 (ref) => ServiceLocator.instance<AddCustomerUseCase>(),
);

final updateCustomerUseCaseProvider = Provider<UpdateCustomerUseCase>(
 (ref) => ServiceLocator.instance<UpdateCustomerUseCase>(),
);

final deleteCustomerUseCaseProvider = Provider<DeleteCustomerUseCase>(
 (ref) => ServiceLocator.instance<DeleteCustomerUseCase>(),
);

/// Estado da lista de clientes (ordenada por nome).
final customersProvider =
 AsyncNotifierProvider<CustomersNotifier, List<Customer>>(
 CustomersNotifier.new,
);

class CustomersNotifier extends AsyncNotifier<List<Customer>> {
 @override
 Future<List<Customer>> build() async {
 final user = ref.watch(authStateProvider).value;
 final storeId = user == null ? null : ref.watch(activeStoreIdProvider(user.id));
 if (storeId == null) return const [];
 final customers = [
 ...await ref.read(getCustomersUseCaseProvider).call(storeId: storeId),
 ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
 return customers;
 }

 /// Recarrega a lista de clientes (ex.: após cadastrar um cliente).
 Future<void> refresh() async {
 ref.invalidateSelf();
 await future;
 }
}
