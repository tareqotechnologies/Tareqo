// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomInvoice {

 String get id; int get number; String get storeId;/// Dados do cliente na factura (snapshot — pode não ter Customer entity).
 String get clientName; String get clientPhone; String get clientEmail; String get clientAddress;/// NIF/ NUIT do cliente (opcional).
 String get clientTaxId; List<CustomInvoiceItem> get items;/// Valor total em centavos.
 int get totalAmountCents;/// Desconto em centavos.
 int get discountCents;/// Imposto (IVA) em centavos.
 int get taxCents;/// Notas visíveis ao cliente (rodapé da factura).
 String get notes;/// Forma de pagamento registada.
 String get paymentMethod;/// Referência de pagamento (ex.: M-Pesa confirmation code).
 String get paymentReference;/// Se foi exportada/exportável como PDF.
 bool get exportedPdf; DateTime get createdAt;
/// Create a copy of CustomInvoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomInvoiceCopyWith<CustomInvoice> get copyWith => _$CustomInvoiceCopyWithImpl<CustomInvoice>(this as CustomInvoice, _$identity);

  /// Serializes this CustomInvoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientPhone, clientPhone) || other.clientPhone == clientPhone)&&(identical(other.clientEmail, clientEmail) || other.clientEmail == clientEmail)&&(identical(other.clientAddress, clientAddress) || other.clientAddress == clientAddress)&&(identical(other.clientTaxId, clientTaxId) || other.clientTaxId == clientTaxId)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalAmountCents, totalAmountCents) || other.totalAmountCents == totalAmountCents)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.taxCents, taxCents) || other.taxCents == taxCents)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentReference, paymentReference) || other.paymentReference == paymentReference)&&(identical(other.exportedPdf, exportedPdf) || other.exportedPdf == exportedPdf)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,storeId,clientName,clientPhone,clientEmail,clientAddress,clientTaxId,const DeepCollectionEquality().hash(items),totalAmountCents,discountCents,taxCents,notes,paymentMethod,paymentReference,exportedPdf,createdAt);

@override
String toString() {
  return 'CustomInvoice(id: $id, number: $number, storeId: $storeId, clientName: $clientName, clientPhone: $clientPhone, clientEmail: $clientEmail, clientAddress: $clientAddress, clientTaxId: $clientTaxId, items: $items, totalAmountCents: $totalAmountCents, discountCents: $discountCents, taxCents: $taxCents, notes: $notes, paymentMethod: $paymentMethod, paymentReference: $paymentReference, exportedPdf: $exportedPdf, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CustomInvoiceCopyWith<$Res>  {
  factory $CustomInvoiceCopyWith(CustomInvoice value, $Res Function(CustomInvoice) _then) = _$CustomInvoiceCopyWithImpl;
@useResult
$Res call({
 String id, int number, String storeId, String clientName, String clientPhone, String clientEmail, String clientAddress, String clientTaxId, List<CustomInvoiceItem> items, int totalAmountCents, int discountCents, int taxCents, String notes, String paymentMethod, String paymentReference, bool exportedPdf, DateTime createdAt
});




}
/// @nodoc
class _$CustomInvoiceCopyWithImpl<$Res>
    implements $CustomInvoiceCopyWith<$Res> {
  _$CustomInvoiceCopyWithImpl(this._self, this._then);

  final CustomInvoice _self;
  final $Res Function(CustomInvoice) _then;

/// Create a copy of CustomInvoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? storeId = null,Object? clientName = null,Object? clientPhone = null,Object? clientEmail = null,Object? clientAddress = null,Object? clientTaxId = null,Object? items = null,Object? totalAmountCents = null,Object? discountCents = null,Object? taxCents = null,Object? notes = null,Object? paymentMethod = null,Object? paymentReference = null,Object? exportedPdf = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientPhone: null == clientPhone ? _self.clientPhone : clientPhone // ignore: cast_nullable_to_non_nullable
as String,clientEmail: null == clientEmail ? _self.clientEmail : clientEmail // ignore: cast_nullable_to_non_nullable
as String,clientAddress: null == clientAddress ? _self.clientAddress : clientAddress // ignore: cast_nullable_to_non_nullable
as String,clientTaxId: null == clientTaxId ? _self.clientTaxId : clientTaxId // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CustomInvoiceItem>,totalAmountCents: null == totalAmountCents ? _self.totalAmountCents : totalAmountCents // ignore: cast_nullable_to_non_nullable
as int,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,taxCents: null == taxCents ? _self.taxCents : taxCents // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,paymentReference: null == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String,exportedPdf: null == exportedPdf ? _self.exportedPdf : exportedPdf // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomInvoice].
extension CustomInvoicePatterns on CustomInvoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomInvoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomInvoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomInvoice value)  $default,){
final _that = this;
switch (_that) {
case _CustomInvoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomInvoice value)?  $default,){
final _that = this;
switch (_that) {
case _CustomInvoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int number,  String storeId,  String clientName,  String clientPhone,  String clientEmail,  String clientAddress,  String clientTaxId,  List<CustomInvoiceItem> items,  int totalAmountCents,  int discountCents,  int taxCents,  String notes,  String paymentMethod,  String paymentReference,  bool exportedPdf,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomInvoice() when $default != null:
return $default(_that.id,_that.number,_that.storeId,_that.clientName,_that.clientPhone,_that.clientEmail,_that.clientAddress,_that.clientTaxId,_that.items,_that.totalAmountCents,_that.discountCents,_that.taxCents,_that.notes,_that.paymentMethod,_that.paymentReference,_that.exportedPdf,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int number,  String storeId,  String clientName,  String clientPhone,  String clientEmail,  String clientAddress,  String clientTaxId,  List<CustomInvoiceItem> items,  int totalAmountCents,  int discountCents,  int taxCents,  String notes,  String paymentMethod,  String paymentReference,  bool exportedPdf,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _CustomInvoice():
return $default(_that.id,_that.number,_that.storeId,_that.clientName,_that.clientPhone,_that.clientEmail,_that.clientAddress,_that.clientTaxId,_that.items,_that.totalAmountCents,_that.discountCents,_that.taxCents,_that.notes,_that.paymentMethod,_that.paymentReference,_that.exportedPdf,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int number,  String storeId,  String clientName,  String clientPhone,  String clientEmail,  String clientAddress,  String clientTaxId,  List<CustomInvoiceItem> items,  int totalAmountCents,  int discountCents,  int taxCents,  String notes,  String paymentMethod,  String paymentReference,  bool exportedPdf,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomInvoice() when $default != null:
return $default(_that.id,_that.number,_that.storeId,_that.clientName,_that.clientPhone,_that.clientEmail,_that.clientAddress,_that.clientTaxId,_that.items,_that.totalAmountCents,_that.discountCents,_that.taxCents,_that.notes,_that.paymentMethod,_that.paymentReference,_that.exportedPdf,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomInvoice implements CustomInvoice {
  const _CustomInvoice({required this.id, this.number = 0, required this.storeId, required this.clientName, this.clientPhone = '', this.clientEmail = '', this.clientAddress = '', this.clientTaxId = '', final  List<CustomInvoiceItem> items = const <CustomInvoiceItem>[], required this.totalAmountCents, this.discountCents = 0, this.taxCents = 0, this.notes = '', this.paymentMethod = '', this.paymentReference = '', this.exportedPdf = false, required this.createdAt}): _items = items;
  factory _CustomInvoice.fromJson(Map<String, dynamic> json) => _$CustomInvoiceFromJson(json);

@override final  String id;
@override@JsonKey() final  int number;
@override final  String storeId;
/// Dados do cliente na factura (snapshot — pode não ter Customer entity).
@override final  String clientName;
@override@JsonKey() final  String clientPhone;
@override@JsonKey() final  String clientEmail;
@override@JsonKey() final  String clientAddress;
/// NIF/ NUIT do cliente (opcional).
@override@JsonKey() final  String clientTaxId;
 final  List<CustomInvoiceItem> _items;
@override@JsonKey() List<CustomInvoiceItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Valor total em centavos.
@override final  int totalAmountCents;
/// Desconto em centavos.
@override@JsonKey() final  int discountCents;
/// Imposto (IVA) em centavos.
@override@JsonKey() final  int taxCents;
/// Notas visíveis ao cliente (rodapé da factura).
@override@JsonKey() final  String notes;
/// Forma de pagamento registada.
@override@JsonKey() final  String paymentMethod;
/// Referência de pagamento (ex.: M-Pesa confirmation code).
@override@JsonKey() final  String paymentReference;
/// Se foi exportada/exportável como PDF.
@override@JsonKey() final  bool exportedPdf;
@override final  DateTime createdAt;

/// Create a copy of CustomInvoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomInvoiceCopyWith<_CustomInvoice> get copyWith => __$CustomInvoiceCopyWithImpl<_CustomInvoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomInvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomInvoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientPhone, clientPhone) || other.clientPhone == clientPhone)&&(identical(other.clientEmail, clientEmail) || other.clientEmail == clientEmail)&&(identical(other.clientAddress, clientAddress) || other.clientAddress == clientAddress)&&(identical(other.clientTaxId, clientTaxId) || other.clientTaxId == clientTaxId)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalAmountCents, totalAmountCents) || other.totalAmountCents == totalAmountCents)&&(identical(other.discountCents, discountCents) || other.discountCents == discountCents)&&(identical(other.taxCents, taxCents) || other.taxCents == taxCents)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.paymentReference, paymentReference) || other.paymentReference == paymentReference)&&(identical(other.exportedPdf, exportedPdf) || other.exportedPdf == exportedPdf)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,storeId,clientName,clientPhone,clientEmail,clientAddress,clientTaxId,const DeepCollectionEquality().hash(_items),totalAmountCents,discountCents,taxCents,notes,paymentMethod,paymentReference,exportedPdf,createdAt);

@override
String toString() {
  return 'CustomInvoice(id: $id, number: $number, storeId: $storeId, clientName: $clientName, clientPhone: $clientPhone, clientEmail: $clientEmail, clientAddress: $clientAddress, clientTaxId: $clientTaxId, items: $items, totalAmountCents: $totalAmountCents, discountCents: $discountCents, taxCents: $taxCents, notes: $notes, paymentMethod: $paymentMethod, paymentReference: $paymentReference, exportedPdf: $exportedPdf, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CustomInvoiceCopyWith<$Res> implements $CustomInvoiceCopyWith<$Res> {
  factory _$CustomInvoiceCopyWith(_CustomInvoice value, $Res Function(_CustomInvoice) _then) = __$CustomInvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, int number, String storeId, String clientName, String clientPhone, String clientEmail, String clientAddress, String clientTaxId, List<CustomInvoiceItem> items, int totalAmountCents, int discountCents, int taxCents, String notes, String paymentMethod, String paymentReference, bool exportedPdf, DateTime createdAt
});




}
/// @nodoc
class __$CustomInvoiceCopyWithImpl<$Res>
    implements _$CustomInvoiceCopyWith<$Res> {
  __$CustomInvoiceCopyWithImpl(this._self, this._then);

  final _CustomInvoice _self;
  final $Res Function(_CustomInvoice) _then;

/// Create a copy of CustomInvoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? storeId = null,Object? clientName = null,Object? clientPhone = null,Object? clientEmail = null,Object? clientAddress = null,Object? clientTaxId = null,Object? items = null,Object? totalAmountCents = null,Object? discountCents = null,Object? taxCents = null,Object? notes = null,Object? paymentMethod = null,Object? paymentReference = null,Object? exportedPdf = null,Object? createdAt = null,}) {
  return _then(_CustomInvoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientPhone: null == clientPhone ? _self.clientPhone : clientPhone // ignore: cast_nullable_to_non_nullable
as String,clientEmail: null == clientEmail ? _self.clientEmail : clientEmail // ignore: cast_nullable_to_non_nullable
as String,clientAddress: null == clientAddress ? _self.clientAddress : clientAddress // ignore: cast_nullable_to_non_nullable
as String,clientTaxId: null == clientTaxId ? _self.clientTaxId : clientTaxId // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CustomInvoiceItem>,totalAmountCents: null == totalAmountCents ? _self.totalAmountCents : totalAmountCents // ignore: cast_nullable_to_non_nullable
as int,discountCents: null == discountCents ? _self.discountCents : discountCents // ignore: cast_nullable_to_non_nullable
as int,taxCents: null == taxCents ? _self.taxCents : taxCents // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,paymentReference: null == paymentReference ? _self.paymentReference : paymentReference // ignore: cast_nullable_to_non_nullable
as String,exportedPdf: null == exportedPdf ? _self.exportedPdf : exportedPdf // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CustomInvoiceItem {

 String get productName;/// Quantidade em milésimos.
 int get quantity;/// Preço unitário em centavos.
 int get unitPriceCents;/// Subtotal (quantity * unitPrice) em centavos.
 int get subtotalCents;/// Unidade (un, kg, l, etc).
 String get unit;
/// Create a copy of CustomInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomInvoiceItemCopyWith<CustomInvoiceItem> get copyWith => _$CustomInvoiceItemCopyWithImpl<CustomInvoiceItem>(this as CustomInvoiceItem, _$identity);

  /// Serializes this CustomInvoiceItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomInvoiceItem&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.subtotalCents, subtotalCents) || other.subtotalCents == subtotalCents)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productName,quantity,unitPriceCents,subtotalCents,unit);

@override
String toString() {
  return 'CustomInvoiceItem(productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents, subtotalCents: $subtotalCents, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $CustomInvoiceItemCopyWith<$Res>  {
  factory $CustomInvoiceItemCopyWith(CustomInvoiceItem value, $Res Function(CustomInvoiceItem) _then) = _$CustomInvoiceItemCopyWithImpl;
@useResult
$Res call({
 String productName, int quantity, int unitPriceCents, int subtotalCents, String unit
});




}
/// @nodoc
class _$CustomInvoiceItemCopyWithImpl<$Res>
    implements $CustomInvoiceItemCopyWith<$Res> {
  _$CustomInvoiceItemCopyWithImpl(this._self, this._then);

  final CustomInvoiceItem _self;
  final $Res Function(CustomInvoiceItem) _then;

/// Create a copy of CustomInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productName = null,Object? quantity = null,Object? unitPriceCents = null,Object? subtotalCents = null,Object? unit = null,}) {
  return _then(_self.copyWith(
productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,subtotalCents: null == subtotalCents ? _self.subtotalCents : subtotalCents // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomInvoiceItem].
extension CustomInvoiceItemPatterns on CustomInvoiceItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomInvoiceItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomInvoiceItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomInvoiceItem value)  $default,){
final _that = this;
switch (_that) {
case _CustomInvoiceItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomInvoiceItem value)?  $default,){
final _that = this;
switch (_that) {
case _CustomInvoiceItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productName,  int quantity,  int unitPriceCents,  int subtotalCents,  String unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomInvoiceItem() when $default != null:
return $default(_that.productName,_that.quantity,_that.unitPriceCents,_that.subtotalCents,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productName,  int quantity,  int unitPriceCents,  int subtotalCents,  String unit)  $default,) {final _that = this;
switch (_that) {
case _CustomInvoiceItem():
return $default(_that.productName,_that.quantity,_that.unitPriceCents,_that.subtotalCents,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productName,  int quantity,  int unitPriceCents,  int subtotalCents,  String unit)?  $default,) {final _that = this;
switch (_that) {
case _CustomInvoiceItem() when $default != null:
return $default(_that.productName,_that.quantity,_that.unitPriceCents,_that.subtotalCents,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomInvoiceItem implements CustomInvoiceItem {
  const _CustomInvoiceItem({required this.productName, required this.quantity, required this.unitPriceCents, required this.subtotalCents, this.unit = 'un'});
  factory _CustomInvoiceItem.fromJson(Map<String, dynamic> json) => _$CustomInvoiceItemFromJson(json);

@override final  String productName;
/// Quantidade em milésimos.
@override final  int quantity;
/// Preço unitário em centavos.
@override final  int unitPriceCents;
/// Subtotal (quantity * unitPrice) em centavos.
@override final  int subtotalCents;
/// Unidade (un, kg, l, etc).
@override@JsonKey() final  String unit;

/// Create a copy of CustomInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomInvoiceItemCopyWith<_CustomInvoiceItem> get copyWith => __$CustomInvoiceItemCopyWithImpl<_CustomInvoiceItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomInvoiceItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomInvoiceItem&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPriceCents, unitPriceCents) || other.unitPriceCents == unitPriceCents)&&(identical(other.subtotalCents, subtotalCents) || other.subtotalCents == subtotalCents)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productName,quantity,unitPriceCents,subtotalCents,unit);

@override
String toString() {
  return 'CustomInvoiceItem(productName: $productName, quantity: $quantity, unitPriceCents: $unitPriceCents, subtotalCents: $subtotalCents, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$CustomInvoiceItemCopyWith<$Res> implements $CustomInvoiceItemCopyWith<$Res> {
  factory _$CustomInvoiceItemCopyWith(_CustomInvoiceItem value, $Res Function(_CustomInvoiceItem) _then) = __$CustomInvoiceItemCopyWithImpl;
@override @useResult
$Res call({
 String productName, int quantity, int unitPriceCents, int subtotalCents, String unit
});




}
/// @nodoc
class __$CustomInvoiceItemCopyWithImpl<$Res>
    implements _$CustomInvoiceItemCopyWith<$Res> {
  __$CustomInvoiceItemCopyWithImpl(this._self, this._then);

  final _CustomInvoiceItem _self;
  final $Res Function(_CustomInvoiceItem) _then;

/// Create a copy of CustomInvoiceItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productName = null,Object? quantity = null,Object? unitPriceCents = null,Object? subtotalCents = null,Object? unit = null,}) {
  return _then(_CustomInvoiceItem(
productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPriceCents: null == unitPriceCents ? _self.unitPriceCents : unitPriceCents // ignore: cast_nullable_to_non_nullable
as int,subtotalCents: null == subtotalCents ? _self.subtotalCents : subtotalCents // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
