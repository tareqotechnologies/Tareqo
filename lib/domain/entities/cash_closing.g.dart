// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_closing.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CashClosing _$CashClosingFromJson(Map<String, dynamic> json) => _CashClosing(
 id: json['id'] as String,
 storeId: json['storeId'] as String? ?? 'st1',
 day: DateTime.parse(json['day'] as String),
 totalSalesCents: (json['totalSalesCents'] as num).toInt(),
 expectedCashCents: (json['expectedCashCents'] as num).toInt(),
 countedCashCents: (json['countedCashCents'] as num).toInt(),
 salesByMethodCents:
 (json['salesByMethodCents'] as Map<String, dynamic>?)?.map(
 (k, e) => MapEntry(k, (e as num).toInt()),
 ) ??
 const {},
 closedAt: DateTime.parse(json['closedAt'] as String),
);

Map<String, dynamic> _$CashClosingToJson(_CashClosing instance) =>
 <String, dynamic>{
 'id': instance.id,
 'storeId': instance.storeId,
 'day': instance.day.toIso8601String(),
 'totalSalesCents': instance.totalSalesCents,
 'expectedCashCents': instance.expectedCashCents,
 'countedCashCents': instance.countedCashCents,
 'salesByMethodCents': instance.salesByMethodCents,
 'closedAt': instance.closedAt.toIso8601String(),
 };
