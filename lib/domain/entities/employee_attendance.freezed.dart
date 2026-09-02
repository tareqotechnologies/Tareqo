// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_attendance.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployeeAttendance {

 String get id; String get employeeId; String get storeId;/// Hora de entrada.
 DateTime get clockIn;/// Hora de saída (null se ainda não saiu).
 DateTime? get clockOut;/// Total de minutos trabalhados (calculado ao registar saída).
 int get totalMinutes;/// Se o registo foi editado manualmente (override do gerente).
 bool get isManualOverride;/// Nota do override (ex.: "esqueceu-se de bater ponto").
 String get overrideNote; DateTime get date;
/// Create a copy of EmployeeAttendance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeAttendanceCopyWith<EmployeeAttendance> get copyWith => _$EmployeeAttendanceCopyWithImpl<EmployeeAttendance>(this as EmployeeAttendance, _$identity);

  /// Serializes this EmployeeAttendance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeAttendance&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.clockIn, clockIn) || other.clockIn == clockIn)&&(identical(other.clockOut, clockOut) || other.clockOut == clockOut)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.isManualOverride, isManualOverride) || other.isManualOverride == isManualOverride)&&(identical(other.overrideNote, overrideNote) || other.overrideNote == overrideNote)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,storeId,clockIn,clockOut,totalMinutes,isManualOverride,overrideNote,date);

@override
String toString() {
  return 'EmployeeAttendance(id: $id, employeeId: $employeeId, storeId: $storeId, clockIn: $clockIn, clockOut: $clockOut, totalMinutes: $totalMinutes, isManualOverride: $isManualOverride, overrideNote: $overrideNote, date: $date)';
}


}

/// @nodoc
abstract mixin class $EmployeeAttendanceCopyWith<$Res>  {
  factory $EmployeeAttendanceCopyWith(EmployeeAttendance value, $Res Function(EmployeeAttendance) _then) = _$EmployeeAttendanceCopyWithImpl;
@useResult
$Res call({
 String id, String employeeId, String storeId, DateTime clockIn, DateTime? clockOut, int totalMinutes, bool isManualOverride, String overrideNote, DateTime date
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? employeeId = null,Object? storeId = null,Object? clockIn = null,Object? clockOut = freezed,Object? totalMinutes = null,Object? isManualOverride = null,Object? overrideNote = null,Object? date = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,clockIn: null == clockIn ? _self.clockIn : clockIn // ignore: cast_nullable_to_non_nullable
as DateTime,clockOut: freezed == clockOut ? _self.clockOut : clockOut // ignore: cast_nullable_to_non_nullable
as DateTime?,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,isManualOverride: null == isManualOverride ? _self.isManualOverride : isManualOverride // ignore: cast_nullable_to_non_nullable
as bool,overrideNote: null == overrideNote ? _self.overrideNote : overrideNote // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String employeeId,  String storeId,  DateTime clockIn,  DateTime? clockOut,  int totalMinutes,  bool isManualOverride,  String overrideNote,  DateTime date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeAttendance() when $default != null:
return $default(_that.id,_that.employeeId,_that.storeId,_that.clockIn,_that.clockOut,_that.totalMinutes,_that.isManualOverride,_that.overrideNote,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String employeeId,  String storeId,  DateTime clockIn,  DateTime? clockOut,  int totalMinutes,  bool isManualOverride,  String overrideNote,  DateTime date)  $default,) {final _that = this;
switch (_that) {
case _EmployeeAttendance():
return $default(_that.id,_that.employeeId,_that.storeId,_that.clockIn,_that.clockOut,_that.totalMinutes,_that.isManualOverride,_that.overrideNote,_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String employeeId,  String storeId,  DateTime clockIn,  DateTime? clockOut,  int totalMinutes,  bool isManualOverride,  String overrideNote,  DateTime date)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeAttendance() when $default != null:
return $default(_that.id,_that.employeeId,_that.storeId,_that.clockIn,_that.clockOut,_that.totalMinutes,_that.isManualOverride,_that.overrideNote,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeAttendance implements EmployeeAttendance {
  const _EmployeeAttendance({required this.id, required this.employeeId, required this.storeId, required this.clockIn, this.clockOut, this.totalMinutes = 0, this.isManualOverride = false, this.overrideNote = '', required this.date});
  factory _EmployeeAttendance.fromJson(Map<String, dynamic> json) => _$EmployeeAttendanceFromJson(json);

@override final  String id;
@override final  String employeeId;
@override final  String storeId;
/// Hora de entrada.
@override final  DateTime clockIn;
/// Hora de saída (null se ainda não saiu).
@override final  DateTime? clockOut;
/// Total de minutos trabalhados (calculado ao registar saída).
@override@JsonKey() final  int totalMinutes;
/// Se o registo foi editado manualmente (override do gerente).
@override@JsonKey() final  bool isManualOverride;
/// Nota do override (ex.: "esqueceu-se de bater ponto").
@override@JsonKey() final  String overrideNote;
@override final  DateTime date;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeAttendance&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.clockIn, clockIn) || other.clockIn == clockIn)&&(identical(other.clockOut, clockOut) || other.clockOut == clockOut)&&(identical(other.totalMinutes, totalMinutes) || other.totalMinutes == totalMinutes)&&(identical(other.isManualOverride, isManualOverride) || other.isManualOverride == isManualOverride)&&(identical(other.overrideNote, overrideNote) || other.overrideNote == overrideNote)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,storeId,clockIn,clockOut,totalMinutes,isManualOverride,overrideNote,date);

@override
String toString() {
  return 'EmployeeAttendance(id: $id, employeeId: $employeeId, storeId: $storeId, clockIn: $clockIn, clockOut: $clockOut, totalMinutes: $totalMinutes, isManualOverride: $isManualOverride, overrideNote: $overrideNote, date: $date)';
}


}

/// @nodoc
abstract mixin class _$EmployeeAttendanceCopyWith<$Res> implements $EmployeeAttendanceCopyWith<$Res> {
  factory _$EmployeeAttendanceCopyWith(_EmployeeAttendance value, $Res Function(_EmployeeAttendance) _then) = __$EmployeeAttendanceCopyWithImpl;
@override @useResult
$Res call({
 String id, String employeeId, String storeId, DateTime clockIn, DateTime? clockOut, int totalMinutes, bool isManualOverride, String overrideNote, DateTime date
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? employeeId = null,Object? storeId = null,Object? clockIn = null,Object? clockOut = freezed,Object? totalMinutes = null,Object? isManualOverride = null,Object? overrideNote = null,Object? date = null,}) {
  return _then(_EmployeeAttendance(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,clockIn: null == clockIn ? _self.clockIn : clockIn // ignore: cast_nullable_to_non_nullable
as DateTime,clockOut: freezed == clockOut ? _self.clockOut : clockOut // ignore: cast_nullable_to_non_nullable
as DateTime?,totalMinutes: null == totalMinutes ? _self.totalMinutes : totalMinutes // ignore: cast_nullable_to_non_nullable
as int,isManualOverride: null == isManualOverride ? _self.isManualOverride : isManualOverride // ignore: cast_nullable_to_non_nullable
as bool,overrideNote: null == overrideNote ? _self.overrideNote : overrideNote // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$EmployeeTarget {

 String get id; String get employeeId; String get storeId;/// Mês/ano da meta (formato "YYYY-MM").
 String get period;/// Meta de vendas em centavos.
 int get salesTargetCents;/// Meta de comissão percentual (ex.: 500 = 5%).
 int get commissionBps;/// Vendas efectuadas no período (actualizado automaticamente).
 int get salesAchievedCents; bool get isActive; DateTime get createdAt;
/// Create a copy of EmployeeTarget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeTargetCopyWith<EmployeeTarget> get copyWith => _$EmployeeTargetCopyWithImpl<EmployeeTarget>(this as EmployeeTarget, _$identity);

  /// Serializes this EmployeeTarget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeTarget&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.period, period) || other.period == period)&&(identical(other.salesTargetCents, salesTargetCents) || other.salesTargetCents == salesTargetCents)&&(identical(other.commissionBps, commissionBps) || other.commissionBps == commissionBps)&&(identical(other.salesAchievedCents, salesAchievedCents) || other.salesAchievedCents == salesAchievedCents)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,storeId,period,salesTargetCents,commissionBps,salesAchievedCents,isActive,createdAt);

@override
String toString() {
  return 'EmployeeTarget(id: $id, employeeId: $employeeId, storeId: $storeId, period: $period, salesTargetCents: $salesTargetCents, commissionBps: $commissionBps, salesAchievedCents: $salesAchievedCents, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EmployeeTargetCopyWith<$Res>  {
  factory $EmployeeTargetCopyWith(EmployeeTarget value, $Res Function(EmployeeTarget) _then) = _$EmployeeTargetCopyWithImpl;
@useResult
$Res call({
 String id, String employeeId, String storeId, String period, int salesTargetCents, int commissionBps, int salesAchievedCents, bool isActive, DateTime createdAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? employeeId = null,Object? storeId = null,Object? period = null,Object? salesTargetCents = null,Object? commissionBps = null,Object? salesAchievedCents = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,salesTargetCents: null == salesTargetCents ? _self.salesTargetCents : salesTargetCents // ignore: cast_nullable_to_non_nullable
as int,commissionBps: null == commissionBps ? _self.commissionBps : commissionBps // ignore: cast_nullable_to_non_nullable
as int,salesAchievedCents: null == salesAchievedCents ? _self.salesAchievedCents : salesAchievedCents // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String employeeId,  String storeId,  String period,  int salesTargetCents,  int commissionBps,  int salesAchievedCents,  bool isActive,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeTarget() when $default != null:
return $default(_that.id,_that.employeeId,_that.storeId,_that.period,_that.salesTargetCents,_that.commissionBps,_that.salesAchievedCents,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String employeeId,  String storeId,  String period,  int salesTargetCents,  int commissionBps,  int salesAchievedCents,  bool isActive,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _EmployeeTarget():
return $default(_that.id,_that.employeeId,_that.storeId,_that.period,_that.salesTargetCents,_that.commissionBps,_that.salesAchievedCents,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String employeeId,  String storeId,  String period,  int salesTargetCents,  int commissionBps,  int salesAchievedCents,  bool isActive,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeTarget() when $default != null:
return $default(_that.id,_that.employeeId,_that.storeId,_that.period,_that.salesTargetCents,_that.commissionBps,_that.salesAchievedCents,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeTarget implements EmployeeTarget {
  const _EmployeeTarget({required this.id, required this.employeeId, required this.storeId, required this.period, required this.salesTargetCents, this.commissionBps = 500, this.salesAchievedCents = 0, this.isActive = true, required this.createdAt});
  factory _EmployeeTarget.fromJson(Map<String, dynamic> json) => _$EmployeeTargetFromJson(json);

@override final  String id;
@override final  String employeeId;
@override final  String storeId;
/// Mês/ano da meta (formato "YYYY-MM").
@override final  String period;
/// Meta de vendas em centavos.
@override final  int salesTargetCents;
/// Meta de comissão percentual (ex.: 500 = 5%).
@override@JsonKey() final  int commissionBps;
/// Vendas efectuadas no período (actualizado automaticamente).
@override@JsonKey() final  int salesAchievedCents;
@override@JsonKey() final  bool isActive;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeTarget&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.period, period) || other.period == period)&&(identical(other.salesTargetCents, salesTargetCents) || other.salesTargetCents == salesTargetCents)&&(identical(other.commissionBps, commissionBps) || other.commissionBps == commissionBps)&&(identical(other.salesAchievedCents, salesAchievedCents) || other.salesAchievedCents == salesAchievedCents)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,storeId,period,salesTargetCents,commissionBps,salesAchievedCents,isActive,createdAt);

@override
String toString() {
  return 'EmployeeTarget(id: $id, employeeId: $employeeId, storeId: $storeId, period: $period, salesTargetCents: $salesTargetCents, commissionBps: $commissionBps, salesAchievedCents: $salesAchievedCents, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeeTargetCopyWith<$Res> implements $EmployeeTargetCopyWith<$Res> {
  factory _$EmployeeTargetCopyWith(_EmployeeTarget value, $Res Function(_EmployeeTarget) _then) = __$EmployeeTargetCopyWithImpl;
@override @useResult
$Res call({
 String id, String employeeId, String storeId, String period, int salesTargetCents, int commissionBps, int salesAchievedCents, bool isActive, DateTime createdAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? employeeId = null,Object? storeId = null,Object? period = null,Object? salesTargetCents = null,Object? commissionBps = null,Object? salesAchievedCents = null,Object? isActive = null,Object? createdAt = null,}) {
  return _then(_EmployeeTarget(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,salesTargetCents: null == salesTargetCents ? _self.salesTargetCents : salesTargetCents // ignore: cast_nullable_to_non_nullable
as int,commissionBps: null == commissionBps ? _self.commissionBps : commissionBps // ignore: cast_nullable_to_non_nullable
as int,salesAchievedCents: null == salesAchievedCents ? _self.salesAchievedCents : salesAchievedCents // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$EmployeeCommission {

 String get id; String get employeeId; String get saleId;/// Valor da comissão em centavos.
 int get amountCents;/// Taxa aplicada em bps (basis points — 500 = 5%).
 int get rateBps; bool get isPaid; DateTime? get paidAt; DateTime get createdAt;
/// Create a copy of EmployeeCommission
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeCommissionCopyWith<EmployeeCommission> get copyWith => _$EmployeeCommissionCopyWithImpl<EmployeeCommission>(this as EmployeeCommission, _$identity);

  /// Serializes this EmployeeCommission to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeCommission&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.saleId, saleId) || other.saleId == saleId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,saleId,amountCents,rateBps,isPaid,paidAt,createdAt);

@override
String toString() {
  return 'EmployeeCommission(id: $id, employeeId: $employeeId, saleId: $saleId, amountCents: $amountCents, rateBps: $rateBps, isPaid: $isPaid, paidAt: $paidAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $EmployeeCommissionCopyWith<$Res>  {
  factory $EmployeeCommissionCopyWith(EmployeeCommission value, $Res Function(EmployeeCommission) _then) = _$EmployeeCommissionCopyWithImpl;
@useResult
$Res call({
 String id, String employeeId, String saleId, int amountCents, int rateBps, bool isPaid, DateTime? paidAt, DateTime createdAt
});




}
/// @nodoc
class _$EmployeeCommissionCopyWithImpl<$Res>
    implements $EmployeeCommissionCopyWith<$Res> {
  _$EmployeeCommissionCopyWithImpl(this._self, this._then);

  final EmployeeCommission _self;
  final $Res Function(EmployeeCommission) _then;

/// Create a copy of EmployeeCommission
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? employeeId = null,Object? saleId = null,Object? amountCents = null,Object? rateBps = null,Object? isPaid = null,Object? paidAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,saleId: null == saleId ? _self.saleId : saleId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployeeCommission].
extension EmployeeCommissionPatterns on EmployeeCommission {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeCommission value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeCommission() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeCommission value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeCommission():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeCommission value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeCommission() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String employeeId,  String saleId,  int amountCents,  int rateBps,  bool isPaid,  DateTime? paidAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeCommission() when $default != null:
return $default(_that.id,_that.employeeId,_that.saleId,_that.amountCents,_that.rateBps,_that.isPaid,_that.paidAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String employeeId,  String saleId,  int amountCents,  int rateBps,  bool isPaid,  DateTime? paidAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _EmployeeCommission():
return $default(_that.id,_that.employeeId,_that.saleId,_that.amountCents,_that.rateBps,_that.isPaid,_that.paidAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String employeeId,  String saleId,  int amountCents,  int rateBps,  bool isPaid,  DateTime? paidAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeCommission() when $default != null:
return $default(_that.id,_that.employeeId,_that.saleId,_that.amountCents,_that.rateBps,_that.isPaid,_that.paidAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployeeCommission implements EmployeeCommission {
  const _EmployeeCommission({required this.id, required this.employeeId, required this.saleId, required this.amountCents, required this.rateBps, this.isPaid = false, this.paidAt, required this.createdAt});
  factory _EmployeeCommission.fromJson(Map<String, dynamic> json) => _$EmployeeCommissionFromJson(json);

@override final  String id;
@override final  String employeeId;
@override final  String saleId;
/// Valor da comissão em centavos.
@override final  int amountCents;
/// Taxa aplicada em bps (basis points — 500 = 5%).
@override final  int rateBps;
@override@JsonKey() final  bool isPaid;
@override final  DateTime? paidAt;
@override final  DateTime createdAt;

/// Create a copy of EmployeeCommission
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeCommissionCopyWith<_EmployeeCommission> get copyWith => __$EmployeeCommissionCopyWithImpl<_EmployeeCommission>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployeeCommissionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeCommission&&(identical(other.id, id) || other.id == id)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.saleId, saleId) || other.saleId == saleId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.rateBps, rateBps) || other.rateBps == rateBps)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,employeeId,saleId,amountCents,rateBps,isPaid,paidAt,createdAt);

@override
String toString() {
  return 'EmployeeCommission(id: $id, employeeId: $employeeId, saleId: $saleId, amountCents: $amountCents, rateBps: $rateBps, isPaid: $isPaid, paidAt: $paidAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$EmployeeCommissionCopyWith<$Res> implements $EmployeeCommissionCopyWith<$Res> {
  factory _$EmployeeCommissionCopyWith(_EmployeeCommission value, $Res Function(_EmployeeCommission) _then) = __$EmployeeCommissionCopyWithImpl;
@override @useResult
$Res call({
 String id, String employeeId, String saleId, int amountCents, int rateBps, bool isPaid, DateTime? paidAt, DateTime createdAt
});




}
/// @nodoc
class __$EmployeeCommissionCopyWithImpl<$Res>
    implements _$EmployeeCommissionCopyWith<$Res> {
  __$EmployeeCommissionCopyWithImpl(this._self, this._then);

  final _EmployeeCommission _self;
  final $Res Function(_EmployeeCommission) _then;

/// Create a copy of EmployeeCommission
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? employeeId = null,Object? saleId = null,Object? amountCents = null,Object? rateBps = null,Object? isPaid = null,Object? paidAt = freezed,Object? createdAt = null,}) {
  return _then(_EmployeeCommission(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,employeeId: null == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as String,saleId: null == saleId ? _self.saleId : saleId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,rateBps: null == rateBps ? _self.rateBps : rateBps // ignore: cast_nullable_to_non_nullable
as int,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
