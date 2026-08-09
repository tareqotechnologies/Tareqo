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
  purchasePriceCents: (json['purchasePriceCents'] as num).toInt(),
  salePriceCents: (json['salePriceCents'] as num).toInt(),
  stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
  code: json['code'] as String? ?? '',
  vendaPorFracao: json['vendaPorFracao'] as bool? ?? false,
  unitLabel: json['unitLabel'] as String? ?? 'un',
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'name': instance.name,
  'description': instance.description,
  'purchasePriceCents': instance.purchasePriceCents,
  'salePriceCents': instance.salePriceCents,
  'stockQuantity': instance.stockQuantity,
  'code': instance.code,
  'vendaPorFracao': instance.vendaPorFracao,
  'unitLabel': instance.unitLabel,
};
