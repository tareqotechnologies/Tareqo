import 'dart:math' as math;

import '../../core/utils/ids.dart';
import '../entities/stock_lot.dart';
import '../repositories/i_stock_lot_repository.dart';
import 'update_product_stock_use_case.dart';

/// Caso de uso: gestão de estoque com **FIFO por lotes** (W11).
///
/// É a porta de entrada para mutar o estoque junto com os lotes:
/// - [increase] (compra) — cria um lote novo e aumenta o total do produto;
/// - [decrease] (venda) — abate a quantidade vendida dos lotes em ordem
///   FIFO (`data_validade` ascendente, sem validade no fim por
///   `data_entrada`) e reduz o total do produto;
/// - [ensureSufficientStock] — pré-validação pela soma dos lotes ativos.
///
/// Mantém a INVARIANTE central do módulo: `product.stock_quantity` é a soma
/// das quantidades atuais dos lotes ativos do produto — o total do produto
/// (lido pelo catálogo, KPIs e telas) nunca diverge dos lotes.
class FifoStockUseCase {
  const FifoStockUseCase(this._lotRepository, this._productStock);

  final IStockLotRepository _lotRepository;

  /// Mutação do total do produto (valida existência e nunca fica negativo).
  final UpdateProductStockUseCase _productStock;

  /// Garante que há [quantity] milésimos de [productId] disponíveis em
  /// lotes ativos na loja [storeId] — sem mutar nada.
  ///
  /// Primeiro valida que o produto EXISTE ([ProductNotFoundException]) —
  /// preserva a semântica original do fluxo — e então lança
  /// [InsufficientStockException] com a soma real dos lotes quando falta.
  Future<void> ensureSufficientStock(
    String productId,
    int quantity, {
    required String storeId,
  }) async {
    // Produto inexistente → ProductNotFoundException (mesma semântica do
    // caminho anterior, mantida para a UI e os contratos das RPCs).
    await _productStock.requireProduct(productId, storeId: storeId);

    final available = await _available(productId, storeId: storeId);
    if (available < quantity) {
      throw InsufficientStockException(
        productId: productId,
        available: available,
        requested: quantity,
      );
    }
  }

  /// Abate [quantity] milésimos do estoque de [productId] da loja
  /// [storeId], consumindo os lotes em **ordem FIFO**.
  ///
  /// Algoritmo (W11):
  /// 1. **Pré-validação atômica** ([ensureSufficientStock]): produto existe
  ///    E a soma dos lotes cobre a quantidade — NADA é mutado quando falta
  ///    estoque (a baixa não deixa baixas parciais nem lotes consumidos
  ///    pela metade ao lançar);
  /// 2. Consulta os lotes ativos ordenados por `data_validade` ascendente
  ///    (mais próximo do vencimento primeiro; sem validade no fim, FIFO
  ///    por data de entrada);
  /// 3. Abate do PRIMEIRO lote; se a quantidade do lote for insuficiente,
  ///    o excedente é abatido automaticamente do lote imediatamente
  ///    seguinte;
  /// 4. Ao final, reduz o total do produto na mesma quantidade ([UpdateProductStockUseCase]
  ///    revalida como defesa em profundidade).
  ///
  /// Deve rodar DENTRO da transação do chamador ([IUnitOfWork] no caminho
  /// composto; RPC `process_sale` no Supabase) — lotes e total do produto
  /// são gravados atomicamente.
  Future<void> decrease(
    String productId,
    int quantity, {
    required String storeId,
  }) async {
    // Passo 1 — pré-validação: lança ANTES de qualquer mutação quando o
    // estoque (soma dos lotes) não cobre a quantidade. A exceção carrega a
    // quantidade REAL disponível e nenhum lote é abatido.
    await ensureSufficientStock(productId, quantity, storeId: storeId);

    final lots = await _lotRepository.getActiveByProduct(
      productId,
      storeId: storeId,
    );

    var remaining = quantity;
    for (final lot in lots) {
      if (remaining <= 0) break;
      final take = math.min(lot.currentQuantity, remaining);
      await _lotRepository.updateQuantity(
        lot.id,
        lot.currentQuantity - take,
        storeId: storeId,
      );
      remaining -= take;
    }

    if (remaining > 0) {
      // Defesa em profundidade: os lotes mudaram ENTRE a pré-validação e
      // a baixa (ex.: chamada fora da transação, concorrência) — nunca
      // deixa o estoque negativo por esta porta.
      final available = await _available(productId, storeId: storeId);
      throw InsufficientStockException(
        productId: productId,
        available: available,
        requested: quantity,
      );
    }

    await _productStock.decrease(productId, quantity, storeId: storeId);
  }

  /// Entrada de mercadoria: cria um NOVO lote ([expiryDate] opcional —
  /// `null` para não perecíveis) e aumenta o total do produto.
  ///
  /// O lote nasce com `initial = current = [quantity]` milésimos e custo de
  /// aquisição [costPriceCents]. [entryDate] é a data da entrada (compra).
  ///
  /// Pré-valida a EXISTÊNCIA do produto ANTES de gravar o lote — uma
  /// compra de produto inexistente lança [ProductNotFoundException] sem
  /// deixar lote órfão (mesma proteção do [decrease]).
  Future<void> increase(
    String productId,
    int quantity, {
    required String storeId,
    DateTime? expiryDate,
    DateTime? entryDate,
    int costPriceCents = 0,
  }) async {
    await _productStock.requireProduct(productId, storeId: storeId);
    await _lotRepository.add(
      StockLot(
        id: AppIds.newId('lot'),
        storeId: storeId,
        productId: productId,
        entryDate: entryDate ?? DateTime.now(),
        expiryDate: expiryDate,
        initialQuantity: quantity,
        currentQuantity: quantity,
        costPriceCents: costPriceCents,
      ),
    );
    await _productStock.increase(productId, quantity, storeId: storeId);
  }

  /// Soma das quantidades atuais dos lotes ativos (milésimos).
  Future<int> _available(String productId, {required String storeId}) async {
    final lots = await _lotRepository.getActiveByProduct(
      productId,
      storeId: storeId,
    );
    return lots.fold<int>(
      0,
      (sum, lot) => sum + lot.currentQuantity,
    );
  }
}
