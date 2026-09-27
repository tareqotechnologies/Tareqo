import '../../core/utils/ids.dart';
import '../../core/utils/quantity.dart';
import '../entities/product.dart';
import '../entities/production_order.dart';
import '../entities/recipe.dart';
import '../repositories/i_production_processor.dart';
import '../repositories/i_production_repository.dart';
import '../repositories/i_unit_of_work.dart';
import 'fifo_stock_use_case.dart';

/// Exceção de domínio: produção inválida (produto não producível, componente
/// ausente/desativado, quantidade de bases inválida ou autocomposição).
final class InvalidProductionException implements Exception {
  const InvalidProductionException(this.message);

  final String message;

  @override
  String toString() => 'InvalidProductionException: $message';
}

/// Caso de uso: executar uma **ordem de produção** a partir de uma ficha
/// técnica — consome os componentes (baixa FIFO por lotes) e cria um novo
/// lote do produto acabado, tudo em uma única transação.
///
/// Orquestra [IProductionRepository], [FifoStockUseCase] e [IUnitOfWork] —
/// depende apenas de abstrações. Quando [processor] é fornecido (Supabase), a
/// produção inteira é delegada a ele (RPC `process_production`); sem
/// processor (SQLite/memória), usa o caminho composto com [IUnitOfWork].
///
/// O custo do produto acabado é calculado a partir do **preço de compra
/// atual** de cada componente ([Product.purchasePriceCents]) × a quantidade
/// consumida — vira o `costPriceCents` do lote criado. A produção NÃO
/// movimenta o caixa (os componentes já foram pagos na compra).
class ProcessProductionUseCase {
  const ProcessProductionUseCase(
    this._recipeRepository,
    this._fifoStock,
    this._unitOfWork, {
    this.processor,
  });

  final IProductionRepository _recipeRepository;
  final FifoStockUseCase _fifoStock;
  final IUnitOfWork _unitOfWork;

  /// Processador atómico opcional (Supabase via RPC).
  final IProductionProcessor? processor;

  /// Produz [batches] bases da [recipe] do produto [finishedProduct],
  /// consumindo os [components] (mapa id → produto, já carregado pela UI).
  ///
  /// Retorna a [ProductionOrder] registrada. Lança
  /// [InvalidProductionException] em violação de regra, `ProductNotFoundException`
  /// se um componente/produto não existir e `InsufficientStockException` se
  /// faltar estoque de algum componente.
  Future<ProductionOrder> call({
    required Recipe recipe,
    required Product finishedProduct,
    required Map<String, Product> components,
    required int batches,
    DateTime? dateTime,
  }) async {
    if (batches <= 0) {
      throw const InvalidProductionException(
        'A quantidade de bases a produzir deve ser maior que zero.',
      );
    }
    if (!finishedProduct.type.isProducible) {
      throw InvalidProductionException(
        'O produto "${finishedProduct.name}" não é produzível '
        '(tipo ${finishedProduct.type.name}).',
      );
    }
    if (recipe.items.isEmpty) {
      throw const InvalidProductionException(
        'A ficha técnica não tem componentes.',
      );
    }

    final producedQuantity = recipe.yieldQuantity * batches;
    final orderItems = <ProductionItem>[];
    var totalCostCents = 0;

    for (final item in recipe.items) {
      if (item.productId == finishedProduct.id) {
        throw const InvalidProductionException(
          'O produto acabado não pode ser componente da própria ficha.',
        );
      }
      final component = components[item.productId];
      if (component == null) {
        throw InvalidProductionException(
          'Componente ${item.productId} não encontrado no catálogo.',
        );
      }
      if (!component.isActive) {
        throw InvalidProductionException(
          'O componente "${component.name}" está desativado.',
        );
      }
      final consumed = item.quantity * batches;
      totalCostCents += Quantity.lineTotal(
        consumed,
        component.purchasePriceCents,
      );
      orderItems.add(
        ProductionItem(
          productId: component.id,
          productName: component.name,
          quantity: consumed,
          unitCostCents: component.purchasePriceCents,
        ),
      );
    }

    // Custo por unidade do produto acabado (arredondado para o centavo).
    final costPriceCents = producedQuantity == 0
        ? 0
        : totalCostCents * Quantity.milliFactor ~/ producedQuantity;

    final order = ProductionOrder(
      id: AppIds.newId('prod'),
      storeId: recipe.storeId,
      productId: finishedProduct.id,
      productName: finishedProduct.name,
      quantity: producedQuantity,
      recipeId: recipe.id,
      costPriceCents: costPriceCents,
      totalCostCents: totalCostCents,
      dateTime: dateTime ?? DateTime.now(),
      items: orderItems,
    );

    // Caminho atómico (Supabase): o servidor garante a transação inteira.
    final atomicProcessor = processor;
    if (atomicProcessor != null) {
      await atomicProcessor.process(order);
      return order;
    }

    await _unitOfWork.run(() async {
      // Valida componentes e produto acabado (existem e estão ATIVOS) ANTES
      // de mutar — espelha o lock_products_or_raise do servidor.
      await _fifoStock.requireActive(
        finishedProduct.id,
        storeId: recipe.storeId,
      );
      for (final item in order.items) {
        await _fifoStock.requireActive(item.productId, storeId: recipe.storeId);
      }

      // Consome cada componente (FIFO por validade/entrada). Roda ANTES de
      // gravar a ordem: uma falha de estoque (o caso comum) não deixa
      // registro órfão — mesmo no caminho em memória, sem transação real.
      for (final item in order.items) {
        await _fifoStock.decrease(
          item.productId,
          item.quantity,
          storeId: recipe.storeId,
        );
      }

      // Cria o lote do produto acabado com o custo calculado.
      await _fifoStock.increase(
        finishedProduct.id,
        producedQuantity,
        storeId: recipe.storeId,
        entryDate: order.dateTime,
        costPriceCents: costPriceCents,
      );

      // Registra a ordem (histórico) por último — o [IUnitOfWork] garante a
      // atomicidade no caminho real (SQLite).
      await _recipeRepository.addProductionOrder(order);
    });

    return order;
  }
}
