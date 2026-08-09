import '../entities/product.dart';
import '../repositories/i_product_repository.dart';

/// Exceção de domínio: produto inexistente no estoque.
final class ProductNotFoundException implements Exception {
  const ProductNotFoundException(this.productId);

  final String productId;

  @override
  String toString() =>
      'ProductNotFoundException: produto $productId não encontrado.';
}

/// Exceção de domínio: estoque insuficiente para atender a solicitação.
final class InsufficientStockException implements Exception {
  const InsufficientStockException({
    required this.productId,
    required this.available,
    required this.requested,
  });

  final String productId;
  final int available;
  final int requested;

  @override
  String toString() =>
      'InsufficientStockException: estoque insuficiente para $productId '
      '(disponível: $available, solicitado: $requested).';
}

/// Caso de uso: controlar a quantidade em estoque de um produto.
///
/// É a **única** porta de entrada para mutar o estoque: garante que o
/// valor nunca fique negativo, validando antes de persistir.
class UpdateProductStockUseCase {
  const UpdateProductStockUseCase(this._repository);

  final IProductRepository _repository;

  /// Obtém o produto da loja [storeId] ou lança [ProductNotFoundException].
  Future<Product> _requireProduct(
    String productId,
    String storeId,
  ) async {
    final product = await _repository.getById(productId, storeId: storeId);
    if (product == null) {
      throw ProductNotFoundException(productId);
    }
    return product;
  }

  /// Garante que o produto [productId] EXISTE na loja [storeId], lançando
  /// [ProductNotFoundException] caso contrário. Usado pelo
  /// [FifoStockUseCase] para preservar a semântica de "produto inexistente"
  /// antes da checagem de lotes.
  Future<void> requireProduct(
    String productId, {
    required String storeId,
  }) async {
    await _requireProduct(productId, storeId);
  }

  /// Garante que há [quantity] unidades de [productId] em estoque na loja
  /// [storeId].
  ///
  /// Usado como pré-validação (ex.: antes de registrar uma venda) —
  /// sem mutar nada. Escopado pela loja: um produto de outra loja não é
  /// visível nem mutável por esta porta.
  Future<void> ensureSufficientStock(
    String productId,
    int quantity, {
    required String storeId,
  }) async {
    final product = await _requireProduct(productId, storeId);
    if (product.stockQuantity < quantity) {
      throw InsufficientStockException(
        productId: productId,
        available: product.stockQuantity,
        requested: quantity,
      );
    }
  }

  /// Reduz [quantity] unidades do estoque de [productId] da loja [storeId].
  ///
  /// Revalida o estoque como defesa contra chamadas diretas — o estoque
  /// nunca fica negativo por esta porta.
  Future<void> decrease(
    String productId,
    int quantity, {
    required String storeId,
  }) async {
    final product = await _requireProduct(productId, storeId);
    if (product.stockQuantity < quantity) {
      throw InsufficientStockException(
        productId: productId,
        available: product.stockQuantity,
        requested: quantity,
      );
    }
    await _repository.updateStock(
      productId,
      product.stockQuantity - quantity,
      storeId: storeId,
    );
  }

  /// Aumenta o estoque de [productId] da loja [storeId] em [quantity]
  /// unidades.
  ///
  /// Usado pelo ProcessPurchaseUseCase (entrada de mercadoria). Revalida a
  /// existência do produto e grava o **valor absoluto** novo — o estoque
  /// nunca fica negativo por esta porta.
  Future<void> increase(
    String productId,
    int quantity, {
    required String storeId,
  }) async {
    final product = await _requireProduct(productId, storeId);
    await _repository.updateStock(
      productId,
      product.stockQuantity + quantity,
      storeId: storeId,
    );
  }
}
