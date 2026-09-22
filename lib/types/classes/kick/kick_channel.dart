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

/// Chatroom descriptor — this flat-boolean shape is what the
/// channel-resolve REST call returns. The live `ChatroomUpdatedEvent`
/// Pusher payload nests each mode instead (see
/// [kickNormalizeChatroomUpdate]); run that first when parsing one.
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

/// `ChatroomUpdatedEvent`'s live Pusher payload nests each mode's toggle
/// under `{enabled: bool, ...}` (`slow_mode.message_interval`,
/// `followers_mode.min_duration`) instead of the flat booleans/ints
/// [KickChatroom.fromJson] expects — the shape reverse-engineered from a
/// community TS gist (Kick has no public schema docs for this event;
/// single-sourced, so treated as best-effort, not gospel). Flattens any
/// nested mode keys in place; already-flat values (the REST shape) pass
/// through untouched, so this is a safe no-op there too.
Map<String, Object?> kickNormalizeChatroomUpdate(Map<String, Object?> raw) {
  final result = Map<String, Object?>.of(raw);
  void flatten(
    String key, {
    String? flatIntervalKey,
    String? nestedIntervalKey,
  }) {
    final nested = result[key];
    if (nested is! Map) return;
    final map = nested.cast<String, Object?>();
    result[key] = map['enabled'] == true;
    final interval = nestedIntervalKey != null ? map[nestedIntervalKey] : null;
    if (flatIntervalKey != null && interval != null) {
      result[flatIntervalKey] = interval;
    }
  }

  flatten(
    'slow_mode',
    flatIntervalKey: 'message_interval',
    nestedIntervalKey: 'message_interval',
  );
  flatten('subscribers_mode');
  flatten(
    'followers_mode',
    flatIntervalKey: 'following_min_duration',
    nestedIntervalKey: 'min_duration',
  );
  flatten('emotes_mode');
  return result;
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
