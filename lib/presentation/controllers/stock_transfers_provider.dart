import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ids.dart';
import '../../domain/entities/stock_transfer.dart';
import 'products_providers.dart';

/// Lista em memória de transferências de estoque entre lojas.
/// Cada transferência é registada quando o utilizador confirma o
/// recebimento — nesse ponto o estoque é mutado (baixa na origem,
/// entrada no destino).
final stockTransfersProvider =
    NotifierProvider<StockTransfersNotifier, List<StockTransfer>>(
      StockTransfersNotifier.new,
    );

class StockTransfersNotifier extends Notifier<List<StockTransfer>> {
  @override
  List<StockTransfer> build() => [];

  /// Executa a transferência: baixa na loja de origem + entrada na loja de
  /// destino. Regista o movimento no histórico.
  Future<void> executeTransfer({
    required String productId,
    required String productName,
    required String fromStoreId,
    required String fromStoreName,
    required String toStoreId,
    required String toStoreName,
    required int quantityMilli,
    required String unitLabel,
  }) async {
    final useCase = ref.read(updateProductUseCaseProvider);
    final getProducts = ref.read(getProductsUseCaseProvider);

    // 1. Ler estoque actual na loja de origem.
    final originProducts = await getProducts.call(storeId: fromStoreId);
    final originProduct = originProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () =>
          throw ArgumentError('Produto não encontrado na loja de origem'),
    );

    final currentStockMilli = originProduct.stockQuantity;
    if (quantityMilli > currentStockMilli) {
      throw ArgumentError('Stock insuficiente na loja de origem');
    }

    // 2. Baixar estoque na loja de origem.
    await useCase.adjustStock(
      productId,
      currentStockMilli - quantityMilli,
      storeId: fromStoreId,
    );

    // 3. Verificar se o produto existe no destino.
    final destProducts = await getProducts.call(storeId: toStoreId);
    final destProduct = destProducts
        .where((p) => p.id == productId)
        .firstOrNull;

    if (destProduct != null) {
      // Produto já existe no destino — somar estoque.
      await useCase.adjustStock(
        productId,
        destProduct.stockQuantity + quantityMilli,
        storeId: toStoreId,
      );
    } else {
      // Produto NÃO existe no destino — criar cópia com novo ID.
      final addUseCase = ref.read(addProductUseCaseProvider);
      final newProduct = originProduct.copyWith(
        id: AppIds.newId('p'),
        storeId: toStoreId,
        stockQuantity: quantityMilli,
      );
      await addUseCase(newProduct);
    }

    // 5. Registar no histórico.
    final transfer = StockTransfer(
      id: 'st_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      productName: productName,
      fromStoreId: fromStoreId,
      fromStoreName: fromStoreName,
      toStoreId: toStoreId,
      toStoreName: toStoreName,
      quantityMilli: quantityMilli,
      unitLabel: unitLabel,
      status: StockTransferStatus.received,
      createdAt: DateTime.now(),
    );

    state = [transfer, ...state];
  }
}
