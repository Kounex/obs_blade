// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'youtube_chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$YouTubeChatMessage {

 String get id; YouTubeChatMessageSnippet get snippet; YouTubeChatAuthorDetails? get authorDetails;/// Local lifecycle flag — set by the chat store when a `tombstone`
/// arrives for this message (dim + marker, same UX as Twitch);
/// never part of the API JSON.
@JsonKey(includeFromJson: false, includeToJson: false) bool get isTombstoned;
/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeChatMessageCopyWith<YouTubeChatMessage> get copyWith => _$YouTubeChatMessageCopyWithImpl<YouTubeChatMessage>(this as YouTubeChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.snippet, snippet) || other.snippet == snippet)&&(identical(other.authorDetails, authorDetails) || other.authorDetails == authorDetails)&&(identical(other.isTombstoned, isTombstoned) || other.isTombstoned == isTombstoned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,snippet,authorDetails,isTombstoned);

@override
String toString() {
  return 'YouTubeChatMessage(id: $id, snippet: $snippet, authorDetails: $authorDetails, isTombstoned: $isTombstoned)';
}


}

/// @nodoc
abstract mixin class $YouTubeChatMessageCopyWith<$Res>  {
  factory $YouTubeChatMessageCopyWith(YouTubeChatMessage value, $Res Function(YouTubeChatMessage) _then) = _$YouTubeChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, YouTubeChatMessageSnippet snippet, YouTubeChatAuthorDetails? authorDetails,@JsonKey(includeFromJson: false, includeToJson: false) bool isTombstoned
});


$YouTubeChatMessageSnippetCopyWith<$Res> get snippet;$YouTubeChatAuthorDetailsCopyWith<$Res>? get authorDetails;

}
/// @nodoc
class _$YouTubeChatMessageCopyWithImpl<$Res>
    implements $YouTubeChatMessageCopyWith<$Res> {
  _$YouTubeChatMessageCopyWithImpl(this._self, this._then);

  final YouTubeChatMessage _self;
  final $Res Function(YouTubeChatMessage) _then;

/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? snippet = null,Object? authorDetails = freezed,Object? isTombstoned = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,snippet: null == snippet ? _self.snippet : snippet // ignore: cast_nullable_to_non_nullable
as YouTubeChatMessageSnippet,authorDetails: freezed == authorDetails ? _self.authorDetails : authorDetails // ignore: cast_nullable_to_non_nullable
as YouTubeChatAuthorDetails?,isTombstoned: null == isTombstoned ? _self.isTombstoned : isTombstoned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeChatMessageSnippetCopyWith<$Res> get snippet {
  
  return $YouTubeChatMessageSnippetCopyWith<$Res>(_self.snippet, (value) {
    return _then(_self.copyWith(snippet: value));
  });
}/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeChatAuthorDetailsCopyWith<$Res>? get authorDetails {
    if (_self.authorDetails == null) {
    return null;
  }

  return $YouTubeChatAuthorDetailsCopyWith<$Res>(_self.authorDetails!, (value) {
    return _then(_self.copyWith(authorDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [YouTubeChatMessage].
extension YouTubeChatMessagePatterns on YouTubeChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  YouTubeChatMessageSnippet snippet,  YouTubeChatAuthorDetails? authorDetails, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTombstoned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeChatMessage() when $default != null:
return $default(_that.id,_that.snippet,_that.authorDetails,_that.isTombstoned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  YouTubeChatMessageSnippet snippet,  YouTubeChatAuthorDetails? authorDetails, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTombstoned)  $default,) {final _that = this;
switch (_that) {
case _YouTubeChatMessage():
return $default(_that.id,_that.snippet,_that.authorDetails,_that.isTombstoned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  YouTubeChatMessageSnippet snippet,  YouTubeChatAuthorDetails? authorDetails, @JsonKey(includeFromJson: false, includeToJson: false)  bool isTombstoned)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeChatMessage() when $default != null:
return $default(_that.id,_that.snippet,_that.authorDetails,_that.isTombstoned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeChatMessage extends YouTubeChatMessage {
  const _YouTubeChatMessage({required this.id, required this.snippet, this.authorDetails, @JsonKey(includeFromJson: false, includeToJson: false) this.isTombstoned = false}): super._();
  factory _YouTubeChatMessage.fromJson(Map<String, dynamic> json) => _$YouTubeChatMessageFromJson(json);

@override final  String id;
@override final  YouTubeChatMessageSnippet snippet;
@override final  YouTubeChatAuthorDetails? authorDetails;
/// Local lifecycle flag — set by the chat store when a `tombstone`
/// arrives for this message (dim + marker, same UX as Twitch);
/// never part of the API JSON.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool isTombstoned;

/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeChatMessageCopyWith<_YouTubeChatMessage> get copyWith => __$YouTubeChatMessageCopyWithImpl<_YouTubeChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.snippet, snippet) || other.snippet == snippet)&&(identical(other.authorDetails, authorDetails) || other.authorDetails == authorDetails)&&(identical(other.isTombstoned, isTombstoned) || other.isTombstoned == isTombstoned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,snippet,authorDetails,isTombstoned);

@override
String toString() {
  return 'YouTubeChatMessage(id: $id, snippet: $snippet, authorDetails: $authorDetails, isTombstoned: $isTombstoned)';
}


}

/// @nodoc
abstract mixin class _$YouTubeChatMessageCopyWith<$Res> implements $YouTubeChatMessageCopyWith<$Res> {
  factory _$YouTubeChatMessageCopyWith(_YouTubeChatMessage value, $Res Function(_YouTubeChatMessage) _then) = __$YouTubeChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, YouTubeChatMessageSnippet snippet, YouTubeChatAuthorDetails? authorDetails,@JsonKey(includeFromJson: false, includeToJson: false) bool isTombstoned
});


@override $YouTubeChatMessageSnippetCopyWith<$Res> get snippet;@override $YouTubeChatAuthorDetailsCopyWith<$Res>? get authorDetails;

}
/// @nodoc
class __$YouTubeChatMessageCopyWithImpl<$Res>
    implements _$YouTubeChatMessageCopyWith<$Res> {
  __$YouTubeChatMessageCopyWithImpl(this._self, this._then);

  final _YouTubeChatMessage _self;
  final $Res Function(_YouTubeChatMessage) _then;

/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? snippet = null,Object? authorDetails = freezed,Object? isTombstoned = null,}) {
  return _then(_YouTubeChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,snippet: null == snippet ? _self.snippet : snippet // ignore: cast_nullable_to_non_nullable
as YouTubeChatMessageSnippet,authorDetails: freezed == authorDetails ? _self.authorDetails : authorDetails // ignore: cast_nullable_to_non_nullable
as YouTubeChatAuthorDetails?,isTombstoned: null == isTombstoned ? _self.isTombstoned : isTombstoned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeChatMessageSnippetCopyWith<$Res> get snippet {
  
  return $YouTubeChatMessageSnippetCopyWith<$Res>(_self.snippet, (value) {
    return _then(_self.copyWith(snippet: value));
  });
}/// Create a copy of YouTubeChatMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeChatAuthorDetailsCopyWith<$Res>? get authorDetails {
    if (_self.authorDetails == null) {
    return null;
  }

  return $YouTubeChatAuthorDetailsCopyWith<$Res>(_self.authorDetails!, (value) {
    return _then(_self.copyWith(authorDetails: value));
  });
}
}


/// @nodoc
mixin _$YouTubeChatMessageSnippet {

@JsonKey(fromJson: YouTubeChatMessageType.parse) YouTubeChatMessageType get type; String? get liveChatId; String? get authorChannelId; DateTime get publishedAt; bool get hasDisplayContent; String? get displayMessage; YouTubeTextMessageDetails? get textMessageDetails; YouTubeSuperChatDetails? get superChatDetails; YouTubeSuperStickerDetails? get superStickerDetails; YouTubeNewSponsorDetails? get newSponsorDetails; YouTubeMemberMilestoneDetails? get memberMilestoneChatDetails; YouTubeMembershipGiftingDetails? get membershipGiftingDetails; YouTubeGiftMembershipReceivedDetails? get giftMembershipReceivedDetails; YouTubePollDetails? get pollDetails; YouTubeUserBannedDetails? get userBannedDetails;
/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeChatMessageSnippetCopyWith<YouTubeChatMessageSnippet> get copyWith => _$YouTubeChatMessageSnippetCopyWithImpl<YouTubeChatMessageSnippet>(this as YouTubeChatMessageSnippet, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeChatMessageSnippet&&(identical(other.type, type) || other.type == type)&&(identical(other.liveChatId, liveChatId) || other.liveChatId == liveChatId)&&(identical(other.authorChannelId, authorChannelId) || other.authorChannelId == authorChannelId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.hasDisplayContent, hasDisplayContent) || other.hasDisplayContent == hasDisplayContent)&&(identical(other.displayMessage, displayMessage) || other.displayMessage == displayMessage)&&(identical(other.textMessageDetails, textMessageDetails) || other.textMessageDetails == textMessageDetails)&&(identical(other.superChatDetails, superChatDetails) || other.superChatDetails == superChatDetails)&&(identical(other.superStickerDetails, superStickerDetails) || other.superStickerDetails == superStickerDetails)&&(identical(other.newSponsorDetails, newSponsorDetails) || other.newSponsorDetails == newSponsorDetails)&&(identical(other.memberMilestoneChatDetails, memberMilestoneChatDetails) || other.memberMilestoneChatDetails == memberMilestoneChatDetails)&&(identical(other.membershipGiftingDetails, membershipGiftingDetails) || other.membershipGiftingDetails == membershipGiftingDetails)&&(identical(other.giftMembershipReceivedDetails, giftMembershipReceivedDetails) || other.giftMembershipReceivedDetails == giftMembershipReceivedDetails)&&(identical(other.pollDetails, pollDetails) || other.pollDetails == pollDetails)&&(identical(other.userBannedDetails, userBannedDetails) || other.userBannedDetails == userBannedDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,liveChatId,authorChannelId,publishedAt,hasDisplayContent,displayMessage,textMessageDetails,superChatDetails,superStickerDetails,newSponsorDetails,memberMilestoneChatDetails,membershipGiftingDetails,giftMembershipReceivedDetails,pollDetails,userBannedDetails);

@override
String toString() {
  return 'YouTubeChatMessageSnippet(type: $type, liveChatId: $liveChatId, authorChannelId: $authorChannelId, publishedAt: $publishedAt, hasDisplayContent: $hasDisplayContent, displayMessage: $displayMessage, textMessageDetails: $textMessageDetails, superChatDetails: $superChatDetails, superStickerDetails: $superStickerDetails, newSponsorDetails: $newSponsorDetails, memberMilestoneChatDetails: $memberMilestoneChatDetails, membershipGiftingDetails: $membershipGiftingDetails, giftMembershipReceivedDetails: $giftMembershipReceivedDetails, pollDetails: $pollDetails, userBannedDetails: $userBannedDetails)';
}


}

/// @nodoc
abstract mixin class $YouTubeChatMessageSnippetCopyWith<$Res>  {
  factory $YouTubeChatMessageSnippetCopyWith(YouTubeChatMessageSnippet value, $Res Function(YouTubeChatMessageSnippet) _then) = _$YouTubeChatMessageSnippetCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: YouTubeChatMessageType.parse) YouTubeChatMessageType type, String? liveChatId, String? authorChannelId, DateTime publishedAt, bool hasDisplayContent, String? displayMessage, YouTubeTextMessageDetails? textMessageDetails, YouTubeSuperChatDetails? superChatDetails, YouTubeSuperStickerDetails? superStickerDetails, YouTubeNewSponsorDetails? newSponsorDetails, YouTubeMemberMilestoneDetails? memberMilestoneChatDetails, YouTubeMembershipGiftingDetails? membershipGiftingDetails, YouTubeGiftMembershipReceivedDetails? giftMembershipReceivedDetails, YouTubePollDetails? pollDetails, YouTubeUserBannedDetails? userBannedDetails
});


$YouTubeTextMessageDetailsCopyWith<$Res>? get textMessageDetails;$YouTubeSuperChatDetailsCopyWith<$Res>? get superChatDetails;$YouTubeSuperStickerDetailsCopyWith<$Res>? get superStickerDetails;$YouTubeNewSponsorDetailsCopyWith<$Res>? get newSponsorDetails;$YouTubeMemberMilestoneDetailsCopyWith<$Res>? get memberMilestoneChatDetails;$YouTubeMembershipGiftingDetailsCopyWith<$Res>? get membershipGiftingDetails;$YouTubeGiftMembershipReceivedDetailsCopyWith<$Res>? get giftMembershipReceivedDetails;$YouTubePollDetailsCopyWith<$Res>? get pollDetails;$YouTubeUserBannedDetailsCopyWith<$Res>? get userBannedDetails;

}
/// @nodoc
class _$YouTubeChatMessageSnippetCopyWithImpl<$Res>
    implements $YouTubeChatMessageSnippetCopyWith<$Res> {
  _$YouTubeChatMessageSnippetCopyWithImpl(this._self, this._then);

  final YouTubeChatMessageSnippet _self;
  final $Res Function(YouTubeChatMessageSnippet) _then;

/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? liveChatId = freezed,Object? authorChannelId = freezed,Object? publishedAt = null,Object? hasDisplayContent = null,Object? displayMessage = freezed,Object? textMessageDetails = freezed,Object? superChatDetails = freezed,Object? superStickerDetails = freezed,Object? newSponsorDetails = freezed,Object? memberMilestoneChatDetails = freezed,Object? membershipGiftingDetails = freezed,Object? giftMembershipReceivedDetails = freezed,Object? pollDetails = freezed,Object? userBannedDetails = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as YouTubeChatMessageType,liveChatId: freezed == liveChatId ? _self.liveChatId : liveChatId // ignore: cast_nullable_to_non_nullable
as String?,authorChannelId: freezed == authorChannelId ? _self.authorChannelId : authorChannelId // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasDisplayContent: null == hasDisplayContent ? _self.hasDisplayContent : hasDisplayContent // ignore: cast_nullable_to_non_nullable
as bool,displayMessage: freezed == displayMessage ? _self.displayMessage : displayMessage // ignore: cast_nullable_to_non_nullable
as String?,textMessageDetails: freezed == textMessageDetails ? _self.textMessageDetails : textMessageDetails // ignore: cast_nullable_to_non_nullable
as YouTubeTextMessageDetails?,superChatDetails: freezed == superChatDetails ? _self.superChatDetails : superChatDetails // ignore: cast_nullable_to_non_nullable
as YouTubeSuperChatDetails?,superStickerDetails: freezed == superStickerDetails ? _self.superStickerDetails : superStickerDetails // ignore: cast_nullable_to_non_nullable
as YouTubeSuperStickerDetails?,newSponsorDetails: freezed == newSponsorDetails ? _self.newSponsorDetails : newSponsorDetails // ignore: cast_nullable_to_non_nullable
as YouTubeNewSponsorDetails?,memberMilestoneChatDetails: freezed == memberMilestoneChatDetails ? _self.memberMilestoneChatDetails : memberMilestoneChatDetails // ignore: cast_nullable_to_non_nullable
as YouTubeMemberMilestoneDetails?,membershipGiftingDetails: freezed == membershipGiftingDetails ? _self.membershipGiftingDetails : membershipGiftingDetails // ignore: cast_nullable_to_non_nullable
as YouTubeMembershipGiftingDetails?,giftMembershipReceivedDetails: freezed == giftMembershipReceivedDetails ? _self.giftMembershipReceivedDetails : giftMembershipReceivedDetails // ignore: cast_nullable_to_non_nullable
as YouTubeGiftMembershipReceivedDetails?,pollDetails: freezed == pollDetails ? _self.pollDetails : pollDetails // ignore: cast_nullable_to_non_nullable
as YouTubePollDetails?,userBannedDetails: freezed == userBannedDetails ? _self.userBannedDetails : userBannedDetails // ignore: cast_nullable_to_non_nullable
as YouTubeUserBannedDetails?,
  ));
}
/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeTextMessageDetailsCopyWith<$Res>? get textMessageDetails {
    if (_self.textMessageDetails == null) {
    return null;
  }

  return $YouTubeTextMessageDetailsCopyWith<$Res>(_self.textMessageDetails!, (value) {
    return _then(_self.copyWith(textMessageDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeSuperChatDetailsCopyWith<$Res>? get superChatDetails {
    if (_self.superChatDetails == null) {
    return null;
  }

  return $YouTubeSuperChatDetailsCopyWith<$Res>(_self.superChatDetails!, (value) {
    return _then(_self.copyWith(superChatDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeSuperStickerDetailsCopyWith<$Res>? get superStickerDetails {
    if (_self.superStickerDetails == null) {
    return null;
  }

  return $YouTubeSuperStickerDetailsCopyWith<$Res>(_self.superStickerDetails!, (value) {
    return _then(_self.copyWith(superStickerDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeNewSponsorDetailsCopyWith<$Res>? get newSponsorDetails {
    if (_self.newSponsorDetails == null) {
    return null;
  }

  return $YouTubeNewSponsorDetailsCopyWith<$Res>(_self.newSponsorDetails!, (value) {
    return _then(_self.copyWith(newSponsorDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeMemberMilestoneDetailsCopyWith<$Res>? get memberMilestoneChatDetails {
    if (_self.memberMilestoneChatDetails == null) {
    return null;
  }

  return $YouTubeMemberMilestoneDetailsCopyWith<$Res>(_self.memberMilestoneChatDetails!, (value) {
    return _then(_self.copyWith(memberMilestoneChatDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeMembershipGiftingDetailsCopyWith<$Res>? get membershipGiftingDetails {
    if (_self.membershipGiftingDetails == null) {
    return null;
  }

  return $YouTubeMembershipGiftingDetailsCopyWith<$Res>(_self.membershipGiftingDetails!, (value) {
    return _then(_self.copyWith(membershipGiftingDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeGiftMembershipReceivedDetailsCopyWith<$Res>? get giftMembershipReceivedDetails {
    if (_self.giftMembershipReceivedDetails == null) {
    return null;
  }

  return $YouTubeGiftMembershipReceivedDetailsCopyWith<$Res>(_self.giftMembershipReceivedDetails!, (value) {
    return _then(_self.copyWith(giftMembershipReceivedDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubePollDetailsCopyWith<$Res>? get pollDetails {
    if (_self.pollDetails == null) {
    return null;
  }

  return $YouTubePollDetailsCopyWith<$Res>(_self.pollDetails!, (value) {
    return _then(_self.copyWith(pollDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeUserBannedDetailsCopyWith<$Res>? get userBannedDetails {
    if (_self.userBannedDetails == null) {
    return null;
  }

  return $YouTubeUserBannedDetailsCopyWith<$Res>(_self.userBannedDetails!, (value) {
    return _then(_self.copyWith(userBannedDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [YouTubeChatMessageSnippet].
extension YouTubeChatMessageSnippetPatterns on YouTubeChatMessageSnippet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeChatMessageSnippet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeChatMessageSnippet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeChatMessageSnippet value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeChatMessageSnippet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeChatMessageSnippet value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeChatMessageSnippet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: YouTubeChatMessageType.parse)  YouTubeChatMessageType type,  String? liveChatId,  String? authorChannelId,  DateTime publishedAt,  bool hasDisplayContent,  String? displayMessage,  YouTubeTextMessageDetails? textMessageDetails,  YouTubeSuperChatDetails? superChatDetails,  YouTubeSuperStickerDetails? superStickerDetails,  YouTubeNewSponsorDetails? newSponsorDetails,  YouTubeMemberMilestoneDetails? memberMilestoneChatDetails,  YouTubeMembershipGiftingDetails? membershipGiftingDetails,  YouTubeGiftMembershipReceivedDetails? giftMembershipReceivedDetails,  YouTubePollDetails? pollDetails,  YouTubeUserBannedDetails? userBannedDetails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeChatMessageSnippet() when $default != null:
return $default(_that.type,_that.liveChatId,_that.authorChannelId,_that.publishedAt,_that.hasDisplayContent,_that.displayMessage,_that.textMessageDetails,_that.superChatDetails,_that.superStickerDetails,_that.newSponsorDetails,_that.memberMilestoneChatDetails,_that.membershipGiftingDetails,_that.giftMembershipReceivedDetails,_that.pollDetails,_that.userBannedDetails);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: YouTubeChatMessageType.parse)  YouTubeChatMessageType type,  String? liveChatId,  String? authorChannelId,  DateTime publishedAt,  bool hasDisplayContent,  String? displayMessage,  YouTubeTextMessageDetails? textMessageDetails,  YouTubeSuperChatDetails? superChatDetails,  YouTubeSuperStickerDetails? superStickerDetails,  YouTubeNewSponsorDetails? newSponsorDetails,  YouTubeMemberMilestoneDetails? memberMilestoneChatDetails,  YouTubeMembershipGiftingDetails? membershipGiftingDetails,  YouTubeGiftMembershipReceivedDetails? giftMembershipReceivedDetails,  YouTubePollDetails? pollDetails,  YouTubeUserBannedDetails? userBannedDetails)  $default,) {final _that = this;
switch (_that) {
case _YouTubeChatMessageSnippet():
return $default(_that.type,_that.liveChatId,_that.authorChannelId,_that.publishedAt,_that.hasDisplayContent,_that.displayMessage,_that.textMessageDetails,_that.superChatDetails,_that.superStickerDetails,_that.newSponsorDetails,_that.memberMilestoneChatDetails,_that.membershipGiftingDetails,_that.giftMembershipReceivedDetails,_that.pollDetails,_that.userBannedDetails);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: YouTubeChatMessageType.parse)  YouTubeChatMessageType type,  String? liveChatId,  String? authorChannelId,  DateTime publishedAt,  bool hasDisplayContent,  String? displayMessage,  YouTubeTextMessageDetails? textMessageDetails,  YouTubeSuperChatDetails? superChatDetails,  YouTubeSuperStickerDetails? superStickerDetails,  YouTubeNewSponsorDetails? newSponsorDetails,  YouTubeMemberMilestoneDetails? memberMilestoneChatDetails,  YouTubeMembershipGiftingDetails? membershipGiftingDetails,  YouTubeGiftMembershipReceivedDetails? giftMembershipReceivedDetails,  YouTubePollDetails? pollDetails,  YouTubeUserBannedDetails? userBannedDetails)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeChatMessageSnippet() when $default != null:
return $default(_that.type,_that.liveChatId,_that.authorChannelId,_that.publishedAt,_that.hasDisplayContent,_that.displayMessage,_that.textMessageDetails,_that.superChatDetails,_that.superStickerDetails,_that.newSponsorDetails,_that.memberMilestoneChatDetails,_that.membershipGiftingDetails,_that.giftMembershipReceivedDetails,_that.pollDetails,_that.userBannedDetails);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeChatMessageSnippet implements YouTubeChatMessageSnippet {
  const _YouTubeChatMessageSnippet({@JsonKey(fromJson: YouTubeChatMessageType.parse) required this.type, this.liveChatId, this.authorChannelId, required this.publishedAt, this.hasDisplayContent = false, this.displayMessage, this.textMessageDetails, this.superChatDetails, this.superStickerDetails, this.newSponsorDetails, this.memberMilestoneChatDetails, this.membershipGiftingDetails, this.giftMembershipReceivedDetails, this.pollDetails, this.userBannedDetails});
  factory _YouTubeChatMessageSnippet.fromJson(Map<String, dynamic> json) => _$YouTubeChatMessageSnippetFromJson(json);

@override@JsonKey(fromJson: YouTubeChatMessageType.parse) final  YouTubeChatMessageType type;
@override final  String? liveChatId;
@override final  String? authorChannelId;
@override final  DateTime publishedAt;
@override@JsonKey() final  bool hasDisplayContent;
@override final  String? displayMessage;
@override final  YouTubeTextMessageDetails? textMessageDetails;
@override final  YouTubeSuperChatDetails? superChatDetails;
@override final  YouTubeSuperStickerDetails? superStickerDetails;
@override final  YouTubeNewSponsorDetails? newSponsorDetails;
@override final  YouTubeMemberMilestoneDetails? memberMilestoneChatDetails;
@override final  YouTubeMembershipGiftingDetails? membershipGiftingDetails;
@override final  YouTubeGiftMembershipReceivedDetails? giftMembershipReceivedDetails;
@override final  YouTubePollDetails? pollDetails;
@override final  YouTubeUserBannedDetails? userBannedDetails;

/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeChatMessageSnippetCopyWith<_YouTubeChatMessageSnippet> get copyWith => __$YouTubeChatMessageSnippetCopyWithImpl<_YouTubeChatMessageSnippet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeChatMessageSnippet&&(identical(other.type, type) || other.type == type)&&(identical(other.liveChatId, liveChatId) || other.liveChatId == liveChatId)&&(identical(other.authorChannelId, authorChannelId) || other.authorChannelId == authorChannelId)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.hasDisplayContent, hasDisplayContent) || other.hasDisplayContent == hasDisplayContent)&&(identical(other.displayMessage, displayMessage) || other.displayMessage == displayMessage)&&(identical(other.textMessageDetails, textMessageDetails) || other.textMessageDetails == textMessageDetails)&&(identical(other.superChatDetails, superChatDetails) || other.superChatDetails == superChatDetails)&&(identical(other.superStickerDetails, superStickerDetails) || other.superStickerDetails == superStickerDetails)&&(identical(other.newSponsorDetails, newSponsorDetails) || other.newSponsorDetails == newSponsorDetails)&&(identical(other.memberMilestoneChatDetails, memberMilestoneChatDetails) || other.memberMilestoneChatDetails == memberMilestoneChatDetails)&&(identical(other.membershipGiftingDetails, membershipGiftingDetails) || other.membershipGiftingDetails == membershipGiftingDetails)&&(identical(other.giftMembershipReceivedDetails, giftMembershipReceivedDetails) || other.giftMembershipReceivedDetails == giftMembershipReceivedDetails)&&(identical(other.pollDetails, pollDetails) || other.pollDetails == pollDetails)&&(identical(other.userBannedDetails, userBannedDetails) || other.userBannedDetails == userBannedDetails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,liveChatId,authorChannelId,publishedAt,hasDisplayContent,displayMessage,textMessageDetails,superChatDetails,superStickerDetails,newSponsorDetails,memberMilestoneChatDetails,membershipGiftingDetails,giftMembershipReceivedDetails,pollDetails,userBannedDetails);

@override
String toString() {
  return 'YouTubeChatMessageSnippet(type: $type, liveChatId: $liveChatId, authorChannelId: $authorChannelId, publishedAt: $publishedAt, hasDisplayContent: $hasDisplayContent, displayMessage: $displayMessage, textMessageDetails: $textMessageDetails, superChatDetails: $superChatDetails, superStickerDetails: $superStickerDetails, newSponsorDetails: $newSponsorDetails, memberMilestoneChatDetails: $memberMilestoneChatDetails, membershipGiftingDetails: $membershipGiftingDetails, giftMembershipReceivedDetails: $giftMembershipReceivedDetails, pollDetails: $pollDetails, userBannedDetails: $userBannedDetails)';
}


}

/// @nodoc
abstract mixin class _$YouTubeChatMessageSnippetCopyWith<$Res> implements $YouTubeChatMessageSnippetCopyWith<$Res> {
  factory _$YouTubeChatMessageSnippetCopyWith(_YouTubeChatMessageSnippet value, $Res Function(_YouTubeChatMessageSnippet) _then) = __$YouTubeChatMessageSnippetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: YouTubeChatMessageType.parse) YouTubeChatMessageType type, String? liveChatId, String? authorChannelId, DateTime publishedAt, bool hasDisplayContent, String? displayMessage, YouTubeTextMessageDetails? textMessageDetails, YouTubeSuperChatDetails? superChatDetails, YouTubeSuperStickerDetails? superStickerDetails, YouTubeNewSponsorDetails? newSponsorDetails, YouTubeMemberMilestoneDetails? memberMilestoneChatDetails, YouTubeMembershipGiftingDetails? membershipGiftingDetails, YouTubeGiftMembershipReceivedDetails? giftMembershipReceivedDetails, YouTubePollDetails? pollDetails, YouTubeUserBannedDetails? userBannedDetails
});


@override $YouTubeTextMessageDetailsCopyWith<$Res>? get textMessageDetails;@override $YouTubeSuperChatDetailsCopyWith<$Res>? get superChatDetails;@override $YouTubeSuperStickerDetailsCopyWith<$Res>? get superStickerDetails;@override $YouTubeNewSponsorDetailsCopyWith<$Res>? get newSponsorDetails;@override $YouTubeMemberMilestoneDetailsCopyWith<$Res>? get memberMilestoneChatDetails;@override $YouTubeMembershipGiftingDetailsCopyWith<$Res>? get membershipGiftingDetails;@override $YouTubeGiftMembershipReceivedDetailsCopyWith<$Res>? get giftMembershipReceivedDetails;@override $YouTubePollDetailsCopyWith<$Res>? get pollDetails;@override $YouTubeUserBannedDetailsCopyWith<$Res>? get userBannedDetails;

}
/// @nodoc
class __$YouTubeChatMessageSnippetCopyWithImpl<$Res>
    implements _$YouTubeChatMessageSnippetCopyWith<$Res> {
  __$YouTubeChatMessageSnippetCopyWithImpl(this._self, this._then);

  final _YouTubeChatMessageSnippet _self;
  final $Res Function(_YouTubeChatMessageSnippet) _then;

/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? liveChatId = freezed,Object? authorChannelId = freezed,Object? publishedAt = null,Object? hasDisplayContent = null,Object? displayMessage = freezed,Object? textMessageDetails = freezed,Object? superChatDetails = freezed,Object? superStickerDetails = freezed,Object? newSponsorDetails = freezed,Object? memberMilestoneChatDetails = freezed,Object? membershipGiftingDetails = freezed,Object? giftMembershipReceivedDetails = freezed,Object? pollDetails = freezed,Object? userBannedDetails = freezed,}) {
  return _then(_YouTubeChatMessageSnippet(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as YouTubeChatMessageType,liveChatId: freezed == liveChatId ? _self.liveChatId : liveChatId // ignore: cast_nullable_to_non_nullable
as String?,authorChannelId: freezed == authorChannelId ? _self.authorChannelId : authorChannelId // ignore: cast_nullable_to_non_nullable
as String?,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,hasDisplayContent: null == hasDisplayContent ? _self.hasDisplayContent : hasDisplayContent // ignore: cast_nullable_to_non_nullable
as bool,displayMessage: freezed == displayMessage ? _self.displayMessage : displayMessage // ignore: cast_nullable_to_non_nullable
as String?,textMessageDetails: freezed == textMessageDetails ? _self.textMessageDetails : textMessageDetails // ignore: cast_nullable_to_non_nullable
as YouTubeTextMessageDetails?,superChatDetails: freezed == superChatDetails ? _self.superChatDetails : superChatDetails // ignore: cast_nullable_to_non_nullable
as YouTubeSuperChatDetails?,superStickerDetails: freezed == superStickerDetails ? _self.superStickerDetails : superStickerDetails // ignore: cast_nullable_to_non_nullable
as YouTubeSuperStickerDetails?,newSponsorDetails: freezed == newSponsorDetails ? _self.newSponsorDetails : newSponsorDetails // ignore: cast_nullable_to_non_nullable
as YouTubeNewSponsorDetails?,memberMilestoneChatDetails: freezed == memberMilestoneChatDetails ? _self.memberMilestoneChatDetails : memberMilestoneChatDetails // ignore: cast_nullable_to_non_nullable
as YouTubeMemberMilestoneDetails?,membershipGiftingDetails: freezed == membershipGiftingDetails ? _self.membershipGiftingDetails : membershipGiftingDetails // ignore: cast_nullable_to_non_nullable
as YouTubeMembershipGiftingDetails?,giftMembershipReceivedDetails: freezed == giftMembershipReceivedDetails ? _self.giftMembershipReceivedDetails : giftMembershipReceivedDetails // ignore: cast_nullable_to_non_nullable
as YouTubeGiftMembershipReceivedDetails?,pollDetails: freezed == pollDetails ? _self.pollDetails : pollDetails // ignore: cast_nullable_to_non_nullable
as YouTubePollDetails?,userBannedDetails: freezed == userBannedDetails ? _self.userBannedDetails : userBannedDetails // ignore: cast_nullable_to_non_nullable
as YouTubeUserBannedDetails?,
  ));
}

/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeTextMessageDetailsCopyWith<$Res>? get textMessageDetails {
    if (_self.textMessageDetails == null) {
    return null;
  }

  return $YouTubeTextMessageDetailsCopyWith<$Res>(_self.textMessageDetails!, (value) {
    return _then(_self.copyWith(textMessageDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeSuperChatDetailsCopyWith<$Res>? get superChatDetails {
    if (_self.superChatDetails == null) {
    return null;
  }

  return $YouTubeSuperChatDetailsCopyWith<$Res>(_self.superChatDetails!, (value) {
    return _then(_self.copyWith(superChatDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeSuperStickerDetailsCopyWith<$Res>? get superStickerDetails {
    if (_self.superStickerDetails == null) {
    return null;
  }

  return $YouTubeSuperStickerDetailsCopyWith<$Res>(_self.superStickerDetails!, (value) {
    return _then(_self.copyWith(superStickerDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeNewSponsorDetailsCopyWith<$Res>? get newSponsorDetails {
    if (_self.newSponsorDetails == null) {
    return null;
  }

  return $YouTubeNewSponsorDetailsCopyWith<$Res>(_self.newSponsorDetails!, (value) {
    return _then(_self.copyWith(newSponsorDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeMemberMilestoneDetailsCopyWith<$Res>? get memberMilestoneChatDetails {
    if (_self.memberMilestoneChatDetails == null) {
    return null;
  }

  return $YouTubeMemberMilestoneDetailsCopyWith<$Res>(_self.memberMilestoneChatDetails!, (value) {
    return _then(_self.copyWith(memberMilestoneChatDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeMembershipGiftingDetailsCopyWith<$Res>? get membershipGiftingDetails {
    if (_self.membershipGiftingDetails == null) {
    return null;
  }

  return $YouTubeMembershipGiftingDetailsCopyWith<$Res>(_self.membershipGiftingDetails!, (value) {
    return _then(_self.copyWith(membershipGiftingDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeGiftMembershipReceivedDetailsCopyWith<$Res>? get giftMembershipReceivedDetails {
    if (_self.giftMembershipReceivedDetails == null) {
    return null;
  }

  return $YouTubeGiftMembershipReceivedDetailsCopyWith<$Res>(_self.giftMembershipReceivedDetails!, (value) {
    return _then(_self.copyWith(giftMembershipReceivedDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubePollDetailsCopyWith<$Res>? get pollDetails {
    if (_self.pollDetails == null) {
    return null;
  }

  return $YouTubePollDetailsCopyWith<$Res>(_self.pollDetails!, (value) {
    return _then(_self.copyWith(pollDetails: value));
  });
}/// Create a copy of YouTubeChatMessageSnippet
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeUserBannedDetailsCopyWith<$Res>? get userBannedDetails {
    if (_self.userBannedDetails == null) {
    return null;
  }

  return $YouTubeUserBannedDetailsCopyWith<$Res>(_self.userBannedDetails!, (value) {
    return _then(_self.copyWith(userBannedDetails: value));
  });
}
}


/// @nodoc
mixin _$YouTubeChatAuthorDetails {

 String? get channelId; String? get channelUrl; String? get displayName; String? get profileImageUrl; bool get isVerified; bool get isChatOwner; bool get isChatSponsor; bool get isChatModerator;
/// Create a copy of YouTubeChatAuthorDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeChatAuthorDetailsCopyWith<YouTubeChatAuthorDetails> get copyWith => _$YouTubeChatAuthorDetailsCopyWithImpl<YouTubeChatAuthorDetails>(this as YouTubeChatAuthorDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeChatAuthorDetails&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelUrl, channelUrl) || other.channelUrl == channelUrl)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isChatOwner, isChatOwner) || other.isChatOwner == isChatOwner)&&(identical(other.isChatSponsor, isChatSponsor) || other.isChatSponsor == isChatSponsor)&&(identical(other.isChatModerator, isChatModerator) || other.isChatModerator == isChatModerator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,channelUrl,displayName,profileImageUrl,isVerified,isChatOwner,isChatSponsor,isChatModerator);

@override
String toString() {
  return 'YouTubeChatAuthorDetails(channelId: $channelId, channelUrl: $channelUrl, displayName: $displayName, profileImageUrl: $profileImageUrl, isVerified: $isVerified, isChatOwner: $isChatOwner, isChatSponsor: $isChatSponsor, isChatModerator: $isChatModerator)';
}


}

/// @nodoc
abstract mixin class $YouTubeChatAuthorDetailsCopyWith<$Res>  {
  factory $YouTubeChatAuthorDetailsCopyWith(YouTubeChatAuthorDetails value, $Res Function(YouTubeChatAuthorDetails) _then) = _$YouTubeChatAuthorDetailsCopyWithImpl;
@useResult
$Res call({
 String? channelId, String? channelUrl, String? displayName, String? profileImageUrl, bool isVerified, bool isChatOwner, bool isChatSponsor, bool isChatModerator
});




}
/// @nodoc
class _$YouTubeChatAuthorDetailsCopyWithImpl<$Res>
    implements $YouTubeChatAuthorDetailsCopyWith<$Res> {
  _$YouTubeChatAuthorDetailsCopyWithImpl(this._self, this._then);

  final YouTubeChatAuthorDetails _self;
  final $Res Function(YouTubeChatAuthorDetails) _then;

/// Create a copy of YouTubeChatAuthorDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channelId = freezed,Object? channelUrl = freezed,Object? displayName = freezed,Object? profileImageUrl = freezed,Object? isVerified = null,Object? isChatOwner = null,Object? isChatSponsor = null,Object? isChatModerator = null,}) {
  return _then(_self.copyWith(
channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,channelUrl: freezed == channelUrl ? _self.channelUrl : channelUrl // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isChatOwner: null == isChatOwner ? _self.isChatOwner : isChatOwner // ignore: cast_nullable_to_non_nullable
as bool,isChatSponsor: null == isChatSponsor ? _self.isChatSponsor : isChatSponsor // ignore: cast_nullable_to_non_nullable
as bool,isChatModerator: null == isChatModerator ? _self.isChatModerator : isChatModerator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeChatAuthorDetails].
extension YouTubeChatAuthorDetailsPatterns on YouTubeChatAuthorDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeChatAuthorDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeChatAuthorDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeChatAuthorDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeChatAuthorDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeChatAuthorDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeChatAuthorDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? channelId,  String? channelUrl,  String? displayName,  String? profileImageUrl,  bool isVerified,  bool isChatOwner,  bool isChatSponsor,  bool isChatModerator)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeChatAuthorDetails() when $default != null:
return $default(_that.channelId,_that.channelUrl,_that.displayName,_that.profileImageUrl,_that.isVerified,_that.isChatOwner,_that.isChatSponsor,_that.isChatModerator);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? channelId,  String? channelUrl,  String? displayName,  String? profileImageUrl,  bool isVerified,  bool isChatOwner,  bool isChatSponsor,  bool isChatModerator)  $default,) {final _that = this;
switch (_that) {
case _YouTubeChatAuthorDetails():
return $default(_that.channelId,_that.channelUrl,_that.displayName,_that.profileImageUrl,_that.isVerified,_that.isChatOwner,_that.isChatSponsor,_that.isChatModerator);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? channelId,  String? channelUrl,  String? displayName,  String? profileImageUrl,  bool isVerified,  bool isChatOwner,  bool isChatSponsor,  bool isChatModerator)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeChatAuthorDetails() when $default != null:
return $default(_that.channelId,_that.channelUrl,_that.displayName,_that.profileImageUrl,_that.isVerified,_that.isChatOwner,_that.isChatSponsor,_that.isChatModerator);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeChatAuthorDetails implements YouTubeChatAuthorDetails {
  const _YouTubeChatAuthorDetails({this.channelId, this.channelUrl, this.displayName, this.profileImageUrl, this.isVerified = false, this.isChatOwner = false, this.isChatSponsor = false, this.isChatModerator = false});
  factory _YouTubeChatAuthorDetails.fromJson(Map<String, dynamic> json) => _$YouTubeChatAuthorDetailsFromJson(json);

@override final  String? channelId;
@override final  String? channelUrl;
@override final  String? displayName;
@override final  String? profileImageUrl;
@override@JsonKey() final  bool isVerified;
@override@JsonKey() final  bool isChatOwner;
@override@JsonKey() final  bool isChatSponsor;
@override@JsonKey() final  bool isChatModerator;

/// Create a copy of YouTubeChatAuthorDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeChatAuthorDetailsCopyWith<_YouTubeChatAuthorDetails> get copyWith => __$YouTubeChatAuthorDetailsCopyWithImpl<_YouTubeChatAuthorDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeChatAuthorDetails&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelUrl, channelUrl) || other.channelUrl == channelUrl)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.isChatOwner, isChatOwner) || other.isChatOwner == isChatOwner)&&(identical(other.isChatSponsor, isChatSponsor) || other.isChatSponsor == isChatSponsor)&&(identical(other.isChatModerator, isChatModerator) || other.isChatModerator == isChatModerator));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,channelUrl,displayName,profileImageUrl,isVerified,isChatOwner,isChatSponsor,isChatModerator);

@override
String toString() {
  return 'YouTubeChatAuthorDetails(channelId: $channelId, channelUrl: $channelUrl, displayName: $displayName, profileImageUrl: $profileImageUrl, isVerified: $isVerified, isChatOwner: $isChatOwner, isChatSponsor: $isChatSponsor, isChatModerator: $isChatModerator)';
}


}

/// @nodoc
abstract mixin class _$YouTubeChatAuthorDetailsCopyWith<$Res> implements $YouTubeChatAuthorDetailsCopyWith<$Res> {
  factory _$YouTubeChatAuthorDetailsCopyWith(_YouTubeChatAuthorDetails value, $Res Function(_YouTubeChatAuthorDetails) _then) = __$YouTubeChatAuthorDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? channelId, String? channelUrl, String? displayName, String? profileImageUrl, bool isVerified, bool isChatOwner, bool isChatSponsor, bool isChatModerator
});




}
/// @nodoc
class __$YouTubeChatAuthorDetailsCopyWithImpl<$Res>
    implements _$YouTubeChatAuthorDetailsCopyWith<$Res> {
  __$YouTubeChatAuthorDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeChatAuthorDetails _self;
  final $Res Function(_YouTubeChatAuthorDetails) _then;

/// Create a copy of YouTubeChatAuthorDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channelId = freezed,Object? channelUrl = freezed,Object? displayName = freezed,Object? profileImageUrl = freezed,Object? isVerified = null,Object? isChatOwner = null,Object? isChatSponsor = null,Object? isChatModerator = null,}) {
  return _then(_YouTubeChatAuthorDetails(
channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,channelUrl: freezed == channelUrl ? _self.channelUrl : channelUrl // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,isChatOwner: null == isChatOwner ? _self.isChatOwner : isChatOwner // ignore: cast_nullable_to_non_nullable
as bool,isChatSponsor: null == isChatSponsor ? _self.isChatSponsor : isChatSponsor // ignore: cast_nullable_to_non_nullable
as bool,isChatModerator: null == isChatModerator ? _self.isChatModerator : isChatModerator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$YouTubeTextMessageDetails {

 String get messageText;
/// Create a copy of YouTubeTextMessageDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeTextMessageDetailsCopyWith<YouTubeTextMessageDetails> get copyWith => _$YouTubeTextMessageDetailsCopyWithImpl<YouTubeTextMessageDetails>(this as YouTubeTextMessageDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeTextMessageDetails&&(identical(other.messageText, messageText) || other.messageText == messageText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageText);

@override
String toString() {
  return 'YouTubeTextMessageDetails(messageText: $messageText)';
}


}

/// @nodoc
abstract mixin class $YouTubeTextMessageDetailsCopyWith<$Res>  {
  factory $YouTubeTextMessageDetailsCopyWith(YouTubeTextMessageDetails value, $Res Function(YouTubeTextMessageDetails) _then) = _$YouTubeTextMessageDetailsCopyWithImpl;
@useResult
$Res call({
 String messageText
});




}
/// @nodoc
class _$YouTubeTextMessageDetailsCopyWithImpl<$Res>
    implements $YouTubeTextMessageDetailsCopyWith<$Res> {
  _$YouTubeTextMessageDetailsCopyWithImpl(this._self, this._then);

  final YouTubeTextMessageDetails _self;
  final $Res Function(YouTubeTextMessageDetails) _then;

/// Create a copy of YouTubeTextMessageDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageText = null,}) {
  return _then(_self.copyWith(
messageText: null == messageText ? _self.messageText : messageText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeTextMessageDetails].
extension YouTubeTextMessageDetailsPatterns on YouTubeTextMessageDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeTextMessageDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeTextMessageDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeTextMessageDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeTextMessageDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeTextMessageDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeTextMessageDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeTextMessageDetails() when $default != null:
return $default(_that.messageText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageText)  $default,) {final _that = this;
switch (_that) {
case _YouTubeTextMessageDetails():
return $default(_that.messageText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageText)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeTextMessageDetails() when $default != null:
return $default(_that.messageText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeTextMessageDetails implements YouTubeTextMessageDetails {
  const _YouTubeTextMessageDetails({required this.messageText});
  factory _YouTubeTextMessageDetails.fromJson(Map<String, dynamic> json) => _$YouTubeTextMessageDetailsFromJson(json);

@override final  String messageText;

/// Create a copy of YouTubeTextMessageDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeTextMessageDetailsCopyWith<_YouTubeTextMessageDetails> get copyWith => __$YouTubeTextMessageDetailsCopyWithImpl<_YouTubeTextMessageDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeTextMessageDetails&&(identical(other.messageText, messageText) || other.messageText == messageText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageText);

@override
String toString() {
  return 'YouTubeTextMessageDetails(messageText: $messageText)';
}


}

/// @nodoc
abstract mixin class _$YouTubeTextMessageDetailsCopyWith<$Res> implements $YouTubeTextMessageDetailsCopyWith<$Res> {
  factory _$YouTubeTextMessageDetailsCopyWith(_YouTubeTextMessageDetails value, $Res Function(_YouTubeTextMessageDetails) _then) = __$YouTubeTextMessageDetailsCopyWithImpl;
@override @useResult
$Res call({
 String messageText
});




}
/// @nodoc
class __$YouTubeTextMessageDetailsCopyWithImpl<$Res>
    implements _$YouTubeTextMessageDetailsCopyWith<$Res> {
  __$YouTubeTextMessageDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeTextMessageDetails _self;
  final $Res Function(_YouTubeTextMessageDetails) _then;

/// Create a copy of YouTubeTextMessageDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageText = null,}) {
  return _then(_YouTubeTextMessageDetails(
messageText: null == messageText ? _self.messageText : messageText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$YouTubeSuperChatDetails {

/// unsigned long — serialized as a string in the JSON
 String? get amountMicros; String? get currency; String? get amountDisplayString; String? get userComment; int get tier;
/// Create a copy of YouTubeSuperChatDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeSuperChatDetailsCopyWith<YouTubeSuperChatDetails> get copyWith => _$YouTubeSuperChatDetailsCopyWithImpl<YouTubeSuperChatDetails>(this as YouTubeSuperChatDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeSuperChatDetails&&(identical(other.amountMicros, amountMicros) || other.amountMicros == amountMicros)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.amountDisplayString, amountDisplayString) || other.amountDisplayString == amountDisplayString)&&(identical(other.userComment, userComment) || other.userComment == userComment)&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amountMicros,currency,amountDisplayString,userComment,tier);

@override
String toString() {
  return 'YouTubeSuperChatDetails(amountMicros: $amountMicros, currency: $currency, amountDisplayString: $amountDisplayString, userComment: $userComment, tier: $tier)';
}


}

/// @nodoc
abstract mixin class $YouTubeSuperChatDetailsCopyWith<$Res>  {
  factory $YouTubeSuperChatDetailsCopyWith(YouTubeSuperChatDetails value, $Res Function(YouTubeSuperChatDetails) _then) = _$YouTubeSuperChatDetailsCopyWithImpl;
@useResult
$Res call({
 String? amountMicros, String? currency, String? amountDisplayString, String? userComment, int tier
});




}
/// @nodoc
class _$YouTubeSuperChatDetailsCopyWithImpl<$Res>
    implements $YouTubeSuperChatDetailsCopyWith<$Res> {
  _$YouTubeSuperChatDetailsCopyWithImpl(this._self, this._then);

  final YouTubeSuperChatDetails _self;
  final $Res Function(YouTubeSuperChatDetails) _then;

/// Create a copy of YouTubeSuperChatDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amountMicros = freezed,Object? currency = freezed,Object? amountDisplayString = freezed,Object? userComment = freezed,Object? tier = null,}) {
  return _then(_self.copyWith(
amountMicros: freezed == amountMicros ? _self.amountMicros : amountMicros // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,amountDisplayString: freezed == amountDisplayString ? _self.amountDisplayString : amountDisplayString // ignore: cast_nullable_to_non_nullable
as String?,userComment: freezed == userComment ? _self.userComment : userComment // ignore: cast_nullable_to_non_nullable
as String?,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeSuperChatDetails].
extension YouTubeSuperChatDetailsPatterns on YouTubeSuperChatDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeSuperChatDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeSuperChatDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeSuperChatDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeSuperChatDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeSuperChatDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeSuperChatDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? amountMicros,  String? currency,  String? amountDisplayString,  String? userComment,  int tier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeSuperChatDetails() when $default != null:
return $default(_that.amountMicros,_that.currency,_that.amountDisplayString,_that.userComment,_that.tier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? amountMicros,  String? currency,  String? amountDisplayString,  String? userComment,  int tier)  $default,) {final _that = this;
switch (_that) {
case _YouTubeSuperChatDetails():
return $default(_that.amountMicros,_that.currency,_that.amountDisplayString,_that.userComment,_that.tier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? amountMicros,  String? currency,  String? amountDisplayString,  String? userComment,  int tier)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeSuperChatDetails() when $default != null:
return $default(_that.amountMicros,_that.currency,_that.amountDisplayString,_that.userComment,_that.tier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeSuperChatDetails implements YouTubeSuperChatDetails {
  const _YouTubeSuperChatDetails({this.amountMicros, this.currency, this.amountDisplayString, this.userComment, this.tier = 0});
  factory _YouTubeSuperChatDetails.fromJson(Map<String, dynamic> json) => _$YouTubeSuperChatDetailsFromJson(json);

/// unsigned long — serialized as a string in the JSON
@override final  String? amountMicros;
@override final  String? currency;
@override final  String? amountDisplayString;
@override final  String? userComment;
@override@JsonKey() final  int tier;

/// Create a copy of YouTubeSuperChatDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeSuperChatDetailsCopyWith<_YouTubeSuperChatDetails> get copyWith => __$YouTubeSuperChatDetailsCopyWithImpl<_YouTubeSuperChatDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeSuperChatDetails&&(identical(other.amountMicros, amountMicros) || other.amountMicros == amountMicros)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.amountDisplayString, amountDisplayString) || other.amountDisplayString == amountDisplayString)&&(identical(other.userComment, userComment) || other.userComment == userComment)&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amountMicros,currency,amountDisplayString,userComment,tier);

@override
String toString() {
  return 'YouTubeSuperChatDetails(amountMicros: $amountMicros, currency: $currency, amountDisplayString: $amountDisplayString, userComment: $userComment, tier: $tier)';
}


}

/// @nodoc
abstract mixin class _$YouTubeSuperChatDetailsCopyWith<$Res> implements $YouTubeSuperChatDetailsCopyWith<$Res> {
  factory _$YouTubeSuperChatDetailsCopyWith(_YouTubeSuperChatDetails value, $Res Function(_YouTubeSuperChatDetails) _then) = __$YouTubeSuperChatDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? amountMicros, String? currency, String? amountDisplayString, String? userComment, int tier
});




}
/// @nodoc
class __$YouTubeSuperChatDetailsCopyWithImpl<$Res>
    implements _$YouTubeSuperChatDetailsCopyWith<$Res> {
  __$YouTubeSuperChatDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeSuperChatDetails _self;
  final $Res Function(_YouTubeSuperChatDetails) _then;

/// Create a copy of YouTubeSuperChatDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amountMicros = freezed,Object? currency = freezed,Object? amountDisplayString = freezed,Object? userComment = freezed,Object? tier = null,}) {
  return _then(_YouTubeSuperChatDetails(
amountMicros: freezed == amountMicros ? _self.amountMicros : amountMicros // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,amountDisplayString: freezed == amountDisplayString ? _self.amountDisplayString : amountDisplayString // ignore: cast_nullable_to_non_nullable
as String?,userComment: freezed == userComment ? _self.userComment : userComment // ignore: cast_nullable_to_non_nullable
as String?,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$YouTubeSuperStickerDetails {

 YouTubeSuperStickerMetadata? get superStickerMetadata;/// unsigned long — serialized as a string in the JSON
 String? get amountMicros; String? get currency; String? get amountDisplayString; int get tier;
/// Create a copy of YouTubeSuperStickerDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeSuperStickerDetailsCopyWith<YouTubeSuperStickerDetails> get copyWith => _$YouTubeSuperStickerDetailsCopyWithImpl<YouTubeSuperStickerDetails>(this as YouTubeSuperStickerDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeSuperStickerDetails&&(identical(other.superStickerMetadata, superStickerMetadata) || other.superStickerMetadata == superStickerMetadata)&&(identical(other.amountMicros, amountMicros) || other.amountMicros == amountMicros)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.amountDisplayString, amountDisplayString) || other.amountDisplayString == amountDisplayString)&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,superStickerMetadata,amountMicros,currency,amountDisplayString,tier);

@override
String toString() {
  return 'YouTubeSuperStickerDetails(superStickerMetadata: $superStickerMetadata, amountMicros: $amountMicros, currency: $currency, amountDisplayString: $amountDisplayString, tier: $tier)';
}


}

/// @nodoc
abstract mixin class $YouTubeSuperStickerDetailsCopyWith<$Res>  {
  factory $YouTubeSuperStickerDetailsCopyWith(YouTubeSuperStickerDetails value, $Res Function(YouTubeSuperStickerDetails) _then) = _$YouTubeSuperStickerDetailsCopyWithImpl;
@useResult
$Res call({
 YouTubeSuperStickerMetadata? superStickerMetadata, String? amountMicros, String? currency, String? amountDisplayString, int tier
});


$YouTubeSuperStickerMetadataCopyWith<$Res>? get superStickerMetadata;

}
/// @nodoc
class _$YouTubeSuperStickerDetailsCopyWithImpl<$Res>
    implements $YouTubeSuperStickerDetailsCopyWith<$Res> {
  _$YouTubeSuperStickerDetailsCopyWithImpl(this._self, this._then);

  final YouTubeSuperStickerDetails _self;
  final $Res Function(YouTubeSuperStickerDetails) _then;

/// Create a copy of YouTubeSuperStickerDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? superStickerMetadata = freezed,Object? amountMicros = freezed,Object? currency = freezed,Object? amountDisplayString = freezed,Object? tier = null,}) {
  return _then(_self.copyWith(
superStickerMetadata: freezed == superStickerMetadata ? _self.superStickerMetadata : superStickerMetadata // ignore: cast_nullable_to_non_nullable
as YouTubeSuperStickerMetadata?,amountMicros: freezed == amountMicros ? _self.amountMicros : amountMicros // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,amountDisplayString: freezed == amountDisplayString ? _self.amountDisplayString : amountDisplayString // ignore: cast_nullable_to_non_nullable
as String?,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of YouTubeSuperStickerDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeSuperStickerMetadataCopyWith<$Res>? get superStickerMetadata {
    if (_self.superStickerMetadata == null) {
    return null;
  }

  return $YouTubeSuperStickerMetadataCopyWith<$Res>(_self.superStickerMetadata!, (value) {
    return _then(_self.copyWith(superStickerMetadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [YouTubeSuperStickerDetails].
extension YouTubeSuperStickerDetailsPatterns on YouTubeSuperStickerDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeSuperStickerDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeSuperStickerDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeSuperStickerDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeSuperStickerDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeSuperStickerDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeSuperStickerDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( YouTubeSuperStickerMetadata? superStickerMetadata,  String? amountMicros,  String? currency,  String? amountDisplayString,  int tier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeSuperStickerDetails() when $default != null:
return $default(_that.superStickerMetadata,_that.amountMicros,_that.currency,_that.amountDisplayString,_that.tier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( YouTubeSuperStickerMetadata? superStickerMetadata,  String? amountMicros,  String? currency,  String? amountDisplayString,  int tier)  $default,) {final _that = this;
switch (_that) {
case _YouTubeSuperStickerDetails():
return $default(_that.superStickerMetadata,_that.amountMicros,_that.currency,_that.amountDisplayString,_that.tier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( YouTubeSuperStickerMetadata? superStickerMetadata,  String? amountMicros,  String? currency,  String? amountDisplayString,  int tier)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeSuperStickerDetails() when $default != null:
return $default(_that.superStickerMetadata,_that.amountMicros,_that.currency,_that.amountDisplayString,_that.tier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeSuperStickerDetails implements YouTubeSuperStickerDetails {
  const _YouTubeSuperStickerDetails({this.superStickerMetadata, this.amountMicros, this.currency, this.amountDisplayString, this.tier = 0});
  factory _YouTubeSuperStickerDetails.fromJson(Map<String, dynamic> json) => _$YouTubeSuperStickerDetailsFromJson(json);

@override final  YouTubeSuperStickerMetadata? superStickerMetadata;
/// unsigned long — serialized as a string in the JSON
@override final  String? amountMicros;
@override final  String? currency;
@override final  String? amountDisplayString;
@override@JsonKey() final  int tier;

/// Create a copy of YouTubeSuperStickerDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeSuperStickerDetailsCopyWith<_YouTubeSuperStickerDetails> get copyWith => __$YouTubeSuperStickerDetailsCopyWithImpl<_YouTubeSuperStickerDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeSuperStickerDetails&&(identical(other.superStickerMetadata, superStickerMetadata) || other.superStickerMetadata == superStickerMetadata)&&(identical(other.amountMicros, amountMicros) || other.amountMicros == amountMicros)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.amountDisplayString, amountDisplayString) || other.amountDisplayString == amountDisplayString)&&(identical(other.tier, tier) || other.tier == tier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,superStickerMetadata,amountMicros,currency,amountDisplayString,tier);

@override
String toString() {
  return 'YouTubeSuperStickerDetails(superStickerMetadata: $superStickerMetadata, amountMicros: $amountMicros, currency: $currency, amountDisplayString: $amountDisplayString, tier: $tier)';
}


}

/// @nodoc
abstract mixin class _$YouTubeSuperStickerDetailsCopyWith<$Res> implements $YouTubeSuperStickerDetailsCopyWith<$Res> {
  factory _$YouTubeSuperStickerDetailsCopyWith(_YouTubeSuperStickerDetails value, $Res Function(_YouTubeSuperStickerDetails) _then) = __$YouTubeSuperStickerDetailsCopyWithImpl;
@override @useResult
$Res call({
 YouTubeSuperStickerMetadata? superStickerMetadata, String? amountMicros, String? currency, String? amountDisplayString, int tier
});


@override $YouTubeSuperStickerMetadataCopyWith<$Res>? get superStickerMetadata;

}
/// @nodoc
class __$YouTubeSuperStickerDetailsCopyWithImpl<$Res>
    implements _$YouTubeSuperStickerDetailsCopyWith<$Res> {
  __$YouTubeSuperStickerDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeSuperStickerDetails _self;
  final $Res Function(_YouTubeSuperStickerDetails) _then;

/// Create a copy of YouTubeSuperStickerDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? superStickerMetadata = freezed,Object? amountMicros = freezed,Object? currency = freezed,Object? amountDisplayString = freezed,Object? tier = null,}) {
  return _then(_YouTubeSuperStickerDetails(
superStickerMetadata: freezed == superStickerMetadata ? _self.superStickerMetadata : superStickerMetadata // ignore: cast_nullable_to_non_nullable
as YouTubeSuperStickerMetadata?,amountMicros: freezed == amountMicros ? _self.amountMicros : amountMicros // ignore: cast_nullable_to_non_nullable
as String?,currency: freezed == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String?,amountDisplayString: freezed == amountDisplayString ? _self.amountDisplayString : amountDisplayString // ignore: cast_nullable_to_non_nullable
as String?,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of YouTubeSuperStickerDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeSuperStickerMetadataCopyWith<$Res>? get superStickerMetadata {
    if (_self.superStickerMetadata == null) {
    return null;
  }

  return $YouTubeSuperStickerMetadataCopyWith<$Res>(_self.superStickerMetadata!, (value) {
    return _then(_self.copyWith(superStickerMetadata: value));
  });
}
}


/// @nodoc
mixin _$YouTubeSuperStickerMetadata {

 String? get stickerId; String? get altText; String? get language;
/// Create a copy of YouTubeSuperStickerMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeSuperStickerMetadataCopyWith<YouTubeSuperStickerMetadata> get copyWith => _$YouTubeSuperStickerMetadataCopyWithImpl<YouTubeSuperStickerMetadata>(this as YouTubeSuperStickerMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeSuperStickerMetadata&&(identical(other.stickerId, stickerId) || other.stickerId == stickerId)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stickerId,altText,language);

@override
String toString() {
  return 'YouTubeSuperStickerMetadata(stickerId: $stickerId, altText: $altText, language: $language)';
}


}

/// @nodoc
abstract mixin class $YouTubeSuperStickerMetadataCopyWith<$Res>  {
  factory $YouTubeSuperStickerMetadataCopyWith(YouTubeSuperStickerMetadata value, $Res Function(YouTubeSuperStickerMetadata) _then) = _$YouTubeSuperStickerMetadataCopyWithImpl;
@useResult
$Res call({
 String? stickerId, String? altText, String? language
});




}
/// @nodoc
class _$YouTubeSuperStickerMetadataCopyWithImpl<$Res>
    implements $YouTubeSuperStickerMetadataCopyWith<$Res> {
  _$YouTubeSuperStickerMetadataCopyWithImpl(this._self, this._then);

  final YouTubeSuperStickerMetadata _self;
  final $Res Function(YouTubeSuperStickerMetadata) _then;

/// Create a copy of YouTubeSuperStickerMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stickerId = freezed,Object? altText = freezed,Object? language = freezed,}) {
  return _then(_self.copyWith(
stickerId: freezed == stickerId ? _self.stickerId : stickerId // ignore: cast_nullable_to_non_nullable
as String?,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeSuperStickerMetadata].
extension YouTubeSuperStickerMetadataPatterns on YouTubeSuperStickerMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeSuperStickerMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeSuperStickerMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeSuperStickerMetadata value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeSuperStickerMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeSuperStickerMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeSuperStickerMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? stickerId,  String? altText,  String? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeSuperStickerMetadata() when $default != null:
return $default(_that.stickerId,_that.altText,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? stickerId,  String? altText,  String? language)  $default,) {final _that = this;
switch (_that) {
case _YouTubeSuperStickerMetadata():
return $default(_that.stickerId,_that.altText,_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? stickerId,  String? altText,  String? language)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeSuperStickerMetadata() when $default != null:
return $default(_that.stickerId,_that.altText,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeSuperStickerMetadata implements YouTubeSuperStickerMetadata {
  const _YouTubeSuperStickerMetadata({this.stickerId, this.altText, this.language});
  factory _YouTubeSuperStickerMetadata.fromJson(Map<String, dynamic> json) => _$YouTubeSuperStickerMetadataFromJson(json);

@override final  String? stickerId;
@override final  String? altText;
@override final  String? language;

/// Create a copy of YouTubeSuperStickerMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeSuperStickerMetadataCopyWith<_YouTubeSuperStickerMetadata> get copyWith => __$YouTubeSuperStickerMetadataCopyWithImpl<_YouTubeSuperStickerMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeSuperStickerMetadata&&(identical(other.stickerId, stickerId) || other.stickerId == stickerId)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stickerId,altText,language);

@override
String toString() {
  return 'YouTubeSuperStickerMetadata(stickerId: $stickerId, altText: $altText, language: $language)';
}


}

/// @nodoc
abstract mixin class _$YouTubeSuperStickerMetadataCopyWith<$Res> implements $YouTubeSuperStickerMetadataCopyWith<$Res> {
  factory _$YouTubeSuperStickerMetadataCopyWith(_YouTubeSuperStickerMetadata value, $Res Function(_YouTubeSuperStickerMetadata) _then) = __$YouTubeSuperStickerMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? stickerId, String? altText, String? language
});




}
/// @nodoc
class __$YouTubeSuperStickerMetadataCopyWithImpl<$Res>
    implements _$YouTubeSuperStickerMetadataCopyWith<$Res> {
  __$YouTubeSuperStickerMetadataCopyWithImpl(this._self, this._then);

  final _YouTubeSuperStickerMetadata _self;
  final $Res Function(_YouTubeSuperStickerMetadata) _then;

/// Create a copy of YouTubeSuperStickerMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stickerId = freezed,Object? altText = freezed,Object? language = freezed,}) {
  return _then(_YouTubeSuperStickerMetadata(
stickerId: freezed == stickerId ? _self.stickerId : stickerId // ignore: cast_nullable_to_non_nullable
as String?,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$YouTubeNewSponsorDetails {

 String? get memberLevelName; bool get isUpgrade;
/// Create a copy of YouTubeNewSponsorDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeNewSponsorDetailsCopyWith<YouTubeNewSponsorDetails> get copyWith => _$YouTubeNewSponsorDetailsCopyWithImpl<YouTubeNewSponsorDetails>(this as YouTubeNewSponsorDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeNewSponsorDetails&&(identical(other.memberLevelName, memberLevelName) || other.memberLevelName == memberLevelName)&&(identical(other.isUpgrade, isUpgrade) || other.isUpgrade == isUpgrade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberLevelName,isUpgrade);

@override
String toString() {
  return 'YouTubeNewSponsorDetails(memberLevelName: $memberLevelName, isUpgrade: $isUpgrade)';
}


}

/// @nodoc
abstract mixin class $YouTubeNewSponsorDetailsCopyWith<$Res>  {
  factory $YouTubeNewSponsorDetailsCopyWith(YouTubeNewSponsorDetails value, $Res Function(YouTubeNewSponsorDetails) _then) = _$YouTubeNewSponsorDetailsCopyWithImpl;
@useResult
$Res call({
 String? memberLevelName, bool isUpgrade
});




}
/// @nodoc
class _$YouTubeNewSponsorDetailsCopyWithImpl<$Res>
    implements $YouTubeNewSponsorDetailsCopyWith<$Res> {
  _$YouTubeNewSponsorDetailsCopyWithImpl(this._self, this._then);

  final YouTubeNewSponsorDetails _self;
  final $Res Function(YouTubeNewSponsorDetails) _then;

/// Create a copy of YouTubeNewSponsorDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberLevelName = freezed,Object? isUpgrade = null,}) {
  return _then(_self.copyWith(
memberLevelName: freezed == memberLevelName ? _self.memberLevelName : memberLevelName // ignore: cast_nullable_to_non_nullable
as String?,isUpgrade: null == isUpgrade ? _self.isUpgrade : isUpgrade // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeNewSponsorDetails].
extension YouTubeNewSponsorDetailsPatterns on YouTubeNewSponsorDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeNewSponsorDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeNewSponsorDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeNewSponsorDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeNewSponsorDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeNewSponsorDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeNewSponsorDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? memberLevelName,  bool isUpgrade)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeNewSponsorDetails() when $default != null:
return $default(_that.memberLevelName,_that.isUpgrade);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? memberLevelName,  bool isUpgrade)  $default,) {final _that = this;
switch (_that) {
case _YouTubeNewSponsorDetails():
return $default(_that.memberLevelName,_that.isUpgrade);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? memberLevelName,  bool isUpgrade)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeNewSponsorDetails() when $default != null:
return $default(_that.memberLevelName,_that.isUpgrade);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeNewSponsorDetails implements YouTubeNewSponsorDetails {
  const _YouTubeNewSponsorDetails({this.memberLevelName, this.isUpgrade = false});
  factory _YouTubeNewSponsorDetails.fromJson(Map<String, dynamic> json) => _$YouTubeNewSponsorDetailsFromJson(json);

@override final  String? memberLevelName;
@override@JsonKey() final  bool isUpgrade;

/// Create a copy of YouTubeNewSponsorDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeNewSponsorDetailsCopyWith<_YouTubeNewSponsorDetails> get copyWith => __$YouTubeNewSponsorDetailsCopyWithImpl<_YouTubeNewSponsorDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeNewSponsorDetails&&(identical(other.memberLevelName, memberLevelName) || other.memberLevelName == memberLevelName)&&(identical(other.isUpgrade, isUpgrade) || other.isUpgrade == isUpgrade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberLevelName,isUpgrade);

@override
String toString() {
  return 'YouTubeNewSponsorDetails(memberLevelName: $memberLevelName, isUpgrade: $isUpgrade)';
}


}

/// @nodoc
abstract mixin class _$YouTubeNewSponsorDetailsCopyWith<$Res> implements $YouTubeNewSponsorDetailsCopyWith<$Res> {
  factory _$YouTubeNewSponsorDetailsCopyWith(_YouTubeNewSponsorDetails value, $Res Function(_YouTubeNewSponsorDetails) _then) = __$YouTubeNewSponsorDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? memberLevelName, bool isUpgrade
});




}
/// @nodoc
class __$YouTubeNewSponsorDetailsCopyWithImpl<$Res>
    implements _$YouTubeNewSponsorDetailsCopyWith<$Res> {
  __$YouTubeNewSponsorDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeNewSponsorDetails _self;
  final $Res Function(_YouTubeNewSponsorDetails) _then;

/// Create a copy of YouTubeNewSponsorDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberLevelName = freezed,Object? isUpgrade = null,}) {
  return _then(_YouTubeNewSponsorDetails(
memberLevelName: freezed == memberLevelName ? _self.memberLevelName : memberLevelName // ignore: cast_nullable_to_non_nullable
as String?,isUpgrade: null == isUpgrade ? _self.isUpgrade : isUpgrade // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$YouTubeMemberMilestoneDetails {

 String? get userComment; int get memberMonth; String? get memberLevelName;
/// Create a copy of YouTubeMemberMilestoneDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeMemberMilestoneDetailsCopyWith<YouTubeMemberMilestoneDetails> get copyWith => _$YouTubeMemberMilestoneDetailsCopyWithImpl<YouTubeMemberMilestoneDetails>(this as YouTubeMemberMilestoneDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeMemberMilestoneDetails&&(identical(other.userComment, userComment) || other.userComment == userComment)&&(identical(other.memberMonth, memberMonth) || other.memberMonth == memberMonth)&&(identical(other.memberLevelName, memberLevelName) || other.memberLevelName == memberLevelName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userComment,memberMonth,memberLevelName);

@override
String toString() {
  return 'YouTubeMemberMilestoneDetails(userComment: $userComment, memberMonth: $memberMonth, memberLevelName: $memberLevelName)';
}


}

/// @nodoc
abstract mixin class $YouTubeMemberMilestoneDetailsCopyWith<$Res>  {
  factory $YouTubeMemberMilestoneDetailsCopyWith(YouTubeMemberMilestoneDetails value, $Res Function(YouTubeMemberMilestoneDetails) _then) = _$YouTubeMemberMilestoneDetailsCopyWithImpl;
@useResult
$Res call({
 String? userComment, int memberMonth, String? memberLevelName
});




}
/// @nodoc
class _$YouTubeMemberMilestoneDetailsCopyWithImpl<$Res>
    implements $YouTubeMemberMilestoneDetailsCopyWith<$Res> {
  _$YouTubeMemberMilestoneDetailsCopyWithImpl(this._self, this._then);

  final YouTubeMemberMilestoneDetails _self;
  final $Res Function(YouTubeMemberMilestoneDetails) _then;

/// Create a copy of YouTubeMemberMilestoneDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userComment = freezed,Object? memberMonth = null,Object? memberLevelName = freezed,}) {
  return _then(_self.copyWith(
userComment: freezed == userComment ? _self.userComment : userComment // ignore: cast_nullable_to_non_nullable
as String?,memberMonth: null == memberMonth ? _self.memberMonth : memberMonth // ignore: cast_nullable_to_non_nullable
as int,memberLevelName: freezed == memberLevelName ? _self.memberLevelName : memberLevelName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeMemberMilestoneDetails].
extension YouTubeMemberMilestoneDetailsPatterns on YouTubeMemberMilestoneDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeMemberMilestoneDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeMemberMilestoneDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeMemberMilestoneDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeMemberMilestoneDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeMemberMilestoneDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeMemberMilestoneDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? userComment,  int memberMonth,  String? memberLevelName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeMemberMilestoneDetails() when $default != null:
return $default(_that.userComment,_that.memberMonth,_that.memberLevelName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? userComment,  int memberMonth,  String? memberLevelName)  $default,) {final _that = this;
switch (_that) {
case _YouTubeMemberMilestoneDetails():
return $default(_that.userComment,_that.memberMonth,_that.memberLevelName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? userComment,  int memberMonth,  String? memberLevelName)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeMemberMilestoneDetails() when $default != null:
return $default(_that.userComment,_that.memberMonth,_that.memberLevelName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeMemberMilestoneDetails implements YouTubeMemberMilestoneDetails {
  const _YouTubeMemberMilestoneDetails({this.userComment, this.memberMonth = 0, this.memberLevelName});
  factory _YouTubeMemberMilestoneDetails.fromJson(Map<String, dynamic> json) => _$YouTubeMemberMilestoneDetailsFromJson(json);

@override final  String? userComment;
@override@JsonKey() final  int memberMonth;
@override final  String? memberLevelName;

/// Create a copy of YouTubeMemberMilestoneDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeMemberMilestoneDetailsCopyWith<_YouTubeMemberMilestoneDetails> get copyWith => __$YouTubeMemberMilestoneDetailsCopyWithImpl<_YouTubeMemberMilestoneDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeMemberMilestoneDetails&&(identical(other.userComment, userComment) || other.userComment == userComment)&&(identical(other.memberMonth, memberMonth) || other.memberMonth == memberMonth)&&(identical(other.memberLevelName, memberLevelName) || other.memberLevelName == memberLevelName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userComment,memberMonth,memberLevelName);

@override
String toString() {
  return 'YouTubeMemberMilestoneDetails(userComment: $userComment, memberMonth: $memberMonth, memberLevelName: $memberLevelName)';
}


}

/// @nodoc
abstract mixin class _$YouTubeMemberMilestoneDetailsCopyWith<$Res> implements $YouTubeMemberMilestoneDetailsCopyWith<$Res> {
  factory _$YouTubeMemberMilestoneDetailsCopyWith(_YouTubeMemberMilestoneDetails value, $Res Function(_YouTubeMemberMilestoneDetails) _then) = __$YouTubeMemberMilestoneDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? userComment, int memberMonth, String? memberLevelName
});




}
/// @nodoc
class __$YouTubeMemberMilestoneDetailsCopyWithImpl<$Res>
    implements _$YouTubeMemberMilestoneDetailsCopyWith<$Res> {
  __$YouTubeMemberMilestoneDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeMemberMilestoneDetails _self;
  final $Res Function(_YouTubeMemberMilestoneDetails) _then;

/// Create a copy of YouTubeMemberMilestoneDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userComment = freezed,Object? memberMonth = null,Object? memberLevelName = freezed,}) {
  return _then(_YouTubeMemberMilestoneDetails(
userComment: freezed == userComment ? _self.userComment : userComment // ignore: cast_nullable_to_non_nullable
as String?,memberMonth: null == memberMonth ? _self.memberMonth : memberMonth // ignore: cast_nullable_to_non_nullable
as int,memberLevelName: freezed == memberLevelName ? _self.memberLevelName : memberLevelName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$YouTubeMembershipGiftingDetails {

 int get giftMembershipsCount; String? get giftMembershipsLevelName;
/// Create a copy of YouTubeMembershipGiftingDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeMembershipGiftingDetailsCopyWith<YouTubeMembershipGiftingDetails> get copyWith => _$YouTubeMembershipGiftingDetailsCopyWithImpl<YouTubeMembershipGiftingDetails>(this as YouTubeMembershipGiftingDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeMembershipGiftingDetails&&(identical(other.giftMembershipsCount, giftMembershipsCount) || other.giftMembershipsCount == giftMembershipsCount)&&(identical(other.giftMembershipsLevelName, giftMembershipsLevelName) || other.giftMembershipsLevelName == giftMembershipsLevelName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,giftMembershipsCount,giftMembershipsLevelName);

@override
String toString() {
  return 'YouTubeMembershipGiftingDetails(giftMembershipsCount: $giftMembershipsCount, giftMembershipsLevelName: $giftMembershipsLevelName)';
}


}

/// @nodoc
abstract mixin class $YouTubeMembershipGiftingDetailsCopyWith<$Res>  {
  factory $YouTubeMembershipGiftingDetailsCopyWith(YouTubeMembershipGiftingDetails value, $Res Function(YouTubeMembershipGiftingDetails) _then) = _$YouTubeMembershipGiftingDetailsCopyWithImpl;
@useResult
$Res call({
 int giftMembershipsCount, String? giftMembershipsLevelName
});




}
/// @nodoc
class _$YouTubeMembershipGiftingDetailsCopyWithImpl<$Res>
    implements $YouTubeMembershipGiftingDetailsCopyWith<$Res> {
  _$YouTubeMembershipGiftingDetailsCopyWithImpl(this._self, this._then);

  final YouTubeMembershipGiftingDetails _self;
  final $Res Function(YouTubeMembershipGiftingDetails) _then;

/// Create a copy of YouTubeMembershipGiftingDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? giftMembershipsCount = null,Object? giftMembershipsLevelName = freezed,}) {
  return _then(_self.copyWith(
giftMembershipsCount: null == giftMembershipsCount ? _self.giftMembershipsCount : giftMembershipsCount // ignore: cast_nullable_to_non_nullable
as int,giftMembershipsLevelName: freezed == giftMembershipsLevelName ? _self.giftMembershipsLevelName : giftMembershipsLevelName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeMembershipGiftingDetails].
extension YouTubeMembershipGiftingDetailsPatterns on YouTubeMembershipGiftingDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeMembershipGiftingDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeMembershipGiftingDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeMembershipGiftingDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeMembershipGiftingDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeMembershipGiftingDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeMembershipGiftingDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int giftMembershipsCount,  String? giftMembershipsLevelName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeMembershipGiftingDetails() when $default != null:
return $default(_that.giftMembershipsCount,_that.giftMembershipsLevelName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int giftMembershipsCount,  String? giftMembershipsLevelName)  $default,) {final _that = this;
switch (_that) {
case _YouTubeMembershipGiftingDetails():
return $default(_that.giftMembershipsCount,_that.giftMembershipsLevelName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int giftMembershipsCount,  String? giftMembershipsLevelName)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeMembershipGiftingDetails() when $default != null:
return $default(_that.giftMembershipsCount,_that.giftMembershipsLevelName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeMembershipGiftingDetails implements YouTubeMembershipGiftingDetails {
  const _YouTubeMembershipGiftingDetails({this.giftMembershipsCount = 0, this.giftMembershipsLevelName});
  factory _YouTubeMembershipGiftingDetails.fromJson(Map<String, dynamic> json) => _$YouTubeMembershipGiftingDetailsFromJson(json);

@override@JsonKey() final  int giftMembershipsCount;
@override final  String? giftMembershipsLevelName;

/// Create a copy of YouTubeMembershipGiftingDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeMembershipGiftingDetailsCopyWith<_YouTubeMembershipGiftingDetails> get copyWith => __$YouTubeMembershipGiftingDetailsCopyWithImpl<_YouTubeMembershipGiftingDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeMembershipGiftingDetails&&(identical(other.giftMembershipsCount, giftMembershipsCount) || other.giftMembershipsCount == giftMembershipsCount)&&(identical(other.giftMembershipsLevelName, giftMembershipsLevelName) || other.giftMembershipsLevelName == giftMembershipsLevelName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,giftMembershipsCount,giftMembershipsLevelName);

@override
String toString() {
  return 'YouTubeMembershipGiftingDetails(giftMembershipsCount: $giftMembershipsCount, giftMembershipsLevelName: $giftMembershipsLevelName)';
}


}

/// @nodoc
abstract mixin class _$YouTubeMembershipGiftingDetailsCopyWith<$Res> implements $YouTubeMembershipGiftingDetailsCopyWith<$Res> {
  factory _$YouTubeMembershipGiftingDetailsCopyWith(_YouTubeMembershipGiftingDetails value, $Res Function(_YouTubeMembershipGiftingDetails) _then) = __$YouTubeMembershipGiftingDetailsCopyWithImpl;
@override @useResult
$Res call({
 int giftMembershipsCount, String? giftMembershipsLevelName
});




}
/// @nodoc
class __$YouTubeMembershipGiftingDetailsCopyWithImpl<$Res>
    implements _$YouTubeMembershipGiftingDetailsCopyWith<$Res> {
  __$YouTubeMembershipGiftingDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeMembershipGiftingDetails _self;
  final $Res Function(_YouTubeMembershipGiftingDetails) _then;

/// Create a copy of YouTubeMembershipGiftingDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? giftMembershipsCount = null,Object? giftMembershipsLevelName = freezed,}) {
  return _then(_YouTubeMembershipGiftingDetails(
giftMembershipsCount: null == giftMembershipsCount ? _self.giftMembershipsCount : giftMembershipsCount // ignore: cast_nullable_to_non_nullable
as int,giftMembershipsLevelName: freezed == giftMembershipsLevelName ? _self.giftMembershipsLevelName : giftMembershipsLevelName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$YouTubeGiftMembershipReceivedDetails {

 String? get memberLevelName; String? get gifterChannelId; String? get associatedMembershipGiftingMessageId;
/// Create a copy of YouTubeGiftMembershipReceivedDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeGiftMembershipReceivedDetailsCopyWith<YouTubeGiftMembershipReceivedDetails> get copyWith => _$YouTubeGiftMembershipReceivedDetailsCopyWithImpl<YouTubeGiftMembershipReceivedDetails>(this as YouTubeGiftMembershipReceivedDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeGiftMembershipReceivedDetails&&(identical(other.memberLevelName, memberLevelName) || other.memberLevelName == memberLevelName)&&(identical(other.gifterChannelId, gifterChannelId) || other.gifterChannelId == gifterChannelId)&&(identical(other.associatedMembershipGiftingMessageId, associatedMembershipGiftingMessageId) || other.associatedMembershipGiftingMessageId == associatedMembershipGiftingMessageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberLevelName,gifterChannelId,associatedMembershipGiftingMessageId);

@override
String toString() {
  return 'YouTubeGiftMembershipReceivedDetails(memberLevelName: $memberLevelName, gifterChannelId: $gifterChannelId, associatedMembershipGiftingMessageId: $associatedMembershipGiftingMessageId)';
}


}

/// @nodoc
abstract mixin class $YouTubeGiftMembershipReceivedDetailsCopyWith<$Res>  {
  factory $YouTubeGiftMembershipReceivedDetailsCopyWith(YouTubeGiftMembershipReceivedDetails value, $Res Function(YouTubeGiftMembershipReceivedDetails) _then) = _$YouTubeGiftMembershipReceivedDetailsCopyWithImpl;
@useResult
$Res call({
 String? memberLevelName, String? gifterChannelId, String? associatedMembershipGiftingMessageId
});




}
/// @nodoc
class _$YouTubeGiftMembershipReceivedDetailsCopyWithImpl<$Res>
    implements $YouTubeGiftMembershipReceivedDetailsCopyWith<$Res> {
  _$YouTubeGiftMembershipReceivedDetailsCopyWithImpl(this._self, this._then);

  final YouTubeGiftMembershipReceivedDetails _self;
  final $Res Function(YouTubeGiftMembershipReceivedDetails) _then;

/// Create a copy of YouTubeGiftMembershipReceivedDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? memberLevelName = freezed,Object? gifterChannelId = freezed,Object? associatedMembershipGiftingMessageId = freezed,}) {
  return _then(_self.copyWith(
memberLevelName: freezed == memberLevelName ? _self.memberLevelName : memberLevelName // ignore: cast_nullable_to_non_nullable
as String?,gifterChannelId: freezed == gifterChannelId ? _self.gifterChannelId : gifterChannelId // ignore: cast_nullable_to_non_nullable
as String?,associatedMembershipGiftingMessageId: freezed == associatedMembershipGiftingMessageId ? _self.associatedMembershipGiftingMessageId : associatedMembershipGiftingMessageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeGiftMembershipReceivedDetails].
extension YouTubeGiftMembershipReceivedDetailsPatterns on YouTubeGiftMembershipReceivedDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeGiftMembershipReceivedDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeGiftMembershipReceivedDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeGiftMembershipReceivedDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeGiftMembershipReceivedDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeGiftMembershipReceivedDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeGiftMembershipReceivedDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? memberLevelName,  String? gifterChannelId,  String? associatedMembershipGiftingMessageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeGiftMembershipReceivedDetails() when $default != null:
return $default(_that.memberLevelName,_that.gifterChannelId,_that.associatedMembershipGiftingMessageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? memberLevelName,  String? gifterChannelId,  String? associatedMembershipGiftingMessageId)  $default,) {final _that = this;
switch (_that) {
case _YouTubeGiftMembershipReceivedDetails():
return $default(_that.memberLevelName,_that.gifterChannelId,_that.associatedMembershipGiftingMessageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? memberLevelName,  String? gifterChannelId,  String? associatedMembershipGiftingMessageId)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeGiftMembershipReceivedDetails() when $default != null:
return $default(_that.memberLevelName,_that.gifterChannelId,_that.associatedMembershipGiftingMessageId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeGiftMembershipReceivedDetails implements YouTubeGiftMembershipReceivedDetails {
  const _YouTubeGiftMembershipReceivedDetails({this.memberLevelName, this.gifterChannelId, this.associatedMembershipGiftingMessageId});
  factory _YouTubeGiftMembershipReceivedDetails.fromJson(Map<String, dynamic> json) => _$YouTubeGiftMembershipReceivedDetailsFromJson(json);

@override final  String? memberLevelName;
@override final  String? gifterChannelId;
@override final  String? associatedMembershipGiftingMessageId;

/// Create a copy of YouTubeGiftMembershipReceivedDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeGiftMembershipReceivedDetailsCopyWith<_YouTubeGiftMembershipReceivedDetails> get copyWith => __$YouTubeGiftMembershipReceivedDetailsCopyWithImpl<_YouTubeGiftMembershipReceivedDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeGiftMembershipReceivedDetails&&(identical(other.memberLevelName, memberLevelName) || other.memberLevelName == memberLevelName)&&(identical(other.gifterChannelId, gifterChannelId) || other.gifterChannelId == gifterChannelId)&&(identical(other.associatedMembershipGiftingMessageId, associatedMembershipGiftingMessageId) || other.associatedMembershipGiftingMessageId == associatedMembershipGiftingMessageId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,memberLevelName,gifterChannelId,associatedMembershipGiftingMessageId);

@override
String toString() {
  return 'YouTubeGiftMembershipReceivedDetails(memberLevelName: $memberLevelName, gifterChannelId: $gifterChannelId, associatedMembershipGiftingMessageId: $associatedMembershipGiftingMessageId)';
}


}

/// @nodoc
abstract mixin class _$YouTubeGiftMembershipReceivedDetailsCopyWith<$Res> implements $YouTubeGiftMembershipReceivedDetailsCopyWith<$Res> {
  factory _$YouTubeGiftMembershipReceivedDetailsCopyWith(_YouTubeGiftMembershipReceivedDetails value, $Res Function(_YouTubeGiftMembershipReceivedDetails) _then) = __$YouTubeGiftMembershipReceivedDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? memberLevelName, String? gifterChannelId, String? associatedMembershipGiftingMessageId
});




}
/// @nodoc
class __$YouTubeGiftMembershipReceivedDetailsCopyWithImpl<$Res>
    implements _$YouTubeGiftMembershipReceivedDetailsCopyWith<$Res> {
  __$YouTubeGiftMembershipReceivedDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeGiftMembershipReceivedDetails _self;
  final $Res Function(_YouTubeGiftMembershipReceivedDetails) _then;

/// Create a copy of YouTubeGiftMembershipReceivedDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? memberLevelName = freezed,Object? gifterChannelId = freezed,Object? associatedMembershipGiftingMessageId = freezed,}) {
  return _then(_YouTubeGiftMembershipReceivedDetails(
memberLevelName: freezed == memberLevelName ? _self.memberLevelName : memberLevelName // ignore: cast_nullable_to_non_nullable
as String?,gifterChannelId: freezed == gifterChannelId ? _self.gifterChannelId : gifterChannelId // ignore: cast_nullable_to_non_nullable
as String?,associatedMembershipGiftingMessageId: freezed == associatedMembershipGiftingMessageId ? _self.associatedMembershipGiftingMessageId : associatedMembershipGiftingMessageId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$YouTubePollDetails {

 YouTubePollMetadata? get metadata;
/// Create a copy of YouTubePollDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubePollDetailsCopyWith<YouTubePollDetails> get copyWith => _$YouTubePollDetailsCopyWithImpl<YouTubePollDetails>(this as YouTubePollDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubePollDetails&&(identical(other.metadata, metadata) || other.metadata == metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata);

@override
String toString() {
  return 'YouTubePollDetails(metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $YouTubePollDetailsCopyWith<$Res>  {
  factory $YouTubePollDetailsCopyWith(YouTubePollDetails value, $Res Function(YouTubePollDetails) _then) = _$YouTubePollDetailsCopyWithImpl;
@useResult
$Res call({
 YouTubePollMetadata? metadata
});


$YouTubePollMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$YouTubePollDetailsCopyWithImpl<$Res>
    implements $YouTubePollDetailsCopyWith<$Res> {
  _$YouTubePollDetailsCopyWithImpl(this._self, this._then);

  final YouTubePollDetails _self;
  final $Res Function(YouTubePollDetails) _then;

/// Create a copy of YouTubePollDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = freezed,}) {
  return _then(_self.copyWith(
metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as YouTubePollMetadata?,
  ));
}
/// Create a copy of YouTubePollDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubePollMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $YouTubePollMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [YouTubePollDetails].
extension YouTubePollDetailsPatterns on YouTubePollDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubePollDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubePollDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubePollDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubePollDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubePollDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubePollDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( YouTubePollMetadata? metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubePollDetails() when $default != null:
return $default(_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( YouTubePollMetadata? metadata)  $default,) {final _that = this;
switch (_that) {
case _YouTubePollDetails():
return $default(_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( YouTubePollMetadata? metadata)?  $default,) {final _that = this;
switch (_that) {
case _YouTubePollDetails() when $default != null:
return $default(_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubePollDetails implements YouTubePollDetails {
  const _YouTubePollDetails({this.metadata});
  factory _YouTubePollDetails.fromJson(Map<String, dynamic> json) => _$YouTubePollDetailsFromJson(json);

@override final  YouTubePollMetadata? metadata;

/// Create a copy of YouTubePollDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubePollDetailsCopyWith<_YouTubePollDetails> get copyWith => __$YouTubePollDetailsCopyWithImpl<_YouTubePollDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubePollDetails&&(identical(other.metadata, metadata) || other.metadata == metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata);

@override
String toString() {
  return 'YouTubePollDetails(metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$YouTubePollDetailsCopyWith<$Res> implements $YouTubePollDetailsCopyWith<$Res> {
  factory _$YouTubePollDetailsCopyWith(_YouTubePollDetails value, $Res Function(_YouTubePollDetails) _then) = __$YouTubePollDetailsCopyWithImpl;
@override @useResult
$Res call({
 YouTubePollMetadata? metadata
});


@override $YouTubePollMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$YouTubePollDetailsCopyWithImpl<$Res>
    implements _$YouTubePollDetailsCopyWith<$Res> {
  __$YouTubePollDetailsCopyWithImpl(this._self, this._then);

  final _YouTubePollDetails _self;
  final $Res Function(_YouTubePollDetails) _then;

/// Create a copy of YouTubePollDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadata = freezed,}) {
  return _then(_YouTubePollDetails(
metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as YouTubePollMetadata?,
  ));
}

/// Create a copy of YouTubePollDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubePollMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $YouTubePollMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
mixin _$YouTubePollMetadata {

 String? get questionText; List<YouTubePollOption> get options;/// `unknown` | `active` | `closed` — tallies are owner-only.
 String? get status;
/// Create a copy of YouTubePollMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubePollMetadataCopyWith<YouTubePollMetadata> get copyWith => _$YouTubePollMetadataCopyWithImpl<YouTubePollMetadata>(this as YouTubePollMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubePollMetadata&&(identical(other.questionText, questionText) || other.questionText == questionText)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionText,const DeepCollectionEquality().hash(options),status);

@override
String toString() {
  return 'YouTubePollMetadata(questionText: $questionText, options: $options, status: $status)';
}


}

/// @nodoc
abstract mixin class $YouTubePollMetadataCopyWith<$Res>  {
  factory $YouTubePollMetadataCopyWith(YouTubePollMetadata value, $Res Function(YouTubePollMetadata) _then) = _$YouTubePollMetadataCopyWithImpl;
@useResult
$Res call({
 String? questionText, List<YouTubePollOption> options, String? status
});




}
/// @nodoc
class _$YouTubePollMetadataCopyWithImpl<$Res>
    implements $YouTubePollMetadataCopyWith<$Res> {
  _$YouTubePollMetadataCopyWithImpl(this._self, this._then);

  final YouTubePollMetadata _self;
  final $Res Function(YouTubePollMetadata) _then;

/// Create a copy of YouTubePollMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionText = freezed,Object? options = null,Object? status = freezed,}) {
  return _then(_self.copyWith(
questionText: freezed == questionText ? _self.questionText : questionText // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<YouTubePollOption>,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubePollMetadata].
extension YouTubePollMetadataPatterns on YouTubePollMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubePollMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubePollMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubePollMetadata value)  $default,){
final _that = this;
switch (_that) {
case _YouTubePollMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubePollMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubePollMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? questionText,  List<YouTubePollOption> options,  String? status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubePollMetadata() when $default != null:
return $default(_that.questionText,_that.options,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? questionText,  List<YouTubePollOption> options,  String? status)  $default,) {final _that = this;
switch (_that) {
case _YouTubePollMetadata():
return $default(_that.questionText,_that.options,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? questionText,  List<YouTubePollOption> options,  String? status)?  $default,) {final _that = this;
switch (_that) {
case _YouTubePollMetadata() when $default != null:
return $default(_that.questionText,_that.options,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubePollMetadata implements YouTubePollMetadata {
  const _YouTubePollMetadata({this.questionText, final  List<YouTubePollOption> options = const <YouTubePollOption>[], this.status}): _options = options;
  factory _YouTubePollMetadata.fromJson(Map<String, dynamic> json) => _$YouTubePollMetadataFromJson(json);

@override final  String? questionText;
 final  List<YouTubePollOption> _options;
@override@JsonKey() List<YouTubePollOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

/// `unknown` | `active` | `closed` — tallies are owner-only.
@override final  String? status;

/// Create a copy of YouTubePollMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubePollMetadataCopyWith<_YouTubePollMetadata> get copyWith => __$YouTubePollMetadataCopyWithImpl<_YouTubePollMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubePollMetadata&&(identical(other.questionText, questionText) || other.questionText == questionText)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionText,const DeepCollectionEquality().hash(_options),status);

@override
String toString() {
  return 'YouTubePollMetadata(questionText: $questionText, options: $options, status: $status)';
}


}

/// @nodoc
abstract mixin class _$YouTubePollMetadataCopyWith<$Res> implements $YouTubePollMetadataCopyWith<$Res> {
  factory _$YouTubePollMetadataCopyWith(_YouTubePollMetadata value, $Res Function(_YouTubePollMetadata) _then) = __$YouTubePollMetadataCopyWithImpl;
@override @useResult
$Res call({
 String? questionText, List<YouTubePollOption> options, String? status
});




}
/// @nodoc
class __$YouTubePollMetadataCopyWithImpl<$Res>
    implements _$YouTubePollMetadataCopyWith<$Res> {
  __$YouTubePollMetadataCopyWithImpl(this._self, this._then);

  final _YouTubePollMetadata _self;
  final $Res Function(_YouTubePollMetadata) _then;

/// Create a copy of YouTubePollMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionText = freezed,Object? options = null,Object? status = freezed,}) {
  return _then(_YouTubePollMetadata(
questionText: freezed == questionText ? _self.questionText : questionText // ignore: cast_nullable_to_non_nullable
as String?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<YouTubePollOption>,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$YouTubePollOption {

 String? get optionText;/// Only present when the request was authorized by the channel owner.
 String? get tally;
/// Create a copy of YouTubePollOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubePollOptionCopyWith<YouTubePollOption> get copyWith => _$YouTubePollOptionCopyWithImpl<YouTubePollOption>(this as YouTubePollOption, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubePollOption&&(identical(other.optionText, optionText) || other.optionText == optionText)&&(identical(other.tally, tally) || other.tally == tally));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,optionText,tally);

@override
String toString() {
  return 'YouTubePollOption(optionText: $optionText, tally: $tally)';
}


}

/// @nodoc
abstract mixin class $YouTubePollOptionCopyWith<$Res>  {
  factory $YouTubePollOptionCopyWith(YouTubePollOption value, $Res Function(YouTubePollOption) _then) = _$YouTubePollOptionCopyWithImpl;
@useResult
$Res call({
 String? optionText, String? tally
});




}
/// @nodoc
class _$YouTubePollOptionCopyWithImpl<$Res>
    implements $YouTubePollOptionCopyWith<$Res> {
  _$YouTubePollOptionCopyWithImpl(this._self, this._then);

  final YouTubePollOption _self;
  final $Res Function(YouTubePollOption) _then;

/// Create a copy of YouTubePollOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? optionText = freezed,Object? tally = freezed,}) {
  return _then(_self.copyWith(
optionText: freezed == optionText ? _self.optionText : optionText // ignore: cast_nullable_to_non_nullable
as String?,tally: freezed == tally ? _self.tally : tally // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubePollOption].
extension YouTubePollOptionPatterns on YouTubePollOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubePollOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubePollOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubePollOption value)  $default,){
final _that = this;
switch (_that) {
case _YouTubePollOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubePollOption value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubePollOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? optionText,  String? tally)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubePollOption() when $default != null:
return $default(_that.optionText,_that.tally);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? optionText,  String? tally)  $default,) {final _that = this;
switch (_that) {
case _YouTubePollOption():
return $default(_that.optionText,_that.tally);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? optionText,  String? tally)?  $default,) {final _that = this;
switch (_that) {
case _YouTubePollOption() when $default != null:
return $default(_that.optionText,_that.tally);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubePollOption implements YouTubePollOption {
  const _YouTubePollOption({this.optionText, this.tally});
  factory _YouTubePollOption.fromJson(Map<String, dynamic> json) => _$YouTubePollOptionFromJson(json);

@override final  String? optionText;
/// Only present when the request was authorized by the channel owner.
@override final  String? tally;

/// Create a copy of YouTubePollOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubePollOptionCopyWith<_YouTubePollOption> get copyWith => __$YouTubePollOptionCopyWithImpl<_YouTubePollOption>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubePollOption&&(identical(other.optionText, optionText) || other.optionText == optionText)&&(identical(other.tally, tally) || other.tally == tally));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,optionText,tally);

@override
String toString() {
  return 'YouTubePollOption(optionText: $optionText, tally: $tally)';
}


}

/// @nodoc
abstract mixin class _$YouTubePollOptionCopyWith<$Res> implements $YouTubePollOptionCopyWith<$Res> {
  factory _$YouTubePollOptionCopyWith(_YouTubePollOption value, $Res Function(_YouTubePollOption) _then) = __$YouTubePollOptionCopyWithImpl;
@override @useResult
$Res call({
 String? optionText, String? tally
});




}
/// @nodoc
class __$YouTubePollOptionCopyWithImpl<$Res>
    implements _$YouTubePollOptionCopyWith<$Res> {
  __$YouTubePollOptionCopyWithImpl(this._self, this._then);

  final _YouTubePollOption _self;
  final $Res Function(_YouTubePollOption) _then;

/// Create a copy of YouTubePollOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? optionText = freezed,Object? tally = freezed,}) {
  return _then(_YouTubePollOption(
optionText: freezed == optionText ? _self.optionText : optionText // ignore: cast_nullable_to_non_nullable
as String?,tally: freezed == tally ? _self.tally : tally // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$YouTubeUserBannedDetails {

 YouTubeBannedUserDetails? get bannedUserDetails;/// `permanent` | `temporary`
 String? get banType;/// Only present for temporary bans (timeouts).
 int? get banDurationSeconds;
/// Create a copy of YouTubeUserBannedDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeUserBannedDetailsCopyWith<YouTubeUserBannedDetails> get copyWith => _$YouTubeUserBannedDetailsCopyWithImpl<YouTubeUserBannedDetails>(this as YouTubeUserBannedDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeUserBannedDetails&&(identical(other.bannedUserDetails, bannedUserDetails) || other.bannedUserDetails == bannedUserDetails)&&(identical(other.banType, banType) || other.banType == banType)&&(identical(other.banDurationSeconds, banDurationSeconds) || other.banDurationSeconds == banDurationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bannedUserDetails,banType,banDurationSeconds);

@override
String toString() {
  return 'YouTubeUserBannedDetails(bannedUserDetails: $bannedUserDetails, banType: $banType, banDurationSeconds: $banDurationSeconds)';
}


}

/// @nodoc
abstract mixin class $YouTubeUserBannedDetailsCopyWith<$Res>  {
  factory $YouTubeUserBannedDetailsCopyWith(YouTubeUserBannedDetails value, $Res Function(YouTubeUserBannedDetails) _then) = _$YouTubeUserBannedDetailsCopyWithImpl;
@useResult
$Res call({
 YouTubeBannedUserDetails? bannedUserDetails, String? banType, int? banDurationSeconds
});


$YouTubeBannedUserDetailsCopyWith<$Res>? get bannedUserDetails;

}
/// @nodoc
class _$YouTubeUserBannedDetailsCopyWithImpl<$Res>
    implements $YouTubeUserBannedDetailsCopyWith<$Res> {
  _$YouTubeUserBannedDetailsCopyWithImpl(this._self, this._then);

  final YouTubeUserBannedDetails _self;
  final $Res Function(YouTubeUserBannedDetails) _then;

/// Create a copy of YouTubeUserBannedDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bannedUserDetails = freezed,Object? banType = freezed,Object? banDurationSeconds = freezed,}) {
  return _then(_self.copyWith(
bannedUserDetails: freezed == bannedUserDetails ? _self.bannedUserDetails : bannedUserDetails // ignore: cast_nullable_to_non_nullable
as YouTubeBannedUserDetails?,banType: freezed == banType ? _self.banType : banType // ignore: cast_nullable_to_non_nullable
as String?,banDurationSeconds: freezed == banDurationSeconds ? _self.banDurationSeconds : banDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of YouTubeUserBannedDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeBannedUserDetailsCopyWith<$Res>? get bannedUserDetails {
    if (_self.bannedUserDetails == null) {
    return null;
  }

  return $YouTubeBannedUserDetailsCopyWith<$Res>(_self.bannedUserDetails!, (value) {
    return _then(_self.copyWith(bannedUserDetails: value));
  });
}
}


/// Adds pattern-matching-related methods to [YouTubeUserBannedDetails].
extension YouTubeUserBannedDetailsPatterns on YouTubeUserBannedDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeUserBannedDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeUserBannedDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeUserBannedDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeUserBannedDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeUserBannedDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeUserBannedDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( YouTubeBannedUserDetails? bannedUserDetails,  String? banType,  int? banDurationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeUserBannedDetails() when $default != null:
return $default(_that.bannedUserDetails,_that.banType,_that.banDurationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( YouTubeBannedUserDetails? bannedUserDetails,  String? banType,  int? banDurationSeconds)  $default,) {final _that = this;
switch (_that) {
case _YouTubeUserBannedDetails():
return $default(_that.bannedUserDetails,_that.banType,_that.banDurationSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( YouTubeBannedUserDetails? bannedUserDetails,  String? banType,  int? banDurationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeUserBannedDetails() when $default != null:
return $default(_that.bannedUserDetails,_that.banType,_that.banDurationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeUserBannedDetails implements YouTubeUserBannedDetails {
  const _YouTubeUserBannedDetails({this.bannedUserDetails, this.banType, this.banDurationSeconds});
  factory _YouTubeUserBannedDetails.fromJson(Map<String, dynamic> json) => _$YouTubeUserBannedDetailsFromJson(json);

@override final  YouTubeBannedUserDetails? bannedUserDetails;
/// `permanent` | `temporary`
@override final  String? banType;
/// Only present for temporary bans (timeouts).
@override final  int? banDurationSeconds;

/// Create a copy of YouTubeUserBannedDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeUserBannedDetailsCopyWith<_YouTubeUserBannedDetails> get copyWith => __$YouTubeUserBannedDetailsCopyWithImpl<_YouTubeUserBannedDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeUserBannedDetails&&(identical(other.bannedUserDetails, bannedUserDetails) || other.bannedUserDetails == bannedUserDetails)&&(identical(other.banType, banType) || other.banType == banType)&&(identical(other.banDurationSeconds, banDurationSeconds) || other.banDurationSeconds == banDurationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bannedUserDetails,banType,banDurationSeconds);

@override
String toString() {
  return 'YouTubeUserBannedDetails(bannedUserDetails: $bannedUserDetails, banType: $banType, banDurationSeconds: $banDurationSeconds)';
}


}

/// @nodoc
abstract mixin class _$YouTubeUserBannedDetailsCopyWith<$Res> implements $YouTubeUserBannedDetailsCopyWith<$Res> {
  factory _$YouTubeUserBannedDetailsCopyWith(_YouTubeUserBannedDetails value, $Res Function(_YouTubeUserBannedDetails) _then) = __$YouTubeUserBannedDetailsCopyWithImpl;
@override @useResult
$Res call({
 YouTubeBannedUserDetails? bannedUserDetails, String? banType, int? banDurationSeconds
});


@override $YouTubeBannedUserDetailsCopyWith<$Res>? get bannedUserDetails;

}
/// @nodoc
class __$YouTubeUserBannedDetailsCopyWithImpl<$Res>
    implements _$YouTubeUserBannedDetailsCopyWith<$Res> {
  __$YouTubeUserBannedDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeUserBannedDetails _self;
  final $Res Function(_YouTubeUserBannedDetails) _then;

/// Create a copy of YouTubeUserBannedDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bannedUserDetails = freezed,Object? banType = freezed,Object? banDurationSeconds = freezed,}) {
  return _then(_YouTubeUserBannedDetails(
bannedUserDetails: freezed == bannedUserDetails ? _self.bannedUserDetails : bannedUserDetails // ignore: cast_nullable_to_non_nullable
as YouTubeBannedUserDetails?,banType: freezed == banType ? _self.banType : banType // ignore: cast_nullable_to_non_nullable
as String?,banDurationSeconds: freezed == banDurationSeconds ? _self.banDurationSeconds : banDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of YouTubeUserBannedDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YouTubeBannedUserDetailsCopyWith<$Res>? get bannedUserDetails {
    if (_self.bannedUserDetails == null) {
    return null;
  }

  return $YouTubeBannedUserDetailsCopyWith<$Res>(_self.bannedUserDetails!, (value) {
    return _then(_self.copyWith(bannedUserDetails: value));
  });
}
}


/// @nodoc
mixin _$YouTubeBannedUserDetails {

 String? get channelId; String? get channelUrl; String? get displayName; String? get profileImageUrl;
/// Create a copy of YouTubeBannedUserDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeBannedUserDetailsCopyWith<YouTubeBannedUserDetails> get copyWith => _$YouTubeBannedUserDetailsCopyWithImpl<YouTubeBannedUserDetails>(this as YouTubeBannedUserDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeBannedUserDetails&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelUrl, channelUrl) || other.channelUrl == channelUrl)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,channelUrl,displayName,profileImageUrl);

@override
String toString() {
  return 'YouTubeBannedUserDetails(channelId: $channelId, channelUrl: $channelUrl, displayName: $displayName, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class $YouTubeBannedUserDetailsCopyWith<$Res>  {
  factory $YouTubeBannedUserDetailsCopyWith(YouTubeBannedUserDetails value, $Res Function(YouTubeBannedUserDetails) _then) = _$YouTubeBannedUserDetailsCopyWithImpl;
@useResult
$Res call({
 String? channelId, String? channelUrl, String? displayName, String? profileImageUrl
});




}
/// @nodoc
class _$YouTubeBannedUserDetailsCopyWithImpl<$Res>
    implements $YouTubeBannedUserDetailsCopyWith<$Res> {
  _$YouTubeBannedUserDetailsCopyWithImpl(this._self, this._then);

  final YouTubeBannedUserDetails _self;
  final $Res Function(YouTubeBannedUserDetails) _then;

/// Create a copy of YouTubeBannedUserDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channelId = freezed,Object? channelUrl = freezed,Object? displayName = freezed,Object? profileImageUrl = freezed,}) {
  return _then(_self.copyWith(
channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,channelUrl: freezed == channelUrl ? _self.channelUrl : channelUrl // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeBannedUserDetails].
extension YouTubeBannedUserDetailsPatterns on YouTubeBannedUserDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeBannedUserDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeBannedUserDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeBannedUserDetails value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeBannedUserDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeBannedUserDetails value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeBannedUserDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? channelId,  String? channelUrl,  String? displayName,  String? profileImageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeBannedUserDetails() when $default != null:
return $default(_that.channelId,_that.channelUrl,_that.displayName,_that.profileImageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? channelId,  String? channelUrl,  String? displayName,  String? profileImageUrl)  $default,) {final _that = this;
switch (_that) {
case _YouTubeBannedUserDetails():
return $default(_that.channelId,_that.channelUrl,_that.displayName,_that.profileImageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? channelId,  String? channelUrl,  String? displayName,  String? profileImageUrl)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeBannedUserDetails() when $default != null:
return $default(_that.channelId,_that.channelUrl,_that.displayName,_that.profileImageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _YouTubeBannedUserDetails implements YouTubeBannedUserDetails {
  const _YouTubeBannedUserDetails({this.channelId, this.channelUrl, this.displayName, this.profileImageUrl});
  factory _YouTubeBannedUserDetails.fromJson(Map<String, dynamic> json) => _$YouTubeBannedUserDetailsFromJson(json);

@override final  String? channelId;
@override final  String? channelUrl;
@override final  String? displayName;
@override final  String? profileImageUrl;

/// Create a copy of YouTubeBannedUserDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeBannedUserDetailsCopyWith<_YouTubeBannedUserDetails> get copyWith => __$YouTubeBannedUserDetailsCopyWithImpl<_YouTubeBannedUserDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeBannedUserDetails&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.channelUrl, channelUrl) || other.channelUrl == channelUrl)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,channelId,channelUrl,displayName,profileImageUrl);

@override
String toString() {
  return 'YouTubeBannedUserDetails(channelId: $channelId, channelUrl: $channelUrl, displayName: $displayName, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class _$YouTubeBannedUserDetailsCopyWith<$Res> implements $YouTubeBannedUserDetailsCopyWith<$Res> {
  factory _$YouTubeBannedUserDetailsCopyWith(_YouTubeBannedUserDetails value, $Res Function(_YouTubeBannedUserDetails) _then) = __$YouTubeBannedUserDetailsCopyWithImpl;
@override @useResult
$Res call({
 String? channelId, String? channelUrl, String? displayName, String? profileImageUrl
});




}
/// @nodoc
class __$YouTubeBannedUserDetailsCopyWithImpl<$Res>
    implements _$YouTubeBannedUserDetailsCopyWith<$Res> {
  __$YouTubeBannedUserDetailsCopyWithImpl(this._self, this._then);

  final _YouTubeBannedUserDetails _self;
  final $Res Function(_YouTubeBannedUserDetails) _then;

/// Create a copy of YouTubeBannedUserDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channelId = freezed,Object? channelUrl = freezed,Object? displayName = freezed,Object? profileImageUrl = freezed,}) {
  return _then(_YouTubeBannedUserDetails(
channelId: freezed == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String?,channelUrl: freezed == channelUrl ? _self.channelUrl : channelUrl // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
