import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:tareqo/core/config/supabase_config.dart';
import 'package:tareqo/core/di/service_locator.dart';
import 'package:tareqo/data/datasources/local/pending_op_queue.dart';
import 'package:tareqo/data/datasources/local/product_local_data_source.dart';
import 'package:tareqo/data/datasources/remote/supabase_product_data_source.dart';
import 'package:tareqo/data/services/offline_sync_service.dart';
import 'package:tareqo/domain/repositories/i_auth_repository.dart';
import 'package:tareqo/domain/repositories/i_product_repository.dart';
import 'package:tareqo/domain/usecases/add_customer_use_case.dart';
import 'package:tareqo/domain/usecases/process_sale_use_case.dart';
import 'package:tareqo/domain/usecases/get_products_use_case.dart';

void main() {
  // Inicializa o binding para o path_provider ter canal (a falha de
  // plataforma cai no fallback de memória SEM stack trace ruidoso).
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => GetIt.instance.reset());

  test('initialize registra o grafo completo e resolve sem erro', () async {
    await ServiceLocator.initialize();

    final getIt = ServiceLocator.instance;

    // Camadas críticas do grafo registradas.
    expect(getIt.isRegistered<IAuthRepository>(), isTrue);
    expect(getIt.isRegistered<IProductRepository>(), isTrue);
    expect(getIt.isRegistered<GetProductsUseCase>(), isTrue);
    expect(getIt.isRegistered<ProcessSaleUseCase>(), isTrue);
    expect(getIt.isRegistered<AddCustomerUseCase>(), isTrue);
    expect(getIt.isRegistered<OfflineSyncService>(), isTrue);
    expect(getIt.isRegistered<IPendingOpQueue>(), isTrue);

    // Resolver NÃO deve lançar (o grafo está íntegro) — sem chamar rede.
    expect(getIt<IAuthRepository>(), isNotNull);
    expect(getIt<IProductRepository>(), isNotNull);
    expect(getIt<ProcessSaleUseCase>(), isA<ProcessSaleUseCase>());
    expect(getIt<OfflineSyncService>(), isA<OfflineSyncService>());
    expect(getIt<IPendingOpQueue>(), isA<IPendingOpQueue>());
  });

  test('sem SQLite (teste) a fila offline cai para memória', () async {
    await ServiceLocator.initialize();

    final queue = ServiceLocator.instance<IPendingOpQueue>();
    // Em testes não há path_provider/SQLite → fila em memória (a mesma
    // usada pela web) — nunca null.
    expect(queue, isA<IPendingOpQueue>());
    await queue.add(
      PendingOp(
        opType: 'process_sale',
        payload: const {
          'sale': {'id': 's1'},
        },
        createdAt: DateTime(2026, 8, 16),
      ),
    );
    expect(await queue.count(), 1);
  });

  test(
    'com Supabase configurado (defaults), datasource de produto é o remoto',
    () async {
      // Nos testes o SupabaseConfig usa os defaults embutidos (isConfigured
      // true) → o grafo registra os datasources REMOTOS.
      expect(SupabaseConfig.isConfigured, isTrue);

      await ServiceLocator.initialize();

      final productDs = ServiceLocator.instance<ProductLocalDataSource>();
      expect(productDs, isA<ProductSupabaseDataSourceImpl>());
    },
  );
}
