/// Configuração do suporte — contacto de WhatsApp usado pelo ecrã Ajuda
/// (tile "Fale com o suporte").
///
/// O default embutido é o número REAL de suporte (informação pública, mesmo
/// padrão do website). Para apontar a outro número (ex.: testes A/B por
/// país), sobrescreva no build:
/// `flutter build --dart-define=SUPPORT_WHATSAPP_NUMBER=2588XXXXXXXXX`
///
/// O número deve conter APENAS dígitos com o código do país — é o formato
/// que o `wa.me` exige (sem `+`, sem espaços, sem traços).
abstract final class SupportConfig {
  static const String _defaultWhatsAppNumber = '258846606062';

  /// Número de WhatsApp do suporte (dígitos, com código do país).
  static const String whatsAppNumber = String.fromEnvironment(
    'SUPPORT_WHATSAPP_NUMBER',
    defaultValue: _defaultWhatsAppNumber,
  );

  /// URI `wa.me` com o número do suporte e a [message] pré-preenchida —
  /// mesmo formato usado pelas partilhas de recibo/cotação do app.
  static Uri whatsappUri(String message) => Uri.parse(
    'https://wa.me/$whatsAppNumber?text=${Uri.encodeComponent(message)}',
  );
}
