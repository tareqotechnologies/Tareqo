import '../entities/product.dart';
import '../repositories/i_product_repository.dart';
import '../repositories/i_stock_adjustment_processor.dart';
import '../repositories/i_unit_of_work.dart';
import 'add_product_use_case.dart' show InvalidPriceException;
import 'fifo_stock_use_case.dart';
import 'update_product_stock_use_case.dart' show ProductNotFoundException;

/// Caso de uso: editar um produto existente.
///
/// Três operações, todas escopadas pela loja e atômicas:
/// - [updateDetails] — campos EDITÁVEIS do catálogo (nome, descrição,
///   preços, código/PLU, venda por fração e status ativo). **Nunca** toca
///   no estoque: a mutação de quantidade passa exclusivamente pelo
///   [FifoStockUseCase], que mantém a invariante `stock = Σ lotes`;
/// - [adjustStock] — AJUSTE MANUAL do estoque (contagem física,
///   quebra/perda): define a quantidade ABSOLUTA, criando um lote novo
///   quando aumenta e consumindo lotes em FIFO quando diminui — a
///   invariante nunca quebra. No Supabase delega à RPC `adjust_product_stock`
///   (transação única no servidor, guarda gerencial);
/// - [setActive] — desativa/reativa o produto (some do PDV e das compras
///   quando inativo; o estoque é preservado para a reativação).
///
/// Regra de negócio duplicada do [AddProductUseCase] por consistência: o
/// preço de venda não pode ser menor que o preço de compra — a edição
/// rejeita o mesmo caso de erro ([InvalidPriceException]).
class UpdateProductUseCase {
  const UpdateProductUseCase(
    this._repository,
    this._fifoStock,
    this._unitOfWork, {
    this.stockAdjustmentProcessor,
  });

  final IProductRepository _repository;
  final FifoStockUseCase _fifoStock;
  final IUnitOfWork _unitOfWork;

  /// Supabase: processador atômico registrado (RPC `adjust_product_stock`).
  /// Local/testes: `null` — o ajuste usa o caminho composto com
  /// [IUnitOfWork] + [FifoStockUseCase].
  final IStockAdjustmentProcessor? stockAdjustmentProcessor;

  /// Atualiza os campos EDITÁVEIS do catálogo de [product] (nome,
  /// descrição, preços, código/PLU, venda por fração e status ativo).
  ///
  /// ⚠️ O estoque de [product] é IGNORADO — a persistência atualiza apenas
  /// os campos do catálogo; o estoque continua pela porta FIFO.
  ///
  /// Lança [InvalidPriceException] se o preço de venda for menor que o de
  /// compra (nada é persistido nesse caso) e [StateError] se o produto não
  /// existir na loja.
  Future<void> updateDetails(Product product) async {
    if (product.salePriceCents < product.purchasePriceCents) {
      throw InvalidPriceException(
        'O preço de venda (${product.salePriceCents}) não pode ser menor '
        'que o preço de compra (${product.purchasePriceCents}).',
      );
    }
    await _repository.update(product);
  }

  /// Define o estoque do produto [productId] da loja [storeId] para
  /// [newQuantity] MILÉSIMOS (valor absoluto — contagem física).
  ///
  /// - Aumentou: cria um LOTE novo (sem validade — FIFO por data de
  ///   entrada; custo = preço de compra atual do catálogo);
  /// - Diminuiu: consome os lotes em ordem FIFO (validade mais próxima
  ///   primeiro) — o estoque do produto cai junto na mesma transação;
  /// - Igual: no-op.
  ///
  /// Lança [ProductNotFoundException] se o produto não existir na loja e
  /// [ArgumentError] para quantidade negativa. A invariante
  /// `stock = Σ lotes` nunca quebra por esta porta.
  Future<void> adjustStock(
    String productId,
    int newQuantity, {
    required String storeId,
  }) async {
    // Primeiro valida a EXISTÊNCIA (o erro de produto inexistente tem
    // precedência sobre o ArgumentError de quantidade negativa).
    final product = await _repository.getById(productId, storeId: storeId);
    if (product == null) throw ProductNotFoundException(productId);

    if (newQuantity < 0) {
      throw ArgumentError.value(
        newQuantity,
        'newQuantity',
        'O estoque não pode ficar negativo.',
      );
    }
    if (newQuantity == product.stockQuantity) return;

    final processor = stockAdjustmentProcessor;
    if (processor != null) {
      // Supabase: delega à RPC `adjust_product_stock` (lotes + total do
      // produto em UMA transação no servidor, guarda gerencial).
      await processor.adjustStock(productId, newQuantity, storeId: storeId);
      return;
    }

    final delta = newQuantity - product.stockQuantity;
    await _unitOfWork.run(() async {
      if (delta > 0) {
        // Aumento: lote novo (FIFO por entrada; custo = preço de compra
        // atual do catálogo — mesmo custo do lote inicial do cadastro).
        await _fifoStock.increase(
          productId,
          delta,
          storeId: storeId,
          costPriceCents: product.purchasePriceCents,
        );
      } else {
        // Redução: baixa FIFO (validade mais próxima primeiro).
        await _fifoStock.decrease(productId, -delta, storeId: storeId);
      }
    });
  }

  /// Desativa/reativa o produto [productId] da loja [storeId].
  ///
  /// Produto inativo some do PDV e das compras (não pode ser vendido nem
  /// reposto), mas permanece na lista de Produtos com o selo "Inativo" e o
  /// estoque existente é preservado — a reativação devolve a venda. No-op
  /// quando o status já é o desejado. Lança [ProductNotFoundException] se
  /// o produto não existir na loja.
  Future<void> setActive(
    String productId, {
    required String storeId,
    required bool isActive,
  }) async {
    final product = await _repository.getById(productId, storeId: storeId);
    if (product == null) throw ProductNotFoundException(productId);
    if (product.isActive == isActive) return;
    await _repository.update(product.copyWith(isActive: isActive));
  }
}
