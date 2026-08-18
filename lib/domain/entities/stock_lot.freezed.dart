// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_lot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockLot {

 String get id;// Loja dona do lote — cada loja tem seus próprios lotes (Fase 2 do
// multi-tenancy).
 String get storeId; String get productId;// Data de ENTRADA do lote (data da compra) — critério FIFO quando não
// há data de validade.
 DateTime get entryDate;// Data de VALIDADE — `null` para produtos sem validade (não
// perecíveis), que seguem FIFO por data de entrada.
 DateTime? get expiryDate;// Quantidade INICIAL recebida (milésimos) — referência histórica.
 int get initialQuantity;// Quantidade ATUAL disponível (milésimos) — diminui a cada venda FIFO;
// lotes zerados são inativos e não participam das baixas.
 int get currentQuantity;// Custo de aquisição em CENTAVOS inteiros (W4) — base do custo do
// estoque (custo do lote na data da compra).
 int get costPriceCents;
/// Create a copy of StockLot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockLotCopyWith<StockLot> get copyWith => _$StockLotCopyWithImpl<StockLot>(this as StockLot, _$identity);

 /// Serializes this StockLot to a JSON map.
 Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is StockLot&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.entryDate, entryDate) || other.entryDate == entryDate)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.initialQuantity, initialQuantity) || other.initialQuantity == initialQuantity)&&(identical(other.currentQuantity, currentQuantity) || other.currentQuantity == currentQuantity)&&(identical(other.costPriceCents, costPriceCents) || other.costPriceCents == costPriceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,productId,entryDate,expiryDate,initialQuantity,currentQuantity,costPriceCents);

@override
String toString() {
 return 'StockLot(id: $id, storeId: $storeId, productId: $productId, entryDate: $entryDate, expiryDate: $expiryDate, initialQuantity: $initialQuantity, currentQuantity: $currentQuantity, costPriceCents: $costPriceCents)';
}


}

/// @nodoc
abstract mixin class $StockLotCopyWith<$Res> {
 factory $StockLotCopyWith(StockLot value, $Res Function(StockLot) _then) = _$StockLotCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String productId, DateTime entryDate, DateTime? expiryDate, int initialQuantity, int currentQuantity, int costPriceCents
});




}
/// @nodoc
class _$StockLotCopyWithImpl<$Res>
 implements $StockLotCopyWith<$Res> {
 _$StockLotCopyWithImpl(this._self, this._then);

 final StockLot _self;
 final $Res Function(StockLot) _then;

/// Create a copy of StockLot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? productId = null,Object? entryDate = null,Object? expiryDate = freezed,Object? initialQuantity = null,Object? currentQuantity = null,Object? costPriceCents = null,}) {
 return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,initialQuantity: null == initialQuantity ? _self.initialQuantity : initialQuantity // ignore: cast_nullable_to_non_nullable
as int,currentQuantity: null == currentQuantity ? _self.currentQuantity : currentQuantity // ignore: cast_nullable_to_non_nullable
as int,costPriceCents: null == costPriceCents ? _self.costPriceCents : costPriceCents // ignore: cast_nullable_to_non_nullable
as int,
 ));
}

}


/// Adds pattern-matching-related methods to [StockLot].
extension StockLotPatterns on StockLot {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case final Subclass value:
/// return ...;
/// case _:
/// return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockLot value)? $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockLot() when $default != null:
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
/// case final Subclass value:
/// return ...;
/// case final Subclass2 value:
/// return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockLot value) $default,){
final _that = this;
switch (_that) {
case _StockLot():
return $default(_that);case _:
 throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case final Subclass value:
/// return ...;
/// case _:
/// return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockLot value)? $default,){
final _that = this;
switch (_that) {
case _StockLot() when $default != null:
return $default(_that);case _:
 return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case Subclass(:final field):
/// return ...;
/// case _:
/// return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, String storeId, String productId, DateTime entryDate, DateTime? expiryDate, int initialQuantity, int currentQuantity, int costPriceCents)? $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockLot() when $default != null:
return $default(_that.id,_that.storeId,_that.productId,_that.entryDate,_that.expiryDate,_that.initialQuantity,_that.currentQuantity,_that.costPriceCents);case _:
 return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case Subclass(:final field):
/// return ...;
/// case Subclass2(:final field2):
/// return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, String storeId, String productId, DateTime entryDate, DateTime? expiryDate, int initialQuantity, int currentQuantity, int costPriceCents) $default,) {final _that = this;
switch (_that) {
case _StockLot():
return $default(_that.id,_that.storeId,_that.productId,_that.entryDate,_that.expiryDate,_that.initialQuantity,_that.currentQuantity,_that.costPriceCents);case _:
 throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
/// case Subclass(:final field):
/// return ...;
/// case _:
/// return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, String storeId, String productId, DateTime entryDate, DateTime? expiryDate, int initialQuantity, int currentQuantity, int costPriceCents)? $default,) {final _that = this;
switch (_that) {
case _StockLot() when $default != null:
return $default(_that.id,_that.storeId,_that.productId,_that.entryDate,_that.expiryDate,_that.initialQuantity,_that.currentQuantity,_that.costPriceCents);case _:
 return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockLot implements StockLot {
 const _StockLot({required this.id, this.storeId = 'st1', required this.productId, required this.entryDate, this.expiryDate, required this.initialQuantity, required this.currentQuantity, required this.costPriceCents});
 factory _StockLot.fromJson(Map<String, dynamic> json) => _$StockLotFromJson(json);

@override final String id;
// Loja dona do lote — cada loja tem seus próprios lotes (Fase 2 do
// multi-tenancy).
@override@JsonKey() final String storeId;
@override final String productId;
// Data de ENTRADA do lote (data da compra) — critério FIFO quando não
// há data de validade.
@override final DateTime entryDate;
// Data de VALIDADE — `null` para produtos sem validade (não
// perecíveis), que seguem FIFO por data de entrada.
@override final DateTime? expiryDate;
// Quantidade INICIAL recebida (milésimos) — referência histórica.
@override final int initialQuantity;
// Quantidade ATUAL disponível (milésimos) — diminui a cada venda FIFO;
// lotes zerados são inativos e não participam das baixas.
@override final int currentQuantity;
// Custo de aquisição em CENTAVOS inteiros (W4) — base do custo do
// estoque (custo do lote na data da compra).
@override final int costPriceCents;

/// Create a copy of StockLot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockLotCopyWith<_StockLot> get copyWith => __$StockLotCopyWithImpl<_StockLot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
 return _$StockLotToJson(this, );
}

@override
bool operator ==(Object other) {
 return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockLot&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.entryDate, entryDate) || other.entryDate == entryDate)&&(identical(other.expiryDate, expiryDate) || other.expiryDate == expiryDate)&&(identical(other.initialQuantity, initialQuantity) || other.initialQuantity == initialQuantity)&&(identical(other.currentQuantity, currentQuantity) || other.currentQuantity == currentQuantity)&&(identical(other.costPriceCents, costPriceCents) || other.costPriceCents == costPriceCents));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,productId,entryDate,expiryDate,initialQuantity,currentQuantity,costPriceCents);

@override
String toString() {
 return 'StockLot(id: $id, storeId: $storeId, productId: $productId, entryDate: $entryDate, expiryDate: $expiryDate, initialQuantity: $initialQuantity, currentQuantity: $currentQuantity, costPriceCents: $costPriceCents)';
}


}

/// @nodoc
abstract mixin class _$StockLotCopyWith<$Res> implements $StockLotCopyWith<$Res> {
 factory _$StockLotCopyWith(_StockLot value, $Res Function(_StockLot) _then) = __$StockLotCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String productId, DateTime entryDate, DateTime? expiryDate, int initialQuantity, int currentQuantity, int costPriceCents
});




}
/// @nodoc
class __$StockLotCopyWithImpl<$Res>
 implements _$StockLotCopyWith<$Res> {
 __$StockLotCopyWithImpl(this._self, this._then);

 final _StockLot _self;
 final $Res Function(_StockLot) _then;

/// Create a copy of StockLot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? productId = null,Object? entryDate = null,Object? expiryDate = freezed,Object? initialQuantity = null,Object? currentQuantity = null,Object? costPriceCents = null,}) {
 return _then(_StockLot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,expiryDate: freezed == expiryDate ? _self.expiryDate : expiryDate // ignore: cast_nullable_to_non_nullable
as DateTime?,initialQuantity: null == initialQuantity ? _self.initialQuantity : initialQuantity // ignore: cast_nullable_to_non_nullable
as int,currentQuantity: null == currentQuantity ? _self.currentQuantity : currentQuantity // ignore: cast_nullable_to_non_nullable
as int,costPriceCents: null == costPriceCents ? _self.costPriceCents : costPriceCents // ignore: cast_nullable_to_non_nullable
as int,
 ));
}


}

// dart format on
