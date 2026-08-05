import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_device_code_dialog.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(
      theme: ThemeData(cupertinoOverrideTheme: const CupertinoThemeData()),

      /// The test font's full-em glyphs are much wider than production
      /// fonts — at 1.0 the selected 'YouTube ᵇᵉᵗᵃ' dropdown item
      /// overflows its fixed-width row by a few pixels
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(0.8)),
        child: Scaffold(body: child),
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late TwitchChatStore store;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_integration');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    await Hive.openBox(HiveKeys.Settings.name);
    store = TwitchChatStore(
      authService: FakeTwitchAuthService(),
      eventSubFactory: (_, __, ___) => FakeTwitchEventSubService(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<DashboardStore>(DashboardStore());
  });

  tearDown(() async {
    /// Fire-and-forget: the cancellation side effects happen
    /// synchronously; awaiting dispose() here would hang for stores
    /// whose subscription was created inside a widget test's FakeAsync
    /// zone (its future only dispatches through that zone)
    store.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('slot shows the native view for Twitch when logged in',
      (tester) async {
    /// Hive writes need real I/O — the test body's FakeAsync zone never
    /// completes them (and a pending write hangs Hive.close() in tearDown)
    await tester.runAsync(() async {
      await settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    });
    store.authState = TwitchAuthState.loggedIn;
    store.chatConnection = TwitchChatConnectionState.live;

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    expect(find.byType(NativeTwitchChatView), findsOneWidget);
  });

  testWidgets('slot keeps the empty state + connect button when logged out',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    });

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(find.text('Connect Twitch'), findsOneWidget);
  });

  testWidgets('connect button starts the login and the dialog auto-closes',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    });

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect Twitch'));
    await tester.pump();
    expect(find.byType(TwitchDeviceCodeDialog), findsOneWidget);

    /// The login chain awaits a real Hive write (persisting the token).
    /// runAsync gives the OS-level I/O a real-time window, but the
    /// Dart-level continuations were captured by the test's FakeAsync
    /// zone and only resume on the next pump. (pumpAndSettle can't be
    /// used while the dialog's progress spinner is animating — it never
    /// settles.)
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    expect(store.authState, TwitchAuthState.loggedIn);

    /// Observer rebuild registers the auto-close post-frame callback →
    /// pops the dialog; one longer pump covers the exit animation (the
    /// native view's connecting spinner is animating, so no settle)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(TwitchDeviceCodeDialog), findsNothing);

    /// Unmount the chat UI and stop the store first: a box close with
    /// live stream subscribers (HiveBuilder listenables, the store's
    /// auth-box watcher) never finishes — the 'done' handshake would
    /// stay queued in this zone. dispose() goes through runAsync since
    /// awaiting its future directly would hang (see below)
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.dispose());
    await tester.pump();

    /// Hive must be closed from inside the test's FakeAsync zone: the
    /// tap-driven login ran its Hive write in that zone, and the
    /// Completers Hive created for its write queue only dispatch their
    /// listeners through the zone they were created in — real-zone code
    /// in tearDown (harness.close()) would await one of them forever.
    /// Each pump drains the zone's queue; each runAsync is a real-time
    /// window for the next file op of the close (read/write/lock file
    /// handles are closed sequentially — hence several rounds). Boxes
    /// are re-opened by the next setUp.
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('username bar shows the Twitch account action only for Twitch',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.link), findsOneWidget);

    await tester.runAsync(() async {
      await settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.YouTube);
    });
    await tester.pumpAndSettle();
    expect(find.byIcon(CupertinoIcons.link), findsNothing);
  });

  testWidgets('username bar shows the connected account and offers disconnect',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox().put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    });
    store.authState = TwitchAuthState.loggedIn;
    store.user = FakeTwitchAuthService.user;

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();

    /// Account chip instead of a bare status icon — reads as tappable
    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
    expect(find.text('Kounex'), findsOneWidget);

    await tester.tap(find.text('Kounex'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Twitch?'), findsOneWidget);
  });

  testWidgets('tapping the code copies it and confirms inline',
      (tester) async {
    store.authState = TwitchAuthState.awaitingAuthorization;
    store.pendingUserCode = 'ABCD-EFGH';
    store.pendingVerificationUri = 'https://www.twitch.tv/activate';

    await tester.pumpWidget(wrap(const TwitchDeviceCodeDialog()));
    await tester.pump();

    expect(find.text('Tap the code to copy it'), findsOneWidget);

    await tester.tap(find.text('ABCD-EFGH'));
    await tester.pump();
    expect(find.text('Copied to clipboard'), findsOneWidget);

    /// Feedback reverts once its window elapsed
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Copied to clipboard'), findsNothing);
    expect(find.text('Tap the code to copy it'), findsOneWidget);
  });
}
