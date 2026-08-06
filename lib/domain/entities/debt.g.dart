// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Debt _$DebtFromJson(Map<String, dynamic> json) => _Debt(
  id: json['id'] as String,
  storeId: json['storeId'] as String? ?? 'st1',
  personName: json['personName'] as String,
  amountCents: (json['amountCents'] as num).toInt(),
  dueDate: DateTime.parse(json['dueDate'] as String),
  isCustomerDebt: json['isCustomerDebt'] as bool,
  isPaid: json['isPaid'] as bool? ?? false,
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  customerId: json['customerId'] as String?,
);

Map<String, dynamic> _$DebtToJson(_Debt instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'personName': instance.personName,
  'amountCents': instance.amountCents,
  'dueDate': instance.dueDate.toIso8601String(),
  'isCustomerDebt': instance.isCustomerDebt,
  'isPaid': instance.isPaid,
  'paidAt': instance.paidAt?.toIso8601String(),
  'customerId': instance.customerId,
};
