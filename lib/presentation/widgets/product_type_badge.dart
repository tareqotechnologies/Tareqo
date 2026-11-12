import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import 'status_chip.dart';

/// Cores dos selos de categoria de produto — escala neutra oficial.
/// Matéria-prima: Preto 60; Revenda: Preto 100; Produzido: Preto 70;
/// Composto: Branco 90; Embalagem: Branco 80. O acento não é usado em
/// selos informativos (micro-acento só em CTA/foco/selecção).
Color productTypeColor(ProductType type) => switch (type) {
  ProductType.rawMaterial => AppColors.black60,
  ProductType.resale => AppColors.categoryResale,
  ProductType.manufactured => AppColors.categoryProduzido,
  ProductType.composite => AppColors.categoryComposto,
  ProductType.packaging => AppColors.white80,
};

/// Rótulo localizado do tipo estrutural do produto (Fase 1).
String productTypeLabel(BuildContext context, ProductType type) =>
    switch (type) {
      ProductType.rawMaterial => context.l10n.productsTypeRawMaterial,
      ProductType.resale => context.l10n.productsTypeResale,
      ProductType.manufactured => context.l10n.productsTypeManufactured,
      ProductType.composite => context.l10n.productsTypeComposite,
      ProductType.packaging => context.l10n.productsTypePackaging,
    };

/// Selo do TIPO estrutural do produto (Fase 1) — mesmo rótulo/cor em toda a
/// app (lista de Produtos, carrinho do PDV e carrinho de compras), para o
/// operador reconhecer o papel do produto (matéria-prima, revenda,
/// produzido, composto, embalagem) sem abrir o cadastro.
///
/// Convenção de exibição: o PDV e a lista de Produtos mostram o tipo como
/// TEXTO na linha de metadados (via [productTypeLabel]) — superfícies
/// densas em que o selo colorido competiria com preço e quantidade; no
/// PDV [ProductType.resale] também aparece (o operador vê sempre o
/// papel). Compras e Produção mantêm o selo colorido.
class ProductTypeBadge extends StatelessWidget {
  const ProductTypeBadge({super.key, required this.type});

  final ProductType type;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: productTypeLabel(context, type),
    color: productTypeColor(type),
  );
}
