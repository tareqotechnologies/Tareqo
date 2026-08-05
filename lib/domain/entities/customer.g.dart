// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Customer _$CustomerFromJson(Map<String, dynamic> json) => _Customer(
  id: json['id'] as String,
  storeId: json['storeId'] as String? ?? 'st1',
  name: json['name'] as String,
  phone: json['phone'] as String? ?? '',
  email: json['email'] as String? ?? '',
);

Map<String, dynamic> _$CustomerToJson(_Customer instance) => <String, dynamic>{
  'id': instance.id,
  'storeId': instance.storeId,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
};
