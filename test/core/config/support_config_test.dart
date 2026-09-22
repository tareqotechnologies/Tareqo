import 'package:flutter_test/flutter_test.dart';

import 'package:tareqo/core/config/support_config.dart';

/// Sem --dart-define, o número embutido de produção está ativo — o tile
/// "Fale com o suporte" do ecrã Ajuda abre o WhatsApp do suporte real.
void main() {
  group('SupportConfig', () {
    test('número de WhatsApp embutido tem formato wa.me válido', () {
      // Apenas dígitos, com código do país (258 = Moçambique) — formato
      // exigido pelo wa.me (sem +, sem espaços, sem traços).
      expect(RegExp(r'^\d{12,15}$').hasMatch(SupportConfig.whatsAppNumber),
          isTrue, reason: 'número: ${SupportConfig.whatsAppNumber}');
    });

    test('whatsappUri monta o deep link com número e mensagem', () {
      final uri = SupportConfig.whatsappUri('Olá! Preciso de ajuda.');

      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/${SupportConfig.whatsAppNumber}');
      // Mensagem pré-preenchida decodificada.
      expect(uri.queryParameters['text'], 'Olá! Preciso de ajuda.');
    });
  });
}
