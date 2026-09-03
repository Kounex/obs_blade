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
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_text_field.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_setup_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_youtube_services.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeYouTubeLiveChatService chatService;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  Widget wrap() => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              child: YouTubeSetupSheet(
                hostContext: context,
                chatService: chatService,
              ),
            ),
          ),
        ),
      );

  /// FakeAsync-zone Hive close dance (see native_chat_options_sheet_test).
  Future<void> closeHiveInZone(WidgetTester tester) async {
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yt_setup_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    chatService = FakeYouTubeLiveChatService();
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('prefills the fields from settings', (tester) async {
    /// runAsync: awaited Hive writes never complete in the fake-async zone.
    await tester.runAsync(() async {
      await settingsBox().put(SettingsKeys.YouTubeApiKey.name, 'saved-key');
      await settingsBox()
          .put(SettingsKeys.YouTubeOAuthClientId.name, 'saved-client');
    });

    await tester.pumpWidget(wrap());
    await tester.pump();

    /// The collapsed expansion tile still builds its body (ExpandablePanel
    /// keeps the expanded subtree in the tree, just clipped).
    expect(find.text('saved-key'), findsOneWidget);
    expect(find.text('saved-client'), findsOneWidget);
  });

  testWidgets('empty key never probes the service', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.byKey(const Key('youtube-setup-test-key')), findsOneWidget);
    await tester.tap(find.byKey(const Key('youtube-setup-test-key')));
    await tester.pump();

    /// The button is disabled with an empty field — no probe ran.
    expect(chatService.resolveCalls, 0);
    expect(find.byKey(const Key('youtube-setup-key-valid')), findsNothing);
    expect(find.byKey(const Key('youtube-setup-key-invalid')), findsNothing);
  });

  testWidgets('invalid key shows the inline failure', (tester) async {
    chatService.resolveThrows =
        const YouTubeForbiddenException('Resolving live chat failed (400: API key not valid)');

    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.enterText(
        find.byType(NativeChatTextField).first, 'bad-key');
    await tester.pump();
    await tester.tap(find.byKey(const Key('youtube-setup-test-key')));
    await tester.pump();

    expect(chatService.resolveCalls, 1);
    expect(find.byKey(const Key('youtube-setup-key-invalid')), findsOneWidget);
    expect(find.textContaining('API key not valid'), findsOneWidget);
    expect(find.byKey(const Key('youtube-setup-key-valid')), findsNothing);
  });

  testWidgets('valid key shows the inline success and save persists the keys',
      (tester) async {
    /// try/finally: a failed expectation must still run the FakeAsync-zone
    /// Hive close dance — the save below writes to the settings box, and
    /// skipping the dance deadlocks tearDown's harness.close().
    try {
      await tester.pumpWidget(wrap());
      await tester.pump();

      await tester.enterText(
          find.byType(NativeChatTextField).first, 'good-key');
      await tester.pump();
      await tester.tap(find.byKey(const Key('youtube-setup-test-key')));
      await tester.pump();

      expect(chatService.resolveCalls, 1);
      expect(
          find.byKey(const Key('youtube-setup-key-valid')), findsOneWidget);
      expect(find.byKey(const Key('youtube-setup-key-invalid')), findsNothing);

      /// Editing after a successful probe resets the verdict.
      await tester.enterText(
          find.byType(NativeChatTextField).first, 'good-key-changed');
      await tester.pump();
      expect(find.byKey(const Key('youtube-setup-key-valid')), findsNothing);

      await tester.tap(find.byKey(const Key('youtube-setup-save')));
      await tester.pump();

      expect(
        settingsBox().get(SettingsKeys.YouTubeApiKey.name),
        'good-key-changed',
      );
    } finally {
      await closeHiveInZone(tester);
    }
  });

  testWidgets('saving an empty key deletes the setting', (tester) async {
    try {
      /// runAsync: awaited Hive writes never complete in the fake-async zone.
      await tester.runAsync(() =>
          settingsBox().put(SettingsKeys.YouTubeApiKey.name, 'stale-key'));
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('stale-key'), findsOneWidget);

      await tester.enterText(find.byType(NativeChatTextField).first, '');
      await tester.pump();
      await tester.tap(find.byKey(const Key('youtube-setup-save')));
      await tester.pump();

      expect(settingsBox().get(SettingsKeys.YouTubeApiKey.name), isNull);
    } finally {
      await closeHiveInZone(tester);
    }
  });

  testWidgets(
      'Connect without Save persists the fields and starts the device flow',
      (tester) async {
    final store = YouTubeChatStore(
      authService: FakeYouTubeAuthService(),
      chatService: chatService,
      sleep: (duration) async {},
    );
    try {
      /// runAsync: box opens are real I/O — they never complete in the
      /// fake-async zone.
      await tester.runAsync(
          () => Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name));
      GetIt.instance.registerSingleton<YouTubeChatStore>(store);

      await tester.pumpWidget(wrap());
      await tester.pump();

      await tester.enterText(
          find.byType(NativeChatTextField).at(0), 'fresh-key');
      await tester.pump();
      await tester.tap(find.byKey(const Key('youtube-setup-test-key')));
      await tester.pump();
      expect(
          find.byKey(const Key('youtube-setup-key-valid')), findsOneWidget);

      /// The collapsed tile's fields are clipped to zero size — taps miss
      /// them and enterText would land in the still-focused key field.
      await tester.tap(find.text('Advanced: sign-in (optional)'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(NativeChatTextField).at(1), 'fresh-client');
      await tester.enterText(
          find.byType(NativeChatTextField).at(2), 'fresh-secret');
      await tester.pump();

      /// No Save tap — Connect must persist on its own, otherwise
      /// startLogin's !isConfigured guard bounces to unconfigured and the
      /// device-code dialog spins forever (review finding).
      await tester.ensureVisible(find.byKey(const Key('youtube-setup-sign-in')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('youtube-setup-sign-in')));
      await tester.pump();

      expect(
          settingsBox().get(SettingsKeys.YouTubeApiKey.name), 'fresh-key');
      expect(settingsBox().get(SettingsKeys.YouTubeOAuthClientId.name),
          'fresh-client');
      expect(settingsBox().get(SettingsKeys.YouTubeOAuthClientSecret.name),
          'fresh-secret');
      expect(store.authState, isNot(YouTubeAuthState.unconfigured));
    } finally {
      unawaited(store.dispose());

      /// GetIt reset only after the close dance — its pumps rebuild the
      /// sheet's Observer, which still reads the registered store.
      await closeHiveInZone(tester);
      await GetIt.instance.reset();
    }
  });
}
