// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'debt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Debt {

 String get id;// Loja dona do fiado (Fase 2 do multi-tenancy). Cada loja tem seu
// próprio "a receber / a pagar".
 String get storeId; String get personName;// Valor em CENTAVOS inteiros (W4 — migração de dinheiro para
// centavos; o banco persiste BIGINT/INTEGER).
 int get amountCents; DateTime get dueDate; bool get isCustomerDebt; bool get isPaid;// Data da baixa (carimbada pelo SettleDebtUseCase) — null enquanto
// a dívida estiver pendente. Alimenta o histórico de quitações.
 DateTime? get paidAt;// Vínculo opcional com o cadastro de clientes. O [personName] continua
// sendo o "snapshot" exibido no histórico — se o cadastro do cliente
// mudar de nome depois, a dívida mantém o nome da época.
 String? get customerId;
/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DebtCopyWith<Debt> get copyWith => _$DebtCopyWithImpl<Debt>(this as Debt, _$identity);

  /// Serializes this Debt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Debt&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.personName, personName) || other.personName == personName)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isCustomerDebt, isCustomerDebt) || other.isCustomerDebt == isCustomerDebt)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.customerId, customerId) || other.customerId == customerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,personName,amountCents,dueDate,isCustomerDebt,isPaid,paidAt,customerId);

@override
String toString() {
  return 'Debt(id: $id, storeId: $storeId, personName: $personName, amountCents: $amountCents, dueDate: $dueDate, isCustomerDebt: $isCustomerDebt, isPaid: $isPaid, paidAt: $paidAt, customerId: $customerId)';
}


}

/// @nodoc
abstract mixin class $DebtCopyWith<$Res>  {
  factory $DebtCopyWith(Debt value, $Res Function(Debt) _then) = _$DebtCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String personName, int amountCents, DateTime dueDate, bool isCustomerDebt, bool isPaid, DateTime? paidAt, String? customerId
});




}
/// @nodoc
class _$DebtCopyWithImpl<$Res>
    implements $DebtCopyWith<$Res> {
  _$DebtCopyWithImpl(this._self, this._then);

  final Debt _self;
  final $Res Function(Debt) _then;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? personName = null,Object? amountCents = null,Object? dueDate = null,Object? isCustomerDebt = null,Object? isPaid = null,Object? paidAt = freezed,Object? customerId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,personName: null == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,isCustomerDebt: null == isCustomerDebt ? _self.isCustomerDebt : isCustomerDebt // ignore: cast_nullable_to_non_nullable
as bool,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Debt].
extension DebtPatterns on Debt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Debt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Debt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Debt value)  $default,){
final _that = this;
switch (_that) {
case _Debt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Debt value)?  $default,){
final _that = this;
switch (_that) {
case _Debt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String personName,  int amountCents,  DateTime dueDate,  bool isCustomerDebt,  bool isPaid,  DateTime? paidAt,  String? customerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Debt() when $default != null:
return $default(_that.id,_that.storeId,_that.personName,_that.amountCents,_that.dueDate,_that.isCustomerDebt,_that.isPaid,_that.paidAt,_that.customerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String personName,  int amountCents,  DateTime dueDate,  bool isCustomerDebt,  bool isPaid,  DateTime? paidAt,  String? customerId)  $default,) {final _that = this;
switch (_that) {
case _Debt():
return $default(_that.id,_that.storeId,_that.personName,_that.amountCents,_that.dueDate,_that.isCustomerDebt,_that.isPaid,_that.paidAt,_that.customerId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String personName,  int amountCents,  DateTime dueDate,  bool isCustomerDebt,  bool isPaid,  DateTime? paidAt,  String? customerId)?  $default,) {final _that = this;
switch (_that) {
case _Debt() when $default != null:
return $default(_that.id,_that.storeId,_that.personName,_that.amountCents,_that.dueDate,_that.isCustomerDebt,_that.isPaid,_that.paidAt,_that.customerId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Debt implements Debt {
  const _Debt({required this.id, this.storeId = 'st1', required this.personName, required this.amountCents, required this.dueDate, required this.isCustomerDebt, this.isPaid = false, this.paidAt, this.customerId}): assert(amountCents >= 0, 'O valor da dívida deve ser positivo.');
  factory _Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);

@override final  String id;
// Loja dona do fiado (Fase 2 do multi-tenancy). Cada loja tem seu
// próprio "a receber / a pagar".
@override@JsonKey() final  String storeId;
@override final  String personName;
// Valor em CENTAVOS inteiros (W4 — migração de dinheiro para
// centavos; o banco persiste BIGINT/INTEGER).
@override final  int amountCents;
@override final  DateTime dueDate;
@override final  bool isCustomerDebt;
@override@JsonKey() final  bool isPaid;
// Data da baixa (carimbada pelo SettleDebtUseCase) — null enquanto
// a dívida estiver pendente. Alimenta o histórico de quitações.
@override final  DateTime? paidAt;
// Vínculo opcional com o cadastro de clientes. O [personName] continua
// sendo o "snapshot" exibido no histórico — se o cadastro do cliente
// mudar de nome depois, a dívida mantém o nome da época.
@override final  String? customerId;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DebtCopyWith<_Debt> get copyWith => __$DebtCopyWithImpl<_Debt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DebtToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Debt&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.personName, personName) || other.personName == personName)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isCustomerDebt, isCustomerDebt) || other.isCustomerDebt == isCustomerDebt)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.customerId, customerId) || other.customerId == customerId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,personName,amountCents,dueDate,isCustomerDebt,isPaid,paidAt,customerId);

@override
String toString() {
  return 'Debt(id: $id, storeId: $storeId, personName: $personName, amountCents: $amountCents, dueDate: $dueDate, isCustomerDebt: $isCustomerDebt, isPaid: $isPaid, paidAt: $paidAt, customerId: $customerId)';
}


}

/// @nodoc
abstract mixin class _$DebtCopyWith<$Res> implements $DebtCopyWith<$Res> {
  factory _$DebtCopyWith(_Debt value, $Res Function(_Debt) _then) = __$DebtCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String personName, int amountCents, DateTime dueDate, bool isCustomerDebt, bool isPaid, DateTime? paidAt, String? customerId
});




}
/// @nodoc
class __$DebtCopyWithImpl<$Res>
    implements _$DebtCopyWith<$Res> {
  __$DebtCopyWithImpl(this._self, this._then);

  final _Debt _self;
  final $Res Function(_Debt) _then;

/// Create a copy of Debt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? personName = null,Object? amountCents = null,Object? dueDate = null,Object? isCustomerDebt = null,Object? isPaid = null,Object? paidAt = freezed,Object? customerId = freezed,}) {
  return _then(_Debt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,personName: null == personName ? _self.personName : personName // ignore: cast_nullable_to_non_nullable
as String,amountCents: null == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int,dueDate: null == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime,isCustomerDebt: null == isCustomerDebt ? _self.isCustomerDebt : isCustomerDebt // ignore: cast_nullable_to_non_nullable
as bool,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
