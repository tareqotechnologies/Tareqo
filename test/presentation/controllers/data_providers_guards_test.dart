import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:tareqo/presentation/controllers/customers_providers.dart';
import 'package:tareqo/presentation/controllers/debts_providers.dart';
import 'package:tareqo/presentation/controllers/products_providers.dart';
import 'package:tareqo/presentation/controllers/sales_providers.dart';

/// Contratos de GUARDA dos providers de dados (produtos, clientes,
/// dívidas, vendas): sem usuário logado, os notifiers devolvem estado
/// VAZIO sem tocar no ServiceLocator — o mesmo padrão validado para
/// finanças em finance_providers_test.dart. Com sessão, o caminho feliz
/// é exercitado pelos testes de tela (que sobrescrevem os use cases).
///
/// O branch de erro do GetIt (provider lido sem DI) é validado apenas no
/// invoice_providers_test.dart — o padrão é idêntico em todos.
void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  group('guarda sem sessão — estados vazios determinísticos', () {
    test('customersProvider: lista vazia sem usuário logado', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(customersProvider.future), isEmpty);
    });

    test('productsProvider: lista vazia sem usuário logado', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(productsProvider.future), isEmpty);
    });

    test('salesProvider: lista vazia sem usuário logado', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(salesListProvider.future), isEmpty);
    });

    test('pendingDebtsProvider: lista vazia sem usuário logado', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(await container.read(pendingDebtsProvider.future), isEmpty);
    });
  });
}
