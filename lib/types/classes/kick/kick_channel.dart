import 'package:freezed_annotation/freezed_annotation.dart';

part 'kick_channel.freezed.dart';
part 'kick_channel.g.dart';

Object? _readUsername(Map<dynamic, dynamic> json, String key) =>
    kickChannelJsonMap(json['user'])?['username'];

Object? _readBadgeImage(Map<dynamic, dynamic> json, String key) =>
    kickChannelJsonMap(json['badge_image'])?['src'];

Map<String, Object?>? kickChannelJsonMap(Object? raw) =>
    raw is Map ? raw.cast<String, Object?>() : null;

/// Resolution payload of `GET https://kick.com/api/v2/channels/{slug}` —
/// no auth. The chatroom id inside [chatroom] is the Pusher subscription
/// target (`chatrooms.{id}.v2`); [livestream] is null while offline.
@Freezed(fromJson: true, toJson: false)
abstract class KickChannelInfo with _$KickChannelInfo {
  const KickChannelInfo._();

  const factory KickChannelInfo({
    required int id,
    @JsonKey(name: 'user_id') int? userId,
    required String slug,

    /// Display name lives under `user.username`.
    @JsonKey(readValue: _readUsername) String? username,
    required KickChatroom chatroom,
    @JsonKey(name: 'subscriber_badges')
    @Default(<KickSubscriberBadge>[])
    List<KickSubscriberBadge> subscriberBadges,
    KickLivestreamInfo? livestream,
  }) = _KickChannelInfo;

  factory KickChannelInfo.fromJson(Map<String, Object?> json) =>
      _$KickChannelInfoFromJson(json);

  int get chatroomId => this.chatroom.id;
  bool get isLive => this.livestream?.isLive ?? false;
  int? get viewerCount => this.livestream?.viewerCount;
}

/// Chatroom descriptor — the moderation modes ride
/// `ChatroomUpdatedEvent` payloads in the same shape.
@Freezed(fromJson: true, toJson: false)
abstract class KickChatroom with _$KickChatroom {
  const factory KickChatroom({
    required int id,
    @JsonKey(name: 'slow_mode') @Default(false) bool slowMode,
    @JsonKey(name: 'followers_mode') @Default(false) bool followersMode,
    @JsonKey(name: 'subscribers_mode') @Default(false) bool subscribersMode,
    @JsonKey(name: 'emotes_mode') @Default(false) bool emotesMode,
    @JsonKey(name: 'message_interval') @Default(0) int messageInterval,
    @JsonKey(name: 'following_min_duration')
    @Default(0)
    int followingMinDuration,
  }) = _KickChatroom;

  factory KickChatroom.fromJson(Map<String, Object?> json) =>
      _$KickChatroomFromJson(json);
}

/// Per-tenure subscriber badge artwork (months → image), resolved at the
/// channel level — v2 message badges already carry their own `image_url`.
@Freezed(fromJson: true, toJson: false)
abstract class KickSubscriberBadge with _$KickSubscriberBadge {
  const factory KickSubscriberBadge({
    @Default(0) int months,
    @JsonKey(name: 'badge_image', readValue: _readBadgeImage) String? imageUrl,
  }) = _KickSubscriberBadge;

  factory KickSubscriberBadge.fromJson(Map<String, Object?> json) =>
      _$KickSubscriberBadgeFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class KickLivestreamInfo with _$KickLivestreamInfo {
  const factory KickLivestreamInfo({
    @JsonKey(name: 'is_live') @Default(false) bool isLive,
    @JsonKey(name: 'viewer_count') int? viewerCount,
  }) = _KickLivestreamInfo;

  factory KickLivestreamInfo.fromJson(Map<String, Object?> json) =>
      _$KickLivestreamInfoFromJson(json);
}
