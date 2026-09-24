import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_combined_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/pinned_chat_banner.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart';
import 'support/fake_youtube_services.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(height: 600.0, child: child)),
);

DateTime at(int second) => DateTime.utc(2026, 9, 24, 12, 0, 0, second);

YouTubeChatMessage ytMessage(String id, String text, DateTime when) =>
    YouTubeChatMessage(
      id: id,
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.textMessage,
        publishedAt: when,
        authorChannelId: 'chan-$id',
        displayMessage: text,
        textMessageDetails: YouTubeTextMessageDetails(messageText: text),
      ),
      authorDetails: YouTubeChatAuthorDetails(
        channelId: 'chan-$id',
        displayName: 'Yt$id',
      ),
    );

KickChatMessage kickMessage(String id, String text, DateTime when) =>
    KickChatMessage(
      id: id,
      content: text,
      createdAt: when,
      sender: KickChatSender(id: 7, username: 'Kick$id', slug: 'kick$id'),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore twitch;
  late YouTubeChatStore youTube;
  late KickChatStore kick;
  late CombinedChatStore combined;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('combined_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);

    twitch = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      isProResolver: () => true,
      eventSubFactory:
          (
            _,
            __,
            ___,
            ____,
            _____,
            ______,
            _______,
            ________,
            _________,
            __________,
          ) => FakeTwitchEventSubService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
    );
    youTube = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      liveResolver: FakeYouTubeLiveResolver(),
      isProResolver: () => true,
    );
    kick = KickChatStore(
      channelService: FakeKickChannelService(),
      isProResolver: () => true,
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
    );

    /// Sources come straight from observables - no sign-in flows, no
    /// selectChannel (no Hive writes inside the fake-async zone).
    youTube.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/UCownchannel000000000000'),
      isOwn: true,
      title: 'My Channel',
    );
    kick.ownChannelSlug = 'kicker';

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
    await kick.dispose();
    await youTube.dispose();
    await twitch.dispose();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('rows from every source render in time order with icons', (
    tester,
  ) async {
    kick.messages.addAll([
      kickMessage('k1', 'kick first', at(1)),
      kickMessage('k2', 'kick third', at(3)),
    ]);
    youTube.messages.add(ytMessage('y1', 'youtube second', at(2)));

    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pump();

    double top(String text) => tester.getTopLeft(find.textContaining(text)).dy;
    expect(top('kick first'), lessThan(top('youtube second')));
    expect(top('youtube second'), lessThan(top('kick third')));
    expect(find.byKey(const Key('combined-row-icon-Kick')), findsNWidgets(2));
    expect(find.byKey(const Key('combined-row-icon-YouTube')), findsOneWidget);
  });

  testWidgets('a switched-off source drops out of the timeline', (
    tester,
  ) async {
    kick.messages.add(kickMessage('k1', 'kick line', at(1)));
    youTube.messages.add(ytMessage('y1', 'youtube line', at(2)));
    combined.disabledPlatforms.add(ChatType.Kick);

    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pump();

    expect(find.textContaining('youtube line'), findsOneWidget);
    expect(find.textContaining('kick line'), findsNothing);
  });

  testWidgets('no sources: explains there is nothing to combine', (
    tester,
  ) async {
    youTube.ownChannel = null;
    kick.ownChannelSlug = null;

    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pump();

    expect(find.text('No chats to combine yet.'), findsOneWidget);
  });

  testWidgets('a full merged buffer keeps following new rows', (tester) async {
    for (var i = 0; i < 500; i++) {
      kick.messages.add(kickMessage('h$i', 'x', at(1)));
    }
    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, closeTo(position.maxScrollExtent, 1.0));

    /// The merged view is capped at 500: each arrival pushes one row out.
    final long = List.filled(40, 'long words here').join(' ');
    for (var i = 0; i < 3; i++) {
      youTube.messages.add(ytMessage('n$i', 'NEW$i $long', at(10 + i)));
      await tester.pumpAndSettle();
    }

    expect(combined.timeline.length, 500);
    expect(position.pixels, closeTo(position.maxScrollExtent, 1.0));
  });

  testWidgets('each source pin stacks and tucks on its own', (tester) async {
    kick.messages.add(kickMessage('k1', 'kick line', at(1)));
    kick.pinnedMessage = kickMessage('p1', 'kick pin text', at(1));
    await tester.pumpWidget(
      wrap(
        const CombinedPinStack(
          pins: [
            CombinedPin(
              platform: ChatType.Twitch,
              messageId: 't',
              senderName: 'Streamer',
              text: 'twitch pin text',
            ),
            CombinedPin(
              platform: ChatType.Kick,
              messageId: 'k',
              senderName: 'Kicker',
              text: 'kick pin text',
            ),
          ],
          child: SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PinnedChatBanner), findsNWidgets(2));

    /// The banner cross-fades a collapsed + an expanded copy of the text.
    expect(
      tester.getTopLeft(find.textContaining('twitch pin text').first).dy,
      lessThan(
        tester.getTopLeft(find.textContaining('kick pin text').first).dy,
      ),
    );

    /// Tuck the Twitch pin: its banner goes, the Kick banner stays open.
    /// Two ✕ glyphs; the upper one belongs to the Twitch banner.
    final closes = find.byIcon(CupertinoIcons.xmark);
    expect(closes, findsNWidgets(2));
    final twitchClose =
        tester.getCenter(closes.at(0)).dy < tester.getCenter(closes.at(1)).dy
        ? closes.at(0)
        : closes.at(1);
    await tester.tap(twitchClose);
    await tester.pumpAndSettle();

    expect(find.textContaining('twitch pin text'), findsNothing);
    expect(find.textContaining('kick pin text'), findsWidgets);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

    /// The tucked Twitch pin shows the platform icon instead of a pin.
    expect(find.byIcon(ChatType.Twitch.icon), findsWidgets);
  });

  test('combinedVisibleItems applies the shared mute filter', () {
    final items = [
      CombinedItem(
        platform: ChatType.Kick,
        payload: kickMessage('k1', 'hello there', at(1)),
        at: at(1),
        key: 'kick:k1',
      ),
      CombinedItem(
        platform: ChatType.YouTube,
        payload: ytMessage('y1', 'spoiler inside', at(2)),
        at: at(2),
        key: 'youtube:y1',
      ),
    ];
    final visible = combinedVisibleItems(
      items,
      filters: const ChatFilterSettings(
        muteWords: ['spoiler'],
        muteReplace: false,
        highlightUsers: {},
        ignoredUsers: {},
      ),
      twitchNoticeVisible: (_) => true,
      kickNoticeVisible: (_) => true,
    );

    expect(visible.map((i) => i.key), ['kick:k1']);
  });
}
