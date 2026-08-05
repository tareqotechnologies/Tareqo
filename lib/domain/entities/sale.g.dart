// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Sale _$SaleFromJson(Map<String, dynamic> json) => _Sale(
  id: json['id'] as String,
  storeId: json['storeId'] as String? ?? 'st1',
  items: (json['items'] as List<dynamic>)
      .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paymentMethod: $enumDecode(_$PaymentMethodEnumMap, json['paymentMethod']),
  dateTime: DateTime.parse(json['dateTime'] as String),
);

Map<String, dynamic> _$SaleToJson(_Sale instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'totalAmount': instance.totalAmount,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
  'dateTime': instance.dateTime.toIso8601String(),
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.debitCard: 'debitCard',
  PaymentMethod.creditCard: 'creditCard',
  PaymentMethod.pix: 'pix',
  PaymentMethod.transfer: 'transfer',
};
