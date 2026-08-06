import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Entidade de domínio que representa um produto do ERP.
///
/// Imutável por construção (Freezed): todos os campos são `final`, o
/// construtor é `const` e o `copyWith` gera novas instâncias em vez de
/// mutar. Não possui lógica de infraestrutura — apenas regra de negócio.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    // Loja dona do produto — cada loja tem seu próprio estoque (Fase 2
    // do multi-tenancy). O valor default mantém compatibilidade com
    // construções antigas; a UI sempre carimba a loja ativa.
    @Default('st1') String storeId,
    required String name,
    @Default('') String description,
    // Preços em CENTAVOS inteiros (W4 — migração de dinheiro para
    // centavos; o banco persiste BIGINT/INTEGER).
    required int purchasePriceCents,
    required int salePriceCents,
    @Default(0) int stockQuantity,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
