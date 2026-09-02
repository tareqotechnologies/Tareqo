// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Quotation _$QuotationFromJson(Map<String, dynamic> json) => _Quotation(
  id: json['id'] as String,
  number: (json['number'] as num?)?.toInt() ?? 0,
  storeId: json['storeId'] as String,
  customerId: json['customerId'] as String,
  customerName: json['customerName'] as String,
  customerPhone: json['customerPhone'] as String? ?? '',
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => QuotationItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <QuotationItem>[],
  totalAmountCents: (json['totalAmountCents'] as num).toInt(),
  status:
      $enumDecodeNullable(_$QuotationStatusEnumMap, json['status']) ??
      QuotationStatus.draft,
  discountCents: (json['discountCents'] as num?)?.toInt() ?? 0,
  notes: json['notes'] as String? ?? '',
  validUntil: DateTime.parse(json['validUntil'] as String),
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  acceptedAt: json['acceptedAt'] == null
      ? null
      : DateTime.parse(json['acceptedAt'] as String),
  rejectedAt: json['rejectedAt'] == null
      ? null
      : DateTime.parse(json['rejectedAt'] as String),
  convertedSaleId: json['convertedSaleId'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$QuotationToJson(_Quotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'storeId': instance.storeId,
      'customerId': instance.customerId,
      'customerName': instance.customerName,
      'customerPhone': instance.customerPhone,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'totalAmountCents': instance.totalAmountCents,
      'status': _$QuotationStatusEnumMap[instance.status]!,
      'discountCents': instance.discountCents,
      'notes': instance.notes,
      'validUntil': instance.validUntil.toIso8601String(),
      'sentAt': instance.sentAt?.toIso8601String(),
      'acceptedAt': instance.acceptedAt?.toIso8601String(),
      'rejectedAt': instance.rejectedAt?.toIso8601String(),
      'convertedSaleId': instance.convertedSaleId,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$QuotationStatusEnumMap = {
  QuotationStatus.draft: 'draft',
  QuotationStatus.sent: 'sent',
  QuotationStatus.accepted: 'accepted',
  QuotationStatus.rejected: 'rejected',
  QuotationStatus.expired: 'expired',
  QuotationStatus.converted: 'converted',
};

_QuotationItem _$QuotationItemFromJson(Map<String, dynamic> json) =>
    _QuotationItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPriceCents: (json['unitPriceCents'] as num).toInt(),
    );

Map<String, dynamic> _$QuotationItemToJson(_QuotationItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'unitPriceCents': instance.unitPriceCents,
    };
