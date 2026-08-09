// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_chat_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatNotificationEvent {

 String get broadcasterUserId; String get chatterUserId; String get chatterUserLogin; String get chatterUserName; String get messageId; String get systemMessage; String get noticeType; String? get color; List<ChatMessageBadge> get badges;/// Optional message the chatter attached (often empty — the typed
/// chat line may arrive separately as `channel.chat.message`).
 ChatMessageText? get message; ChatNotificationWatchStreak? get watchStreak;
/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationEventCopyWith<ChatNotificationEvent> get copyWith => _$ChatNotificationEventCopyWithImpl<ChatNotificationEvent>(this as ChatNotificationEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId)&&(identical(other.chatterUserId, chatterUserId) || other.chatterUserId == chatterUserId)&&(identical(other.chatterUserLogin, chatterUserLogin) || other.chatterUserLogin == chatterUserLogin)&&(identical(other.chatterUserName, chatterUserName) || other.chatterUserName == chatterUserName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.systemMessage, systemMessage) || other.systemMessage == systemMessage)&&(identical(other.noticeType, noticeType) || other.noticeType == noticeType)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.badges, badges)&&(identical(other.message, message) || other.message == message)&&(identical(other.watchStreak, watchStreak) || other.watchStreak == watchStreak));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId,chatterUserId,chatterUserLogin,chatterUserName,messageId,systemMessage,noticeType,color,const DeepCollectionEquality().hash(badges),message,watchStreak);

@override
String toString() {
  return 'ChatNotificationEvent(broadcasterUserId: $broadcasterUserId, chatterUserId: $chatterUserId, chatterUserLogin: $chatterUserLogin, chatterUserName: $chatterUserName, messageId: $messageId, systemMessage: $systemMessage, noticeType: $noticeType, color: $color, badges: $badges, message: $message, watchStreak: $watchStreak)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationEventCopyWith<$Res>  {
  factory $ChatNotificationEventCopyWith(ChatNotificationEvent value, $Res Function(ChatNotificationEvent) _then) = _$ChatNotificationEventCopyWithImpl;
@useResult
$Res call({
 String broadcasterUserId, String chatterUserId, String chatterUserLogin, String chatterUserName, String messageId, String systemMessage, String noticeType, String? color, List<ChatMessageBadge> badges, ChatMessageText? message, ChatNotificationWatchStreak? watchStreak
});


$ChatMessageTextCopyWith<$Res>? get message;$ChatNotificationWatchStreakCopyWith<$Res>? get watchStreak;

}
/// @nodoc
class _$ChatNotificationEventCopyWithImpl<$Res>
    implements $ChatNotificationEventCopyWith<$Res> {
  _$ChatNotificationEventCopyWithImpl(this._self, this._then);

  final ChatNotificationEvent _self;
  final $Res Function(ChatNotificationEvent) _then;

/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? broadcasterUserId = null,Object? chatterUserId = null,Object? chatterUserLogin = null,Object? chatterUserName = null,Object? messageId = null,Object? systemMessage = null,Object? noticeType = null,Object? color = freezed,Object? badges = null,Object? message = freezed,Object? watchStreak = freezed,}) {
  return _then(_self.copyWith(
broadcasterUserId: null == broadcasterUserId ? _self.broadcasterUserId : broadcasterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserId: null == chatterUserId ? _self.chatterUserId : chatterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserLogin: null == chatterUserLogin ? _self.chatterUserLogin : chatterUserLogin // ignore: cast_nullable_to_non_nullable
as String,chatterUserName: null == chatterUserName ? _self.chatterUserName : chatterUserName // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,systemMessage: null == systemMessage ? _self.systemMessage : systemMessage // ignore: cast_nullable_to_non_nullable
as String,noticeType: null == noticeType ? _self.noticeType : noticeType // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<ChatMessageBadge>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessageText?,watchStreak: freezed == watchStreak ? _self.watchStreak : watchStreak // ignore: cast_nullable_to_non_nullable
as ChatNotificationWatchStreak?,
  ));
}
/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageTextCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $ChatMessageTextCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationWatchStreakCopyWith<$Res>? get watchStreak {
    if (_self.watchStreak == null) {
    return null;
  }

  return $ChatNotificationWatchStreakCopyWith<$Res>(_self.watchStreak!, (value) {
    return _then(_self.copyWith(watchStreak: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatNotificationEvent].
extension ChatNotificationEventPatterns on ChatNotificationEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  String systemMessage,  String noticeType,  String? color,  List<ChatMessageBadge> badges,  ChatMessageText? message,  ChatNotificationWatchStreak? watchStreak)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationEvent() when $default != null:
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.systemMessage,_that.noticeType,_that.color,_that.badges,_that.message,_that.watchStreak);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  String systemMessage,  String noticeType,  String? color,  List<ChatMessageBadge> badges,  ChatMessageText? message,  ChatNotificationWatchStreak? watchStreak)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationEvent():
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.systemMessage,_that.noticeType,_that.color,_that.badges,_that.message,_that.watchStreak);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  String systemMessage,  String noticeType,  String? color,  List<ChatMessageBadge> badges,  ChatMessageText? message,  ChatNotificationWatchStreak? watchStreak)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationEvent() when $default != null:
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.systemMessage,_that.noticeType,_that.color,_that.badges,_that.message,_that.watchStreak);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationEvent implements ChatNotificationEvent {
  const _ChatNotificationEvent({required this.broadcasterUserId, required this.chatterUserId, required this.chatterUserLogin, required this.chatterUserName, required this.messageId, required this.systemMessage, required this.noticeType, this.color, final  List<ChatMessageBadge> badges = const <ChatMessageBadge>[], this.message, this.watchStreak}): _badges = badges;
  factory _ChatNotificationEvent.fromJson(Map<String, dynamic> json) => _$ChatNotificationEventFromJson(json);

@override final  String broadcasterUserId;
@override final  String chatterUserId;
@override final  String chatterUserLogin;
@override final  String chatterUserName;
@override final  String messageId;
@override final  String systemMessage;
@override final  String noticeType;
@override final  String? color;
 final  List<ChatMessageBadge> _badges;
@override@JsonKey() List<ChatMessageBadge> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}

/// Optional message the chatter attached (often empty — the typed
/// chat line may arrive separately as `channel.chat.message`).
@override final  ChatMessageText? message;
@override final  ChatNotificationWatchStreak? watchStreak;

/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationEventCopyWith<_ChatNotificationEvent> get copyWith => __$ChatNotificationEventCopyWithImpl<_ChatNotificationEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId)&&(identical(other.chatterUserId, chatterUserId) || other.chatterUserId == chatterUserId)&&(identical(other.chatterUserLogin, chatterUserLogin) || other.chatterUserLogin == chatterUserLogin)&&(identical(other.chatterUserName, chatterUserName) || other.chatterUserName == chatterUserName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.systemMessage, systemMessage) || other.systemMessage == systemMessage)&&(identical(other.noticeType, noticeType) || other.noticeType == noticeType)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other._badges, _badges)&&(identical(other.message, message) || other.message == message)&&(identical(other.watchStreak, watchStreak) || other.watchStreak == watchStreak));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId,chatterUserId,chatterUserLogin,chatterUserName,messageId,systemMessage,noticeType,color,const DeepCollectionEquality().hash(_badges),message,watchStreak);

@override
String toString() {
  return 'ChatNotificationEvent(broadcasterUserId: $broadcasterUserId, chatterUserId: $chatterUserId, chatterUserLogin: $chatterUserLogin, chatterUserName: $chatterUserName, messageId: $messageId, systemMessage: $systemMessage, noticeType: $noticeType, color: $color, badges: $badges, message: $message, watchStreak: $watchStreak)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationEventCopyWith<$Res> implements $ChatNotificationEventCopyWith<$Res> {
  factory _$ChatNotificationEventCopyWith(_ChatNotificationEvent value, $Res Function(_ChatNotificationEvent) _then) = __$ChatNotificationEventCopyWithImpl;
@override @useResult
$Res call({
 String broadcasterUserId, String chatterUserId, String chatterUserLogin, String chatterUserName, String messageId, String systemMessage, String noticeType, String? color, List<ChatMessageBadge> badges, ChatMessageText? message, ChatNotificationWatchStreak? watchStreak
});


@override $ChatMessageTextCopyWith<$Res>? get message;@override $ChatNotificationWatchStreakCopyWith<$Res>? get watchStreak;

}
/// @nodoc
class __$ChatNotificationEventCopyWithImpl<$Res>
    implements _$ChatNotificationEventCopyWith<$Res> {
  __$ChatNotificationEventCopyWithImpl(this._self, this._then);

  final _ChatNotificationEvent _self;
  final $Res Function(_ChatNotificationEvent) _then;

/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? broadcasterUserId = null,Object? chatterUserId = null,Object? chatterUserLogin = null,Object? chatterUserName = null,Object? messageId = null,Object? systemMessage = null,Object? noticeType = null,Object? color = freezed,Object? badges = null,Object? message = freezed,Object? watchStreak = freezed,}) {
  return _then(_ChatNotificationEvent(
broadcasterUserId: null == broadcasterUserId ? _self.broadcasterUserId : broadcasterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserId: null == chatterUserId ? _self.chatterUserId : chatterUserId // ignore: cast_nullable_to_non_nullable
as String,chatterUserLogin: null == chatterUserLogin ? _self.chatterUserLogin : chatterUserLogin // ignore: cast_nullable_to_non_nullable
as String,chatterUserName: null == chatterUserName ? _self.chatterUserName : chatterUserName // ignore: cast_nullable_to_non_nullable
as String,messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,systemMessage: null == systemMessage ? _self.systemMessage : systemMessage // ignore: cast_nullable_to_non_nullable
as String,noticeType: null == noticeType ? _self.noticeType : noticeType // ignore: cast_nullable_to_non_nullable
as String,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<ChatMessageBadge>,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessageText?,watchStreak: freezed == watchStreak ? _self.watchStreak : watchStreak // ignore: cast_nullable_to_non_nullable
as ChatNotificationWatchStreak?,
  ));
}

/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageTextCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $ChatMessageTextCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationWatchStreakCopyWith<$Res>? get watchStreak {
    if (_self.watchStreak == null) {
    return null;
  }

  return $ChatNotificationWatchStreakCopyWith<$Res>(_self.watchStreak!, (value) {
    return _then(_self.copyWith(watchStreak: value));
  });
}
}


/// @nodoc
mixin _$ChatNotificationWatchStreak {

 int get streakCount; int get channelPointsAwarded;
/// Create a copy of ChatNotificationWatchStreak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationWatchStreakCopyWith<ChatNotificationWatchStreak> get copyWith => _$ChatNotificationWatchStreakCopyWithImpl<ChatNotificationWatchStreak>(this as ChatNotificationWatchStreak, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationWatchStreak&&(identical(other.streakCount, streakCount) || other.streakCount == streakCount)&&(identical(other.channelPointsAwarded, channelPointsAwarded) || other.channelPointsAwarded == channelPointsAwarded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streakCount,channelPointsAwarded);

@override
String toString() {
  return 'ChatNotificationWatchStreak(streakCount: $streakCount, channelPointsAwarded: $channelPointsAwarded)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationWatchStreakCopyWith<$Res>  {
  factory $ChatNotificationWatchStreakCopyWith(ChatNotificationWatchStreak value, $Res Function(ChatNotificationWatchStreak) _then) = _$ChatNotificationWatchStreakCopyWithImpl;
@useResult
$Res call({
 int streakCount, int channelPointsAwarded
});




}
/// @nodoc
class _$ChatNotificationWatchStreakCopyWithImpl<$Res>
    implements $ChatNotificationWatchStreakCopyWith<$Res> {
  _$ChatNotificationWatchStreakCopyWithImpl(this._self, this._then);

  final ChatNotificationWatchStreak _self;
  final $Res Function(ChatNotificationWatchStreak) _then;

/// Create a copy of ChatNotificationWatchStreak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? streakCount = null,Object? channelPointsAwarded = null,}) {
  return _then(_self.copyWith(
streakCount: null == streakCount ? _self.streakCount : streakCount // ignore: cast_nullable_to_non_nullable
as int,channelPointsAwarded: null == channelPointsAwarded ? _self.channelPointsAwarded : channelPointsAwarded // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNotificationWatchStreak].
extension ChatNotificationWatchStreakPatterns on ChatNotificationWatchStreak {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationWatchStreak value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationWatchStreak() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationWatchStreak value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationWatchStreak():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationWatchStreak value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationWatchStreak() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int streakCount,  int channelPointsAwarded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationWatchStreak() when $default != null:
return $default(_that.streakCount,_that.channelPointsAwarded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int streakCount,  int channelPointsAwarded)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationWatchStreak():
return $default(_that.streakCount,_that.channelPointsAwarded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int streakCount,  int channelPointsAwarded)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationWatchStreak() when $default != null:
return $default(_that.streakCount,_that.channelPointsAwarded);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationWatchStreak implements ChatNotificationWatchStreak {
  const _ChatNotificationWatchStreak({required this.streakCount, this.channelPointsAwarded = 0});
  factory _ChatNotificationWatchStreak.fromJson(Map<String, dynamic> json) => _$ChatNotificationWatchStreakFromJson(json);

@override final  int streakCount;
@override@JsonKey() final  int channelPointsAwarded;

/// Create a copy of ChatNotificationWatchStreak
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationWatchStreakCopyWith<_ChatNotificationWatchStreak> get copyWith => __$ChatNotificationWatchStreakCopyWithImpl<_ChatNotificationWatchStreak>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationWatchStreak&&(identical(other.streakCount, streakCount) || other.streakCount == streakCount)&&(identical(other.channelPointsAwarded, channelPointsAwarded) || other.channelPointsAwarded == channelPointsAwarded));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,streakCount,channelPointsAwarded);

@override
String toString() {
  return 'ChatNotificationWatchStreak(streakCount: $streakCount, channelPointsAwarded: $channelPointsAwarded)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationWatchStreakCopyWith<$Res> implements $ChatNotificationWatchStreakCopyWith<$Res> {
  factory _$ChatNotificationWatchStreakCopyWith(_ChatNotificationWatchStreak value, $Res Function(_ChatNotificationWatchStreak) _then) = __$ChatNotificationWatchStreakCopyWithImpl;
@override @useResult
$Res call({
 int streakCount, int channelPointsAwarded
});




}
/// @nodoc
class __$ChatNotificationWatchStreakCopyWithImpl<$Res>
    implements _$ChatNotificationWatchStreakCopyWith<$Res> {
  __$ChatNotificationWatchStreakCopyWithImpl(this._self, this._then);

  final _ChatNotificationWatchStreak _self;
  final $Res Function(_ChatNotificationWatchStreak) _then;

/// Create a copy of ChatNotificationWatchStreak
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? streakCount = null,Object? channelPointsAwarded = null,}) {
  return _then(_ChatNotificationWatchStreak(
streakCount: null == streakCount ? _self.streakCount : streakCount // ignore: cast_nullable_to_non_nullable
as int,channelPointsAwarded: null == channelPointsAwarded ? _self.channelPointsAwarded : channelPointsAwarded // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
