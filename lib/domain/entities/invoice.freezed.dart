// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Invoice {

 String get id;/// Número sequencial da factura (ex.: INV-00001, INV-00002).
/// Atribuído pelo banco no insert — SQLite: MAX+1 por tenant;
/// Supabase: RPC ou gen_random_uuid().
 int get number;/// Tenant a quem a factura se destina.
 String get tenantId;/// Plano contratado no momento da geração (snapshot).
 String get planId;/// Valor em CENTAVOS inteiros (mesma unidade do Plan.priceMonthlyCents).
 int get amountCents;/// Estado actual da factura.
 InvoiceStatus get status;/// Data de vencimento — quando a factura expira se não for paga.
 DateTime get dueDate;/// Período que a factura cobre (ex.: "Janeiro 2026").
 String get period;/// Data de pagamento (carimbada quando o super admin marca como paga).
 DateTime? get paidAt;/// Observações do super admin sobre a factura.
 String? get notes; DateTime get createdAt;
/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceCopyWith<Invoice> get copyWith => _$InvoiceCopyWithImpl<Invoice>(this as Invoice, _$identity);

  /// Serializes this Invoice to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.period, period) || other.period == period)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,tenantId,planId,amountCents,status,dueDate,period,paidAt,notes,createdAt);

@override
String toString() {
  return 'Invoice(id: $id, number: $number, tenantId: $tenantId, planId: $planId, amountCents: $amountCents, status: $status, dueDate: $dueDate, period: $period, paidAt: $paidAt, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InvoiceCopyWith<$Res>  {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) _then) = _$InvoiceCopyWithImpl;
@useResult
$Res call({
 String id, int number, String tenantId, String planId, int amountCents, InvoiceStatus status, DateTime dueDate, String period, DateTime? paidAt, String? notes, DateTime createdAt
});




}
/// @nodoc
class _$InvoiceCopyWithImpl<$Res>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._self, this._then);

  final Invoice _self;
  final $Res Function(Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? number = null,Object? tenantId = null,Object? planId = null,Object? amountCents = null,Object? status = null,Object? dueDate = null,Object? period = null,Object? paidAt = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Invoice].
extension InvoicePatterns on Invoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Invoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Invoice value)  $default,){
final _that = this;
switch (_that) {
case _Invoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Invoice value)?  $default,){
final _that = this;
switch (_that) {
case _Invoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int number,  String tenantId,  String planId,  int amountCents,  InvoiceStatus status,  DateTime dueDate,  String period,  DateTime? paidAt,  String? notes,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.number,_that.tenantId,_that.planId,_that.amountCents,_that.status,_that.dueDate,_that.period,_that.paidAt,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int number,  String tenantId,  String planId,  int amountCents,  InvoiceStatus status,  DateTime dueDate,  String period,  DateTime? paidAt,  String? notes,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Invoice():
return $default(_that.id,_that.number,_that.tenantId,_that.planId,_that.amountCents,_that.status,_that.dueDate,_that.period,_that.paidAt,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int number,  String tenantId,  String planId,  int amountCents,  InvoiceStatus status,  DateTime dueDate,  String period,  DateTime? paidAt,  String? notes,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Invoice() when $default != null:
return $default(_that.id,_that.number,_that.tenantId,_that.planId,_that.amountCents,_that.status,_that.dueDate,_that.period,_that.paidAt,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Invoice implements Invoice {
  const _Invoice({required this.id, this.number = 0, required this.tenantId, required this.planId, required this.amountCents, this.status = InvoiceStatus.pending, required this.dueDate, this.period = '', this.paidAt, this.notes, required this.createdAt});
  factory _Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);

@override final  String id;
/// Número sequencial da factura (ex.: INV-00001, INV-00002).
/// Atribuído pelo banco no insert — SQLite: MAX+1 por tenant;
/// Supabase: RPC ou gen_random_uuid().
@override@JsonKey() final  int number;
/// Tenant a quem a factura se destina.
@override final  String tenantId;
/// Plano contratado no momento da geração (snapshot).
@override final  String planId;
/// Valor em CENTAVOS inteiros (mesma unidade do Plan.priceMonthlyCents).
@override final  int amountCents;
/// Estado actual da factura.
@override@JsonKey() final  InvoiceStatus status;
/// Data de vencimento — quando a factura expira se não for paga.
@override final  DateTime dueDate;
/// Período que a factura cobre (ex.: "Janeiro 2026").
@override@JsonKey() final  String period;
/// Data de pagamento (carimbada quando o super admin marca como paga).
@override final  DateTime? paidAt;
/// Observações do super admin sobre a factura.
@override final  String? notes;
@override final  DateTime createdAt;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceCopyWith<_Invoice> get copyWith => __$InvoiceCopyWithImpl<_Invoice>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Invoice&&(identical(other.id, id) || other.id == id)&&(identical(other.number, number) || other.number == number)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.status, status) || other.status == status)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.period, period) || other.period == period)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,number,tenantId,planId,amountCents,status,dueDate,period,paidAt,notes,createdAt);

@override
String toString() {
  return 'Invoice(id: $id, number: $number, tenantId: $tenantId, planId: $planId, amountCents: $amountCents, status: $status, dueDate: $dueDate, period: $period, paidAt: $paidAt, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InvoiceCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$InvoiceCopyWith(_Invoice value, $Res Function(_Invoice) _then) = __$InvoiceCopyWithImpl;
@override @useResult
$Res call({
 String id, int number, String tenantId, String planId, int amountCents, InvoiceStatus status, DateTime dueDate, String period, DateTime? paidAt, String? notes, DateTime createdAt
});




}
/// @nodoc
class __$InvoiceCopyWithImpl<$Res>
    implements _$InvoiceCopyWith<$Res> {
  __$InvoiceCopyWithImpl(this._self, this._then);

  final _Invoice _self;
  final $Res Function(_Invoice) _then;

/// Create a copy of Invoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? number = null,Object? tenantId = null,Object? planId = null,Object? amountCents = null,Object? status = null,Object? dueDate = null,Object? period = null,Object? paidAt = freezed,Object? notes = freezed,Object? createdAt = null,}) {
  return _then(_Invoice(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InvoiceStatus,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
