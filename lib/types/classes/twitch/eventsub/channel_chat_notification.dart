import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';

part 'channel_chat_notification.freezed.dart';
part 'channel_chat_notification.g.dart';

/// `channel.chat.notification` — subs, gifts, raids, watch streaks, etc.
/// UI uses [systemMessage] + [noticeType] for copy/icon/accent; typed
/// blocks beyond [watchStreak] are left unmodeled (Twitch already
/// formats [systemMessage]).
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
    String? color,
    @Default(<ChatMessageBadge>[]) List<ChatMessageBadge> badges,
    /// Optional message the chatter attached (often empty — the typed
    /// chat line may arrive separately as `channel.chat.message`).
    ChatMessageText? message,
    ChatNotificationWatchStreak? watchStreak,
  }) = _ChatNotificationEvent;

  factory ChatNotificationEvent.fromJson(Map<String, Object?> json) =>
      _$ChatNotificationEventFromJson(json);
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

/// Timeline wrapper — arrival seq for merge with messages / /clear banners.
class ChatNotificationNotice {
  final int afterSeq;
  final ChatNotificationEvent event;

  const ChatNotificationNotice({
    required this.afterSeq,
    required this.event,
  });
}

/// Accent + icon seed for a [noticeType] (`shared_chat_*` normalized).
({ChatNoticeColorSeed color, ChatNoticeIconSeed icon}) chatNoticeChrome(
  String noticeType,
) {
  final type = noticeType.startsWith('shared_chat_')
      ? noticeType.substring('shared_chat_'.length)
      : noticeType;
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
