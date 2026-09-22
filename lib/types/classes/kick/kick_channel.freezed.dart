// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kick_channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KickChannelInfo {

 int get id;@JsonKey(name: 'user_id') int? get userId; String get slug;/// Display name lives under `user.username`.
@JsonKey(readValue: _readUsername) String? get username; KickChatroom get chatroom;@JsonKey(name: 'subscriber_badges') List<KickSubscriberBadge> get subscriberBadges; KickLivestreamInfo? get livestream;
/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickChannelInfoCopyWith<KickChannelInfo> get copyWith => _$KickChannelInfoCopyWithImpl<KickChannelInfo>(this as KickChannelInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickChannelInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.username, username) || other.username == username)&&(identical(other.chatroom, chatroom) || other.chatroom == chatroom)&&const DeepCollectionEquality().equals(other.subscriberBadges, subscriberBadges)&&(identical(other.livestream, livestream) || other.livestream == livestream));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,slug,username,chatroom,const DeepCollectionEquality().hash(subscriberBadges),livestream);

@override
String toString() {
  return 'KickChannelInfo(id: $id, userId: $userId, slug: $slug, username: $username, chatroom: $chatroom, subscriberBadges: $subscriberBadges, livestream: $livestream)';
}


}

/// @nodoc
abstract mixin class $KickChannelInfoCopyWith<$Res>  {
  factory $KickChannelInfoCopyWith(KickChannelInfo value, $Res Function(KickChannelInfo) _then) = _$KickChannelInfoCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'user_id') int? userId, String slug,@JsonKey(readValue: _readUsername) String? username, KickChatroom chatroom,@JsonKey(name: 'subscriber_badges') List<KickSubscriberBadge> subscriberBadges, KickLivestreamInfo? livestream
});


$KickChatroomCopyWith<$Res> get chatroom;$KickLivestreamInfoCopyWith<$Res>? get livestream;

}
/// @nodoc
class _$KickChannelInfoCopyWithImpl<$Res>
    implements $KickChannelInfoCopyWith<$Res> {
  _$KickChannelInfoCopyWithImpl(this._self, this._then);

  final KickChannelInfo _self;
  final $Res Function(KickChannelInfo) _then;

/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = freezed,Object? slug = null,Object? username = freezed,Object? chatroom = null,Object? subscriberBadges = null,Object? livestream = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,chatroom: null == chatroom ? _self.chatroom : chatroom // ignore: cast_nullable_to_non_nullable
as KickChatroom,subscriberBadges: null == subscriberBadges ? _self.subscriberBadges : subscriberBadges // ignore: cast_nullable_to_non_nullable
as List<KickSubscriberBadge>,livestream: freezed == livestream ? _self.livestream : livestream // ignore: cast_nullable_to_non_nullable
as KickLivestreamInfo?,
  ));
}
/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickChatroomCopyWith<$Res> get chatroom {
  
  return $KickChatroomCopyWith<$Res>(_self.chatroom, (value) {
    return _then(_self.copyWith(chatroom: value));
  });
}/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickLivestreamInfoCopyWith<$Res>? get livestream {
    if (_self.livestream == null) {
    return null;
  }

  return $KickLivestreamInfoCopyWith<$Res>(_self.livestream!, (value) {
    return _then(_self.copyWith(livestream: value));
  });
}
}


/// Adds pattern-matching-related methods to [KickChannelInfo].
extension KickChannelInfoPatterns on KickChannelInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickChannelInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickChannelInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickChannelInfo value)  $default,){
final _that = this;
switch (_that) {
case _KickChannelInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickChannelInfo value)?  $default,){
final _that = this;
switch (_that) {
case _KickChannelInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_id')  int? userId,  String slug, @JsonKey(readValue: _readUsername)  String? username,  KickChatroom chatroom, @JsonKey(name: 'subscriber_badges')  List<KickSubscriberBadge> subscriberBadges,  KickLivestreamInfo? livestream)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickChannelInfo() when $default != null:
return $default(_that.id,_that.userId,_that.slug,_that.username,_that.chatroom,_that.subscriberBadges,_that.livestream);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_id')  int? userId,  String slug, @JsonKey(readValue: _readUsername)  String? username,  KickChatroom chatroom, @JsonKey(name: 'subscriber_badges')  List<KickSubscriberBadge> subscriberBadges,  KickLivestreamInfo? livestream)  $default,) {final _that = this;
switch (_that) {
case _KickChannelInfo():
return $default(_that.id,_that.userId,_that.slug,_that.username,_that.chatroom,_that.subscriberBadges,_that.livestream);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'user_id')  int? userId,  String slug, @JsonKey(readValue: _readUsername)  String? username,  KickChatroom chatroom, @JsonKey(name: 'subscriber_badges')  List<KickSubscriberBadge> subscriberBadges,  KickLivestreamInfo? livestream)?  $default,) {final _that = this;
switch (_that) {
case _KickChannelInfo() when $default != null:
return $default(_that.id,_that.userId,_that.slug,_that.username,_that.chatroom,_that.subscriberBadges,_that.livestream);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickChannelInfo extends KickChannelInfo {
  const _KickChannelInfo({required this.id, @JsonKey(name: 'user_id') this.userId, required this.slug, @JsonKey(readValue: _readUsername) this.username, required this.chatroom, @JsonKey(name: 'subscriber_badges') final  List<KickSubscriberBadge> subscriberBadges = const <KickSubscriberBadge>[], this.livestream}): _subscriberBadges = subscriberBadges,super._();
  factory _KickChannelInfo.fromJson(Map<String, dynamic> json) => _$KickChannelInfoFromJson(json);

@override final  int id;
@override@JsonKey(name: 'user_id') final  int? userId;
@override final  String slug;
/// Display name lives under `user.username`.
@override@JsonKey(readValue: _readUsername) final  String? username;
@override final  KickChatroom chatroom;
 final  List<KickSubscriberBadge> _subscriberBadges;
@override@JsonKey(name: 'subscriber_badges') List<KickSubscriberBadge> get subscriberBadges {
  if (_subscriberBadges is EqualUnmodifiableListView) return _subscriberBadges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subscriberBadges);
}

@override final  KickLivestreamInfo? livestream;

/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickChannelInfoCopyWith<_KickChannelInfo> get copyWith => __$KickChannelInfoCopyWithImpl<_KickChannelInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickChannelInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.username, username) || other.username == username)&&(identical(other.chatroom, chatroom) || other.chatroom == chatroom)&&const DeepCollectionEquality().equals(other._subscriberBadges, _subscriberBadges)&&(identical(other.livestream, livestream) || other.livestream == livestream));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,slug,username,chatroom,const DeepCollectionEquality().hash(_subscriberBadges),livestream);

@override
String toString() {
  return 'KickChannelInfo(id: $id, userId: $userId, slug: $slug, username: $username, chatroom: $chatroom, subscriberBadges: $subscriberBadges, livestream: $livestream)';
}


}

/// @nodoc
abstract mixin class _$KickChannelInfoCopyWith<$Res> implements $KickChannelInfoCopyWith<$Res> {
  factory _$KickChannelInfoCopyWith(_KickChannelInfo value, $Res Function(_KickChannelInfo) _then) = __$KickChannelInfoCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'user_id') int? userId, String slug,@JsonKey(readValue: _readUsername) String? username, KickChatroom chatroom,@JsonKey(name: 'subscriber_badges') List<KickSubscriberBadge> subscriberBadges, KickLivestreamInfo? livestream
});


@override $KickChatroomCopyWith<$Res> get chatroom;@override $KickLivestreamInfoCopyWith<$Res>? get livestream;

}
/// @nodoc
class __$KickChannelInfoCopyWithImpl<$Res>
    implements _$KickChannelInfoCopyWith<$Res> {
  __$KickChannelInfoCopyWithImpl(this._self, this._then);

  final _KickChannelInfo _self;
  final $Res Function(_KickChannelInfo) _then;

/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = freezed,Object? slug = null,Object? username = freezed,Object? chatroom = null,Object? subscriberBadges = null,Object? livestream = freezed,}) {
  return _then(_KickChannelInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,chatroom: null == chatroom ? _self.chatroom : chatroom // ignore: cast_nullable_to_non_nullable
as KickChatroom,subscriberBadges: null == subscriberBadges ? _self._subscriberBadges : subscriberBadges // ignore: cast_nullable_to_non_nullable
as List<KickSubscriberBadge>,livestream: freezed == livestream ? _self.livestream : livestream // ignore: cast_nullable_to_non_nullable
as KickLivestreamInfo?,
  ));
}

/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickChatroomCopyWith<$Res> get chatroom {
  
  return $KickChatroomCopyWith<$Res>(_self.chatroom, (value) {
    return _then(_self.copyWith(chatroom: value));
  });
}/// Create a copy of KickChannelInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$KickLivestreamInfoCopyWith<$Res>? get livestream {
    if (_self.livestream == null) {
    return null;
  }

  return $KickLivestreamInfoCopyWith<$Res>(_self.livestream!, (value) {
    return _then(_self.copyWith(livestream: value));
  });
}
}


/// @nodoc
mixin _$KickChatroom {

 int get id;@JsonKey(name: 'slow_mode') bool get slowMode;@JsonKey(name: 'followers_mode') bool get followersMode;@JsonKey(name: 'subscribers_mode') bool get subscribersMode;@JsonKey(name: 'emotes_mode') bool get emotesMode;@JsonKey(name: 'message_interval') int get messageInterval;@JsonKey(name: 'following_min_duration') int get followingMinDuration;
/// Create a copy of KickChatroom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickChatroomCopyWith<KickChatroom> get copyWith => _$KickChatroomCopyWithImpl<KickChatroom>(this as KickChatroom, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickChatroom&&(identical(other.id, id) || other.id == id)&&(identical(other.slowMode, slowMode) || other.slowMode == slowMode)&&(identical(other.followersMode, followersMode) || other.followersMode == followersMode)&&(identical(other.subscribersMode, subscribersMode) || other.subscribersMode == subscribersMode)&&(identical(other.emotesMode, emotesMode) || other.emotesMode == emotesMode)&&(identical(other.messageInterval, messageInterval) || other.messageInterval == messageInterval)&&(identical(other.followingMinDuration, followingMinDuration) || other.followingMinDuration == followingMinDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slowMode,followersMode,subscribersMode,emotesMode,messageInterval,followingMinDuration);

@override
String toString() {
  return 'KickChatroom(id: $id, slowMode: $slowMode, followersMode: $followersMode, subscribersMode: $subscribersMode, emotesMode: $emotesMode, messageInterval: $messageInterval, followingMinDuration: $followingMinDuration)';
}


}

/// @nodoc
abstract mixin class $KickChatroomCopyWith<$Res>  {
  factory $KickChatroomCopyWith(KickChatroom value, $Res Function(KickChatroom) _then) = _$KickChatroomCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'slow_mode') bool slowMode,@JsonKey(name: 'followers_mode') bool followersMode,@JsonKey(name: 'subscribers_mode') bool subscribersMode,@JsonKey(name: 'emotes_mode') bool emotesMode,@JsonKey(name: 'message_interval') int messageInterval,@JsonKey(name: 'following_min_duration') int followingMinDuration
});




}
/// @nodoc
class _$KickChatroomCopyWithImpl<$Res>
    implements $KickChatroomCopyWith<$Res> {
  _$KickChatroomCopyWithImpl(this._self, this._then);

  final KickChatroom _self;
  final $Res Function(KickChatroom) _then;

/// Create a copy of KickChatroom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slowMode = null,Object? followersMode = null,Object? subscribersMode = null,Object? emotesMode = null,Object? messageInterval = null,Object? followingMinDuration = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slowMode: null == slowMode ? _self.slowMode : slowMode // ignore: cast_nullable_to_non_nullable
as bool,followersMode: null == followersMode ? _self.followersMode : followersMode // ignore: cast_nullable_to_non_nullable
as bool,subscribersMode: null == subscribersMode ? _self.subscribersMode : subscribersMode // ignore: cast_nullable_to_non_nullable
as bool,emotesMode: null == emotesMode ? _self.emotesMode : emotesMode // ignore: cast_nullable_to_non_nullable
as bool,messageInterval: null == messageInterval ? _self.messageInterval : messageInterval // ignore: cast_nullable_to_non_nullable
as int,followingMinDuration: null == followingMinDuration ? _self.followingMinDuration : followingMinDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [KickChatroom].
extension KickChatroomPatterns on KickChatroom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickChatroom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickChatroom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickChatroom value)  $default,){
final _that = this;
switch (_that) {
case _KickChatroom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickChatroom value)?  $default,){
final _that = this;
switch (_that) {
case _KickChatroom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'slow_mode')  bool slowMode, @JsonKey(name: 'followers_mode')  bool followersMode, @JsonKey(name: 'subscribers_mode')  bool subscribersMode, @JsonKey(name: 'emotes_mode')  bool emotesMode, @JsonKey(name: 'message_interval')  int messageInterval, @JsonKey(name: 'following_min_duration')  int followingMinDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickChatroom() when $default != null:
return $default(_that.id,_that.slowMode,_that.followersMode,_that.subscribersMode,_that.emotesMode,_that.messageInterval,_that.followingMinDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'slow_mode')  bool slowMode, @JsonKey(name: 'followers_mode')  bool followersMode, @JsonKey(name: 'subscribers_mode')  bool subscribersMode, @JsonKey(name: 'emotes_mode')  bool emotesMode, @JsonKey(name: 'message_interval')  int messageInterval, @JsonKey(name: 'following_min_duration')  int followingMinDuration)  $default,) {final _that = this;
switch (_that) {
case _KickChatroom():
return $default(_that.id,_that.slowMode,_that.followersMode,_that.subscribersMode,_that.emotesMode,_that.messageInterval,_that.followingMinDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'slow_mode')  bool slowMode, @JsonKey(name: 'followers_mode')  bool followersMode, @JsonKey(name: 'subscribers_mode')  bool subscribersMode, @JsonKey(name: 'emotes_mode')  bool emotesMode, @JsonKey(name: 'message_interval')  int messageInterval, @JsonKey(name: 'following_min_duration')  int followingMinDuration)?  $default,) {final _that = this;
switch (_that) {
case _KickChatroom() when $default != null:
return $default(_that.id,_that.slowMode,_that.followersMode,_that.subscribersMode,_that.emotesMode,_that.messageInterval,_that.followingMinDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickChatroom implements KickChatroom {
  const _KickChatroom({required this.id, @JsonKey(name: 'slow_mode') this.slowMode = false, @JsonKey(name: 'followers_mode') this.followersMode = false, @JsonKey(name: 'subscribers_mode') this.subscribersMode = false, @JsonKey(name: 'emotes_mode') this.emotesMode = false, @JsonKey(name: 'message_interval') this.messageInterval = 0, @JsonKey(name: 'following_min_duration') this.followingMinDuration = 0});
  factory _KickChatroom.fromJson(Map<String, dynamic> json) => _$KickChatroomFromJson(json);

@override final  int id;
@override@JsonKey(name: 'slow_mode') final  bool slowMode;
@override@JsonKey(name: 'followers_mode') final  bool followersMode;
@override@JsonKey(name: 'subscribers_mode') final  bool subscribersMode;
@override@JsonKey(name: 'emotes_mode') final  bool emotesMode;
@override@JsonKey(name: 'message_interval') final  int messageInterval;
@override@JsonKey(name: 'following_min_duration') final  int followingMinDuration;

/// Create a copy of KickChatroom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickChatroomCopyWith<_KickChatroom> get copyWith => __$KickChatroomCopyWithImpl<_KickChatroom>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickChatroom&&(identical(other.id, id) || other.id == id)&&(identical(other.slowMode, slowMode) || other.slowMode == slowMode)&&(identical(other.followersMode, followersMode) || other.followersMode == followersMode)&&(identical(other.subscribersMode, subscribersMode) || other.subscribersMode == subscribersMode)&&(identical(other.emotesMode, emotesMode) || other.emotesMode == emotesMode)&&(identical(other.messageInterval, messageInterval) || other.messageInterval == messageInterval)&&(identical(other.followingMinDuration, followingMinDuration) || other.followingMinDuration == followingMinDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slowMode,followersMode,subscribersMode,emotesMode,messageInterval,followingMinDuration);

@override
String toString() {
  return 'KickChatroom(id: $id, slowMode: $slowMode, followersMode: $followersMode, subscribersMode: $subscribersMode, emotesMode: $emotesMode, messageInterval: $messageInterval, followingMinDuration: $followingMinDuration)';
}


}

/// @nodoc
abstract mixin class _$KickChatroomCopyWith<$Res> implements $KickChatroomCopyWith<$Res> {
  factory _$KickChatroomCopyWith(_KickChatroom value, $Res Function(_KickChatroom) _then) = __$KickChatroomCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'slow_mode') bool slowMode,@JsonKey(name: 'followers_mode') bool followersMode,@JsonKey(name: 'subscribers_mode') bool subscribersMode,@JsonKey(name: 'emotes_mode') bool emotesMode,@JsonKey(name: 'message_interval') int messageInterval,@JsonKey(name: 'following_min_duration') int followingMinDuration
});




}
/// @nodoc
class __$KickChatroomCopyWithImpl<$Res>
    implements _$KickChatroomCopyWith<$Res> {
  __$KickChatroomCopyWithImpl(this._self, this._then);

  final _KickChatroom _self;
  final $Res Function(_KickChatroom) _then;

/// Create a copy of KickChatroom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slowMode = null,Object? followersMode = null,Object? subscribersMode = null,Object? emotesMode = null,Object? messageInterval = null,Object? followingMinDuration = null,}) {
  return _then(_KickChatroom(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slowMode: null == slowMode ? _self.slowMode : slowMode // ignore: cast_nullable_to_non_nullable
as bool,followersMode: null == followersMode ? _self.followersMode : followersMode // ignore: cast_nullable_to_non_nullable
as bool,subscribersMode: null == subscribersMode ? _self.subscribersMode : subscribersMode // ignore: cast_nullable_to_non_nullable
as bool,emotesMode: null == emotesMode ? _self.emotesMode : emotesMode // ignore: cast_nullable_to_non_nullable
as bool,messageInterval: null == messageInterval ? _self.messageInterval : messageInterval // ignore: cast_nullable_to_non_nullable
as int,followingMinDuration: null == followingMinDuration ? _self.followingMinDuration : followingMinDuration // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$KickSubscriberBadge {

 int get months;@JsonKey(name: 'badge_image', readValue: _readBadgeImage) String? get imageUrl;
/// Create a copy of KickSubscriberBadge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickSubscriberBadgeCopyWith<KickSubscriberBadge> get copyWith => _$KickSubscriberBadgeCopyWithImpl<KickSubscriberBadge>(this as KickSubscriberBadge, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickSubscriberBadge&&(identical(other.months, months) || other.months == months)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,months,imageUrl);

@override
String toString() {
  return 'KickSubscriberBadge(months: $months, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $KickSubscriberBadgeCopyWith<$Res>  {
  factory $KickSubscriberBadgeCopyWith(KickSubscriberBadge value, $Res Function(KickSubscriberBadge) _then) = _$KickSubscriberBadgeCopyWithImpl;
@useResult
$Res call({
 int months,@JsonKey(name: 'badge_image', readValue: _readBadgeImage) String? imageUrl
});




}
/// @nodoc
class _$KickSubscriberBadgeCopyWithImpl<$Res>
    implements $KickSubscriberBadgeCopyWith<$Res> {
  _$KickSubscriberBadgeCopyWithImpl(this._self, this._then);

  final KickSubscriberBadge _self;
  final $Res Function(KickSubscriberBadge) _then;

/// Create a copy of KickSubscriberBadge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? months = null,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [KickSubscriberBadge].
extension KickSubscriberBadgePatterns on KickSubscriberBadge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickSubscriberBadge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickSubscriberBadge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickSubscriberBadge value)  $default,){
final _that = this;
switch (_that) {
case _KickSubscriberBadge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickSubscriberBadge value)?  $default,){
final _that = this;
switch (_that) {
case _KickSubscriberBadge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int months, @JsonKey(name: 'badge_image', readValue: _readBadgeImage)  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickSubscriberBadge() when $default != null:
return $default(_that.months,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int months, @JsonKey(name: 'badge_image', readValue: _readBadgeImage)  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _KickSubscriberBadge():
return $default(_that.months,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int months, @JsonKey(name: 'badge_image', readValue: _readBadgeImage)  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _KickSubscriberBadge() when $default != null:
return $default(_that.months,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickSubscriberBadge implements KickSubscriberBadge {
  const _KickSubscriberBadge({this.months = 0, @JsonKey(name: 'badge_image', readValue: _readBadgeImage) this.imageUrl});
  factory _KickSubscriberBadge.fromJson(Map<String, dynamic> json) => _$KickSubscriberBadgeFromJson(json);

@override@JsonKey() final  int months;
@override@JsonKey(name: 'badge_image', readValue: _readBadgeImage) final  String? imageUrl;

/// Create a copy of KickSubscriberBadge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickSubscriberBadgeCopyWith<_KickSubscriberBadge> get copyWith => __$KickSubscriberBadgeCopyWithImpl<_KickSubscriberBadge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickSubscriberBadge&&(identical(other.months, months) || other.months == months)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,months,imageUrl);

@override
String toString() {
  return 'KickSubscriberBadge(months: $months, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$KickSubscriberBadgeCopyWith<$Res> implements $KickSubscriberBadgeCopyWith<$Res> {
  factory _$KickSubscriberBadgeCopyWith(_KickSubscriberBadge value, $Res Function(_KickSubscriberBadge) _then) = __$KickSubscriberBadgeCopyWithImpl;
@override @useResult
$Res call({
 int months,@JsonKey(name: 'badge_image', readValue: _readBadgeImage) String? imageUrl
});




}
/// @nodoc
class __$KickSubscriberBadgeCopyWithImpl<$Res>
    implements _$KickSubscriberBadgeCopyWith<$Res> {
  __$KickSubscriberBadgeCopyWithImpl(this._self, this._then);

  final _KickSubscriberBadge _self;
  final $Res Function(_KickSubscriberBadge) _then;

/// Create a copy of KickSubscriberBadge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? months = null,Object? imageUrl = freezed,}) {
  return _then(_KickSubscriberBadge(
months: null == months ? _self.months : months // ignore: cast_nullable_to_non_nullable
as int,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$KickLivestreamInfo {

@JsonKey(name: 'is_live') bool get isLive;@JsonKey(name: 'viewer_count') int? get viewerCount;
/// Create a copy of KickLivestreamInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickLivestreamInfoCopyWith<KickLivestreamInfo> get copyWith => _$KickLivestreamInfoCopyWithImpl<KickLivestreamInfo>(this as KickLivestreamInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickLivestreamInfo&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.viewerCount, viewerCount) || other.viewerCount == viewerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isLive,viewerCount);

@override
String toString() {
  return 'KickLivestreamInfo(isLive: $isLive, viewerCount: $viewerCount)';
}


}

/// @nodoc
abstract mixin class $KickLivestreamInfoCopyWith<$Res>  {
  factory $KickLivestreamInfoCopyWith(KickLivestreamInfo value, $Res Function(KickLivestreamInfo) _then) = _$KickLivestreamInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'is_live') bool isLive,@JsonKey(name: 'viewer_count') int? viewerCount
});




}
/// @nodoc
class _$KickLivestreamInfoCopyWithImpl<$Res>
    implements $KickLivestreamInfoCopyWith<$Res> {
  _$KickLivestreamInfoCopyWithImpl(this._self, this._then);

  final KickLivestreamInfo _self;
  final $Res Function(KickLivestreamInfo) _then;

/// Create a copy of KickLivestreamInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLive = null,Object? viewerCount = freezed,}) {
  return _then(_self.copyWith(
isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,viewerCount: freezed == viewerCount ? _self.viewerCount : viewerCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [KickLivestreamInfo].
extension KickLivestreamInfoPatterns on KickLivestreamInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickLivestreamInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickLivestreamInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickLivestreamInfo value)  $default,){
final _that = this;
switch (_that) {
case _KickLivestreamInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickLivestreamInfo value)?  $default,){
final _that = this;
switch (_that) {
case _KickLivestreamInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'is_live')  bool isLive, @JsonKey(name: 'viewer_count')  int? viewerCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickLivestreamInfo() when $default != null:
return $default(_that.isLive,_that.viewerCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'is_live')  bool isLive, @JsonKey(name: 'viewer_count')  int? viewerCount)  $default,) {final _that = this;
switch (_that) {
case _KickLivestreamInfo():
return $default(_that.isLive,_that.viewerCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'is_live')  bool isLive, @JsonKey(name: 'viewer_count')  int? viewerCount)?  $default,) {final _that = this;
switch (_that) {
case _KickLivestreamInfo() when $default != null:
return $default(_that.isLive,_that.viewerCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickLivestreamInfo implements KickLivestreamInfo {
  const _KickLivestreamInfo({@JsonKey(name: 'is_live') this.isLive = false, @JsonKey(name: 'viewer_count') this.viewerCount});
  factory _KickLivestreamInfo.fromJson(Map<String, dynamic> json) => _$KickLivestreamInfoFromJson(json);

@override@JsonKey(name: 'is_live') final  bool isLive;
@override@JsonKey(name: 'viewer_count') final  int? viewerCount;

/// Create a copy of KickLivestreamInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickLivestreamInfoCopyWith<_KickLivestreamInfo> get copyWith => __$KickLivestreamInfoCopyWithImpl<_KickLivestreamInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickLivestreamInfo&&(identical(other.isLive, isLive) || other.isLive == isLive)&&(identical(other.viewerCount, viewerCount) || other.viewerCount == viewerCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isLive,viewerCount);

@override
String toString() {
  return 'KickLivestreamInfo(isLive: $isLive, viewerCount: $viewerCount)';
}


}

/// @nodoc
abstract mixin class _$KickLivestreamInfoCopyWith<$Res> implements $KickLivestreamInfoCopyWith<$Res> {
  factory _$KickLivestreamInfoCopyWith(_KickLivestreamInfo value, $Res Function(_KickLivestreamInfo) _then) = __$KickLivestreamInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'is_live') bool isLive,@JsonKey(name: 'viewer_count') int? viewerCount
});




}
/// @nodoc
class __$KickLivestreamInfoCopyWithImpl<$Res>
    implements _$KickLivestreamInfoCopyWith<$Res> {
  __$KickLivestreamInfoCopyWithImpl(this._self, this._then);

  final _KickLivestreamInfo _self;
  final $Res Function(_KickLivestreamInfo) _then;

/// Create a copy of KickLivestreamInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLive = null,Object? viewerCount = freezed,}) {
  return _then(_KickLivestreamInfo(
isLive: null == isLive ? _self.isLive : isLive // ignore: cast_nullable_to_non_nullable
as bool,viewerCount: freezed == viewerCount ? _self.viewerCount : viewerCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
