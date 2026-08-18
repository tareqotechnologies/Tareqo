// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_lot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StockLot _$StockLotFromJson(Map<String, dynamic> json) => _StockLot(
 id: json['id'] as String,
 storeId: json['storeId'] as String? ?? 'st1',
 productId: json['productId'] as String,
 entryDate: DateTime.parse(json['entryDate'] as String),
 expiryDate: json['expiryDate'] == null
 ? null
 : DateTime.parse(json['expiryDate'] as String),
 initialQuantity: (json['initialQuantity'] as num).toInt(),
 currentQuantity: (json['currentQuantity'] as num).toInt(),
 costPriceCents: (json['costPriceCents'] as num).toInt(),
);

Map<String, dynamic> _$StockLotToJson(_StockLot instance) => <String, dynamic>{
 'id': instance.id,
 'storeId': instance.storeId,
 'productId': instance.productId,
 'entryDate': instance.entryDate.toIso8601String(),
 'expiryDate': instance.expiryDate?.toIso8601String(),
 'initialQuantity': instance.initialQuantity,
 'currentQuantity': instance.currentQuantity,
 'costPriceCents': instance.costPriceCents,
};
