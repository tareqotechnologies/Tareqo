// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_management.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeAttendance {

 String get id; String get storeId;/// Funcionário (SUJEITO) — UUID do auth.users.
 String get userId;/// Dia de trabalho no formato `YYYY-MM-DD` (chave de unicidade).
 String get workDate; DateTime get clockIn;/// null enquanto o funcionário está presente (sem saída registada).
 DateTime? get clockOut;/// Quem executou a acção (dono/gerente) — auth.uid() no servidor.
 String get recordedBy; DateTime get createdAt;
/// Create a copy of EmployeeAttendance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeAttendanceCopyWith<EmployeeAttendance> get copyWith => _$EmployeeAttendanceCopyWithImpl<EmployeeAttendance>(this as EmployeeAttendance, _$identity);

  /// Serializes this EmployeeAttendance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeAttendance&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workDate, workDate) || other.workDate == workDate)&&(identical(other.clockIn, clockIn) || other.clockIn == clockIn)&&(identical(other.clockOut, clockOut) || other.clockOut == clockOut)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,userId,workDate,clockIn,clockOut,recordedBy,createdAt);

@override
String toString() {
  return 'EmployeeAttendance(id: $id, storeId: $storeId, userId: $userId, workDate: $workDate, clockIn: $clockIn, clockOut: $clockOut, recordedBy: $recordedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EmployeeAttendanceCopyWith<$Res>  {
  factory $EmployeeAttendanceCopyWith(EmployeeAttendance value, $Res Function(EmployeeAttendance) _then) = _$EmployeeAttendanceCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String userId, String workDate, DateTime clockIn, DateTime? clockOut, String recordedBy, DateTime createdAt
});




}
/// @nodoc
class _$EmployeeAttendanceCopyWithImpl<$Res>
    implements $EmployeeAttendanceCopyWith<$Res> {
  _$EmployeeAttendanceCopyWithImpl(this._self, this._then);

  final EmployeeAttendance _self;
  final $Res Function(EmployeeAttendance) _then;

/// Create a copy of EmployeeAttendance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? userId = null,Object? workDate = null,Object? clockIn = null,Object? clockOut = freezed,Object? recordedBy = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workDate: null == workDate ? _self.workDate : workDate // ignore: cast_nullable_to_non_nullable
as String,clockIn: null == clockIn ? _self.clockIn : clockIn // ignore: cast_nullable_to_non_nullable
as DateTime,clockOut: freezed == clockOut ? _self.clockOut : clockOut // ignore: cast_nullable_to_non_nullable
as DateTime?,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeAttendance].
extension EmployeeAttendancePatterns on EmployeeAttendance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeAttendance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeAttendance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeAttendance value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeAttendance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeAttendance value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeAttendance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String userId,  String workDate,  DateTime clockIn,  DateTime? clockOut,  String recordedBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeAttendance() when $default != null:
return $default(_that.id,_that.storeId,_that.userId,_that.workDate,_that.clockIn,_that.clockOut,_that.recordedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String userId,  String workDate,  DateTime clockIn,  DateTime? clockOut,  String recordedBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _EmployeeAttendance():
return $default(_that.id,_that.storeId,_that.userId,_that.workDate,_that.clockIn,_that.clockOut,_that.recordedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String userId,  String workDate,  DateTime clockIn,  DateTime? clockOut,  String recordedBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeAttendance() when $default != null:
return $default(_that.id,_that.storeId,_that.userId,_that.workDate,_that.clockIn,_that.clockOut,_that.recordedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeAttendance implements EmployeeAttendance {
  const _EmployeeAttendance({required this.id, required this.storeId, required this.userId, required this.workDate, required this.clockIn, this.clockOut, this.recordedBy = '', required this.createdAt});
  factory _EmployeeAttendance.fromJson(Map<String, dynamic> json) => _$EmployeeAttendanceFromJson(json);

@override final  String id;
@override final  String storeId;
/// Funcionário (SUJEITO) — UUID do auth.users.
@override final  String userId;
/// Dia de trabalho no formato `YYYY-MM-DD` (chave de unicidade).
@override final  String workDate;
@override final  DateTime clockIn;
/// null enquanto o funcionário está presente (sem saída registada).
@override final  DateTime? clockOut;
/// Quem executou a acção (dono/gerente) — auth.uid() no servidor.
@override@JsonKey() final  String recordedBy;
@override final  DateTime createdAt;

/// Create a copy of EmployeeAttendance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeAttendanceCopyWith<_EmployeeAttendance> get copyWith => __$EmployeeAttendanceCopyWithImpl<_EmployeeAttendance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeAttendanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeAttendance&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.workDate, workDate) || other.workDate == workDate)&&(identical(other.clockIn, clockIn) || other.clockIn == clockIn)&&(identical(other.clockOut, clockOut) || other.clockOut == clockOut)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,userId,workDate,clockIn,clockOut,recordedBy,createdAt);

@override
String toString() {
  return 'EmployeeAttendance(id: $id, storeId: $storeId, userId: $userId, workDate: $workDate, clockIn: $clockIn, clockOut: $clockOut, recordedBy: $recordedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeeAttendanceCopyWith<$Res> implements $EmployeeAttendanceCopyWith<$Res> {
  factory _$EmployeeAttendanceCopyWith(_EmployeeAttendance value, $Res Function(_EmployeeAttendance) _then) = __$EmployeeAttendanceCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String userId, String workDate, DateTime clockIn, DateTime? clockOut, String recordedBy, DateTime createdAt
});




}
/// @nodoc
class __$EmployeeAttendanceCopyWithImpl<$Res>
    implements _$EmployeeAttendanceCopyWith<$Res> {
  __$EmployeeAttendanceCopyWithImpl(this._self, this._then);

  final _EmployeeAttendance _self;
  final $Res Function(_EmployeeAttendance) _then;

/// Create a copy of EmployeeAttendance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? userId = null,Object? workDate = null,Object? clockIn = null,Object? clockOut = freezed,Object? recordedBy = null,Object? createdAt = null,}) {
  return _then(_EmployeeAttendance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,workDate: null == workDate ? _self.workDate : workDate // ignore: cast_nullable_to_non_nullable
as String,clockIn: null == clockIn ? _self.clockIn : clockIn // ignore: cast_nullable_to_non_nullable
as DateTime,clockOut: freezed == clockOut ? _self.clockOut : clockOut // ignore: cast_nullable_to_non_nullable
as DateTime?,recordedBy: null == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$EmployeeCommissionRate {

 String get id; String get storeId; String get userId;/// Pontos base (500 = 5%). Validado ≥ 0 e ≤ 10000 (100%).
 int get rateBps; DateTime get createdAt;
/// Create a copy of EmployeeCommissionRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeCommissionRateCopyWith<EmployeeCommissionRate> get copyWith => _$EmployeeCommissionRateCopyWithImpl<EmployeeCommissionRate>(this as EmployeeCommissionRate, _$identity);

  /// Serializes this EmployeeCommissionRate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeCommissionRate&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,userId,rateBps,createdAt);

@override
String toString() {
  return 'EmployeeCommissionRate(id: $id, storeId: $storeId, userId: $userId, rateBps: $rateBps, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EmployeeCommissionRateCopyWith<$Res>  {
  factory $EmployeeCommissionRateCopyWith(EmployeeCommissionRate value, $Res Function(EmployeeCommissionRate) _then) = _$EmployeeCommissionRateCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String userId, int rateBps, DateTime createdAt
});




}
/// @nodoc
class _$EmployeeCommissionRateCopyWithImpl<$Res>
    implements $EmployeeCommissionRateCopyWith<$Res> {
  _$EmployeeCommissionRateCopyWithImpl(this._self, this._then);

  final EmployeeCommissionRate _self;
  final $Res Function(EmployeeCommissionRate) _then;

/// Create a copy of EmployeeCommissionRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? userId = null,Object? rateBps = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeCommissionRate].
extension EmployeeCommissionRatePatterns on EmployeeCommissionRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeCommissionRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeCommissionRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeCommissionRate value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeCommissionRate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeCommissionRate value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeCommissionRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String userId,  int rateBps,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeCommissionRate() when $default != null:
return $default(_that.id,_that.storeId,_that.userId,_that.rateBps,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String userId,  int rateBps,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _EmployeeCommissionRate():
return $default(_that.id,_that.storeId,_that.userId,_that.rateBps,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String userId,  int rateBps,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeCommissionRate() when $default != null:
return $default(_that.id,_that.storeId,_that.userId,_that.rateBps,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeCommissionRate implements EmployeeCommissionRate {
  const _EmployeeCommissionRate({required this.id, required this.storeId, required this.userId, required this.rateBps, required this.createdAt});
  factory _EmployeeCommissionRate.fromJson(Map<String, dynamic> json) => _$EmployeeCommissionRateFromJson(json);

@override final  String id;
@override final  String storeId;
@override final  String userId;
/// Pontos base (500 = 5%). Validado ≥ 0 e ≤ 10000 (100%).
@override final  int rateBps;
@override final  DateTime createdAt;

/// Create a copy of EmployeeCommissionRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeCommissionRateCopyWith<_EmployeeCommissionRate> get copyWith => __$EmployeeCommissionRateCopyWithImpl<_EmployeeCommissionRate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeCommissionRateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeCommissionRate&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,userId,rateBps,createdAt);

@override
String toString() {
  return 'EmployeeCommissionRate(id: $id, storeId: $storeId, userId: $userId, rateBps: $rateBps, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeeCommissionRateCopyWith<$Res> implements $EmployeeCommissionRateCopyWith<$Res> {
  factory _$EmployeeCommissionRateCopyWith(_EmployeeCommissionRate value, $Res Function(_EmployeeCommissionRate) _then) = __$EmployeeCommissionRateCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String userId, int rateBps, DateTime createdAt
});




}
/// @nodoc
class __$EmployeeCommissionRateCopyWithImpl<$Res>
    implements _$EmployeeCommissionRateCopyWith<$Res> {
  __$EmployeeCommissionRateCopyWithImpl(this._self, this._then);

  final _EmployeeCommissionRate _self;
  final $Res Function(_EmployeeCommissionRate) _then;

/// Create a copy of EmployeeCommissionRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? userId = null,Object? rateBps = null,Object? createdAt = null,}) {
  return _then(_EmployeeCommissionRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$EmployeeTarget {

 String get id; String get storeId; String get userId;/// Mês da meta no formato `YYYY-MM`.
 String get month;/// Meta de vendas em centavos.
 int get targetCents; DateTime get createdAt;
/// Create a copy of EmployeeTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeTargetCopyWith<EmployeeTarget> get copyWith => _$EmployeeTargetCopyWithImpl<EmployeeTarget>(this as EmployeeTarget, _$identity);

  /// Serializes this EmployeeTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeTarget&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.month, month) || other.month == month)&&(identical(other.targetCents, targetCents) || other.targetCents == targetCents)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,userId,month,targetCents,createdAt);

@override
String toString() {
  return 'EmployeeTarget(id: $id, storeId: $storeId, userId: $userId, month: $month, targetCents: $targetCents, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EmployeeTargetCopyWith<$Res>  {
  factory $EmployeeTargetCopyWith(EmployeeTarget value, $Res Function(EmployeeTarget) _then) = _$EmployeeTargetCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String userId, String month, int targetCents, DateTime createdAt
});




}
/// @nodoc
class _$EmployeeTargetCopyWithImpl<$Res>
    implements $EmployeeTargetCopyWith<$Res> {
  _$EmployeeTargetCopyWithImpl(this._self, this._then);

  final EmployeeTarget _self;
  final $Res Function(EmployeeTarget) _then;

/// Create a copy of EmployeeTarget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? userId = null,Object? month = null,Object? targetCents = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,targetCents: null == targetCents ? _self.targetCents : targetCents // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeTarget].
extension EmployeeTargetPatterns on EmployeeTarget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeTarget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeTarget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeTarget value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeTarget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeTarget value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeTarget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String userId,  String month,  int targetCents,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeTarget() when $default != null:
return $default(_that.id,_that.storeId,_that.userId,_that.month,_that.targetCents,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String userId,  String month,  int targetCents,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _EmployeeTarget():
return $default(_that.id,_that.storeId,_that.userId,_that.month,_that.targetCents,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String userId,  String month,  int targetCents,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeTarget() when $default != null:
return $default(_that.id,_that.storeId,_that.userId,_that.month,_that.targetCents,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeTarget implements EmployeeTarget {
  const _EmployeeTarget({required this.id, required this.storeId, required this.userId, required this.month, required this.targetCents, required this.createdAt});
  factory _EmployeeTarget.fromJson(Map<String, dynamic> json) => _$EmployeeTargetFromJson(json);

@override final  String id;
@override final  String storeId;
@override final  String userId;
/// Mês da meta no formato `YYYY-MM`.
@override final  String month;
/// Meta de vendas em centavos.
@override final  int targetCents;
@override final  DateTime createdAt;

/// Create a copy of EmployeeTarget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeTargetCopyWith<_EmployeeTarget> get copyWith => __$EmployeeTargetCopyWithImpl<_EmployeeTarget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeTargetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeTarget&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.month, month) || other.month == month)&&(identical(other.targetCents, targetCents) || other.targetCents == targetCents)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,userId,month,targetCents,createdAt);

@override
String toString() {
  return 'EmployeeTarget(id: $id, storeId: $storeId, userId: $userId, month: $month, targetCents: $targetCents, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeeTargetCopyWith<$Res> implements $EmployeeTargetCopyWith<$Res> {
  factory _$EmployeeTargetCopyWith(_EmployeeTarget value, $Res Function(_EmployeeTarget) _then) = __$EmployeeTargetCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String userId, String month, int targetCents, DateTime createdAt
});




}
/// @nodoc
class __$EmployeeTargetCopyWithImpl<$Res>
    implements _$EmployeeTargetCopyWith<$Res> {
  __$EmployeeTargetCopyWithImpl(this._self, this._then);

  final _EmployeeTarget _self;
  final $Res Function(_EmployeeTarget) _then;

/// Create a copy of EmployeeTarget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? userId = null,Object? month = null,Object? targetCents = null,Object? createdAt = null,}) {
  return _then(_EmployeeTarget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,month: null == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as String,targetCents: null == targetCents ? _self.targetCents : targetCents // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$EmployeeCommissionSummaryEntry {

 String get userId;/// Nome do funcionário (join com store_employees).
 String get fullName;/// Vendas ATIVAS do funcionário na loja no mês (centavos).
 int get salesCents;/// Taxa cadastrada em pontos base (0 = sem taxa → comissão 0).
 int get rateBps;/// Comissão calculada = salesCents × rateBps / 10000 (centavos).
 int get commissionCents;
/// Create a copy of EmployeeCommissionSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeCommissionSummaryEntryCopyWith<EmployeeCommissionSummaryEntry> get copyWith => _$EmployeeCommissionSummaryEntryCopyWithImpl<EmployeeCommissionSummaryEntry>(this as EmployeeCommissionSummaryEntry, _$identity);

  /// Serializes this EmployeeCommissionSummaryEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeCommissionSummaryEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.salesCents, salesCents) || other.salesCents == salesCents)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.commissionCents, commissionCents) || other.commissionCents == commissionCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,salesCents,rateBps,commissionCents);

@override
String toString() {
  return 'EmployeeCommissionSummaryEntry(userId: $userId, fullName: $fullName, salesCents: $salesCents, rateBps: $rateBps, commissionCents: $commissionCents)';
}


}

/// @nodoc
abstract mixin class $EmployeeCommissionSummaryEntryCopyWith<$Res>  {
  factory $EmployeeCommissionSummaryEntryCopyWith(EmployeeCommissionSummaryEntry value, $Res Function(EmployeeCommissionSummaryEntry) _then) = _$EmployeeCommissionSummaryEntryCopyWithImpl;
@useResult
$Res call({
 String userId, String fullName, int salesCents, int rateBps, int commissionCents
});




}
/// @nodoc
class _$EmployeeCommissionSummaryEntryCopyWithImpl<$Res>
    implements $EmployeeCommissionSummaryEntryCopyWith<$Res> {
  _$EmployeeCommissionSummaryEntryCopyWithImpl(this._self, this._then);

  final EmployeeCommissionSummaryEntry _self;
  final $Res Function(EmployeeCommissionSummaryEntry) _then;

/// Create a copy of EmployeeCommissionSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? salesCents = null,Object? rateBps = null,Object? commissionCents = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,salesCents: null == salesCents ? _self.salesCents : salesCents // ignore: cast_nullable_to_non_nullable
as int,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,commissionCents: null == commissionCents ? _self.commissionCents : commissionCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeCommissionSummaryEntry].
extension EmployeeCommissionSummaryEntryPatterns on EmployeeCommissionSummaryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeCommissionSummaryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeCommissionSummaryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeCommissionSummaryEntry value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeCommissionSummaryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeCommissionSummaryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeCommissionSummaryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String fullName,  int salesCents,  int rateBps,  int commissionCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeCommissionSummaryEntry() when $default != null:
return $default(_that.userId,_that.fullName,_that.salesCents,_that.rateBps,_that.commissionCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String fullName,  int salesCents,  int rateBps,  int commissionCents)  $default,) {final _that = this;
switch (_that) {
case _EmployeeCommissionSummaryEntry():
return $default(_that.userId,_that.fullName,_that.salesCents,_that.rateBps,_that.commissionCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String fullName,  int salesCents,  int rateBps,  int commissionCents)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeCommissionSummaryEntry() when $default != null:
return $default(_that.userId,_that.fullName,_that.salesCents,_that.rateBps,_that.commissionCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeCommissionSummaryEntry implements EmployeeCommissionSummaryEntry {
  const _EmployeeCommissionSummaryEntry({required this.userId, required this.fullName, required this.salesCents, this.rateBps = 0, required this.commissionCents});
  factory _EmployeeCommissionSummaryEntry.fromJson(Map<String, dynamic> json) => _$EmployeeCommissionSummaryEntryFromJson(json);

@override final  String userId;
/// Nome do funcionário (join com store_employees).
@override final  String fullName;
/// Vendas ATIVAS do funcionário na loja no mês (centavos).
@override final  int salesCents;
/// Taxa cadastrada em pontos base (0 = sem taxa → comissão 0).
@override@JsonKey() final  int rateBps;
/// Comissão calculada = salesCents × rateBps / 10000 (centavos).
@override final  int commissionCents;

/// Create a copy of EmployeeCommissionSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeCommissionSummaryEntryCopyWith<_EmployeeCommissionSummaryEntry> get copyWith => __$EmployeeCommissionSummaryEntryCopyWithImpl<_EmployeeCommissionSummaryEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeCommissionSummaryEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeCommissionSummaryEntry&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.salesCents, salesCents) || other.salesCents == salesCents)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.commissionCents, commissionCents) || other.commissionCents == commissionCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,fullName,salesCents,rateBps,commissionCents);

@override
String toString() {
  return 'EmployeeCommissionSummaryEntry(userId: $userId, fullName: $fullName, salesCents: $salesCents, rateBps: $rateBps, commissionCents: $commissionCents)';
}


}

/// @nodoc
abstract mixin class _$EmployeeCommissionSummaryEntryCopyWith<$Res> implements $EmployeeCommissionSummaryEntryCopyWith<$Res> {
  factory _$EmployeeCommissionSummaryEntryCopyWith(_EmployeeCommissionSummaryEntry value, $Res Function(_EmployeeCommissionSummaryEntry) _then) = __$EmployeeCommissionSummaryEntryCopyWithImpl;
@override @useResult
$Res call({
 String userId, String fullName, int salesCents, int rateBps, int commissionCents
});




}
/// @nodoc
class __$EmployeeCommissionSummaryEntryCopyWithImpl<$Res>
    implements _$EmployeeCommissionSummaryEntryCopyWith<$Res> {
  __$EmployeeCommissionSummaryEntryCopyWithImpl(this._self, this._then);

  final _EmployeeCommissionSummaryEntry _self;
  final $Res Function(_EmployeeCommissionSummaryEntry) _then;

/// Create a copy of EmployeeCommissionSummaryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? salesCents = null,Object? rateBps = null,Object? commissionCents = null,}) {
  return _then(_EmployeeCommissionSummaryEntry(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,salesCents: null == salesCents ? _self.salesCents : salesCents // ignore: cast_nullable_to_non_nullable
as int,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,commissionCents: null == commissionCents ? _self.commissionCents : commissionCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
