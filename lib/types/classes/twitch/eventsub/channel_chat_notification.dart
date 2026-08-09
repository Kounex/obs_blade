import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';

part 'channel_chat_notification.freezed.dart';
part 'channel_chat_notification.g.dart';

/// `channel.chat.notification` — subs, gifts, raids, watch streaks, etc.
/// UI uses [systemMessage] + [noticeType] for copy/icon/accent; typed
/// blocks feed the same-line meta chip (`Name · 450`).
@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationEvent with _$ChatNotificationEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationEvent({
    required String broadcasterUserId,
    required String chatterUserId,
    required String chatterUserLogin,
    required String chatterUserName,
    required String messageId,
    required String systemMessage,
    required String noticeType,
    /// Chatter name color (hex), not the announcement highlight.
    String? color,
    @Default(<ChatMessageBadge>[]) List<ChatMessageBadge> badges,
    /// Optional message the chatter attached (often empty — the typed
    /// chat line may arrive separately as `channel.chat.message`).
    ChatMessageText? message,
    /// Present when [noticeType] is `announcement` — Helix highlight
    /// (`blue` / `green` / `orange` / `purple` / `primary`).
    ChatNotificationAnnouncement? announcement,
    ChatNotificationWatchStreak? watchStreak,
    ChatNotificationRaid? raid,
    ChatNotificationSubGift? subGift,
    ChatNotificationCommunitySubGift? communitySubGift,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'bits_badge_tier')
    ChatNotificationBitsBadgeTier? bitsBadgeTier,
    ChatNotificationCharityDonation? charityDonation,
  }) = _ChatNotificationEvent;

  factory ChatNotificationEvent.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationEventFromJson(_promoteSharedChatBlocks(json));
}

/// Copies `shared_chat_<key>` onto `<key>` when the primary slot is null
/// so shared-chat notices reuse the same typed fields. Also normalizes
/// nested maps so a `Map<dynamic, dynamic>` announcement never blows up
/// the whole notification parse (which would drop the banner entirely).
Map<String, dynamic> _promoteSharedChatBlocks(Map<String, Object?> json) {
  final out = Map<String, dynamic>.from(json);
  const keys = <String>[
    'announcement',
    'watch_streak',
    'raid',
    'sub_gift',
    'community_sub_gift',
    'bits_badge_tier',
    'charity_donation',
  ];
  for (final key in keys) {
    if (out[key] == null && out['shared_chat_$key'] != null) {
      out[key] = out['shared_chat_$key'];
    }
    final value = out[key];
    if (value is Map) {
      out[key] = Map<String, dynamic>.from(value);
    }
  }
  return out;
}

/// Nested `announcement` / `shared_chat_announcement` block.
@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationAnnouncement
    with _$ChatNotificationAnnouncement {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationAnnouncement({
    /// `blue` | `green` | `orange` | `purple` | `primary`.
    required String color,
  }) = _ChatNotificationAnnouncement;

  /// Tolerates missing / odd casing (`ORANGE` from IRC-style sources).
  factory ChatNotificationAnnouncement.fromJson(Map<String, Object?> json) {
    final raw = json['color']?.toString().trim().toLowerCase();
    return ChatNotificationAnnouncement(
      color: (raw == null || raw.isEmpty) ? 'primary' : raw,
    );
  }
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationWatchStreak
    with _$ChatNotificationWatchStreak {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationWatchStreak({
    required int streakCount,
    @Default(0) int channelPointsAwarded,
  }) = _ChatNotificationWatchStreak;

  factory ChatNotificationWatchStreak.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationWatchStreakFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationRaid with _$ChatNotificationRaid {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationRaid({
    required int viewerCount,
    String? userName,
    String? userLogin,
  }) = _ChatNotificationRaid;

  factory ChatNotificationRaid.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationRaidFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationSubGift with _$ChatNotificationSubGift {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationSubGift({
    /// Twitch docs use `sub_plan` (`1000` / `2000` / `3000`).
    String? subPlan,
    int? cumulativeTotal,
    String? recipientUserName,
  }) = _ChatNotificationSubGift;

  factory ChatNotificationSubGift.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationSubGiftFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationCommunitySubGift
    with _$ChatNotificationCommunitySubGift {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationCommunitySubGift({
    required int total,
    String? subPlan,
    int? cumulativeTotal,
  }) = _ChatNotificationCommunitySubGift;

  factory ChatNotificationCommunitySubGift.fromJson(
    Map<String, Object?> json,
  ) =>
      _$ChatNotificationCommunitySubGiftFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationBitsBadgeTier
    with _$ChatNotificationBitsBadgeTier {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationBitsBadgeTier({
    required int tier,
  }) = _ChatNotificationBitsBadgeTier;

  factory ChatNotificationBitsBadgeTier.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationBitsBadgeTierFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationCharityDonation
    with _$ChatNotificationCharityDonation {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationCharityDonation({
    String? charityName,
    ChatNotificationCharityAmount? amount,
  }) = _ChatNotificationCharityDonation;

  factory ChatNotificationCharityDonation.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationCharityDonationFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class ChatNotificationCharityAmount
    with _$ChatNotificationCharityAmount {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
  const factory ChatNotificationCharityAmount({
    required int value,
    /// Twitch docs alternate `decimal_places` / `decimal_place`.
    @JsonKey(name: 'decimal_places') int? decimalPlaces,
    @JsonKey(name: 'decimal_place') int? decimalPlace,
    String? currency,
  }) = _ChatNotificationCharityAmount;

  factory ChatNotificationCharityAmount.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationCharityAmountFromJson(json);
}

extension ChatNotificationCharityAmountFormat on ChatNotificationCharityAmount {
  String? get formatted {
    final places = this.decimalPlaces ?? this.decimalPlace ?? 2;
    final major = this.value / (places <= 0 ? 1 : _pow10(places));
    final code = this.currency;
    if (code == null || code.isEmpty) {
      return major == major.roundToDouble()
          ? '${major.round()}'
          : major.toStringAsFixed(places.clamp(0, 4));
    }
    return '${major.toStringAsFixed(places.clamp(0, 4))} $code';
  }
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

/// Timeline wrapper — arrival seq for merge with messages / /clear banners.
class ChatNotificationNotice {
  final int afterSeq;
  final ChatNotificationEvent event;

  const ChatNotificationNotice({
    required this.afterSeq,
    required this.event,
  });
}

String _normalizeNoticeType(String noticeType) =>
    noticeType.startsWith('shared_chat_')
        ? noticeType.substring('shared_chat_'.length)
        : noticeType;

String? _tierShort(String? subPlan) {
  final value = int.tryParse(subPlan ?? '');
  if (value == null) return null;
  return 'Tier ${value ~/ 1000}';
}

String _compactInt(int value) {
  if (value >= 1000000) {
    final m = value / 1000000;
    if (m == m.roundToDouble()) return '${m.round()}M';
    return '${m.toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final k = value / 1000;
    if (k == k.roundToDouble()) return '${k.round()}k';
    return '${k.toStringAsFixed(1)}k';
  }
  return '$value';
}

/// Same-line meta after the notice author (`Name · meta`). Null = omit.
String? chatNoticeMetaText(ChatNotificationEvent event) {
  switch (_normalizeNoticeType(event.noticeType)) {
    case 'watch_streak':
      final points = event.watchStreak?.channelPointsAwarded ?? 0;
      return points > 0 ? _compactInt(points) : null;
    case 'raid':
      final viewers = event.raid?.viewerCount;
      return viewers == null ? null : _compactInt(viewers);
    case 'community_sub_gift':
      final gift = event.communitySubGift;
      if (gift == null) return null;
      final tier = _tierShort(gift.subPlan);
      return tier == null ? '${gift.total}' : '${gift.total} · $tier';
    case 'sub_gift':
      return _tierShort(event.subGift?.subPlan);
    case 'bits_badge_tier':
      final tier = event.bitsBadgeTier?.tier;
      return tier == null ? null : _compactInt(tier);
    case 'charity_donation':
      return event.charityDonation?.amount?.formatted;
    default:
      return null;
  }
}

/// Accent + icon seed for a [noticeType] (`shared_chat_*` normalized).
({ChatNoticeColorSeed color, ChatNoticeIconSeed icon}) chatNoticeChrome(
  String noticeType,
) {
  final type = _normalizeNoticeType(noticeType);
  return switch (type) {
    'sub' ||
    'resub' ||
    'sub_gift' ||
    'community_sub_gift' ||
    'gift_paid_upgrade' ||
    'prime_paid_upgrade' ||
    'pay_it_forward' =>
      (
        color: ChatNoticeColorSeed.sub,
        icon: ChatNoticeIconSeed.star,
      ),
    'watch_streak' => (
        color: ChatNoticeColorSeed.streak,
        icon: ChatNoticeIconSeed.flame,
      ),
    'raid' || 'unraid' => (
        color: ChatNoticeColorSeed.raid,
        icon: ChatNoticeIconSeed.people,
      ),
    'announcement' => (
        color: ChatNoticeColorSeed.announce,
        icon: ChatNoticeIconSeed.megaphone,
      ),
    'bits_badge_tier' => (
        color: ChatNoticeColorSeed.bits,
        icon: ChatNoticeIconSeed.diamond,
      ),
    'charity_donation' => (
        color: ChatNoticeColorSeed.charity,
        icon: ChatNoticeIconSeed.heart,
      ),
    'modiversary' => (
        color: ChatNoticeColorSeed.mod,
        icon: ChatNoticeIconSeed.shield,
      ),
    _ => (
        color: ChatNoticeColorSeed.generic,
        icon: ChatNoticeIconSeed.info,
      ),
  };
}

enum ChatNoticeColorSeed {
  sub,
  streak,
  raid,
  announce,
  bits,
  charity,
  mod,
  generic,
}

enum ChatNoticeIconSeed {
  star,
  flame,
  people,
  megaphone,
  diamond,
  heart,
  shield,
  info,
}
