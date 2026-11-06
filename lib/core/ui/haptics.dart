import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_preferences.dart';

/// Feedback tátil centralizado do app.
///
/// **Filosofia (HIG):** haptics confirmam eventos significativos, não
/// toques. Usar com moderação — vibração em cada interação vira ruído e
/// fadiga. Escopo deliberado (moderado):
///
/// * [selection] — trocas de seleção relevantes (aba, filtro, toggle).
/// * [success] — venda/pagamento concluído, gravação confirmada.
/// * [warning] — confirmação destrutiva aceita, ação de risco.
/// * [error] — falha que exige atenção do utilizador.
///
/// Nunca em cada tecla do PDV, nunca em scroll, nunca em navegção comum.
///
/// **Preferência:** respeita `hapticsEnabled` (Lojas → Ajustes → Geral,
/// padrão `true`). O estado vive em [AppPreferences] (SharedPreferences,
/// leitura no bootstrap); em teste, use [debugOverrideEnabled] para fixar.
///
/// **Determinismo em testes/goldens:** a vibração é um efeito de
/// plataforma — nos testes de widget ela é um no-op (o plugin não está
/// registrado), mas o gate da preferência é aplicado antes, de modo que
/// testes com a preferência desligada não tocam o canal de plataforma.
abstract final class Haptics {
  static const String _prefsKey = 'haptics_enabled';

  static bool _enabled = true;

  /// Gate de teste (injeta o valor sem tocar em SharedPreferences).
  @visibleForTesting
  static bool? debugOverrideEnabled;

  /// Lê a preferência persistida (chamado no bootstrap de produção).
  ///
  /// Best-effort: sem plataforma disponível (testes de widget) mantém o
  /// default — a preferência nunca bloqueia o arranque.
  static Future<void> load() async {
    try {
      final value = await AppPreferences.getBool(_prefsKey);
      if (value != null) _enabled = value;
    } catch (_) {
      // Mantém o default (ligado).
    }
  }

  /// Persiste e aplica a preferência (Lojas → Ajustes → Geral).
  /// O estado em memória é aplicado SEMPRE — persistência é best-effort.
  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      await AppPreferences.setBool(_prefsKey, value);
    } catch (_) {
      // Sem plataforma (testes): fica válido em memória.
    }
  }

  /// Estado atual (para o switch da tela de Ajustes).
  static bool get isEnabled => debugOverrideEnabled ?? _enabled;

  static void _perform(VoidCallback action) {
    if (!isEnabled) return;
    action();
  }

  /// Seleção relevante: leve "clique" seco (aba, filtro, toggle).
  static void selection() => _perform(HapticFeedback.selectionClick);

  /// Conclusão bem-sucedida de uma ação importante (venda, pagamento).
  static void success() => _perform(HapticFeedback.mediumImpact);

  /// Aviso/ação de risco confirmada (destrutiva aceita).
  static void warning() => _perform(HapticFeedback.heavyImpact);

  /// Falha que exige atenção (erro de validação bloqueante).
  static void error() => _perform(HapticFeedback.vibrate);
}
