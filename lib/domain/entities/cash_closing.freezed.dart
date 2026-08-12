// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cash_closing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CashClosing {

 String get id;// Loja dona do fecho — o caixa é por loja (Fase 2 do multi-tenancy).
 String get storeId;// Dia fechado (início do dia local — a unicidade é por loja + dia).
 DateTime get day;// Σ das vendas ATIVAS do dia (todas as formas de pagamento).
 int get totalSalesCents;// O que deveria estar na gaveta: só vendas em DINHEIRO (a conferência
// física compara contra este valor).
 int get expectedCashCents;// Dinheiro físico contado pelo usuário na conferência.
 int get countedCashCents;// Abertura por forma de pagamento (method.name → centavos) — o Z.
 Map<String, int> get salesByMethodCents;// Momento em que o fecho foi confirmado/atualizado.
 DateTime get closedAt;
/// Create a copy of CashClosing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CashClosingCopyWith<CashClosing> get copyWith => _$CashClosingCopyWithImpl<CashClosing>(this as CashClosing, _$identity);

  /// Serializes this CashClosing to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CashClosing&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.day, day) || other.day == day)&&(identical(other.totalSalesCents, totalSalesCents) || other.totalSalesCents == totalSalesCents)&&(identical(other.expectedCashCents, expectedCashCents) || other.expectedCashCents == expectedCashCents)&&(identical(other.countedCashCents, countedCashCents) || other.countedCashCents == countedCashCents)&&const DeepCollectionEquality().equals(other.salesByMethodCents, salesByMethodCents)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,day,totalSalesCents,expectedCashCents,countedCashCents,const DeepCollectionEquality().hash(salesByMethodCents),closedAt);

@override
String toString() {
  return 'CashClosing(id: $id, storeId: $storeId, day: $day, totalSalesCents: $totalSalesCents, expectedCashCents: $expectedCashCents, countedCashCents: $countedCashCents, salesByMethodCents: $salesByMethodCents, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class $CashClosingCopyWith<$Res>  {
  factory $CashClosingCopyWith(CashClosing value, $Res Function(CashClosing) _then) = _$CashClosingCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, DateTime day, int totalSalesCents, int expectedCashCents, int countedCashCents, Map<String, int> salesByMethodCents, DateTime closedAt
});




}
/// @nodoc
class _$CashClosingCopyWithImpl<$Res>
    implements $CashClosingCopyWith<$Res> {
  _$CashClosingCopyWithImpl(this._self, this._then);

  final CashClosing _self;
  final $Res Function(CashClosing) _then;

/// Create a copy of CashClosing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? day = null,Object? totalSalesCents = null,Object? expectedCashCents = null,Object? countedCashCents = null,Object? salesByMethodCents = null,Object? closedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,totalSalesCents: null == totalSalesCents ? _self.totalSalesCents : totalSalesCents // ignore: cast_nullable_to_non_nullable
as int,expectedCashCents: null == expectedCashCents ? _self.expectedCashCents : expectedCashCents // ignore: cast_nullable_to_non_nullable
as int,countedCashCents: null == countedCashCents ? _self.countedCashCents : countedCashCents // ignore: cast_nullable_to_non_nullable
as int,salesByMethodCents: null == salesByMethodCents ? _self.salesByMethodCents : salesByMethodCents // ignore: cast_nullable_to_non_nullable
as Map<String, int>,closedAt: null == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CashClosing].
extension CashClosingPatterns on CashClosing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CashClosing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CashClosing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CashClosing value)  $default,){
final _that = this;
switch (_that) {
case _CashClosing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CashClosing value)?  $default,){
final _that = this;
switch (_that) {
case _CashClosing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  DateTime day,  int totalSalesCents,  int expectedCashCents,  int countedCashCents,  Map<String, int> salesByMethodCents,  DateTime closedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CashClosing() when $default != null:
return $default(_that.id,_that.storeId,_that.day,_that.totalSalesCents,_that.expectedCashCents,_that.countedCashCents,_that.salesByMethodCents,_that.closedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  DateTime day,  int totalSalesCents,  int expectedCashCents,  int countedCashCents,  Map<String, int> salesByMethodCents,  DateTime closedAt)  $default,) {final _that = this;
switch (_that) {
case _CashClosing():
return $default(_that.id,_that.storeId,_that.day,_that.totalSalesCents,_that.expectedCashCents,_that.countedCashCents,_that.salesByMethodCents,_that.closedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  DateTime day,  int totalSalesCents,  int expectedCashCents,  int countedCashCents,  Map<String, int> salesByMethodCents,  DateTime closedAt)?  $default,) {final _that = this;
switch (_that) {
case _CashClosing() when $default != null:
return $default(_that.id,_that.storeId,_that.day,_that.totalSalesCents,_that.expectedCashCents,_that.countedCashCents,_that.salesByMethodCents,_that.closedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CashClosing implements CashClosing {
  const _CashClosing({required this.id, this.storeId = 'st1', required this.day, required this.totalSalesCents, required this.expectedCashCents, required this.countedCashCents, final  Map<String, int> salesByMethodCents = const {}, required this.closedAt}): assert(expectedCashCents >= 0, 'O valor esperado deve ser positivo.'),assert(countedCashCents >= 0, 'O valor contado deve ser positivo.'),_salesByMethodCents = salesByMethodCents;
  factory _CashClosing.fromJson(Map<String, dynamic> json) => _$CashClosingFromJson(json);

@override final  String id;
// Loja dona do fecho — o caixa é por loja (Fase 2 do multi-tenancy).
@override@JsonKey() final  String storeId;
// Dia fechado (início do dia local — a unicidade é por loja + dia).
@override final  DateTime day;
// Σ das vendas ATIVAS do dia (todas as formas de pagamento).
@override final  int totalSalesCents;
// O que deveria estar na gaveta: só vendas em DINHEIRO (a conferência
// física compara contra este valor).
@override final  int expectedCashCents;
// Dinheiro físico contado pelo usuário na conferência.
@override final  int countedCashCents;
// Abertura por forma de pagamento (method.name → centavos) — o Z.
 final  Map<String, int> _salesByMethodCents;
// Abertura por forma de pagamento (method.name → centavos) — o Z.
@override@JsonKey() Map<String, int> get salesByMethodCents {
  if (_salesByMethodCents is EqualUnmodifiableMapView) return _salesByMethodCents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_salesByMethodCents);
}

// Momento em que o fecho foi confirmado/atualizado.
@override final  DateTime closedAt;

/// Create a copy of CashClosing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CashClosingCopyWith<_CashClosing> get copyWith => __$CashClosingCopyWithImpl<_CashClosing>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CashClosingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CashClosing&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.day, day) || other.day == day)&&(identical(other.totalSalesCents, totalSalesCents) || other.totalSalesCents == totalSalesCents)&&(identical(other.expectedCashCents, expectedCashCents) || other.expectedCashCents == expectedCashCents)&&(identical(other.countedCashCents, countedCashCents) || other.countedCashCents == countedCashCents)&&const DeepCollectionEquality().equals(other._salesByMethodCents, _salesByMethodCents)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,day,totalSalesCents,expectedCashCents,countedCashCents,const DeepCollectionEquality().hash(_salesByMethodCents),closedAt);

@override
String toString() {
  return 'CashClosing(id: $id, storeId: $storeId, day: $day, totalSalesCents: $totalSalesCents, expectedCashCents: $expectedCashCents, countedCashCents: $countedCashCents, salesByMethodCents: $salesByMethodCents, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class _$CashClosingCopyWith<$Res> implements $CashClosingCopyWith<$Res> {
  factory _$CashClosingCopyWith(_CashClosing value, $Res Function(_CashClosing) _then) = __$CashClosingCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, DateTime day, int totalSalesCents, int expectedCashCents, int countedCashCents, Map<String, int> salesByMethodCents, DateTime closedAt
});




}
/// @nodoc
class __$CashClosingCopyWithImpl<$Res>
    implements _$CashClosingCopyWith<$Res> {
  __$CashClosingCopyWithImpl(this._self, this._then);

  final _CashClosing _self;
  final $Res Function(_CashClosing) _then;

/// Create a copy of CashClosing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? day = null,Object? totalSalesCents = null,Object? expectedCashCents = null,Object? countedCashCents = null,Object? salesByMethodCents = null,Object? closedAt = null,}) {
  return _then(_CashClosing(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,day: null == day ? _self.day : day // ignore: cast_nullable_to_non_nullable
as DateTime,totalSalesCents: null == totalSalesCents ? _self.totalSalesCents : totalSalesCents // ignore: cast_nullable_to_non_nullable
as int,expectedCashCents: null == expectedCashCents ? _self.expectedCashCents : expectedCashCents // ignore: cast_nullable_to_non_nullable
as int,countedCashCents: null == countedCashCents ? _self.countedCashCents : countedCashCents // ignore: cast_nullable_to_non_nullable
as int,salesByMethodCents: null == salesByMethodCents ? _self._salesByMethodCents : salesByMethodCents // ignore: cast_nullable_to_non_nullable
as Map<String, int>,closedAt: null == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
