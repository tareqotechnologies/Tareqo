// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_employee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StoreEmployee _$StoreEmployeeFromJson(Map<String, dynamic> json) =>
 _StoreEmployee(
 id: json['id'] as String,
 tenantId: json['tenantId'] as String,
 storeId: json['storeId'] as String,
 userId: json['userId'] as String,
 fullName: json['fullName'] as String,
 email: json['email'] as String,
 role:
 $enumDecodeNullable(_$EmployeeRoleEnumMap, json['role']) ??
 EmployeeRole.employee,
 isActive: json['isActive'] as bool? ?? true,
 );

Map<String, dynamic> _$StoreEmployeeToJson(_StoreEmployee instance) =>
 <String, dynamic>{
 'id': instance.id,
 'tenantId': instance.tenantId,
 'storeId': instance.storeId,
 'userId': instance.userId,
 'fullName': instance.fullName,
 'email': instance.email,
 'role': _$EmployeeRoleEnumMap[instance.role]!,
 'isActive': instance.isActive,
 };

const _$EmployeeRoleEnumMap = {
 EmployeeRole.manager: 'manager',
 EmployeeRole.employee: 'employee',
};
