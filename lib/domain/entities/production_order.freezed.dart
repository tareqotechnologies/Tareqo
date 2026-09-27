// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'production_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductionItem {

 String get productId; String get productName; int get quantity; int get unitCostCents;
/// Create a copy of ProductionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductionItemCopyWith<ProductionItem> get copyWith => _$ProductionItemCopyWithImpl<ProductionItem>(this as ProductionItem, _$identity);

  /// Serializes this ProductionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductionItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCostCents, unitCostCents) || other.unitCostCents == unitCostCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitCostCents);

@override
String toString() {
  return 'ProductionItem(productId: $productId, productName: $productName, quantity: $quantity, unitCostCents: $unitCostCents)';
}


}

/// @nodoc
abstract mixin class $ProductionItemCopyWith<$Res>  {
  factory $ProductionItemCopyWith(ProductionItem value, $Res Function(ProductionItem) _then) = _$ProductionItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, int quantity, int unitCostCents
});




}
/// @nodoc
class _$ProductionItemCopyWithImpl<$Res>
    implements $ProductionItemCopyWith<$Res> {
  _$ProductionItemCopyWithImpl(this._self, this._then);

  final ProductionItem _self;
  final $Res Function(ProductionItem) _then;

/// Create a copy of ProductionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitCostCents = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitCostCents: null == unitCostCents ? _self.unitCostCents : unitCostCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductionItem].
extension ProductionItemPatterns on ProductionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductionItem value)  $default,){
final _that = this;
switch (_that) {
case _ProductionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductionItem value)?  $default,){
final _that = this;
switch (_that) {
case _ProductionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitCostCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductionItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitCostCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitCostCents)  $default,) {final _that = this;
switch (_that) {
case _ProductionItem():
return $default(_that.productId,_that.productName,_that.quantity,_that.unitCostCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  int quantity,  int unitCostCents)?  $default,) {final _that = this;
switch (_that) {
case _ProductionItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitCostCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductionItem implements ProductionItem {
  const _ProductionItem({required this.productId, required this.productName, required this.quantity, required this.unitCostCents});
  factory _ProductionItem.fromJson(Map<String, dynamic> json) => _$ProductionItemFromJson(json);

@override final  String productId;
@override final  String productName;
@override final  int quantity;
@override final  int unitCostCents;

/// Create a copy of ProductionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductionItemCopyWith<_ProductionItem> get copyWith => __$ProductionItemCopyWithImpl<_ProductionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductionItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitCostCents, unitCostCents) || other.unitCostCents == unitCostCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitCostCents);

@override
String toString() {
  return 'ProductionItem(productId: $productId, productName: $productName, quantity: $quantity, unitCostCents: $unitCostCents)';
}


}

/// @nodoc
abstract mixin class _$ProductionItemCopyWith<$Res> implements $ProductionItemCopyWith<$Res> {
  factory _$ProductionItemCopyWith(_ProductionItem value, $Res Function(_ProductionItem) _then) = __$ProductionItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, int quantity, int unitCostCents
});




}
/// @nodoc
class __$ProductionItemCopyWithImpl<$Res>
    implements _$ProductionItemCopyWith<$Res> {
  __$ProductionItemCopyWithImpl(this._self, this._then);

  final _ProductionItem _self;
  final $Res Function(_ProductionItem) _then;

/// Create a copy of ProductionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitCostCents = null,}) {
  return _then(_ProductionItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitCostCents: null == unitCostCents ? _self.unitCostCents : unitCostCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProductionOrder {

 String get id; String get storeId;// Produto ACABADO produzido.
 String get productId; String get productName;// Quantidade produzida, em MILÉSIMOS (W11).
 int get quantity;// Ficha técnica de origem (null se a produção foi avulsa).
 String? get recipeId;// Custo por unidade do produto acabado (CENTAVOS, W4) — vira o
// `cost_price` do lote criado.
 int get costPriceCents;// Custo total da ordem (CENTAVOS) = Σ (componente × custo unitário).
 int get totalCostCents; DateTime get dateTime;// Componentes consumidos (snapshot).
 List<ProductionItem> get items;
/// Create a copy of ProductionOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductionOrderCopyWith<ProductionOrder> get copyWith => _$ProductionOrderCopyWithImpl<ProductionOrder>(this as ProductionOrder, _$identity);

  /// Serializes this ProductionOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductionOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.costPriceCents, costPriceCents) || other.costPriceCents == costPriceCents)&&(identical(other.totalCostCents, totalCostCents) || other.totalCostCents == totalCostCents)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,productId,productName,quantity,recipeId,costPriceCents,totalCostCents,dateTime,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'ProductionOrder(id: $id, storeId: $storeId, productId: $productId, productName: $productName, quantity: $quantity, recipeId: $recipeId, costPriceCents: $costPriceCents, totalCostCents: $totalCostCents, dateTime: $dateTime, items: $items)';
}


}

/// @nodoc
abstract mixin class $ProductionOrderCopyWith<$Res>  {
  factory $ProductionOrderCopyWith(ProductionOrder value, $Res Function(ProductionOrder) _then) = _$ProductionOrderCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String productId, String productName, int quantity, String? recipeId, int costPriceCents, int totalCostCents, DateTime dateTime, List<ProductionItem> items
});




}
/// @nodoc
class _$ProductionOrderCopyWithImpl<$Res>
    implements $ProductionOrderCopyWith<$Res> {
  _$ProductionOrderCopyWithImpl(this._self, this._then);

  final ProductionOrder _self;
  final $Res Function(ProductionOrder) _then;

/// Create a copy of ProductionOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? productId = null,Object? productName = null,Object? quantity = null,Object? recipeId = freezed,Object? costPriceCents = null,Object? totalCostCents = null,Object? dateTime = null,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,costPriceCents: null == costPriceCents ? _self.costPriceCents : costPriceCents // ignore: cast_nullable_to_non_nullable
as int,totalCostCents: null == totalCostCents ? _self.totalCostCents : totalCostCents // ignore: cast_nullable_to_non_nullable
as int,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ProductionItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductionOrder].
extension ProductionOrderPatterns on ProductionOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductionOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductionOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductionOrder value)  $default,){
final _that = this;
switch (_that) {
case _ProductionOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductionOrder value)?  $default,){
final _that = this;
switch (_that) {
case _ProductionOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String productId,  String productName,  int quantity,  String? recipeId,  int costPriceCents,  int totalCostCents,  DateTime dateTime,  List<ProductionItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductionOrder() when $default != null:
return $default(_that.id,_that.storeId,_that.productId,_that.productName,_that.quantity,_that.recipeId,_that.costPriceCents,_that.totalCostCents,_that.dateTime,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String productId,  String productName,  int quantity,  String? recipeId,  int costPriceCents,  int totalCostCents,  DateTime dateTime,  List<ProductionItem> items)  $default,) {final _that = this;
switch (_that) {
case _ProductionOrder():
return $default(_that.id,_that.storeId,_that.productId,_that.productName,_that.quantity,_that.recipeId,_that.costPriceCents,_that.totalCostCents,_that.dateTime,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String productId,  String productName,  int quantity,  String? recipeId,  int costPriceCents,  int totalCostCents,  DateTime dateTime,  List<ProductionItem> items)?  $default,) {final _that = this;
switch (_that) {
case _ProductionOrder() when $default != null:
return $default(_that.id,_that.storeId,_that.productId,_that.productName,_that.quantity,_that.recipeId,_that.costPriceCents,_that.totalCostCents,_that.dateTime,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductionOrder implements ProductionOrder {
  const _ProductionOrder({required this.id, this.storeId = 'st1', required this.productId, required this.productName, required this.quantity, this.recipeId, required this.costPriceCents, required this.totalCostCents, required this.dateTime, required final  List<ProductionItem> items}): _items = items;
  factory _ProductionOrder.fromJson(Map<String, dynamic> json) => _$ProductionOrderFromJson(json);

@override final  String id;
@override@JsonKey() final  String storeId;
// Produto ACABADO produzido.
@override final  String productId;
@override final  String productName;
// Quantidade produzida, em MILÉSIMOS (W11).
@override final  int quantity;
// Ficha técnica de origem (null se a produção foi avulsa).
@override final  String? recipeId;
// Custo por unidade do produto acabado (CENTAVOS, W4) — vira o
// `cost_price` do lote criado.
@override final  int costPriceCents;
// Custo total da ordem (CENTAVOS) = Σ (componente × custo unitário).
@override final  int totalCostCents;
@override final  DateTime dateTime;
// Componentes consumidos (snapshot).
 final  List<ProductionItem> _items;
// Componentes consumidos (snapshot).
@override List<ProductionItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ProductionOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductionOrderCopyWith<_ProductionOrder> get copyWith => __$ProductionOrderCopyWithImpl<_ProductionOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductionOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductionOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.recipeId, recipeId) || other.recipeId == recipeId)&&(identical(other.costPriceCents, costPriceCents) || other.costPriceCents == costPriceCents)&&(identical(other.totalCostCents, totalCostCents) || other.totalCostCents == totalCostCents)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,productId,productName,quantity,recipeId,costPriceCents,totalCostCents,dateTime,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'ProductionOrder(id: $id, storeId: $storeId, productId: $productId, productName: $productName, quantity: $quantity, recipeId: $recipeId, costPriceCents: $costPriceCents, totalCostCents: $totalCostCents, dateTime: $dateTime, items: $items)';
}


}

/// @nodoc
abstract mixin class _$ProductionOrderCopyWith<$Res> implements $ProductionOrderCopyWith<$Res> {
  factory _$ProductionOrderCopyWith(_ProductionOrder value, $Res Function(_ProductionOrder) _then) = __$ProductionOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String productId, String productName, int quantity, String? recipeId, int costPriceCents, int totalCostCents, DateTime dateTime, List<ProductionItem> items
});




}
/// @nodoc
class __$ProductionOrderCopyWithImpl<$Res>
    implements _$ProductionOrderCopyWith<$Res> {
  __$ProductionOrderCopyWithImpl(this._self, this._then);

  final _ProductionOrder _self;
  final $Res Function(_ProductionOrder) _then;

/// Create a copy of ProductionOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? productId = null,Object? productName = null,Object? quantity = null,Object? recipeId = freezed,Object? costPriceCents = null,Object? totalCostCents = null,Object? dateTime = null,Object? items = null,}) {
  return _then(_ProductionOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,recipeId: freezed == recipeId ? _self.recipeId : recipeId // ignore: cast_nullable_to_non_nullable
as String?,costPriceCents: null == costPriceCents ? _self.costPriceCents : costPriceCents // ignore: cast_nullable_to_non_nullable
as int,totalCostCents: null == totalCostCents ? _self.totalCostCents : totalCostCents // ignore: cast_nullable_to_non_nullable
as int,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ProductionItem>,
  ));
}


}

// dart format on
