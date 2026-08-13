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
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/twitch_account_control.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_action_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_dropdown.dart';
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
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________, _________, __________) =>
          FakeTwitchEventSubService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
    );
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<DashboardStore>(DashboardStore());
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()));
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
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });
    store.authState = TwitchAuthState.loggedIn;
    store.chatConnection = TwitchChatConnectionState.live;

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    expect(find.byType(NativeTwitchChatView), findsOneWidget);
  });

  testWidgets(
      'slot shows the native connect prompt when logged out in native mode',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(
      find.text('Connect your Twitch account to see your chat natively.'),
      findsOneWidget,
    );

    /// Two "Connect Twitch" affordances by design in this tree: the
    /// username bar's account-control pill (Task 4) and the slot prompt's
    /// pill - both call startTwitchLogin
    expect(find.text('Connect Twitch'), findsNWidgets(2));
  });

  testWidgets('connect button starts the login and the dialog auto-closes',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    /// `.last` = the slot prompt's pill (the username bar's account-control
    /// pill comes first in tree order; both invoke the same
    /// startTwitchLogin, so the tested flow is identical)
    await tester.tap(find.text('Connect Twitch').last);
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

  testWidgets(
      'slot keeps the legacy WebView path when logged in but the engine is WebView',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    });
    store.authState = TwitchAuthState.loggedIn;
    store.chatConnection = TwitchChatConnectionState.live;

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    /// Being logged in no longer takes over the slot by itself — the
    /// WebView engine keeps the legacy path (here: its empty state, since
    /// no username is selected and a real WebView can't mount in tests)
    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(
      find.text('No Twitch username selected, so no one\'s chat can be displayed.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'native engine with a selected username still shows the connect prompt when logged out',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
      await settingsBox()
          .put(SettingsKeys.TwitchUsernames.name, <String>['someuser']);
      await settingsBox()
          .put(SettingsKeys.SelectedTwitchUsername.name, 'someuser');
    });

    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pumpAndSettle();

    /// The native branch wins before the legacy stack - no WebView gets
    /// built for the selected username while logged out
    expect(find.byType(NativeTwitchChatView), findsNothing);
    expect(
      find.text('Connect your Twitch account to see your chat natively.'),
      findsOneWidget,
    );
    expect(
      find.text('No Twitch username selected, so no one\'s chat can be displayed.'),
      findsNothing,
    );
  });

  testWidgets(
      'username bar shows the engine switch and connect pill only for Twitch in native mode',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsOneWidget);
    expect(find.text('Connect Twitch'), findsOneWidget);

    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.YouTube);
    });
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoSlidingSegmentedControl<ChatEngine>),
        findsNothing);
    expect(find.text('Connect Twitch'), findsNothing);
  });

  testWidgets(
      'username bar shows the connected account in native mode and offers disconnect',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    });
    store.authState = TwitchAuthState.loggedIn;
    store.user = FakeTwitchAuthService.user;

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();

    /// Account chip instead of a bare status icon — reads as tappable
    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);

    /// The display name shows twice: the channel dropdown's own-channel row
    /// and the account chip
    expect(find.text('Kounex'), findsNWidgets(2));

    await tester.tap(find.descendant(
      of: find.byType(TwitchAccountControl),
      matching: find.text('Kounex'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Twitch?'), findsOneWidget);
  });

  testWidgets('switching engines swaps the bar controls and persists the key',
      (tester) async {
    await tester.runAsync(() async {
      await settingsBox()
          .put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
      await settingsBox()
          .put(SettingsKeys.TwitchUsernames.name, <String>['someuser']);
      await settingsBox()
          .put(SettingsKeys.SelectedTwitchUsername.name, 'someuser');
    });

    await tester.pumpWidget(wrap(const ChatUsernameBar()));
    await tester.pumpAndSettle();

    /// WebView engine by default: username controls, no account control,
    /// and no persisted key yet
    expect(find.byType(UsernameDropdown), findsOneWidget);
    expect(find.byType(UsernameActionRow), findsOneWidget);
    expect(find.byType(TwitchAccountControl), findsNothing);
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name), isNull);

    await tester.tap(find.text('Native'));
    await tester.pump();

    /// Hive applies puts to its in-memory keystore synchronously; the box
    /// watch event reaches the HiveBuilder through the zone's microtasks,
    /// so pumps alone drive the rebuild (no real I/O window needed)
    expect(settingsBox().get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.native);

    await tester.pumpAndSettle();

    expect(find.byType(UsernameDropdown), findsNothing);
    expect(find.byType(UsernameActionRow), findsNothing);
    expect(find.byType(TwitchAccountControl), findsOneWidget);

    /// Close Hive from inside the test's FakeAsync zone (zone-bound write
    /// Completers hang a real-zone close) - same dance as the login test,
    /// minus the store dispose: no login flow ran here
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

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

  testWidgets(
      'native account control offers connect while logged out and starts login on tap',
      (tester) async {
    await tester.pumpWidget(wrap(const TwitchAccountControl()));
    await tester.pumpAndSettle();

    expect(find.text('Connect Twitch'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsNothing);

    await tester.tap(find.text('Connect Twitch'));
    await tester.pump();
    expect(find.byType(TwitchDeviceCodeDialog), findsOneWidget);

    /// Same teardown dance as the slot login test above: the tap-driven
    /// login chain persists the token (Hive write in this FakeAsync zone)
    /// and starts the store's auth-box watcher — unmount, dispose and
    /// close Hive from inside the zone or harness.close() hangs.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.dispose());
    await tester.pump();

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

  testWidgets(
      'native account control shows the connected account and disconnects on confirm',
      (tester) async {
    store.authState = TwitchAuthState.loggedIn;
    store.user = FakeTwitchAuthService.user;

    await tester.pumpWidget(wrap(const TwitchAccountControl()));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.checkmark_circle_fill), findsOneWidget);
    expect(find.text('Kounex'), findsOneWidget);

    await tester.tap(find.text('Kounex'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Twitch?'), findsOneWidget);

    await tester.tap(find.text('Disconnect'));
    await tester.pumpAndSettle();
    expect(find.text('Disconnect Twitch?'), findsNothing);

    /// logout() awaits the chat disconnect, the TwitchAuth box delete and
    /// the (faked) revoke — real I/O window, then the zone resumes the
    /// continuations
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(store.authState, TwitchAuthState.loggedOut);

    /// The tap-driven box delete ran in the test's FakeAsync zone and
    /// Hive's write-queue Completers only dispatch through the zone they
    /// were created in - a real-zone harness.close() in tearDown would
    /// hang. Same close-inside-the-zone dance as the login test above.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => store.dispose());
    await tester.pump();

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
