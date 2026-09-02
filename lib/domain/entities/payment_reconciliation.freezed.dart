// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_reconciliation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaymentReconciliation {

 String get id; MobileMoneyProvider get provider;/// Número de telefone do remetente.
 String get phone;/// Código de confirmação do provedor (ex.: MP123456).
 String get confirmationCode;/// Valor em centavos.
 int get amountCents; MobileMoneyStatus get status;/// ID da venda associada (se reconciliada automaticamente).
 String? get saleId;/// ID da cotação associada (se pagamento de cotação).
 String? get quotationId;/// ID da factura associada (se pagamento de factura).
 String? get customInvoiceId;/// Notas do operador.
 String get notes;/// Dados raw da notificação push/API (JSON serializado).
 String get rawData; DateTime get createdAt; DateTime? get reconciledAt;
/// Create a copy of PaymentReconciliation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentReconciliationCopyWith<PaymentReconciliation> get copyWith => _$PaymentReconciliationCopyWithImpl<PaymentReconciliation>(this as PaymentReconciliation, _$identity);

  /// Serializes this PaymentReconciliation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentReconciliation&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.confirmationCode, confirmationCode) || other.confirmationCode == confirmationCode)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.saleId, saleId) || other.saleId == saleId)&&(identical(other.quotationId, quotationId) || other.quotationId == quotationId)&&(identical(other.customInvoiceId, customInvoiceId) || other.customInvoiceId == customInvoiceId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.rawData, rawData) || other.rawData == rawData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reconciledAt, reconciledAt) || other.reconciledAt == reconciledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provider,phone,confirmationCode,amountCents,status,saleId,quotationId,customInvoiceId,notes,rawData,createdAt,reconciledAt);

@override
String toString() {
  return 'PaymentReconciliation(id: $id, provider: $provider, phone: $phone, confirmationCode: $confirmationCode, amountCents: $amountCents, status: $status, saleId: $saleId, quotationId: $quotationId, customInvoiceId: $customInvoiceId, notes: $notes, rawData: $rawData, createdAt: $createdAt, reconciledAt: $reconciledAt)';
}


}

/// @nodoc
abstract mixin class $PaymentReconciliationCopyWith<$Res>  {
  factory $PaymentReconciliationCopyWith(PaymentReconciliation value, $Res Function(PaymentReconciliation) _then) = _$PaymentReconciliationCopyWithImpl;
@useResult
$Res call({
 String id, MobileMoneyProvider provider, String phone, String confirmationCode, int amountCents, MobileMoneyStatus status, String? saleId, String? quotationId, String? customInvoiceId, String notes, String rawData, DateTime createdAt, DateTime? reconciledAt
});




}
/// @nodoc
class _$PaymentReconciliationCopyWithImpl<$Res>
    implements $PaymentReconciliationCopyWith<$Res> {
  _$PaymentReconciliationCopyWithImpl(this._self, this._then);

  final PaymentReconciliation _self;
  final $Res Function(PaymentReconciliation) _then;

/// Create a copy of PaymentReconciliation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? provider = null,Object? phone = null,Object? confirmationCode = null,Object? amountCents = null,Object? status = null,Object? saleId = freezed,Object? quotationId = freezed,Object? customInvoiceId = freezed,Object? notes = null,Object? rawData = null,Object? createdAt = null,Object? reconciledAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as MobileMoneyProvider,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,confirmationCode: null == confirmationCode ? _self.confirmationCode : confirmationCode // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MobileMoneyStatus,saleId: freezed == saleId ? _self.saleId : saleId // ignore: cast_nullable_to_non_nullable
as String?,quotationId: freezed == quotationId ? _self.quotationId : quotationId // ignore: cast_nullable_to_non_nullable
as String?,customInvoiceId: freezed == customInvoiceId ? _self.customInvoiceId : customInvoiceId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,rawData: null == rawData ? _self.rawData : rawData // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reconciledAt: freezed == reconciledAt ? _self.reconciledAt : reconciledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentReconciliation].
extension PaymentReconciliationPatterns on PaymentReconciliation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentReconciliation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentReconciliation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentReconciliation value)  $default,){
final _that = this;
switch (_that) {
case _PaymentReconciliation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentReconciliation value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentReconciliation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  MobileMoneyProvider provider,  String phone,  String confirmationCode,  int amountCents,  MobileMoneyStatus status,  String? saleId,  String? quotationId,  String? customInvoiceId,  String notes,  String rawData,  DateTime createdAt,  DateTime? reconciledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentReconciliation() when $default != null:
return $default(_that.id,_that.provider,_that.phone,_that.confirmationCode,_that.amountCents,_that.status,_that.saleId,_that.quotationId,_that.customInvoiceId,_that.notes,_that.rawData,_that.createdAt,_that.reconciledAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  MobileMoneyProvider provider,  String phone,  String confirmationCode,  int amountCents,  MobileMoneyStatus status,  String? saleId,  String? quotationId,  String? customInvoiceId,  String notes,  String rawData,  DateTime createdAt,  DateTime? reconciledAt)  $default,) {final _that = this;
switch (_that) {
case _PaymentReconciliation():
return $default(_that.id,_that.provider,_that.phone,_that.confirmationCode,_that.amountCents,_that.status,_that.saleId,_that.quotationId,_that.customInvoiceId,_that.notes,_that.rawData,_that.createdAt,_that.reconciledAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  MobileMoneyProvider provider,  String phone,  String confirmationCode,  int amountCents,  MobileMoneyStatus status,  String? saleId,  String? quotationId,  String? customInvoiceId,  String notes,  String rawData,  DateTime createdAt,  DateTime? reconciledAt)?  $default,) {final _that = this;
switch (_that) {
case _PaymentReconciliation() when $default != null:
return $default(_that.id,_that.provider,_that.phone,_that.confirmationCode,_that.amountCents,_that.status,_that.saleId,_that.quotationId,_that.customInvoiceId,_that.notes,_that.rawData,_that.createdAt,_that.reconciledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentReconciliation implements PaymentReconciliation {
  const _PaymentReconciliation({required this.id, required this.provider, required this.phone, this.confirmationCode = '', required this.amountCents, this.status = MobileMoneyStatus.pending, this.saleId, this.quotationId, this.customInvoiceId, this.notes = '', this.rawData = '', required this.createdAt, this.reconciledAt});
  factory _PaymentReconciliation.fromJson(Map<String, dynamic> json) => _$PaymentReconciliationFromJson(json);

@override final  String id;
@override final  MobileMoneyProvider provider;
/// Número de telefone do remetente.
@override final  String phone;
/// Código de confirmação do provedor (ex.: MP123456).
@override@JsonKey() final  String confirmationCode;
/// Valor em centavos.
@override final  int amountCents;
@override@JsonKey() final  MobileMoneyStatus status;
/// ID da venda associada (se reconciliada automaticamente).
@override final  String? saleId;
/// ID da cotação associada (se pagamento de cotação).
@override final  String? quotationId;
/// ID da factura associada (se pagamento de factura).
@override final  String? customInvoiceId;
/// Notas do operador.
@override@JsonKey() final  String notes;
/// Dados raw da notificação push/API (JSON serializado).
@override@JsonKey() final  String rawData;
@override final  DateTime createdAt;
@override final  DateTime? reconciledAt;

/// Create a copy of PaymentReconciliation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentReconciliationCopyWith<_PaymentReconciliation> get copyWith => __$PaymentReconciliationCopyWithImpl<_PaymentReconciliation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentReconciliationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentReconciliation&&(identical(other.id, id) || other.id == id)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.confirmationCode, confirmationCode) || other.confirmationCode == confirmationCode)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.saleId, saleId) || other.saleId == saleId)&&(identical(other.quotationId, quotationId) || other.quotationId == quotationId)&&(identical(other.customInvoiceId, customInvoiceId) || other.customInvoiceId == customInvoiceId)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.rawData, rawData) || other.rawData == rawData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reconciledAt, reconciledAt) || other.reconciledAt == reconciledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,provider,phone,confirmationCode,amountCents,status,saleId,quotationId,customInvoiceId,notes,rawData,createdAt,reconciledAt);

@override
String toString() {
  return 'PaymentReconciliation(id: $id, provider: $provider, phone: $phone, confirmationCode: $confirmationCode, amountCents: $amountCents, status: $status, saleId: $saleId, quotationId: $quotationId, customInvoiceId: $customInvoiceId, notes: $notes, rawData: $rawData, createdAt: $createdAt, reconciledAt: $reconciledAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentReconciliationCopyWith<$Res> implements $PaymentReconciliationCopyWith<$Res> {
  factory _$PaymentReconciliationCopyWith(_PaymentReconciliation value, $Res Function(_PaymentReconciliation) _then) = __$PaymentReconciliationCopyWithImpl;
@override @useResult
$Res call({
 String id, MobileMoneyProvider provider, String phone, String confirmationCode, int amountCents, MobileMoneyStatus status, String? saleId, String? quotationId, String? customInvoiceId, String notes, String rawData, DateTime createdAt, DateTime? reconciledAt
});




}
/// @nodoc
class __$PaymentReconciliationCopyWithImpl<$Res>
    implements _$PaymentReconciliationCopyWith<$Res> {
  __$PaymentReconciliationCopyWithImpl(this._self, this._then);

  final _PaymentReconciliation _self;
  final $Res Function(_PaymentReconciliation) _then;

/// Create a copy of PaymentReconciliation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? provider = null,Object? phone = null,Object? confirmationCode = null,Object? amountCents = null,Object? status = null,Object? saleId = freezed,Object? quotationId = freezed,Object? customInvoiceId = freezed,Object? notes = null,Object? rawData = null,Object? createdAt = null,Object? reconciledAt = freezed,}) {
  return _then(_PaymentReconciliation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as MobileMoneyProvider,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,confirmationCode: null == confirmationCode ? _self.confirmationCode : confirmationCode // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MobileMoneyStatus,saleId: freezed == saleId ? _self.saleId : saleId // ignore: cast_nullable_to_non_nullable
as String?,quotationId: freezed == quotationId ? _self.quotationId : quotationId // ignore: cast_nullable_to_non_nullable
as String?,customInvoiceId: freezed == customInvoiceId ? _self.customInvoiceId : customInvoiceId // ignore: cast_nullable_to_non_nullable
as String?,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,rawData: null == rawData ? _self.rawData : rawData // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reconciledAt: freezed == reconciledAt ? _self.reconciledAt : reconciledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
