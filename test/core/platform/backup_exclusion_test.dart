import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/platform/backup_exclusion_io.dart';

/// V9 (auditoria 2026-08) — exclusão de backup dos arquivos locais.
///
/// Cobre o núcleo testável (`_excludePathFromBackup` com `isIOS` injetado):
/// fora do iOS é no-op imediato; no iOS chama o channel
/// `dev.tareqo/backup_exclusion` com o caminho exato; falha do
/// channel nunca propaga (best-effort).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.tareqo/backup_exclusion');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('fora do iOS é no-op — nunca chama o channel nativo', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });

    await excludeFromBackupOnPlatform('/tmp/qualquer.db', isIOS: false);

    expect(calls, isEmpty, reason: 'Android/desktop não devem tocar o iOS');
  });

  test('no iOS chama o channel com o caminho exato', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });

    await excludeFromBackupOnPlatform('/data/foo/tareqo.db', isIOS: true);

    expect(calls, hasLength(1));
    expect(calls.single.method, 'excludeFromBackup');
    expect(calls.single.arguments, {'path': '/data/foo/tareqo.db'});
  });

  test('falha do channel nativo NUNCA propaga (best-effort)', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => throw PlatformException(code: 'EXCLUDE_FAILED'),
    );

    await expectLater(
      excludeFromBackupOnPlatform('/data/foo/imagens', isIOS: true),
      completes,
    );
  });
}
