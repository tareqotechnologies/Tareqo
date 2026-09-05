import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/custom_invoice.dart';
import '../../domain/repositories/i_custom_invoice_repository.dart';

/// Ponte entre o ServiceLocator (GetIt) e o Riverpod — substituível em
/// testes via `overrideWithValue`.
final customInvoiceRepositoryProvider = Provider<ICustomInvoiceRepository>(
  (ref) => ServiceLocator.instance<ICustomInvoiceRepository>(),
);

/// Facturas da loja [storeId] persistidas, da mais recente para a mais
/// antiga. Re-buscar ao voltar à tela; invalidar após criar uma factura.
final customInvoicesProvider =
    FutureProvider.autoDispose.family<List<CustomInvoice>, String>(
  (ref, storeId) =>
      ref.watch(customInvoiceRepositoryProvider).getByStore(storeId),
);
