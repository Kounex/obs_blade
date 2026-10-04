import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
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
}
