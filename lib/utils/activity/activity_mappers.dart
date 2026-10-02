import '../../types/classes/activity/activity_event.dart';
import '../../types/classes/youtube/youtube_chat_message.dart';

/// Payload → [ActivityEvent] mappers for every source. Pure functions:
/// return null for anything the feed doesn't show. Ids are built so the
/// same real-world event gets the same id from every path of one source
/// (live socket, reconnect replay, REST backfill).

Map<String, Object?>? _map(Object? value) =>
    value is Map ? Map<String, Object?>.from(value) : null;

String? _str(Object? value) {
  if (value == null) return null;
  final text = '$value';
  return text.isEmpty ? null : text;
}

int? _int(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text),
  _ => null,
};

DateTime _time(Object? value, DateTime fallback) =>
    (value is String ? DateTime.tryParse(value) : null)?.toUtc() ??
    fallback.toUtc();

String? _tier(Map<String, Object?>? block) {
  if (block == null) return null;
  if (block['is_prime'] == true) return 'prime';
  return _str(block['sub_tier']);
}

// Twitch (EventSub)

/// EventSub notification for the user's own channel ([channelId]).
/// [messageId] is the EventSub envelope's message id, [sentAt] its
/// timestamp.
ActivityEvent? twitchActivityFromEventSub({
  required String type,
  required Map<String, Object?> event,
  required String channelId,
  required String messageId,
  required DateTime sentAt,
}) {
  ActivityEvent build({
    required String id,
    required ActivityKind kind,
    required ActivityActor actor,
    ActivityAmount? amount,
    String? tier,
    String? message,
    String? title,
    List<String> recipients = const [],
    DateTime? timestamp,
  }) => ActivityEvent(
    id: 'twitch:$channelId:$id',
    platform: ActivityPlatform.twitch,
    channelId: channelId,
    kind: kind,
    actor: actor,
    amount: amount,
    tier: tier,
    message: message,
    title: title,
    recipients: recipients,
    timestamp: timestamp ?? sentAt.toUtc(),
    sources: {ActivitySource.native: messageId},
    primarySource: ActivitySource.native,
  );

  ActivityActor user(String prefix, {bool anonymous = false}) {
    final name = _str(event['${prefix}_name']);
    if (anonymous || name == null) return ActivityActor.anonymousActor;
    return ActivityActor(
      id: _str(event['${prefix}_id']),
      login: _str(event['${prefix}_login']),
      name: name,
    );
  }

  switch (type) {
    case 'channel.follow':
      final actor = user('user');
      final userId = actor.id;
      if (userId == null) return null;
      return build(
        id: 'follow:$userId',
        kind: ActivityKind.follow,
        actor: actor,
        timestamp: _time(event['followed_at'], sentAt),
      );

    case 'channel.cheer':
      final bits = _int(event['bits']);
      if (bits == null || bits <= 0) return null;
      return build(
        id: 'cheer:$messageId',
        kind: ActivityKind.cheer,
        actor: user('user', anonymous: event['is_anonymous'] == true),
        amount: ActivityAmount(bits, ActivityUnit.bits),
        message: _str(event['message']),
      );

    case 'channel.channel_points_custom_reward_redemption.add':
      final reward = _map(event['reward']);
      final redemptionId = _str(event['id']) ?? messageId;
      final cost = _int(reward?['cost']);
      return build(
        id: 'redemption:$redemptionId',
        kind: ActivityKind.redemption,
        actor: user('user'),
        amount: cost == null ? null : ActivityAmount(cost, ActivityUnit.points),
        title: _str(reward?['title']),
        message: _str(event['user_input']),
        timestamp: _time(event['redeemed_at'], sentAt),
      );

    case 'channel.hype_train.begin':
    case 'channel.hype_train.progress':
    case 'channel.hype_train.end':
      final trainId = _str(event['id']);
      final level = _int(event['level']);
      if (trainId == null || level == null) return null;
      final contributors = <String>[
        for (final entry in (event['top_contributions'] as List?) ?? const [])
          ?_str(_map(entry)?['user_name']),
      ];
      return build(
        id: 'hypetrain:$trainId',
        kind: ActivityKind.hypeTrain,
        actor: ActivityActor.anonymousActor,
        amount: ActivityAmount(level, ActivityUnit.level),
        tier: _str(event['type']),
        recipients: contributors,
        title: type == 'channel.hype_train.end' ? 'ended' : null,
        timestamp: _time(event['started_at'], sentAt),
      );

    case 'channel.chat.notification':
      return _twitchChatNotification(event, channelId, messageId, sentAt, build);
  }
  return null;
}

ActivityEvent? _twitchChatNotification(
  Map<String, Object?> event,
  String channelId,
  String messageId,
  DateTime sentAt,
  ActivityEvent Function({
    required String id,
    required ActivityKind kind,
    required ActivityActor actor,
    ActivityAmount? amount,
    String? tier,
    String? message,
    String? title,
    List<String> recipients,
    DateTime? timestamp,
  })
  build,
) {
  final noticeType = _str(event['notice_type']) ?? '';

  /// `shared_chat_*` notices happened in another channel of a shared chat
  /// session - not the user's own activity.
  if (noticeType.startsWith('shared_chat_')) return null;
  final chatMessageId = _str(event['message_id']) ?? messageId;
  final anonymous = event['chatter_is_anonymous'] == true;
  final chatterName = _str(event['chatter_user_name']);
  final chatter = anonymous || chatterName == null
      ? ActivityActor.anonymousActor
      : ActivityActor(
          id: _str(event['chatter_user_id']),
          login: _str(event['chatter_user_login']),
          name: chatterName,
        );
  final text = _str(_map(event['message'])?['text']);

  switch (noticeType) {
    case 'sub':
      final block = _map(event['sub']);
      return build(
        id: 'sub:$chatMessageId',
        kind: ActivityKind.sub,
        actor: chatter,
        tier: _tier(block),
        message: text,
      );
    case 'resub':
      final block = _map(event['resub']);
      final months = _int(block?['cumulative_months']);
      return build(
        id: 'sub:$chatMessageId',
        kind: ActivityKind.resub,
        actor: chatter,
        tier: _tier(block),
        amount: months == null
            ? null
            : ActivityAmount(months, ActivityUnit.months),
        message: text,
      );
    case 'sub_gift':
      final block = _map(event['sub_gift']);
      final recipient = _str(block?['recipient_user_name']);
      final communityId = _str(block?['community_gift_id']);
      return build(
        /// Part of a bomb: lands on the community gift's row as one more
        /// recipient (the ledger merges recipients by id)
        id: communityId != null
            ? 'gift:$communityId'
            : 'gift:$chatMessageId',
        kind: ActivityKind.giftSub,
        actor: chatter,
        tier: _tier(block),
        amount: communityId != null
            ? null
            : const ActivityAmount(1, ActivityUnit.subs),
        recipients: [?recipient],
      );
    case 'community_sub_gift':
      final block = _map(event['community_sub_gift']);
      final total = _int(block?['total']) ?? 0;
      final communityId = _str(block?['id']) ?? chatMessageId;
      return build(
        id: 'gift:$communityId',
        kind: ActivityKind.giftSub,
        actor: chatter,
        tier: _tier(block),
        amount: ActivityAmount(total, ActivityUnit.subs),
      );
    case 'gift_paid_upgrade':
    case 'prime_paid_upgrade':
      return build(
        id: 'sub:$chatMessageId',
        kind: ActivityKind.sub,
        actor: chatter,
        tier: _tier(_map(event['prime_paid_upgrade'])),
        title: noticeType == 'gift_paid_upgrade'
            ? 'Continued a gifted sub'
            : 'Upgraded from Prime',
      );
    case 'raid':
      final block = _map(event['raid']);
      final viewers = _int(block?['viewer_count']);
      final name = _str(block?['user_name']) ?? chatterName;
      return build(
        id: 'raid:$chatMessageId',
        kind: ActivityKind.raid,
        actor: name == null
            ? chatter
            : ActivityActor(
                id: _str(block?['user_id']) ?? _str(event['chatter_user_id']),
                login: _str(block?['user_login']),
                name: name,
              ),
        amount: viewers == null
            ? null
            : ActivityAmount(viewers, ActivityUnit.viewers),
      );
    case 'charity_donation':
      final block = _map(event['charity_donation']);
      final amount = _map(block?['amount']);
      final value = _int(amount?['value']);
      final places = _int(amount?['decimal_places']) ?? 0;
      final currency = _str(amount?['currency']);
      var divisor = 1;
      for (var i = 0; i < places; i++) {
        divisor *= 10;
      }
      return build(
        id: 'charity:$chatMessageId',
        kind: ActivityKind.charity,
        actor: chatter,
        amount: value == null || currency == null
            ? null
            : ActivityAmount(value / divisor, currency),
        title: _str(block?['charity_name']),
      );
  }
  return null;
}

/// One row of `GET /helix/channels/followers` (newest first).
ActivityEvent? twitchActivityFromFollower(
  Map<String, Object?> row,
  String channelId,
) {
  final userId = _str(row['user_id']);
  final name = _str(row['user_name']);
  final at = DateTime.tryParse('${row['followed_at']}');
  if (userId == null || name == null || at == null) return null;
  return ActivityEvent(
    id: 'twitch:$channelId:follow:$userId',
    platform: ActivityPlatform.twitch,
    channelId: channelId,
    kind: ActivityKind.follow,
    actor: ActivityActor(id: userId, login: _str(row['user_login']), name: name),
    timestamp: at.toUtc(),
    sources: {ActivitySource.native: 'follow:$userId'},
    primarySource: ActivitySource.native,
  );
}

// YouTube (live chat poll)

ActivityEvent? youTubeActivityFromMessage(
  YouTubeChatMessage message,
  String channelId,
) {
  final snippet = message.snippet;
  final name = message.authorName;
  final actor = name == null
      ? ActivityActor.anonymousActor
      : ActivityActor(id: message.authorChannelId, name: name);

  ActivityAmount? money(String? micros, String? currency, String? display) {
    final value = int.tryParse(micros ?? '');
    if (value == null || currency == null || currency.isEmpty) return null;
    return ActivityAmount(value / 1000000, currency, display: display);
  }

  ActivityEvent build(
    ActivityKind kind, {
    ActivityAmount? amount,
    String? tier,
    String? text,
    String? title,
    List<String> recipients = const [],
  }) => ActivityEvent(
    id: 'youtube:$channelId:${message.id}',
    platform: ActivityPlatform.youtube,
    channelId: channelId,
    kind: kind,
    actor: actor,
    amount: amount,
    tier: tier,
    message: text,
    title: title,
    recipients: recipients,
    timestamp: snippet.publishedAt.toUtc(),
    sources: {ActivitySource.native: message.id},
    primarySource: ActivitySource.native,
  );

  switch (message.type) {
    case YouTubeChatMessageType.superChat:
      final details = snippet.superChatDetails;
      return build(
        ActivityKind.superChat,
        amount: money(
          details?.amountMicros,
          details?.currency,
          details?.amountDisplayString,
        ),
        text: details?.userComment,
      );
    case YouTubeChatMessageType.superSticker:
      final details = snippet.superStickerDetails;
      return build(
        ActivityKind.superSticker,
        amount: money(
          details?.amountMicros,
          details?.currency,
          details?.amountDisplayString,
        ),
        title: details?.superStickerMetadata?.altText,
      );
    case YouTubeChatMessageType.newSponsor:
      final details = snippet.newSponsorDetails;
      return build(
        ActivityKind.member,
        tier: details?.memberLevelName,
        title: (details?.isUpgrade ?? false) ? 'Upgraded' : null,
      );
    case YouTubeChatMessageType.memberMilestone:
      final details = snippet.memberMilestoneChatDetails;
      final months = details?.memberMonth ?? 0;
      return build(
        ActivityKind.memberMilestone,
        tier: details?.memberLevelName,
        amount: months > 0 ? ActivityAmount(months, ActivityUnit.months) : null,
        text: details?.userComment,
      );
    case YouTubeChatMessageType.membershipGifting:
      final details = snippet.membershipGiftingDetails;
      final count = details?.giftMembershipsCount ?? 0;
      return build(
        ActivityKind.memberGift,
        tier: details?.giftMembershipsLevelName,
        amount: count > 0 ? ActivityAmount(count, ActivityUnit.subs) : null,
      );
    default:
      return null;
  }
}

// Kick (Pusher, native - payload shapes guessed, see kick-chat-audit)

/// [channelId] is the own Kick user id, [eventId] something stable per
/// event if Pusher had one, else a synthetic one.
ActivityEvent? kickActivityFromPusher({
  required String kind,
  required String channelId,
  required String eventId,
  required DateTime at,
  String? username,
  int? months,
  List<String> recipients = const [],
  int? viewers,
}) {
  final actor = username == null
      ? ActivityActor.anonymousActor
      : ActivityActor(login: username.toLowerCase(), name: username);
  final (ActivityKind activityKind, ActivityAmount? amount) = switch (kind) {
    'subscription' => (
      (months ?? 1) > 1 ? ActivityKind.resub : ActivityKind.sub,
      (months ?? 1) > 1 ? ActivityAmount(months!, ActivityUnit.months) : null,
    ),
    'gift' => (
      ActivityKind.giftSub,
      ActivityAmount(recipients.length, ActivityUnit.subs),
    ),
    'host' => (
      ActivityKind.host,
      viewers == null ? null : ActivityAmount(viewers, ActivityUnit.viewers),
    ),
    _ => (ActivityKind.other, null),
  };
  if (activityKind == ActivityKind.other) return null;
  return ActivityEvent(
    id: 'kick:$channelId:pusher:$eventId',
    platform: ActivityPlatform.kick,
    channelId: channelId,
    kind: activityKind,
    actor: actor,
    amount: amount,
    recipients: recipients,
    timestamp: at.toUtc(),
    sources: {ActivitySource.native: eventId},
    primarySource: ActivitySource.native,
  );
}

// Kick (relay - official webhook payloads, KickDevDocs event-types.md)

ActivityActor _kickUser(Object? value) {
  final user = _map(value);
  if (user == null || user['is_anonymous'] == true) {
    return ActivityActor.anonymousActor;
  }
  final name = _str(user['username']);
  if (name == null) return ActivityActor.anonymousActor;
  return ActivityActor(
    id: _str(user['user_id']),
    login: _str(user['channel_slug']) ?? name.toLowerCase(),
    name: name,
  );
}

/// One relay `event` frame: `event_type`, `message_id`, `timestamp`,
/// `payload`. Stream status frames return null here - the store reads
/// them for sessions (see [kickRelayLiveStatus]).
ActivityEvent? kickActivityFromRelay(Map<String, Object?> frame) {
  final type = _str(frame['event_type']);
  final messageId = _str(frame['message_id']);
  final payload = _map(frame['payload']);
  if (type == null || messageId == null || payload == null) return null;
  final channelId = _str(_map(payload['broadcaster'])?['user_id']);
  if (channelId == null) return null;
  final sentAt = _time(frame['timestamp'], DateTime.now());

  ActivityEvent build(
    String id,
    ActivityKind kind,
    ActivityActor actor, {
    ActivityAmount? amount,
    String? tier,
    String? message,
    String? title,
    List<String> recipients = const [],
    DateTime? timestamp,
  }) => ActivityEvent(
    id: 'kick:$channelId:$id',
    platform: ActivityPlatform.kick,
    channelId: channelId,
    kind: kind,
    actor: actor,
    amount: amount,
    tier: tier,
    message: message,
    title: title,
    recipients: recipients,
    timestamp: timestamp ?? sentAt,
    sources: {ActivitySource.kickRelay: messageId},
    primarySource: ActivitySource.kickRelay,
  );

  switch (type) {
    case 'channel.followed':
      final actor = _kickUser(payload['follower']);
      final key = actor.id ?? actor.login ?? messageId;
      return build('follow:$key', ActivityKind.follow, actor);
    case 'channel.subscription.new':
    case 'channel.subscription.renewal':
      final months = _int(payload['duration']);
      final renewal = type == 'channel.subscription.renewal';
      return build(
        'sub:$messageId',
        renewal ? ActivityKind.resub : ActivityKind.sub,
        _kickUser(payload['subscriber']),
        amount: renewal && months != null
            ? ActivityAmount(months, ActivityUnit.months)
            : null,
        timestamp: _time(payload['created_at'], sentAt),
      );
    case 'channel.subscription.gifts':
      final giftees = <String>[
        for (final giftee in (payload['giftees'] as List?) ?? const [])
          ?_str(_map(giftee)?['username']),
      ];
      return build(
        'gift:$messageId',
        ActivityKind.giftSub,
        _kickUser(payload['gifter']),
        amount: ActivityAmount(
          giftees.isEmpty ? 1 : giftees.length,
          ActivityUnit.subs,
        ),
        recipients: giftees,
        timestamp: _time(payload['created_at'], sentAt),
      );
    case 'kicks.gifted':
      final gift = _map(payload['gift']);
      final amount = _int(gift?['amount']);
      return build(
        'kicks:$messageId',
        ActivityKind.kicks,
        _kickUser(payload['sender']),
        amount: amount == null
            ? null
            : ActivityAmount(amount, ActivityUnit.kicks),
        title: _str(gift?['name']),
        tier: _str(gift?['tier']),
        message: _str(gift?['message']),
        timestamp: _time(payload['created_at'], sentAt),
      );
    case 'channel.reward.redemption.updated':

      /// Every status change re-sends the redemption; one row per
      /// redemption id (the latest status wins in the merge)
      final reward = _map(payload['reward']);
      final redemptionId = _str(payload['id']) ?? messageId;
      final cost = _int(reward?['cost']);
      return build(
        'redemption:$redemptionId',
        ActivityKind.redemption,
        _kickUser(payload['redeemer']),
        amount: cost == null ? null : ActivityAmount(cost, ActivityUnit.points),
        title: _str(reward?['title']),
        message: _str(payload['user_input']),
        timestamp: _time(payload['redeemed_at'], sentAt),
      );
  }
  return null;
}

/// `livestream.status.updated` relay frame → (channel id, live, at).
(String, bool, DateTime)? kickRelayLiveStatus(Map<String, Object?> frame) {
  if (_str(frame['event_type']) != 'livestream.status.updated') return null;
  final payload = _map(frame['payload']);
  final channelId = _str(_map(payload?['broadcaster'])?['user_id']);
  final live = payload?['is_live'];
  if (channelId == null || live is! bool) return null;
  final at = live
      ? _time(payload?['started_at'], DateTime.now())
      : _time(payload?['ended_at'], DateTime.now());
  return (channelId, live, at);
}
