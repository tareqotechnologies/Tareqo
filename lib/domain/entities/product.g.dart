// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  storeId: json['storeId'] as String? ?? 'st1',
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  purchasePrice: (json['purchasePrice'] as num).toDouble(),
  salePrice: (json['salePrice'] as num).toDouble(),
  stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'name': instance.name,
  'description': instance.description,
  'purchasePrice': instance.purchasePrice,
  'salePrice': instance.salePrice,
  'stockQuantity': instance.stockQuantity,
};
