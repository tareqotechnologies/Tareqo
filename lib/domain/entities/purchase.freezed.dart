// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'purchase.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PurchaseItem {

 String get productId; String get productName;// Quantidade em MILÉSIMOS de unidade (W11): 1000 = 1 unidade/kg.
 int get quantity;// Preço unitário de compra em CENTAVOS inteiros (W4).
 int get unitPriceCents;// Data de VALIDADE do lote criado por este item (W11 — FIFO).
// `null` para produtos sem validade (não perecíveis): o lote entra no
// FIFO pela data de ENTRADA.
 DateTime? get expiryDate;
/// Create a copy of PurchaseItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseItemCopyWith<PurchaseItem> get copyWith => _$PurchaseItemCopyWithImpl<PurchaseItem>(this as PurchaseItem, _$identity);

  /// Serializes this PurchaseItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitPriceCents,expiryDate);

@override
String toString() {
  return 'PurchaseItem(productId: $productId, productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents, expiryDate: $expiryDate)';
}


}

/// @nodoc
abstract mixin class $PurchaseItemCopyWith<$Res>  {
  factory $PurchaseItemCopyWith(PurchaseItem value, $Res Function(PurchaseItem) _then) = _$PurchaseItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, int quantity, int unitPriceCents, DateTime? expiryDate
});




}
/// @nodoc
class _$PurchaseItemCopyWithImpl<$Res>
    implements $PurchaseItemCopyWith<$Res> {
  _$PurchaseItemCopyWithImpl(this._self, this._then);

  final PurchaseItem _self;
  final $Res Function(PurchaseItem) _then;

/// Create a copy of PurchaseItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitPriceCents = null,Object? expiryDate = freezed,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PurchaseItem].
extension PurchaseItemPatterns on PurchaseItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PurchaseItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PurchaseItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PurchaseItem value)  $default,){
final _that = this;
switch (_that) {
case _PurchaseItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PurchaseItem value)?  $default,){
final _that = this;
switch (_that) {
case _PurchaseItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitPriceCents,  DateTime? expiryDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PurchaseItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents,_that.expiryDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitPriceCents,  DateTime? expiryDate)  $default,) {final _that = this;
switch (_that) {
case _PurchaseItem():
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents,_that.expiryDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  int quantity,  int unitPriceCents,  DateTime? expiryDate)?  $default,) {final _that = this;
switch (_that) {
case _PurchaseItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents,_that.expiryDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PurchaseItem implements PurchaseItem {
  const _PurchaseItem({required this.productId, required this.productName, required this.quantity, required this.unitPriceCents, this.expiryDate});
  factory _PurchaseItem.fromJson(Map<String, dynamic> json) => _$PurchaseItemFromJson(json);

@override final  String productId;
@override final  String productName;
// Quantidade em MILÉSIMOS de unidade (W11): 1000 = 1 unidade/kg.
@override final  int quantity;
// Preço unitário de compra em CENTAVOS inteiros (W4).
@override final  int unitPriceCents;
// Data de VALIDADE do lote criado por este item (W11 — FIFO).
// `null` para produtos sem validade (não perecíveis): o lote entra no
// FIFO pela data de ENTRADA.
@override final  DateTime? expiryDate;

/// Create a copy of PurchaseItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseItemCopyWith<_PurchaseItem> get copyWith => __$PurchaseItemCopyWithImpl<_PurchaseItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PurchaseItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitPriceCents,expiryDate);

@override
String toString() {
  return 'PurchaseItem(productId: $productId, productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents, expiryDate: $expiryDate)';
}


}

/// @nodoc
abstract mixin class _$PurchaseItemCopyWith<$Res> implements $PurchaseItemCopyWith<$Res> {
  factory _$PurchaseItemCopyWith(_PurchaseItem value, $Res Function(_PurchaseItem) _then) = __$PurchaseItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, int quantity, int unitPriceCents, DateTime? expiryDate
});




}
/// @nodoc
class __$PurchaseItemCopyWithImpl<$Res>
    implements _$PurchaseItemCopyWith<$Res> {
  __$PurchaseItemCopyWithImpl(this._self, this._then);

  final _PurchaseItem _self;
  final $Res Function(_PurchaseItem) _then;

/// Create a copy of PurchaseItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitPriceCents = null,Object? expiryDate = freezed,}) {
  return _then(_PurchaseItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Purchase {

 String get id;// Número SEQUENCIAL da compra DENTRO da loja (ex.: C-00001, C-00002).
// Atribuído pelo banco no insert — SQLite: MAX+1 por loja dentro da
// transação; Supabase: RPC process_purchase com advisory lock por loja.
// O default 0 nunca é persistido (é substituído na gravação).
 int get number;// Loja que realizou a compra (Fase 2 do multi-tenancy) — a entrada
// de estoque é por loja.
 String get storeId; String get supplierName; List<PurchaseItem> get items;// Valor TOTAL da compra em CENTAVOS inteiros (W4).
 int get totalAmountCents;// Forma de pagamento usada para pagar o fornecedor (mesmo enum de
// Vendas). DEFAULT cash: compras antigas não registravam o método —
// a migração interpreta como pagamento à vista.
 PaymentMethod get paymentMethod; DateTime get dateTime;
/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseCopyWith<Purchase> get copyWith => _$PurchaseCopyWithImpl<Purchase>(this as Purchase, _$identity);

  /// Serializes this Purchase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Purchase&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.supplierName, supplierName) || other.supplierName == supplierName)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalAmountCents, totalAmountCents) || other.totalAmountCents == totalAmountCents)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,storeId,supplierName,const DeepCollectionEquality().hash(items),totalAmountCents,paymentMethod,dateTime);

@override
String toString() {
  return 'Purchase(id: $id, number: $number, storeId: $storeId, supplierName: $supplierName, items: $items, totalAmountCents: $totalAmountCents, paymentMethod: $paymentMethod, dateTime: $dateTime)';
}


}

/// @nodoc
abstract mixin class $PurchaseCopyWith<$Res>  {
  factory $PurchaseCopyWith(Purchase value, $Res Function(Purchase) _then) = _$PurchaseCopyWithImpl;
@useResult
$Res call({
 String id, int number, String storeId, String supplierName, List<PurchaseItem> items, int totalAmountCents, PaymentMethod paymentMethod, DateTime dateTime
});




}
/// @nodoc
class _$PurchaseCopyWithImpl<$Res>
    implements $PurchaseCopyWith<$Res> {
  _$PurchaseCopyWithImpl(this._self, this._then);

  final Purchase _self;
  final $Res Function(Purchase) _then;

/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? storeId = null,Object? supplierName = null,Object? items = null,Object? totalAmountCents = null,Object? paymentMethod = null,Object? dateTime = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,supplierName: null == supplierName ? _self.supplierName : supplierName // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PurchaseItem>,totalAmountCents: null == totalAmountCents ? _self.totalAmountCents : totalAmountCents // ignore: cast_nullable_to_non_nullable
as int,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Purchase].
extension PurchasePatterns on Purchase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Purchase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Purchase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Purchase value)  $default,){
final _that = this;
switch (_that) {
case _Purchase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Purchase value)?  $default,){
final _that = this;
switch (_that) {
case _Purchase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int number,  String storeId,  String supplierName,  List<PurchaseItem> items,  int totalAmountCents,  PaymentMethod paymentMethod,  DateTime dateTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Purchase() when $default != null:
return $default(_that.id,_that.number,_that.storeId,_that.supplierName,_that.items,_that.totalAmountCents,_that.paymentMethod,_that.dateTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int number,  String storeId,  String supplierName,  List<PurchaseItem> items,  int totalAmountCents,  PaymentMethod paymentMethod,  DateTime dateTime)  $default,) {final _that = this;
switch (_that) {
case _Purchase():
return $default(_that.id,_that.number,_that.storeId,_that.supplierName,_that.items,_that.totalAmountCents,_that.paymentMethod,_that.dateTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int number,  String storeId,  String supplierName,  List<PurchaseItem> items,  int totalAmountCents,  PaymentMethod paymentMethod,  DateTime dateTime)?  $default,) {final _that = this;
switch (_that) {
case _Purchase() when $default != null:
return $default(_that.id,_that.number,_that.storeId,_that.supplierName,_that.items,_that.totalAmountCents,_that.paymentMethod,_that.dateTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Purchase implements Purchase {
  const _Purchase({required this.id, this.number = 0, this.storeId = 'st1', required this.supplierName, required final  List<PurchaseItem> items, required this.totalAmountCents, this.paymentMethod = PaymentMethod.cash, required this.dateTime}): _items = items;
  factory _Purchase.fromJson(Map<String, dynamic> json) => _$PurchaseFromJson(json);

@override final  String id;
// Número SEQUENCIAL da compra DENTRO da loja (ex.: C-00001, C-00002).
// Atribuído pelo banco no insert — SQLite: MAX+1 por loja dentro da
// transação; Supabase: RPC process_purchase com advisory lock por loja.
// O default 0 nunca é persistido (é substituído na gravação).
@override@JsonKey() final  int number;
// Loja que realizou a compra (Fase 2 do multi-tenancy) — a entrada
// de estoque é por loja.
@override@JsonKey() final  String storeId;
@override final  String supplierName;
 final  List<PurchaseItem> _items;
@override List<PurchaseItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

// Valor TOTAL da compra em CENTAVOS inteiros (W4).
@override final  int totalAmountCents;
// Forma de pagamento usada para pagar o fornecedor (mesmo enum de
// Vendas). DEFAULT cash: compras antigas não registravam o método —
// a migração interpreta como pagamento à vista.
@override@JsonKey() final  PaymentMethod paymentMethod;
@override final  DateTime dateTime;

/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PurchaseCopyWith<_Purchase> get copyWith => __$PurchaseCopyWithImpl<_Purchase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PurchaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Purchase&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.supplierName, supplierName) || other.supplierName == supplierName)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalAmountCents, totalAmountCents) || other.totalAmountCents == totalAmountCents)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.dateTime, dateTime) || other.dateTime == dateTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,storeId,supplierName,const DeepCollectionEquality().hash(_items),totalAmountCents,paymentMethod,dateTime);

@override
String toString() {
  return 'Purchase(id: $id, number: $number, storeId: $storeId, supplierName: $supplierName, items: $items, totalAmountCents: $totalAmountCents, paymentMethod: $paymentMethod, dateTime: $dateTime)';
}


}

/// @nodoc
abstract mixin class _$PurchaseCopyWith<$Res> implements $PurchaseCopyWith<$Res> {
  factory _$PurchaseCopyWith(_Purchase value, $Res Function(_Purchase) _then) = __$PurchaseCopyWithImpl;
@override @useResult
$Res call({
 String id, int number, String storeId, String supplierName, List<PurchaseItem> items, int totalAmountCents, PaymentMethod paymentMethod, DateTime dateTime
});




}
/// @nodoc
class __$PurchaseCopyWithImpl<$Res>
    implements _$PurchaseCopyWith<$Res> {
  __$PurchaseCopyWithImpl(this._self, this._then);

  final _Purchase _self;
  final $Res Function(_Purchase) _then;

/// Create a copy of Purchase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? storeId = null,Object? supplierName = null,Object? items = null,Object? totalAmountCents = null,Object? paymentMethod = null,Object? dateTime = null,}) {
  return _then(_Purchase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,supplierName: null == supplierName ? _self.supplierName : supplierName // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PurchaseItem>,totalAmountCents: null == totalAmountCents ? _self.totalAmountCents : totalAmountCents // ignore: cast_nullable_to_non_nullable
as int,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as PaymentMethod,dateTime: null == dateTime ? _self.dateTime : dateTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
