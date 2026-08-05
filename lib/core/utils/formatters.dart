import 'package:intl/intl.dart';

/// Formatação para a UI (moeda, datas e dias relativos).
///
/// A moeda e o idioma são configurados pelo **dono do tenant** (Ajustes)
/// via [applySettings] — o [AppSettings] é aplicado no `DumbhanengueApp`
/// sempre que o tenant carrega/altera. Sem configuração (testes, antes do
/// login), o padrão é BRL + pt-BR, mantendo o comportamento original.
abstract final class Formatters {
  static String _currencyCode = 'BRL';
  static String _language = 'pt';

  /// Símbolo por moeda suportada (escolha do dono).
  static const Map<String, String> _currencySymbols = {
    'BRL': r'R$',
    'USD': r'US$',
    'EUR': '€',
    'MZN': 'MTn',
  };

  /// Aplica as preferências do tenant à formatação (moeda + idioma).
  static void applySettings({
    required String currencyCode,
    required String language,
  }) {
    _currencyCode = currencyCode;
    _language = language;
  }

  /// Código da moeda atualmente ativa (default `BRL`).
  static String get currentCurrencyCode => _currencyCode;

  /// Idioma atualmente ativo (default `pt`).
  static String get currentLanguage => _language;

  /// Formata um valor na moeda e idioma ativos:
  /// `R$ 1.234,56` (pt) ou `US$ 1,234.56` (en).
  static String currency(double value) {
    final symbol = _currencySymbols[_currencyCode] ?? '$_currencyCode ';
    final locale = _language == 'en' ? 'en_US' : 'pt_BR';
    final formatted = NumberFormat('#,##0.00', locale).format(value);
    return '$symbol $formatted';
  }

  /// Formata como `04/08/2026`.
  static String date(DateTime date) =>
      '${_two(date.day)}/${_two(date.month)}/${date.year}';

  /// Formata como `04/08/2026 14:30`.
  static String dateTime(DateTime date) =>
      '${Formatters.date(date)} ${_two(date.hour)}:${_two(date.minute)}';

  /// Dia relativo: `Hoje`/`Today`, `Ontem`/`Yesterday` ou `04/08` — ideal
  /// para listas (segue o idioma ativo).
  static String day(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    final difference = today.difference(that).inDays;

    if (difference == 0) return _language == 'en' ? 'Today' : 'Hoje';
    if (difference == 1) return _language == 'en' ? 'Yesterday' : 'Ontem';
    return '${_two(date.day)}/${_two(date.month)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
