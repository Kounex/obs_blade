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
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/combined/combined_match_finder.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/combined_chat_builder_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart';
import 'support/fake_youtube_services.dart';

/// Scripted suggestions — records what was asked.
class FakeFinder extends CombinedMatchFinder {
  final List<CombinedMatch> results;
  final List<(String, Set<ChatType>)> asked = [];

  FakeFinder(this.results);

  @override
  Future<List<CombinedMatch>> find(
    String name, {
    required Set<ChatType> platforms,
  }) async {
    this.asked.add((name, platforms));
    return [
      for (final match in this.results)
        if (platforms.contains(match.platform)) match,
    ];
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore twitch;
  late YouTubeChatStore youTube;
  late KickChatStore kick;
  late CombinedChatStore combined;
  late FakeFinder finder;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('combined_builder_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);

    /// A Kick channel already on the list — pickable from the menu.
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.KickUsernames.name, ['xqc']);

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
    kick.channels.add('xqc');
    combined = CombinedChatStore(
      twitchStore: () => twitch,
      youTubeStore: () => youTube,
      kickStore: () => kick,
    );
    finder = FakeFinder(const [
      CombinedMatch(platform: ChatType.YouTube, value: '@xqcow', label: 'xQc'),
    ]);
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

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CombinedChatBuilderSheet(matchFinder: finder),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('picking a channel suggests same-name matches; tapping one '
      'fills that platform and unlocks Save', (tester) async {
    await pumpSheet(tester);

    /// Save stays disabled below two sources.
    expect(find.text('Pick at least two channels to save.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('combined-builder-Kick')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('xqc').last);
    await tester.pumpAndSettle();

    /// Looked up on the platforms still empty, by the picked slug.
    expect(finder.asked.single.$1, 'xqc');
    expect(finder.asked.single.$2, {ChatType.Twitch, ChatType.YouTube});
    expect(
      find.byKey(const Key('combined-suggestion-YouTube')),
      findsOneWidget,
    );
    expect(find.text('Pick at least two channels to save.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('combined-suggestion-YouTube')));
    await tester.pumpAndSettle();

    /// The suggestion became the YouTube pick (and left the chip row).
    expect(find.byKey(const Key('combined-suggestion-YouTube')), findsNothing);
    expect(find.text('xQc'), findsOneWidget);
    expect(find.text('Pick at least two channels to save.'), findsNothing);
  });

  testWidgets('suggestions are never picked on their own', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.byKey(const Key('combined-builder-Kick')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('xqc').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('combined-suggestion-YouTube')),
      findsOneWidget,
    );
    expect(find.text('No YouTube channel'), findsOneWidget);
  });
}
