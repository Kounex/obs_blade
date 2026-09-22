import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

/// Toggle groups for the synthetic `system`-type notices the Kick chat
/// store appends (`_appendNotice` in `kick_chat.dart`). `/clear` is not
/// listed — it is not user-toggleable, matching the Twitch engine's
/// unconditional clear banner.
enum KickChatNoticeCategory { subsAndGifts, hosts }

/// Classifies a synthetic system message by its id prefix (the same
/// prefix the row widget reads to pick an icon) — `null` for `/clear`
/// or any unrecognized prefix, which are always shown.
KickChatNoticeCategory? kickChatNoticeCategory(String messageId) {
  if (messageId.startsWith('system-sub-') ||
      messageId.startsWith('system-gift-')) {
    return KickChatNoticeCategory.subsAndGifts;
  }
  if (messageId.startsWith('system-host-')) {
    return KickChatNoticeCategory.hosts;
  }
  return null;
}

SettingsKeys settingsKeyForKickChatNoticeCategory(
  KickChatNoticeCategory category,
) => switch (category) {
  KickChatNoticeCategory.subsAndGifts => SettingsKeys.KickChatNoticeSubs,
  KickChatNoticeCategory.hosts => SettingsKeys.KickChatNoticeHosts,
};

bool isKickChatNoticeVisible(Box settingsBox, String messageId) {
  final category = kickChatNoticeCategory(messageId);
  if (category == null) return true;
  final key = settingsKeyForKickChatNoticeCategory(category);
  return settingsBox.get(key.name, defaultValue: true) as bool;
}
