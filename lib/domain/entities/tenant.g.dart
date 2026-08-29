// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tenant _$TenantFromJson(Map<String, dynamic> json) => _Tenant(
  id: json['id'] as String,
  ownerUserId: json['ownerUserId'] as String,
  businessName: json['businessName'] as String,
  planId: json['planId'] as String,
  status: $enumDecode(_$TenantStatusEnumMap, json['status']),
  rejectionReason: json['rejectionReason'] as String?,
  approvedAt: json['approvedAt'] == null
      ? null
      : DateTime.parse(json['approvedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  planExpiresAt: json['planExpiresAt'] == null
      ? null
      : DateTime.parse(json['planExpiresAt'] as String),
  nextInvoiceAt: json['nextInvoiceAt'] == null
      ? null
      : DateTime.parse(json['nextInvoiceAt'] as String),
  currencyCode: json['currencyCode'] as String? ?? 'MZN',
  language: json['language'] as String? ?? 'pt',
);

Map<String, dynamic> _$TenantToJson(_Tenant instance) => <String, dynamic>{
  'id': instance.id,
  'ownerUserId': instance.ownerUserId,
  'businessName': instance.businessName,
  'planId': instance.planId,
  'status': _$TenantStatusEnumMap[instance.status]!,
  'rejectionReason': instance.rejectionReason,
  'approvedAt': instance.approvedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'planExpiresAt': instance.planExpiresAt?.toIso8601String(),
  'nextInvoiceAt': instance.nextInvoiceAt?.toIso8601String(),
  'currencyCode': instance.currencyCode,
  'language': instance.language,
};

const _$TenantStatusEnumMap = {
  TenantStatus.pending: 'pending',
  TenantStatus.approved: 'approved',
  TenantStatus.rejected: 'rejected',
};
