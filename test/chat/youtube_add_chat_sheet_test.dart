import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/shared/design/count_up_text.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_channel_search_service.dart';
import 'package:obs_blade/utils/youtube/youtube_entry_name.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube/youtube_live_status_service.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_add_chat_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_youtube_services.dart';

const String kUcA = 'UCaaaaaaaaaaaaaaaaaaaaaa';
const String kUcB = 'UCbbbbbbbbbbbbbbbbbbbbbb';

class FakeNamer extends YouTubeEntryNamer {
  final List<YouTubeTarget> calls = [];

  @override
  Future<String> nameFor(YouTubeTarget target) async {
    this.calls.add(target);
    return 'Named ${target.storageValue}';
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late YouTubeChatStore store;
  late FakeChannelSearchService search;
  late FakeNamer namer;

  /// `/live` per channel path (unlisted: no clear answer → unknown, the
  /// search's own LIVE stays - "search shows LIVE" relies on it) and
  /// `videos.list` details per video id; [liveGate] holds the `/live`
  /// answers back until completed
  late Map<String, Object?> liveVideos;
  late Map<String, Map<String, Object?>> liveDetails;
  late List<Uri> videosCalls;
  Completer<void>? liveGate;

  YouTubeLiveStatusService liveStatus() => YouTubeLiveStatusService(
    resolver: _GatedLiveResolver(
      () => liveGate?.future,
      liveVideos,
      fallback: const YouTubeLiveResolveException('no answer'),
    ),
    client: MockClient((request) async {
      videosCalls.add(request.url);
      return http.Response(
        json.encode({
          'items': [
            for (final id in request.url.queryParameters['id']!.split(','))
              if (liveDetails[id] != null)
                {'id': id, 'liveStreamingDetails': liveDetails[id]},
          ],
        }),
        200,
      );
    }),
  );

  Box settings() => Hive.box(HiveKeys.Settings.name);

  Map<String, String> entries() => Map<String, String>.from(
    settings().get(
      SettingsKeys.YouTubeUsernames.name,
      defaultValue: <String, String>{},
    ),
  );

  /// FakeAsync-zone Hive close dance (see native_chat_options_sheet_test).
  Future<void> closeHiveInZone(WidgetTester tester) async {
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
    }
    await tester.pump();
    expect(closed, isTrue);
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
        YouTubeAuth.kBoxKey,
        YouTubeAuth(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
          scopes: kYouTubeChatScopes,
        ),
      );
    });
    store.authState = YouTubeAuthState.signedIn;
  }

  /// Opens the sheet from a button so it can pop; [result] gets the pop
  /// value.
  Future<void> open(
    WidgetTester tester, {
    bool pickOnly = false,
    void Function(YouTubeAddChatPick?)? result,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final pick = await showYouTubeAddChatSheet(
                  context,
                  searchService: search,
                  namer: namer,
                  liveStatusService: liveStatus(),
                  pickOnly: pickOnly,
                );
                result?.call(pick);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('youtube_add_chat_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    await settings().put(SettingsKeys.YouTubeApiKey.name, 'key-1');
    search = FakeChannelSearchService();
    namer = FakeNamer();
    liveVideos = {};
    liveDetails = {};
    videosCalls = [];
    liveGate = null;

    /// Not Pro: selecting a channel stays a selection (no poll loop in
    /// the fake-async zone).
    store = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: FakeYouTubeLiveChatService(),
      liveResolver: FakeYouTubeLiveResolver(),
      isProResolver: () => false,
    );
    GetIt.instance.registerSingleton<YouTubeChatStore>(store);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    if (Hive.isBoxOpen(HiveKeys.Settings.name)) await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('signed out: a hint, no subscriptions call', (tester) async {
    await open(tester);

    expect(find.textContaining('paste an @handle'), findsOneWidget);
    expect(find.text('Channels you subscribe to'), findsNothing);
    expect(search.subscriptionCalls, 0);
    await closeHiveInZone(tester);
  });

  testWidgets('signed in: subscriptions list; a tap adds the channel by id '
      'under its title and switches to it', (tester) async {
    await signIn(tester);
    search.subscriptions = const [
      YouTubeChannelSuggestion(
        channelId: kUcA,
        title: 'Alpha',
        handle: '@alpha',
        subscriberCount: 1200,
      ),
    ];
    await open(tester);

    expect(find.text('Channels you subscribe to'), findsOneWidget);
    expect(find.text('@alpha · 1.2K subscribers'), findsOneWidget);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(entries(), {'Alpha': kUcA});
    expect(store.selectedChannelLabel, 'Alpha');
    expect(find.text('Channels you subscribe to'), findsNothing);
    expect(
      settings().get(SettingsKeys.SelectedYouTubeUsername.name),
      isNull,
      reason: 'the WebView selection is left alone',
    );
    await closeHiveInZone(tester);
  });

  testWidgets('a subscriptions failure shows a retry row', (tester) async {
    await signIn(tester);
    search.subscriptionsThrows = const YouTubeApiException('boom');
    await open(tester);

    expect(find.text('Could not load this list'), findsOneWidget);
    search.subscriptionsThrows = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('None'), findsOneWidget);
    await closeHiveInZone(tester);
  });

  testWidgets('search shows LIVE and checks off listed channels', (
    tester,
  ) async {
    await tester.runAsync(
      () =>
          settings().put(SettingsKeys.YouTubeUsernames.name, {'Beta': '@beta'}),
    );
    store.reloadChannels();
    search.results['mark'] = const [
      YouTubeChannelSuggestion(channelId: kUcA, title: 'Mark', isLive: true),
      YouTubeChannelSuggestion(
        channelId: kUcB,
        title: 'Beta TV',
        handle: '@beta',
      ),
    ];
    await open(tester);
    await type(tester, 'mark');

    expect(search.searchCalls, ['mark']);
    expect(find.byKey(const Key('add-chat-live-search-$kUcA')), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    /// The listed one is inert.
    await tester.tap(find.text('Beta TV'));
    await tester.pumpAndSettle();
    expect(find.text('Beta TV'), findsOneWidget);
    await closeHiveInZone(tester);
  });

  testWidgets('under 3 characters there is no search', (tester) async {
    await open(tester);
    await type(tester, 'ma');

    expect(find.text('Type at least 3 characters'), findsOneWidget);
    expect(search.searchCalls, isEmpty);
    await closeHiveInZone(tester);
  });

  testWidgets('used-up searches: says so and offers the word as a handle', (
    tester,
  ) async {
    search.searchThrows = const YouTubeQuotaExceededException('quota');
    await open(tester);
    await type(tester, 'markiplier');

    expect(find.textContaining('100 searches a day'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    final handleRow = find.byKey(
      const Key('youtube-add-chat-direct-channel:@markiplier'),
    );
    expect(handleRow, findsOneWidget);

    await tester.tap(handleRow);
    await tester.pumpAndSettle();
    expect(namer.calls.single, const YouTubeChannelTarget('@markiplier'));
    expect(entries(), {'Named @markiplier': '@markiplier'});
    await closeHiveInZone(tester);
  });

  testWidgets('a link is taken as is, without a search', (tester) async {
    await open(tester);
    await type(tester, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');

    expect(search.searchCalls, isEmpty);
    expect(find.text('Stream dQw4w9WgXcQ'), findsOneWidget);
    expect(find.text('Pins this one stream'), findsOneWidget);

    await type(tester, 'youtube.com/nothing-here');
    expect(find.text('Not a YouTube channel or stream link'), findsOneWidget);
    await closeHiveInZone(tester);
  });

  testWidgets('pick mode returns the pick and saves nothing', (tester) async {
    YouTubeAddChatPick? picked;
    search.results['alpha'] = const [
      YouTubeChannelSuggestion(channelId: kUcA, title: 'Alpha'),
    ];
    await tester.runAsync(
      () => settings().put(SettingsKeys.YouTubeUsernames.name, {
        'Alpha': '@someoneelse',
      }),
    );
    await open(tester, pickOnly: true, result: (pick) => picked = pick);
    expect(find.text('YouTube channel'), findsOneWidget);
    await type(tester, 'alpha');
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    expect(picked?.label, 'Alpha (2)', reason: 'name taken by another entry');
    expect(picked?.value, kUcA);
    expect(entries(), {'Alpha': '@someoneelse'});
    await closeHiveInZone(tester);
  });

  testWidgets('a name with "." or "/" is searched, not taken as a link', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'Mr. Beast');

    expect(search.searchCalls, ['Mr. Beast']);
    expect(find.text('Not a YouTube channel or stream link'), findsNothing);
    await closeHiveInZone(tester);
  });

  testWidgets('pick mode: a subscription already listed by @handle comes '
      'back as that entry, not a second copy', (tester) async {
    YouTubeAddChatPick? picked;
    await signIn(tester);
    search.subscriptions = const [
      YouTubeChannelSuggestion(channelId: kUcB, title: 'Beta', handle: '@beta'),
    ];
    await tester.runAsync(
      () => settings().put(SettingsKeys.YouTubeUsernames.name, {
        'Beta Stream': '@beta',
      }),
    );
    await open(tester, pickOnly: true, result: (pick) => picked = pick);
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();

    expect(picked?.label, 'Beta Stream');
    expect(picked?.value, '@beta');
    await closeHiveInZone(tester);
  });

  testWidgets('a pasted @handle of a channel listed by UC id switches to '
      'that entry instead of adding a copy', (tester) async {
    await tester.runAsync(
      () => settings().put(SettingsKeys.YouTubeUsernames.name, {'Beta': kUcB}),
    );
    store.reloadChannels();
    search.aliases['@beta'] = {const YouTubeChannelTarget('channel/$kUcB').key};
    await open(tester);
    await type(tester, '@beta');
    await tester.tap(
      find.byKey(const Key('youtube-add-chat-direct-channel:@beta')),
    );
    await tester.pumpAndSettle();

    expect(entries(), {'Beta': kUcB});
    expect(store.selectedChannelLabel, 'Beta');
    await closeHiveInZone(tester);
  });

  testWidgets('a pasted own @handle selects the own channel ("You")', (
    tester,
  ) async {
    store.ownChannel = const YouTubeChatChannel(
      label: kYouTubeOwnChannelLabel,
      target: YouTubeChannelTarget('channel/$kUcA'),
      isOwn: true,
      title: 'Me',
    );
    search.aliases['@mine'] = {const YouTubeChannelTarget('channel/$kUcA').key};
    await open(tester);
    await type(tester, '@mine');
    await tester.tap(
      find.byKey(const Key('youtube-add-chat-direct-channel:@mine')),
    );
    await tester.pumpAndSettle();

    expect(entries(), isEmpty);
    expect(store.selectedChannelLabel, kYouTubeOwnChannelLabel);
    await closeHiveInZone(tester);
  });

  group('LIVE + viewers', () {
    const live = {'actualStartTime': '2026-10-04T10:00:00Z'};
    Finder viewers(String label) => find.byWidgetPredicate(
      (widget) => widget is CountUpText && widget.value == label,
    );

    testWidgets('subscriptions: live ones first, most viewers on top, the '
        'rest A-Z; a hidden count is LIVE without a number', (tester) async {
      await signIn(tester);
      search.subscriptions = const [
        YouTubeChannelSuggestion(channelId: 'UCalpha', title: 'Alpha'),
        YouTubeChannelSuggestion(channelId: 'UCbeta', title: 'Beta'),
        YouTubeChannelSuggestion(channelId: 'UCcharlie', title: 'Charlie'),
        YouTubeChannelSuggestion(channelId: 'UCdelta', title: 'Delta'),
        YouTubeChannelSuggestion(channelId: 'UCgamma', title: 'Gamma'),
        YouTubeChannelSuggestion(channelId: 'UCsched', title: 'Scheduled'),
      ];
      liveVideos.addAll({
        'channel/UCalpha': null,
        'channel/UCbeta': 'vBeta',
        'channel/UCdelta': 'vDelta',
        'channel/UCgamma': 'vGamma',
        'channel/UCsched': 'vSched',
      });
      liveDetails.addAll({
        'vBeta': {...live, 'concurrentViewers': '50'},
        'vDelta': live,
        'vGamma': {...live, 'concurrentViewers': '1234'},
        'vSched': {'scheduledStartTime': '2026-10-05T10:00:00Z'},
      });
      await open(tester);

      double top(String title) => tester.getTopLeft(find.text(title)).dy;
      final order = ['Gamma', 'Beta', 'Delta', 'Alpha', 'Charlie', 'Scheduled'];
      for (var i = 1; i < order.length; i++) {
        expect(
          top(order[i - 1]),
          lessThan(top(order[i])),
          reason: '${order[i - 1]} above ${order[i]}',
        );
      }
      expect(viewers('1.2k'), findsOneWidget);
      expect(viewers('50'), findsOneWidget);
      expect(
        find.byKey(const Key('add-chat-live-sub-UCdelta')),
        findsOneWidget,
      );
      for (final id in ['UCalpha', 'UCcharlie', 'UCsched']) {
        expect(find.byKey(Key('add-chat-live-sub-$id')), findsNothing);
      }
      expect(videosCalls, hasLength(1), reason: 'one videos.list per chunk');
      await closeHiveInZone(tester);
    });

    testWidgets('search: the /live check beats the search index both ways', (
      tester,
    ) async {
      search.results['mark'] = const [
        YouTubeChannelSuggestion(channelId: kUcA, title: 'Mark', isLive: true),
        YouTubeChannelSuggestion(channelId: kUcB, title: 'Mark Live'),
      ];
      liveVideos.addAll({'channel/$kUcA': null, 'channel/$kUcB': 'vB'});
      liveDetails['vB'] = {...live, 'concurrentViewers': '900'};
      await open(tester);
      await type(tester, 'mark');

      expect(find.byKey(const Key('add-chat-live-search-$kUcA')), findsNothing);
      expect(
        find.byKey(const Key('add-chat-live-search-$kUcB')),
        findsOneWidget,
      );
      expect(viewers('900'), findsOneWidget);
      await closeHiveInZone(tester);
    });

    testWidgets('a press stays with its channel when the list reorders '
        'under it (rows move once, after the check)', (tester) async {
      await signIn(tester);
      search.subscriptions = const [
        YouTubeChannelSuggestion(channelId: 'UCalpha', title: 'Alpha'),
        YouTubeChannelSuggestion(channelId: 'UCzed', title: 'Zed'),
      ];
      liveVideos['channel/UCzed'] = 'vZed';
      liveDetails['vZed'] = {...live, 'concurrentViewers': '500'};
      liveGate = Completer<void>();
      await open(tester);

      final alphaTop = tester.getTopLeft(find.text('Alpha')).dy;
      expect(alphaTop, lessThan(tester.getTopLeft(find.text('Zed')).dy));
      final press = await tester.startGesture(
        tester.getCenter(find.text('Alpha')),
      );
      liveGate!.complete();
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Zed')).dy,
        lessThan(tester.getTopLeft(find.text('Alpha')).dy),
      );

      await press.up();
      await tester.pumpAndSettle();
      expect(entries(), {'Alpha': 'UCalpha'});
      await closeHiveInZone(tester);
    });
  });
}

/// [KeyedLiveResolver] whose answers wait for a gate (null: answer now)
class _GatedLiveResolver extends KeyedLiveResolver {
  final Future<void>? Function() gate;

  _GatedLiveResolver(this.gate, super.answers, {super.fallback});

  @override
  Future<String?> resolveLiveVideoId(YouTubeChannelTarget channel) async {
    await this.gate();
    return super.resolveLiveVideoId(channel);
  }
}
