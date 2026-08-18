// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sale_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SaleItem {

 String get productId; String get productName;// Quantidade em MILÉSIMOS de unidade (W11): 1000 = 1 unidade/kg.
 int get quantity;// Preço unitário cobrado em CENTAVOS inteiros (W4).
 int get unitPriceCents;
/// Create a copy of SaleItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaleItemCopyWith<SaleItem> get copyWith => _$SaleItemCopyWithImpl<SaleItem>(this as SaleItem, _$identity);

 /// Serializes this SaleItem to a JSON map.
 Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is SaleItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitPriceCents);

@override
String toString() {
 return 'SaleItem(productId: $productId, productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents)';
}


}

/// @nodoc
abstract mixin class $SaleItemCopyWith<$Res> {
 factory $SaleItemCopyWith(SaleItem value, $Res Function(SaleItem) _then) = _$SaleItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, int quantity, int unitPriceCents
});




}
/// @nodoc
class _$SaleItemCopyWithImpl<$Res>
 implements $SaleItemCopyWith<$Res> {
 _$SaleItemCopyWithImpl(this._self, this._then);

 final SaleItem _self;
 final $Res Function(SaleItem) _then;

/// Create a copy of SaleItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitPriceCents = null,}) {
 return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,
 ));
}

}


/// Adds pattern-matching-related methods to [SaleItem].
extension SaleItemPatterns on SaleItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaleItem value)? $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaleItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaleItem value) $default,){
final _that = this;
switch (_that) {
case _SaleItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaleItem value)? $default,){
final _that = this;
switch (_that) {
case _SaleItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId, String productName, int quantity, int unitPriceCents)? $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaleItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId, String productName, int quantity, int unitPriceCents) $default,) {final _that = this;
switch (_that) {
case _SaleItem():
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId, String productName, int quantity, int unitPriceCents)? $default,) {final _that = this;
switch (_that) {
case _SaleItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents);case _:
 return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SaleItem implements SaleItem {
 const _SaleItem({required this.productId, required this.productName, required this.quantity, required this.unitPriceCents});
 factory _SaleItem.fromJson(Map<String, dynamic> json) => _$SaleItemFromJson(json);

@override final String productId;
@override final String productName;
// Quantidade em MILÉSIMOS de unidade (W11): 1000 = 1 unidade/kg.
@override final int quantity;
// Preço unitário cobrado em CENTAVOS inteiros (W4).
@override final int unitPriceCents;

/// Create a copy of SaleItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaleItemCopyWith<_SaleItem> get copyWith => __$SaleItemCopyWithImpl<_SaleItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
 return _$SaleItemToJson(this, );
}

@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaleItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitPriceCents);

@override
String toString() {
 return 'SaleItem(productId: $productId, productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents)';
}


}

/// @nodoc
abstract mixin class _$SaleItemCopyWith<$Res> implements $SaleItemCopyWith<$Res> {
 factory _$SaleItemCopyWith(_SaleItem value, $Res Function(_SaleItem) _then) = __$SaleItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, int quantity, int unitPriceCents
});




}
/// @nodoc
class __$SaleItemCopyWithImpl<$Res>
 implements _$SaleItemCopyWith<$Res> {
 __$SaleItemCopyWithImpl(this._self, this._then);

 final _SaleItem _self;
 final $Res Function(_SaleItem) _then;

/// Create a copy of SaleItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitPriceCents = null,}) {
 return _then(_SaleItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,
 ));
}


}

// dart format on
