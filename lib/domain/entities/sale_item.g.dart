// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SaleItem _$SaleItemFromJson(Map<String, dynamic> json) => _SaleItem(
  productId: json['productId'] as String,
  productName: json['productName'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPriceCents: (json['unitPriceCents'] as num).toInt(),
);

Map<String, dynamic> _$SaleItemToJson(_SaleItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'productName': instance.productName,
  'quantity': instance.quantity,
  'unitPriceCents': instance.unitPriceCents,
};
