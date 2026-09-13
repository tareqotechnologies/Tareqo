import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/observability/crash_reporting.dart';

/// Contratos observáveis do [CrashReporting] SEM `SENTRY_DSN` (dev/CI):
/// o serviço é no-op silencioso no canal remoto e imprime no console em
/// debug. O ramo Sentry exige DSN em tempo de compilação — não é
/// executável em teste unitário (documentado como limitação).
void main() {
  group('CrashReporting sem DSN (ambiente de teste)', () {
    test('deve reportar isEnabled false — app não depende do Sentry', () {
      // when / then — sem --dart-define=SENTRY_DSN o serviço fica no-op.
      expect(CrashReporting.isEnabled, isFalse);
    });

    test(
      'initialize() deve completar sem erro (no-op, sem tocar a rede)',
      () async {
        // when / then — sem DSN, nem SentryFlutter.init nem handlers são
        // instalados; a inicialização do app não pode travar por causa disso.
        await CrashReporting.initialize();
      },
    );

    test('capture deve imprimir o erro no console em debug (com hint)', () {
      // given — auditoria M2: telas chamam CrashReporting.capture em vez
      // de debugPrint solto; o log precisa carregar o contexto do erro.
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        logs.add(message ?? '');
      };
      addTearDown(() => debugPrint = original);

      // when
      CrashReporting.capture(
        StateError('carrinho inconsistente'),
        StackTrace.current,
        hint: 'checkout',
      );

      // then — canal debug: prefixo [erro], hint e o erro na saída.
      final output = logs.join('\n');
      expect(output, startsWith('[erro]'));
      expect(output, contains('checkout'));
      expect(output, contains('carrinho inconsistente'));
    });

    test('capture sem hint deve imprimir o erro sem sufixo de contexto', () {
      // given
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        logs.add(message ?? '');
      };
      addTearDown(() => debugPrint = original);

      // when
      CrashReporting.capture(
        ArgumentError('valor negativo'),
        StackTrace.current,
      );

      // then — sem hint não há espaço extra antes do erro.
      final output = logs.join('\n');
      expect(output, startsWith('[erro] '));
      expect(output, isNot(contains('null')));
      expect(output, contains('valor negativo'));
      // Stack trace acompanha (diagnóstico local sem Sentry).
      expect(output, contains('#'));
    });
  });
}
