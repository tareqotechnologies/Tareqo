import 'package:flutter/material.dart';

/// Stub para plataformas SEM `dart:io` (web): o modo local não guarda
/// imagens em disco na web (store no-op), então qualquer caminho local
/// cai no fallback do ícone.
Widget localImageFile(String path, Widget fallback, {int? cacheWidth}) =>
    fallback;
