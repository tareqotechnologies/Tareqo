import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import 'status_chip.dart';

/// Cores dos selos de categoria de produto (modo escuro otimizado).
/// Revenda: cinza; Produzido: laranja; Composto: azul/roxo.
/// Utilizadas nos selos/badges ao lado dos produtos.
Color productTypeColor(ProductType type) => switch (type) {
  ProductType.rawMaterial => AppColors.accentOrangeSoft,
  ProductType.resale => AppColors.categoryResale,       // gray 300
  ProductType.manufactured => AppColors.categoryProduzido, // orange accent
  ProductType.composite => AppColors.categoryComposto,     // violet 400
  ProductType.packaging => AppColors.lightSurfaceSecondary,
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
/// Convenção de exibição: as LINHAS do PDV e das compras mostram o selo em
/// TODOS os tipos (incluindo [ProductType.resale], para o operador ver
/// sempre o papel); a lista de Produtos omite o selo de [ProductType.resale]
/// (o estado comum do varejo — evita ruído) e guarda a visibilidade com
/// `if (type != ProductType.resale)`.
class ProductTypeBadge extends StatelessWidget {
  const ProductTypeBadge({super.key, required this.type});

  final ProductType type;

  @override
  Widget build(BuildContext context) => StatusChip(
    label: productTypeLabel(context, type),
    color: productTypeColor(type),
  );
}
