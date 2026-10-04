import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_channel_suggestion.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_channel_search_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_status_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_add_chat_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_add_chat_sheet.dart';

import '../../test/chat/support/fake_kick_services.dart';
import '../../test/chat/support/fake_youtube_services.dart';
import 'support/shots_harness.dart';

/// The YouTube and Kick "Add chat" sheets: every state a user can reach
/// (empty signed out / in, results, failures, pasted links), phone,
/// 320 pt and tablet.
void main() {
  final harness = ShotsHarness();
  late YouTubeChatStore youTube;
  late KickChatStore kick;
  late FakeChannelSearchService search;
  late FakeKickChannelService kickChannels;
  late FakeKickApiService kickApi;

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.YouTubeApiKey.name, 'key');
    search = FakeChannelSearchService();
    youTube = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      liveResolver: FakeYouTubeLiveResolver(),
      isProResolver: () => false,
    );
    kickChannels = FakeKickChannelService();
    kickApi = FakeKickApiService();
    kick = KickChatStore(
      channelService: kickChannels,
      apiService: kickApi,
      isProResolver: () => false,
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
    );
    GetIt.instance
      ..registerSingleton<YouTubeChatStore>(youTube)
      ..registerSingleton<KickChatStore>(kick);
  });
  tearDown(() async {
    await GetIt.instance.reset();
    await youTube.dispose();
    await kick.dispose();
    await harness.tearDown();
  });

  /// The sheet as showBaseBottomSheet presents it: bottom-aligned card,
  /// capped at the card width on tablets.
  Widget sheet(Widget child) => Builder(
    builder: (context) => Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kBaseCardMaxWidth),
        child: Material(color: Theme.of(context).cardColor, child: child),
      ),
    ),
  );

  Future<void> typeAndShoot(
    WidgetTester tester,
    String query,
    String name,
  ) async {
    await tester.enterText(find.byType(TextField), query);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../build/widget_shots/$name.png'),
    );
  }

  Future<void> signInYouTube(WidgetTester tester) async {
    await tester.runAsync(
      () => Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
        YouTubeAuth.kBoxKey,
        YouTubeAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
          scopes: kYouTubeChatScopes,
        ),
      ),
    );
    youTube.authState = YouTubeAuthState.signedIn;
  }

  Future<void> signInKick(WidgetTester tester) async {
    await tester.runAsync(
      () => Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
        KickAuth.kBoxKey,
        KickAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
          scopes: kKickChatScopes,
          userId: 1,
          username: 'me',
        ),
      ),
    );
    kick.authState = KickAuthState.signedIn;
  }

  const ucA = 'UCaaaaaaaaaaaaaaaaaaaaaa';
  const ucB = 'UCbbbbbbbbbbbbbbbbbbbbbb';
  const ucC = 'UCcccccccccccccccccccccc';

  /// Ludwig and Markiplier live with viewers, NASA live with the count
  /// hidden, the rest offline - no real `/live` reads in the shots
  YouTubeLiveStatusService liveStatus({Completer<void>? gate}) =>
      YouTubeLiveStatusService(
        resolver: _GatedResolver(gate, {
          'channel/$ucA': 'vA',
          'channel/$ucB': 'vB',
        }),
        client: MockClient(
          (request) async => http.Response(
            json.encode({
              'items': [
                {
                  'id': 'vA',
                  'liveStreamingDetails': {
                    'actualStartTime': '2026-10-04T10:00:00Z',
                    'concurrentViewers': '23456',
                  },
                },
                {
                  'id': 'vB',
                  'liveStreamingDetails': {
                    'actualStartTime': '2026-10-04T10:00:00Z',
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

  void scriptYouTubeSearch() {
    search.results['markiplier'] = const [
      YouTubeChannelSuggestion(
        channelId: ucA,
        title: 'Markiplier',
        handle: '@markiplier',
        subscriberCount: 37200000,
        isLive: true,
      ),
      YouTubeChannelSuggestion(
        channelId: ucB,
        title: 'Markiplier Clips and Highlights Every Day Archive',
        handle: '@markiplierclipsandhighlightseverydayarchive',
        subscriberCount: 812000,
      ),
      YouTubeChannelSuggestion(
        channelId: ucC,
        title: 'Unus Annus',
        handle: '@unusannus',
        subscriberCount: 4100000,
      ),
    ];
  }

  Future<void> listUnusAnnus(WidgetTester tester) async {
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.YouTubeUsernames.name, {'Unus Annus': ucC}),
    );
    youTube.reloadChannels();
  }

  group('YouTube', () {
    testWidgets('signed out, then search results', (tester) async {
      scriptYouTubeSearch();
      await listUnusAnnus(tester);
      await harness.shot(
        tester,
        'add_chat_youtube_signed_out',
        sheet(
          YouTubeAddChatSheet(
            searchService: search,
            liveStatusService: liveStatus(),
          ),
        ),
      );
      await typeAndShoot(tester, 'markiplier', 'add_chat_youtube_search');
    });

    testWidgets('search results, narrow', (tester) async {
      scriptYouTubeSearch();
      await listUnusAnnus(tester);
      await harness.shot(
        tester,
        'add_chat_youtube_empty_narrow',
        sheet(
          YouTubeAddChatSheet(
            key: UniqueKey(),
            searchService: search,
            liveStatusService: liveStatus(),
          ),
        ),
        size: const Size(320, 640),
      );
      await typeAndShoot(
        tester,
        'markiplier',
        'add_chat_youtube_search_narrow',
      );
    });

    testWidgets('signed in: subscriptions (tablet)', (tester) async {
      await signInYouTube(tester);
      search.subscriptions = const [
        YouTubeChannelSuggestion(
          channelId: 'UCdddddddddddddddddddddd',
          title: 'Alpha Gaming',
          handle: '@alphagaming',
          subscriberCount: 91000,
        ),
        YouTubeChannelSuggestion(
          channelId: ucA,
          title: 'Ludwig',
          handle: '@ludwig',
          subscriberCount: 5600000,
        ),
        YouTubeChannelSuggestion(
          channelId: ucB,
          title: 'NASA',
          handle: '@nasa',
        ),
        YouTubeChannelSuggestion(channelId: ucC, title: 'Unus Annus'),
      ];
      await listUnusAnnus(tester);
      await harness.shot(
        tester,
        'add_chat_youtube_subscriptions',
        sheet(
          YouTubeAddChatSheet(
            searchService: search,
            liveStatusService: liveStatus(),
          ),
        ),
      );
      await tester.tap(find.text('Live now 2'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../../build/widget_shots/add_chat_youtube_live_only.png',
        ),
      );
      await harness.shot(
        tester,
        'add_chat_youtube_subscriptions_narrow',
        sheet(
          YouTubeAddChatSheet(
            key: UniqueKey(),
            searchService: search,
            liveStatusService: liveStatus(),
          ),
        ),
        size: const Size(320, 640),
      );
      final gate = Completer<void>();
      await harness.shot(
        tester,
        'add_chat_youtube_checking_narrow',
        sheet(
          YouTubeAddChatSheet(
            key: UniqueKey(),
            searchService: search,
            liveStatusService: liveStatus(gate: gate),
          ),
        ),
        size: const Size(320, 640),
      );
      gate.complete();
      await tester.pump(const Duration(seconds: 1));
      await harness.shot(
        tester,
        'add_chat_youtube_subscriptions_tablet',
        sheet(
          YouTubeAddChatSheet(
            key: UniqueKey(),
            searchService: search,
            liveStatusService: liveStatus(),
          ),
        ),
        size: kShotTablet,
      );
    });

    testWidgets('searches used up', (tester) async {
      search.searchThrows = const YouTubeQuotaExceededException('quota');
      await harness.shot(
        tester,
        'add_chat_youtube_start_quota',
        sheet(
          YouTubeAddChatSheet(
            searchService: search,
            liveStatusService: liveStatus(),
          ),
        ),
      );
      await typeAndShoot(tester, 'markiplier', 'add_chat_youtube_quota');
    });

    testWidgets('pasted video link', (tester) async {
      await harness.shot(
        tester,
        'add_chat_youtube_start_link',
        sheet(
          YouTubeAddChatSheet(
            searchService: search,
            liveStatusService: liveStatus(),
          ),
        ),
      );
      await typeAndShoot(
        tester,
        'https://youtu.be/dQw4w9WgXcQ',
        'add_chat_youtube_link',
      );
    });
  });

  void scriptKickSearch() {
    kickChannels.searchResults['xqc'] = const [
      KickChannelSuggestion(
        slug: 'xqc',
        displayName: 'xQc',
        followersCount: 1118300,
        verified: true,
      ),
      KickChannelSuggestion(
        slug: 'xqcow-waiting-room-x',
        displayName: 'xQcOW_waiting_room_X',
        followersCount: 632,
        isLive: true,
      ),
      KickChannelSuggestion(
        slug: 'latruiexqc',
        displayName: 'LaTruiexQc',
        followersCount: 495,
      ),
    ];
  }

  Future<void> listXqc(WidgetTester tester) async {
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.KickUsernames.name, <String>['latruiexqc']),
    );
    kick.reloadChannels();
  }

  group('Kick', () {
    testWidgets('signed out, then search results', (tester) async {
      scriptKickSearch();
      await listXqc(tester);
      await harness.shot(
        tester,
        'add_chat_kick_signed_out',
        sheet(const KickAddChatSheet(languageCode: 'de')),
      );
      await typeAndShoot(tester, 'xqc', 'add_chat_kick_search');
    });

    testWidgets('search results, narrow', (tester) async {
      scriptKickSearch();
      await listXqc(tester);
      await harness.shot(
        tester,
        'add_chat_kick_empty_narrow',
        sheet(const KickAddChatSheet(languageCode: 'de')),
        size: const Size(320, 640),
      );
      await typeAndShoot(tester, 'xqc', 'add_chat_kick_search_narrow');
    });

    testWidgets('signed in: popular live (phone + tablet)', (tester) async {
      await signInKick(tester);
      kickApi.popular['de'] = const [
        KickChannelSuggestion(
          slug: 'denzelthom',
          displayName: 'denzelthom',
          isLive: true,
          viewerCount: 538,
          categoryName: 'Just Chatting',
        ),
        KickChannelSuggestion(
          slug: 'ronbielecki',
          displayName: 'ronbielecki',
          isLive: true,
          viewerCount: 242,
          categoryName: 'Grand Theft Auto V (GTA)',
        ),
        KickChannelSuggestion(
          slug: 'angelinaftg',
          displayName: 'angelinaftg',
          isLive: true,
          viewerCount: 1232,
        ),
      ];
      await harness.shot(
        tester,
        'add_chat_kick_popular',
        sheet(const KickAddChatSheet(languageCode: 'de')),
      );
      await harness.shot(
        tester,
        'add_chat_kick_popular_tablet',
        sheet(const KickAddChatSheet(languageCode: 'de')),
        size: kShotTablet,
      );
    });

    testWidgets('search failure keeps the typed slug', (tester) async {
      kickChannels.searchThrows = const KickApiException('blocked');
      await harness.shot(
        tester,
        'add_chat_kick_start_error',
        sheet(const KickAddChatSheet(languageCode: 'de')),
      );
      await typeAndShoot(tester, 'somestreamer', 'add_chat_kick_error');
    });
  });
}

/// [KeyedLiveResolver] holding its answers until [gate] completes
class _GatedResolver extends KeyedLiveResolver {
  final Completer<void>? gate;

  _GatedResolver(this.gate, super.answers);

  @override
  Future<String?> resolveLiveVideoId(YouTubeChannelTarget channel) async {
    await this.gate?.future;
    return super.resolveLiveVideoId(channel);
  }
}
