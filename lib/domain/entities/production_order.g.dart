// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductionItem _$ProductionItemFromJson(Map<String, dynamic> json) =>
    _ProductionItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unitCostCents: (json['unitCostCents'] as num).toInt(),
    );

Map<String, dynamic> _$ProductionItemToJson(_ProductionItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'unitCostCents': instance.unitCostCents,
    };

_ProductionOrder _$ProductionOrderFromJson(Map<String, dynamic> json) =>
    _ProductionOrder(
      id: json['id'] as String,
      storeId: json['storeId'] as String? ?? 'st1',
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      recipeId: json['recipeId'] as String?,
      costPriceCents: (json['costPriceCents'] as num).toInt(),
      totalCostCents: (json['totalCostCents'] as num).toInt(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      items: (json['items'] as List<dynamic>)
          .map((e) => ProductionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ProductionOrderToJson(_ProductionOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
      'recipeId': instance.recipeId,
      'costPriceCents': instance.costPriceCents,
      'totalCostCents': instance.totalCostCents,
      'dateTime': instance.dateTime.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
