// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_employee.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoreEmployee {

 String get id; String get tenantId; String get storeId; String get userId; String get fullName; String get email; EmployeeRole get role;/// Vínculo ATIVO? `false` = funcionário desativado (conta suspensa).
 bool get isActive;
/// Create a copy of StoreEmployee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreEmployeeCopyWith<StoreEmployee> get copyWith => _$StoreEmployeeCopyWithImpl<StoreEmployee>(this as StoreEmployee, _$identity);

  /// Serializes this StoreEmployee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreEmployee&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,storeId,userId,fullName,email,role,isActive);

@override
String toString() {
  return 'StoreEmployee(id: $id, tenantId: $tenantId, storeId: $storeId, userId: $userId, fullName: $fullName, email: $email, role: $role, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $StoreEmployeeCopyWith<$Res>  {
  factory $StoreEmployeeCopyWith(StoreEmployee value, $Res Function(StoreEmployee) _then) = _$StoreEmployeeCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String storeId, String userId, String fullName, String email, EmployeeRole role, bool isActive
});




}
/// @nodoc
class _$StoreEmployeeCopyWithImpl<$Res>
    implements $StoreEmployeeCopyWith<$Res> {
  _$StoreEmployeeCopyWithImpl(this._self, this._then);

  final StoreEmployee _self;
  final $Res Function(StoreEmployee) _then;

/// Create a copy of StoreEmployee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? storeId = null,Object? userId = null,Object? fullName = null,Object? email = null,Object? role = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as EmployeeRole,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StoreEmployee].
extension StoreEmployeePatterns on StoreEmployee {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreEmployee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreEmployee() when $default != null:
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
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreEmployee value)  $default,){
final _that = this;
switch (_that) {
case _StoreEmployee():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreEmployee value)?  $default,){
final _that = this;
switch (_that) {
case _StoreEmployee() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String storeId,  String userId,  String fullName,  String email,  EmployeeRole role,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreEmployee() when $default != null:
return $default(_that.id,_that.tenantId,_that.storeId,_that.userId,_that.fullName,_that.email,_that.role,_that.isActive);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String storeId,  String userId,  String fullName,  String email,  EmployeeRole role,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _StoreEmployee():
return $default(_that.id,_that.tenantId,_that.storeId,_that.userId,_that.fullName,_that.email,_that.role,_that.isActive);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String storeId,  String userId,  String fullName,  String email,  EmployeeRole role,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _StoreEmployee() when $default != null:
return $default(_that.id,_that.tenantId,_that.storeId,_that.userId,_that.fullName,_that.email,_that.role,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoreEmployee implements StoreEmployee {
  const _StoreEmployee({required this.id, required this.tenantId, required this.storeId, required this.userId, required this.fullName, required this.email, this.role = EmployeeRole.employee, this.isActive = true});
  factory _StoreEmployee.fromJson(Map<String, dynamic> json) => _$StoreEmployeeFromJson(json);

@override final  String id;
@override final  String tenantId;
@override final  String storeId;
@override final  String userId;
@override final  String fullName;
@override final  String email;
@override@JsonKey() final  EmployeeRole role;
/// Vínculo ATIVO? `false` = funcionário desativado (conta suspensa).
@override@JsonKey() final  bool isActive;

/// Create a copy of StoreEmployee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreEmployeeCopyWith<_StoreEmployee> get copyWith => __$StoreEmployeeCopyWithImpl<_StoreEmployee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoreEmployeeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreEmployee&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,storeId,userId,fullName,email,role,isActive);

@override
String toString() {
  return 'StoreEmployee(id: $id, tenantId: $tenantId, storeId: $storeId, userId: $userId, fullName: $fullName, email: $email, role: $role, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$StoreEmployeeCopyWith<$Res> implements $StoreEmployeeCopyWith<$Res> {
  factory _$StoreEmployeeCopyWith(_StoreEmployee value, $Res Function(_StoreEmployee) _then) = __$StoreEmployeeCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String storeId, String userId, String fullName, String email, EmployeeRole role, bool isActive
});




}
/// @nodoc
class __$StoreEmployeeCopyWithImpl<$Res>
    implements _$StoreEmployeeCopyWith<$Res> {
  __$StoreEmployeeCopyWithImpl(this._self, this._then);

  final _StoreEmployee _self;
  final $Res Function(_StoreEmployee) _then;

/// Create a copy of StoreEmployee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? storeId = null,Object? userId = null,Object? fullName = null,Object? email = null,Object? role = null,Object? isActive = null,}) {
  return _then(_StoreEmployee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as EmployeeRole,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
