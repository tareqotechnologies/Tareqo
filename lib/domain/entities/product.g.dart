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
  imagePath: json['imagePath'] as String? ?? '',
  purchasePriceCents: (json['purchasePriceCents'] as num).toInt(),
  salePriceCents: (json['salePriceCents'] as num).toInt(),
  stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
  barcode: json['barcode'] as String? ?? '',
  code: json['code'] as String? ?? '',
  vendaPorFracao: json['vendaPorFracao'] as bool? ?? false,
  unitLabel: json['unitLabel'] as String? ?? 'un',
  category: json['category'] as String? ?? '',
  isActive: json['isActive'] as bool? ?? true,
  type:
      $enumDecodeNullable(
        _$ProductTypeEnumMap,
        json['type'],
        unknownValue: ProductType.resale,
      ) ??
      ProductType.resale,
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'name': instance.name,
  'description': instance.description,
  'imagePath': instance.imagePath,
  'purchasePriceCents': instance.purchasePriceCents,
  'salePriceCents': instance.salePriceCents,
  'stockQuantity': instance.stockQuantity,
  'barcode': instance.barcode,
  'code': instance.code,
  'vendaPorFracao': instance.vendaPorFracao,
  'unitLabel': instance.unitLabel,
  'category': instance.category,
  'isActive': instance.isActive,
  'type': _$ProductTypeEnumMap[instance.type]!,
};

const _$ProductTypeEnumMap = {
  ProductType.rawMaterial: 'rawMaterial',
  ProductType.resale: 'resale',
  ProductType.manufactured: 'manufactured',
  ProductType.composite: 'composite',
  ProductType.packaging: 'packaging',
};
