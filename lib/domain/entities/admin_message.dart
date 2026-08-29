import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_message.freezed.dart';
part 'admin_message.g.dart';

/// Tipo de mensagem do super admin para o tenant.
enum AdminMessageType {
  /// Cotação / proposta de plano (valor, período).
  billingQuote,

  /// Alteração de validade do plano (extensão, redução).
  planExpiryChange,

  /// Notificação de expiração iminente do plano.
  planExpiringSoon,

  /// Mensagem geral do admin (aviso, actualização, etc.).
  general,
}

/// Mensagem enviada pelo super admin para o dono do tenant.
///
/// O super admin pode emitir cotações, notificar alterações de validade,
/// ou enviar mensagens gerais. A mensagem aparece no painel de notificações
/// do tenant com um badge e pode ser marcada como lida.
@freezed
abstract class AdminMessage with _$AdminMessage {
  const factory AdminMessage({
    required String id,

    /// Tenant destinatário da mensagem.
    required String tenantId,

    /// Tipo da mensagem.
    required AdminMessageType type,

    /// Título da mensagem (ex.: "Cotação de Plano", "Validade Alterada").
    required String title,

    /// Corpo da mensagem (ex.: "O seu plano Pro foi renovado até 15/09/2026").
    required String body,

    /// Se a mensagem foi lida pelo dono do tenant.
    @Default(false) bool isRead,

    /// Data de criação.
    required DateTime createdAt,

    /// Data em que foi lida (null enquanto não lida).
    DateTime? readAt,
  }) = _AdminMessage;

  factory AdminMessage.fromJson(Map<String, dynamic> json) =>
      _$AdminMessageFromJson(json);
}
