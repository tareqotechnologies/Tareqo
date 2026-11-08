import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Tipo estrutural do produto (Fase 1 — pastelaria/produção).
///
/// Distingue o papel do produto na operação real — matéria-prima que entra
/// na receita, item comprado pronto para revender, produto fabricado
/// internamente (ficha técnica/produção), produto composto montado a partir
/// de componentes (ex.: hambúrguer completo) e embalagem/material de
/// consumo — em vez de tratar tudo como simples item de compra e venda.
///
/// O valor é persistido PELO NOME (JSON/SQLite/Postgres gravam `resale`,
/// `rawMaterial`...). O default é [resale] por compatibilidade: produtos
/// antigos (sem a coluna) já eram compráveis e vendáveis — continuam
/// funcionando exatamente igual.
enum ProductType {
  /// Matéria-prima: farinha, açúcar, ovos, leite, carne... — consumida
  /// pela produção (ficha técnica), nunca vendida diretamente no balcão.
  rawMaterial('Matéria-prima'),

  /// Produto comprado pronto para revenda: água, refrigerante, sumo
  /// engarrafado, embalados. Entrada por compra, baixa por venda.
  resale('Revenda'),

  /// Produto produzido internamente: pão francês, croissant, empada,
  /// bolo, hambúrguer de carne. Nasce de uma ordem de produção (ficha
  /// técnica baixa os ingredientes e cria o lote do produto acabado).
  manufactured('Produzido'),

  /// Produto composto/montado: hambúrguer completo, sanduíche, menu,
  /// pequeno-almoço — vendido pela explosão dos componentes da receita
  /// (ou pelo produto acabado pré-produzido, no modo híbrido).
  composite('Composto'),

  /// Embalagem e material de consumo: caixa, saco, copo, tampa,
  /// guardanapo, talher. Comprado e consumido pela produção/montagem.
  packaging('Embalagem');

  const ProductType(this.label);

  /// Rótulo exibido na UI (a serialização JSON usa o nome do enum).
  final String label;

  /// Papel no fluxo de COMPRAS: itens repostos por uma entrada de estoque
  /// comprada de fornecedores — matéria-prima, revenda e embalagem. Os
  /// produzidos/compostos nascem da produção interna (ficha técnica), não
  /// de uma compra, então não aparecem no carrinho de compras.
  bool get isPurchasable =>
      this == ProductType.rawMaterial ||
      this == ProductType.resale ||
      this == ProductType.packaging;

  /// Papel no PDV: itens vendáveis ao balcão — revenda, produzidos e
  /// compostos. Matéria-prima e embalagem são consumidas internamente
  /// (produção/montagem), nunca vendidas directamente.
  bool get isSellable =>
      this == ProductType.resale ||
      this == ProductType.manufactured ||
      this == ProductType.composite;

  /// Papel na PRODUÇÃO (Fase 2 — ficha técnica): itens que podem nascer de
  /// uma ordem de produção interna — produzidos (pão, bolo) e compostos
  /// (hambúrguer, menu). Matéria-prima/embalagem são CONSUMIDAS pela
  /// produção e a revenda já entra pronta pela compra — nenhum deles pode
  /// ser o produto ACABADO de uma ficha técnica.
  bool get isProducible =>
      this == ProductType.manufactured || this == ProductType.composite;
}

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
    @Default(0) int stockQuantity,// Código de barras convencional do produto (EAN-13, EAN-8, UPC-A, UPC-E,// Code 128 etc.). Campo opcional, universal — independente do PLU ou// configuração de balança. Prefixo vazio = sem código de barras.@Default('') String barcode,// Código de barras/PLU do produto (opcional, até 5 dígitos): usado// pelas balanças etiquetadoras (formato 20PPPPPWWWWW) e pelo campo de// código de barras do PDV. Os ids internos são alfanuméricos longos;// o PLU é o código numérico impresso nas etiquetas.@Default('') String code,
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
    // Tipo estrutural do produto (Fase 1). Default [ProductType.resale]
    // por compatibilidade: produtos antigos (sem a coluna no banco) já
    // eram compráveis e vendáveis — a leitura preserva o comportamento;
    // o JSON externo sem o campo também cai no default.
    //
    // `unknownEnumValue`: um valor NÃO reconhecido (ex.: gravado por uma
    // versão mais nova do app) cai em [ProductType.resale] em vez de
    // lançar `ArgumentError` — mesma tolerância dos datasources SQLite e
    // Supabase, que fazem `firstWhere(...orElse: resale)` ao mapear a
    // coluna `type`.
    @JsonKey(unknownEnumValue: ProductType.resale)
    @Default(ProductType.resale)
    ProductType type,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
