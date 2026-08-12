// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sale _$SaleFromJson(Map<String, dynamic> json) => _Sale(
  id: json['id'] as String,
  number: (json['number'] as num?)?.toInt() ?? 0,
  storeId: json['storeId'] as String? ?? 'st1',
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmountCents: (json['totalAmountCents'] as num).toInt(),
  paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
  dateTime: DateTime.parse(json['dateTime'] as String),
  status:
      $enumDecodeNullable(_$SaleStatusEnumMap, json['status']) ??
      SaleStatus.active,
  cancelledAt: json['cancelledAt'] == null
      ? null
      : DateTime.parse(json['cancelledAt'] as String),
);

Map<String, dynamic> _$SaleToJson(_Sale instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'storeId': instance.storeId,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'totalAmountCents': instance.totalAmountCents,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
  'dateTime': instance.dateTime.toIso8601String(),
  'status': _$SaleStatusEnumMap[instance.status]!,
  'cancelledAt': instance.cancelledAt?.toIso8601String(),
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.debitCard: 'debitCard',
  PaymentMethod.creditCard: 'creditCard',
  PaymentMethod.mPesa: 'mPesa',
  PaymentMethod.eMola: 'eMola',
  PaymentMethod.transfer: 'transfer',
};

const _$SaleStatusEnumMap = {
  SaleStatus.active: 'active',
  SaleStatus.cancelled: 'cancelled',
};
