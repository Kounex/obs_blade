import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'kick_chat_message.freezed.dart';
part 'kick_chat_message.g.dart';

/// Typed view on the `type` field of a Kick chat message. `system` is
/// local-only (synthetic notices the store appends, e.g. after a
/// `/clear`) — it never arrives on the wire; unknown wire values degrade
/// to [message] so parsing never breaks forward-compat.
enum KickChatMessageType {
  message,
  reply,
  system;

  static KickChatMessageType parse(Object? value) =>
      value == 'reply' ? reply : message;
}

/// Kick payloads are shape-unstable across endpoints: in the history
/// backfill (`/api/v2/channels/{id}/messages`) nested objects like
/// `metadata` may arrive as a JSON-encoded STRING, while live Pusher
/// events carry them as objects. Accepts both (plus junk → null).
/// A pin from history (`data.pinned_message`) or a live
/// `PinnedMessageCreatedEvent`: `{message: <chat message>, ...}`.
/// The nested message is the original chat line. Null when nothing is
/// pinned or the payload is junk.
KickChatMessage? kickPinnedMessage(Object? raw) {
  final map = kickJsonObject(raw);
  if (map == null) return null;
  final nested = kickJsonObject(map['message']);
  final source = nested ?? map;
  if (source['id'] is! String) return null;
  try {
    return KickChatMessage.fromJson(source);
  } catch (_) {
    return null;
  }
}

Map<String, Object?>? kickJsonObject(Object? raw) {
  if (raw is Map) return raw.cast<String, Object?>();
  if (raw is String) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) return decoded.cast<String, Object?>();
    } catch (_) {
      // not JSON — treat as absent
    }
  }
  return null;
}

/// A chat message of a Kick chatroom — the shared shape of the history
/// backfill and the live `ChatMessageEvent` / `ChatMessageSentEvent`
/// Pusher payloads.
@Freezed(fromJson: true, toJson: false)
abstract class KickChatMessage with _$KickChatMessage {
  const KickChatMessage._();

  const factory KickChatMessage({
    required String id,
    @JsonKey(name: 'chatroom_id') int? chatroomId,
    @Default('') String content,

    /// `message` | `reply` on the wire — [KickChatMessageType.system] is
    /// synthetic (never parsed).
    @JsonKey(fromJson: KickChatMessageType.parse)
    @Default(KickChatMessageType.message)
    KickChatMessageType type,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    KickChatSender? sender,
    @JsonKey(fromJson: KickChatMessageMetadata.parse)
    KickChatMessageMetadata? metadata,

    /// Local lifecycle flag — set by the chat store when a
    /// `MessageDeletedEvent` / `UserBannedEvent` arrives for this message
    /// (dim + marker, same UX as Twitch/YouTube); never part of the
    /// wire JSON.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isTombstoned,

    /// Loaded by the join backfill (sent before this session joined) —
    /// rendered dimmed, with the "New messages" divider after the last one.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isHistorical,
  }) = _KickChatMessage;

  factory KickChatMessage.fromJson(Map<String, Object?> json) =>
      _$KickChatMessageFromJson(json);

  String get authorName => this.sender?.username ?? 'Unknown';
  int? get authorId => this.sender?.id;
}

@Freezed(fromJson: true, toJson: false)
abstract class KickChatSender with _$KickChatSender {
  const factory KickChatSender({
    int? id,
    String? username,
    String? slug,
    KickChatIdentity? identity,
  }) = _KickChatSender;

  factory KickChatSender.fromJson(Map<String, Object?> json) =>
      _$KickChatSenderFromJson(json);
}

/// Sender cosmetics: chat color plus both badge generations. [badgesV2]
/// entries carry artwork (`image_url`); legacy [badges] are text/glyph
/// descriptors only (`{type, text, count?}` — count = months/gifts).
@Freezed(fromJson: true, toJson: false)
abstract class KickChatIdentity with _$KickChatIdentity {
  const KickChatIdentity._();

  const factory KickChatIdentity({
    String? color,
    @Default(<KickChatLegacyBadge>[]) List<KickChatLegacyBadge> badges,
    @JsonKey(name: 'badges_v2')
    @Default(<KickChatBadgeV2>[])
    List<KickChatBadgeV2> badgesV2,
  }) = _KickChatIdentity;

  factory KickChatIdentity.fromJson(Map<String, Object?> json) =>
      _$KickChatIdentityFromJson(json);

  /// The badges to render: `selected` entries with artwork when any are
  /// flagged, otherwise every v2 badge that has artwork.
  List<KickChatBadgeV2> get displayBadges {
    final withArt = this.badgesV2.where(
      (badge) => badge.imageUrl != null && badge.imageUrl!.isNotEmpty,
    );
    final selected = withArt.where((badge) => badge.selected).toList();
    return selected.isNotEmpty ? selected : withArt.toList();
  }
}

@Freezed(fromJson: true, toJson: false)
abstract class KickChatBadgeV2 with _$KickChatBadgeV2 {
  const factory KickChatBadgeV2({
    String? name,
    @JsonKey(name: 'badge_type') String? badgeType,
    @JsonKey(name: 'image_url') String? imageUrl,

    /// Free-form extras (e.g. `{"level": 32}`) — same String-or-Map
    /// instability as message metadata.
    @JsonKey(fromJson: kickJsonObject) Map<String, Object?>? metadata,
    @Default(false) bool selected,
    @JsonKey(name: 'sort_order') int? sortOrder,
  }) = _KickChatBadgeV2;

  factory KickChatBadgeV2.fromJson(Map<String, Object?> json) =>
      _$KickChatBadgeV2FromJson(json);
}

/// Legacy badge descriptor — no artwork in the payload, the row renders
/// these as small text chips (only when no v2 badge has artwork).
@Freezed(fromJson: true, toJson: false)
abstract class KickChatLegacyBadge with _$KickChatLegacyBadge {
  const factory KickChatLegacyBadge({String? type, String? text, int? count}) =
      _KickChatLegacyBadge;

  factory KickChatLegacyBadge.fromJson(Map<String, Object?> json) =>
      _$KickChatLegacyBadgeFromJson(json);
}

/// Message extras: `message_ref` on every message; replies additionally
/// carry `original_sender` / `original_message`, themselves unstable in
/// shape (plain string or nested object) — flattened to display strings
/// here. Hand-rolled: the whole object may arrive as a JSON-encoded
/// string, which freezed field converters can't fix at this level.
class KickChatMessageMetadata {
  final String? messageRef;
  final String? originalSenderName;
  final String? originalMessageContent;

  const KickChatMessageMetadata({
    this.messageRef,
    this.originalSenderName,
    this.originalMessageContent,
  });

  static String? _displayString(Object? raw, String key) {
    if (raw is String) return raw;
    final map = kickJsonObject(raw);
    final value = map?[key];
    return value is String ? value : null;
  }

  static KickChatMessageMetadata? parse(Object? raw) {
    final map = kickJsonObject(raw);
    if (map == null) return null;
    return KickChatMessageMetadata(
      messageRef: map['message_ref'] as String?,
      originalSenderName: _displayString(map['original_sender'], 'username'),
      originalMessageContent: _displayString(
        map['original_message'],
        'content',
      ),
    );
  }
}

/// One piece of message content — plain text or an emote reference.
/// Kick inlines emotes as `[emote:{id}:{name}]` tokens inside `content`.
class KickChatFragment {
  final String text;
  final int? emoteId;
  final String? emoteName;

  const KickChatFragment.text(this.text) : emoteId = null, emoteName = null;

  const KickChatFragment.emote(this.emoteId, this.emoteName) : text = '';

  bool get isEmote => this.emoteId != null;
}

final RegExp kickEmoteTokenPattern = RegExp(r'\[emote:(\d+):([^\]]+)\]');

String kickEmoteUrl(int emoteId) =>
    'https://files.kick.com/emotes/$emoteId/fullsize';

/// Splits [content] into text/emote fragments in order. Emote tokens with
/// a malformed id degrade to their raw text (never dropped).
List<KickChatFragment> parseKickChatContent(String content) {
  if (content.isEmpty) return const [];
  final fragments = <KickChatFragment>[];
  var cursor = 0;
  for (final match in kickEmoteTokenPattern.allMatches(content)) {
    if (match.start > cursor) {
      fragments.add(
        KickChatFragment.text(content.substring(cursor, match.start)),
      );
    }
    final id = int.tryParse(match.group(1)!);
    if (id == null) {
      fragments.add(KickChatFragment.text(match.group(0)!));
    } else {
      fragments.add(KickChatFragment.emote(id, match.group(2)!));
    }
    cursor = match.end;
  }
  if (cursor < content.length) {
    fragments.add(KickChatFragment.text(content.substring(cursor)));
  }
  return fragments;
}
