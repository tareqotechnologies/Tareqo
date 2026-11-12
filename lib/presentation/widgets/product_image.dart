import 'package:flutter/material.dart';

import 'local_image_file_stub.dart'
    if (dart.library.io) 'local_image_file_io.dart';

/// Foto do produto (design system ultra-clean): quadrado arredondado que
/// exibe a imagem referenciada por [imagePath] — URL pública do Supabase
/// Storage (`http...`, Image.network) ou caminho de arquivo local (Image.file).
///
/// Sem imagem (ou falha ao carregar), o fallback é o mesmo thumbnail com
/// ícone usado antes do recurso de fotos — a UI nunca fica vazia.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imagePath,
    this.size = 44,
    this.radius = 12,
    this.iconSize = 20,
  }) : fluidHeight = 0;

  /// Variância fluida (card em grelha): preenche a largura da coluna
  /// com altura fixa de [fluidHeight].
  const ProductImage.fluid({
    super.key,
    required this.imagePath,
    this.fluidHeight = 0,
    this.radius = 12,
    this.iconSize = 20,
  }) : size = 0;

  /// Referência da foto (URL, caminho local ou vazio = sem foto).
  final String imagePath;

  final double size;
  final double radius;
  final double iconSize;

  /// Com `size == 0` (via `ProductImage.fluid`), a foto é fluida:
  /// largura disponível × [fluidHeight].
  final double fluidHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    // Placeholder padrão: tinta neutra (Preto 100 no claro, Preto 80 no
    // escuro) com glifo Snow. A tinta fica reservada a CTA/seleção — uma
    // miniatura por linha não é acento, é conteúdo.
    final fallbackBackground = dark
        ? scheme.surfaceContainerHighest
        : scheme.onSurface;
    final fallbackForeground = dark ? scheme.onSurface : scheme.surface;

    Widget fallbackOf(double width, double height) => Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fallbackBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        size: iconSize,
        color: fallbackForeground,
      ),
    );

    if (size == 0) {
      // Variância fluida: largura disponível × fluidHeight.
      final fallback = fallbackOf(double.infinity, fluidHeight);
      if (imagePath.isEmpty) return fallback;
      final image = imagePath.startsWith('http')
          ? Image.network(
              imagePath,
              fit: BoxFit.cover,
              cacheWidth: 512,
              errorBuilder: (_, _, _) => fallback,
            )
          : localImageFile(imagePath, fallback, cacheWidth: 512);
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: double.infinity,
          height: fluidHeight,
          child: image,
        ),
      );
    }

    final fallback = fallbackOf(size, size);
    if (imagePath.isEmpty) return fallback;

    // cacheWidth ~= 2× o tamanho exibido: decodifica o thumbnail em
    // resolução reduzida (as fotos são JPEG 1024px no storage) — evita
    // decodificar a imagem cheia para um quadrado de 44px nas listas.
    final cacheWidth = (size * 2).round();

    final Widget image = imagePath.startsWith('http')
        ? Image.network(
            imagePath,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            errorBuilder: (_, _, _) => fallback,
          )
        : localImageFile(imagePath, fallback, cacheWidth: cacheWidth);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}
