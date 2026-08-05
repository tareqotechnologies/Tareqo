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
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );

Map<String, dynamic> _$PurchaseItemToJson(_PurchaseItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'unitPrice': instance.unitPrice,
    };

_Purchase _$PurchaseFromJson(Map<String, dynamic> json) => _Purchase(
  id: json['id'] as String,
  storeId: json['storeId'] as String? ?? 'st1',
  supplierName: json['supplierName'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  dateTime: DateTime.parse(json['dateTime'] as String),
);

Map<String, dynamic> _$PurchaseToJson(_Purchase instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'supplierName': instance.supplierName,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'totalAmount': instance.totalAmount,
  'dateTime': instance.dateTime.toIso8601String(),
};
