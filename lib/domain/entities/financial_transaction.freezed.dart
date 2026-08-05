// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'financial_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FinancialTransaction {

 String get id;// Loja dona do movimento — o caixa é por loja (Fase 2 do
// multi-tenancy).
 String get storeId; String get description; double get amount; TransactionType get type; String get category; DateTime get date; TransactionStatus get status;// Vínculo opcional com a dívida de "fiado" que originou a pendência
// (ex.: seed). Permite que a baixa (SettleDebtUseCase) marque a MESMA
// transação como paga, em vez de criar uma duplicata no caixa.
 String? get debtId;
/// Create a copy of FinancialTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinancialTransactionCopyWith<FinancialTransaction> get copyWith => _$FinancialTransactionCopyWithImpl<FinancialTransaction>(this as FinancialTransaction, _$identity);

  /// Serializes this FinancialTransaction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinancialTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.debtId, debtId) || other.debtId == debtId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,description,amount,type,category,date,status,debtId);

@override
String toString() {
  return 'FinancialTransaction(id: $id, storeId: $storeId, description: $description, amount: $amount, type: $type, category: $category, date: $date, status: $status, debtId: $debtId)';
}


}

/// @nodoc
abstract mixin class $FinancialTransactionCopyWith<$Res>  {
  factory $FinancialTransactionCopyWith(FinancialTransaction value, $Res Function(FinancialTransaction) _then) = _$FinancialTransactionCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String description, double amount, TransactionType type, String category, DateTime date, TransactionStatus status, String? debtId
});




}
/// @nodoc
class _$FinancialTransactionCopyWithImpl<$Res>
    implements $FinancialTransactionCopyWith<$Res> {
  _$FinancialTransactionCopyWithImpl(this._self, this._then);

  final FinancialTransaction _self;
  final $Res Function(FinancialTransaction) _then;

/// Create a copy of FinancialTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? description = null,Object? amount = null,Object? type = null,Object? category = null,Object? date = null,Object? status = null,Object? debtId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransactionStatus,debtId: freezed == debtId ? _self.debtId : debtId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FinancialTransaction].
extension FinancialTransactionPatterns on FinancialTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinancialTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinancialTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinancialTransaction value)  $default,){
final _that = this;
switch (_that) {
case _FinancialTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinancialTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _FinancialTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String description,  double amount,  TransactionType type,  String category,  DateTime date,  TransactionStatus status,  String? debtId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinancialTransaction() when $default != null:
return $default(_that.id,_that.storeId,_that.description,_that.amount,_that.type,_that.category,_that.date,_that.status,_that.debtId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String description,  double amount,  TransactionType type,  String category,  DateTime date,  TransactionStatus status,  String? debtId)  $default,) {final _that = this;
switch (_that) {
case _FinancialTransaction():
return $default(_that.id,_that.storeId,_that.description,_that.amount,_that.type,_that.category,_that.date,_that.status,_that.debtId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String description,  double amount,  TransactionType type,  String category,  DateTime date,  TransactionStatus status,  String? debtId)?  $default,) {final _that = this;
switch (_that) {
case _FinancialTransaction() when $default != null:
return $default(_that.id,_that.storeId,_that.description,_that.amount,_that.type,_that.category,_that.date,_that.status,_that.debtId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinancialTransaction implements FinancialTransaction {
  const _FinancialTransaction({required this.id, this.storeId = 'st1', required this.description, required this.amount, required this.type, required this.category, required this.date, this.status = TransactionStatus.paid, this.debtId}): assert(amount >= 0, 'O valor da transação deve ser positivo.');
  factory _FinancialTransaction.fromJson(Map<String, dynamic> json) => _$FinancialTransactionFromJson(json);

@override final  String id;
// Loja dona do movimento — o caixa é por loja (Fase 2 do
// multi-tenancy).
@override@JsonKey() final  String storeId;
@override final  String description;
@override final  double amount;
@override final  TransactionType type;
@override final  String category;
@override final  DateTime date;
@override@JsonKey() final  TransactionStatus status;
// Vínculo opcional com a dívida de "fiado" que originou a pendência
// (ex.: seed). Permite que a baixa (SettleDebtUseCase) marque a MESMA
// transação como paga, em vez de criar uma duplicata no caixa.
@override final  String? debtId;

/// Create a copy of FinancialTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinancialTransactionCopyWith<_FinancialTransaction> get copyWith => __$FinancialTransactionCopyWithImpl<_FinancialTransaction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinancialTransactionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinancialTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.description, description) || other.description == description)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.debtId, debtId) || other.debtId == debtId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,description,amount,type,category,date,status,debtId);

@override
String toString() {
  return 'FinancialTransaction(id: $id, storeId: $storeId, description: $description, amount: $amount, type: $type, category: $category, date: $date, status: $status, debtId: $debtId)';
}


}

/// @nodoc
abstract mixin class _$FinancialTransactionCopyWith<$Res> implements $FinancialTransactionCopyWith<$Res> {
  factory _$FinancialTransactionCopyWith(_FinancialTransaction value, $Res Function(_FinancialTransaction) _then) = __$FinancialTransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String description, double amount, TransactionType type, String category, DateTime date, TransactionStatus status, String? debtId
});




}
/// @nodoc
class __$FinancialTransactionCopyWithImpl<$Res>
    implements _$FinancialTransactionCopyWith<$Res> {
  __$FinancialTransactionCopyWithImpl(this._self, this._then);

  final _FinancialTransaction _self;
  final $Res Function(_FinancialTransaction) _then;

/// Create a copy of FinancialTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? description = null,Object? amount = null,Object? type = null,Object? category = null,Object? date = null,Object? status = null,Object? debtId = freezed,}) {
  return _then(_FinancialTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransactionType,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TransactionStatus,debtId: freezed == debtId ? _self.debtId : debtId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
