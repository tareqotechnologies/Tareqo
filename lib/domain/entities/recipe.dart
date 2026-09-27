import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

/// Componente de uma FICHA TÉCNICA (Fase 2 — pastelaria/produção).
///
/// Aponta para o produto COMPONENTE (matéria-prima, embalagem ou um
/// intermediário) e a quantidade consumida para produzir [Recipe.yieldQuantity]
/// do produto acabado. A quantidade está em MILÉSIMOS de unidade (W11) —
/// mesma convenção do estoque e dos lotes.
///
/// Não guarda snapshot de nome/preço: a ficha técnica é uma CONFIGURAÇÃO
/// (não um documento histórico) — o nome exibido vem do catálogo vivo, e o
/// custo é calculado no momento da produção (preço de compra atual do
/// componente). O histórico de produção é que guarda o snapshot.
@freezed
abstract class RecipeItem with _$RecipeItem {
  const factory RecipeItem({
    /// Produto COMPONENTE (consumido pela produção).
    required String productId,

    /// Quantidade consumida para um lote/base, em MILÉSIMOS (W11).
    required int quantity,
  }) = _RecipeItem;

  factory RecipeItem.fromJson(Map<String, dynamic> json) =>
      _$RecipeItemFromJson(json);
}

/// Entidade de domínio que representa uma **FICHA TÉCNICA** (receita/BOM) —
/// a receita para produzir um produto `manufactured`/`composite`.
///
/// Relação: [items] são consumidos ([ProductType.isPurchasable]/consumíveis)
/// e o [productId] é o produto ACABADO ([ProductType.isProducible]) criado
/// por uma ordem de produção. A produção baixa os componentes em ordem FIFO
/// dos lotes e cria um NOVO lote do produto acabado, com custo calculado a
/// partir dos componentes — tudo atómico (ver `ProcessProductionUseCase`).
///
/// [yieldQuantity] é o RENDIMENTO da base: quantos milésimos do produto
/// acabado a receita produz a partir das quantidades em [items]. Produzir
/// N bases multiplica todos os componentes e o rendimento por N.
///
/// Imutável (Freezed) — mesmas convenções do restante do domínio.
@freezed
abstract class Recipe with _$Recipe {
  const factory Recipe({
    required String id,
    // Loja dona da ficha técnica (Fase 2 do multi-tenancy).
    @Default('st1') String storeId,
    // Produto ACABADO que esta ficha técnica produz (`manufactured`/
    // `composite`). Uma produção cria um lote novo deste produto.
    required String productId,
    // Rendimento da base, em MILÉSIMOS de unidade (W11): 1000 = 1 unidade.
    // Deve ser > 0 — produzir N bases gera `yieldQuantity * N`.
    required int yieldQuantity,
    // Componentes consumidos (ao menos um). Quantidades > 0.
    required List<RecipeItem> items,
    // Ficha ATIVA: uma ficha inativa é preservada no histórico mas não
    // aparece para produzir.
    @Default(true) bool isActive,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);
}
