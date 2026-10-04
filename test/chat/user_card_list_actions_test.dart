import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_user_card_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart' show FakeThirdPartyEmoteService;
import 'support/fake_youtube_services.dart';
import 'youtube_chat_message_row_test.dart' show ytMessage;

/// Highlight / ignore from the user card on YouTube and Kick, like Twitch:
/// rows for others (never for yourself), writing the name the platform's
/// rows are matched by.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box<dynamic> settings() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('user_card_lists');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Widget host(Widget Function(BuildContext context) card) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => SingleChildScrollView(child: card(context)),
      ),
    ),
  );

  group('YouTube', () {
    setUp(() async {
      await Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
        YouTubeAuth.kBoxKey,
        YouTubeAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: 0,
          scopes: kYouTubeChatScopes,
          channelTitle: 'Me',
          channelId: 'UCme',
        ),
      );
      GetIt.instance.registerSingleton<YouTubeChatStore>(
        YouTubeChatStore(
          authService: FakeYouTubeAuthService(),
          chatService: FakeYouTubeLiveChatService(),
          isProResolver: () => true,
        ),
      );
    });

    testWidgets('another viewer: highlight writes their display name', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => YouTubeUserCardSheet(
            channelId: 'UCremy',
            fallbackName: 'Remy',
            hostContext: context,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Highlight Remy'), findsOneWidget);
      expect(find.text('Ignore Remy'), findsOneWidget);

      /// The tap writes Hive - outside the fake clock (a put in a
      /// testWidgets body hangs the file at teardown)
      await tester.runAsync(() async {
        await tester.tap(find.text('Highlight Remy'));
        await Hive.box(HiveKeys.Settings.name).flush();
      });
      await tester.pump();
      expect(
        settings().get(SettingsKeys.ChatHighlightUsers.name) as String,
        contains('Remy'),
      );
    });

    testWidgets('a chatty viewer: the card stops at 2/3 of the screen and '
        'the history scrolls under the pinned name', (tester) async {
      final store = GetIt.instance<YouTubeChatStore>();
      runInAction(() {
        for (var i = 0; i < 20; i++) {
          store.messages.add(
            ytMessage(
              'm$i',
              author: 'UCremy',
              authorName: 'Remy',
              text: 'message number $i with some words to wrap the line',
            ),
          );
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showYouTubeUserCardSheet(context, channelId: 'UCremy'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final sheet = tester.getSize(find.byType(YouTubeUserCardSheet));
      expect(sheet.height, lessThanOrEqualTo(screen * 2 / 3 + 1));

      /// Newest first; the oldest of the 20 is below the fold until
      /// scrolled to
      final oldest = find.textContaining(
        'message number 0 ',
        findRichText: true,
      );
      expect(tester.getTopLeft(oldest).dy, greaterThan(screen));
      await tester.scrollUntilVisible(
        oldest,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.getTopLeft(oldest).dy, lessThan(screen));
      expect(find.text('Remy'), findsWidgets);
    });

    testWidgets('own card: no highlight / ignore', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => YouTubeUserCardSheet(
            channelId: 'UCme',
            fallbackName: 'Me',
            hostContext: context,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Highlight'), findsNothing);
      expect(find.textContaining('Ignore'), findsNothing);
    });
  });

  group('Kick', () {
    setUp(() async {
      await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
        KickAuth.kBoxKey,
        KickAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: kKickChatScopes,
          userId: 7,
          username: 'me',
        ),
      );
      GetIt.instance.registerSingleton<KickChatStore>(
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
              KickEmoteStore(service: FakeKickEmoteService()),
        ),
      );
    });

    testWidgets('another viewer: ignore writes their username', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => KickUserCardSheet(
            userId: 42,
            fallbackName: 'kickfan',
            hostContext: context,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Ignore kickfan'), findsOneWidget);

      /// The tap writes Hive - outside the fake clock (a put in a
      /// testWidgets body hangs the file at teardown)
      await tester.runAsync(() async {
        await tester.tap(find.text('Ignore kickfan'));
        await Hive.box(HiveKeys.Settings.name).flush();
      });
      await tester.pump();
      expect(
        settings().get(SettingsKeys.ChatIgnoredUsers.name) as String,
        contains('kickfan'),
      );
    });

    testWidgets('own card: no highlight / ignore', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => KickUserCardSheet(
            userId: 7,
            fallbackName: 'me',
            hostContext: context,
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Ignore'), findsNothing);
    });
  });
}
