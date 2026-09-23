// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kick_chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KickChatMessage {

 String get id;@JsonKey(name: 'chatroom_id') int? get chatroomId; String get content;/// `message` | `reply` on the wire — [KickChatMessageType.system] is
/// synthetic (never parsed).
@JsonKey(fromJson: KickChatMessageType.parse) KickChatMessageType get type;@JsonKey(name: 'created_at') DateTime? get createdAt; KickChatSender? get sender;@JsonKey(fromJson: KickChatMessageMetadata.parse) KickChatMessageMetadata? get metadata;/// Local lifecycle flag — set by the chat store when a
/// `MessageDeletedEvent` / `UserBannedEvent` arrives for this message
/// (dim + marker, same UX as Twitch/YouTube); never part of the
/// wire JSON.
@JsonKey(includeFromJson: false, includeToJson: false) bool get isTombstoned;/// Loaded by the join backfill (sent before this session joined) —
/// rendered dimmed, with the "New messages" divider after the last one.
@JsonKey(includeFromJson: false, includeToJson: false) bool get isHistorical;
/// Create a copy of KickChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickChatMessageCopyWith<KickChatMessage> get copyWith => _$KickChatMessageCopyWithImpl<KickChatMessage>(this as KickChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.chatroomId, chatroomId) || other.chatroomId == chatroomId)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.isTombstoned, isTombstoned) || other.isTombstoned == isTombstoned)&&(identical(other.isHistorical, isHistorical) || other.isHistorical == isHistorical));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,chatroomId,content,type,createdAt,sender,metadata,isTombstoned,isHistorical);

@override
String toString() {
  return 'KickChatMessage(id: $id, chatroomId: $chatroomId, content: $content, type: $type, createdAt: $createdAt, sender: $sender, metadata: $metadata, isTombstoned: $isTombstoned, isHistorical: $isHistorical)';
}


}

/// @nodoc
abstract mixin class $KickChatMessageCopyWith<$Res>  {
  factory $KickChatMessageCopyWith(KickChatMessage value, $Res Function(KickChatMessage) _then) = _$KickChatMessageCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'chatroom_id') int? chatroomId, String content,@JsonKey(fromJson: KickChatMessageType.parse) KickChatMessageType type,@JsonKey(name: 'created_at') DateTime? createdAt, KickChatSender? sender,@JsonKey(fromJson: KickChatMessageMetadata.parse) KickChatMessageMetadata? metadata,@JsonKey(includeFromJson: false, includeToJson: false) bool isTombstoned,@JsonKey(includeFromJson: false, includeToJson: false) bool isHistorical
});


$KickChatSenderCopyWith<$Res>? get sender;

}
/// @nodoc
class _$KickChatMessageCopyWithImpl<$Res>
    implements $KickChatMessageCopyWith<$Res> {
  _$KickChatMessageCopyWithImpl(this._self, this._then);

  final KickChatMessage _self;
  final $Res Function(KickChatMessage) _then;

/// Create a copy of KickChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? chatroomId = freezed,Object? content = null,Object? type = null,Object? createdAt = freezed,Object? sender = freezed,Object? metadata = freezed,Object? isTombstoned = null,Object? isHistorical = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chatroomId: freezed == chatroomId ? _self.chatroomId : chatroomId // ignore: cast_nullable_to_non_nullable
as int?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as KickChatMessageType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as KickChatSender?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as KickChatMessageMetadata?,isTombstoned: null == isTombstoned ? _self.isTombstoned : isTombstoned // ignore: cast_nullable_to_non_nullable
as bool,isHistorical: null == isHistorical ? _self.isHistorical : isHistorical // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of KickChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickChatSenderCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $KickChatSenderCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// Adds pattern-matching-related methods to [KickChatMessage].
extension KickChatMessagePatterns on KickChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _KickChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _KickChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'chatroom_id')  int? chatroomId,  String content, @JsonKey(fromJson: KickChatMessageType.parse)  KickChatMessageType type, @JsonKey(name: 'created_at')  DateTime? createdAt,  KickChatSender? sender, @JsonKey(fromJson: KickChatMessageMetadata.parse)  KickChatMessageMetadata? metadata, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTombstoned, @JsonKey(includeFromJson: false, includeToJson: false)  bool isHistorical)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickChatMessage() when $default != null:
return $default(_that.id,_that.chatroomId,_that.content,_that.type,_that.createdAt,_that.sender,_that.metadata,_that.isTombstoned,_that.isHistorical);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'chatroom_id')  int? chatroomId,  String content, @JsonKey(fromJson: KickChatMessageType.parse)  KickChatMessageType type, @JsonKey(name: 'created_at')  DateTime? createdAt,  KickChatSender? sender, @JsonKey(fromJson: KickChatMessageMetadata.parse)  KickChatMessageMetadata? metadata, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTombstoned, @JsonKey(includeFromJson: false, includeToJson: false)  bool isHistorical)  $default,) {final _that = this;
switch (_that) {
case _KickChatMessage():
return $default(_that.id,_that.chatroomId,_that.content,_that.type,_that.createdAt,_that.sender,_that.metadata,_that.isTombstoned,_that.isHistorical);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'chatroom_id')  int? chatroomId,  String content, @JsonKey(fromJson: KickChatMessageType.parse)  KickChatMessageType type, @JsonKey(name: 'created_at')  DateTime? createdAt,  KickChatSender? sender, @JsonKey(fromJson: KickChatMessageMetadata.parse)  KickChatMessageMetadata? metadata, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTombstoned, @JsonKey(includeFromJson: false, includeToJson: false)  bool isHistorical)?  $default,) {final _that = this;
switch (_that) {
case _KickChatMessage() when $default != null:
return $default(_that.id,_that.chatroomId,_that.content,_that.type,_that.createdAt,_that.sender,_that.metadata,_that.isTombstoned,_that.isHistorical);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickChatMessage extends KickChatMessage {
  const _KickChatMessage({required this.id, @JsonKey(name: 'chatroom_id') this.chatroomId, this.content = '', @JsonKey(fromJson: KickChatMessageType.parse) this.type = KickChatMessageType.message, @JsonKey(name: 'created_at') this.createdAt, this.sender, @JsonKey(fromJson: KickChatMessageMetadata.parse) this.metadata, @JsonKey(includeFromJson: false, includeToJson: false) this.isTombstoned = false, @JsonKey(includeFromJson: false, includeToJson: false) this.isHistorical = false}): super._();
  factory _KickChatMessage.fromJson(Map<String, dynamic> json) => _$KickChatMessageFromJson(json);

@override final  String id;
@override@JsonKey(name: 'chatroom_id') final  int? chatroomId;
@override@JsonKey() final  String content;
/// `message` | `reply` on the wire — [KickChatMessageType.system] is
/// synthetic (never parsed).
@override@JsonKey(fromJson: KickChatMessageType.parse) final  KickChatMessageType type;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override final  KickChatSender? sender;
@override@JsonKey(fromJson: KickChatMessageMetadata.parse) final  KickChatMessageMetadata? metadata;
/// Local lifecycle flag — set by the chat store when a
/// `MessageDeletedEvent` / `UserBannedEvent` arrives for this message
/// (dim + marker, same UX as Twitch/YouTube); never part of the
/// wire JSON.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isTombstoned;
/// Loaded by the join backfill (sent before this session joined) —
/// rendered dimmed, with the "New messages" divider after the last one.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isHistorical;

/// Create a copy of KickChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickChatMessageCopyWith<_KickChatMessage> get copyWith => __$KickChatMessageCopyWithImpl<_KickChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.chatroomId, chatroomId) || other.chatroomId == chatroomId)&&(identical(other.content, content) || other.content == content)&&(identical(other.type, type) || other.type == type)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.isTombstoned, isTombstoned) || other.isTombstoned == isTombstoned)&&(identical(other.isHistorical, isHistorical) || other.isHistorical == isHistorical));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,chatroomId,content,type,createdAt,sender,metadata,isTombstoned,isHistorical);

@override
String toString() {
  return 'KickChatMessage(id: $id, chatroomId: $chatroomId, content: $content, type: $type, createdAt: $createdAt, sender: $sender, metadata: $metadata, isTombstoned: $isTombstoned, isHistorical: $isHistorical)';
}


}

/// @nodoc
abstract mixin class _$KickChatMessageCopyWith<$Res> implements $KickChatMessageCopyWith<$Res> {
  factory _$KickChatMessageCopyWith(_KickChatMessage value, $Res Function(_KickChatMessage) _then) = __$KickChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'chatroom_id') int? chatroomId, String content,@JsonKey(fromJson: KickChatMessageType.parse) KickChatMessageType type,@JsonKey(name: 'created_at') DateTime? createdAt, KickChatSender? sender,@JsonKey(fromJson: KickChatMessageMetadata.parse) KickChatMessageMetadata? metadata,@JsonKey(includeFromJson: false, includeToJson: false) bool isTombstoned,@JsonKey(includeFromJson: false, includeToJson: false) bool isHistorical
});


@override $KickChatSenderCopyWith<$Res>? get sender;

}
/// @nodoc
class __$KickChatMessageCopyWithImpl<$Res>
    implements _$KickChatMessageCopyWith<$Res> {
  __$KickChatMessageCopyWithImpl(this._self, this._then);

  final _KickChatMessage _self;
  final $Res Function(_KickChatMessage) _then;

/// Create a copy of KickChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? chatroomId = freezed,Object? content = null,Object? type = null,Object? createdAt = freezed,Object? sender = freezed,Object? metadata = freezed,Object? isTombstoned = null,Object? isHistorical = null,}) {
  return _then(_KickChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,chatroomId: freezed == chatroomId ? _self.chatroomId : chatroomId // ignore: cast_nullable_to_non_nullable
as int?,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as KickChatMessageType,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,sender: freezed == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as KickChatSender?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as KickChatMessageMetadata?,isTombstoned: null == isTombstoned ? _self.isTombstoned : isTombstoned // ignore: cast_nullable_to_non_nullable
as bool,isHistorical: null == isHistorical ? _self.isHistorical : isHistorical // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of KickChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickChatSenderCopyWith<$Res>? get sender {
    if (_self.sender == null) {
    return null;
  }

  return $KickChatSenderCopyWith<$Res>(_self.sender!, (value) {
    return _then(_self.copyWith(sender: value));
  });
}
}


/// @nodoc
mixin _$KickChatSender {

 int? get id; String? get username; String? get slug; KickChatIdentity? get identity;
/// Create a copy of KickChatSender
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickChatSenderCopyWith<KickChatSender> get copyWith => _$KickChatSenderCopyWithImpl<KickChatSender>(this as KickChatSender, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickChatSender&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.identity, identity) || other.identity == identity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,slug,identity);

@override
String toString() {
  return 'KickChatSender(id: $id, username: $username, slug: $slug, identity: $identity)';
}


}

/// @nodoc
abstract mixin class $KickChatSenderCopyWith<$Res>  {
  factory $KickChatSenderCopyWith(KickChatSender value, $Res Function(KickChatSender) _then) = _$KickChatSenderCopyWithImpl;
@useResult
$Res call({
 int? id, String? username, String? slug, KickChatIdentity? identity
});


$KickChatIdentityCopyWith<$Res>? get identity;

}
/// @nodoc
class _$KickChatSenderCopyWithImpl<$Res>
    implements $KickChatSenderCopyWith<$Res> {
  _$KickChatSenderCopyWithImpl(this._self, this._then);

  final KickChatSender _self;
  final $Res Function(KickChatSender) _then;

/// Create a copy of KickChatSender
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? username = freezed,Object? slug = freezed,Object? identity = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,identity: freezed == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as KickChatIdentity?,
  ));
}
/// Create a copy of KickChatSender
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickChatIdentityCopyWith<$Res>? get identity {
    if (_self.identity == null) {
    return null;
  }

  return $KickChatIdentityCopyWith<$Res>(_self.identity!, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}


/// Adds pattern-matching-related methods to [KickChatSender].
extension KickChatSenderPatterns on KickChatSender {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickChatSender value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickChatSender() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickChatSender value)  $default,){
final _that = this;
switch (_that) {
case _KickChatSender():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickChatSender value)?  $default,){
final _that = this;
switch (_that) {
case _KickChatSender() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? username,  String? slug,  KickChatIdentity? identity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickChatSender() when $default != null:
return $default(_that.id,_that.username,_that.slug,_that.identity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? username,  String? slug,  KickChatIdentity? identity)  $default,) {final _that = this;
switch (_that) {
case _KickChatSender():
return $default(_that.id,_that.username,_that.slug,_that.identity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? username,  String? slug,  KickChatIdentity? identity)?  $default,) {final _that = this;
switch (_that) {
case _KickChatSender() when $default != null:
return $default(_that.id,_that.username,_that.slug,_that.identity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickChatSender implements KickChatSender {
  const _KickChatSender({this.id, this.username, this.slug, this.identity});
  factory _KickChatSender.fromJson(Map<String, dynamic> json) => _$KickChatSenderFromJson(json);

@override final  int? id;
@override final  String? username;
@override final  String? slug;
@override final  KickChatIdentity? identity;

/// Create a copy of KickChatSender
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickChatSenderCopyWith<_KickChatSender> get copyWith => __$KickChatSenderCopyWithImpl<_KickChatSender>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickChatSender&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.identity, identity) || other.identity == identity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,slug,identity);

@override
String toString() {
  return 'KickChatSender(id: $id, username: $username, slug: $slug, identity: $identity)';
}


}

/// @nodoc
abstract mixin class _$KickChatSenderCopyWith<$Res> implements $KickChatSenderCopyWith<$Res> {
  factory _$KickChatSenderCopyWith(_KickChatSender value, $Res Function(_KickChatSender) _then) = __$KickChatSenderCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? username, String? slug, KickChatIdentity? identity
});


@override $KickChatIdentityCopyWith<$Res>? get identity;

}
/// @nodoc
class __$KickChatSenderCopyWithImpl<$Res>
    implements _$KickChatSenderCopyWith<$Res> {
  __$KickChatSenderCopyWithImpl(this._self, this._then);

  final _KickChatSender _self;
  final $Res Function(_KickChatSender) _then;

/// Create a copy of KickChatSender
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? username = freezed,Object? slug = freezed,Object? identity = freezed,}) {
  return _then(_KickChatSender(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,identity: freezed == identity ? _self.identity : identity // ignore: cast_nullable_to_non_nullable
as KickChatIdentity?,
  ));
}

/// Create a copy of KickChatSender
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickChatIdentityCopyWith<$Res>? get identity {
    if (_self.identity == null) {
    return null;
  }

  return $KickChatIdentityCopyWith<$Res>(_self.identity!, (value) {
    return _then(_self.copyWith(identity: value));
  });
}
}


/// @nodoc
mixin _$KickChatIdentity {

 String? get color; List<KickChatLegacyBadge> get badges;@JsonKey(name: 'badges_v2') List<KickChatBadgeV2> get badgesV2;
/// Create a copy of KickChatIdentity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickChatIdentityCopyWith<KickChatIdentity> get copyWith => _$KickChatIdentityCopyWithImpl<KickChatIdentity>(this as KickChatIdentity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickChatIdentity&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.badges, badges)&&const DeepCollectionEquality().equals(other.badgesV2, badgesV2));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,color,const DeepCollectionEquality().hash(badges),const DeepCollectionEquality().hash(badgesV2));

@override
String toString() {
  return 'KickChatIdentity(color: $color, badges: $badges, badgesV2: $badgesV2)';
}


}

/// @nodoc
abstract mixin class $KickChatIdentityCopyWith<$Res>  {
  factory $KickChatIdentityCopyWith(KickChatIdentity value, $Res Function(KickChatIdentity) _then) = _$KickChatIdentityCopyWithImpl;
@useResult
$Res call({
 String? color, List<KickChatLegacyBadge> badges,@JsonKey(name: 'badges_v2') List<KickChatBadgeV2> badgesV2
});




}
/// @nodoc
class _$KickChatIdentityCopyWithImpl<$Res>
    implements $KickChatIdentityCopyWith<$Res> {
  _$KickChatIdentityCopyWithImpl(this._self, this._then);

  final KickChatIdentity _self;
  final $Res Function(KickChatIdentity) _then;

/// Create a copy of KickChatIdentity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = freezed,Object? badges = null,Object? badgesV2 = null,}) {
  return _then(_self.copyWith(
color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<KickChatLegacyBadge>,badgesV2: null == badgesV2 ? _self.badgesV2 : badgesV2 // ignore: cast_nullable_to_non_nullable
as List<KickChatBadgeV2>,
  ));
}

}


/// Adds pattern-matching-related methods to [KickChatIdentity].
extension KickChatIdentityPatterns on KickChatIdentity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickChatIdentity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickChatIdentity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickChatIdentity value)  $default,){
final _that = this;
switch (_that) {
case _KickChatIdentity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickChatIdentity value)?  $default,){
final _that = this;
switch (_that) {
case _KickChatIdentity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? color,  List<KickChatLegacyBadge> badges, @JsonKey(name: 'badges_v2')  List<KickChatBadgeV2> badgesV2)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickChatIdentity() when $default != null:
return $default(_that.color,_that.badges,_that.badgesV2);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? color,  List<KickChatLegacyBadge> badges, @JsonKey(name: 'badges_v2')  List<KickChatBadgeV2> badgesV2)  $default,) {final _that = this;
switch (_that) {
case _KickChatIdentity():
return $default(_that.color,_that.badges,_that.badgesV2);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? color,  List<KickChatLegacyBadge> badges, @JsonKey(name: 'badges_v2')  List<KickChatBadgeV2> badgesV2)?  $default,) {final _that = this;
switch (_that) {
case _KickChatIdentity() when $default != null:
return $default(_that.color,_that.badges,_that.badgesV2);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickChatIdentity extends KickChatIdentity {
  const _KickChatIdentity({this.color, final  List<KickChatLegacyBadge> badges = const <KickChatLegacyBadge>[], @JsonKey(name: 'badges_v2') final  List<KickChatBadgeV2> badgesV2 = const <KickChatBadgeV2>[]}): _badges = badges,_badgesV2 = badgesV2,super._();
  factory _KickChatIdentity.fromJson(Map<String, dynamic> json) => _$KickChatIdentityFromJson(json);

@override final  String? color;
 final  List<KickChatLegacyBadge> _badges;
@override@JsonKey() List<KickChatLegacyBadge> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

 final  List<KickChatBadgeV2> _badgesV2;
@override@JsonKey(name: 'badges_v2') List<KickChatBadgeV2> get badgesV2 {
  if (_badgesV2 is EqualUnmodifiableListView) return _badgesV2;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badgesV2);
}


/// Create a copy of KickChatIdentity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickChatIdentityCopyWith<_KickChatIdentity> get copyWith => __$KickChatIdentityCopyWithImpl<_KickChatIdentity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickChatIdentity&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other._badges, _badges)&&const DeepCollectionEquality().equals(other._badgesV2, _badgesV2));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,color,const DeepCollectionEquality().hash(_badges),const DeepCollectionEquality().hash(_badgesV2));

@override
String toString() {
  return 'KickChatIdentity(color: $color, badges: $badges, badgesV2: $badgesV2)';
}


}

/// @nodoc
abstract mixin class _$KickChatIdentityCopyWith<$Res> implements $KickChatIdentityCopyWith<$Res> {
  factory _$KickChatIdentityCopyWith(_KickChatIdentity value, $Res Function(_KickChatIdentity) _then) = __$KickChatIdentityCopyWithImpl;
@override @useResult
$Res call({
 String? color, List<KickChatLegacyBadge> badges,@JsonKey(name: 'badges_v2') List<KickChatBadgeV2> badgesV2
});




}
/// @nodoc
class __$KickChatIdentityCopyWithImpl<$Res>
    implements _$KickChatIdentityCopyWith<$Res> {
  __$KickChatIdentityCopyWithImpl(this._self, this._then);

  final _KickChatIdentity _self;
  final $Res Function(_KickChatIdentity) _then;

/// Create a copy of KickChatIdentity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? color = freezed,Object? badges = null,Object? badgesV2 = null,}) {
  return _then(_KickChatIdentity(
color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<KickChatLegacyBadge>,badgesV2: null == badgesV2 ? _self._badgesV2 : badgesV2 // ignore: cast_nullable_to_non_nullable
as List<KickChatBadgeV2>,
  ));
}


}


/// @nodoc
mixin _$KickChatBadgeV2 {

 String? get name;@JsonKey(name: 'badge_type') String? get badgeType;@JsonKey(name: 'image_url') String? get imageUrl;/// Free-form extras (e.g. `{"level": 32}`) — same String-or-Map
/// instability as message metadata.
@JsonKey(fromJson: kickJsonObject) Map<String, Object?>? get metadata; bool get selected;@JsonKey(name: 'sort_order') int? get sortOrder;
/// Create a copy of KickChatBadgeV2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickChatBadgeV2CopyWith<KickChatBadgeV2> get copyWith => _$KickChatBadgeV2CopyWithImpl<KickChatBadgeV2>(this as KickChatBadgeV2, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickChatBadgeV2&&(identical(other.name, name) || other.name == name)&&(identical(other.badgeType, badgeType) || other.badgeType == badgeType)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,badgeType,imageUrl,const DeepCollectionEquality().hash(metadata),selected,sortOrder);

@override
String toString() {
  return 'KickChatBadgeV2(name: $name, badgeType: $badgeType, imageUrl: $imageUrl, metadata: $metadata, selected: $selected, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $KickChatBadgeV2CopyWith<$Res>  {
  factory $KickChatBadgeV2CopyWith(KickChatBadgeV2 value, $Res Function(KickChatBadgeV2) _then) = _$KickChatBadgeV2CopyWithImpl;
@useResult
$Res call({
 String? name,@JsonKey(name: 'badge_type') String? badgeType,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(fromJson: kickJsonObject) Map<String, Object?>? metadata, bool selected,@JsonKey(name: 'sort_order') int? sortOrder
});




}
/// @nodoc
class _$KickChatBadgeV2CopyWithImpl<$Res>
    implements $KickChatBadgeV2CopyWith<$Res> {
  _$KickChatBadgeV2CopyWithImpl(this._self, this._then);

  final KickChatBadgeV2 _self;
  final $Res Function(KickChatBadgeV2) _then;

/// Create a copy of KickChatBadgeV2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? badgeType = freezed,Object? imageUrl = freezed,Object? metadata = freezed,Object? selected = null,Object? sortOrder = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,badgeType: freezed == badgeType ? _self.badgeType : badgeType // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [KickChatBadgeV2].
extension KickChatBadgeV2Patterns on KickChatBadgeV2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickChatBadgeV2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickChatBadgeV2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickChatBadgeV2 value)  $default,){
final _that = this;
switch (_that) {
case _KickChatBadgeV2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickChatBadgeV2 value)?  $default,){
final _that = this;
switch (_that) {
case _KickChatBadgeV2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'badge_type')  String? badgeType, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(fromJson: kickJsonObject)  Map<String, Object?>? metadata,  bool selected, @JsonKey(name: 'sort_order')  int? sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickChatBadgeV2() when $default != null:
return $default(_that.name,_that.badgeType,_that.imageUrl,_that.metadata,_that.selected,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? name, @JsonKey(name: 'badge_type')  String? badgeType, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(fromJson: kickJsonObject)  Map<String, Object?>? metadata,  bool selected, @JsonKey(name: 'sort_order')  int? sortOrder)  $default,) {final _that = this;
switch (_that) {
case _KickChatBadgeV2():
return $default(_that.name,_that.badgeType,_that.imageUrl,_that.metadata,_that.selected,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? name, @JsonKey(name: 'badge_type')  String? badgeType, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(fromJson: kickJsonObject)  Map<String, Object?>? metadata,  bool selected, @JsonKey(name: 'sort_order')  int? sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _KickChatBadgeV2() when $default != null:
return $default(_that.name,_that.badgeType,_that.imageUrl,_that.metadata,_that.selected,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickChatBadgeV2 implements KickChatBadgeV2 {
  const _KickChatBadgeV2({this.name, @JsonKey(name: 'badge_type') this.badgeType, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(fromJson: kickJsonObject) final  Map<String, Object?>? metadata, this.selected = false, @JsonKey(name: 'sort_order') this.sortOrder}): _metadata = metadata;
  factory _KickChatBadgeV2.fromJson(Map<String, dynamic> json) => _$KickChatBadgeV2FromJson(json);

@override final  String? name;
@override@JsonKey(name: 'badge_type') final  String? badgeType;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
/// Free-form extras (e.g. `{"level": 32}`) — same String-or-Map
/// instability as message metadata.
 final  Map<String, Object?>? _metadata;
/// Free-form extras (e.g. `{"level": 32}`) — same String-or-Map
/// instability as message metadata.
@override@JsonKey(fromJson: kickJsonObject) Map<String, Object?>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  bool selected;
@override@JsonKey(name: 'sort_order') final  int? sortOrder;

/// Create a copy of KickChatBadgeV2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickChatBadgeV2CopyWith<_KickChatBadgeV2> get copyWith => __$KickChatBadgeV2CopyWithImpl<_KickChatBadgeV2>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickChatBadgeV2&&(identical(other.name, name) || other.name == name)&&(identical(other.badgeType, badgeType) || other.badgeType == badgeType)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,badgeType,imageUrl,const DeepCollectionEquality().hash(_metadata),selected,sortOrder);

@override
String toString() {
  return 'KickChatBadgeV2(name: $name, badgeType: $badgeType, imageUrl: $imageUrl, metadata: $metadata, selected: $selected, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$KickChatBadgeV2CopyWith<$Res> implements $KickChatBadgeV2CopyWith<$Res> {
  factory _$KickChatBadgeV2CopyWith(_KickChatBadgeV2 value, $Res Function(_KickChatBadgeV2) _then) = __$KickChatBadgeV2CopyWithImpl;
@override @useResult
$Res call({
 String? name,@JsonKey(name: 'badge_type') String? badgeType,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(fromJson: kickJsonObject) Map<String, Object?>? metadata, bool selected,@JsonKey(name: 'sort_order') int? sortOrder
});




}
/// @nodoc
class __$KickChatBadgeV2CopyWithImpl<$Res>
    implements _$KickChatBadgeV2CopyWith<$Res> {
  __$KickChatBadgeV2CopyWithImpl(this._self, this._then);

  final _KickChatBadgeV2 _self;
  final $Res Function(_KickChatBadgeV2) _then;

/// Create a copy of KickChatBadgeV2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? badgeType = freezed,Object? imageUrl = freezed,Object? metadata = freezed,Object? selected = null,Object? sortOrder = freezed,}) {
  return _then(_KickChatBadgeV2(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,badgeType: freezed == badgeType ? _self.badgeType : badgeType // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$KickChatLegacyBadge {

 String? get type; String? get text; int? get count;
/// Create a copy of KickChatLegacyBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickChatLegacyBadgeCopyWith<KickChatLegacyBadge> get copyWith => _$KickChatLegacyBadgeCopyWithImpl<KickChatLegacyBadge>(this as KickChatLegacyBadge, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickChatLegacyBadge&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text,count);

@override
String toString() {
  return 'KickChatLegacyBadge(type: $type, text: $text, count: $count)';
}


}

/// @nodoc
abstract mixin class $KickChatLegacyBadgeCopyWith<$Res>  {
  factory $KickChatLegacyBadgeCopyWith(KickChatLegacyBadge value, $Res Function(KickChatLegacyBadge) _then) = _$KickChatLegacyBadgeCopyWithImpl;
@useResult
$Res call({
 String? type, String? text, int? count
});




}
/// @nodoc
class _$KickChatLegacyBadgeCopyWithImpl<$Res>
    implements $KickChatLegacyBadgeCopyWith<$Res> {
  _$KickChatLegacyBadgeCopyWithImpl(this._self, this._then);

  final KickChatLegacyBadge _self;
  final $Res Function(KickChatLegacyBadge) _then;

/// Create a copy of KickChatLegacyBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = freezed,Object? text = freezed,Object? count = freezed,}) {
  return _then(_self.copyWith(
type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [KickChatLegacyBadge].
extension KickChatLegacyBadgePatterns on KickChatLegacyBadge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickChatLegacyBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickChatLegacyBadge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickChatLegacyBadge value)  $default,){
final _that = this;
switch (_that) {
case _KickChatLegacyBadge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickChatLegacyBadge value)?  $default,){
final _that = this;
switch (_that) {
case _KickChatLegacyBadge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? type,  String? text,  int? count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickChatLegacyBadge() when $default != null:
return $default(_that.type,_that.text,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? type,  String? text,  int? count)  $default,) {final _that = this;
switch (_that) {
case _KickChatLegacyBadge():
return $default(_that.type,_that.text,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? type,  String? text,  int? count)?  $default,) {final _that = this;
switch (_that) {
case _KickChatLegacyBadge() when $default != null:
return $default(_that.type,_that.text,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickChatLegacyBadge implements KickChatLegacyBadge {
  const _KickChatLegacyBadge({this.type, this.text, this.count});
  factory _KickChatLegacyBadge.fromJson(Map<String, dynamic> json) => _$KickChatLegacyBadgeFromJson(json);

@override final  String? type;
@override final  String? text;
@override final  int? count;

/// Create a copy of KickChatLegacyBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickChatLegacyBadgeCopyWith<_KickChatLegacyBadge> get copyWith => __$KickChatLegacyBadgeCopyWithImpl<_KickChatLegacyBadge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickChatLegacyBadge&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text,count);

@override
String toString() {
  return 'KickChatLegacyBadge(type: $type, text: $text, count: $count)';
}


}

/// @nodoc
abstract mixin class _$KickChatLegacyBadgeCopyWith<$Res> implements $KickChatLegacyBadgeCopyWith<$Res> {
  factory _$KickChatLegacyBadgeCopyWith(_KickChatLegacyBadge value, $Res Function(_KickChatLegacyBadge) _then) = __$KickChatLegacyBadgeCopyWithImpl;
@override @useResult
$Res call({
 String? type, String? text, int? count
});




}
/// @nodoc
class __$KickChatLegacyBadgeCopyWithImpl<$Res>
    implements _$KickChatLegacyBadgeCopyWith<$Res> {
  __$KickChatLegacyBadgeCopyWithImpl(this._self, this._then);

  final _KickChatLegacyBadge _self;
  final $Res Function(_KickChatLegacyBadge) _then;

/// Create a copy of KickChatLegacyBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = freezed,Object? text = freezed,Object? count = freezed,}) {
  return _then(_KickChatLegacyBadge(
type: freezed == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,count: freezed == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
