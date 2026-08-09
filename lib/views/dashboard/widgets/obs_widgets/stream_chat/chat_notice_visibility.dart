import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

/// Toggle groups for `channel.chat.notification` (and first-message chrome).
enum ChatNoticeCategory {
  subs,
  streaks,
  raids,
  announcements,
  bitsBadge,
  charity,
  modiversary,
  other,
}

/// Maps a Twitch [noticeType] onto a [ChatNoticeCategory] toggle.
ChatNoticeCategory chatNoticeCategory(String noticeType) =>
    switch (chatNoticeChrome(noticeType).color) {
      ChatNoticeColorSeed.sub => ChatNoticeCategory.subs,
      ChatNoticeColorSeed.streak => ChatNoticeCategory.streaks,
      ChatNoticeColorSeed.raid => ChatNoticeCategory.raids,
      ChatNoticeColorSeed.announce => ChatNoticeCategory.announcements,
      ChatNoticeColorSeed.bits => ChatNoticeCategory.bitsBadge,
      ChatNoticeColorSeed.charity => ChatNoticeCategory.charity,
      ChatNoticeColorSeed.mod => ChatNoticeCategory.modiversary,
      ChatNoticeColorSeed.generic => ChatNoticeCategory.other,
    };

SettingsKeys settingsKeyForChatNoticeCategory(ChatNoticeCategory category) =>
    switch (category) {
      ChatNoticeCategory.subs => SettingsKeys.TwitchChatNoticeSubs,
      ChatNoticeCategory.streaks => SettingsKeys.TwitchChatNoticeStreaks,
      ChatNoticeCategory.raids => SettingsKeys.TwitchChatNoticeRaids,
      ChatNoticeCategory.announcements =>
        SettingsKeys.TwitchChatNoticeAnnouncements,
      ChatNoticeCategory.bitsBadge => SettingsKeys.TwitchChatNoticeBitsBadge,
      ChatNoticeCategory.charity => SettingsKeys.TwitchChatNoticeCharity,
      ChatNoticeCategory.modiversary =>
        SettingsKeys.TwitchChatNoticeModiversary,
      ChatNoticeCategory.other => SettingsKeys.TwitchChatNoticeOther,
    };

bool isChatNoticeTypeVisible(Box settingsBox, String noticeType) {
  final key = settingsKeyForChatNoticeCategory(chatNoticeCategory(noticeType));
  return settingsBox.get(key.name, defaultValue: true) as bool;
}

bool isChatFirstMessageVisible(Box settingsBox) =>
    settingsBox.get(
      SettingsKeys.TwitchChatNoticeFirstMessage.name,
      defaultValue: true,
    ) as bool;
