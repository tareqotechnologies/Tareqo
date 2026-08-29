// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InvoiceNotification _$InvoiceNotificationFromJson(Map<String, dynamic> json) =>
    _InvoiceNotification(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      invoiceId: json['invoiceId'] as String?,
      type: $enumDecode(_$InvoiceNotificationTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$InvoiceNotificationToJson(
  _InvoiceNotification instance,
) => <String, dynamic>{
  'id': instance.id,
  'tenantId': instance.tenantId,
  'invoiceId': instance.invoiceId,
  'type': _$InvoiceNotificationTypeEnumMap[instance.type]!,
  'title': instance.title,
  'body': instance.body,
  'isRead': instance.isRead,
  'createdAt': instance.createdAt.toIso8601String(),
  'readAt': instance.readAt?.toIso8601String(),
};

const _$InvoiceNotificationTypeEnumMap = {
  InvoiceNotificationType.invoiceGenerated: 'invoiceGenerated',
  InvoiceNotificationType.invoiceDueSoon: 'invoiceDueSoon',
  InvoiceNotificationType.invoiceExpired: 'invoiceExpired',
  InvoiceNotificationType.invoicePaid: 'invoicePaid',
};
