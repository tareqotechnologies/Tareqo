import '../../core/utils/ids.dart';
import '../entities/product.dart';
import '../entities/stock_lot.dart';
import '../repositories/i_product_repository.dart';
import '../repositories/i_stock_lot_repository.dart';
import '../repositories/i_unit_of_work.dart';

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
///
/// W11 (FIFO): quando o cadastro informa estoque inicial, um LOTE é criado
/// junto com a validade informada (opcional — null para não perecíveis; o
/// dono também pode informar validade nas compras). Produto e lote são
/// gravados na mesma transação ([IUnitOfWork]): a invariante
/// `stock = Σ lotes` nunca fica quebrada.
class AddProductUseCase {
  const AddProductUseCase(
    this._repository,
    this._lotRepository,
    this._unitOfWork,
  );

  final IProductRepository _repository;
  final IStockLotRepository _lotRepository;
  final IUnitOfWork _unitOfWork;

  /// Adiciona [product], validando que o preço de venda não seja menor
  /// que o preço de compra.
  ///
  /// [expiryDate] (opcional) carimba a validade do LOTE inicial do estoque
  /// de abertura — alimenta os alertas do dashboard (Vermelho: vencido;
  /// Amarelo: vence em < 30 dias). null = produto sem validade (não
  /// perecível), FIFO por data de entrada.
  ///
  /// Lança [InvalidPriceException] se a validação falhar; o produto
  /// **não** é persistido nesse caso.
  Future<void> call(Product product, {DateTime? expiryDate}) async {
    if (product.salePriceCents < product.purchasePriceCents) {
      throw InvalidPriceException(
        'O preço de venda (${product.salePriceCents}) não pode ser menor '
        'que o preço de compra (${product.purchasePriceCents}).',
      );
    }

    await _unitOfWork.run(() async {
      await _repository.add(product);
      if (product.stockQuantity > 0) {
        // Lote inicial do estoque de abertura (W11): validade opcional do
        // cadastro (null = FIFO por data de entrada), custo = preço de
        // compra do cadastro.
        await _lotRepository.add(
          StockLot(
            id: AppIds.newId('lot'),
            storeId: product.storeId,
            productId: product.id,
            entryDate: DateTime.now(),
            expiryDate: expiryDate,
            initialQuantity: product.stockQuantity,
            currentQuantity: product.stockQuantity,
            costPriceCents: product.purchasePriceCents,
          ),
        );
      }
    });
  }
}
