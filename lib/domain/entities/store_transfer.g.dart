// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoreTransfer _$StoreTransferFromJson(Map<String, dynamic> json) =>
    _StoreTransfer(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 0,
      fromStoreId: json['fromStoreId'] as String,
      fromStoreName: json['fromStoreName'] as String,
      toStoreId: json['toStoreId'] as String,
      toStoreName: json['toStoreName'] as String,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => StoreTransferItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <StoreTransferItem>[],
      status:
          $enumDecodeNullable(_$TransferStatusEnumMap, json['status']) ??
          TransferStatus.pending,
      notes: json['notes'] as String? ?? '',
      shippedAt: json['shippedAt'] == null
          ? null
          : DateTime.parse(json['shippedAt'] as String),
      receivedAt: json['receivedAt'] == null
          ? null
          : DateTime.parse(json['receivedAt'] as String),
      authorizedByUserId: json['authorizedByUserId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StoreTransferToJson(_StoreTransfer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'fromStoreId': instance.fromStoreId,
      'fromStoreName': instance.fromStoreName,
      'toStoreId': instance.toStoreId,
      'toStoreName': instance.toStoreName,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'status': _$TransferStatusEnumMap[instance.status]!,
      'notes': instance.notes,
      'shippedAt': instance.shippedAt?.toIso8601String(),
      'receivedAt': instance.receivedAt?.toIso8601String(),
      'authorizedByUserId': instance.authorizedByUserId,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$TransferStatusEnumMap = {
  TransferStatus.pending: 'pending',
  TransferStatus.inTransit: 'inTransit',
  TransferStatus.received: 'received',
  TransferStatus.cancelled: 'cancelled',
};

_StoreTransferItem _$StoreTransferItemFromJson(Map<String, dynamic> json) =>
    _StoreTransferItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$StoreTransferItemToJson(_StoreTransferItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'quantity': instance.quantity,
    };
