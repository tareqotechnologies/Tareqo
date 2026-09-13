import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:tareqo/presentation/controllers/invoice_providers.dart';

/// Contrato dos providers de FACTURAS (painel admin) sem backend:
/// os AsyncNotifier de listagem leem use cases do ServiceLocator. Com o
/// GetIt VAZIO (teste), o acesso ao provider falha — o contrato observável
/// é que o erro é DETERMINÍSTICO e EXPLÍCITO (a exceção do GetIt nomeia o
/// use case exato que o provider consome), nunca uma lista fantasma vazia
/// que mascararia um problema de configuração.
void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  test(
    'pendingInvoicesProvider consome GetPendingInvoicesUseCase do ServiceLocator',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(pendingInvoicesProvider.future),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('GetPendingInvoicesUseCase is not registered'),
          ),
        ),
      );
    },
  );

  test(
    'allInvoicesProvider e tenantInvoicesProvider amarram aos use cases certos',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(allInvoicesProvider.future),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('GetAllInvoicesUseCase is not registered'),
          ),
        ),
      );
      await expectLater(
        container.read(tenantInvoicesProvider('tn-1').future),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('GetTenantInvoicesUseCase is not registered'),
          ),
        ),
      );
    },
  );
}
