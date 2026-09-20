import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_notification.freezed.dart';
part 'invoice_notification.g.dart';

/// Tipo de notificação de factura.
enum InvoiceNotificationType {
  /// Factura gerada (renovação mensal).
  invoiceGenerated,

  /// Factura está para vencer (7 dias antes).
  invoiceDueSoon,

  /// Factura expirou (não foi paga).
  invoiceExpired,

  /// Factura marcada como paga.
  invoicePaid,

  /// Add-on está para expirar (7, 3 ou 1 dia antes).
  addOnExpiringSoon,

  /// Add-on expirou.
  addOnExpired,
}

/// Notificação in-app para o dono do tenant quando uma factura é gerada
/// ou sofre alteração de estado.
///
/// Cada notificação é ligada a um tenant e, opcionalmente, a uma factura
/// específica. O dono vê as notificações no dashboard e pode marcá-las
/// como lidas.
@freezed
abstract class InvoiceNotification with _$InvoiceNotification {
  const factory InvoiceNotification({
    required String id,

    /// Tenant destinatário da notificação.
    required String tenantId,

    /// Factura associada (pode ser null para notificações gerais).
    String? invoiceId,

    /// Tipo da notificação.
    required InvoiceNotificationType type,

    /// Título da notificação (ex.: "Nova factura gerada").
    required String title,

    /// Corpo da notificação (ex.: "Factura INV-00001 no valor de 5000 MZN").
    ///
    /// Pré-formatado em PT no momento da criação (dado armazenado). Quando
    /// [bodyParams] está presente, a exibição reconstrói o corpo localizado
    /// a partir dos parâmetros; [body] permanece como fallback legado.
    required String body,

    /// Parâmetros de interpolação do corpo, para localização na exibição.
    ///
    /// Chaves por tipo (todas String; `days` chega como String numérica e
    /// é convertida na exibição):
    /// - invoiceGenerated: `period`, `amount`, `currency`, `dueDate`
    /// - invoiceDueSoon:   `period`, `amount`, `currency`, `days`
    /// - invoiceExpired:   `period`, `amount`, `currency`
    /// - invoicePaid:      `period`, `amount`, `currency`
    /// - addOnExpiringSoon: `addonName`, `days`, `date`
    /// - addOnExpired:      `addonName`, `date`
    ///
    /// Null ⇒ notificação legada: a exibição mostra [body] como está.
    Map<String, String>? bodyParams,

    /// Se a notificação foi lida pelo dono.
    @Default(false) bool isRead,

    /// Data de criação.
    required DateTime createdAt,

    /// Data em que foi lida (null enquanto não lida).
    DateTime? readAt,
  }) = _InvoiceNotification;

  factory InvoiceNotification.fromJson(Map<String, dynamic> json) =>
      _$InvoiceNotificationFromJson(json);
}
