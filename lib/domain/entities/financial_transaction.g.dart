// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FinancialTransaction _$FinancialTransactionFromJson(
  Map<String, dynamic> json,
) => _FinancialTransaction(
  id: json['id'] as String,
  storeId: json['storeId'] as String? ?? 'st1',
  description: json['description'] as String,
  amount: (json['amount'] as num).toDouble(),
  type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
  category: json['category'] as String,
  date: DateTime.parse(json['date'] as String),
  status:
      $enumDecodeNullable(_$TransactionStatusEnumMap, json['status']) ??
      TransactionStatus.paid,
  debtId: json['debtId'] as String?,
);

Map<String, dynamic> _$FinancialTransactionToJson(
  _FinancialTransaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'description': instance.description,
  'amount': instance.amount,
  'type': _$TransactionTypeEnumMap[instance.type]!,
  'category': instance.category,
  'date': instance.date.toIso8601String(),
  'status': _$TransactionStatusEnumMap[instance.status]!,
  'debtId': instance.debtId,
};

const _$TransactionTypeEnumMap = {
  TransactionType.income: 'income',
  TransactionType.expense: 'expense',
};

const _$TransactionStatusEnumMap = {
  TransactionStatus.paid: 'paid',
  TransactionStatus.pending: 'pending',
};
