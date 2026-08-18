import 'package:flutter/material.dart';

import 'local_image_file_stub.dart' if (dart.library.io) 'local_image_file_io.dart';

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
 });

 /// Referência da foto (URL, caminho local ou vazio = sem foto).
 final String imagePath;

 final double size;
 final double radius;
 final double iconSize;

 @override
 Widget build(BuildContext context) {
 final theme = Theme.of(context);

 final fallback = Container(
 width: size,
 height: size,
 alignment: Alignment.center,
 decoration: BoxDecoration(
 color: theme.colorScheme.primaryContainer,
 borderRadius: BorderRadius.circular(radius),
 border: Border.all(
 color: theme.colorScheme.primary.withValues(alpha: 0.4),
 width: 1.2,
 ),
 ),
 child: Icon(
 Icons.inventory_2_outlined,
 size: iconSize,
 color: theme.colorScheme.onPrimaryContainer,
 ),
 );

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
