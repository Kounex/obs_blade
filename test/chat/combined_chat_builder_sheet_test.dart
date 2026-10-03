import 'dart:async';
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
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/combined/combined_match_finder.dart';
import 'package:obs_blade/utils/youtube/youtube_entry_name.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_kick_username.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_youtube_username.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/combined_chat_builder_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/add_chat_sheet.dart';

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

/// Answers like the real namer for a channel id: the channel's title
class FakeNamer extends YouTubeEntryNamer {
  final List<YouTubeTarget> asked = [];

  /// `/@handle` pages that exist (path -> og:title)
  final Map<String, String> pages = {};

  @override
  Future<String> nameFor(YouTubeTarget target) async {
    this.asked.add(target);
    return 'NASA';
  }

  @override
  Future<String?> channelPageTitle(String path) async => this.pages[path];
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  /// Set when a test closed Hive itself (see [closeHiveInZone])
  var hiveClosed = false;
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
    if (!hiveClosed) {
      await kick.dispose();
      await youTube.dispose();
      await twitch.dispose();
      await harness.close();
    }
    hiveClosed = false;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// The add dialogs write settings inside the test's FakeAsync zone, whose
  /// Hive write Completers only complete there - a real-zone close in
  /// tearDown would hang (handoff § gotchas). Unmount and close here.
  Future<void> closeHiveInZone(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await kick.dispose();
      await youTube.dispose();
      await twitch.dispose();
    });
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 20 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    expect(closed, isTrue);
    hiveClosed = true;
  }

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

  Future<void> pumpBuilder(
    WidgetTester tester, {
    FakeNamer? namer,
    FakeTwitchChannelService? twitchChannels,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CombinedChatBuilderSheet(
              matchFinder: finder,
              youTubeNamer: namer,
              twitchChannelService: twitchChannels,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openOther(WidgetTester tester, ChatType platform) async {
    await tester.tap(find.byKey(Key('combined-builder-${platform.name}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other ${platform.text} channel…').last);
    await tester.pumpAndSettle();
  }

  /// "Other…" reuses the platform's own picker: Twitch's Add chat sheet
  /// (follows / moderated / live / search) in pick mode.
  testWidgets('"Other Twitch channel…" opens the Add chat sheet; a followed '
      'channel becomes the pick', (tester) async {
    await tester.runAsync(() async {
      await Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).put(
        TwitchAuth.kBoxKey,
        TwitchAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
          scopes: const ['user:read:follows'],
          userId: FakeTwitchAuthService.user.id,
        ),
      );
    });
    twitch.authState = TwitchAuthState.loggedIn;
    twitch.user = FakeTwitchAuthService.user;
    final channels = FakeTwitchChannelService()
      ..followedChannels = [
        TwitchChannelRef(
          id: 'f1',
          login: 'friend',
          displayName: 'Friend',
          addedAt: DateTime.utc(2026, 10, 3),
        ),
      ]
      ..liveStreams = const {'f1': 120};
    await pumpBuilder(tester, twitchChannels: channels);
    await openOther(tester, ChatType.Twitch);

    expect(find.byType(AddChatSheet), findsOneWidget);
    expect(find.text('Twitch channel'), findsOneWidget);
    expect(find.text('Channels you follow'), findsOneWidget);

    await tester.tap(find.text('Friend'));
    await tester.pumpAndSettle();

    expect(find.byType(AddChatSheet), findsNothing);
    expect(find.text('Friend'), findsOneWidget);

    /// Picked, not added to the Twitch list (the combo registers it on
    /// save)
    expect(twitch.channels.map((c) => c.id), isNot(contains('f1')));
  });

  testWidgets('"Other Twitch channel…" signed out says to sign in', (
    tester,
  ) async {
    await pumpBuilder(tester);
    await openOther(tester, ChatType.Twitch);

    expect(find.byType(AddChatSheet), findsNothing);
    expect(find.text('Sign in to Twitch to find channels'), findsOneWidget);
  });

  testWidgets('"Other YouTube channel…" opens the YouTube add dialog; the '
      'entry is named by the channel title and the WebView selection stays', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.SelectedYouTubeUsername.name, 'Kept');
    });
    final namer = FakeNamer();
    await pumpBuilder(tester, namer: namer);
    await openOther(tester, ChatType.YouTube);

    expect(find.text('Add YouTube Chat'), findsOneWidget);
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AddEditYouTubeUsernameDialog),
            matching: find.byType(EditableText),
          )
          .first,
      'https://www.youtube.com/channel/UCLA_DiR1FfKNvjuUpBHmylQ',
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(namer.asked.single, isA<YouTubeChannelTarget>());
    expect(find.text('NASA'), findsOneWidget);
    expect(find.textContaining('UCLA_'), findsNothing);
    expect(
      Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.SelectedYouTubeUsername.name),
      'Kept',
    );
    expect(finder.asked.single.$1, 'NASA');
    await closeHiveInZone(tester);
  });

  testWidgets('"Other Kick channel…" opens the Kick add dialog; the WebView '
      'selection stays', (tester) async {
    await pumpBuilder(tester);
    await openOther(tester, ChatType.Kick);

    expect(find.text('Add Kick Channel'), findsOneWidget);
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AddEditKickUsernameDialog),
            matching: find.byType(EditableText),
          )
          .first,
      'kick.com/friend',
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(find.text('friend'), findsOneWidget);
    expect(
      Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.SelectedKickUsername.name),
      isNull,
    );
    await closeHiveInZone(tester);
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

  testWidgets('the channel menu lists A–Z with LIVE / OFFLINE tags', (
    tester,
  ) async {
    kick.channels.addAll(['alpha', 'mid']);
    kick.channelLivePreview['xqc'] = const KickChannelInfo(
      id: 1,
      slug: 'xqc',
      chatroom: KickChatroom(id: 2),
      livestream: KickLivestreamInfo(isLive: true, viewerCount: 5000),
    );
    kick.channelLivePreview['alpha'] = const KickChannelInfo(
      id: 3,
      slug: 'alpha',
      chatroom: KickChatroom(id: 4),
    );
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('combined-builder-Kick')));
    await tester.pumpAndSettle();

    double top(String text) => tester.getTopLeft(find.text(text).last).dy;
    expect(top('alpha'), lessThan(top('mid')));
    expect(top('mid'), lessThan(top('xqc')));
    expect(
      find.byKey(const Key('combined-builder-live-Kick-xqc')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('combined-builder-offline-Kick-alpha')),
      findsOneWidget,
    );

    /// Not resolved yet: no claim either way.
    expect(
      find.byKey(const Key('combined-builder-live-Kick-mid')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('combined-builder-offline-Kick-mid')),
      findsNothing,
    );
  });
}
