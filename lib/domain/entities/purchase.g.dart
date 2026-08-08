// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PurchaseItem _$PurchaseItemFromJson(Map<String, dynamic> json) =>
    _PurchaseItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitPriceCents: (json['unitPriceCents'] as num).toInt(),
    );

Map<String, dynamic> _$PurchaseItemToJson(_PurchaseItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'unitPriceCents': instance.unitPriceCents,
    };

_Purchase _$PurchaseFromJson(Map<String, dynamic> json) => _Purchase(
  id: json['id'] as String,
  number: (json['number'] as num?)?.toInt() ?? 0,
  storeId: json['storeId'] as String? ?? 'st1',
  supplierName: json['supplierName'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmountCents: (json['totalAmountCents'] as num).toInt(),
  paymentMethod:
      $enumDecodeNullable(_$PaymentMethodEnumMap, json['paymentMethod']) ??
      PaymentMethod.cash,
  dateTime: DateTime.parse(json['dateTime'] as String),
);

Map<String, dynamic> _$PurchaseToJson(_Purchase instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'storeId': instance.storeId,
  'supplierName': instance.supplierName,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'totalAmountCents': instance.totalAmountCents,
  'paymentMethod': _$PaymentMethodEnumMap[instance.paymentMethod]!,
  'dateTime': instance.dateTime.toIso8601String(),
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.debitCard: 'debitCard',
  PaymentMethod.creditCard: 'creditCard',
  PaymentMethod.mPesa: 'mPesa',
  PaymentMethod.eMola: 'eMola',
  PaymentMethod.transfer: 'transfer',
};
