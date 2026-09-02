// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_reconciliation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentReconciliation _$PaymentReconciliationFromJson(
  Map<String, dynamic> json,
) => _PaymentReconciliation(
  id: json['id'] as String,
  provider: $enumDecode(_$MobileMoneyProviderEnumMap, json['provider']),
  phone: json['phone'] as String,
  confirmationCode: json['confirmationCode'] as String? ?? '',
  amountCents: (json['amountCents'] as num).toInt(),
  status:
      $enumDecodeNullable(_$MobileMoneyStatusEnumMap, json['status']) ??
      MobileMoneyStatus.pending,
  saleId: json['saleId'] as String?,
  quotationId: json['quotationId'] as String?,
  customInvoiceId: json['customInvoiceId'] as String?,
  notes: json['notes'] as String? ?? '',
  rawData: json['rawData'] as String? ?? '',
  createdAt: DateTime.parse(json['createdAt'] as String),
  reconciledAt: json['reconciledAt'] == null
      ? null
      : DateTime.parse(json['reconciledAt'] as String),
);

Map<String, dynamic> _$PaymentReconciliationToJson(
  _PaymentReconciliation instance,
) => <String, dynamic>{
  'id': instance.id,
  'provider': _$MobileMoneyProviderEnumMap[instance.provider]!,
  'phone': instance.phone,
  'confirmationCode': instance.confirmationCode,
  'amountCents': instance.amountCents,
  'status': _$MobileMoneyStatusEnumMap[instance.status]!,
  'saleId': instance.saleId,
  'quotationId': instance.quotationId,
  'customInvoiceId': instance.customInvoiceId,
  'notes': instance.notes,
  'rawData': instance.rawData,
  'createdAt': instance.createdAt.toIso8601String(),
  'reconciledAt': instance.reconciledAt?.toIso8601String(),
};

const _$MobileMoneyProviderEnumMap = {
  MobileMoneyProvider.mPesa: 'mPesa',
  MobileMoneyProvider.eMola: 'eMola',
};

const _$MobileMoneyStatusEnumMap = {
  MobileMoneyStatus.pending: 'pending',
  MobileMoneyStatus.confirmed: 'confirmed',
  MobileMoneyStatus.failed: 'failed',
  MobileMoneyStatus.reconciled: 'reconciled',
};
