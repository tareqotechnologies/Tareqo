// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_barcode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductBarcode {

 String get id; String get storeId; String get productId; String get barcode; int get qtyFactor; String get description; bool get isActive;
/// Create a copy of ProductBarcode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductBarcodeCopyWith<ProductBarcode> get copyWith => _$ProductBarcodeCopyWithImpl<ProductBarcode>(this as ProductBarcode, _$identity);

  /// Serializes this ProductBarcode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductBarcode&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.qtyFactor, qtyFactor) || other.qtyFactor == qtyFactor)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,productId,barcode,qtyFactor,description,isActive);

@override
String toString() {
  return 'ProductBarcode(id: $id, storeId: $storeId, productId: $productId, barcode: $barcode, qtyFactor: $qtyFactor, description: $description, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $ProductBarcodeCopyWith<$Res>  {
  factory $ProductBarcodeCopyWith(ProductBarcode value, $Res Function(ProductBarcode) _then) = _$ProductBarcodeCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String productId, String barcode, int qtyFactor, String description, bool isActive
});




}
/// @nodoc
class _$ProductBarcodeCopyWithImpl<$Res>
    implements $ProductBarcodeCopyWith<$Res> {
  _$ProductBarcodeCopyWithImpl(this._self, this._then);

  final ProductBarcode _self;
  final $Res Function(ProductBarcode) _then;

/// Create a copy of ProductBarcode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? productId = null,Object? barcode = null,Object? qtyFactor = null,Object? description = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,qtyFactor: null == qtyFactor ? _self.qtyFactor : qtyFactor // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductBarcode].
extension ProductBarcodePatterns on ProductBarcode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductBarcode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductBarcode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductBarcode value)  $default,){
final _that = this;
switch (_that) {
case _ProductBarcode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductBarcode value)?  $default,){
final _that = this;
switch (_that) {
case _ProductBarcode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String productId,  String barcode,  int qtyFactor,  String description,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductBarcode() when $default != null:
return $default(_that.id,_that.storeId,_that.productId,_that.barcode,_that.qtyFactor,_that.description,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String productId,  String barcode,  int qtyFactor,  String description,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _ProductBarcode():
return $default(_that.id,_that.storeId,_that.productId,_that.barcode,_that.qtyFactor,_that.description,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String productId,  String barcode,  int qtyFactor,  String description,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _ProductBarcode() when $default != null:
return $default(_that.id,_that.storeId,_that.productId,_that.barcode,_that.qtyFactor,_that.description,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductBarcode implements ProductBarcode {
  const _ProductBarcode({required this.id, this.storeId = 'st1', required this.productId, required this.barcode, this.qtyFactor = 1, this.description = '', this.isActive = true});
  factory _ProductBarcode.fromJson(Map<String, dynamic> json) => _$ProductBarcodeFromJson(json);

@override final  String id;
@override@JsonKey() final  String storeId;
@override final  String productId;
@override final  String barcode;
@override@JsonKey() final  int qtyFactor;
@override@JsonKey() final  String description;
@override@JsonKey() final  bool isActive;

/// Create a copy of ProductBarcode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductBarcodeCopyWith<_ProductBarcode> get copyWith => __$ProductBarcodeCopyWithImpl<_ProductBarcode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductBarcodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductBarcode&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.barcode, barcode) || other.barcode == barcode)&&(identical(other.qtyFactor, qtyFactor) || other.qtyFactor == qtyFactor)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,productId,barcode,qtyFactor,description,isActive);

@override
String toString() {
  return 'ProductBarcode(id: $id, storeId: $storeId, productId: $productId, barcode: $barcode, qtyFactor: $qtyFactor, description: $description, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$ProductBarcodeCopyWith<$Res> implements $ProductBarcodeCopyWith<$Res> {
  factory _$ProductBarcodeCopyWith(_ProductBarcode value, $Res Function(_ProductBarcode) _then) = __$ProductBarcodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String productId, String barcode, int qtyFactor, String description, bool isActive
});




}
/// @nodoc
class __$ProductBarcodeCopyWithImpl<$Res>
    implements _$ProductBarcodeCopyWith<$Res> {
  __$ProductBarcodeCopyWithImpl(this._self, this._then);

  final _ProductBarcode _self;
  final $Res Function(_ProductBarcode) _then;

/// Create a copy of ProductBarcode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? productId = null,Object? barcode = null,Object? qtyFactor = null,Object? description = null,Object? isActive = null,}) {
  return _then(_ProductBarcode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,barcode: null == barcode ? _self.barcode : barcode // ignore: cast_nullable_to_non_nullable
as String,qtyFactor: null == qtyFactor ? _self.qtyFactor : qtyFactor // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
