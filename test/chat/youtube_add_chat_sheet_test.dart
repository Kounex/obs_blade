import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_channel_search_service.dart';
import 'package:obs_blade/utils/youtube/youtube_entry_name.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
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
}
