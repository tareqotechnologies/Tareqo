import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/ui/haptics.dart';

/// Contrato da camada de haptics (Fase 3): default ligado, toggle de
/// preferência respeitado e gate de teste determinístico. A chamada de
/// plataforma em si é no-op no ambiente de teste — o que se valida aqui é
/// o estado/gate, não a vibração.
void main() {
  tearDown(() {
    Haptics.debugOverrideEnabled = null;
  });

  test('default é ligado', () {
    expect(Haptics.isEnabled, isTrue);
  });

  test('setEnabled desliga e religa o feedback', () async {
    await Haptics.setEnabled(false);
    expect(Haptics.isEnabled, isFalse);

    await Haptics.setEnabled(true);
    expect(Haptics.isEnabled, isTrue);
  });

  test('debugOverrideEnabled tem precedência (gate de teste)', () async {
    Haptics.debugOverrideEnabled = false;
    expect(Haptics.isEnabled, isFalse);

    // A preferência não vence o override de teste.
    await Haptics.setEnabled(true);
    expect(Haptics.isEnabled, isFalse);
  });

  test('chamadas de feedback respeitam o gate (sem exceção com preferência off)', () async {
    await Haptics.setEnabled(false);
    // Nenhuma destas deve lançar nem vibrar com a preferência desligada.
    Haptics.selection();
    Haptics.success();
    Haptics.warning();
    Haptics.error();
  });
}
