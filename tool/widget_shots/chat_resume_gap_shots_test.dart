import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_combined_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_kick_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';

import '../../test/chat/support/fake_kick_services.dart';
import '../../test/chat/support/fake_twitch_services.dart';
import '../../test/chat/support/fake_youtube_services.dart';
import 'support/shots_harness.dart';

/// The resume catch-up's gap divider ("Some messages while away are
/// missing") in a native Twitch timeline, a native Kick timeline and the
/// combined timeline.
void main() {
  final harness = ShotsHarness();
  late TwitchChatStore twitch;
  late YouTubeChatStore youTube;
  late KickChatStore kick;
  late CombinedChatStore combined;

  ChatMessageEvent twitchMessage(String id, String author, String text) =>
      ChatMessageEvent(
        broadcasterUserId: 'b1',
        chatterUserId: 'u-$id',
        chatterUserLogin: author.toLowerCase(),
        chatterUserName: author,
        messageId: id,
        color: '#9146FF',
        message: ChatMessageText(
          text: text,
          fragments: [ChatMessageFragment(type: 'text', text: text)],
        ),
      );

  KickChatMessage kickMessage(
    String id,
    String author,
    String text,
    DateTime at,
  ) => KickChatMessage(
    id: id,
    content: text,
    createdAt: at,
    sender: KickChatSender(
      id: 7,
      username: author,
      slug: author.toLowerCase(),
      identity: const KickChatIdentity(color: '#53FC18'),
    ),
  );

  YouTubeChatMessage ytMessage(String id, String text, DateTime at) =>
      YouTubeChatMessage(
        id: id,
        snippet: YouTubeChatMessageSnippet(
          type: YouTubeChatMessageType.textMessage,
          publishedAt: at,
          authorChannelId: 'chan-$id',
          displayMessage: text,
          textMessageDetails: YouTubeTextMessageDetails(messageText: text),
        ),
        authorDetails: YouTubeChatAuthorDetails(
          channelId: 'chan-$id',
          displayName: 'YtFan',
        ),
      );

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    twitch =
        TwitchChatStore(
            authService: FakeTwitchAuthService(),
            isProResolver: () => true,
            eventSubFactory:
                (
                  _,
                  _,
                  _,
                  _,
                  _,
                  _,
                  _,
                  _,
                  _,
                  _,
                ) => FakeTwitchEventSubService(),
            ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
          )
          ..authState = TwitchAuthState.loggedIn
          ..user = FakeTwitchAuthService.user
          ..chatConnection = TwitchChatConnectionState.live;
    youTube = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      isProResolver: () => true,
    );
    kick =
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
                throw StateError('no kick emotes in shots'),
          )
          ..ownChannelSlug = 'kicker'
          ..selectedChannelSlug = 'kicker'
          ..chatConnection = KickChatConnectionState.connected;
    combined = CombinedChatStore(
      twitchStore: () => twitch,
      youTubeStore: () => youTube,
      kickStore: () => kick,
    );
    GetIt.instance
      ..registerSingleton<TwitchChatStore>(twitch)
      ..registerSingleton<YouTubeChatStore>(youTube)
      ..registerSingleton<KickChatStore>(kick)
      ..registerSingleton<CombinedChatStore>(combined)
      ..registerSingleton<TwitchBadgeStore>(
        TwitchBadgeStore(service: FakeTwitchBadgeService()),
      )
      ..registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
      );
  });
  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  /// A pre-resume block, then the gap divider, then the catch-up block.
  void fillTwitch() {
    for (var i = 0; i < 6; i++) {
      twitch.appendChatMessageForTest(
        twitchMessage('pre-$i', 'Regular$i', 'chatting along before $i'),
      );
    }
    for (var i = 0; i < 4; i++) {
      twitch.appendChatMessageForTest(
        twitchMessage('cu-$i', 'NewFace$i', 'said while you were away $i'),
      );
    }
    runInAction(() => twitch.resumeGapBoundaries.add('cu-0'));
  }

  void fillKick() {
    final t0 = DateTime.utc(2026, 10, 5, 12);
    runInAction(() {
      for (var i = 0; i < 6; i++) {
        kick.messages.add(
          kickMessage(
            'pre-$i',
            'Regular$i',
            'kick chat before $i',
            t0.add(Duration(minutes: i)),
          ),
        );
      }
      for (var i = 0; i < 4; i++) {
        kick.messages.add(
          kickMessage(
            'cu-$i',
            'NewFace$i',
            'kick while away $i',
            t0.add(Duration(minutes: 30 + i)),
          ),
        );
      }
      kick.resumeGapBoundaries.add('cu-0');
    });
  }

  testWidgets('twitch timeline: the gap divider between pre-resume and '
      'catch-up rows', (tester) async {
    fillTwitch();
    await harness.shot(
      tester,
      'chat_resume_gap_twitch',
      const NativeTwitchChatView(),
    );
    await harness.shot(
      tester,
      'chat_resume_gap_twitch_narrow',
      const NativeTwitchChatView(),
      size: const Size(320, 640),
    );
  });

  testWidgets('kick timeline: the gap divider between pre-resume and '
      'catch-up rows', (tester) async {
    fillKick();
    await harness.shot(
      tester,
      'chat_resume_gap_kick',
      const NativeKickChatView(),
    );
    await harness.shot(
      tester,
      'chat_resume_gap_kick_narrow',
      const NativeKickChatView(),
      size: const Size(320, 640),
    );
  });

  testWidgets('combined timeline: the marker row sorts at the boundary', (
    tester,
  ) async {
    fillKick();
    final t0 = DateTime.utc(2026, 10, 5, 12);
    runInAction(() {
      youTube.messages.add(
        ytMessage(
          'y1',
          'youtube meanwhile',
          t0.add(const Duration(minutes: 20)),
        ),
      );
    });
    await harness.shot(
      tester,
      'chat_resume_gap_combined',
      const NativeCombinedChatView(),
    );
    await harness.shot(
      tester,
      'chat_resume_gap_combined_tablet',
      const NativeCombinedChatView(),
      size: kShotTablet,
    );
  });
}
