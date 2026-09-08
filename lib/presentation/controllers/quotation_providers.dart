import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/quotation.dart';
import '../../domain/repositories/i_quotation_repository.dart';

/// Ponte entre o ServiceLocator (GetIt) e o Riverpod — substituível em
/// testes via `overrideWithValue`.
final quotationRepositoryProvider = Provider<IQuotationRepository>(
  (ref) => ServiceLocator.instance<IQuotationRepository>(),
);

/// Cotações da loja [storeId] persistidas, da mais recente para a mais
/// antiga. Re-buscar ao voltar à tela; invalidar após criar/atualizar.
final quotationsProvider = FutureProvider.autoDispose
    .family<List<Quotation>, String>(
      (ref, storeId) =>
          ref.watch(quotationRepositoryProvider).getByStore(storeId),
    );
