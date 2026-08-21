import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Marca [path] (arquivo ou diretório) como **excluído do backup** do
/// sistema. No iOS chama o channel nativo que seta
/// `NSURLIsExcludedFromBackupKey`; em qualquer outra plataforma (Android —
/// já excluído globalmente via `allowBackup=false` —, desktop) é um no-op.
///
/// **Best-effort:** nunca propaga erro. Se o channel falhar (ex.: app em
/// primeiro launch com o registrar ainda indisponível), o app segue normal
/// e a exclusão pode ser retentada no próximo boot — segurança em
/// profundidade não pode derrubar a disponibilidade.
Future<void> excludePathFromBackup(String path) async {
  await excludeFromBackupOnPlatform(path, isIOS: Platform.isIOS);
}

/// Núcleo testável: o guard de plataforma é injetado (em teste forçamos
/// `isIOS: true` para exercitar o channel sem estar num dispositivo iOS).
@visibleForTesting
Future<void> excludeFromBackupOnPlatform(
  String path, {
  required bool isIOS,
}) async {
  if (!isIOS) return;
  try {
    const channel = MethodChannel('dev.dumbhanengue/backup_exclusion');
    await channel.invokeMethod<void>('excludeFromBackup', {'path': path});
  } catch (_) {
    // Ignorado de propósito — exclusão de backup é melhoria, não requisito.
  }
}
