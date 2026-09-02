// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AddOn _$AddOnFromJson(Map<String, dynamic> json) => _AddOn(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  category: $enumDecode(_$AddOnCategoryEnumMap, json['category']),
  priceMonthlyCents: (json['priceMonthlyCents'] as num).toInt(),
  iconName: json['iconName'] as String? ?? '',
  isAvailable: json['isAvailable'] as bool? ?? true,
);

Map<String, dynamic> _$AddOnToJson(_AddOn instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': _$AddOnCategoryEnumMap[instance.category]!,
  'priceMonthlyCents': instance.priceMonthlyCents,
  'iconName': instance.iconName,
  'isAvailable': instance.isAvailable,
};

const _$AddOnCategoryEnumMap = {
  AddOnCategory.invoice: 'invoice',
  AddOnCategory.quotation: 'quotation',
  AddOnCategory.reports: 'reports',
  AddOnCategory.employees: 'employees',
  AddOnCategory.multiStore: 'multiStore',
  AddOnCategory.payments: 'payments',
};

_TenantAddOn _$TenantAddOnFromJson(Map<String, dynamic> json) => _TenantAddOn(
  id: json['id'] as String,
  tenantId: json['tenantId'] as String,
  addOnId: json['addOnId'] as String,
  activatedAt: DateTime.parse(json['activatedAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$TenantAddOnToJson(_TenantAddOn instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenantId': instance.tenantId,
      'addOnId': instance.addOnId,
      'activatedAt': instance.activatedAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'isActive': instance.isActive,
    };
