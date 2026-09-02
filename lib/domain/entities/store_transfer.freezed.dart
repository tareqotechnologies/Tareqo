// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_transfer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StoreTransfer {

 String get id; int get number; String get fromStoreId; String get fromStoreName; String get toStoreId; String get toStoreName; List<StoreTransferItem> get items; TransferStatus get status;/// Notas/justificativa da transferência.
 String get notes; DateTime? get shippedAt; DateTime? get receivedAt;/// ID do funcionário que autorizou.
 String get authorizedByUserId; DateTime get createdAt;
/// Create a copy of StoreTransfer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreTransferCopyWith<StoreTransfer> get copyWith => _$StoreTransferCopyWithImpl<StoreTransfer>(this as StoreTransfer, _$identity);

  /// Serializes this StoreTransfer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreTransfer&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.fromStoreId, fromStoreId) || other.fromStoreId == fromStoreId)&&(identical(other.fromStoreName, fromStoreName) || other.fromStoreName == fromStoreName)&&(identical(other.toStoreId, toStoreId) || other.toStoreId == toStoreId)&&(identical(other.toStoreName, toStoreName) || other.toStoreName == toStoreName)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.shippedAt, shippedAt) || other.shippedAt == shippedAt)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.authorizedByUserId, authorizedByUserId) || other.authorizedByUserId == authorizedByUserId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,fromStoreId,fromStoreName,toStoreId,toStoreName,const DeepCollectionEquality().hash(items),status,notes,shippedAt,receivedAt,authorizedByUserId,createdAt);

@override
String toString() {
  return 'StoreTransfer(id: $id, number: $number, fromStoreId: $fromStoreId, fromStoreName: $fromStoreName, toStoreId: $toStoreId, toStoreName: $toStoreName, items: $items, status: $status, notes: $notes, shippedAt: $shippedAt, receivedAt: $receivedAt, authorizedByUserId: $authorizedByUserId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StoreTransferCopyWith<$Res>  {
  factory $StoreTransferCopyWith(StoreTransfer value, $Res Function(StoreTransfer) _then) = _$StoreTransferCopyWithImpl;
@useResult
$Res call({
 String id, int number, String fromStoreId, String fromStoreName, String toStoreId, String toStoreName, List<StoreTransferItem> items, TransferStatus status, String notes, DateTime? shippedAt, DateTime? receivedAt, String authorizedByUserId, DateTime createdAt
});




}
/// @nodoc
class _$StoreTransferCopyWithImpl<$Res>
    implements $StoreTransferCopyWith<$Res> {
  _$StoreTransferCopyWithImpl(this._self, this._then);

  final StoreTransfer _self;
  final $Res Function(StoreTransfer) _then;

/// Create a copy of StoreTransfer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? fromStoreId = null,Object? fromStoreName = null,Object? toStoreId = null,Object? toStoreName = null,Object? items = null,Object? status = null,Object? notes = null,Object? shippedAt = freezed,Object? receivedAt = freezed,Object? authorizedByUserId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,fromStoreId: null == fromStoreId ? _self.fromStoreId : fromStoreId // ignore: cast_nullable_to_non_nullable
as String,fromStoreName: null == fromStoreName ? _self.fromStoreName : fromStoreName // ignore: cast_nullable_to_non_nullable
as String,toStoreId: null == toStoreId ? _self.toStoreId : toStoreId // ignore: cast_nullable_to_non_nullable
as String,toStoreName: null == toStoreName ? _self.toStoreName : toStoreName // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<StoreTransferItem>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,shippedAt: freezed == shippedAt ? _self.shippedAt : shippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,authorizedByUserId: null == authorizedByUserId ? _self.authorizedByUserId : authorizedByUserId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [StoreTransfer].
extension StoreTransferPatterns on StoreTransfer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreTransfer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreTransfer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreTransfer value)  $default,){
final _that = this;
switch (_that) {
case _StoreTransfer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreTransfer value)?  $default,){
final _that = this;
switch (_that) {
case _StoreTransfer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int number,  String fromStoreId,  String fromStoreName,  String toStoreId,  String toStoreName,  List<StoreTransferItem> items,  TransferStatus status,  String notes,  DateTime? shippedAt,  DateTime? receivedAt,  String authorizedByUserId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreTransfer() when $default != null:
return $default(_that.id,_that.number,_that.fromStoreId,_that.fromStoreName,_that.toStoreId,_that.toStoreName,_that.items,_that.status,_that.notes,_that.shippedAt,_that.receivedAt,_that.authorizedByUserId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int number,  String fromStoreId,  String fromStoreName,  String toStoreId,  String toStoreName,  List<StoreTransferItem> items,  TransferStatus status,  String notes,  DateTime? shippedAt,  DateTime? receivedAt,  String authorizedByUserId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _StoreTransfer():
return $default(_that.id,_that.number,_that.fromStoreId,_that.fromStoreName,_that.toStoreId,_that.toStoreName,_that.items,_that.status,_that.notes,_that.shippedAt,_that.receivedAt,_that.authorizedByUserId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int number,  String fromStoreId,  String fromStoreName,  String toStoreId,  String toStoreName,  List<StoreTransferItem> items,  TransferStatus status,  String notes,  DateTime? shippedAt,  DateTime? receivedAt,  String authorizedByUserId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StoreTransfer() when $default != null:
return $default(_that.id,_that.number,_that.fromStoreId,_that.fromStoreName,_that.toStoreId,_that.toStoreName,_that.items,_that.status,_that.notes,_that.shippedAt,_that.receivedAt,_that.authorizedByUserId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoreTransfer implements StoreTransfer {
  const _StoreTransfer({required this.id, this.number = 0, required this.fromStoreId, required this.fromStoreName, required this.toStoreId, required this.toStoreName, final  List<StoreTransferItem> items = const <StoreTransferItem>[], this.status = TransferStatus.pending, this.notes = '', this.shippedAt, this.receivedAt, this.authorizedByUserId = '', required this.createdAt}): _items = items;
  factory _StoreTransfer.fromJson(Map<String, dynamic> json) => _$StoreTransferFromJson(json);

@override final  String id;
@override@JsonKey() final  int number;
@override final  String fromStoreId;
@override final  String fromStoreName;
@override final  String toStoreId;
@override final  String toStoreName;
 final  List<StoreTransferItem> _items;
@override@JsonKey() List<StoreTransferItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  TransferStatus status;
/// Notas/justificativa da transferência.
@override@JsonKey() final  String notes;
@override final  DateTime? shippedAt;
@override final  DateTime? receivedAt;
/// ID do funcionário que autorizou.
@override@JsonKey() final  String authorizedByUserId;
@override final  DateTime createdAt;

/// Create a copy of StoreTransfer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreTransferCopyWith<_StoreTransfer> get copyWith => __$StoreTransferCopyWithImpl<_StoreTransfer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoreTransferToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreTransfer&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.fromStoreId, fromStoreId) || other.fromStoreId == fromStoreId)&&(identical(other.fromStoreName, fromStoreName) || other.fromStoreName == fromStoreName)&&(identical(other.toStoreId, toStoreId) || other.toStoreId == toStoreId)&&(identical(other.toStoreName, toStoreName) || other.toStoreName == toStoreName)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.shippedAt, shippedAt) || other.shippedAt == shippedAt)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.authorizedByUserId, authorizedByUserId) || other.authorizedByUserId == authorizedByUserId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,fromStoreId,fromStoreName,toStoreId,toStoreName,const DeepCollectionEquality().hash(_items),status,notes,shippedAt,receivedAt,authorizedByUserId,createdAt);

@override
String toString() {
  return 'StoreTransfer(id: $id, number: $number, fromStoreId: $fromStoreId, fromStoreName: $fromStoreName, toStoreId: $toStoreId, toStoreName: $toStoreName, items: $items, status: $status, notes: $notes, shippedAt: $shippedAt, receivedAt: $receivedAt, authorizedByUserId: $authorizedByUserId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StoreTransferCopyWith<$Res> implements $StoreTransferCopyWith<$Res> {
  factory _$StoreTransferCopyWith(_StoreTransfer value, $Res Function(_StoreTransfer) _then) = __$StoreTransferCopyWithImpl;
@override @useResult
$Res call({
 String id, int number, String fromStoreId, String fromStoreName, String toStoreId, String toStoreName, List<StoreTransferItem> items, TransferStatus status, String notes, DateTime? shippedAt, DateTime? receivedAt, String authorizedByUserId, DateTime createdAt
});




}
/// @nodoc
class __$StoreTransferCopyWithImpl<$Res>
    implements _$StoreTransferCopyWith<$Res> {
  __$StoreTransferCopyWithImpl(this._self, this._then);

  final _StoreTransfer _self;
  final $Res Function(_StoreTransfer) _then;

/// Create a copy of StoreTransfer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? fromStoreId = null,Object? fromStoreName = null,Object? toStoreId = null,Object? toStoreName = null,Object? items = null,Object? status = null,Object? notes = null,Object? shippedAt = freezed,Object? receivedAt = freezed,Object? authorizedByUserId = null,Object? createdAt = null,}) {
  return _then(_StoreTransfer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,fromStoreId: null == fromStoreId ? _self.fromStoreId : fromStoreId // ignore: cast_nullable_to_non_nullable
as String,fromStoreName: null == fromStoreName ? _self.fromStoreName : fromStoreName // ignore: cast_nullable_to_non_nullable
as String,toStoreId: null == toStoreId ? _self.toStoreId : toStoreId // ignore: cast_nullable_to_non_nullable
as String,toStoreName: null == toStoreName ? _self.toStoreName : toStoreName // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<StoreTransferItem>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransferStatus,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,shippedAt: freezed == shippedAt ? _self.shippedAt : shippedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,authorizedByUserId: null == authorizedByUserId ? _self.authorizedByUserId : authorizedByUserId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$StoreTransferItem {

 String get productId; String get productName;/// Quantidade em milésimos.
 int get quantity;
/// Create a copy of StoreTransferItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StoreTransferItemCopyWith<StoreTransferItem> get copyWith => _$StoreTransferItemCopyWithImpl<StoreTransferItem>(this as StoreTransferItem, _$identity);

  /// Serializes this StoreTransferItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StoreTransferItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity);

@override
String toString() {
  return 'StoreTransferItem(productId: $productId, productName: $productName, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $StoreTransferItemCopyWith<$Res>  {
  factory $StoreTransferItemCopyWith(StoreTransferItem value, $Res Function(StoreTransferItem) _then) = _$StoreTransferItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, int quantity
});




}
/// @nodoc
class _$StoreTransferItemCopyWithImpl<$Res>
    implements $StoreTransferItemCopyWith<$Res> {
  _$StoreTransferItemCopyWithImpl(this._self, this._then);

  final StoreTransferItem _self;
  final $Res Function(StoreTransferItem) _then;

/// Create a copy of StoreTransferItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StoreTransferItem].
extension StoreTransferItemPatterns on StoreTransferItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StoreTransferItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StoreTransferItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StoreTransferItem value)  $default,){
final _that = this;
switch (_that) {
case _StoreTransferItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StoreTransferItem value)?  $default,){
final _that = this;
switch (_that) {
case _StoreTransferItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StoreTransferItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity)  $default,) {final _that = this;
switch (_that) {
case _StoreTransferItem():
return $default(_that.productId,_that.productName,_that.quantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _StoreTransferItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StoreTransferItem implements StoreTransferItem {
  const _StoreTransferItem({required this.productId, required this.productName, required this.quantity});
  factory _StoreTransferItem.fromJson(Map<String, dynamic> json) => _$StoreTransferItemFromJson(json);

@override final  String productId;
@override final  String productName;
/// Quantidade em milésimos.
@override final  int quantity;

/// Create a copy of StoreTransferItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StoreTransferItemCopyWith<_StoreTransferItem> get copyWith => __$StoreTransferItemCopyWithImpl<_StoreTransferItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StoreTransferItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StoreTransferItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity);

@override
String toString() {
  return 'StoreTransferItem(productId: $productId, productName: $productName, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$StoreTransferItemCopyWith<$Res> implements $StoreTransferItemCopyWith<$Res> {
  factory _$StoreTransferItemCopyWith(_StoreTransferItem value, $Res Function(_StoreTransferItem) _then) = __$StoreTransferItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, int quantity
});




}
/// @nodoc
class __$StoreTransferItemCopyWithImpl<$Res>
    implements _$StoreTransferItemCopyWith<$Res> {
  __$StoreTransferItemCopyWithImpl(this._self, this._then);

  final _StoreTransferItem _self;
  final $Res Function(_StoreTransferItem) _then;

/// Create a copy of StoreTransferItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,}) {
  return _then(_StoreTransferItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
