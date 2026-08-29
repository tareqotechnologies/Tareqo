// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdminMessage _$AdminMessageFromJson(Map<String, dynamic> json) =>
    _AdminMessage(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      type: $enumDecode(_$AdminMessageTypeEnumMap, json['type']),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] == null
          ? null
          : DateTime.parse(json['readAt'] as String),
    );

Map<String, dynamic> _$AdminMessageToJson(_AdminMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'type': _$AdminMessageTypeEnumMap[instance.type]!,
      'title': instance.title,
      'body': instance.body,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
      'readAt': instance.readAt?.toIso8601String(),
    };

const _$AdminMessageTypeEnumMap = {
  AdminMessageType.billingQuote: 'billingQuote',
  AdminMessageType.planExpiryChange: 'planExpiryChange',
  AdminMessageType.planExpiringSoon: 'planExpiringSoon',
  AdminMessageType.general: 'general',
};
