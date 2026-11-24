// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_barcode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductBarcode _$ProductBarcodeFromJson(Map<String, dynamic> json) =>
    _ProductBarcode(
      id: json['id'] as String,
      storeId: json['storeId'] as String? ?? 'st1',
      productId: json['productId'] as String,
      barcode: json['barcode'] as String,
      qtyFactor: (json['qtyFactor'] as num?)?.toInt() ?? 1,
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$ProductBarcodeToJson(_ProductBarcode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storeId': instance.storeId,
      'productId': instance.productId,
      'barcode': instance.barcode,
      'qtyFactor': instance.qtyFactor,
      'description': instance.description,
      'isActive': instance.isActive,
    };
