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

 String get broadcasterUserId; String get chatterUserId; String get chatterUserLogin; String get chatterUserName; String get messageId; String get systemMessage; String get noticeType;/// Chatter name color (hex), not the announcement highlight.
 String? get color; List<ChatMessageBadge> get badges;/// Optional message the chatter attached (often empty — the typed
/// chat line may arrive separately as `channel.chat.message`).
 ChatMessageText? get message;/// Present when [noticeType] is `announcement` — Helix highlight
/// (`blue` / `green` / `orange` / `purple` / `primary`).
 ChatNotificationAnnouncement? get announcement; ChatNotificationWatchStreak? get watchStreak; ChatNotificationRaid? get raid; ChatNotificationSubGift? get subGift; ChatNotificationCommunitySubGift? get communitySubGift;@JsonKey(name: 'bits_badge_tier') ChatNotificationBitsBadgeTier? get bitsBadgeTier; ChatNotificationCharityDonation? get charityDonation;
/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationEventCopyWith<ChatNotificationEvent> get copyWith => _$ChatNotificationEventCopyWithImpl<ChatNotificationEvent>(this as ChatNotificationEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId)&&(identical(other.chatterUserId, chatterUserId) || other.chatterUserId == chatterUserId)&&(identical(other.chatterUserLogin, chatterUserLogin) || other.chatterUserLogin == chatterUserLogin)&&(identical(other.chatterUserName, chatterUserName) || other.chatterUserName == chatterUserName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.systemMessage, systemMessage) || other.systemMessage == systemMessage)&&(identical(other.noticeType, noticeType) || other.noticeType == noticeType)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other.badges, badges)&&(identical(other.message, message) || other.message == message)&&(identical(other.announcement, announcement) || other.announcement == announcement)&&(identical(other.watchStreak, watchStreak) || other.watchStreak == watchStreak)&&(identical(other.raid, raid) || other.raid == raid)&&(identical(other.subGift, subGift) || other.subGift == subGift)&&(identical(other.communitySubGift, communitySubGift) || other.communitySubGift == communitySubGift)&&(identical(other.bitsBadgeTier, bitsBadgeTier) || other.bitsBadgeTier == bitsBadgeTier)&&(identical(other.charityDonation, charityDonation) || other.charityDonation == charityDonation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId,chatterUserId,chatterUserLogin,chatterUserName,messageId,systemMessage,noticeType,color,const DeepCollectionEquality().hash(badges),message,announcement,watchStreak,raid,subGift,communitySubGift,bitsBadgeTier,charityDonation);

@override
String toString() {
  return 'ChatNotificationEvent(broadcasterUserId: $broadcasterUserId, chatterUserId: $chatterUserId, chatterUserLogin: $chatterUserLogin, chatterUserName: $chatterUserName, messageId: $messageId, systemMessage: $systemMessage, noticeType: $noticeType, color: $color, badges: $badges, message: $message, announcement: $announcement, watchStreak: $watchStreak, raid: $raid, subGift: $subGift, communitySubGift: $communitySubGift, bitsBadgeTier: $bitsBadgeTier, charityDonation: $charityDonation)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationEventCopyWith<$Res>  {
  factory $ChatNotificationEventCopyWith(ChatNotificationEvent value, $Res Function(ChatNotificationEvent) _then) = _$ChatNotificationEventCopyWithImpl;
@useResult
$Res call({
 String broadcasterUserId, String chatterUserId, String chatterUserLogin, String chatterUserName, String messageId, String systemMessage, String noticeType, String? color, List<ChatMessageBadge> badges, ChatMessageText? message, ChatNotificationAnnouncement? announcement, ChatNotificationWatchStreak? watchStreak, ChatNotificationRaid? raid, ChatNotificationSubGift? subGift, ChatNotificationCommunitySubGift? communitySubGift,@JsonKey(name: 'bits_badge_tier') ChatNotificationBitsBadgeTier? bitsBadgeTier, ChatNotificationCharityDonation? charityDonation
});


$ChatMessageTextCopyWith<$Res>? get message;$ChatNotificationAnnouncementCopyWith<$Res>? get announcement;$ChatNotificationWatchStreakCopyWith<$Res>? get watchStreak;$ChatNotificationRaidCopyWith<$Res>? get raid;$ChatNotificationSubGiftCopyWith<$Res>? get subGift;$ChatNotificationCommunitySubGiftCopyWith<$Res>? get communitySubGift;$ChatNotificationBitsBadgeTierCopyWith<$Res>? get bitsBadgeTier;$ChatNotificationCharityDonationCopyWith<$Res>? get charityDonation;

}
/// @nodoc
class _$ChatNotificationEventCopyWithImpl<$Res>
    implements $ChatNotificationEventCopyWith<$Res> {
  _$ChatNotificationEventCopyWithImpl(this._self, this._then);

  final ChatNotificationEvent _self;
  final $Res Function(ChatNotificationEvent) _then;

/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? broadcasterUserId = null,Object? chatterUserId = null,Object? chatterUserLogin = null,Object? chatterUserName = null,Object? messageId = null,Object? systemMessage = null,Object? noticeType = null,Object? color = freezed,Object? badges = null,Object? message = freezed,Object? announcement = freezed,Object? watchStreak = freezed,Object? raid = freezed,Object? subGift = freezed,Object? communitySubGift = freezed,Object? bitsBadgeTier = freezed,Object? charityDonation = freezed,}) {
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
as ChatMessageText?,announcement: freezed == announcement ? _self.announcement : announcement // ignore: cast_nullable_to_non_nullable
as ChatNotificationAnnouncement?,watchStreak: freezed == watchStreak ? _self.watchStreak : watchStreak // ignore: cast_nullable_to_non_nullable
as ChatNotificationWatchStreak?,raid: freezed == raid ? _self.raid : raid // ignore: cast_nullable_to_non_nullable
as ChatNotificationRaid?,subGift: freezed == subGift ? _self.subGift : subGift // ignore: cast_nullable_to_non_nullable
as ChatNotificationSubGift?,communitySubGift: freezed == communitySubGift ? _self.communitySubGift : communitySubGift // ignore: cast_nullable_to_non_nullable
as ChatNotificationCommunitySubGift?,bitsBadgeTier: freezed == bitsBadgeTier ? _self.bitsBadgeTier : bitsBadgeTier // ignore: cast_nullable_to_non_nullable
as ChatNotificationBitsBadgeTier?,charityDonation: freezed == charityDonation ? _self.charityDonation : charityDonation // ignore: cast_nullable_to_non_nullable
as ChatNotificationCharityDonation?,
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
$ChatNotificationAnnouncementCopyWith<$Res>? get announcement {
    if (_self.announcement == null) {
    return null;
  }

  return $ChatNotificationAnnouncementCopyWith<$Res>(_self.announcement!, (value) {
    return _then(_self.copyWith(announcement: value));
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
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationRaidCopyWith<$Res>? get raid {
    if (_self.raid == null) {
    return null;
  }

  return $ChatNotificationRaidCopyWith<$Res>(_self.raid!, (value) {
    return _then(_self.copyWith(raid: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationSubGiftCopyWith<$Res>? get subGift {
    if (_self.subGift == null) {
    return null;
  }

  return $ChatNotificationSubGiftCopyWith<$Res>(_self.subGift!, (value) {
    return _then(_self.copyWith(subGift: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationCommunitySubGiftCopyWith<$Res>? get communitySubGift {
    if (_self.communitySubGift == null) {
    return null;
  }

  return $ChatNotificationCommunitySubGiftCopyWith<$Res>(_self.communitySubGift!, (value) {
    return _then(_self.copyWith(communitySubGift: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationBitsBadgeTierCopyWith<$Res>? get bitsBadgeTier {
    if (_self.bitsBadgeTier == null) {
    return null;
  }

  return $ChatNotificationBitsBadgeTierCopyWith<$Res>(_self.bitsBadgeTier!, (value) {
    return _then(_self.copyWith(bitsBadgeTier: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationCharityDonationCopyWith<$Res>? get charityDonation {
    if (_self.charityDonation == null) {
    return null;
  }

  return $ChatNotificationCharityDonationCopyWith<$Res>(_self.charityDonation!, (value) {
    return _then(_self.copyWith(charityDonation: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  String systemMessage,  String noticeType,  String? color,  List<ChatMessageBadge> badges,  ChatMessageText? message,  ChatNotificationAnnouncement? announcement,  ChatNotificationWatchStreak? watchStreak,  ChatNotificationRaid? raid,  ChatNotificationSubGift? subGift,  ChatNotificationCommunitySubGift? communitySubGift, @JsonKey(name: 'bits_badge_tier')  ChatNotificationBitsBadgeTier? bitsBadgeTier,  ChatNotificationCharityDonation? charityDonation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationEvent() when $default != null:
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.systemMessage,_that.noticeType,_that.color,_that.badges,_that.message,_that.announcement,_that.watchStreak,_that.raid,_that.subGift,_that.communitySubGift,_that.bitsBadgeTier,_that.charityDonation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  String systemMessage,  String noticeType,  String? color,  List<ChatMessageBadge> badges,  ChatMessageText? message,  ChatNotificationAnnouncement? announcement,  ChatNotificationWatchStreak? watchStreak,  ChatNotificationRaid? raid,  ChatNotificationSubGift? subGift,  ChatNotificationCommunitySubGift? communitySubGift, @JsonKey(name: 'bits_badge_tier')  ChatNotificationBitsBadgeTier? bitsBadgeTier,  ChatNotificationCharityDonation? charityDonation)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationEvent():
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.systemMessage,_that.noticeType,_that.color,_that.badges,_that.message,_that.announcement,_that.watchStreak,_that.raid,_that.subGift,_that.communitySubGift,_that.bitsBadgeTier,_that.charityDonation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String broadcasterUserId,  String chatterUserId,  String chatterUserLogin,  String chatterUserName,  String messageId,  String systemMessage,  String noticeType,  String? color,  List<ChatMessageBadge> badges,  ChatMessageText? message,  ChatNotificationAnnouncement? announcement,  ChatNotificationWatchStreak? watchStreak,  ChatNotificationRaid? raid,  ChatNotificationSubGift? subGift,  ChatNotificationCommunitySubGift? communitySubGift, @JsonKey(name: 'bits_badge_tier')  ChatNotificationBitsBadgeTier? bitsBadgeTier,  ChatNotificationCharityDonation? charityDonation)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationEvent() when $default != null:
return $default(_that.broadcasterUserId,_that.chatterUserId,_that.chatterUserLogin,_that.chatterUserName,_that.messageId,_that.systemMessage,_that.noticeType,_that.color,_that.badges,_that.message,_that.announcement,_that.watchStreak,_that.raid,_that.subGift,_that.communitySubGift,_that.bitsBadgeTier,_that.charityDonation);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationEvent implements ChatNotificationEvent {
  const _ChatNotificationEvent({required this.broadcasterUserId, required this.chatterUserId, required this.chatterUserLogin, required this.chatterUserName, required this.messageId, required this.systemMessage, required this.noticeType, this.color, final  List<ChatMessageBadge> badges = const <ChatMessageBadge>[], this.message, this.announcement, this.watchStreak, this.raid, this.subGift, this.communitySubGift, @JsonKey(name: 'bits_badge_tier') this.bitsBadgeTier, this.charityDonation}): _badges = badges;
  factory _ChatNotificationEvent.fromJson(Map<String, dynamic> json) => _$ChatNotificationEventFromJson(json);

@override final  String broadcasterUserId;
@override final  String chatterUserId;
@override final  String chatterUserLogin;
@override final  String chatterUserName;
@override final  String messageId;
@override final  String systemMessage;
@override final  String noticeType;
/// Chatter name color (hex), not the announcement highlight.
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
/// Present when [noticeType] is `announcement` — Helix highlight
/// (`blue` / `green` / `orange` / `purple` / `primary`).
@override final  ChatNotificationAnnouncement? announcement;
@override final  ChatNotificationWatchStreak? watchStreak;
@override final  ChatNotificationRaid? raid;
@override final  ChatNotificationSubGift? subGift;
@override final  ChatNotificationCommunitySubGift? communitySubGift;
@override@JsonKey(name: 'bits_badge_tier') final  ChatNotificationBitsBadgeTier? bitsBadgeTier;
@override final  ChatNotificationCharityDonation? charityDonation;

/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationEventCopyWith<_ChatNotificationEvent> get copyWith => __$ChatNotificationEventCopyWithImpl<_ChatNotificationEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId)&&(identical(other.chatterUserId, chatterUserId) || other.chatterUserId == chatterUserId)&&(identical(other.chatterUserLogin, chatterUserLogin) || other.chatterUserLogin == chatterUserLogin)&&(identical(other.chatterUserName, chatterUserName) || other.chatterUserName == chatterUserName)&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.systemMessage, systemMessage) || other.systemMessage == systemMessage)&&(identical(other.noticeType, noticeType) || other.noticeType == noticeType)&&(identical(other.color, color) || other.color == color)&&const DeepCollectionEquality().equals(other._badges, _badges)&&(identical(other.message, message) || other.message == message)&&(identical(other.announcement, announcement) || other.announcement == announcement)&&(identical(other.watchStreak, watchStreak) || other.watchStreak == watchStreak)&&(identical(other.raid, raid) || other.raid == raid)&&(identical(other.subGift, subGift) || other.subGift == subGift)&&(identical(other.communitySubGift, communitySubGift) || other.communitySubGift == communitySubGift)&&(identical(other.bitsBadgeTier, bitsBadgeTier) || other.bitsBadgeTier == bitsBadgeTier)&&(identical(other.charityDonation, charityDonation) || other.charityDonation == charityDonation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId,chatterUserId,chatterUserLogin,chatterUserName,messageId,systemMessage,noticeType,color,const DeepCollectionEquality().hash(_badges),message,announcement,watchStreak,raid,subGift,communitySubGift,bitsBadgeTier,charityDonation);

@override
String toString() {
  return 'ChatNotificationEvent(broadcasterUserId: $broadcasterUserId, chatterUserId: $chatterUserId, chatterUserLogin: $chatterUserLogin, chatterUserName: $chatterUserName, messageId: $messageId, systemMessage: $systemMessage, noticeType: $noticeType, color: $color, badges: $badges, message: $message, announcement: $announcement, watchStreak: $watchStreak, raid: $raid, subGift: $subGift, communitySubGift: $communitySubGift, bitsBadgeTier: $bitsBadgeTier, charityDonation: $charityDonation)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationEventCopyWith<$Res> implements $ChatNotificationEventCopyWith<$Res> {
  factory _$ChatNotificationEventCopyWith(_ChatNotificationEvent value, $Res Function(_ChatNotificationEvent) _then) = __$ChatNotificationEventCopyWithImpl;
@override @useResult
$Res call({
 String broadcasterUserId, String chatterUserId, String chatterUserLogin, String chatterUserName, String messageId, String systemMessage, String noticeType, String? color, List<ChatMessageBadge> badges, ChatMessageText? message, ChatNotificationAnnouncement? announcement, ChatNotificationWatchStreak? watchStreak, ChatNotificationRaid? raid, ChatNotificationSubGift? subGift, ChatNotificationCommunitySubGift? communitySubGift,@JsonKey(name: 'bits_badge_tier') ChatNotificationBitsBadgeTier? bitsBadgeTier, ChatNotificationCharityDonation? charityDonation
});


@override $ChatMessageTextCopyWith<$Res>? get message;@override $ChatNotificationAnnouncementCopyWith<$Res>? get announcement;@override $ChatNotificationWatchStreakCopyWith<$Res>? get watchStreak;@override $ChatNotificationRaidCopyWith<$Res>? get raid;@override $ChatNotificationSubGiftCopyWith<$Res>? get subGift;@override $ChatNotificationCommunitySubGiftCopyWith<$Res>? get communitySubGift;@override $ChatNotificationBitsBadgeTierCopyWith<$Res>? get bitsBadgeTier;@override $ChatNotificationCharityDonationCopyWith<$Res>? get charityDonation;

}
/// @nodoc
class __$ChatNotificationEventCopyWithImpl<$Res>
    implements _$ChatNotificationEventCopyWith<$Res> {
  __$ChatNotificationEventCopyWithImpl(this._self, this._then);

  final _ChatNotificationEvent _self;
  final $Res Function(_ChatNotificationEvent) _then;

/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? broadcasterUserId = null,Object? chatterUserId = null,Object? chatterUserLogin = null,Object? chatterUserName = null,Object? messageId = null,Object? systemMessage = null,Object? noticeType = null,Object? color = freezed,Object? badges = null,Object? message = freezed,Object? announcement = freezed,Object? watchStreak = freezed,Object? raid = freezed,Object? subGift = freezed,Object? communitySubGift = freezed,Object? bitsBadgeTier = freezed,Object? charityDonation = freezed,}) {
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
as ChatMessageText?,announcement: freezed == announcement ? _self.announcement : announcement // ignore: cast_nullable_to_non_nullable
as ChatNotificationAnnouncement?,watchStreak: freezed == watchStreak ? _self.watchStreak : watchStreak // ignore: cast_nullable_to_non_nullable
as ChatNotificationWatchStreak?,raid: freezed == raid ? _self.raid : raid // ignore: cast_nullable_to_non_nullable
as ChatNotificationRaid?,subGift: freezed == subGift ? _self.subGift : subGift // ignore: cast_nullable_to_non_nullable
as ChatNotificationSubGift?,communitySubGift: freezed == communitySubGift ? _self.communitySubGift : communitySubGift // ignore: cast_nullable_to_non_nullable
as ChatNotificationCommunitySubGift?,bitsBadgeTier: freezed == bitsBadgeTier ? _self.bitsBadgeTier : bitsBadgeTier // ignore: cast_nullable_to_non_nullable
as ChatNotificationBitsBadgeTier?,charityDonation: freezed == charityDonation ? _self.charityDonation : charityDonation // ignore: cast_nullable_to_non_nullable
as ChatNotificationCharityDonation?,
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
$ChatNotificationAnnouncementCopyWith<$Res>? get announcement {
    if (_self.announcement == null) {
    return null;
  }

  return $ChatNotificationAnnouncementCopyWith<$Res>(_self.announcement!, (value) {
    return _then(_self.copyWith(announcement: value));
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
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationRaidCopyWith<$Res>? get raid {
    if (_self.raid == null) {
    return null;
  }

  return $ChatNotificationRaidCopyWith<$Res>(_self.raid!, (value) {
    return _then(_self.copyWith(raid: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationSubGiftCopyWith<$Res>? get subGift {
    if (_self.subGift == null) {
    return null;
  }

  return $ChatNotificationSubGiftCopyWith<$Res>(_self.subGift!, (value) {
    return _then(_self.copyWith(subGift: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationCommunitySubGiftCopyWith<$Res>? get communitySubGift {
    if (_self.communitySubGift == null) {
    return null;
  }

  return $ChatNotificationCommunitySubGiftCopyWith<$Res>(_self.communitySubGift!, (value) {
    return _then(_self.copyWith(communitySubGift: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationBitsBadgeTierCopyWith<$Res>? get bitsBadgeTier {
    if (_self.bitsBadgeTier == null) {
    return null;
  }

  return $ChatNotificationBitsBadgeTierCopyWith<$Res>(_self.bitsBadgeTier!, (value) {
    return _then(_self.copyWith(bitsBadgeTier: value));
  });
}/// Create a copy of ChatNotificationEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationCharityDonationCopyWith<$Res>? get charityDonation {
    if (_self.charityDonation == null) {
    return null;
  }

  return $ChatNotificationCharityDonationCopyWith<$Res>(_self.charityDonation!, (value) {
    return _then(_self.copyWith(charityDonation: value));
  });
}
}


/// @nodoc
mixin _$ChatNotificationAnnouncement {

/// `blue` | `green` | `orange` | `purple` | `primary`.
 String get color;
/// Create a copy of ChatNotificationAnnouncement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationAnnouncementCopyWith<ChatNotificationAnnouncement> get copyWith => _$ChatNotificationAnnouncementCopyWithImpl<ChatNotificationAnnouncement>(this as ChatNotificationAnnouncement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationAnnouncement&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,color);

@override
String toString() {
  return 'ChatNotificationAnnouncement(color: $color)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationAnnouncementCopyWith<$Res>  {
  factory $ChatNotificationAnnouncementCopyWith(ChatNotificationAnnouncement value, $Res Function(ChatNotificationAnnouncement) _then) = _$ChatNotificationAnnouncementCopyWithImpl;
@useResult
$Res call({
 String color
});




}
/// @nodoc
class _$ChatNotificationAnnouncementCopyWithImpl<$Res>
    implements $ChatNotificationAnnouncementCopyWith<$Res> {
  _$ChatNotificationAnnouncementCopyWithImpl(this._self, this._then);

  final ChatNotificationAnnouncement _self;
  final $Res Function(ChatNotificationAnnouncement) _then;

/// Create a copy of ChatNotificationAnnouncement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = null,}) {
  return _then(_self.copyWith(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNotificationAnnouncement].
extension ChatNotificationAnnouncementPatterns on ChatNotificationAnnouncement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationAnnouncement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationAnnouncement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationAnnouncement value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationAnnouncement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationAnnouncement value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationAnnouncement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationAnnouncement() when $default != null:
return $default(_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String color)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationAnnouncement():
return $default(_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String color)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationAnnouncement() when $default != null:
return $default(_that.color);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationAnnouncement implements ChatNotificationAnnouncement {
  const _ChatNotificationAnnouncement({required this.color});
  factory _ChatNotificationAnnouncement.fromJson(Map<String, dynamic> json) => _$ChatNotificationAnnouncementFromJson(json);

/// `blue` | `green` | `orange` | `purple` | `primary`.
@override final  String color;

/// Create a copy of ChatNotificationAnnouncement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationAnnouncementCopyWith<_ChatNotificationAnnouncement> get copyWith => __$ChatNotificationAnnouncementCopyWithImpl<_ChatNotificationAnnouncement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationAnnouncement&&(identical(other.color, color) || other.color == color));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,color);

@override
String toString() {
  return 'ChatNotificationAnnouncement(color: $color)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationAnnouncementCopyWith<$Res> implements $ChatNotificationAnnouncementCopyWith<$Res> {
  factory _$ChatNotificationAnnouncementCopyWith(_ChatNotificationAnnouncement value, $Res Function(_ChatNotificationAnnouncement) _then) = __$ChatNotificationAnnouncementCopyWithImpl;
@override @useResult
$Res call({
 String color
});




}
/// @nodoc
class __$ChatNotificationAnnouncementCopyWithImpl<$Res>
    implements _$ChatNotificationAnnouncementCopyWith<$Res> {
  __$ChatNotificationAnnouncementCopyWithImpl(this._self, this._then);

  final _ChatNotificationAnnouncement _self;
  final $Res Function(_ChatNotificationAnnouncement) _then;

/// Create a copy of ChatNotificationAnnouncement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? color = null,}) {
  return _then(_ChatNotificationAnnouncement(
color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
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


/// @nodoc
mixin _$ChatNotificationRaid {

 int get viewerCount; String? get userName; String? get userLogin;
/// Create a copy of ChatNotificationRaid
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationRaidCopyWith<ChatNotificationRaid> get copyWith => _$ChatNotificationRaidCopyWithImpl<ChatNotificationRaid>(this as ChatNotificationRaid, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationRaid&&(identical(other.viewerCount, viewerCount) || other.viewerCount == viewerCount)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userLogin, userLogin) || other.userLogin == userLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,viewerCount,userName,userLogin);

@override
String toString() {
  return 'ChatNotificationRaid(viewerCount: $viewerCount, userName: $userName, userLogin: $userLogin)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationRaidCopyWith<$Res>  {
  factory $ChatNotificationRaidCopyWith(ChatNotificationRaid value, $Res Function(ChatNotificationRaid) _then) = _$ChatNotificationRaidCopyWithImpl;
@useResult
$Res call({
 int viewerCount, String? userName, String? userLogin
});




}
/// @nodoc
class _$ChatNotificationRaidCopyWithImpl<$Res>
    implements $ChatNotificationRaidCopyWith<$Res> {
  _$ChatNotificationRaidCopyWithImpl(this._self, this._then);

  final ChatNotificationRaid _self;
  final $Res Function(ChatNotificationRaid) _then;

/// Create a copy of ChatNotificationRaid
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? viewerCount = null,Object? userName = freezed,Object? userLogin = freezed,}) {
  return _then(_self.copyWith(
viewerCount: null == viewerCount ? _self.viewerCount : viewerCount // ignore: cast_nullable_to_non_nullable
as int,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,userLogin: freezed == userLogin ? _self.userLogin : userLogin // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNotificationRaid].
extension ChatNotificationRaidPatterns on ChatNotificationRaid {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationRaid value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationRaid() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationRaid value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationRaid():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationRaid value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationRaid() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int viewerCount,  String? userName,  String? userLogin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationRaid() when $default != null:
return $default(_that.viewerCount,_that.userName,_that.userLogin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int viewerCount,  String? userName,  String? userLogin)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationRaid():
return $default(_that.viewerCount,_that.userName,_that.userLogin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int viewerCount,  String? userName,  String? userLogin)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationRaid() when $default != null:
return $default(_that.viewerCount,_that.userName,_that.userLogin);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationRaid implements ChatNotificationRaid {
  const _ChatNotificationRaid({required this.viewerCount, this.userName, this.userLogin});
  factory _ChatNotificationRaid.fromJson(Map<String, dynamic> json) => _$ChatNotificationRaidFromJson(json);

@override final  int viewerCount;
@override final  String? userName;
@override final  String? userLogin;

/// Create a copy of ChatNotificationRaid
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationRaidCopyWith<_ChatNotificationRaid> get copyWith => __$ChatNotificationRaidCopyWithImpl<_ChatNotificationRaid>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationRaid&&(identical(other.viewerCount, viewerCount) || other.viewerCount == viewerCount)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userLogin, userLogin) || other.userLogin == userLogin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,viewerCount,userName,userLogin);

@override
String toString() {
  return 'ChatNotificationRaid(viewerCount: $viewerCount, userName: $userName, userLogin: $userLogin)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationRaidCopyWith<$Res> implements $ChatNotificationRaidCopyWith<$Res> {
  factory _$ChatNotificationRaidCopyWith(_ChatNotificationRaid value, $Res Function(_ChatNotificationRaid) _then) = __$ChatNotificationRaidCopyWithImpl;
@override @useResult
$Res call({
 int viewerCount, String? userName, String? userLogin
});




}
/// @nodoc
class __$ChatNotificationRaidCopyWithImpl<$Res>
    implements _$ChatNotificationRaidCopyWith<$Res> {
  __$ChatNotificationRaidCopyWithImpl(this._self, this._then);

  final _ChatNotificationRaid _self;
  final $Res Function(_ChatNotificationRaid) _then;

/// Create a copy of ChatNotificationRaid
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? viewerCount = null,Object? userName = freezed,Object? userLogin = freezed,}) {
  return _then(_ChatNotificationRaid(
viewerCount: null == viewerCount ? _self.viewerCount : viewerCount // ignore: cast_nullable_to_non_nullable
as int,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,userLogin: freezed == userLogin ? _self.userLogin : userLogin // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatNotificationSubGift {

/// Twitch docs use `sub_plan` (`1000` / `2000` / `3000`).
 String? get subPlan; int? get cumulativeTotal; String? get recipientUserName;
/// Create a copy of ChatNotificationSubGift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationSubGiftCopyWith<ChatNotificationSubGift> get copyWith => _$ChatNotificationSubGiftCopyWithImpl<ChatNotificationSubGift>(this as ChatNotificationSubGift, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationSubGift&&(identical(other.subPlan, subPlan) || other.subPlan == subPlan)&&(identical(other.cumulativeTotal, cumulativeTotal) || other.cumulativeTotal == cumulativeTotal)&&(identical(other.recipientUserName, recipientUserName) || other.recipientUserName == recipientUserName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subPlan,cumulativeTotal,recipientUserName);

@override
String toString() {
  return 'ChatNotificationSubGift(subPlan: $subPlan, cumulativeTotal: $cumulativeTotal, recipientUserName: $recipientUserName)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationSubGiftCopyWith<$Res>  {
  factory $ChatNotificationSubGiftCopyWith(ChatNotificationSubGift value, $Res Function(ChatNotificationSubGift) _then) = _$ChatNotificationSubGiftCopyWithImpl;
@useResult
$Res call({
 String? subPlan, int? cumulativeTotal, String? recipientUserName
});




}
/// @nodoc
class _$ChatNotificationSubGiftCopyWithImpl<$Res>
    implements $ChatNotificationSubGiftCopyWith<$Res> {
  _$ChatNotificationSubGiftCopyWithImpl(this._self, this._then);

  final ChatNotificationSubGift _self;
  final $Res Function(ChatNotificationSubGift) _then;

/// Create a copy of ChatNotificationSubGift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subPlan = freezed,Object? cumulativeTotal = freezed,Object? recipientUserName = freezed,}) {
  return _then(_self.copyWith(
subPlan: freezed == subPlan ? _self.subPlan : subPlan // ignore: cast_nullable_to_non_nullable
as String?,cumulativeTotal: freezed == cumulativeTotal ? _self.cumulativeTotal : cumulativeTotal // ignore: cast_nullable_to_non_nullable
as int?,recipientUserName: freezed == recipientUserName ? _self.recipientUserName : recipientUserName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNotificationSubGift].
extension ChatNotificationSubGiftPatterns on ChatNotificationSubGift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationSubGift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationSubGift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationSubGift value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationSubGift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationSubGift value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationSubGift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? subPlan,  int? cumulativeTotal,  String? recipientUserName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationSubGift() when $default != null:
return $default(_that.subPlan,_that.cumulativeTotal,_that.recipientUserName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? subPlan,  int? cumulativeTotal,  String? recipientUserName)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationSubGift():
return $default(_that.subPlan,_that.cumulativeTotal,_that.recipientUserName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? subPlan,  int? cumulativeTotal,  String? recipientUserName)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationSubGift() when $default != null:
return $default(_that.subPlan,_that.cumulativeTotal,_that.recipientUserName);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationSubGift implements ChatNotificationSubGift {
  const _ChatNotificationSubGift({this.subPlan, this.cumulativeTotal, this.recipientUserName});
  factory _ChatNotificationSubGift.fromJson(Map<String, dynamic> json) => _$ChatNotificationSubGiftFromJson(json);

/// Twitch docs use `sub_plan` (`1000` / `2000` / `3000`).
@override final  String? subPlan;
@override final  int? cumulativeTotal;
@override final  String? recipientUserName;

/// Create a copy of ChatNotificationSubGift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationSubGiftCopyWith<_ChatNotificationSubGift> get copyWith => __$ChatNotificationSubGiftCopyWithImpl<_ChatNotificationSubGift>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationSubGift&&(identical(other.subPlan, subPlan) || other.subPlan == subPlan)&&(identical(other.cumulativeTotal, cumulativeTotal) || other.cumulativeTotal == cumulativeTotal)&&(identical(other.recipientUserName, recipientUserName) || other.recipientUserName == recipientUserName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subPlan,cumulativeTotal,recipientUserName);

@override
String toString() {
  return 'ChatNotificationSubGift(subPlan: $subPlan, cumulativeTotal: $cumulativeTotal, recipientUserName: $recipientUserName)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationSubGiftCopyWith<$Res> implements $ChatNotificationSubGiftCopyWith<$Res> {
  factory _$ChatNotificationSubGiftCopyWith(_ChatNotificationSubGift value, $Res Function(_ChatNotificationSubGift) _then) = __$ChatNotificationSubGiftCopyWithImpl;
@override @useResult
$Res call({
 String? subPlan, int? cumulativeTotal, String? recipientUserName
});




}
/// @nodoc
class __$ChatNotificationSubGiftCopyWithImpl<$Res>
    implements _$ChatNotificationSubGiftCopyWith<$Res> {
  __$ChatNotificationSubGiftCopyWithImpl(this._self, this._then);

  final _ChatNotificationSubGift _self;
  final $Res Function(_ChatNotificationSubGift) _then;

/// Create a copy of ChatNotificationSubGift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subPlan = freezed,Object? cumulativeTotal = freezed,Object? recipientUserName = freezed,}) {
  return _then(_ChatNotificationSubGift(
subPlan: freezed == subPlan ? _self.subPlan : subPlan // ignore: cast_nullable_to_non_nullable
as String?,cumulativeTotal: freezed == cumulativeTotal ? _self.cumulativeTotal : cumulativeTotal // ignore: cast_nullable_to_non_nullable
as int?,recipientUserName: freezed == recipientUserName ? _self.recipientUserName : recipientUserName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatNotificationCommunitySubGift {

 int get total; String? get subPlan; int? get cumulativeTotal;
/// Create a copy of ChatNotificationCommunitySubGift
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationCommunitySubGiftCopyWith<ChatNotificationCommunitySubGift> get copyWith => _$ChatNotificationCommunitySubGiftCopyWithImpl<ChatNotificationCommunitySubGift>(this as ChatNotificationCommunitySubGift, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationCommunitySubGift&&(identical(other.total, total) || other.total == total)&&(identical(other.subPlan, subPlan) || other.subPlan == subPlan)&&(identical(other.cumulativeTotal, cumulativeTotal) || other.cumulativeTotal == cumulativeTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,subPlan,cumulativeTotal);

@override
String toString() {
  return 'ChatNotificationCommunitySubGift(total: $total, subPlan: $subPlan, cumulativeTotal: $cumulativeTotal)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationCommunitySubGiftCopyWith<$Res>  {
  factory $ChatNotificationCommunitySubGiftCopyWith(ChatNotificationCommunitySubGift value, $Res Function(ChatNotificationCommunitySubGift) _then) = _$ChatNotificationCommunitySubGiftCopyWithImpl;
@useResult
$Res call({
 int total, String? subPlan, int? cumulativeTotal
});




}
/// @nodoc
class _$ChatNotificationCommunitySubGiftCopyWithImpl<$Res>
    implements $ChatNotificationCommunitySubGiftCopyWith<$Res> {
  _$ChatNotificationCommunitySubGiftCopyWithImpl(this._self, this._then);

  final ChatNotificationCommunitySubGift _self;
  final $Res Function(ChatNotificationCommunitySubGift) _then;

/// Create a copy of ChatNotificationCommunitySubGift
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? subPlan = freezed,Object? cumulativeTotal = freezed,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,subPlan: freezed == subPlan ? _self.subPlan : subPlan // ignore: cast_nullable_to_non_nullable
as String?,cumulativeTotal: freezed == cumulativeTotal ? _self.cumulativeTotal : cumulativeTotal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNotificationCommunitySubGift].
extension ChatNotificationCommunitySubGiftPatterns on ChatNotificationCommunitySubGift {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationCommunitySubGift value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationCommunitySubGift() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationCommunitySubGift value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationCommunitySubGift():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationCommunitySubGift value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationCommunitySubGift() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  String? subPlan,  int? cumulativeTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationCommunitySubGift() when $default != null:
return $default(_that.total,_that.subPlan,_that.cumulativeTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  String? subPlan,  int? cumulativeTotal)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationCommunitySubGift():
return $default(_that.total,_that.subPlan,_that.cumulativeTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  String? subPlan,  int? cumulativeTotal)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationCommunitySubGift() when $default != null:
return $default(_that.total,_that.subPlan,_that.cumulativeTotal);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationCommunitySubGift implements ChatNotificationCommunitySubGift {
  const _ChatNotificationCommunitySubGift({required this.total, this.subPlan, this.cumulativeTotal});
  factory _ChatNotificationCommunitySubGift.fromJson(Map<String, dynamic> json) => _$ChatNotificationCommunitySubGiftFromJson(json);

@override final  int total;
@override final  String? subPlan;
@override final  int? cumulativeTotal;

/// Create a copy of ChatNotificationCommunitySubGift
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationCommunitySubGiftCopyWith<_ChatNotificationCommunitySubGift> get copyWith => __$ChatNotificationCommunitySubGiftCopyWithImpl<_ChatNotificationCommunitySubGift>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationCommunitySubGift&&(identical(other.total, total) || other.total == total)&&(identical(other.subPlan, subPlan) || other.subPlan == subPlan)&&(identical(other.cumulativeTotal, cumulativeTotal) || other.cumulativeTotal == cumulativeTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,subPlan,cumulativeTotal);

@override
String toString() {
  return 'ChatNotificationCommunitySubGift(total: $total, subPlan: $subPlan, cumulativeTotal: $cumulativeTotal)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationCommunitySubGiftCopyWith<$Res> implements $ChatNotificationCommunitySubGiftCopyWith<$Res> {
  factory _$ChatNotificationCommunitySubGiftCopyWith(_ChatNotificationCommunitySubGift value, $Res Function(_ChatNotificationCommunitySubGift) _then) = __$ChatNotificationCommunitySubGiftCopyWithImpl;
@override @useResult
$Res call({
 int total, String? subPlan, int? cumulativeTotal
});




}
/// @nodoc
class __$ChatNotificationCommunitySubGiftCopyWithImpl<$Res>
    implements _$ChatNotificationCommunitySubGiftCopyWith<$Res> {
  __$ChatNotificationCommunitySubGiftCopyWithImpl(this._self, this._then);

  final _ChatNotificationCommunitySubGift _self;
  final $Res Function(_ChatNotificationCommunitySubGift) _then;

/// Create a copy of ChatNotificationCommunitySubGift
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? subPlan = freezed,Object? cumulativeTotal = freezed,}) {
  return _then(_ChatNotificationCommunitySubGift(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,subPlan: freezed == subPlan ? _self.subPlan : subPlan // ignore: cast_nullable_to_non_nullable
as String?,cumulativeTotal: freezed == cumulativeTotal ? _self.cumulativeTotal : cumulativeTotal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ChatNotificationBitsBadgeTier {

 int get tier;
/// Create a copy of ChatNotificationBitsBadgeTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationBitsBadgeTierCopyWith<ChatNotificationBitsBadgeTier> get copyWith => _$ChatNotificationBitsBadgeTierCopyWithImpl<ChatNotificationBitsBadgeTier>(this as ChatNotificationBitsBadgeTier, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationBitsBadgeTier&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier);

@override
String toString() {
  return 'ChatNotificationBitsBadgeTier(tier: $tier)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationBitsBadgeTierCopyWith<$Res>  {
  factory $ChatNotificationBitsBadgeTierCopyWith(ChatNotificationBitsBadgeTier value, $Res Function(ChatNotificationBitsBadgeTier) _then) = _$ChatNotificationBitsBadgeTierCopyWithImpl;
@useResult
$Res call({
 int tier
});




}
/// @nodoc
class _$ChatNotificationBitsBadgeTierCopyWithImpl<$Res>
    implements $ChatNotificationBitsBadgeTierCopyWith<$Res> {
  _$ChatNotificationBitsBadgeTierCopyWithImpl(this._self, this._then);

  final ChatNotificationBitsBadgeTier _self;
  final $Res Function(ChatNotificationBitsBadgeTier) _then;

/// Create a copy of ChatNotificationBitsBadgeTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tier = null,}) {
  return _then(_self.copyWith(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNotificationBitsBadgeTier].
extension ChatNotificationBitsBadgeTierPatterns on ChatNotificationBitsBadgeTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationBitsBadgeTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationBitsBadgeTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationBitsBadgeTier value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationBitsBadgeTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationBitsBadgeTier value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationBitsBadgeTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int tier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationBitsBadgeTier() when $default != null:
return $default(_that.tier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int tier)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationBitsBadgeTier():
return $default(_that.tier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int tier)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationBitsBadgeTier() when $default != null:
return $default(_that.tier);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationBitsBadgeTier implements ChatNotificationBitsBadgeTier {
  const _ChatNotificationBitsBadgeTier({required this.tier});
  factory _ChatNotificationBitsBadgeTier.fromJson(Map<String, dynamic> json) => _$ChatNotificationBitsBadgeTierFromJson(json);

@override final  int tier;

/// Create a copy of ChatNotificationBitsBadgeTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationBitsBadgeTierCopyWith<_ChatNotificationBitsBadgeTier> get copyWith => __$ChatNotificationBitsBadgeTierCopyWithImpl<_ChatNotificationBitsBadgeTier>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationBitsBadgeTier&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tier);

@override
String toString() {
  return 'ChatNotificationBitsBadgeTier(tier: $tier)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationBitsBadgeTierCopyWith<$Res> implements $ChatNotificationBitsBadgeTierCopyWith<$Res> {
  factory _$ChatNotificationBitsBadgeTierCopyWith(_ChatNotificationBitsBadgeTier value, $Res Function(_ChatNotificationBitsBadgeTier) _then) = __$ChatNotificationBitsBadgeTierCopyWithImpl;
@override @useResult
$Res call({
 int tier
});




}
/// @nodoc
class __$ChatNotificationBitsBadgeTierCopyWithImpl<$Res>
    implements _$ChatNotificationBitsBadgeTierCopyWith<$Res> {
  __$ChatNotificationBitsBadgeTierCopyWithImpl(this._self, this._then);

  final _ChatNotificationBitsBadgeTier _self;
  final $Res Function(_ChatNotificationBitsBadgeTier) _then;

/// Create a copy of ChatNotificationBitsBadgeTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tier = null,}) {
  return _then(_ChatNotificationBitsBadgeTier(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ChatNotificationCharityDonation {

 String? get charityName; ChatNotificationCharityAmount? get amount;
/// Create a copy of ChatNotificationCharityDonation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationCharityDonationCopyWith<ChatNotificationCharityDonation> get copyWith => _$ChatNotificationCharityDonationCopyWithImpl<ChatNotificationCharityDonation>(this as ChatNotificationCharityDonation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationCharityDonation&&(identical(other.charityName, charityName) || other.charityName == charityName)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,charityName,amount);

@override
String toString() {
  return 'ChatNotificationCharityDonation(charityName: $charityName, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationCharityDonationCopyWith<$Res>  {
  factory $ChatNotificationCharityDonationCopyWith(ChatNotificationCharityDonation value, $Res Function(ChatNotificationCharityDonation) _then) = _$ChatNotificationCharityDonationCopyWithImpl;
@useResult
$Res call({
 String? charityName, ChatNotificationCharityAmount? amount
});


$ChatNotificationCharityAmountCopyWith<$Res>? get amount;

}
/// @nodoc
class _$ChatNotificationCharityDonationCopyWithImpl<$Res>
    implements $ChatNotificationCharityDonationCopyWith<$Res> {
  _$ChatNotificationCharityDonationCopyWithImpl(this._self, this._then);

  final ChatNotificationCharityDonation _self;
  final $Res Function(ChatNotificationCharityDonation) _then;

/// Create a copy of ChatNotificationCharityDonation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? charityName = freezed,Object? amount = freezed,}) {
  return _then(_self.copyWith(
charityName: freezed == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as ChatNotificationCharityAmount?,
  ));
}
/// Create a copy of ChatNotificationCharityDonation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationCharityAmountCopyWith<$Res>? get amount {
    if (_self.amount == null) {
    return null;
  }

  return $ChatNotificationCharityAmountCopyWith<$Res>(_self.amount!, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatNotificationCharityDonation].
extension ChatNotificationCharityDonationPatterns on ChatNotificationCharityDonation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationCharityDonation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationCharityDonation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationCharityDonation value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationCharityDonation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationCharityDonation value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationCharityDonation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? charityName,  ChatNotificationCharityAmount? amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationCharityDonation() when $default != null:
return $default(_that.charityName,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? charityName,  ChatNotificationCharityAmount? amount)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationCharityDonation():
return $default(_that.charityName,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? charityName,  ChatNotificationCharityAmount? amount)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationCharityDonation() when $default != null:
return $default(_that.charityName,_that.amount);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationCharityDonation implements ChatNotificationCharityDonation {
  const _ChatNotificationCharityDonation({this.charityName, this.amount});
  factory _ChatNotificationCharityDonation.fromJson(Map<String, dynamic> json) => _$ChatNotificationCharityDonationFromJson(json);

@override final  String? charityName;
@override final  ChatNotificationCharityAmount? amount;

/// Create a copy of ChatNotificationCharityDonation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationCharityDonationCopyWith<_ChatNotificationCharityDonation> get copyWith => __$ChatNotificationCharityDonationCopyWithImpl<_ChatNotificationCharityDonation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationCharityDonation&&(identical(other.charityName, charityName) || other.charityName == charityName)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,charityName,amount);

@override
String toString() {
  return 'ChatNotificationCharityDonation(charityName: $charityName, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationCharityDonationCopyWith<$Res> implements $ChatNotificationCharityDonationCopyWith<$Res> {
  factory _$ChatNotificationCharityDonationCopyWith(_ChatNotificationCharityDonation value, $Res Function(_ChatNotificationCharityDonation) _then) = __$ChatNotificationCharityDonationCopyWithImpl;
@override @useResult
$Res call({
 String? charityName, ChatNotificationCharityAmount? amount
});


@override $ChatNotificationCharityAmountCopyWith<$Res>? get amount;

}
/// @nodoc
class __$ChatNotificationCharityDonationCopyWithImpl<$Res>
    implements _$ChatNotificationCharityDonationCopyWith<$Res> {
  __$ChatNotificationCharityDonationCopyWithImpl(this._self, this._then);

  final _ChatNotificationCharityDonation _self;
  final $Res Function(_ChatNotificationCharityDonation) _then;

/// Create a copy of ChatNotificationCharityDonation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? charityName = freezed,Object? amount = freezed,}) {
  return _then(_ChatNotificationCharityDonation(
charityName: freezed == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as ChatNotificationCharityAmount?,
  ));
}

/// Create a copy of ChatNotificationCharityDonation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatNotificationCharityAmountCopyWith<$Res>? get amount {
    if (_self.amount == null) {
    return null;
  }

  return $ChatNotificationCharityAmountCopyWith<$Res>(_self.amount!, (value) {
    return _then(_self.copyWith(amount: value));
  });
}
}


/// @nodoc
mixin _$ChatNotificationCharityAmount {

 int get value;/// Twitch docs alternate `decimal_places` / `decimal_place`.
@JsonKey(name: 'decimal_places') int? get decimalPlaces;@JsonKey(name: 'decimal_place') int? get decimalPlace; String? get currency;
/// Create a copy of ChatNotificationCharityAmount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatNotificationCharityAmountCopyWith<ChatNotificationCharityAmount> get copyWith => _$ChatNotificationCharityAmountCopyWithImpl<ChatNotificationCharityAmount>(this as ChatNotificationCharityAmount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatNotificationCharityAmount&&(identical(other.value, value) || other.value == value)&&(identical(other.decimalPlaces, decimalPlaces) || other.decimalPlaces == decimalPlaces)&&(identical(other.decimalPlace, decimalPlace) || other.decimalPlace == decimalPlace)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,decimalPlaces,decimalPlace,currency);

@override
String toString() {
  return 'ChatNotificationCharityAmount(value: $value, decimalPlaces: $decimalPlaces, decimalPlace: $decimalPlace, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $ChatNotificationCharityAmountCopyWith<$Res>  {
  factory $ChatNotificationCharityAmountCopyWith(ChatNotificationCharityAmount value, $Res Function(ChatNotificationCharityAmount) _then) = _$ChatNotificationCharityAmountCopyWithImpl;
@useResult
$Res call({
 int value,@JsonKey(name: 'decimal_places') int? decimalPlaces,@JsonKey(name: 'decimal_place') int? decimalPlace, String? currency
});




}
/// @nodoc
class _$ChatNotificationCharityAmountCopyWithImpl<$Res>
    implements $ChatNotificationCharityAmountCopyWith<$Res> {
  _$ChatNotificationCharityAmountCopyWithImpl(this._self, this._then);

  final ChatNotificationCharityAmount _self;
  final $Res Function(ChatNotificationCharityAmount) _then;

/// Create a copy of ChatNotificationCharityAmount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? decimalPlaces = freezed,Object? decimalPlace = freezed,Object? currency = freezed,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,decimalPlaces: freezed == decimalPlaces ? _self.decimalPlaces : decimalPlaces // ignore: cast_nullable_to_non_nullable
as int?,decimalPlace: freezed == decimalPlace ? _self.decimalPlace : decimalPlace // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatNotificationCharityAmount].
extension ChatNotificationCharityAmountPatterns on ChatNotificationCharityAmount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatNotificationCharityAmount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatNotificationCharityAmount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatNotificationCharityAmount value)  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationCharityAmount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatNotificationCharityAmount value)?  $default,){
final _that = this;
switch (_that) {
case _ChatNotificationCharityAmount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value, @JsonKey(name: 'decimal_places')  int? decimalPlaces, @JsonKey(name: 'decimal_place')  int? decimalPlace,  String? currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatNotificationCharityAmount() when $default != null:
return $default(_that.value,_that.decimalPlaces,_that.decimalPlace,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value, @JsonKey(name: 'decimal_places')  int? decimalPlaces, @JsonKey(name: 'decimal_place')  int? decimalPlace,  String? currency)  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationCharityAmount():
return $default(_that.value,_that.decimalPlaces,_that.decimalPlace,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value, @JsonKey(name: 'decimal_places')  int? decimalPlaces, @JsonKey(name: 'decimal_place')  int? decimalPlace,  String? currency)?  $default,) {final _that = this;
switch (_that) {
case _ChatNotificationCharityAmount() when $default != null:
return $default(_that.value,_that.decimalPlaces,_that.decimalPlace,_that.currency);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatNotificationCharityAmount implements ChatNotificationCharityAmount {
  const _ChatNotificationCharityAmount({required this.value, @JsonKey(name: 'decimal_places') this.decimalPlaces, @JsonKey(name: 'decimal_place') this.decimalPlace, this.currency});
  factory _ChatNotificationCharityAmount.fromJson(Map<String, dynamic> json) => _$ChatNotificationCharityAmountFromJson(json);

@override final  int value;
/// Twitch docs alternate `decimal_places` / `decimal_place`.
@override@JsonKey(name: 'decimal_places') final  int? decimalPlaces;
@override@JsonKey(name: 'decimal_place') final  int? decimalPlace;
@override final  String? currency;

/// Create a copy of ChatNotificationCharityAmount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatNotificationCharityAmountCopyWith<_ChatNotificationCharityAmount> get copyWith => __$ChatNotificationCharityAmountCopyWithImpl<_ChatNotificationCharityAmount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatNotificationCharityAmount&&(identical(other.value, value) || other.value == value)&&(identical(other.decimalPlaces, decimalPlaces) || other.decimalPlaces == decimalPlaces)&&(identical(other.decimalPlace, decimalPlace) || other.decimalPlace == decimalPlace)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,decimalPlaces,decimalPlace,currency);

@override
String toString() {
  return 'ChatNotificationCharityAmount(value: $value, decimalPlaces: $decimalPlaces, decimalPlace: $decimalPlace, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$ChatNotificationCharityAmountCopyWith<$Res> implements $ChatNotificationCharityAmountCopyWith<$Res> {
  factory _$ChatNotificationCharityAmountCopyWith(_ChatNotificationCharityAmount value, $Res Function(_ChatNotificationCharityAmount) _then) = __$ChatNotificationCharityAmountCopyWithImpl;
@override @useResult
$Res call({
 int value,@JsonKey(name: 'decimal_places') int? decimalPlaces,@JsonKey(name: 'decimal_place') int? decimalPlace, String? currency
});




}
/// @nodoc
class __$ChatNotificationCharityAmountCopyWithImpl<$Res>
    implements _$ChatNotificationCharityAmountCopyWith<$Res> {
  __$ChatNotificationCharityAmountCopyWithImpl(this._self, this._then);

  final _ChatNotificationCharityAmount _self;
  final $Res Function(_ChatNotificationCharityAmount) _then;

/// Create a copy of ChatNotificationCharityAmount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? decimalPlaces = freezed,Object? decimalPlace = freezed,Object? currency = freezed,}) {
  return _then(_ChatNotificationCharityAmount(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,decimalPlaces: freezed == decimalPlaces ? _self.decimalPlaces : decimalPlaces // ignore: cast_nullable_to_non_nullable
as int?,decimalPlace: freezed == decimalPlace ? _self.decimalPlace : decimalPlace // ignore: cast_nullable_to_non_nullable
as int?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
