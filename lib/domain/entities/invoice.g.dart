// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invoice _$InvoiceFromJson(Map<String, dynamic> json) => _Invoice(
  id: json['id'] as String,
  number: (json['number'] as num?)?.toInt() ?? 0,
  tenantId: json['tenantId'] as String,
  planId: json['planId'] as String,
  amountCents: (json['amountCents'] as num).toInt(),
  status:
      $enumDecodeNullable(_$InvoiceStatusEnumMap, json['status']) ??
      InvoiceStatus.pending,
  dueDate: DateTime.parse(json['dueDate'] as String),
  period: json['period'] as String? ?? '',
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  notes: json['notes'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$InvoiceToJson(_Invoice instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'tenantId': instance.tenantId,
  'planId': instance.planId,
  'amountCents': instance.amountCents,
  'status': _$InvoiceStatusEnumMap[instance.status]!,
  'dueDate': instance.dueDate.toIso8601String(),
  'period': instance.period,
  'paidAt': instance.paidAt?.toIso8601String(),
  'notes': instance.notes,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$InvoiceStatusEnumMap = {
  InvoiceStatus.pending: 'pending',
  InvoiceStatus.paid: 'paid',
  InvoiceStatus.expired: 'expired',
  InvoiceStatus.cancelled: 'cancelled',
};
