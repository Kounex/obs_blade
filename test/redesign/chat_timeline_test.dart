import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/redesign/chat/chat_access.dart';
import 'package:obs_blade/redesign/chat/chat_timeline.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';

const _message = ChatMessageEvent(
  broadcasterUserId: 'owner',
  chatterUserId: 'viewer',
  chatterUserLogin: 'viewer',
  chatterUserName: 'Viewer',
  messageId: 'rich',
  message: ChatMessageText(
    text: 'Kappa',
    fragments: [
      ChatMessageFragment(
        type: 'emote',
        text: 'Kappa',
        emote: ChatFragmentEmote(id: '25'),
      ),
    ],
  ),
  badges: [ChatMessageBadge(setId: 'moderator', id: '1', info: '')],
);

void main() {
  late _Twitch twitch;
  late YouTubeChatStore youtube;
  ChatTimeline project({
    ChatGate gate = ChatGate.open,
    ChatType platform = ChatType.Twitch,
  }) => projectChatTimeline(
    access: ChatAccess(
      platform: platform,
      engine: ChatEngine.native,
      gate: gate,
      channelId: 'owner',
    ),
    twitch: twitch,
    youtube: youtube,
  );
  setUp(() {
    twitch = _Twitch();
    youtube = YouTubeChatStore();
  });

  test(
    'Twitch payload identity, emotes and badges reach the renderer intact',
    () {
      twitch.messages.add(_message);
      final timeline = project();
      final entry = timeline.entries.single as TwitchMessageEntry;
      expect(identical(entry.message, _message), true);
      expect(entry.message.message.fragments.single.emote?.id, '25');
      expect(entry.message.badges.single.setId, 'moderator');
      expect(() => timeline.entries.clear(), throwsUnsupportedError);
    },
  );

  test('notices remain in store arrival order with full metadata', () {
    const clear = ChatSystemNotice(
      afterSeq: 0,
      kind: ChatSystemNoticeKind.chatCleared,
    );
    const notice = ChatNotificationNotice(
      afterSeq: 0,
      event: ChatNotificationEvent(
        broadcasterUserId: 'owner',
        chatterUserId: 'viewer',
        chatterUserLogin: 'viewer',
        chatterUserName: 'Viewer',
        messageId: 'notice',
        systemMessage: 'Viewer raided with 12 viewers',
        noticeType: 'raid',
        raid: ChatNotificationRaid(viewerCount: 12),
      ),
    );
    twitch.systemNotices.add(clear);
    twitch.chatNotifications.add(notice);
    final entries = project().entries;
    expect(entries.map((entry) => entry.runtimeType), [
      ChatSystemEntry,
      TwitchNoticeEntry,
    ]);
    expect(identical((entries.last as TwitchNoticeEntry).notice, notice), true);
  });

  test('deletion rebuilds a content-visible row with its actor', () {
    twitch.messages.add(_message);
    final deletedStates = <bool>[];
    final stop = autorun((_) {
      deletedStates.add(
        (project().entries.single as TwitchMessageEntry).deleted,
      );
    });
    twitch.applyMessageDelete(
      const ChatMessageDeleteEvent(
        messageId: 'rich',
        targetUserId: 'viewer',
        userName: 'Mod',
      ),
    );
    final entry = project().entries.single as TwitchMessageEntry;
    expect(deletedStates, [false, true]);
    expect(entry.message.message.text, 'Kappa');
    expect(entry.deletedBy, 'Mod');
    expect(entry.tombstone, isNotNull);
    stop();
  });

  test('gate removes native content without erasing store history', () {
    twitch.messages.add(_message);
    expect(project(gate: ChatGate.pro).entries, isEmpty);
    expect(project(gate: ChatGate.embedded).entries, isEmpty);
    expect(twitch.messages.single, _message);
  });

  test('old conversation is hidden during the channel buffer swap', () {
    twitch.messages.add(_message);
    twitch.switching = true;
    expect(project().entries, isEmpty);
    twitch.switching = false;
    expect(project().entries, hasLength(1));
  });

  test('YouTube retains paid-message details and tombstone state', () {
    final message = YouTubeChatMessage(
      id: 'paid',
      isTombstoned: true,
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.superChat,
        publishedAt: DateTime.utc(2026),
        superChatDetails: const YouTubeSuperChatDetails(
          currency: 'EUR',
          amountDisplayString: '€5.00',
        ),
      ),
    );
    youtube.messages.add(message);
    final entry =
        project(platform: ChatType.YouTube).entries.single
            as YouTubeMessageEntry;
    expect(identical(entry.message, message), true);
    expect(entry.message.isTombstoned, true);
    expect(entry.message.snippet.superChatDetails?.currency, 'EUR');
  });
}

class _Twitch extends TwitchChatStore {
  bool switching = false;
  @override
  bool get isSwitchingChannel => switching;
}
