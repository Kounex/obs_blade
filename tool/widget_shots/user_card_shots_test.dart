import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/stores/views/chat_history.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/chat_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart'
    show NativeChatConnectionStatus;
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_user_card_sheet.dart';

import '../../test/chat/support/fake_kick_services.dart';
import '../../test/chat/support/fake_twitch_services.dart';
import '../../test/chat/support/fake_youtube_services.dart';
import '../../test/chat/youtube_chat_message_row_test.dart' show ytMessage;
import 'support/shots_harness.dart';

/// YouTube and Kick user cards with the highlight / ignore rows (same as
/// Twitch's card).
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    GetIt.instance
      ..registerSingleton<ChatHistoryStore>(ChatHistoryStore())
      ..registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
      )
      ..registerSingleton<TwitchChatStore>(
        TwitchChatStore(
          authService: FakeTwitchAuthService(),
          isProResolver: () => true,
          eventSubFactory: (_, _, _, _, _, _, _, _, _, _) =>
              FakeTwitchEventSubService(),
          ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
        ),
      )
      ..registerSingleton<YouTubeChatStore>(
        YouTubeChatStore(
          authService: FakeYouTubeAuthService(),
          chatService: FakeYouTubeLiveChatService(),
          isProResolver: () => true,
        ),
      )
      ..registerSingleton<KickChatStore>(
        KickChatStore(
          channelService: FakeKickChannelService(),
          authService: FakeKickAuthService(),
          apiService: FakeKickApiService(),
          pusherFactory: ({required onEvent, required onStateChanged}) =>
              FakeKickPusherService(
                onEvent: onEvent,
                onStateChanged: onStateChanged,
              ),
          isProResolver: () => true,
          emoteStoreResolver: () =>
              ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
          kickEmoteStoreResolver: () =>
              KickEmoteStore(service: FakeKickEmoteService()),
        ),
      );
  });
  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  testWidgets('youtube card', (tester) async {
    await harness.shot(
      tester,
      'user_card_youtube',
      Builder(
        builder: (context) => YouTubeUserCardSheet(
          channelId: 'UCremy',
          fallbackName: 'Remy',
          hostContext: context,
        ),
      ),
    );
  });

  testWidgets('kick card', (tester) async {
    await harness.shot(
      tester,
      'user_card_kick',
      Builder(
        builder: (context) => KickUserCardSheet(
          userId: 42,
          fallbackName: 'kickfan',
          hostContext: context,
        ),
      ),
    );
  });

  testWidgets('chatty viewer, opened as a sheet', (tester) async {
    final store = GetIt.instance<YouTubeChatStore>();
    runInAction(() {
      for (var i = 0; i < 20; i++) {
        store.messages.add(
          ytMessage(
            'm$i',
            author: 'UCremy',
            authorName: 'Remy',
            text: 'message number $i with a few more words so it wraps',
          ),
        );
      }
    });
    await harness.shot(
      tester,
      'user_card_youtube_chatty_base',
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () =>
                showYouTubeUserCardSheet(context, channelId: 'UCremy'),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../build/widget_shots/user_card_youtube_chatty.png',
      ),
    );
  });

  /// Opens the card the way the chat does, lets it settle, optionally
  /// scrolls the history by [scroll], then shoots
  Future<void> openAndShoot(
    WidgetTester tester,
    String name,
    void Function(BuildContext context) open, {
    Size size = kShotPhone,
    String? scrollFrom,
    double scroll = 0.0,
  }) async {
    await harness.shot(
      tester,
      '${name}_base',
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
      size: size,
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (scrollFrom != null) {
      await tester.drag(
        find.textContaining(scrollFrom, findRichText: true).first,
        Offset(0.0, -scroll),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../build/widget_shots/$name.png'),
    );
  }

  void addChattyRemy() {
    final store = GetIt.instance<YouTubeChatStore>();
    runInAction(() {
      for (var i = 0; i < 20; i++) {
        store.messages.add(
          ytMessage(
            'm$i',
            author: 'UCremy',
            authorName: 'Remy',
            text: 'message number $i with a few more words so it wraps',
          ),
        );
      }
    });
  }

  /// Only the history under LIVE scrolls (name, facts, lists, LIVE stay)
  for (final (suffix, size) in [
    ('scrolled', kShotPhone),
    ('narrow', const Size(320, 640)),
    ('tablet', kShotTablet),

    /// Too short to pin: all of it scrolls together
    ('landscape', const Size(844, 390)),
  ]) {
    testWidgets('chatty viewer, history scrolled, $suffix', (tester) async {
      addChattyRemy();
      await openAndShoot(
        tester,
        'user_card_youtube_chatty_$suffix',
        (context) => showYouTubeUserCardSheet(context, channelId: 'UCremy'),
        size: size,
        scrollFrom: 'message number 19 ',
        scroll: 160.0,
      );
    });
  }

  testWidgets('twitch self card: footer pinned under the history', (
    tester,
  ) async {
    final twitch = GetIt.instance<TwitchChatStore>();
    for (var i = 0; i < 25; i++) {
      twitch.appendChatMessageForTest(
        ChatMessageEvent(
          broadcasterUserId: 'b1',
          chatterUserId: 'self-1',
          chatterUserLogin: 'selflogin',
          chatterUserName: 'SelfUser',
          messageId: 'm$i',
          color: '#9146FF',
          message: ChatMessageText(
            text: 'message number $i from my own account',
            fragments: [
              ChatMessageFragment(
                type: 'text',
                text: 'message number $i from my own account',
              ),
            ],
          ),
        ),
      );
    }
    await openAndShoot(
      tester,
      'user_card_twitch_self_chatty',
      (context) => showChatUserCardSheet(
        context,
        userId: 'self-1',
        userService: FakeTwitchUserService(),
        connection: ChatUserCardConnection(
          chatType: ChatType.Twitch,
          status: NativeChatConnectionStatus.live,
          statusLabel: '',
          statusColor: Colors.grey,
          accountLabel: 'SelfUser',
          onLogout: () {},
        ),
      ),
      scrollFrom: 'message number 24 ',
      scroll: 120.0,
    );
  });

  /// 60 retained rows: the card shows the first 50 and a "Show 10 older
  /// messages" button; tapping reveals the rest (lazily).
  testWidgets('chatty viewer, >50 retained: the expand button', (
    tester,
  ) async {
    final store = GetIt.instance<YouTubeChatStore>();
    runInAction(() {
      for (var i = 0; i < 60; i++) {
        store.messages.add(
          ytMessage(
            'm$i',
            author: 'UCremy',
            authorName: 'Remy',
            text: 'message number $i with a few more words so it wraps',
          ),
        );
      }
    });
    await harness.shot(
      tester,
      'user_card_youtube_history_button_base',
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () =>
                showYouTubeUserCardSheet(context, channelId: 'UCremy'),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    /// The button is past the fold - scroll the history to it
    await tester.scrollUntilVisible(
      find.text('Show 10 older messages'),
      300.0,
      scrollable: find.byType(Scrollable).last,
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../build/widget_shots/user_card_youtube_history_button.png',
      ),
    );

    await tester.tap(find.text('Show 10 older messages'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.scrollUntilVisible(
      find.textContaining('message number 0 ', findRichText: true),
      300.0,
      scrollable: find.byType(Scrollable).last,
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../build/widget_shots/user_card_youtube_history_expanded.png',
      ),
    );
  });

  /// A history row deleted before its eviction keeps the feed-time
  /// tombstone (greyed, marker, actor) on the card.
  testWidgets('twitch card: tombstoned history rows behind live ones', (
    tester,
  ) async {
    final twitch = GetIt.instance<TwitchChatStore>();
    final history = GetIt.instance<ChatHistoryStore>();
    ChatMessageEvent event(String id, String text) => ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: 'viewer-1',
      chatterUserLogin: 'viewerlogin',
      chatterUserName: 'ViewerOne',
      messageId: id,
      color: '#9146FF',
      message: ChatMessageText(
        text: text,
        fragments: [ChatMessageFragment(type: 'text', text: text)],
      ),
    );

    /// The store queries the history by its effective channel - no user,
    /// no selection in this harness: the empty key.
    history.record(
      platform: ChatHistoryPlatform.twitch,
      channelKey: '',
      authorKey: 'viewer-1',
      message: event('old-1', 'an evicted row, still readable'),
      tombstone: const ChatHistoryTombstone(isDeleted: false),
    );
    history.record(
      platform: ChatHistoryPlatform.twitch,
      channelKey: '',
      authorKey: 'viewer-1',
      message: event('old-2', 'deleted before it left the buffer'),
      tombstone: const ChatHistoryTombstone(
        isDeleted: true,
        marker: ' -Deleted',
        actor: 'ModPerson',
      ),
    );
    twitch.appendChatMessageForTest(event('live-1', 'still in the buffer'));

    await openAndShoot(
      tester,
      'user_card_twitch_history_tombstone',
      (context) => showChatUserCardSheet(
        context,
        userId: 'viewer-1',
        userService: FakeTwitchUserService(),
      ),
    );
  });
}
