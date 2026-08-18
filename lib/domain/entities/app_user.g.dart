// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
 id: json['id'] as String,
 email: json['email'] as String,
 fullName: json['fullName'] as String? ?? '',
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
 'id': instance.id,
 'email': instance.email,
 'fullName': instance.fullName,
};
