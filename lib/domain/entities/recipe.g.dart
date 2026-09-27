// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeItem _$RecipeItemFromJson(Map<String, dynamic> json) => _RecipeItem(
  productId: json['productId'] as String,
  quantity: (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$RecipeItemToJson(_RecipeItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
    };

_Recipe _$RecipeFromJson(Map<String, dynamic> json) => _Recipe(
  id: json['id'] as String,
  storeId: json['storeId'] as String? ?? 'st1',
  productId: json['productId'] as String,
  yieldQuantity: (json['yieldQuantity'] as num).toInt(),
  items: (json['items'] as List<dynamic>)
      .map((e) => RecipeItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RecipeToJson(_Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'productId': instance.productId,
  'yieldQuantity': instance.yieldQuantity,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
