// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvoiceNotification {

 String get id;/// Tenant destinatário da notificação.
 String get tenantId;/// Factura associada (pode ser null para notificações gerais).
 String? get invoiceId;/// Tipo da notificação.
 InvoiceNotificationType get type;/// Título da notificação (ex.: "Nova factura gerada").
 String get title;/// Corpo da notificação (ex.: "Factura INV-00001 no valor de 5000 MZN").
 String get body;/// Se a notificação foi lida pelo dono.
 bool get isRead;/// Data de criação.
 DateTime get createdAt;/// Data em que foi lida (null enquanto não lida).
 DateTime? get readAt;
/// Create a copy of InvoiceNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceNotificationCopyWith<InvoiceNotification> get copyWith => _$InvoiceNotificationCopyWithImpl<InvoiceNotification>(this as InvoiceNotification, _$identity);

  /// Serializes this InvoiceNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,invoiceId,type,title,body,isRead,createdAt,readAt);

@override
String toString() {
  return 'InvoiceNotification(id: $id, tenantId: $tenantId, invoiceId: $invoiceId, type: $type, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class $InvoiceNotificationCopyWith<$Res>  {
  factory $InvoiceNotificationCopyWith(InvoiceNotification value, $Res Function(InvoiceNotification) _then) = _$InvoiceNotificationCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String? invoiceId, InvoiceNotificationType type, String title, String body, bool isRead, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class _$InvoiceNotificationCopyWithImpl<$Res>
    implements $InvoiceNotificationCopyWith<$Res> {
  _$InvoiceNotificationCopyWithImpl(this._self, this._then);

  final InvoiceNotification _self;
  final $Res Function(InvoiceNotification) _then;

/// Create a copy of InvoiceNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? invoiceId = freezed,Object? type = null,Object? title = null,Object? body = null,Object? isRead = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,invoiceId: freezed == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InvoiceNotificationType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceNotification].
extension InvoiceNotificationPatterns on InvoiceNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceNotification value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceNotification value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String? invoiceId,  InvoiceNotificationType type,  String title,  String body,  bool isRead,  DateTime createdAt,  DateTime? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceNotification() when $default != null:
return $default(_that.id,_that.tenantId,_that.invoiceId,_that.type,_that.title,_that.body,_that.isRead,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String? invoiceId,  InvoiceNotificationType type,  String title,  String body,  bool isRead,  DateTime createdAt,  DateTime? readAt)  $default,) {final _that = this;
switch (_that) {
case _InvoiceNotification():
return $default(_that.id,_that.tenantId,_that.invoiceId,_that.type,_that.title,_that.body,_that.isRead,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String? invoiceId,  InvoiceNotificationType type,  String title,  String body,  bool isRead,  DateTime createdAt,  DateTime? readAt)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceNotification() when $default != null:
return $default(_that.id,_that.tenantId,_that.invoiceId,_that.type,_that.title,_that.body,_that.isRead,_that.createdAt,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceNotification implements InvoiceNotification {
  const _InvoiceNotification({required this.id, required this.tenantId, this.invoiceId, required this.type, required this.title, required this.body, this.isRead = false, required this.createdAt, this.readAt});
  factory _InvoiceNotification.fromJson(Map<String, dynamic> json) => _$InvoiceNotificationFromJson(json);

@override final  String id;
/// Tenant destinatário da notificação.
@override final  String tenantId;
/// Factura associada (pode ser null para notificações gerais).
@override final  String? invoiceId;
/// Tipo da notificação.
@override final  InvoiceNotificationType type;
/// Título da notificação (ex.: "Nova factura gerada").
@override final  String title;
/// Corpo da notificação (ex.: "Factura INV-00001 no valor de 5000 MZN").
@override final  String body;
/// Se a notificação foi lida pelo dono.
@override@JsonKey() final  bool isRead;
/// Data de criação.
@override final  DateTime createdAt;
/// Data em que foi lida (null enquanto não lida).
@override final  DateTime? readAt;

/// Create a copy of InvoiceNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceNotificationCopyWith<_InvoiceNotification> get copyWith => __$InvoiceNotificationCopyWithImpl<_InvoiceNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.invoiceId, invoiceId) || other.invoiceId == invoiceId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,invoiceId,type,title,body,isRead,createdAt,readAt);

@override
String toString() {
  return 'InvoiceNotification(id: $id, tenantId: $tenantId, invoiceId: $invoiceId, type: $type, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$InvoiceNotificationCopyWith<$Res> implements $InvoiceNotificationCopyWith<$Res> {
  factory _$InvoiceNotificationCopyWith(_InvoiceNotification value, $Res Function(_InvoiceNotification) _then) = __$InvoiceNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String? invoiceId, InvoiceNotificationType type, String title, String body, bool isRead, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class __$InvoiceNotificationCopyWithImpl<$Res>
    implements _$InvoiceNotificationCopyWith<$Res> {
  __$InvoiceNotificationCopyWithImpl(this._self, this._then);

  final _InvoiceNotification _self;
  final $Res Function(_InvoiceNotification) _then;

/// Create a copy of InvoiceNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? invoiceId = freezed,Object? type = null,Object? title = null,Object? body = null,Object? isRead = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_InvoiceNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,invoiceId: freezed == invoiceId ? _self.invoiceId : invoiceId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as InvoiceNotificationType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
