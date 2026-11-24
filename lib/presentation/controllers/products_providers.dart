import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_barcode.dart';
import '../../domain/repositories/i_product_image_store.dart';
import '../../domain/usecases/add_product_use_case.dart';
import '../../domain/usecases/get_products_use_case.dart';
import '../../domain/usecases/product_barcode_use_cases.dart';
import '../../domain/usecases/update_product_use_case.dart';
import 'account_providers.dart';
import 'auth_providers.dart';

/// Ponte entre o ServiceLocator (GetIt) e o Riverpod: expõe o caso de
/// uso como provider, permitindo substituí-lo facilmente em testes
/// (`overrideWithValue`).
final getProductsUseCaseProvider = Provider<GetProductsUseCase>(
  (ref) => ServiceLocator.instance<GetProductsUseCase>(),
);

final addProductUseCaseProvider = Provider<AddProductUseCase>(
  (ref) => ServiceLocator.instance<AddProductUseCase>(),
);

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>(
  (ref) => ServiceLocator.instance<UpdateProductUseCase>(),
);

/// Casos de uso de embalagens. Nullable para testes que montam o PDV sem
/// inicializar o ServiceLocator (fallback: sem códigos adicionais).
final getProductBarcodesUseCaseProvider = Provider<GetProductBarcodesUseCase?>(
  (ref) => ServiceLocator.instance.isRegistered<GetProductBarcodesUseCase>()
      ? ServiceLocator.instance<GetProductBarcodesUseCase>()
      : null,
);

final saveProductBarcodesUseCaseProvider =
    Provider<SaveProductBarcodesUseCase?>(
      (ref) =>
          ServiceLocator.instance.isRegistered<SaveProductBarcodesUseCase>()
          ? ServiceLocator.instance<SaveProductBarcodesUseCase>()
          : null,
    );

/// Códigos de barras/embalagens da loja — usado pelo PDV para resolver
/// caixa/fardo sem carregar produtos diferentes.
final productBarcodesProvider =
    FutureProvider.family<List<ProductBarcode>, String>((ref, storeId) async {
      final useCase = ref.watch(getProductBarcodesUseCaseProvider);
      if (useCase == null) return const [];
      return useCase(storeId: storeId);
    });

/// Ponte para o armazenamento de FOTOS de produto (Supabase Storage no
/// SaaS, arquivo local no SQLite, no-op na memória/web). As sheets de
/// Novo/Editar produto usam este provider para subir a foto antes de
/// persistir o produto — substituível em testes via `overrideWithValue`.
final productImageStoreProvider = Provider<IProductImageStore>(
  (ref) => ServiceLocator.instance<IProductImageStore>(),
);

/// Estado da lista de produtos.
///
/// Um [AsyncValue]: `loading` (buscando), `error` (falha) ou `data`
/// (produtos carregados). A tela consome via `ref.watch` e reage
/// declarativamente a cada mudança.
final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);

/// Notifier que orquestra o carregamento da lista de produtos.
///
/// Conhece apenas o [GetProductsUseCase] (abstração de domínio) — nenhuma
/// dependência com datasources ou implementações concretas.
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() {
    final user = ref.watch(authStateProvider).value;
    final storeId = user == null
        ? null
        : ref.watch(activeStoreIdProvider(user.id));
    // Sem usuário ou loja ativa, lista vazia (o AuthGate roteia o login).
    if (storeId == null) return Future.value(const []);
    return ref.read(getProductsUseCaseProvider).call(storeId: storeId);
  }

  /// Recarrega a lista de produtos (ex.: pull-to-refresh).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
