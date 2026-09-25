import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/combined/combined_combo.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/combined_chat_picker.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart';
import 'support/fake_youtube_services.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    extensions: const [AppStatusColors.standard, AppTextColors.standard],
  ),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16.0), child: child),
  ),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore twitch;
  late YouTubeChatStore youTube;
  late KickChatStore kick;
  late CombinedChatStore combined;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('combined_picker_test');
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
      isProResolver: () => false,
    );
    youTube.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/UCownchannel000000000000'),
      isOwn: true,
      title: 'My Channel',
    );
    kick.ownChannelSlug = 'kicker';
    kick.chatConnection = KickChatConnectionState.connected;
    combined = CombinedChatStore(
      twitchStore: () => twitch,
      youTubeStore: () => youTube,
      kickStore: () => kick,
    );
    GetIt.instance
      ..registerSingleton<TwitchChatStore>(twitch)
      ..registerSingleton<YouTubeChatStore>(youTube)
      ..registerSingleton<KickChatStore>(kick)
      ..registerSingleton<CombinedChatStore>(combined);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await kick.dispose();
    await youTube.dispose();
    await twitch.dispose();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('the card spans the row and shows name, channels, on-air '
      'summary', (tester) async {
    await tester.pumpWidget(wrap(const CombinedChatPicker()));

    final card = tester.getRect(find.byKey(const Key('combined-combo-card')));
    final page = tester.getRect(find.byType(Scaffold));
    expect(card.width, page.width - 32.0, reason: 'full width, not a column');

    expect(find.text('My chats'), findsOneWidget);
    expect(find.text('My Channel · kicker'), findsOneWidget);

    /// Kick's chat is connected, but nobody is on air: "Offline", never
    /// a connection count dressed up as "live".
    expect(find.byKey(const Key('combined-summary-offline')), findsOneWidget);
    expect(find.textContaining('live'), findsNothing);
    expect(find.byKey(const Key('combined-stack-YouTube')), findsOneWidget);
    expect(find.byKey(const Key('combined-stack-Kick')), findsOneWidget);
  });

  testWidgets('tapping the card opens the switcher: My chats, saved combos, '
      'a plain "New combined chat" button', (tester) async {
    combined.combos.add(
      const CombinedCombo(id: 'c1', name: 'Co-stream', kickSlug: 'aaa'),
    );
    await tester.pumpWidget(wrap(const CombinedChatPicker()));

    await tester.tap(find.byKey(const Key('combined-combo-card')));
    await tester.pumpAndSettle();

    expect(find.text('Combined chats'), findsOneWidget);
    expect(find.byKey(const Key('combined-combo-tile-my')), findsOneWidget);
    expect(find.byKey(const Key('combined-combo-tile-c1')), findsOneWidget);
    expect(find.text('Kick: aaa'), findsOneWidget);
    expect(find.text('New combined chat'), findsOneWidget);
    expect(find.textContaining('…'), findsNothing);

    /// Selecting persists to Hive — real I/O must run outside the
    /// fake-async zone or the suite hangs at shutdown.
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('combined-combo-tile-c1')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(combined.selectedComboId, 'c1');
    expect(find.text('Combined chats'), findsNothing);
  });

  testWidgets('on air rings the badge and fills the summary; connection '
      'problems get a marker; a healthy connection shows nothing', (
    tester,
  ) async {
    /// Kick: chat connected + streamer live. YouTube: needs setup
    /// (unconfigured), not live.
    kick.channelInfo = const KickChannelInfo(
      id: 1,
      slug: 'kicker',
      chatroom: KickChatroom(id: 2),
      livestream: KickLivestreamInfo(isLive: true, viewerCount: 3100),
    );
    await tester.pumpWidget(wrap(const CombinedChatPicker()));

    expect(find.byKey(const Key('combined-stack-live-Kick')), findsOneWidget);
    expect(find.byKey(const Key('combined-stack-live-YouTube')), findsNothing);
    expect(find.byKey(const Key('combined-summary-live')), findsOneWidget);
    expect(find.text('3.1k'), findsOneWidget);

    /// Kick is healthy: no marker. YouTube needs the user: a marker.
    expect(find.byKey(const Key('combined-stack-issue-Kick')), findsNothing);
    expect(
      find.byKey(const Key('combined-stack-issue-YouTube')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('combined-summary-issues')), findsOneWidget);
  });

  testWidgets('"Manage" on My chats opens My chats even when a saved combo '
      'is shown', (tester) async {
    combined.combos.add(
      const CombinedCombo(id: 'c1', name: 'Co-stream', kickSlug: 'aaa'),
    );
    combined.selectedComboId = 'c1';
    await tester.pumpWidget(wrap(const CombinedChatPicker()));

    await tester.tap(find.byKey(const Key('combined-combo-card')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('combined-combo-tile-my')),
        matching: find.text('Manage'),
      ),
    );
    await tester.pumpAndSettle();

    /// The My-chats sheet: its intro text + per-platform toggles, not the
    /// combo's Edit header.
    expect(
      find.textContaining('Your own channels on each platform'),
      findsOneWidget,
    );
    expect(find.text('Edit'), findsNothing);
  });

  test('same-name channels collapse to one name + platforms', () {
    const same = [
      CombinedSource(platform: ChatType.Twitch, key: '1', label: 'LVNDMARK'),
      CombinedSource(platform: ChatType.YouTube, key: 'y', label: 'LVNDMARK'),
      CombinedSource(platform: ChatType.Kick, key: 'k', label: 'lvndmark'),
    ];
    expect(combinedSourcesSubtitle(same), 'LVNDMARK on Twitch, YouTube, Kick');
    const mixed = [
      CombinedSource(platform: ChatType.Twitch, key: '1', label: 'xQcOW'),
      CombinedSource(platform: ChatType.Kick, key: 'k', label: 'kicker'),
    ];
    expect(combinedSourcesSubtitle(mixed), 'xQcOW · kicker');
  });
}
