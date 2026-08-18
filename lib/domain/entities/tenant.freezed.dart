// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tenant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Tenant {

 String get id; String get ownerUserId; String get businessName; String get planId; TenantStatus get status; String? get rejectionReason; DateTime? get approvedAt; DateTime get createdAt;/// Moeda padrão dos valores (BRL, USD, EUR, MZN) — escolhida pelo dono
/// no onboarding e alterável em Lojas → Ajustes. Novos tenants nascem
/// com MZN (mercado-alvo Moçambique).
 String get currencyCode;/// Idioma do aplicativo (`pt` ou `en`) — escolhido pelo dono.
 String get language;
/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantCopyWith<Tenant> get copyWith => _$TenantCopyWithImpl<Tenant>(this as Tenant, _$identity);

 /// Serializes this Tenant to a JSON map.
 Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is Tenant&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerUserId, ownerUserId) || other.ownerUserId == ownerUserId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerUserId,businessName,planId,status,rejectionReason,approvedAt,createdAt,currencyCode,language);

@override
String toString() {
 return 'Tenant(id: $id, ownerUserId: $ownerUserId, businessName: $businessName, planId: $planId, status: $status, rejectionReason: $rejectionReason, approvedAt: $approvedAt, createdAt: $createdAt, currencyCode: $currencyCode, language: $language)';
}


}

/// @nodoc
abstract mixin class $TenantCopyWith<$Res> {
 factory $TenantCopyWith(Tenant value, $Res Function(Tenant) _then) = _$TenantCopyWithImpl;
@useResult
$Res call({
 String id, String ownerUserId, String businessName, String planId, TenantStatus status, String? rejectionReason, DateTime? approvedAt, DateTime createdAt, String currencyCode, String language
});




}
/// @nodoc
class _$TenantCopyWithImpl<$Res>
 implements $TenantCopyWith<$Res> {
 _$TenantCopyWithImpl(this._self, this._then);

 final Tenant _self;
 final $Res Function(Tenant) _then;

/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ownerUserId = null,Object? businessName = null,Object? planId = null,Object? status = null,Object? rejectionReason = freezed,Object? approvedAt = freezed,Object? createdAt = null,Object? currencyCode = null,Object? language = null,}) {
 return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerUserId: null == ownerUserId ? _self.ownerUserId : ownerUserId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TenantStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
 ));
}

}


/// Adds pattern-matching-related methods to [Tenant].
extension TenantPatterns on Tenant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case final Subclass value:
/// return ...;
/// case _:
/// return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tenant value)? $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tenant() when $default != null:
return $default(_that);case _:
 return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case final Subclass value:
/// return ...;
/// case final Subclass2 value:
/// return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tenant value) $default,){
final _that = this;
switch (_that) {
case _Tenant():
return $default(_that);case _:
 throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case final Subclass value:
/// return ...;
/// case _:
/// return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tenant value)? $default,){
final _that = this;
switch (_that) {
case _Tenant() when $default != null:
return $default(_that);case _:
 return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case Subclass(:final field):
/// return ...;
/// case _:
/// return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, String ownerUserId, String businessName, String planId, TenantStatus status, String? rejectionReason, DateTime? approvedAt, DateTime createdAt, String currencyCode, String language)? $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tenant() when $default != null:
return $default(_that.id,_that.ownerUserId,_that.businessName,_that.planId,_that.status,_that.rejectionReason,_that.approvedAt,_that.createdAt,_that.currencyCode,_that.language);case _:
 return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case Subclass(:final field):
/// return ...;
/// case Subclass2(:final field2):
/// return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, String ownerUserId, String businessName, String planId, TenantStatus status, String? rejectionReason, DateTime? approvedAt, DateTime createdAt, String currencyCode, String language) $default,) {final _that = this;
switch (_that) {
case _Tenant():
return $default(_that.id,_that.ownerUserId,_that.businessName,_that.planId,_that.status,_that.rejectionReason,_that.approvedAt,_that.createdAt,_that.currencyCode,_that.language);case _:
 throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case Subclass(:final field):
/// return ...;
/// case _:
/// return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, String ownerUserId, String businessName, String planId, TenantStatus status, String? rejectionReason, DateTime? approvedAt, DateTime createdAt, String currencyCode, String language)? $default,) {final _that = this;
switch (_that) {
case _Tenant() when $default != null:
return $default(_that.id,_that.ownerUserId,_that.businessName,_that.planId,_that.status,_that.rejectionReason,_that.approvedAt,_that.createdAt,_that.currencyCode,_that.language);case _:
 return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tenant implements Tenant {
 const _Tenant({required this.id, required this.ownerUserId, required this.businessName, required this.planId, required this.status, this.rejectionReason, this.approvedAt, required this.createdAt, this.currencyCode = 'MZN', this.language = 'pt'});
 factory _Tenant.fromJson(Map<String, dynamic> json) => _$TenantFromJson(json);

@override final String id;
@override final String ownerUserId;
@override final String businessName;
@override final String planId;
@override final TenantStatus status;
@override final String? rejectionReason;
@override final DateTime? approvedAt;
@override final DateTime createdAt;
/// Moeda padrão dos valores (BRL, USD, EUR, MZN) — escolhida pelo dono
/// no onboarding e alterável em Lojas → Ajustes. Novos tenants nascem
/// com MZN (mercado-alvo Moçambique).
@override@JsonKey() final String currencyCode;
/// Idioma do aplicativo (`pt` ou `en`) — escolhido pelo dono.
@override@JsonKey() final String language;

/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantCopyWith<_Tenant> get copyWith => __$TenantCopyWithImpl<_Tenant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
 return _$TenantToJson(this, );
}

@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tenant&&(identical(other.id, id) || other.id == id)&&(identical(other.ownerUserId, ownerUserId) || other.ownerUserId == ownerUserId)&&(identical(other.businessName, businessName) || other.businessName == businessName)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.status, status) || other.status == status)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.approvedAt, approvedAt) || other.approvedAt == approvedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ownerUserId,businessName,planId,status,rejectionReason,approvedAt,createdAt,currencyCode,language);

@override
String toString() {
 return 'Tenant(id: $id, ownerUserId: $ownerUserId, businessName: $businessName, planId: $planId, status: $status, rejectionReason: $rejectionReason, approvedAt: $approvedAt, createdAt: $createdAt, currencyCode: $currencyCode, language: $language)';
}


}

/// @nodoc
abstract mixin class _$TenantCopyWith<$Res> implements $TenantCopyWith<$Res> {
 factory _$TenantCopyWith(_Tenant value, $Res Function(_Tenant) _then) = __$TenantCopyWithImpl;
@override @useResult
$Res call({
 String id, String ownerUserId, String businessName, String planId, TenantStatus status, String? rejectionReason, DateTime? approvedAt, DateTime createdAt, String currencyCode, String language
});




}
/// @nodoc
class __$TenantCopyWithImpl<$Res>
 implements _$TenantCopyWith<$Res> {
 __$TenantCopyWithImpl(this._self, this._then);

 final _Tenant _self;
 final $Res Function(_Tenant) _then;

/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ownerUserId = null,Object? businessName = null,Object? planId = null,Object? status = null,Object? rejectionReason = freezed,Object? approvedAt = freezed,Object? createdAt = null,Object? currencyCode = null,Object? language = null,}) {
 return _then(_Tenant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ownerUserId: null == ownerUserId ? _self.ownerUserId : ownerUserId // ignore: cast_nullable_to_non_nullable
as String,businessName: null == businessName ? _self.businessName : businessName // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TenantStatus,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,approvedAt: freezed == approvedAt ? _self.approvedAt : approvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
 ));
}


}

// dart format on
