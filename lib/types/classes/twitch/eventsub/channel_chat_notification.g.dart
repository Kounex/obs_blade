// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_chat_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatNotificationEvent _$ChatNotificationEventFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationEvent(
  broadcasterUserId: json['broadcaster_user_id'] as String,
  chatterUserId: json['chatter_user_id'] as String,
  chatterUserLogin: json['chatter_user_login'] as String,
  chatterUserName: json['chatter_user_name'] as String,
  messageId: json['message_id'] as String,
  systemMessage: json['system_message'] as String,
  noticeType: json['notice_type'] as String,
  color: json['color'] as String?,
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => ChatMessageBadge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatMessageBadge>[],
  message: json['message'] == null
      ? null
      : ChatMessageText.fromJson(json['message'] as Map<String, dynamic>),
  announcement: json['announcement'] == null
      ? null
      : ChatNotificationAnnouncement.fromJson(
          json['announcement'] as Map<String, dynamic>,
        ),
  watchStreak: json['watch_streak'] == null
      ? null
      : ChatNotificationWatchStreak.fromJson(
          json['watch_streak'] as Map<String, dynamic>,
        ),
  raid: json['raid'] == null
      ? null
      : ChatNotificationRaid.fromJson(json['raid'] as Map<String, dynamic>),
  subGift: json['sub_gift'] == null
      ? null
      : ChatNotificationSubGift.fromJson(
          json['sub_gift'] as Map<String, dynamic>,
        ),
  communitySubGift: json['community_sub_gift'] == null
      ? null
      : ChatNotificationCommunitySubGift.fromJson(
          json['community_sub_gift'] as Map<String, dynamic>,
        ),
  bitsBadgeTier: json['bits_badge_tier'] == null
      ? null
      : ChatNotificationBitsBadgeTier.fromJson(
          json['bits_badge_tier'] as Map<String, dynamic>,
        ),
  charityDonation: json['charity_donation'] == null
      ? null
      : ChatNotificationCharityDonation.fromJson(
          json['charity_donation'] as Map<String, dynamic>,
        ),
);

_ChatNotificationAnnouncement _$ChatNotificationAnnouncementFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationAnnouncement(color: json['color'] as String);

_ChatNotificationWatchStreak _$ChatNotificationWatchStreakFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationWatchStreak(
  streakCount: (json['streak_count'] as num).toInt(),
  channelPointsAwarded: (json['channel_points_awarded'] as num?)?.toInt() ?? 0,
);

_ChatNotificationRaid _$ChatNotificationRaidFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationRaid(
  viewerCount: (json['viewer_count'] as num).toInt(),
  userName: json['user_name'] as String?,
  userLogin: json['user_login'] as String?,
);

_ChatNotificationSubGift _$ChatNotificationSubGiftFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationSubGift(
  subPlan: json['sub_plan'] as String?,
  cumulativeTotal: (json['cumulative_total'] as num?)?.toInt(),
  recipientUserName: json['recipient_user_name'] as String?,
);

_ChatNotificationCommunitySubGift _$ChatNotificationCommunitySubGiftFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationCommunitySubGift(
  total: (json['total'] as num).toInt(),
  subPlan: json['sub_plan'] as String?,
  cumulativeTotal: (json['cumulative_total'] as num?)?.toInt(),
);

_ChatNotificationBitsBadgeTier _$ChatNotificationBitsBadgeTierFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationBitsBadgeTier(tier: (json['tier'] as num).toInt());

_ChatNotificationCharityDonation _$ChatNotificationCharityDonationFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationCharityDonation(
  charityName: json['charity_name'] as String?,
  amount: json['amount'] == null
      ? null
      : ChatNotificationCharityAmount.fromJson(
          json['amount'] as Map<String, dynamic>,
        ),
);

_ChatNotificationCharityAmount _$ChatNotificationCharityAmountFromJson(
  Map<String, dynamic> json,
) => _ChatNotificationCharityAmount(
  value: (json['value'] as num).toInt(),
  decimalPlaces: (json['decimal_places'] as num?)?.toInt(),
  decimalPlace: (json['decimal_place'] as num?)?.toInt(),
  currency: json['currency'] as String?,
);
