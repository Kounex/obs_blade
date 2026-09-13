import '../../models/enums/chat_type.dart';
import '../../stores/views/twitch_chat.dart';
import '../../stores/views/youtube_chat.dart';
import '../../types/classes/twitch/chat_system_notice.dart';
import '../../types/classes/twitch/eventsub/channel_chat_message.dart';
import '../../types/classes/twitch/eventsub/channel_chat_notification.dart';
import '../../types/classes/twitch/twitch_pinned_message.dart';
import '../../types/classes/youtube/youtube_chat_message.dart';
import '../../views/dashboard/widgets/obs_widgets/stream_chat/chat_tombstone.dart';
import 'chat_access.dart';

/// A projection of the selected conversation, never a second history cache.
/// Raw platform payloads preserve specialized rendering and interaction data.
class ChatTimeline {
  const ChatTimeline({
    this.entries = const [],
    this.pin,
    this.lifecycleVersion = 0,
  });
  final List<ChatTimelineEntry> entries;
  final TwitchPinnedMessage? pin;
  final int lifecycleVersion;
}

sealed class ChatTimelineEntry {
  const ChatTimelineEntry();
}

class TwitchMessageEntry extends ChatTimelineEntry {
  const TwitchMessageEntry(
    this.message, {
    this.deleted = false,
    this.tombstone,
    this.deletedBy,
  });
  final ChatMessageEvent message;
  final bool deleted;
  final ChatTombstoneInfo? tombstone;
  final String? deletedBy;
}

class TwitchNoticeEntry extends ChatTimelineEntry {
  const TwitchNoticeEntry(this.notice);
  final ChatNotificationNotice notice;
}

class ChatSystemEntry extends ChatTimelineEntry {
  const ChatSystemEntry(this.notice);
  final ChatSystemNotice notice;
}

class YouTubeMessageEntry extends ChatTimelineEntry {
  const YouTubeMessageEntry(this.message);
  final YouTubeChatMessage message;
}

/// Observe with MobX. Notice and tombstone changes ride lifecycleVersion because
/// their store containers are intentionally non-observable. Appearance/category
/// filtering belongs to the renderer, so this seam never silently drops content.
ChatTimeline projectChatTimeline({
  required ChatAccess access,
  required TwitchChatStore twitch,
  required YouTubeChatStore youtube,
}) {
  if (!access.showsNativeConversation) return const ChatTimeline();
  if (access.platform == ChatType.YouTube) {
    return ChatTimeline(
      entries: List.unmodifiable([
        for (final message in youtube.messages) YouTubeMessageEntry(message),
      ]),
    );
  }
  if (access.platform != ChatType.Twitch) return const ChatTimeline();
  final lifecycleVersion = twitch.lifecycleVersion;
  if (twitch.isSwitchingChannel) {
    return ChatTimeline(lifecycleVersion: lifecycleVersion);
  }
  return ChatTimeline(
    lifecycleVersion: lifecycleVersion,
    pin: twitch.pinnedMessage,
    entries: List.unmodifiable([
      for (final item in twitch.messagesWithNotices())
        switch (item) {
          ChatMessageEvent() => TwitchMessageEntry(
            item,
            deleted: twitch.isMessageDeleted(item.messageId),
            tombstone: twitch.tombstoneInfo(item.messageId),
            deletedBy: twitch.deletedMessageActor(item.messageId),
          ),
          ChatNotificationNotice() => TwitchNoticeEntry(item),
          ChatSystemNotice() => ChatSystemEntry(item),
          _ => throw StateError(
            'Unmapped native chat entry: ${item.runtimeType}',
          ),
        },
    ]),
  );
}
