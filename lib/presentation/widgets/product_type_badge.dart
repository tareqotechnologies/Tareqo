import 'package:flutter/material.dart';

import '../../core/i18n/l10n_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import 'status_chip.dart';

/// Cor do selo do TIPO estrutural do produto (Fase 1) — todos dentro da
/// paleta RE2 (petróleo/slate/terracota/cinza quente), sem cor fora do
/// sistema.
Color productTypeColor(ProductType type) => switch (type) {
  ProductType.rawMaterial => AppColors.accentOrangeSoft,
  ProductType.resale => AppColors.accentOrangeSoft,
  ProductType.manufactured => AppColors.lightPrimary,
  ProductType.composite => AppColors.accentOrange,
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
