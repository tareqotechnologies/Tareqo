// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminMessage {

 String get id;/// Tenant destinatário da mensagem.
 String get tenantId;/// Tipo da mensagem.
 AdminMessageType get type;/// Título da mensagem (ex.: "Cotação de Plano", "Validade Alterada").
 String get title;/// Corpo da mensagem (ex.: "O seu plano Pro foi renovado até 15/09/2026").
 String get body;/// Se a mensagem foi lida pelo dono do tenant.
 bool get isRead;/// Data de criação.
 DateTime get createdAt;/// Data em que foi lida (null enquanto não lida).
 DateTime? get readAt;
/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminMessageCopyWith<AdminMessage> get copyWith => _$AdminMessageCopyWithImpl<AdminMessage>(this as AdminMessage, _$identity);

  /// Serializes this AdminMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,type,title,body,isRead,createdAt,readAt);

@override
String toString() {
  return 'AdminMessage(id: $id, tenantId: $tenantId, type: $type, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class $AdminMessageCopyWith<$Res>  {
  factory $AdminMessageCopyWith(AdminMessage value, $Res Function(AdminMessage) _then) = _$AdminMessageCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, AdminMessageType type, String title, String body, bool isRead, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class _$AdminMessageCopyWithImpl<$Res>
    implements $AdminMessageCopyWith<$Res> {
  _$AdminMessageCopyWithImpl(this._self, this._then);

  final AdminMessage _self;
  final $Res Function(AdminMessage) _then;

/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? type = null,Object? title = null,Object? body = null,Object? isRead = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AdminMessageType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminMessage].
extension AdminMessagePatterns on AdminMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminMessage value)  $default,){
final _that = this;
switch (_that) {
case _AdminMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminMessage value)?  $default,){
final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  AdminMessageType type,  String title,  String body,  bool isRead,  DateTime createdAt,  DateTime? readAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
return $default(_that.id,_that.tenantId,_that.type,_that.title,_that.body,_that.isRead,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  AdminMessageType type,  String title,  String body,  bool isRead,  DateTime createdAt,  DateTime? readAt)  $default,) {final _that = this;
switch (_that) {
case _AdminMessage():
return $default(_that.id,_that.tenantId,_that.type,_that.title,_that.body,_that.isRead,_that.createdAt,_that.readAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  AdminMessageType type,  String title,  String body,  bool isRead,  DateTime createdAt,  DateTime? readAt)?  $default,) {final _that = this;
switch (_that) {
case _AdminMessage() when $default != null:
return $default(_that.id,_that.tenantId,_that.type,_that.title,_that.body,_that.isRead,_that.createdAt,_that.readAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminMessage implements AdminMessage {
  const _AdminMessage({required this.id, required this.tenantId, required this.type, required this.title, required this.body, this.isRead = false, required this.createdAt, this.readAt});
  factory _AdminMessage.fromJson(Map<String, dynamic> json) => _$AdminMessageFromJson(json);

@override final  String id;
/// Tenant destinatário da mensagem.
@override final  String tenantId;
/// Tipo da mensagem.
@override final  AdminMessageType type;
/// Título da mensagem (ex.: "Cotação de Plano", "Validade Alterada").
@override final  String title;
/// Corpo da mensagem (ex.: "O seu plano Pro foi renovado até 15/09/2026").
@override final  String body;
/// Se a mensagem foi lida pelo dono do tenant.
@override@JsonKey() final  bool isRead;
/// Data de criação.
@override final  DateTime createdAt;
/// Data em que foi lida (null enquanto não lida).
@override final  DateTime? readAt;

/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminMessageCopyWith<_AdminMessage> get copyWith => __$AdminMessageCopyWithImpl<_AdminMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.readAt, readAt) || other.readAt == readAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tenantId,type,title,body,isRead,createdAt,readAt);

@override
String toString() {
  return 'AdminMessage(id: $id, tenantId: $tenantId, type: $type, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt, readAt: $readAt)';
}


}

/// @nodoc
abstract mixin class _$AdminMessageCopyWith<$Res> implements $AdminMessageCopyWith<$Res> {
  factory _$AdminMessageCopyWith(_AdminMessage value, $Res Function(_AdminMessage) _then) = __$AdminMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, AdminMessageType type, String title, String body, bool isRead, DateTime createdAt, DateTime? readAt
});




}
/// @nodoc
class __$AdminMessageCopyWithImpl<$Res>
    implements _$AdminMessageCopyWith<$Res> {
  __$AdminMessageCopyWithImpl(this._self, this._then);

  final _AdminMessage _self;
  final $Res Function(_AdminMessage) _then;

/// Create a copy of AdminMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? type = null,Object? title = null,Object? body = null,Object? isRead = null,Object? createdAt = null,Object? readAt = freezed,}) {
  return _then(_AdminMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AdminMessageType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
