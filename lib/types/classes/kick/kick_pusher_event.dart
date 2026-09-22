import 'dart:convert';

import 'kick_chat_message.dart';

/// Classification of the app events broadcast on `chatrooms.{id}.v2`.
/// Matched by name SUFFIX — the `App\Events\` prefix varies and
/// `ChatMessageSentEvent` is a newer alias of `ChatMessageEvent`.
enum KickChatroomEventKind {
  message,
  messageDeleted,
  userBanned,
  userUnbanned,
  chatroomClear,
  chatroomUpdated,

  /// Pin create/delete. Create carries the chat message under `message`;
  /// delete clears the channel's single pin.
  pinnedMessage,

  /// A viewer subscribed (`{chatroom_id, username, months}`) — field
  /// names are reverse-engineered (Kick's public API has no Pusher
  /// schema docs; see `docs/kick-chat-audit.md`), not confirmed against
  /// a live capture. Parsing is defensive: a missing/renamed field
  /// degrades to no notice rather than a garbled one.
  subscription,

  /// One user gifted N subs (`{chatroom_id, gifted_usernames,
  /// gifter_username}`) — same reverse-engineered caveat as
  /// [subscription].
  giftedSubscriptions,

  /// Another channel hosted this one (`{chatroom_id, optional_message,
  /// number_viewers, host_username}`) — same reverse-engineered caveat
  /// as [subscription].
  streamHost,
  unknown,
}

/// One decoded Pusher frame on a Kick chatroom channel: `{event, channel,
/// data}` where `data` is a JSON-encoded string (decoded into [data]).
/// Hand-rolled — freezed buys nothing for an envelope this flat.
class KickPusherEvent {
  final String event;
  final String? channel;
  final Map<String, Object?> data;

  const KickPusherEvent({
    required this.event,
    this.channel,
    this.data = const <String, Object?>{},
  });

  /// Parses one raw socket frame. Returns null on junk (non-JSON, no
  /// event name) — a malformed frame must never break the socket loop.
  static KickPusherEvent? parse(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      final event = decoded['event'];
      if (event is! String) return null;
      return KickPusherEvent(
        event: event,
        channel: decoded['channel'] as String?,
        data: kickJsonObject(decoded['data']) ?? const <String, Object?>{},
      );
    } catch (_) {
      return null;
    }
  }

  KickChatroomEventKind get kind {
    final name = this.event;

    /// Pinned events end in `Message…Event` too — classify them before
    /// the plain message/delete suffixes.
    if (name.endsWith('PinnedMessageCreatedEvent') ||
        name.endsWith('PinnedMessageDeletedEvent')) {
      return KickChatroomEventKind.pinnedMessage;
    }
    if (name.endsWith('ChatMessageEvent') ||
        name.endsWith('ChatMessageSentEvent')) {
      return KickChatroomEventKind.message;
    }
    if (name.endsWith('MessageDeletedEvent')) {
      return KickChatroomEventKind.messageDeleted;
    }
    if (name.endsWith('UserBannedEvent')) {
      return KickChatroomEventKind.userBanned;
    }
    if (name.endsWith('UserUnbannedEvent')) {
      return KickChatroomEventKind.userUnbanned;
    }
    if (name.endsWith('ChatroomClearEvent')) {
      return KickChatroomEventKind.chatroomClear;
    }
    if (name.endsWith('ChatroomUpdatedEvent')) {
      return KickChatroomEventKind.chatroomUpdated;
    }

    /// Check the longer/plural suffix first — disjoint from
    /// `SubscriptionEvent` either way, but explicit ordering documents
    /// the intent.
    if (name.endsWith('GiftedSubscriptionsEvent')) {
      return KickChatroomEventKind.giftedSubscriptions;
    }
    if (name.endsWith('SubscriptionEvent')) {
      return KickChatroomEventKind.subscription;
    }
    if (name.endsWith('StreamHostEvent')) {
      return KickChatroomEventKind.streamHost;
    }
    return KickChatroomEventKind.unknown;
  }

  /// `MessageDeletedEvent` — `{id, message: {id}}`; the outer id is the
  /// event's own, the nested one the deleted message's (fallback: outer).
  String? get deletedMessageId {
    final nested = kickJsonObject(this.data['message'])?['id'];
    if (nested is String) return nested;
    return this.data['id'] as String?;
  }

  bool get isPinDeleted => this.event.endsWith('PinnedMessageDeletedEvent');

  /// The chat line inside a `PinnedMessageCreatedEvent` (`message` object,
  /// or the payload itself when it is already a chat message).
  KickChatMessage? get pinnedChatMessage => kickPinnedMessage(this.data);

  /// `UserBannedEvent` / `UserUnbannedEvent` — `{user: {id, ...}}`.
  int? get targetUserId {
    final id = kickJsonObject(this.data['user'])?['id'];
    return id is int ? id : null;
  }

  /// `SubscriptionEvent` — `{username, months}`. Null when either field
  /// is missing (the reverse-engineered shape doesn't hold) — the store
  /// skips the notice rather than showing a garbled one.
  String? get subscriberUsername => this.data['username'] as String?;

  int? get subscriptionMonths => (this.data['months'] as num?)?.toInt();

  /// `GiftedSubscriptionsEvent` — `{gifter_username, gifted_usernames}`.
  String? get gifterUsername => this.data['gifter_username'] as String?;

  List<String> get giftedUsernames =>
      (this.data['gifted_usernames'] as List?)?.whereType<String>().toList() ??
      const <String>[];

  /// `StreamHostEvent` — `{host_username, number_viewers,
  /// optional_message}`.
  String? get hostUsername => this.data['host_username'] as String?;

  int? get hostViewerCount => (this.data['number_viewers'] as num?)?.toInt();

  String? get hostMessage => this.data['optional_message'] as String?;
}
