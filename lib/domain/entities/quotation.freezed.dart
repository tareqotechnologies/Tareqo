// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quotation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Quotation {

 String get id; int get number; String get storeId; String get customerId; String get customerName; String get customerPhone; List<QuotationItem> get items;/// Valor total em centavos.
 int get totalAmountCents; QuotationStatus get status;/// Desconto global em centavos (opcional).
 int get discountCents;/// Notas/observações visíveis ao cliente.
 String get notes;/// Data de validade da cotação.
 DateTime get validUntil; DateTime? get sentAt; DateTime? get acceptedAt; DateTime? get rejectedAt;/// ID da venda gerada quando a cotação é convertida.
 String? get convertedSaleId; DateTime get createdAt;
/// Create a copy of Quotation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuotationCopyWith<Quotation> get copyWith => _$QuotationCopyWithImpl<Quotation>(this as Quotation, _$identity);

  /// Serializes this Quotation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Quotation&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.customerPhone, customerPhone) || other.customerPhone == customerPhone)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalAmountCents, totalAmountCents) || other.totalAmountCents == totalAmountCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.rejectedAt, rejectedAt) || other.rejectedAt == rejectedAt)&&(identical(other.convertedSaleId, convertedSaleId) || other.convertedSaleId == convertedSaleId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,storeId,customerId,customerName,customerPhone,const DeepCollectionEquality().hash(items),totalAmountCents,status,discountCents,notes,validUntil,sentAt,acceptedAt,rejectedAt,convertedSaleId,createdAt);

@override
String toString() {
  return 'Quotation(id: $id, number: $number, storeId: $storeId, customerId: $customerId, customerName: $customerName, customerPhone: $customerPhone, items: $items, totalAmountCents: $totalAmountCents, status: $status, discountCents: $discountCents, notes: $notes, validUntil: $validUntil, sentAt: $sentAt, acceptedAt: $acceptedAt, rejectedAt: $rejectedAt, convertedSaleId: $convertedSaleId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $QuotationCopyWith<$Res>  {
  factory $QuotationCopyWith(Quotation value, $Res Function(Quotation) _then) = _$QuotationCopyWithImpl;
@useResult
$Res call({
 String id, int number, String storeId, String customerId, String customerName, String customerPhone, List<QuotationItem> items, int totalAmountCents, QuotationStatus status, int discountCents, String notes, DateTime validUntil, DateTime? sentAt, DateTime? acceptedAt, DateTime? rejectedAt, String? convertedSaleId, DateTime createdAt
});




}
/// @nodoc
class _$QuotationCopyWithImpl<$Res>
    implements $QuotationCopyWith<$Res> {
  _$QuotationCopyWithImpl(this._self, this._then);

  final Quotation _self;
  final $Res Function(Quotation) _then;

/// Create a copy of Quotation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? storeId = null,Object? customerId = null,Object? customerName = null,Object? customerPhone = null,Object? items = null,Object? totalAmountCents = null,Object? status = null,Object? discountCents = null,Object? notes = null,Object? validUntil = null,Object? sentAt = freezed,Object? acceptedAt = freezed,Object? rejectedAt = freezed,Object? convertedSaleId = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,customerPhone: null == customerPhone ? _self.customerPhone : customerPhone // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<QuotationItem>,totalAmountCents: null == totalAmountCents ? _self.totalAmountCents : totalAmountCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuotationStatus,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,validUntil: null == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectedAt: freezed == rejectedAt ? _self.rejectedAt : rejectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,convertedSaleId: freezed == convertedSaleId ? _self.convertedSaleId : convertedSaleId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Quotation].
extension QuotationPatterns on Quotation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Quotation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Quotation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Quotation value)  $default,){
final _that = this;
switch (_that) {
case _Quotation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Quotation value)?  $default,){
final _that = this;
switch (_that) {
case _Quotation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int number,  String storeId,  String customerId,  String customerName,  String customerPhone,  List<QuotationItem> items,  int totalAmountCents,  QuotationStatus status,  int discountCents,  String notes,  DateTime validUntil,  DateTime? sentAt,  DateTime? acceptedAt,  DateTime? rejectedAt,  String? convertedSaleId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Quotation() when $default != null:
return $default(_that.id,_that.number,_that.storeId,_that.customerId,_that.customerName,_that.customerPhone,_that.items,_that.totalAmountCents,_that.status,_that.discountCents,_that.notes,_that.validUntil,_that.sentAt,_that.acceptedAt,_that.rejectedAt,_that.convertedSaleId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int number,  String storeId,  String customerId,  String customerName,  String customerPhone,  List<QuotationItem> items,  int totalAmountCents,  QuotationStatus status,  int discountCents,  String notes,  DateTime validUntil,  DateTime? sentAt,  DateTime? acceptedAt,  DateTime? rejectedAt,  String? convertedSaleId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Quotation():
return $default(_that.id,_that.number,_that.storeId,_that.customerId,_that.customerName,_that.customerPhone,_that.items,_that.totalAmountCents,_that.status,_that.discountCents,_that.notes,_that.validUntil,_that.sentAt,_that.acceptedAt,_that.rejectedAt,_that.convertedSaleId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int number,  String storeId,  String customerId,  String customerName,  String customerPhone,  List<QuotationItem> items,  int totalAmountCents,  QuotationStatus status,  int discountCents,  String notes,  DateTime validUntil,  DateTime? sentAt,  DateTime? acceptedAt,  DateTime? rejectedAt,  String? convertedSaleId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Quotation() when $default != null:
return $default(_that.id,_that.number,_that.storeId,_that.customerId,_that.customerName,_that.customerPhone,_that.items,_that.totalAmountCents,_that.status,_that.discountCents,_that.notes,_that.validUntil,_that.sentAt,_that.acceptedAt,_that.rejectedAt,_that.convertedSaleId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Quotation implements Quotation {
  const _Quotation({required this.id, this.number = 0, required this.storeId, required this.customerId, required this.customerName, this.customerPhone = '', final  List<QuotationItem> items = const <QuotationItem>[], required this.totalAmountCents, this.status = QuotationStatus.draft, this.discountCents = 0, this.notes = '', required this.validUntil, this.sentAt, this.acceptedAt, this.rejectedAt, this.convertedSaleId, required this.createdAt}): _items = items;
  factory _Quotation.fromJson(Map<String, dynamic> json) => _$QuotationFromJson(json);

@override final  String id;
@override@JsonKey() final  int number;
@override final  String storeId;
@override final  String customerId;
@override final  String customerName;
@override@JsonKey() final  String customerPhone;
 final  List<QuotationItem> _items;
@override@JsonKey() List<QuotationItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Valor total em centavos.
@override final  int totalAmountCents;
@override@JsonKey() final  QuotationStatus status;
/// Desconto global em centavos (opcional).
@override@JsonKey() final  int discountCents;
/// Notas/observações visíveis ao cliente.
@override@JsonKey() final  String notes;
/// Data de validade da cotação.
@override final  DateTime validUntil;
@override final  DateTime? sentAt;
@override final  DateTime? acceptedAt;
@override final  DateTime? rejectedAt;
/// ID da venda gerada quando a cotação é convertida.
@override final  String? convertedSaleId;
@override final  DateTime createdAt;

/// Create a copy of Quotation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuotationCopyWith<_Quotation> get copyWith => __$QuotationCopyWithImpl<_Quotation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuotationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Quotation&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.customerPhone, customerPhone) || other.customerPhone == customerPhone)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalAmountCents, totalAmountCents) || other.totalAmountCents == totalAmountCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.rejectedAt, rejectedAt) || other.rejectedAt == rejectedAt)&&(identical(other.convertedSaleId, convertedSaleId) || other.convertedSaleId == convertedSaleId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,storeId,customerId,customerName,customerPhone,const DeepCollectionEquality().hash(_items),totalAmountCents,status,discountCents,notes,validUntil,sentAt,acceptedAt,rejectedAt,convertedSaleId,createdAt);

@override
String toString() {
  return 'Quotation(id: $id, number: $number, storeId: $storeId, customerId: $customerId, customerName: $customerName, customerPhone: $customerPhone, items: $items, totalAmountCents: $totalAmountCents, status: $status, discountCents: $discountCents, notes: $notes, validUntil: $validUntil, sentAt: $sentAt, acceptedAt: $acceptedAt, rejectedAt: $rejectedAt, convertedSaleId: $convertedSaleId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$QuotationCopyWith<$Res> implements $QuotationCopyWith<$Res> {
  factory _$QuotationCopyWith(_Quotation value, $Res Function(_Quotation) _then) = __$QuotationCopyWithImpl;
@override @useResult
$Res call({
 String id, int number, String storeId, String customerId, String customerName, String customerPhone, List<QuotationItem> items, int totalAmountCents, QuotationStatus status, int discountCents, String notes, DateTime validUntil, DateTime? sentAt, DateTime? acceptedAt, DateTime? rejectedAt, String? convertedSaleId, DateTime createdAt
});




}
/// @nodoc
class __$QuotationCopyWithImpl<$Res>
    implements _$QuotationCopyWith<$Res> {
  __$QuotationCopyWithImpl(this._self, this._then);

  final _Quotation _self;
  final $Res Function(_Quotation) _then;

/// Create a copy of Quotation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? storeId = null,Object? customerId = null,Object? customerName = null,Object? customerPhone = null,Object? items = null,Object? totalAmountCents = null,Object? status = null,Object? discountCents = null,Object? notes = null,Object? validUntil = null,Object? sentAt = freezed,Object? acceptedAt = freezed,Object? rejectedAt = freezed,Object? convertedSaleId = freezed,Object? createdAt = null,}) {
  return _then(_Quotation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,customerPhone: null == customerPhone ? _self.customerPhone : customerPhone // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<QuotationItem>,totalAmountCents: null == totalAmountCents ? _self.totalAmountCents : totalAmountCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuotationStatus,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,validUntil: null == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as DateTime,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,rejectedAt: freezed == rejectedAt ? _self.rejectedAt : rejectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,convertedSaleId: freezed == convertedSaleId ? _self.convertedSaleId : convertedSaleId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$QuotationItem {

 String get productId; String get productName;/// Quantidade em milésimos (1000 = 1 unidade).
 int get quantity;/// Preço unitário proposto em centavos.
 int get unitPriceCents;
/// Create a copy of QuotationItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuotationItemCopyWith<QuotationItem> get copyWith => _$QuotationItemCopyWithImpl<QuotationItem>(this as QuotationItem, _$identity);

  /// Serializes this QuotationItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuotationItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitPriceCents);

@override
String toString() {
  return 'QuotationItem(productId: $productId, productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents)';
}


}

/// @nodoc
abstract mixin class $QuotationItemCopyWith<$Res>  {
  factory $QuotationItemCopyWith(QuotationItem value, $Res Function(QuotationItem) _then) = _$QuotationItemCopyWithImpl;
@useResult
$Res call({
 String productId, String productName, int quantity, int unitPriceCents
});




}
/// @nodoc
class _$QuotationItemCopyWithImpl<$Res>
    implements $QuotationItemCopyWith<$Res> {
  _$QuotationItemCopyWithImpl(this._self, this._then);

  final QuotationItem _self;
  final $Res Function(QuotationItem) _then;

/// Create a copy of QuotationItem
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


/// Adds pattern-matching-related methods to [QuotationItem].
extension QuotationItemPatterns on QuotationItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuotationItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuotationItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuotationItem value)  $default,){
final _that = this;
switch (_that) {
case _QuotationItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuotationItem value)?  $default,){
final _that = this;
switch (_that) {
case _QuotationItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitPriceCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuotationItem() when $default != null:
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
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productId,  String productName,  int quantity,  int unitPriceCents)  $default,) {final _that = this;
switch (_that) {
case _QuotationItem():
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productId,  String productName,  int quantity,  int unitPriceCents)?  $default,) {final _that = this;
switch (_that) {
case _QuotationItem() when $default != null:
return $default(_that.productId,_that.productName,_that.quantity,_that.unitPriceCents);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuotationItem implements QuotationItem {
  const _QuotationItem({required this.productId, required this.productName, required this.quantity, required this.unitPriceCents});
  factory _QuotationItem.fromJson(Map<String, dynamic> json) => _$QuotationItemFromJson(json);

@override final  String productId;
@override final  String productName;
/// Quantidade em milésimos (1000 = 1 unidade).
@override final  int quantity;
/// Preço unitário proposto em centavos.
@override final  int unitPriceCents;

/// Create a copy of QuotationItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuotationItemCopyWith<_QuotationItem> get copyWith => __$QuotationItemCopyWithImpl<_QuotationItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuotationItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuotationItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productName,quantity,unitPriceCents);

@override
String toString() {
  return 'QuotationItem(productId: $productId, productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents)';
}


}

/// @nodoc
abstract mixin class _$QuotationItemCopyWith<$Res> implements $QuotationItemCopyWith<$Res> {
  factory _$QuotationItemCopyWith(_QuotationItem value, $Res Function(_QuotationItem) _then) = __$QuotationItemCopyWithImpl;
@override @useResult
$Res call({
 String productId, String productName, int quantity, int unitPriceCents
});




}
/// @nodoc
class __$QuotationItemCopyWithImpl<$Res>
    implements _$QuotationItemCopyWith<$Res> {
  __$QuotationItemCopyWithImpl(this._self, this._then);

  final _QuotationItem _self;
  final $Res Function(_QuotationItem) _then;

/// Create a copy of QuotationItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productName = null,Object? quantity = null,Object? unitPriceCents = null,}) {
  return _then(_QuotationItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
