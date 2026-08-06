// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Plan _$PlanFromJson(Map<String, dynamic> json) => _Plan(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  priceMonthlyCents: (json['priceMonthlyCents'] as num?)?.toInt() ?? 0,
  maxStores: (json['maxStores'] as num?)?.toInt() ?? 1,
  maxEmployees: (json['maxEmployees'] as num?)?.toInt() ?? 1,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$PlanToJson(_Plan instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'priceMonthlyCents': instance.priceMonthlyCents,
  'maxStores': instance.maxStores,
  'maxEmployees': instance.maxEmployees,
  'isActive': instance.isActive,
};
