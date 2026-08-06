import '../entities/product.dart';
import '../repositories/i_product_repository.dart';

/// Exceção de domínio para violação da regra de preço do produto.
final class InvalidPriceException implements Exception {
  const InvalidPriceException(this.message);

  final String message;

  @override
  String toString() => 'InvalidPriceException: $message';
}

/// Caso de uso: adicionar um novo produto.
///
/// Contém a regra de negócio de validação de preço — decisão deliberada
/// de mantê-la aqui e não na UI (ver README). A UI apenas exibe a
/// mensagem de [InvalidPriceException] quando ela ocorre.
class AddProductUseCase {
  const AddProductUseCase(this._repository);

  final IProductRepository _repository;

  /// Adiciona [product], validando que o preço de venda não seja menor
  /// que o preço de compra.
  ///
  /// Lança [InvalidPriceException] se a validação falhar; o produto
  /// **não** é persistido nesse caso.
  Future<void> call(Product product) async {
    if (product.salePriceCents < product.purchasePriceCents) {
      throw InvalidPriceException(
        'O preço de venda (${product.salePriceCents}) não pode ser menor '
        'que o preço de compra (${product.purchasePriceCents}).',
      );
    }

    await _repository.add(product);
  }
}
