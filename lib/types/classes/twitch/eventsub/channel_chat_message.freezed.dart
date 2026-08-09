// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessageEvent {

 String get broadcasterUserId; String get chatterUserId; String get chatterUserLogin; String get chatterUserName; String get messageId; ChatMessageText get message; String? get color; List<ChatMessageBadge> get badges;/// Twitch message kind — `text`, `user_intro` (intro), etc.
 String get messageType; ChatMessageReply? get reply;/// From EventSub envelope `metadata.message_timestamp` — not on the
/// chat event JSON. Stamped by [TwitchEventSubService] after parse.
@JsonKey(includeFromJson: false, includeToJson: false) DateTime? get receivedAt;/// First-time chatter highlight — from IRC `first-msg=1` (sidecar) or
/// `message_type == user_intro`. Not on the EventSub chat JSON.
@JsonKey(includeFromJson: false, includeToJson: false) bool get isFirstMessage;
/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageEventCopyWith<ChatMessageEvent> get copyWith => _$ChatMessageEventCopyWithImpl<ChatMessageEvent>(this as ChatMessageEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId)&&(identical(other.chatterUserId, chatterUserId) || other.chatterUserId == chatterUserId)&&(identical(other.chatterUserLogin, chatterUserLogin) || other.chatterUserLogin == chatterUserLogin)&&(identical(other.chatterUserName, chatterUserName) || other.chatterUserName == chatterUserName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.message, message) || other.message == message)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.badges, badges)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.isFirstMessage, isFirstMessage) || other.isFirstMessage == isFirstMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId,chatterUserId,chatterUserLogin,chatterUserName,messageId,message,color,const DeepCollectionEquality().hash(badges),messageType,reply,receivedAt,isFirstMessage);

@override
String toString() {
  return 'ChatMessageEvent(broadcasterUserId: $broadcasterUserId, chatterUserId: $chatterUserId, chatterUserLogin: $chatterUserLogin, chatterUserName: $chatterUserName, messageId: $messageId, message: $message, color: $color, badges: $badges, messageType: $messageType, reply: $reply, receivedAt: $receivedAt, isFirstMessage: $isFirstMessage)';
}


}

/// @nodoc
abstract mixin class $ChatMessageEventCopyWith<$Res>  {
  factory $ChatMessageEventCopyWith(ChatMessageEvent value, $Res Function(ChatMessageEvent) _then) = _$ChatMessageEventCopyWithImpl;
@useResult
$Res call({
 String broadcasterUserId, String chatterUserId, String chatterUserLogin, String chatterUserName, String messageId, ChatMessageText message, String? color, List<ChatMessageBadge> badges, String messageType, ChatMessageReply? reply,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? receivedAt,@JsonKey(includeFromJson: false, includeToJson: false) bool isFirstMessage
});


$ChatMessageTextCopyWith<$Res> get message;$ChatMessageReplyCopyWith<$Res>? get reply;

}
/// @nodoc
class _$ChatMessageEventCopyWithImpl<$Res>
    implements $ChatMessageEventCopyWith<$Res> {
  _$ChatMessageEventCopyWithImpl(this._self, this._then);

  final ChatMessageEvent _self;
  final $Res Function(ChatMessageEvent) _then;

/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? broadcasterUserId = null,Object? chatterUserId = null,Object? chatterUserLogin = null,Object? chatterUserName = null,Object? messageId = null,Object? message = null,Object? color = freezed,Object? badges = null,Object? messageType = null,Object? reply = freezed,Object? receivedAt = freezed,Object? isFirstMessage = null,}) {
  return _then(_self.copyWith(
broadcasterUserId: null == broadcasterUserId ? _self.broadcasterUserId : broadcasterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserId: null == chatterUserId ? _self.chatterUserId : chatterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserLogin: null == chatterUserLogin ? _self.chatterUserLogin : chatterUserLogin // ignore: cast_nullable_to_non_nullable
as String,chatterUserName: null == chatterUserName ? _self.chatterUserName : chatterUserName // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessageText,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<ChatMessageBadge>,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as ChatMessageReply?,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isFirstMessage: null == isFirstMessage ? _self.isFirstMessage : isFirstMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageTextCopyWith<$Res> get message {
  
  return $ChatMessageTextCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageReplyCopyWith<$Res>? get reply {
    if (_self.reply == null) {
    return null;
  }

  return $ChatMessageReplyCopyWith<$Res>(_self.reply!, (value) {
    return _then(_self.copyWith(reply: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessageEvent].
extension ChatMessageEventPatterns on ChatMessageEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  ChatMessageText message,  String? color,  List<ChatMessageBadge> badges,  String messageType,  ChatMessageReply? reply, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? receivedAt, @JsonKey(includeFromJson: false, includeToJson: false)  bool isFirstMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageEvent() when $default != null:
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.message,_that.color,_that.badges,_that.messageType,_that.reply,_that.receivedAt,_that.isFirstMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  ChatMessageText message,  String? color,  List<ChatMessageBadge> badges,  String messageType,  ChatMessageReply? reply, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? receivedAt, @JsonKey(includeFromJson: false, includeToJson: false)  bool isFirstMessage)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageEvent():
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.message,_that.color,_that.badges,_that.messageType,_that.reply,_that.receivedAt,_that.isFirstMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  ChatMessageText message,  String? color,  List<ChatMessageBadge> badges,  String messageType,  ChatMessageReply? reply, @JsonKey(includeFromJson: false, includeToJson: false)  DateTime? receivedAt, @JsonKey(includeFromJson: false, includeToJson: false)  bool isFirstMessage)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageEvent() when $default != null:
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.message,_that.color,_that.badges,_that.messageType,_that.reply,_that.receivedAt,_that.isFirstMessage);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatMessageEvent implements ChatMessageEvent {
  const _ChatMessageEvent({required this.broadcasterUserId, required this.chatterUserId, required this.chatterUserLogin, required this.chatterUserName, required this.messageId, required this.message, this.color, final  List<ChatMessageBadge> badges = const <ChatMessageBadge>[], this.messageType = 'text', this.reply, @JsonKey(includeFromJson: false, includeToJson: false) this.receivedAt, @JsonKey(includeFromJson: false, includeToJson: false) this.isFirstMessage = false}): _badges = badges;
  factory _ChatMessageEvent.fromJson(Map<String, dynamic> json) => _$ChatMessageEventFromJson(json);

@override final  String broadcasterUserId;
@override final  String chatterUserId;
@override final  String chatterUserLogin;
@override final  String chatterUserName;
@override final  String messageId;
@override final  ChatMessageText message;
@override final  String? color;
 final  List<ChatMessageBadge> _badges;
@override@JsonKey() List<ChatMessageBadge> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

/// Twitch message kind — `text`, `user_intro` (intro), etc.
@override@JsonKey() final  String messageType;
@override final  ChatMessageReply? reply;
/// From EventSub envelope `metadata.message_timestamp` — not on the
/// chat event JSON. Stamped by [TwitchEventSubService] after parse.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  DateTime? receivedAt;
/// First-time chatter highlight — from IRC `first-msg=1` (sidecar) or
/// `message_type == user_intro`. Not on the EventSub chat JSON.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isFirstMessage;

/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageEventCopyWith<_ChatMessageEvent> get copyWith => __$ChatMessageEventCopyWithImpl<_ChatMessageEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId)&&(identical(other.chatterUserId, chatterUserId) || other.chatterUserId == chatterUserId)&&(identical(other.chatterUserLogin, chatterUserLogin) || other.chatterUserLogin == chatterUserLogin)&&(identical(other.chatterUserName, chatterUserName) || other.chatterUserName == chatterUserName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.message, message) || other.message == message)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other._badges, _badges)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.receivedAt, receivedAt) || other.receivedAt == receivedAt)&&(identical(other.isFirstMessage, isFirstMessage) || other.isFirstMessage == isFirstMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId,chatterUserId,chatterUserLogin,chatterUserName,messageId,message,color,const DeepCollectionEquality().hash(_badges),messageType,reply,receivedAt,isFirstMessage);

@override
String toString() {
  return 'ChatMessageEvent(broadcasterUserId: $broadcasterUserId, chatterUserId: $chatterUserId, chatterUserLogin: $chatterUserLogin, chatterUserName: $chatterUserName, messageId: $messageId, message: $message, color: $color, badges: $badges, messageType: $messageType, reply: $reply, receivedAt: $receivedAt, isFirstMessage: $isFirstMessage)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageEventCopyWith<$Res> implements $ChatMessageEventCopyWith<$Res> {
  factory _$ChatMessageEventCopyWith(_ChatMessageEvent value, $Res Function(_ChatMessageEvent) _then) = __$ChatMessageEventCopyWithImpl;
@override @useResult
$Res call({
 String broadcasterUserId, String chatterUserId, String chatterUserLogin, String chatterUserName, String messageId, ChatMessageText message, String? color, List<ChatMessageBadge> badges, String messageType, ChatMessageReply? reply,@JsonKey(includeFromJson: false, includeToJson: false) DateTime? receivedAt,@JsonKey(includeFromJson: false, includeToJson: false) bool isFirstMessage
});


@override $ChatMessageTextCopyWith<$Res> get message;@override $ChatMessageReplyCopyWith<$Res>? get reply;

}
/// @nodoc
class __$ChatMessageEventCopyWithImpl<$Res>
    implements _$ChatMessageEventCopyWith<$Res> {
  __$ChatMessageEventCopyWithImpl(this._self, this._then);

  final _ChatMessageEvent _self;
  final $Res Function(_ChatMessageEvent) _then;

/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? broadcasterUserId = null,Object? chatterUserId = null,Object? chatterUserLogin = null,Object? chatterUserName = null,Object? messageId = null,Object? message = null,Object? color = freezed,Object? badges = null,Object? messageType = null,Object? reply = freezed,Object? receivedAt = freezed,Object? isFirstMessage = null,}) {
  return _then(_ChatMessageEvent(
broadcasterUserId: null == broadcasterUserId ? _self.broadcasterUserId : broadcasterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserId: null == chatterUserId ? _self.chatterUserId : chatterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserLogin: null == chatterUserLogin ? _self.chatterUserLogin : chatterUserLogin // ignore: cast_nullable_to_non_nullable
as String,chatterUserName: null == chatterUserName ? _self.chatterUserName : chatterUserName // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessageText,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<ChatMessageBadge>,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as ChatMessageReply?,receivedAt: freezed == receivedAt ? _self.receivedAt : receivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isFirstMessage: null == isFirstMessage ? _self.isFirstMessage : isFirstMessage // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageTextCopyWith<$Res> get message {
  
  return $ChatMessageTextCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of ChatMessageEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageReplyCopyWith<$Res>? get reply {
    if (_self.reply == null) {
    return null;
  }

  return $ChatMessageReplyCopyWith<$Res>(_self.reply!, (value) {
    return _then(_self.copyWith(reply: value));
  });
}
}


/// @nodoc
mixin _$ChatMessageText {

 String get text; List<ChatMessageFragment> get fragments;
/// Create a copy of ChatMessageText
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageTextCopyWith<ChatMessageText> get copyWith => _$ChatMessageTextCopyWithImpl<ChatMessageText>(this as ChatMessageText, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageText&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other.fragments, fragments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(fragments));

@override
String toString() {
  return 'ChatMessageText(text: $text, fragments: $fragments)';
}


}

/// @nodoc
abstract mixin class $ChatMessageTextCopyWith<$Res>  {
  factory $ChatMessageTextCopyWith(ChatMessageText value, $Res Function(ChatMessageText) _then) = _$ChatMessageTextCopyWithImpl;
@useResult
$Res call({
 String text, List<ChatMessageFragment> fragments
});




}
/// @nodoc
class _$ChatMessageTextCopyWithImpl<$Res>
    implements $ChatMessageTextCopyWith<$Res> {
  _$ChatMessageTextCopyWithImpl(this._self, this._then);

  final ChatMessageText _self;
  final $Res Function(ChatMessageText) _then;

/// Create a copy of ChatMessageText
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? fragments = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fragments: null == fragments ? _self.fragments : fragments // ignore: cast_nullable_to_non_nullable
as List<ChatMessageFragment>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageText].
extension ChatMessageTextPatterns on ChatMessageText {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageText value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageText() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageText value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageText():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageText value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageText() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  List<ChatMessageFragment> fragments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageText() when $default != null:
return $default(_that.text,_that.fragments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  List<ChatMessageFragment> fragments)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageText():
return $default(_that.text,_that.fragments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  List<ChatMessageFragment> fragments)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageText() when $default != null:
return $default(_that.text,_that.fragments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _ChatMessageText implements ChatMessageText {
  const _ChatMessageText({required this.text, final  List<ChatMessageFragment> fragments = const <ChatMessageFragment>[]}): _fragments = fragments;
  factory _ChatMessageText.fromJson(Map<String, dynamic> json) => _$ChatMessageTextFromJson(json);

@override final  String text;
 final  List<ChatMessageFragment> _fragments;
@override@JsonKey() List<ChatMessageFragment> get fragments {
  if (_fragments is EqualUnmodifiableListView) return _fragments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fragments);
}


/// Create a copy of ChatMessageText
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageTextCopyWith<_ChatMessageText> get copyWith => __$ChatMessageTextCopyWithImpl<_ChatMessageText>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageText&&(identical(other.text, text) || other.text == text)&&const DeepCollectionEquality().equals(other._fragments, _fragments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text,const DeepCollectionEquality().hash(_fragments));

@override
String toString() {
  return 'ChatMessageText(text: $text, fragments: $fragments)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageTextCopyWith<$Res> implements $ChatMessageTextCopyWith<$Res> {
  factory _$ChatMessageTextCopyWith(_ChatMessageText value, $Res Function(_ChatMessageText) _then) = __$ChatMessageTextCopyWithImpl;
@override @useResult
$Res call({
 String text, List<ChatMessageFragment> fragments
});




}
/// @nodoc
class __$ChatMessageTextCopyWithImpl<$Res>
    implements _$ChatMessageTextCopyWith<$Res> {
  __$ChatMessageTextCopyWithImpl(this._self, this._then);

  final _ChatMessageText _self;
  final $Res Function(_ChatMessageText) _then;

/// Create a copy of ChatMessageText
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? fragments = null,}) {
  return _then(_ChatMessageText(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,fragments: null == fragments ? _self._fragments : fragments // ignore: cast_nullable_to_non_nullable
as List<ChatMessageFragment>,
  ));
}


}


/// @nodoc
mixin _$ChatMessageFragment {

 String get type; String get text; ChatFragmentEmote? get emote; ChatFragmentMention? get mention;
/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageFragmentCopyWith<ChatMessageFragment> get copyWith => _$ChatMessageFragmentCopyWithImpl<ChatMessageFragment>(this as ChatMessageFragment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageFragment&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.emote, emote) || other.emote == emote)&&(identical(other.mention, mention) || other.mention == mention));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text,emote,mention);

@override
String toString() {
  return 'ChatMessageFragment(type: $type, text: $text, emote: $emote, mention: $mention)';
}


}

/// @nodoc
abstract mixin class $ChatMessageFragmentCopyWith<$Res>  {
  factory $ChatMessageFragmentCopyWith(ChatMessageFragment value, $Res Function(ChatMessageFragment) _then) = _$ChatMessageFragmentCopyWithImpl;
@useResult
$Res call({
 String type, String text, ChatFragmentEmote? emote, ChatFragmentMention? mention
});


$ChatFragmentEmoteCopyWith<$Res>? get emote;$ChatFragmentMentionCopyWith<$Res>? get mention;

}
/// @nodoc
class _$ChatMessageFragmentCopyWithImpl<$Res>
    implements $ChatMessageFragmentCopyWith<$Res> {
  _$ChatMessageFragmentCopyWithImpl(this._self, this._then);

  final ChatMessageFragment _self;
  final $Res Function(ChatMessageFragment) _then;

/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? text = null,Object? emote = freezed,Object? mention = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,emote: freezed == emote ? _self.emote : emote // ignore: cast_nullable_to_non_nullable
as ChatFragmentEmote?,mention: freezed == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as ChatFragmentMention?,
  ));
}
/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatFragmentEmoteCopyWith<$Res>? get emote {
    if (_self.emote == null) {
    return null;
  }

  return $ChatFragmentEmoteCopyWith<$Res>(_self.emote!, (value) {
    return _then(_self.copyWith(emote: value));
  });
}/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatFragmentMentionCopyWith<$Res>? get mention {
    if (_self.mention == null) {
    return null;
  }

  return $ChatFragmentMentionCopyWith<$Res>(_self.mention!, (value) {
    return _then(_self.copyWith(mention: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatMessageFragment].
extension ChatMessageFragmentPatterns on ChatMessageFragment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageFragment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageFragment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageFragment value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageFragment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageFragment value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageFragment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String text,  ChatFragmentEmote? emote,  ChatFragmentMention? mention)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageFragment() when $default != null:
return $default(_that.type,_that.text,_that.emote,_that.mention);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String text,  ChatFragmentEmote? emote,  ChatFragmentMention? mention)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageFragment():
return $default(_that.type,_that.text,_that.emote,_that.mention);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String text,  ChatFragmentEmote? emote,  ChatFragmentMention? mention)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageFragment() when $default != null:
return $default(_that.type,_that.text,_that.emote,_that.mention);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _ChatMessageFragment implements ChatMessageFragment {
  const _ChatMessageFragment({required this.type, required this.text, this.emote, this.mention});
  factory _ChatMessageFragment.fromJson(Map<String, dynamic> json) => _$ChatMessageFragmentFromJson(json);

@override final  String type;
@override final  String text;
@override final  ChatFragmentEmote? emote;
@override final  ChatFragmentMention? mention;

/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageFragmentCopyWith<_ChatMessageFragment> get copyWith => __$ChatMessageFragmentCopyWithImpl<_ChatMessageFragment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageFragment&&(identical(other.type, type) || other.type == type)&&(identical(other.text, text) || other.text == text)&&(identical(other.emote, emote) || other.emote == emote)&&(identical(other.mention, mention) || other.mention == mention));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,text,emote,mention);

@override
String toString() {
  return 'ChatMessageFragment(type: $type, text: $text, emote: $emote, mention: $mention)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageFragmentCopyWith<$Res> implements $ChatMessageFragmentCopyWith<$Res> {
  factory _$ChatMessageFragmentCopyWith(_ChatMessageFragment value, $Res Function(_ChatMessageFragment) _then) = __$ChatMessageFragmentCopyWithImpl;
@override @useResult
$Res call({
 String type, String text, ChatFragmentEmote? emote, ChatFragmentMention? mention
});


@override $ChatFragmentEmoteCopyWith<$Res>? get emote;@override $ChatFragmentMentionCopyWith<$Res>? get mention;

}
/// @nodoc
class __$ChatMessageFragmentCopyWithImpl<$Res>
    implements _$ChatMessageFragmentCopyWith<$Res> {
  __$ChatMessageFragmentCopyWithImpl(this._self, this._then);

  final _ChatMessageFragment _self;
  final $Res Function(_ChatMessageFragment) _then;

/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? text = null,Object? emote = freezed,Object? mention = freezed,}) {
  return _then(_ChatMessageFragment(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,emote: freezed == emote ? _self.emote : emote // ignore: cast_nullable_to_non_nullable
as ChatFragmentEmote?,mention: freezed == mention ? _self.mention : mention // ignore: cast_nullable_to_non_nullable
as ChatFragmentMention?,
  ));
}

/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatFragmentEmoteCopyWith<$Res>? get emote {
    if (_self.emote == null) {
    return null;
  }

  return $ChatFragmentEmoteCopyWith<$Res>(_self.emote!, (value) {
    return _then(_self.copyWith(emote: value));
  });
}/// Create a copy of ChatMessageFragment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatFragmentMentionCopyWith<$Res>? get mention {
    if (_self.mention == null) {
    return null;
  }

  return $ChatFragmentMentionCopyWith<$Res>(_self.mention!, (value) {
    return _then(_self.copyWith(mention: value));
  });
}
}


/// @nodoc
mixin _$ChatFragmentEmote {

 String get id;
/// Create a copy of ChatFragmentEmote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatFragmentEmoteCopyWith<ChatFragmentEmote> get copyWith => _$ChatFragmentEmoteCopyWithImpl<ChatFragmentEmote>(this as ChatFragmentEmote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatFragmentEmote&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ChatFragmentEmote(id: $id)';
}


}

/// @nodoc
abstract mixin class $ChatFragmentEmoteCopyWith<$Res>  {
  factory $ChatFragmentEmoteCopyWith(ChatFragmentEmote value, $Res Function(ChatFragmentEmote) _then) = _$ChatFragmentEmoteCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ChatFragmentEmoteCopyWithImpl<$Res>
    implements $ChatFragmentEmoteCopyWith<$Res> {
  _$ChatFragmentEmoteCopyWithImpl(this._self, this._then);

  final ChatFragmentEmote _self;
  final $Res Function(ChatFragmentEmote) _then;

/// Create a copy of ChatFragmentEmote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatFragmentEmote].
extension ChatFragmentEmotePatterns on ChatFragmentEmote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatFragmentEmote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatFragmentEmote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatFragmentEmote value)  $default,){
final _that = this;
switch (_that) {
case _ChatFragmentEmote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatFragmentEmote value)?  $default,){
final _that = this;
switch (_that) {
case _ChatFragmentEmote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatFragmentEmote() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id)  $default,) {final _that = this;
switch (_that) {
case _ChatFragmentEmote():
return $default(_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id)?  $default,) {final _that = this;
switch (_that) {
case _ChatFragmentEmote() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _ChatFragmentEmote implements ChatFragmentEmote {
  const _ChatFragmentEmote({required this.id});
  factory _ChatFragmentEmote.fromJson(Map<String, dynamic> json) => _$ChatFragmentEmoteFromJson(json);

@override final  String id;

/// Create a copy of ChatFragmentEmote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatFragmentEmoteCopyWith<_ChatFragmentEmote> get copyWith => __$ChatFragmentEmoteCopyWithImpl<_ChatFragmentEmote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatFragmentEmote&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ChatFragmentEmote(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ChatFragmentEmoteCopyWith<$Res> implements $ChatFragmentEmoteCopyWith<$Res> {
  factory _$ChatFragmentEmoteCopyWith(_ChatFragmentEmote value, $Res Function(_ChatFragmentEmote) _then) = __$ChatFragmentEmoteCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class __$ChatFragmentEmoteCopyWithImpl<$Res>
    implements _$ChatFragmentEmoteCopyWith<$Res> {
  __$ChatFragmentEmoteCopyWithImpl(this._self, this._then);

  final _ChatFragmentEmote _self;
  final $Res Function(_ChatFragmentEmote) _then;

/// Create a copy of ChatFragmentEmote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ChatFragmentEmote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatFragmentMention {

 String get userId; String get userLogin; String get userName;
/// Create a copy of ChatFragmentMention
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatFragmentMentionCopyWith<ChatFragmentMention> get copyWith => _$ChatFragmentMentionCopyWithImpl<ChatFragmentMention>(this as ChatFragmentMention, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatFragmentMention&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userLogin, userLogin) || other.userLogin == userLogin)&&(identical(other.userName, userName) || other.userName == userName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,userLogin,userName);

@override
String toString() {
  return 'ChatFragmentMention(userId: $userId, userLogin: $userLogin, userName: $userName)';
}


}

/// @nodoc
abstract mixin class $ChatFragmentMentionCopyWith<$Res>  {
  factory $ChatFragmentMentionCopyWith(ChatFragmentMention value, $Res Function(ChatFragmentMention) _then) = _$ChatFragmentMentionCopyWithImpl;
@useResult
$Res call({
 String userId, String userLogin, String userName
});




}
/// @nodoc
class _$ChatFragmentMentionCopyWithImpl<$Res>
    implements $ChatFragmentMentionCopyWith<$Res> {
  _$ChatFragmentMentionCopyWithImpl(this._self, this._then);

  final ChatFragmentMention _self;
  final $Res Function(ChatFragmentMention) _then;

/// Create a copy of ChatFragmentMention
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? userLogin = null,Object? userName = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userLogin: null == userLogin ? _self.userLogin : userLogin // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatFragmentMention].
extension ChatFragmentMentionPatterns on ChatFragmentMention {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatFragmentMention value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatFragmentMention() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatFragmentMention value)  $default,){
final _that = this;
switch (_that) {
case _ChatFragmentMention():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatFragmentMention value)?  $default,){
final _that = this;
switch (_that) {
case _ChatFragmentMention() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String userLogin,  String userName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatFragmentMention() when $default != null:
return $default(_that.userId,_that.userLogin,_that.userName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String userLogin,  String userName)  $default,) {final _that = this;
switch (_that) {
case _ChatFragmentMention():
return $default(_that.userId,_that.userLogin,_that.userName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String userLogin,  String userName)?  $default,) {final _that = this;
switch (_that) {
case _ChatFragmentMention() when $default != null:
return $default(_that.userId,_that.userLogin,_that.userName);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatFragmentMention implements ChatFragmentMention {
  const _ChatFragmentMention({required this.userId, required this.userLogin, required this.userName});
  factory _ChatFragmentMention.fromJson(Map<String, dynamic> json) => _$ChatFragmentMentionFromJson(json);

@override final  String userId;
@override final  String userLogin;
@override final  String userName;

/// Create a copy of ChatFragmentMention
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatFragmentMentionCopyWith<_ChatFragmentMention> get copyWith => __$ChatFragmentMentionCopyWithImpl<_ChatFragmentMention>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatFragmentMention&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userLogin, userLogin) || other.userLogin == userLogin)&&(identical(other.userName, userName) || other.userName == userName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,userLogin,userName);

@override
String toString() {
  return 'ChatFragmentMention(userId: $userId, userLogin: $userLogin, userName: $userName)';
}


}

/// @nodoc
abstract mixin class _$ChatFragmentMentionCopyWith<$Res> implements $ChatFragmentMentionCopyWith<$Res> {
  factory _$ChatFragmentMentionCopyWith(_ChatFragmentMention value, $Res Function(_ChatFragmentMention) _then) = __$ChatFragmentMentionCopyWithImpl;
@override @useResult
$Res call({
 String userId, String userLogin, String userName
});




}
/// @nodoc
class __$ChatFragmentMentionCopyWithImpl<$Res>
    implements _$ChatFragmentMentionCopyWith<$Res> {
  __$ChatFragmentMentionCopyWithImpl(this._self, this._then);

  final _ChatFragmentMention _self;
  final $Res Function(_ChatFragmentMention) _then;

/// Create a copy of ChatFragmentMention
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? userLogin = null,Object? userName = null,}) {
  return _then(_ChatFragmentMention(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userLogin: null == userLogin ? _self.userLogin : userLogin // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatMessageReply {

 String get parentMessageId; String get parentMessageBody; String get parentUserId; String get parentUserName; String get parentUserLogin; String get threadMessageId; String get threadUserId; String get threadUserName; String get threadUserLogin;
/// Create a copy of ChatMessageReply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageReplyCopyWith<ChatMessageReply> get copyWith => _$ChatMessageReplyCopyWithImpl<ChatMessageReply>(this as ChatMessageReply, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageReply&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&(identical(other.parentMessageBody, parentMessageBody) || other.parentMessageBody == parentMessageBody)&&(identical(other.parentUserId, parentUserId) || other.parentUserId == parentUserId)&&(identical(other.parentUserName, parentUserName) || other.parentUserName == parentUserName)&&(identical(other.parentUserLogin, parentUserLogin) || other.parentUserLogin == parentUserLogin)&&(identical(other.threadMessageId, threadMessageId) || other.threadMessageId == threadMessageId)&&(identical(other.threadUserId, threadUserId) || other.threadUserId == threadUserId)&&(identical(other.threadUserName, threadUserName) || other.threadUserName == threadUserName)&&(identical(other.threadUserLogin, threadUserLogin) || other.threadUserLogin == threadUserLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,parentMessageId,parentMessageBody,parentUserId,parentUserName,parentUserLogin,threadMessageId,threadUserId,threadUserName,threadUserLogin);

@override
String toString() {
  return 'ChatMessageReply(parentMessageId: $parentMessageId, parentMessageBody: $parentMessageBody, parentUserId: $parentUserId, parentUserName: $parentUserName, parentUserLogin: $parentUserLogin, threadMessageId: $threadMessageId, threadUserId: $threadUserId, threadUserName: $threadUserName, threadUserLogin: $threadUserLogin)';
}


}

/// @nodoc
abstract mixin class $ChatMessageReplyCopyWith<$Res>  {
  factory $ChatMessageReplyCopyWith(ChatMessageReply value, $Res Function(ChatMessageReply) _then) = _$ChatMessageReplyCopyWithImpl;
@useResult
$Res call({
 String parentMessageId, String parentMessageBody, String parentUserId, String parentUserName, String parentUserLogin, String threadMessageId, String threadUserId, String threadUserName, String threadUserLogin
});




}
/// @nodoc
class _$ChatMessageReplyCopyWithImpl<$Res>
    implements $ChatMessageReplyCopyWith<$Res> {
  _$ChatMessageReplyCopyWithImpl(this._self, this._then);

  final ChatMessageReply _self;
  final $Res Function(ChatMessageReply) _then;

/// Create a copy of ChatMessageReply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? parentMessageId = null,Object? parentMessageBody = null,Object? parentUserId = null,Object? parentUserName = null,Object? parentUserLogin = null,Object? threadMessageId = null,Object? threadUserId = null,Object? threadUserName = null,Object? threadUserLogin = null,}) {
  return _then(_self.copyWith(
parentMessageId: null == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String,parentMessageBody: null == parentMessageBody ? _self.parentMessageBody : parentMessageBody // ignore: cast_nullable_to_non_nullable
as String,parentUserId: null == parentUserId ? _self.parentUserId : parentUserId // ignore: cast_nullable_to_non_nullable
as String,parentUserName: null == parentUserName ? _self.parentUserName : parentUserName // ignore: cast_nullable_to_non_nullable
as String,parentUserLogin: null == parentUserLogin ? _self.parentUserLogin : parentUserLogin // ignore: cast_nullable_to_non_nullable
as String,threadMessageId: null == threadMessageId ? _self.threadMessageId : threadMessageId // ignore: cast_nullable_to_non_nullable
as String,threadUserId: null == threadUserId ? _self.threadUserId : threadUserId // ignore: cast_nullable_to_non_nullable
as String,threadUserName: null == threadUserName ? _self.threadUserName : threadUserName // ignore: cast_nullable_to_non_nullable
as String,threadUserLogin: null == threadUserLogin ? _self.threadUserLogin : threadUserLogin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageReply].
extension ChatMessageReplyPatterns on ChatMessageReply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageReply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageReply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageReply value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageReply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageReply value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageReply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String parentMessageId,  String parentMessageBody,  String parentUserId,  String parentUserName,  String parentUserLogin,  String threadMessageId,  String threadUserId,  String threadUserName,  String threadUserLogin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageReply() when $default != null:
return $default(_that.parentMessageId,_that.parentMessageBody,_that.parentUserId,_that.parentUserName,_that.parentUserLogin,_that.threadMessageId,_that.threadUserId,_that.threadUserName,_that.threadUserLogin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String parentMessageId,  String parentMessageBody,  String parentUserId,  String parentUserName,  String parentUserLogin,  String threadMessageId,  String threadUserId,  String threadUserName,  String threadUserLogin)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageReply():
return $default(_that.parentMessageId,_that.parentMessageBody,_that.parentUserId,_that.parentUserName,_that.parentUserLogin,_that.threadMessageId,_that.threadUserId,_that.threadUserName,_that.threadUserLogin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String parentMessageId,  String parentMessageBody,  String parentUserId,  String parentUserName,  String parentUserLogin,  String threadMessageId,  String threadUserId,  String threadUserName,  String threadUserLogin)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageReply() when $default != null:
return $default(_that.parentMessageId,_that.parentMessageBody,_that.parentUserId,_that.parentUserName,_that.parentUserLogin,_that.threadMessageId,_that.threadUserId,_that.threadUserName,_that.threadUserLogin);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatMessageReply implements ChatMessageReply {
  const _ChatMessageReply({required this.parentMessageId, required this.parentMessageBody, required this.parentUserId, required this.parentUserName, required this.parentUserLogin, required this.threadMessageId, required this.threadUserId, required this.threadUserName, required this.threadUserLogin});
  factory _ChatMessageReply.fromJson(Map<String, dynamic> json) => _$ChatMessageReplyFromJson(json);

@override final  String parentMessageId;
@override final  String parentMessageBody;
@override final  String parentUserId;
@override final  String parentUserName;
@override final  String parentUserLogin;
@override final  String threadMessageId;
@override final  String threadUserId;
@override final  String threadUserName;
@override final  String threadUserLogin;

/// Create a copy of ChatMessageReply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageReplyCopyWith<_ChatMessageReply> get copyWith => __$ChatMessageReplyCopyWithImpl<_ChatMessageReply>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageReply&&(identical(other.parentMessageId, parentMessageId) || other.parentMessageId == parentMessageId)&&(identical(other.parentMessageBody, parentMessageBody) || other.parentMessageBody == parentMessageBody)&&(identical(other.parentUserId, parentUserId) || other.parentUserId == parentUserId)&&(identical(other.parentUserName, parentUserName) || other.parentUserName == parentUserName)&&(identical(other.parentUserLogin, parentUserLogin) || other.parentUserLogin == parentUserLogin)&&(identical(other.threadMessageId, threadMessageId) || other.threadMessageId == threadMessageId)&&(identical(other.threadUserId, threadUserId) || other.threadUserId == threadUserId)&&(identical(other.threadUserName, threadUserName) || other.threadUserName == threadUserName)&&(identical(other.threadUserLogin, threadUserLogin) || other.threadUserLogin == threadUserLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,parentMessageId,parentMessageBody,parentUserId,parentUserName,parentUserLogin,threadMessageId,threadUserId,threadUserName,threadUserLogin);

@override
String toString() {
  return 'ChatMessageReply(parentMessageId: $parentMessageId, parentMessageBody: $parentMessageBody, parentUserId: $parentUserId, parentUserName: $parentUserName, parentUserLogin: $parentUserLogin, threadMessageId: $threadMessageId, threadUserId: $threadUserId, threadUserName: $threadUserName, threadUserLogin: $threadUserLogin)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageReplyCopyWith<$Res> implements $ChatMessageReplyCopyWith<$Res> {
  factory _$ChatMessageReplyCopyWith(_ChatMessageReply value, $Res Function(_ChatMessageReply) _then) = __$ChatMessageReplyCopyWithImpl;
@override @useResult
$Res call({
 String parentMessageId, String parentMessageBody, String parentUserId, String parentUserName, String parentUserLogin, String threadMessageId, String threadUserId, String threadUserName, String threadUserLogin
});




}
/// @nodoc
class __$ChatMessageReplyCopyWithImpl<$Res>
    implements _$ChatMessageReplyCopyWith<$Res> {
  __$ChatMessageReplyCopyWithImpl(this._self, this._then);

  final _ChatMessageReply _self;
  final $Res Function(_ChatMessageReply) _then;

/// Create a copy of ChatMessageReply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? parentMessageId = null,Object? parentMessageBody = null,Object? parentUserId = null,Object? parentUserName = null,Object? parentUserLogin = null,Object? threadMessageId = null,Object? threadUserId = null,Object? threadUserName = null,Object? threadUserLogin = null,}) {
  return _then(_ChatMessageReply(
parentMessageId: null == parentMessageId ? _self.parentMessageId : parentMessageId // ignore: cast_nullable_to_non_nullable
as String,parentMessageBody: null == parentMessageBody ? _self.parentMessageBody : parentMessageBody // ignore: cast_nullable_to_non_nullable
as String,parentUserId: null == parentUserId ? _self.parentUserId : parentUserId // ignore: cast_nullable_to_non_nullable
as String,parentUserName: null == parentUserName ? _self.parentUserName : parentUserName // ignore: cast_nullable_to_non_nullable
as String,parentUserLogin: null == parentUserLogin ? _self.parentUserLogin : parentUserLogin // ignore: cast_nullable_to_non_nullable
as String,threadMessageId: null == threadMessageId ? _self.threadMessageId : threadMessageId // ignore: cast_nullable_to_non_nullable
as String,threadUserId: null == threadUserId ? _self.threadUserId : threadUserId // ignore: cast_nullable_to_non_nullable
as String,threadUserName: null == threadUserName ? _self.threadUserName : threadUserName // ignore: cast_nullable_to_non_nullable
as String,threadUserLogin: null == threadUserLogin ? _self.threadUserLogin : threadUserLogin // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatMessageBadge {

 String get setId; String get id; String get info;
/// Create a copy of ChatMessageBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageBadgeCopyWith<ChatMessageBadge> get copyWith => _$ChatMessageBadgeCopyWithImpl<ChatMessageBadge>(this as ChatMessageBadge, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageBadge&&(identical(other.setId, setId) || other.setId == setId)&&(identical(other.id, id) || other.id == id)&&(identical(other.info, info) || other.info == info));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setId,id,info);

@override
String toString() {
  return 'ChatMessageBadge(setId: $setId, id: $id, info: $info)';
}


}

/// @nodoc
abstract mixin class $ChatMessageBadgeCopyWith<$Res>  {
  factory $ChatMessageBadgeCopyWith(ChatMessageBadge value, $Res Function(ChatMessageBadge) _then) = _$ChatMessageBadgeCopyWithImpl;
@useResult
$Res call({
 String setId, String id, String info
});




}
/// @nodoc
class _$ChatMessageBadgeCopyWithImpl<$Res>
    implements $ChatMessageBadgeCopyWith<$Res> {
  _$ChatMessageBadgeCopyWithImpl(this._self, this._then);

  final ChatMessageBadge _self;
  final $Res Function(ChatMessageBadge) _then;

/// Create a copy of ChatMessageBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? setId = null,Object? id = null,Object? info = null,}) {
  return _then(_self.copyWith(
setId: null == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageBadge].
extension ChatMessageBadgePatterns on ChatMessageBadge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageBadge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageBadge value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageBadge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageBadge value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageBadge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String setId,  String id,  String info)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageBadge() when $default != null:
return $default(_that.setId,_that.id,_that.info);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String setId,  String id,  String info)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageBadge():
return $default(_that.setId,_that.id,_that.info);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String setId,  String id,  String info)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageBadge() when $default != null:
return $default(_that.setId,_that.id,_that.info);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatMessageBadge implements ChatMessageBadge {
  const _ChatMessageBadge({required this.setId, required this.id, this.info = ''});
  factory _ChatMessageBadge.fromJson(Map<String, dynamic> json) => _$ChatMessageBadgeFromJson(json);

@override final  String setId;
@override final  String id;
@override@JsonKey() final  String info;

/// Create a copy of ChatMessageBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageBadgeCopyWith<_ChatMessageBadge> get copyWith => __$ChatMessageBadgeCopyWithImpl<_ChatMessageBadge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageBadge&&(identical(other.setId, setId) || other.setId == setId)&&(identical(other.id, id) || other.id == id)&&(identical(other.info, info) || other.info == info));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setId,id,info);

@override
String toString() {
  return 'ChatMessageBadge(setId: $setId, id: $id, info: $info)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageBadgeCopyWith<$Res> implements $ChatMessageBadgeCopyWith<$Res> {
  factory _$ChatMessageBadgeCopyWith(_ChatMessageBadge value, $Res Function(_ChatMessageBadge) _then) = __$ChatMessageBadgeCopyWithImpl;
@override @useResult
$Res call({
 String setId, String id, String info
});




}
/// @nodoc
class __$ChatMessageBadgeCopyWithImpl<$Res>
    implements _$ChatMessageBadgeCopyWith<$Res> {
  __$ChatMessageBadgeCopyWithImpl(this._self, this._then);

  final _ChatMessageBadge _self;
  final $Res Function(_ChatMessageBadge) _then;

/// Create a copy of ChatMessageBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? setId = null,Object? id = null,Object? info = null,}) {
  return _then(_ChatMessageBadge(
setId: null == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,info: null == info ? _self.info : info // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
