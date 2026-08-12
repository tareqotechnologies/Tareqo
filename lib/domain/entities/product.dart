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
    // Foto do produto (opcional): referência da imagem — URL pública do
    // Supabase Storage (modo SaaS) ou caminho de arquivo local (modo
    // SQLite). Vazio = sem foto (a UI mostra o ícone padrão do produto).
    @Default('') String imagePath,
    // Preços em CENTAVOS inteiros (W4 — migração de dinheiro para
    // centavos; o banco persiste BIGINT/INTEGER).
    required int purchasePriceCents,
    required int salePriceCents,
    // Estoque em MILÉSIMOS de unidade (W11): 1000 = 1 unidade (produtos
    // normais) ou 1 kg/litro (produtos por peso). Inteiro exato — mesma
    // filosofia dos centavos (W4).
    @Default(0) int stockQuantity,
    // Código de barras/PLU do produto (opcional, até 5 dígitos): usado
    // pelas balanças etiquetadoras (formato 20PPPPPWWWWW) e pelo campo de
    // código de barras do PDV. Os ids internos são alfanuméricos longos;
    // o PLU é o código numérico impresso nas etiquetas.
    @Default('') String code,
    // Venda por FRAÇÃO (peso/granel): quando verdadeiro, o PDV aceita
    // quantidades decimais (ex.: 1,75 kg) e o código de barras de balança
    // é interpretado. O preço unitário é por UNIDADE da [unitLabel]
    // (ex.: por kg).
    @Default(false) bool vendaPorFracao,
    // Unidade de venda dos produtos por peso (kg, g, l, ml...). 'un'
    // (padrão) = unidade inteira normal.
    @Default('un') String unitLabel,
    // Produto ATIVO no catálogo (padrão). Ao ser desativado, some do PDV
    // e das compras (não pode ser vendido nem reposto), mas permanece na
    // lista de Produtos com o selo "Inativo" — o dono/gerente pode
    // reativá-lo quando quiser. O estoque existente é preservado (volta a
    // ser vendível na reativação).
    @Default(true) bool isActive,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
