import 'package:flutter/foundation.dart';

/// Fonte única de "agora" do app.
///
/// **Por que existe:** telas que renderizam data/saudação/idade de evento
/// lendo `DateTime.now()` direto ficam não-determinísticas em testes
/// visuais (golden tests quebram a cada dia) e difíceis de testar em
/// limites de período (fim do dia/mês). Com o [AppClock], o comportamento
/// de produção é idêntico ao `DateTime.now()` — e os testes fixam o
/// instante via [inject].
///
/// Uso em produção: `AppClock.now()` (delega a `DateTime.now`).
/// Uso em teste:
/// ```dart
/// AppClock.inject(() => DateTime(2026, 9, 17, 10, 30));
/// addTearDown(AppClock.reset);
/// ```
abstract final class AppClock {
  static DateTime Function() _now = DateTime.now;

  /// Instante atual. Sempre prefira este método a `DateTime.now()` em
  /// código de UI que precisa ser testável.
  static DateTime now() => _now();

  /// Fixa a fonte do tempo (apenas testes/goldens).
  @visibleForTesting
  static void inject(DateTime Function() now) => _now = now;

  /// Restaura o relógio real (apenas testes).
  @visibleForTesting
  static void reset() => _now = DateTime.now;
}
