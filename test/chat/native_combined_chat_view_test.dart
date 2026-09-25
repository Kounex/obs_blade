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
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/combined_chat_input.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
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

    /// Write-scoped tokens on Kick + YouTube: a test opts into writing by
    /// flipping the store's `authState` to signed in.
    await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
      KickAuth.kBoxKey,
      KickAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
        scopes: kKickChatScopes,
        userId: 9001,
        username: 'kicker',
        channelSlug: 'kicker',
      ),
    );
    await Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
      YouTubeAuth.kBoxKey,
      YouTubeAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
        scopes: kYouTubeChatScopes,
        channelTitle: 'My Channel',
        channelId: 'UCownchannel000000000000',
      ),
    );

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

    /// Each row carries its platform's tint + rail.
    final rows = tester.widgetList<CombinedSourceRow>(
      find.byType(CombinedSourceRow),
    );
    expect(rows.map((r) => r.platform).toList(), [
      ChatType.Kick,
      ChatType.YouTube,
      ChatType.Kick,
    ]);
  });

  testWidgets('the platform wash spans the full width; the badge sits on '
      'the name line at badge size', (tester) async {
    kick.messages.add(kickMessage('k1', 'kick line', at(1)));

    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pump();

    final view = tester.getRect(find.byType(NativeCombinedChatView));
    final wash = tester.getRect(find.byType(CombinedSourceRow));
    expect(wash.left, view.left, reason: 'stripe on the left edge');
    expect(wash.right, view.right, reason: 'tint across the full width');

    final badge = tester.getRect(
      find.byKey(const Key('combined-row-icon-Kick')),
    );
    expect(badge.height, 16.0, reason: 'same height as platform badges');
    final name = tester.getRect(find.textContaining('Kickk1').first);

    /// Inline in the first line: vertically centered on the name.
    expect((badge.center.dy - name.center.dy).abs(), lessThan(3.0));
  });

  testWidgets('the source strip shows one chip per source', (tester) async {
    kick.messages.add(kickMessage('k1', 'kick line', at(1)));

    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pump();

    expect(find.byKey(const Key('combined-focus-YouTube')), findsOneWidget);
    expect(find.byKey(const Key('combined-focus-Kick')), findsOneWidget);
    expect(find.byKey(const Key('combined-focus-Twitch')), findsNothing);
  });

  testWidgets('live sources carry a LIVE tag, others "Offline"; the strip '
      'stays up on an empty chat', (tester) async {
    kick.channelInfo = const KickChannelInfo(
      id: 1,
      slug: 'kicker',
      chatroom: KickChatroom(id: 2),
      livestream: KickLivestreamInfo(isLive: true, viewerCount: 1234),
    );

    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pump();

    /// No messages yet: placeholder AND the strip.
    expect(find.textContaining('Waiting for messages'), findsOneWidget);
    expect(find.byKey(const Key('combined-focus-Kick')), findsOneWidget);

    expect(find.byKey(const Key('combined-live-Kick')), findsOneWidget);
    expect(find.byKey(const Key('combined-live-YouTube')), findsNothing);
    expect(combined.liveSources, {ChatType.Kick: 1234});

    /// Stream ends: LIVE turns into "Offline" (the chat connection is a
    /// separate, quiet fact).
    kick.channelInfo = const KickChannelInfo(
      id: 1,
      slug: 'kicker',
      chatroom: KickChatroom(id: 2),
    );
    await tester.pump();
    expect(find.byKey(const Key('combined-live-Kick')), findsNothing);
    expect(find.byKey(const Key('combined-offline-Kick')), findsOneWidget);
  });

  testWidgets('a connection problem shows a marker + label instead of '
      '"Offline"', (tester) async {
    kick.chatConnection = KickChatConnectionState.error;
    await tester.pumpWidget(wrap(const NativeCombinedChatView()));
    await tester.pump();

    expect(find.byKey(const Key('combined-issue-Kick')), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.byKey(const Key('combined-offline-Kick')), findsNothing);
  });

  testWidgets('a focused platform window shows "↩ Combined"', (tester) async {
    combined.focusedPlatform = ChatType.Kick;

    Widget window(ChatType type) => wrap(
      NativeChatWindow(
        chatType: type,
        status: NativeChatConnectionStatus.live,
        child: const SizedBox.expand(),
      ),
    );

    await tester.pumpWidget(window(ChatType.Kick));
    expect(find.byKey(const Key('combined-focus-back')), findsOneWidget);
    expect(find.text('My chats'), findsOneWidget);

    /// Other platforms' windows stay plain.
    await tester.pumpWidget(window(ChatType.YouTube));
    expect(find.byKey(const Key('combined-focus-back')), findsNothing);

    combined.focusedPlatform = null;
    await tester.pumpWidget(window(ChatType.Kick));
    await tester.pump();
    expect(find.byKey(const Key('combined-focus-back')), findsNothing);
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

  group('writing', () {
    Widget view() => wrap(
      Column(
        children: [
          const Expanded(child: NativeCombinedChatView()),
          CombinedChatInput(
            controller: TextEditingController(),
            focusNode: FocusNode(),
          ),
        ],
      ),
    );

    testWidgets('signed out everywhere: the dock is read-only', (tester) async {
      await tester.pumpWidget(view());
      await tester.pump();

      expect(find.text('Chat is read-only'), findsOneWidget);
      expect(find.byKey(const Key('combined-send-target')), findsNothing);
    });

    testWidgets('the target chip picks between writable sources', (
      tester,
    ) async {
      kick.authState = KickAuthState.signedIn;
      youTube.authState = YouTubeAuthState.signedIn;
      await tester.pumpWidget(view());
      await tester.pump();

      /// Source order: YouTube before Kick in "My chats".
      expect(find.text('Send to YouTube…'), findsOneWidget);

      await tester.tap(find.byKey(const Key('combined-send-target')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('combined-send-target-YouTube')), findsOne);

      /// The pick persists to Hive — real I/O that never completes inside
      /// testWidgets' fake-async zone; runAsync escapes it.
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('combined-send-target-Kick')));
        await Hive.box(HiveKeys.Settings.name).flush();
      });
      await tester.pumpAndSettle();

      expect(combined.sendTarget, ChatType.Kick);
      expect(find.text('Send to Kick…'), findsOneWidget);
    });

    testWidgets('long-press a Kick row → Reply locks the target to Kick', (
      tester,
    ) async {
      kick.authState = KickAuthState.signedIn;
      youTube.authState = YouTubeAuthState.signedIn;
      kick.messages.add(kickMessage('k1', 'kick line', at(1)));
      await tester.pumpWidget(view());
      await tester.pump();
      expect(combined.sendTarget, ChatType.YouTube);

      await tester.longPress(find.textContaining('kick line'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reply'));
      await tester.pumpAndSettle();

      expect(kick.replyTarget?.id, 'k1');
      expect(combined.sendTarget, ChatType.Kick);
      expect(find.textContaining('Replying to'), findsOneWidget);

      /// Locked: the chip doesn't open the picker while replying.
      await tester.tap(find.byKey(const Key('combined-send-target')));
      await tester.pumpAndSettle();
      expect(find.text('Send to'), findsNothing);

      /// ✕ on the strip drops the reply; the pick applies again.
      await tester.tap(find.byIcon(CupertinoIcons.xmark).last);
      await tester.pump();
      expect(kick.replyTarget, isNull);
      expect(combined.sendTarget, ChatType.YouTube);
    });

    testWidgets('signed out on Kick: long-press offers Copy, no Reply', (
      tester,
    ) async {
      await tester.runAsync(
        () => Hive.box<KickAuth>(HiveKeys.KickAuth.name).clear(),
      );
      kick.messages.add(kickMessage('k1', 'kick line', at(1)));
      await tester.pumpWidget(view());
      await tester.pump();

      await tester.longPress(find.textContaining('kick line'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Copy'), findsWidgets);
      expect(find.text('Reply'), findsNothing);
    });
  });
}
