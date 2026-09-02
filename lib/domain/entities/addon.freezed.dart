// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'addon.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AddOn {

 String get id; String get name; String get description; AddOnCategory get category;/// Preço mensal em CENTAVOS inteiros.
 int get priceMonthlyCents;/// Ícone do add-on.
 String get iconName;/// Se o add-on está disponível para compra (pode ser descontinuado).
 bool get isAvailable;
/// Create a copy of AddOn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddOnCopyWith<AddOn> get copyWith => _$AddOnCopyWithImpl<AddOn>(this as AddOn, _$identity);

  /// Serializes this AddOn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddOn&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.priceMonthlyCents, priceMonthlyCents) || other.priceMonthlyCents == priceMonthlyCents)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,category,priceMonthlyCents,iconName,isAvailable);

@override
String toString() {
  return 'AddOn(id: $id, name: $name, description: $description, category: $category, priceMonthlyCents: $priceMonthlyCents, iconName: $iconName, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class $AddOnCopyWith<$Res>  {
  factory $AddOnCopyWith(AddOn value, $Res Function(AddOn) _then) = _$AddOnCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, AddOnCategory category, int priceMonthlyCents, String iconName, bool isAvailable
});




}
/// @nodoc
class _$AddOnCopyWithImpl<$Res>
    implements $AddOnCopyWith<$Res> {
  _$AddOnCopyWithImpl(this._self, this._then);

  final AddOn _self;
  final $Res Function(AddOn) _then;

/// Create a copy of AddOn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? category = null,Object? priceMonthlyCents = null,Object? iconName = null,Object? isAvailable = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AddOnCategory,priceMonthlyCents: null == priceMonthlyCents ? _self.priceMonthlyCents : priceMonthlyCents // ignore: cast_nullable_to_non_nullable
as int,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AddOn].
extension AddOnPatterns on AddOn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddOn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddOn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddOn value)  $default,){
final _that = this;
switch (_that) {
case _AddOn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddOn value)?  $default,){
final _that = this;
switch (_that) {
case _AddOn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  AddOnCategory category,  int priceMonthlyCents,  String iconName,  bool isAvailable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddOn() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.category,_that.priceMonthlyCents,_that.iconName,_that.isAvailable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  AddOnCategory category,  int priceMonthlyCents,  String iconName,  bool isAvailable)  $default,) {final _that = this;
switch (_that) {
case _AddOn():
return $default(_that.id,_that.name,_that.description,_that.category,_that.priceMonthlyCents,_that.iconName,_that.isAvailable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  AddOnCategory category,  int priceMonthlyCents,  String iconName,  bool isAvailable)?  $default,) {final _that = this;
switch (_that) {
case _AddOn() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.category,_that.priceMonthlyCents,_that.iconName,_that.isAvailable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AddOn implements AddOn {
  const _AddOn({required this.id, required this.name, required this.description, required this.category, required this.priceMonthlyCents, this.iconName = '', this.isAvailable = true});
  factory _AddOn.fromJson(Map<String, dynamic> json) => _$AddOnFromJson(json);

@override final  String id;
@override final  String name;
@override final  String description;
@override final  AddOnCategory category;
/// Preço mensal em CENTAVOS inteiros.
@override final  int priceMonthlyCents;
/// Ícone do add-on.
@override@JsonKey() final  String iconName;
/// Se o add-on está disponível para compra (pode ser descontinuado).
@override@JsonKey() final  bool isAvailable;

/// Create a copy of AddOn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddOnCopyWith<_AddOn> get copyWith => __$AddOnCopyWithImpl<_AddOn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AddOnToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddOn&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.priceMonthlyCents, priceMonthlyCents) || other.priceMonthlyCents == priceMonthlyCents)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isAvailable, isAvailable) || other.isAvailable == isAvailable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,category,priceMonthlyCents,iconName,isAvailable);

@override
String toString() {
  return 'AddOn(id: $id, name: $name, description: $description, category: $category, priceMonthlyCents: $priceMonthlyCents, iconName: $iconName, isAvailable: $isAvailable)';
}


}

/// @nodoc
abstract mixin class _$AddOnCopyWith<$Res> implements $AddOnCopyWith<$Res> {
  factory _$AddOnCopyWith(_AddOn value, $Res Function(_AddOn) _then) = __$AddOnCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, AddOnCategory category, int priceMonthlyCents, String iconName, bool isAvailable
});




}
/// @nodoc
class __$AddOnCopyWithImpl<$Res>
    implements _$AddOnCopyWith<$Res> {
  __$AddOnCopyWithImpl(this._self, this._then);

  final _AddOn _self;
  final $Res Function(_AddOn) _then;

/// Create a copy of AddOn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? category = null,Object? priceMonthlyCents = null,Object? iconName = null,Object? isAvailable = null,}) {
  return _then(_AddOn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as AddOnCategory,priceMonthlyCents: null == priceMonthlyCents ? _self.priceMonthlyCents : priceMonthlyCents // ignore: cast_nullable_to_non_nullable
as int,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,isAvailable: null == isAvailable ? _self.isAvailable : isAvailable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$TenantAddOn {

 String get id; String get tenantId; String get addOnId; DateTime get activatedAt; DateTime? get expiresAt; bool get isActive;
/// Create a copy of TenantAddOn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantAddOnCopyWith<TenantAddOn> get copyWith => _$TenantAddOnCopyWithImpl<TenantAddOn>(this as TenantAddOn, _$identity);

  /// Serializes this TenantAddOn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TenantAddOn&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.addOnId, addOnId) || other.addOnId == addOnId)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,addOnId,activatedAt,expiresAt,isActive);

@override
String toString() {
  return 'TenantAddOn(id: $id, tenantId: $tenantId, addOnId: $addOnId, activatedAt: $activatedAt, expiresAt: $expiresAt, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $TenantAddOnCopyWith<$Res>  {
  factory $TenantAddOnCopyWith(TenantAddOn value, $Res Function(TenantAddOn) _then) = _$TenantAddOnCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String addOnId, DateTime activatedAt, DateTime? expiresAt, bool isActive
});




}
/// @nodoc
class _$TenantAddOnCopyWithImpl<$Res>
    implements $TenantAddOnCopyWith<$Res> {
  _$TenantAddOnCopyWithImpl(this._self, this._then);

  final TenantAddOn _self;
  final $Res Function(TenantAddOn) _then;

/// Create a copy of TenantAddOn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? addOnId = null,Object? activatedAt = null,Object? expiresAt = freezed,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,addOnId: null == addOnId ? _self.addOnId : addOnId // ignore: cast_nullable_to_non_nullable
as String,activatedAt: null == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TenantAddOn].
extension TenantAddOnPatterns on TenantAddOn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TenantAddOn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TenantAddOn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TenantAddOn value)  $default,){
final _that = this;
switch (_that) {
case _TenantAddOn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TenantAddOn value)?  $default,){
final _that = this;
switch (_that) {
case _TenantAddOn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String addOnId,  DateTime activatedAt,  DateTime? expiresAt,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TenantAddOn() when $default != null:
return $default(_that.id,_that.tenantId,_that.addOnId,_that.activatedAt,_that.expiresAt,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String addOnId,  DateTime activatedAt,  DateTime? expiresAt,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _TenantAddOn():
return $default(_that.id,_that.tenantId,_that.addOnId,_that.activatedAt,_that.expiresAt,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String addOnId,  DateTime activatedAt,  DateTime? expiresAt,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _TenantAddOn() when $default != null:
return $default(_that.id,_that.tenantId,_that.addOnId,_that.activatedAt,_that.expiresAt,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TenantAddOn implements TenantAddOn {
  const _TenantAddOn({required this.id, required this.tenantId, required this.addOnId, required this.activatedAt, this.expiresAt, this.isActive = true});
  factory _TenantAddOn.fromJson(Map<String, dynamic> json) => _$TenantAddOnFromJson(json);

@override final  String id;
@override final  String tenantId;
@override final  String addOnId;
@override final  DateTime activatedAt;
@override final  DateTime? expiresAt;
@override@JsonKey() final  bool isActive;

/// Create a copy of TenantAddOn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantAddOnCopyWith<_TenantAddOn> get copyWith => __$TenantAddOnCopyWithImpl<_TenantAddOn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TenantAddOnToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TenantAddOn&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.addOnId, addOnId) || other.addOnId == addOnId)&&(identical(other.activatedAt, activatedAt) || other.activatedAt == activatedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,addOnId,activatedAt,expiresAt,isActive);

@override
String toString() {
  return 'TenantAddOn(id: $id, tenantId: $tenantId, addOnId: $addOnId, activatedAt: $activatedAt, expiresAt: $expiresAt, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$TenantAddOnCopyWith<$Res> implements $TenantAddOnCopyWith<$Res> {
  factory _$TenantAddOnCopyWith(_TenantAddOn value, $Res Function(_TenantAddOn) _then) = __$TenantAddOnCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String addOnId, DateTime activatedAt, DateTime? expiresAt, bool isActive
});




}
/// @nodoc
class __$TenantAddOnCopyWithImpl<$Res>
    implements _$TenantAddOnCopyWith<$Res> {
  __$TenantAddOnCopyWithImpl(this._self, this._then);

  final _TenantAddOn _self;
  final $Res Function(_TenantAddOn) _then;

/// Create a copy of TenantAddOn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? addOnId = null,Object? activatedAt = null,Object? expiresAt = freezed,Object? isActive = null,}) {
  return _then(_TenantAddOn(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,addOnId: null == addOnId ? _self.addOnId : addOnId // ignore: cast_nullable_to_non_nullable
as String,activatedAt: null == activatedAt ? _self.activatedAt : activatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
