// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Plan {

 String get id; String get name; String get description;// Preço mensal em CENTAVOS inteiros (W4 — migração de dinheiro para
// centavos; o banco persiste BIGINT/INTEGER).
 int get priceMonthlyCents; int get maxStores; int get maxEmployees; bool get isActive;
/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanCopyWith<Plan> get copyWith => _$PlanCopyWithImpl<Plan>(this as Plan, _$identity);

  /// Serializes this Plan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Plan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.priceMonthlyCents, priceMonthlyCents) || other.priceMonthlyCents == priceMonthlyCents)&&(identical(other.maxStores, maxStores) || other.maxStores == maxStores)&&(identical(other.maxEmployees, maxEmployees) || other.maxEmployees == maxEmployees)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,priceMonthlyCents,maxStores,maxEmployees,isActive);

@override
String toString() {
  return 'Plan(id: $id, name: $name, description: $description, priceMonthlyCents: $priceMonthlyCents, maxStores: $maxStores, maxEmployees: $maxEmployees, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $PlanCopyWith<$Res>  {
  factory $PlanCopyWith(Plan value, $Res Function(Plan) _then) = _$PlanCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, int priceMonthlyCents, int maxStores, int maxEmployees, bool isActive
});




}
/// @nodoc
class _$PlanCopyWithImpl<$Res>
    implements $PlanCopyWith<$Res> {
  _$PlanCopyWithImpl(this._self, this._then);

  final Plan _self;
  final $Res Function(Plan) _then;

/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? priceMonthlyCents = null,Object? maxStores = null,Object? maxEmployees = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceMonthlyCents: null == priceMonthlyCents ? _self.priceMonthlyCents : priceMonthlyCents // ignore: cast_nullable_to_non_nullable
as int,maxStores: null == maxStores ? _self.maxStores : maxStores // ignore: cast_nullable_to_non_nullable
as int,maxEmployees: null == maxEmployees ? _self.maxEmployees : maxEmployees // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Plan].
extension PlanPatterns on Plan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Plan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Plan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Plan value)  $default,){
final _that = this;
switch (_that) {
case _Plan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Plan value)?  $default,){
final _that = this;
switch (_that) {
case _Plan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int priceMonthlyCents,  int maxStores,  int maxEmployees,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Plan() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.priceMonthlyCents,_that.maxStores,_that.maxEmployees,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int priceMonthlyCents,  int maxStores,  int maxEmployees,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _Plan():
return $default(_that.id,_that.name,_that.description,_that.priceMonthlyCents,_that.maxStores,_that.maxEmployees,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  int priceMonthlyCents,  int maxStores,  int maxEmployees,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _Plan() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.priceMonthlyCents,_that.maxStores,_that.maxEmployees,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Plan implements Plan {
  const _Plan({required this.id, required this.name, this.description = '', this.priceMonthlyCents = 0, this.maxStores = 1, this.maxEmployees = 1, this.isActive = true});
  factory _Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey() final  String description;
// Preço mensal em CENTAVOS inteiros (W4 — migração de dinheiro para
// centavos; o banco persiste BIGINT/INTEGER).
@override@JsonKey() final  int priceMonthlyCents;
@override@JsonKey() final  int maxStores;
@override@JsonKey() final  int maxEmployees;
@override@JsonKey() final  bool isActive;

/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanCopyWith<_Plan> get copyWith => __$PlanCopyWithImpl<_Plan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Plan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.priceMonthlyCents, priceMonthlyCents) || other.priceMonthlyCents == priceMonthlyCents)&&(identical(other.maxStores, maxStores) || other.maxStores == maxStores)&&(identical(other.maxEmployees, maxEmployees) || other.maxEmployees == maxEmployees)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,priceMonthlyCents,maxStores,maxEmployees,isActive);

@override
String toString() {
  return 'Plan(id: $id, name: $name, description: $description, priceMonthlyCents: $priceMonthlyCents, maxStores: $maxStores, maxEmployees: $maxEmployees, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$PlanCopyWith<$Res> implements $PlanCopyWith<$Res> {
  factory _$PlanCopyWith(_Plan value, $Res Function(_Plan) _then) = __$PlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, int priceMonthlyCents, int maxStores, int maxEmployees, bool isActive
});




}
/// @nodoc
class __$PlanCopyWithImpl<$Res>
    implements _$PlanCopyWith<$Res> {
  __$PlanCopyWithImpl(this._self, this._then);

  final _Plan _self;
  final $Res Function(_Plan) _then;

/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? priceMonthlyCents = null,Object? maxStores = null,Object? maxEmployees = null,Object? isActive = null,}) {
  return _then(_Plan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,priceMonthlyCents: null == priceMonthlyCents ? _self.priceMonthlyCents : priceMonthlyCents // ignore: cast_nullable_to_non_nullable
as int,maxStores: null == maxStores ? _self.maxStores : maxStores // ignore: cast_nullable_to_non_nullable
as int,maxEmployees: null == maxEmployees ? _self.maxEmployees : maxEmployees // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
