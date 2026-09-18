import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Espia o canal de plataforma do HapticFeedback: em teste a vibração é
/// no-op, mas a MENSAGEM no `SystemChannels.platform` prova que o gate da
/// preferência passou e o feedback foi solicitado — determinístico.
///
/// Contrato do Flutter moderno: o método do canal é sempre
/// `'HapticFeedback.vibrate'` e o TIPO da vibração viaja no argumento
/// (`'HapticFeedbackType.selectionClick'` etc.); o `vibrate()` legado não
/// leva argumento (`null`). O mesmo canal carrega mensagens de
/// SystemChrome/SystemSound — tudo que não é haptic é ignorado.
///
/// Uso: `final spy = HapticSpy()..install();` no `setUp` e
/// `spy.uninstall();` no `tearDown` (ou `addTearDown`).
class HapticSpy {
  int selectionClicks = 0;
  int mediumImpacts = 0;
  int heavyImpacts = 0;
  int vibrates = 0;

  Future<Object?>? _handler(MethodCall call) async {
    if (call.method != 'HapticFeedback.vibrate') return null;
    switch (call.arguments as String?) {
      case 'HapticFeedbackType.selectionClick':
        selectionClicks++;
      case 'HapticFeedbackType.mediumImpact':
        mediumImpacts++;
      case 'HapticFeedbackType.heavyImpact':
        heavyImpacts++;
      case null:
        vibrates++;
    }
    return null;
  }

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, _handler);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  }
}
