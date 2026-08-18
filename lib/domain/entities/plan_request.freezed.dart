// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanRequest {

 String get id; String get tenantId; String get currentPlanId; String get requestedPlanId; PlanRequestStatus get status; DateTime? get decidedAt; DateTime get createdAt;
/// Create a copy of PlanRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanRequestCopyWith<PlanRequest> get copyWith => _$PlanRequestCopyWithImpl<PlanRequest>(this as PlanRequest, _$identity);

 /// Serializes this PlanRequest to a JSON map.
 Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.currentPlanId, currentPlanId) || other.currentPlanId == currentPlanId)&&(identical(other.requestedPlanId, requestedPlanId) || other.requestedPlanId == requestedPlanId)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,currentPlanId,requestedPlanId,status,decidedAt,createdAt);

@override
String toString() {
 return 'PlanRequest(id: $id, tenantId: $tenantId, currentPlanId: $currentPlanId, requestedPlanId: $requestedPlanId, status: $status, decidedAt: $decidedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PlanRequestCopyWith<$Res> {
 factory $PlanRequestCopyWith(PlanRequest value, $Res Function(PlanRequest) _then) = _$PlanRequestCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String currentPlanId, String requestedPlanId, PlanRequestStatus status, DateTime? decidedAt, DateTime createdAt
});




}
/// @nodoc
class _$PlanRequestCopyWithImpl<$Res>
 implements $PlanRequestCopyWith<$Res> {
 _$PlanRequestCopyWithImpl(this._self, this._then);

 final PlanRequest _self;
 final $Res Function(PlanRequest) _then;

/// Create a copy of PlanRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? currentPlanId = null,Object? requestedPlanId = null,Object? status = null,Object? decidedAt = freezed,Object? createdAt = null,}) {
 return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,currentPlanId: null == currentPlanId ? _self.currentPlanId : currentPlanId // ignore: cast_nullable_to_non_nullable
as String,requestedPlanId: null == requestedPlanId ? _self.requestedPlanId : requestedPlanId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanRequestStatus,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
 ));
}

}


/// Adds pattern-matching-related methods to [PlanRequest].
extension PlanRequestPatterns on PlanRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanRequest value)? $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanRequest value) $default,){
final _that = this;
switch (_that) {
case _PlanRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanRequest value)? $default,){
final _that = this;
switch (_that) {
case _PlanRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, String tenantId, String currentPlanId, String requestedPlanId, PlanRequestStatus status, DateTime? decidedAt, DateTime createdAt)? $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanRequest() when $default != null:
return $default(_that.id,_that.tenantId,_that.currentPlanId,_that.requestedPlanId,_that.status,_that.decidedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, String tenantId, String currentPlanId, String requestedPlanId, PlanRequestStatus status, DateTime? decidedAt, DateTime createdAt) $default,) {final _that = this;
switch (_that) {
case _PlanRequest():
return $default(_that.id,_that.tenantId,_that.currentPlanId,_that.requestedPlanId,_that.status,_that.decidedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, String tenantId, String currentPlanId, String requestedPlanId, PlanRequestStatus status, DateTime? decidedAt, DateTime createdAt)? $default,) {final _that = this;
switch (_that) {
case _PlanRequest() when $default != null:
return $default(_that.id,_that.tenantId,_that.currentPlanId,_that.requestedPlanId,_that.status,_that.decidedAt,_that.createdAt);case _:
 return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanRequest implements PlanRequest {
 const _PlanRequest({required this.id, required this.tenantId, required this.currentPlanId, required this.requestedPlanId, this.status = PlanRequestStatus.pending, this.decidedAt, required this.createdAt});
 factory _PlanRequest.fromJson(Map<String, dynamic> json) => _$PlanRequestFromJson(json);

@override final String id;
@override final String tenantId;
@override final String currentPlanId;
@override final String requestedPlanId;
@override@JsonKey() final PlanRequestStatus status;
@override final DateTime? decidedAt;
@override final DateTime createdAt;

/// Create a copy of PlanRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanRequestCopyWith<_PlanRequest> get copyWith => __$PlanRequestCopyWithImpl<_PlanRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
 return _$PlanRequestToJson(this, );
}

@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.currentPlanId, currentPlanId) || other.currentPlanId == currentPlanId)&&(identical(other.requestedPlanId, requestedPlanId) || other.requestedPlanId == requestedPlanId)&&(identical(other.status, status) || other.status == status)&&(identical(other.decidedAt, decidedAt) || other.decidedAt == decidedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,currentPlanId,requestedPlanId,status,decidedAt,createdAt);

@override
String toString() {
 return 'PlanRequest(id: $id, tenantId: $tenantId, currentPlanId: $currentPlanId, requestedPlanId: $requestedPlanId, status: $status, decidedAt: $decidedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PlanRequestCopyWith<$Res> implements $PlanRequestCopyWith<$Res> {
 factory _$PlanRequestCopyWith(_PlanRequest value, $Res Function(_PlanRequest) _then) = __$PlanRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String currentPlanId, String requestedPlanId, PlanRequestStatus status, DateTime? decidedAt, DateTime createdAt
});




}
/// @nodoc
class __$PlanRequestCopyWithImpl<$Res>
 implements _$PlanRequestCopyWith<$Res> {
 __$PlanRequestCopyWithImpl(this._self, this._then);

 final _PlanRequest _self;
 final $Res Function(_PlanRequest) _then;

/// Create a copy of PlanRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? currentPlanId = null,Object? requestedPlanId = null,Object? status = null,Object? decidedAt = freezed,Object? createdAt = null,}) {
 return _then(_PlanRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,currentPlanId: null == currentPlanId ? _self.currentPlanId : currentPlanId // ignore: cast_nullable_to_non_nullable
as String,requestedPlanId: null == requestedPlanId ? _self.requestedPlanId : requestedPlanId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanRequestStatus,decidedAt: freezed == decidedAt ? _self.decidedAt : decidedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
 ));
}


}

// dart format on
