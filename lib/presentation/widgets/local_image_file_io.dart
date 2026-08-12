import 'dart:io';

import 'package:flutter/material.dart';

/// Renderiza a imagem de um arquivo LOCAL (`dart:io` — nativo).
/// Substituída pelo stub em plataformas sem `dart:io` (web).
/// [cacheWidth] decodifica em resolução reduzida (thumbnail nas listas).
Widget localImageFile(
  String path,
  Widget fallback, {
  int? cacheWidth,
}) => Image.file(
  File(path),
  fit: BoxFit.cover,
  cacheWidth: cacheWidth,
  errorBuilder: (_, _, _) => fallback,
);
