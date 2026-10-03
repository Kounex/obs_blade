import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_channel_suggestion.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_add_chat_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeKickChannelService channelService;
  late FakeKickApiService apiService;
  late KickChatStore store;

  Box settings() => Hive.box(HiveKeys.Settings.name);

  List<String> slugs() => List<String>.from(
    settings().get(SettingsKeys.KickUsernames.name, defaultValue: <String>[]),
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
      await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
        KickAuth.kBoxKey,
        KickAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: kKickChatScopes,
          userId: 9001,
          username: 'kicker',
        ),
      );
    });
    store.authState = KickAuthState.signedIn;
  }

  Future<void> open(
    WidgetTester tester, {
    bool pickOnly = false,
    void Function(String?)? result,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final slug = await showKickAddChatSheet(
                  context,
                  pickOnly: pickOnly,
                  languageCode: 'de',
                );
                result?.call(slug);
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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_add_chat_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
    channelService = FakeKickChannelService();
    apiService = FakeKickApiService();

    /// Not Pro: selecting a channel stays a selection (no socket).
    store = KickChatStore(
      channelService: channelService,
      apiService: apiService,
      isProResolver: () => false,
      pusherFactory: ({required onEvent, required onStateChanged}) =>
          FakeKickPusherService(
            onEvent: onEvent,
            onStateChanged: onStateChanged,
          ),
    );
    GetIt.instance.registerSingleton<KickChatStore>(store);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    if (Hive.isBoxOpen(HiveKeys.Settings.name)) await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('signed out: a hint, no live listing - search still works', (
    tester,
  ) async {
    channelService.searchResults['xqc'] = const [
      KickChannelSuggestion(slug: 'xqc', displayName: 'xQc', verified: true),
    ];
    await open(tester);

    expect(
      find.textContaining('popular live channels show here'),
      findsOneWidget,
    );
    expect(apiService.popularCalls, isEmpty);

    await type(tester, 'xqc');
    expect(find.text('xQc'), findsOneWidget);
    expect(find.byKey(const Key('add-chat-verified-xqc')), findsOneWidget);
    await closeHiveInZone(tester);
  });

  testWidgets('signed in: popular live in the device language', (tester) async {
    await signIn(tester);
    apiService.popular['de'] = const [
      KickChannelSuggestion(
        slug: 'denzelthom',
        displayName: 'denzelthom',
        isLive: true,
        viewerCount: 538,
        categoryName: 'Just Chatting',
      ),
    ];
    await open(tester);

    expect(apiService.popularCalls, ['de']);
    expect(find.text('Popular live now'), findsOneWidget);
    expect(find.text('Just Chatting'), findsOneWidget);
    expect(
      find.byKey(const Key('add-chat-live-popular-denzelthom')),
      findsOneWidget,
    );
    await closeHiveInZone(tester);
  });

  testWidgets('nobody live in the language: falls back to every language', (
    tester,
  ) async {
    await signIn(tester);
    apiService.popular[''] = const [
      KickChannelSuggestion(slug: 'big', displayName: 'big', isLive: true),
    ];
    await open(tester);

    expect(apiService.popularCalls, ['de', '']);
    expect(find.text('big'), findsOneWidget);
    await closeHiveInZone(tester);
  });

  testWidgets('a pick adds the slug to the list and switches to it', (
    tester,
  ) async {
    channelService.searchResults['trai'] = const [
      KickChannelSuggestion(
        slug: 'trainwreckstv',
        displayName: 'Trainwreckstv',
        followersCount: 648586,
        isLive: true,
      ),
    ];
    await open(tester);
    await type(tester, 'trai');

    expect(find.text('649K followers'), findsOneWidget);
    expect(
      find.byKey(const Key('add-chat-live-search-trainwreckstv')),
      findsOneWidget,
    );
    await tester.tap(find.text('Trainwreckstv'));
    await tester.pumpAndSettle();

    expect(slugs(), ['trainwreckstv']);
    expect(store.selectedChannelSlug, 'trainwreckstv');
    expect(find.text('Add chat'), findsNothing);
    await closeHiveInZone(tester);
  });

  testWidgets('listed channels are checked off and inert', (tester) async {
    await tester.runAsync(
      () => settings().put(SettingsKeys.KickUsernames.name, <String>['xqc']),
    );
    store.reloadChannels();
    channelService.searchResults['xqc'] = const [
      KickChannelSuggestion(slug: 'xqc', displayName: 'xQc'),
    ];
    await open(tester);
    await type(tester, 'xqc');

    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('xQc'));
    await tester.pumpAndSettle();
    expect(find.text('xQc'), findsOneWidget);
    await closeHiveInZone(tester);
  });

  testWidgets('search failure: retry plus the typed slug as is', (
    tester,
  ) async {
    channelService.searchThrows = const KickApiException('blocked');
    await open(tester);
    await type(tester, 'somestreamer');

    expect(find.text('Could not search Kick'), findsOneWidget);
    final direct = find.byKey(const Key('kick-add-chat-direct-somestreamer'));
    expect(direct, findsOneWidget);
    await tester.tap(direct);
    await tester.pumpAndSettle();
    expect(slugs(), ['somestreamer']);
    await closeHiveInZone(tester);
  });

  testWidgets('a kick.com link is taken as is, without a search', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'https://kick.com/popout/xqc/chat');

    expect(channelService.searchCalls, isEmpty);
    expect(find.byKey(const Key('kick-add-chat-direct-xqc')), findsOneWidget);

    await type(tester, 'twitch.tv/xqc');
    expect(find.text('Not a Kick channel link'), findsOneWidget);
    await closeHiveInZone(tester);
  });

  testWidgets('pick mode returns the slug and saves nothing', (tester) async {
    String? picked;
    await open(tester, pickOnly: true, result: (slug) => picked = slug);
    expect(find.text('Kick channel'), findsOneWidget);
    await type(tester, 'kick.com/xqc');
    await tester.tap(find.byKey(const Key('kick-add-chat-direct-xqc')));
    await tester.pumpAndSettle();

    expect(picked, 'xqc');
    expect(slugs(), isEmpty);
    await closeHiveInZone(tester);
  });
}
