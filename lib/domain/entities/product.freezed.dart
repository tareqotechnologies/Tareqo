// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

 String get id;// Loja dona do produto — cada loja tem seu próprio estoque (Fase 2
// do multi-tenancy). O valor default mantém compatibilidade com
// construções antigas; a UI sempre carimba a loja ativa.
 String get storeId; String get name; String get description;// Foto do produto (opcional): referência da imagem — URL pública do
// Supabase Storage (modo SaaS) ou caminho de arquivo local (modo
// SQLite). Vazio = sem foto (a UI mostra o ícone padrão do produto).
 String get imagePath;// Preços em CENTAVOS inteiros (W4 — migração de dinheiro para
// centavos; o banco persiste BIGINT/INTEGER).
 int get purchasePriceCents; int get salePriceCents;// Estoque em MILÉSIMOS de unidade (W11): 1000 = 1 unidade (produtos
// normais) ou 1 kg/litro (produtos por peso). Inteiro exato — mesma
// filosofia dos centavos (W4).
 int get stockQuantity;// Código de barras/PLU do produto (opcional, até 5 dígitos): usado
// pelas balanças etiquetadoras (formato 20PPPPPWWWWW) e pelo campo de
// código de barras do PDV. Os ids internos são alfanuméricos longos;
// o PLU é o código numérico impresso nas etiquetas.
 String get code;// Venda por FRAÇÃO (peso/granel): quando verdadeiro, o PDV aceita
// quantidades decimais (ex.: 1,75 kg) e o código de barras de balança
// é interpretado. O preço unitário é por UNIDADE da [unitLabel]
// (ex.: por kg).
 bool get vendaPorFracao;// Unidade de venda dos produtos por peso (kg, g, l, ml...). 'un'
// (padrão) = unidade inteira normal.
 String get unitLabel;// Produto ATIVO no catálogo (padrão). Ao ser desativado, some do PDV
// e das compras (não pode ser vendido nem reposto), mas permanece na
// lista de Produtos com o selo "Inativo" — o dono/gerente pode
// reativá-lo quando quiser. O estoque existente é preservado (volta a
// ser vendível na reativação).
 bool get isActive;// Tipo estrutural do produto (Fase 1). Default [ProductType.resale]
// por compatibilidade: produtos antigos (sem a coluna no banco) já
// eram compráveis e vendáveis — a leitura preserva o comportamento;
// o JSON externo sem o campo também cai no default.
//
// `unknownEnumValue`: um valor NÃO reconhecido (ex.: gravado por uma
// versão mais nova do app) cai em [ProductType.resale] em vez de
// lançar `ArgumentError` — mesma tolerância dos datasources SQLite e
// Supabase, que fazem `firstWhere(...orElse: resale)` ao mapear a
// coluna `type`.
@JsonKey(unknownEnumValue: ProductType.resale) ProductType get type;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.purchasePriceCents, purchasePriceCents) || other.purchasePriceCents == purchasePriceCents)&&(identical(other.salePriceCents, salePriceCents) || other.salePriceCents == salePriceCents)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.code, code) || other.code == code)&&(identical(other.vendaPorFracao, vendaPorFracao) || other.vendaPorFracao == vendaPorFracao)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,name,description,imagePath,purchasePriceCents,salePriceCents,stockQuantity,code,vendaPorFracao,unitLabel,isActive,type);

@override
String toString() {
  return 'Product(id: $id, storeId: $storeId, name: $name, description: $description, imagePath: $imagePath, purchasePriceCents: $purchasePriceCents, salePriceCents: $salePriceCents, stockQuantity: $stockQuantity, code: $code, vendaPorFracao: $vendaPorFracao, unitLabel: $unitLabel, isActive: $isActive, type: $type)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String storeId, String name, String description, String imagePath, int purchasePriceCents, int salePriceCents, int stockQuantity, String code, bool vendaPorFracao, String unitLabel, bool isActive,@JsonKey(unknownEnumValue: ProductType.resale) ProductType type
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? storeId = null,Object? name = null,Object? description = null,Object? imagePath = null,Object? purchasePriceCents = null,Object? salePriceCents = null,Object? stockQuantity = null,Object? code = null,Object? vendaPorFracao = null,Object? unitLabel = null,Object? isActive = null,Object? type = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,purchasePriceCents: null == purchasePriceCents ? _self.purchasePriceCents : purchasePriceCents // ignore: cast_nullable_to_non_nullable
as int,salePriceCents: null == salePriceCents ? _self.salePriceCents : salePriceCents // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,vendaPorFracao: null == vendaPorFracao ? _self.vendaPorFracao : vendaPorFracao // ignore: cast_nullable_to_non_nullable
as bool,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String storeId,  String name,  String description,  String imagePath,  int purchasePriceCents,  int salePriceCents,  int stockQuantity,  String code,  bool vendaPorFracao,  String unitLabel,  bool isActive, @JsonKey(unknownEnumValue: ProductType.resale)  ProductType type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.storeId,_that.name,_that.description,_that.imagePath,_that.purchasePriceCents,_that.salePriceCents,_that.stockQuantity,_that.code,_that.vendaPorFracao,_that.unitLabel,_that.isActive,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String storeId,  String name,  String description,  String imagePath,  int purchasePriceCents,  int salePriceCents,  int stockQuantity,  String code,  bool vendaPorFracao,  String unitLabel,  bool isActive, @JsonKey(unknownEnumValue: ProductType.resale)  ProductType type)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.storeId,_that.name,_that.description,_that.imagePath,_that.purchasePriceCents,_that.salePriceCents,_that.stockQuantity,_that.code,_that.vendaPorFracao,_that.unitLabel,_that.isActive,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String storeId,  String name,  String description,  String imagePath,  int purchasePriceCents,  int salePriceCents,  int stockQuantity,  String code,  bool vendaPorFracao,  String unitLabel,  bool isActive, @JsonKey(unknownEnumValue: ProductType.resale)  ProductType type)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.storeId,_that.name,_that.description,_that.imagePath,_that.purchasePriceCents,_that.salePriceCents,_that.stockQuantity,_that.code,_that.vendaPorFracao,_that.unitLabel,_that.isActive,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.id, this.storeId = 'st1', required this.name, this.description = '', this.imagePath = '', required this.purchasePriceCents, required this.salePriceCents, this.stockQuantity = 0, this.code = '', this.vendaPorFracao = false, this.unitLabel = 'un', this.isActive = true, @JsonKey(unknownEnumValue: ProductType.resale) this.type = ProductType.resale});
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String id;
// Loja dona do produto — cada loja tem seu próprio estoque (Fase 2
// do multi-tenancy). O valor default mantém compatibilidade com
// construções antigas; a UI sempre carimba a loja ativa.
@override@JsonKey() final  String storeId;
@override final  String name;
@override@JsonKey() final  String description;
// Foto do produto (opcional): referência da imagem — URL pública do
// Supabase Storage (modo SaaS) ou caminho de arquivo local (modo
// SQLite). Vazio = sem foto (a UI mostra o ícone padrão do produto).
@override@JsonKey() final  String imagePath;
// Preços em CENTAVOS inteiros (W4 — migração de dinheiro para
// centavos; o banco persiste BIGINT/INTEGER).
@override final  int purchasePriceCents;
@override final  int salePriceCents;
// Estoque em MILÉSIMOS de unidade (W11): 1000 = 1 unidade (produtos
// normais) ou 1 kg/litro (produtos por peso). Inteiro exato — mesma
// filosofia dos centavos (W4).
@override@JsonKey() final  int stockQuantity;
// Código de barras/PLU do produto (opcional, até 5 dígitos): usado
// pelas balanças etiquetadoras (formato 20PPPPPWWWWW) e pelo campo de
// código de barras do PDV. Os ids internos são alfanuméricos longos;
// o PLU é o código numérico impresso nas etiquetas.
@override@JsonKey() final  String code;
// Venda por FRAÇÃO (peso/granel): quando verdadeiro, o PDV aceita
// quantidades decimais (ex.: 1,75 kg) e o código de barras de balança
// é interpretado. O preço unitário é por UNIDADE da [unitLabel]
// (ex.: por kg).
@override@JsonKey() final  bool vendaPorFracao;
// Unidade de venda dos produtos por peso (kg, g, l, ml...). 'un'
// (padrão) = unidade inteira normal.
@override@JsonKey() final  String unitLabel;
// Produto ATIVO no catálogo (padrão). Ao ser desativado, some do PDV
// e das compras (não pode ser vendido nem reposto), mas permanece na
// lista de Produtos com o selo "Inativo" — o dono/gerente pode
// reativá-lo quando quiser. O estoque existente é preservado (volta a
// ser vendível na reativação).
@override@JsonKey() final  bool isActive;
// Tipo estrutural do produto (Fase 1). Default [ProductType.resale]
// por compatibilidade: produtos antigos (sem a coluna no banco) já
// eram compráveis e vendáveis — a leitura preserva o comportamento;
// o JSON externo sem o campo também cai no default.
//
// `unknownEnumValue`: um valor NÃO reconhecido (ex.: gravado por uma
// versão mais nova do app) cai em [ProductType.resale] em vez de
// lançar `ArgumentError` — mesma tolerância dos datasources SQLite e
// Supabase, que fazem `firstWhere(...orElse: resale)` ao mapear a
// coluna `type`.
@override@JsonKey(unknownEnumValue: ProductType.resale) final  ProductType type;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.storeId, storeId) || other.storeId == storeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.purchasePriceCents, purchasePriceCents) || other.purchasePriceCents == purchasePriceCents)&&(identical(other.salePriceCents, salePriceCents) || other.salePriceCents == salePriceCents)&&(identical(other.stockQuantity, stockQuantity) || other.stockQuantity == stockQuantity)&&(identical(other.code, code) || other.code == code)&&(identical(other.vendaPorFracao, vendaPorFracao) || other.vendaPorFracao == vendaPorFracao)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,storeId,name,description,imagePath,purchasePriceCents,salePriceCents,stockQuantity,code,vendaPorFracao,unitLabel,isActive,type);

@override
String toString() {
  return 'Product(id: $id, storeId: $storeId, name: $name, description: $description, imagePath: $imagePath, purchasePriceCents: $purchasePriceCents, salePriceCents: $salePriceCents, stockQuantity: $stockQuantity, code: $code, vendaPorFracao: $vendaPorFracao, unitLabel: $unitLabel, isActive: $isActive, type: $type)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String storeId, String name, String description, String imagePath, int purchasePriceCents, int salePriceCents, int stockQuantity, String code, bool vendaPorFracao, String unitLabel, bool isActive,@JsonKey(unknownEnumValue: ProductType.resale) ProductType type
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? storeId = null,Object? name = null,Object? description = null,Object? imagePath = null,Object? purchasePriceCents = null,Object? salePriceCents = null,Object? stockQuantity = null,Object? code = null,Object? vendaPorFracao = null,Object? unitLabel = null,Object? isActive = null,Object? type = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,storeId: null == storeId ? _self.storeId : storeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,purchasePriceCents: null == purchasePriceCents ? _self.purchasePriceCents : purchasePriceCents // ignore: cast_nullable_to_non_nullable
as int,salePriceCents: null == salePriceCents ? _self.salePriceCents : salePriceCents // ignore: cast_nullable_to_non_nullable
as int,stockQuantity: null == stockQuantity ? _self.stockQuantity : stockQuantity // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,vendaPorFracao: null == vendaPorFracao ? _self.vendaPorFracao : vendaPorFracao // ignore: cast_nullable_to_non_nullable
as bool,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProductType,
  ));
}


}

// dart format on
